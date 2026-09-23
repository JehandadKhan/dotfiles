"""DAP adapter: nvim-dap <-> a running Jupyter kernel's built-in debugger.

    python nb_dap_bridge.py <kernel-connection-file>

Speaks DAP on stdio to nvim-dap and forwards every request to the kernel as a
`debug_request` on its control channel -- the same path JupyterLab's debugger
uses. Kernel-side DAP events arrive as `debug_event` on iopub and are relayed.

The one thing this adds over a plain proxy is line mapping. ipykernel compiles
each cell under `<tmp>/ipykernel_<pid>/<murmur2(cell text)>.py` (see
ipykernel/compiler.py:get_file_name), so a breakpoint on line N of `foo.ipynb`
means nothing to debugpy. nvim sends `nbRegisterCells` with the text and start
line of every `# %%` cell in the notebook buffer; `dumpCell` gives each cell's
compiled path, and from then on:
  * setBreakpoints on foo.ipynb  -> split across the cells' paths, lines shifted
  * stackTrace / breakpoint events -> cell paths mapped back to foo.ipynb lines
so the cursor stops in the notebook buffer rather than in a temp file.
"""

import asyncio
import json
import os
import sys
from typing import Any

from jupyter_client.asynchronous import AsyncKernelClient

KERNEL_TIMEOUT = 30


def norm(path):
    # dumpCell reports tempfile.gettempdir() paths (/var/folders/...); debugpy
    # may report the realpath (/private/var/...). Key everything on realpath.
    return os.path.realpath(path) if path else path


class Bridge:
    def __init__(self, connection_file):
        self.kc = AsyncKernelClient()
        self.kc.load_connection_file(connection_file)
        self.kc.start_channels(shell=False, stdin=False, hb=False)
        self.out_seq = 0
        self.k_seq = 0
        self.pending = {}  # kernel msg_id -> future
        self.cells = {}  # norm(cell path) -> (notebook path, start line, n lines)
        self.nb_cells = {}  # notebook path -> set of norm(cell path)
        self.nb_bps = {}  # notebook path -> breakpoints as nvim-dap sent them
        self.expect = None  # cell text nvim is about to execute (sanity check)
        self.done = asyncio.Event()

    # -- stdio -------------------------------------------------------------

    def send(self, obj):
        self.out_seq += 1
        obj["seq"] = self.out_seq
        data = json.dumps(obj).encode()
        sys.stdout.buffer.write(b"Content-Length: %d\r\n\r\n" % len(data) + data)
        sys.stdout.buffer.flush()

    def respond(self, req, success=True, body=None, message=None):
        resp = {"type": "response", "request_seq": req["seq"], "command": req["command"], "success": success}
        if body is not None:
            resp["body"] = body
        if message:
            resp["message"] = message
        self.send(resp)

    def event(self, name, body=None):
        self.send({"type": "event", "event": name, "body": body or {}})

    async def read_stdin(self):
        loop = asyncio.get_running_loop()
        reader = asyncio.StreamReader()
        await loop.connect_read_pipe(lambda: asyncio.StreamReaderProtocol(reader), sys.stdin)
        while True:
            length = None
            while True:
                line = await reader.readline()
                if not line:
                    return
                line = line.strip()
                if not line:
                    break
                k, _, v = line.partition(b":")
                if k.lower() == b"content-length":
                    length = int(v)
            if length is None:
                continue
            req = json.loads(await reader.readexactly(length))
            if req.get("type") == "request":
                # sequential on purpose: DAP clients expect in-order handling,
                # and breakpoint splits must finish before the next request
                await self.handle(req)

    # -- kernel ------------------------------------------------------------

    async def kreq(self, command, arguments=None):
        self.k_seq += 1
        content = {"type": "request", "seq": self.k_seq, "command": command, "arguments": arguments or {}}
        msg = self.kc.session.msg("debug_request", content)
        fut = asyncio.get_running_loop().create_future()
        self.pending[msg["header"]["msg_id"]] = fut
        self.kc.control_channel.send(msg)
        try:
            return await asyncio.wait_for(fut, KERNEL_TIMEOUT)
        finally:
            self.pending.pop(msg["header"]["msg_id"], None)

    async def read_control(self):
        while True:
            msg = await self.kc.control_channel.get_msg()
            fut = self.pending.get(msg["parent_header"].get("msg_id"))
            if fut and not fut.done():
                fut.set_result(msg["content"])

    async def read_iopub(self):
        while True:
            msg = await self.kc.iopub_channel.get_msg()
            kind = msg["msg_type"]
            if kind == "debug_event":
                ev = msg["content"]
                if ev.get("event") == "breakpoint":
                    bp = ev.get("body", {}).get("breakpoint", {})
                    self.map_location(bp)
                self.send(ev)
            elif kind == "execute_input" and self.expect is not None:
                if msg["content"].get("code") != self.expect:
                    self.event("nbWarning", {"message": "cell text sent to the kernel differs from what was registered; breakpoints in this cell may not bind"})
                self.expect = None

    # -- line mapping --------------------------------------------------------

    def map_location(self, obj):
        """Rewrite a frame/breakpoint whose source is a cell file to the notebook."""
        src = obj.get("source") or {}
        cell = self.cells.get(norm(src.get("path")))
        if not cell:
            return
        nb, start, _ = cell
        obj["source"] = {"name": os.path.basename(nb), "path": nb}
        for key in ("line", "endLine"):
            if obj.get(key):
                obj[key] += start - 1

    async def push_nb_breakpoints(self, nb):
        """Send the notebook's breakpoints to every registered cell of it."""
        bps = self.nb_bps.get(nb, [])
        results: list[Any] = [None] * len(bps)
        for cp in self.nb_cells.get(nb, ()):
            _, start, n = self.cells[cp]
            idx = [i for i, b in enumerate(bps) if start <= b["line"] < start + n]
            sub = [dict(bps[i], line=bps[i]["line"] - start + 1) for i in idx]
            r = await self.kreq("setBreakpoints", {"source": {"path": cp}, "breakpoints": sub})
            for i, got in zip(idx, (r.get("body") or {}).get("breakpoints", [])):
                got = dict(got, source={"path": cp})
                self.map_location(got)
                got.setdefault("line", bps[i]["line"])
                results[i] = got
        # Lines outside any registered cell can't be bound yet: they will be the
        # next time the notebook's cells are registered. Report them as pending
        # (verified) rather than rejected so the sign doesn't look broken.
        return [r or {"verified": True, "line": b["line"]} for r, b in zip(results, bps)]

    # -- requests ------------------------------------------------------------

    async def forward(self, req):
        resp = await self.kreq(req["command"], req.get("arguments"))
        resp = dict(resp, request_seq=req["seq"])
        return resp

    async def handle(self, req):
        cmd = req["command"]
        args = req.get("arguments") or {}
        try:
            if cmd == "nbRegisterCells":
                await self.register_cells(args)
                self.respond(req)
            elif cmd == "setBreakpoints" and (args.get("source") or {}).get("path", "").endswith(".ipynb"):
                nb = args["source"]["path"]
                self.nb_bps[nb] = args.get("breakpoints", [])
                self.respond(req, body={"breakpoints": await self.push_nb_breakpoints(nb)})
            elif cmd == "attach":
                # ipykernel fills in debugpy's host/port itself; nvim-dap's
                # config fields (connection file etc.) mean nothing to it
                self.send(await self.forward(dict(req, arguments={})))
            elif cmd in ("disconnect", "terminate"):
                # The kernel belongs to molten, not to this debug session. nvim-dap's
                # terminate sends `terminate` or `disconnect{terminateDebuggee=true}`,
                # and debugpy honours either by killing the process it's attached to
                # -- i.e. the kernel. Always detach instead; execution resumes.
                resp = await self.kreq("disconnect", {"restart": False, "terminateDebuggee": False})
                self.send(dict(resp, request_seq=req["seq"], command=cmd))
                if cmd == "terminate":
                    self.event("terminated")
                self.done.set()
            else:
                resp = await self.forward(req)
                if cmd == "initialize" and resp.get("body"):
                    # steer nvim-dap to `disconnect` (handled above) over `terminate`
                    resp["body"]["supportsTerminateRequest"] = False
                if cmd == "stackTrace":
                    for frame in (resp.get("body") or {}).get("stackFrames", []):
                        self.map_location(frame)
                self.send(resp)
        except asyncio.TimeoutError:
            self.respond(req, False, message=f"kernel did not answer {cmd} (is it alive?)")
        except Exception as e:  # never let one bad request kill the session
            self.respond(req, False, message=f"{type(e).__name__}: {e}")

    async def register_cells(self, args):
        nb = args["path"]
        new = set()
        for c in args["cells"]:
            r = await self.kreq("dumpCell", {"code": c["code"]})
            cp = norm(r["body"]["sourcePath"])
            self.cells[cp] = (nb, c["start"], c["code"].count("\n") + 1)
            new.add(cp)
        # cells whose text changed since last time: their old compiled paths
        # would keep stale breakpoints at now-meaningless lines
        for cp in self.nb_cells.get(nb, set()) - new:
            await self.kreq("setBreakpoints", {"source": {"path": cp}, "breakpoints": []})
            self.cells.pop(cp, None)
        self.nb_cells[nb] = new
        await self.push_nb_breakpoints(nb)
        self.expect = args.get("expect")

    async def run(self):
        tasks = [asyncio.create_task(t) for t in (self.read_control(), self.read_iopub())]
        stdin = asyncio.create_task(self.read_stdin())
        done = asyncio.create_task(self.done.wait())
        await asyncio.wait({stdin, done}, return_when=asyncio.FIRST_COMPLETED)
        if stdin.done() and not self.done.is_set():
            # nvim went away mid-session: detach so a kernel paused at a
            # breakpoint resumes instead of hanging forever
            try:
                await self.kreq("disconnect", {"restart": False, "terminateDebuggee": False})
            except Exception:
                pass
        for t in tasks + [stdin, done]:
            t.cancel()
        self.kc.stop_channels()


if __name__ == "__main__":
    asyncio.run(Bridge(sys.argv[1]).run())
