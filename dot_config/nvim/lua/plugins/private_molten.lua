-- install-lazyvim.sh: managed file (rewritten on every re-run)

-- Molten has no concept of `# %%` markers. A "cell" to molten is an
-- extmark-backed span (CodeCell) created by an evaluate call; :MoltenReevaluateCell
-- searches those spans for one containing the cursor and errors "Not in a cell"
-- when none match. So the `# %%` markers have to be translated into a span by us,
-- via vim.fn.MoltenEvaluateRange(start, end) -- 1-indexed, inclusive -- which is
-- what registers the extmarks that make re-eval work later.

local CELL_PAT = "^%s*#%s*%%%%" -- matches `# %%`, `#%%`, `# %% [markdown]`

--- Find the 1-indexed inclusive line range of the `# %%` cell under the cursor
--- (or containing line `at`, when given).
--- The marker line itself is included (it is a comment, harmless to the kernel,
--- and keeps the extmark anchored to the cell header so re-eval stays stable).
local function cell_range(at)
  local cur = at or vim.api.nvim_win_get_cursor(0)[1]
  local last = vim.api.nvim_buf_line_count(0)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  local function is_marker(n)
    return lines[n] ~= nil and lines[n]:match(CELL_PAT) ~= nil
  end

  -- walk up to this cell's marker (or the top of the buffer)
  local start = cur
  while start > 1 and not is_marker(start) do
    start = start - 1
  end

  -- walk down to the line before the next marker
  local stop = cur
  while stop < last and not is_marker(stop + 1) do
    stop = stop + 1
  end

  -- trim trailing blank lines so the span ends on real code
  while stop > start and lines[stop]:match("^%s*$") do
    stop = stop - 1
  end

  return start, stop
end

--- True when lines start..stop hold something besides blanks and `# %%` markers.
local function has_code(start, stop)
  for _, l in ipairs(vim.api.nvim_buf_get_lines(0, start - 1, stop, false)) do
    if not l:match("^%s*$") and not l:match(CELL_PAT) then
      return true
    end
  end
  return false
end

--- Evaluate the cell under the cursor, creating the molten span.
local function run_cell()
  local start, stop = cell_range()
  -- a cell that is nothing but its `# %%` marker has no code to run; sending it
  -- would register an empty span and produce an empty output block
  if not has_code(start, stop) then
    vim.notify("Molten: empty cell, nothing to run", vim.log.levels.WARN)
    return
  end
  vim.fn.MoltenEvaluateRange(start, stop)
end

--- Re-eval if the cursor is already inside a tracked span, otherwise evaluate
--- the `# %%` cell (which creates the span). Makes one key always do the right
--- thing instead of erroring "Not in a cell" on the first run.
local function run_or_rerun()
  local ok = pcall(vim.cmd, "MoltenReevaluateCell")
  if not ok then
    run_cell()
  end
end

--- Clear molten's inline output extmarks WITHOUT touching cell boundaries.
---
--- molten puts everything in one `molten-extmarks` namespace, so a blanket
--- nvim_buf_clear_namespace() would also delete the DynamicPosition marks that
--- define each CodeCell -- i.e. it would wipe every tracked cell and bring back
--- "Not in a cell". The three kinds of mark in that namespace are distinguishable
--- (verified against a live buffer):
---   * cell boundaries (DynamicPosition)  -> bare mark, no virt_lines
---   * float spacing   (set_height)       -> virt_lines, but all EMPTY strings
---   * real output     (show_virtual_output) -> virt_lines with non-empty text
--- so we delete only the third kind.
local function clear_virt_output_marks()
  local ns = vim.api.nvim_create_namespace("molten-extmarks")
  local buf = vim.api.nvim_get_current_buf()
  local marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
  local cleared = 0
  for _, m in ipairs(marks) do
    local id, details = m[1], m[4]
    local vl = details and details.virt_lines
    if vl then
      local has_text = false
      for _, line in ipairs(vl) do
        for _, chunk in ipairs(line) do
          if chunk[1] ~= nil and chunk[1] ~= "" then
            has_text = true
            break
          end
        end
        if has_text then break end
      end
      if has_text then
        vim.api.nvim_buf_del_extmark(buf, ns, id)
        cleared = cleared + 1
      end
    end
  end
  return cleared
end

--- Toggle inline virtual-text output.
---
--- :MoltenHideOutput only sets should_show_floating_win = False -- it hides the
--- *floating* window. With vim.g.molten_virt_text_output = true the output is
--- drawn as virtual text instead, by a separate path: update_interface()
--- unconditionally re-runs show_virtual_output() for every cell whenever
--- molten_virt_text_output is set (moltenbuffer.py:372). Since HideOutput itself
--- ends by calling _update_interface(), it clears the float flag and then
--- immediately redraws the virt text -- so it can never hide it.
---
--- Hiding therefore needs two things: flip the option off so nothing redraws it,
--- and delete the marks that are already on screen.
local virt_text_shown = true

local function toggle_virt_output()
  virt_text_shown = not virt_text_shown

  if not virt_text_shown then
    -- stop future redraws first, then clear what is already drawn
    pcall(vim.fn.MoltenUpdateOption, "virt_text_output", false)
    vim.g.molten_virt_text_output = false
    local n = clear_virt_output_marks()
    vim.notify(("Molten: inline output hidden (%d cleared)"):format(n), vim.log.levels.INFO)
  else
    pcall(vim.fn.MoltenUpdateOption, "virt_text_output", true)
    vim.g.molten_virt_text_output = true
    -- show_virtual_output() early-returns when a cell is DONE and still holds a
    -- virt_text_id (outputbuffer.py:206), and clear_virt_output() never resets
    -- that id -- so a plain UpdateInterface will not bring the text back.
    -- Re-running the cells is the only redraw path molten exposes.
    pcall(vim.cmd, "MoltenReevaluateAll")
    vim.notify("Molten: inline output shown (cells re-run)", vim.log.levels.INFO)
  end
end

--- Hide the floating output window for the current cell.
---
--- This only affects the float. With virt_text_output on, the inline text stays
--- -- use <leader>mt for that. (:MoltenDelete is the one command that truly
--- clears a cell's virt text, but it also does `del self.outputs[cell]`, which
--- destroys the tracked span and breaks re-eval for that cell, so it stays bound
--- to <leader>md as an explicit delete rather than being used to hide.)
local function hide_output()
  pcall(vim.cmd, "MoltenHideOutput")
  -- HideOutput ends in _update_interface(), which redraws virt text while the
  -- option is on; clear after it so the inline output actually goes away too.
  clear_virt_output_marks()
end

--- Run the current cell, then jump to the first line of the next one.
local function run_cell_and_advance()
  local _, stop = cell_range()
  run_cell()
  local last = vim.api.nvim_buf_line_count(0)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for n = stop + 1, last do
    if lines[n] and lines[n]:match(CELL_PAT) then
      vim.api.nvim_win_set_cursor(0, { math.min(n + 1, last), 0 })
      return
    end
  end
  vim.api.nvim_win_set_cursor(0, { last, 0 })
end

-- Local patch to molten: only trust iopub messages replying to molten's own
-- execute requests.
--
-- molten's JupyterRuntime.tick() feeds every iopub message to the current output
-- without checking parent_header (runtime.py `_tick_one`), and treats ANY
-- `status: idle` as "this cell finished". Anything else talking to the kernel
-- breaks that, and the debugger does so twice over:
--   * ipykernel publishes busy/idle for every *control* message, and each DAP
--     request (`debug_request`) is one -- so the first stackTrace while paused at
--     a breakpoint marks the cell DONE;
--   * on attach, ipykernel starts debugpy by sending ITSELF a silent
--     execute_request, whose idle sits in molten's iopub backlog and is consumed
--     as soon as the next cell is queued -- DONE before it even starts.
-- Either way the cell shows `Out[...]: Done` and its real output is dropped or
-- lands on the next cell. Filtering by msg_type isn't enough (the second case IS
-- an execute_request), so the patch records the msg_id of each execute molten
-- sends and skips any message whose parent is not one of them. The remote
-- jupyter-server client returns no msg_id, so it keeps the old unfiltered path.
-- Upstream-worthy; until then it is applied here.
--
-- lazy.nvim updates with a plain `git checkout` (no --force), so a dirty file
-- would block a molten update: the patch is reverted on Lazy{Update,Sync,Restore}Pre
-- and re-applied on the next startup (init runs before molten's python host loads).
local MOLTEN_PATCH_MARK = "# [nvim-config] own-execute filter"
local MOLTEN_PATCH_FILE = "rplugin/python3/molten/runtime.py"
local MOLTEN_PATCHES = {
  {
    anchor = "        self.kernel_client.execute(code)\n",
    body = [[
        msg_id = self.kernel_client.execute(code)
        ]] .. MOLTEN_PATCH_MARK .. "\n" .. [[
        if msg_id:
            self.__dict__.setdefault("_nvim_own_ids", set()).add(msg_id)
]],
  },
  {
    anchor = [[
                if "content" not in message or "msg_type" not in message:
                    continue
]],
    body = [[
                if "content" not in message or "msg_type" not in message:
                    continue
                ]] .. MOLTEN_PATCH_MARK .. "\n" .. [[
                own = self.__dict__.get("_nvim_own_ids")
                if own is not None and (message.get("parent_header") or {}).get("msg_id") not in own:
                    continue
]],
  },
}

local function molten_dir()
  return vim.fn.stdpath("data") .. "/lazy/molten-nvim"
end

local function patch_molten()
  local path = molten_dir() .. "/" .. MOLTEN_PATCH_FILE
  local f = io.open(path, "r")
  if not f then
    return -- not installed yet
  end
  local src = f:read("*a")
  f:close()
  if src:find(MOLTEN_PATCH_MARK, 1, true) then
    return
  end
  -- all-or-nothing: half a patch (ids recorded but never filtered, or the
  -- reverse) would be worse than none
  for _, p in ipairs(MOLTEN_PATCHES) do
    local s, e = src:find(p.anchor, 1, true)
    if not s then
      vim.schedule(function()
        vim.notify("molten iopub patch no longer applies (upstream changed runtime.py); "
          .. "cell output may be lost while debugging", vim.log.levels.WARN)
      end)
      return
    end
    src = src:sub(1, s - 1) .. p.body .. src:sub(e + 1)
  end
  f = assert(io.open(path, "w"))
  f:write(src)
  f:close()
end

local function unpatch_molten()
  vim.system({ "git", "-C", molten_dir(), "checkout", "--", MOLTEN_PATCH_FILE }):wait()
end

-- Debugging cells ---------------------------------------------------------------
--
-- Molten has no debugger, but ipykernel does (the one JupyterLab drives): DAP
-- messages sent as `debug_request` on the kernel's control channel. The
-- scripts/nb_dap_bridge.py adapter connects nvim-dap to that, attached to the
-- very kernel molten started, so cells still run through molten and output still
-- renders inline. The bridge maps notebook lines <-> ipykernel's per-cell temp
-- files, which is why every `# %%` cell's text is registered before each run.

local function venv_python()
  local p = vim.g.python3_host_prog
  if p and vim.fn.executable(p) == 1 then
    return p
  end
  return vim.fn.expand("~/.local/share/nvim-venv/bin/python")
end

--- Connection files of ipykernels descended from this nvim, i.e. the ones molten
--- launched (via its rplugin host). molten does not expose them; ps does.
local function molten_kernels()
  local procs = {}
  for _, l in ipairs(vim.fn.systemlist({ "ps", "-A", "-o", "pid=,ppid=,command=" })) do
    local pid, ppid, cmd = l:match("^%s*(%d+)%s+(%d+)%s+(.*)$")
    if pid then
      procs[tonumber(pid)] = { ppid = tonumber(ppid), cmd = cmd }
    end
  end
  local me, found = vim.fn.getpid(), {}
  for _, p in pairs(procs) do
    local file = p.cmd:match("ipykernel_launcher.-%-f%s+(%S+)")
    local a, hops = p.ppid, 0
    while file and a and a > 1 and hops < 8 do
      if a == me then
        table.insert(found, { file = file, python = p.cmd:match("^(%S+)") })
        break
      end
      a, hops = procs[a] and procs[a].ppid, hops + 1
    end
  end
  return found
end

--- Every non-empty `# %%` cell in the buffer, with the exact text molten sends
--- for it (MoltenEvaluateRange over whole lines, joined by "\n"). ipykernel
--- names a cell's compiled file by a hash of that text, so it must match.
local function notebook_cells()
  local cells, n, last = {}, 1, vim.api.nvim_buf_line_count(0)
  while n <= last do
    local start, stop = cell_range(n)
    if has_code(start, stop) then
      local text = table.concat(vim.api.nvim_buf_get_lines(0, start - 1, stop, false), "\n")
      table.insert(cells, { start = start, code = text })
    end
    -- next cell begins at the next marker after this one's (untrimmed) end
    n = stop + 1
    while n <= last and not vim.fn.getline(n):match(CELL_PAT) do
      n = n + 1
    end
  end
  return cells
end

--- Call cb(session) with a nvim-dap session attached to molten's kernel,
--- starting one (and waiting for configurationDone) if needed.
local function with_debug_session(cb)
  local dap = require("dap")
  local s = dap.session()
  if s and s.config.type == "nbkernel" then
    return cb(s)
  end

  dap.adapters.nbkernel = function(on_adapter, config)
    on_adapter({
      type = "executable",
      command = venv_python(),
      args = { vim.fn.stdpath("config") .. "/scripts/nb_dap_bridge.py", config.connection_file },
    })
  end
  dap.listeners.after.event_nbWarning.nbdebug = function(_, body)
    vim.notify("Notebook debug: " .. body.message, vim.log.levels.WARN)
  end

  local function start(kernel)
    dap.listeners.after.configurationDone.nbdebug = function(session)
      dap.listeners.after.configurationDone.nbdebug = nil
      vim.schedule(function()
        cb(session)
      end)
    end
    dap.run({
      type = "nbkernel",
      request = "attach",
      name = "Notebook kernel",
      connection_file = kernel.file,
    })
  end

  local kernels = molten_kernels()
  if #kernels == 0 then
    vim.notify("Notebook debug: no molten kernel running in this nvim (<leader>mi first)", vim.log.levels.ERROR)
  elseif #kernels == 1 then
    start(kernels[1])
  else
    vim.ui.select(kernels, {
      prompt = "Debug which kernel?",
      format_item = function(k)
        return k.python .. "  (" .. vim.fn.fnamemodify(k.file, ":t") .. ")"
      end,
    }, function(k)
      if k then
        start(k)
      end
    end)
  end
end

--- Run the cell under the cursor with the debugger attached: breakpoints set
--- with <leader>db anywhere in the notebook (or in imported .py files) stop it.
local function debug_cell()
  local buf = vim.api.nvim_get_current_buf()
  local start, stop = cell_range()
  if not has_code(start, stop) then
    vim.notify("Molten: empty cell, nothing to run", vim.log.levels.WARN)
    return
  end
  with_debug_session(function(session)
    vim.api.nvim_buf_call(buf, function()
      local code = table.concat(vim.api.nvim_buf_get_lines(0, start - 1, stop, false), "\n")
      session:request("nbRegisterCells", {
        path = vim.api.nvim_buf_get_name(buf),
        cells = notebook_cells(),
        expect = code,
      }, function(err)
        if err then
          vim.notify("Notebook debug: " .. tostring(err.message or err), vim.log.levels.ERROR)
          return
        end
        vim.schedule(function()
          vim.api.nvim_buf_call(buf, function()
            vim.fn.MoltenEvaluateRange(start, stop)
          end)
        end)
      end)
    end)
  end)
end

return {
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    dependencies = { "3rd/image.nvim" },
    build = ":UpdateRemotePlugins",
    ft = { "python", "markdown", "quarto" },
    init = function()
      patch_molten()
      vim.api.nvim_create_autocmd("User", {
        pattern = { "LazyUpdatePre", "LazySyncPre", "LazyRestorePre" },
        callback = unpatch_molten,
      })
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = false
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = true
      vim.g.molten_wrap_output = true
    end,
    keys = {
      { "<leader>mi", ":MoltenInit<CR>",                  desc = "Molten: init kernel" },
      { "<leader>mc", run_cell,                           desc = "Molten: run # %% cell" },
      { "<leader>mn", run_cell_and_advance,               desc = "Molten: run cell + next" },
      { "<leader>me", ":MoltenEvaluateOperator<CR>",      desc = "Molten: eval operator" },
      { "<leader>ml", ":MoltenEvaluateLine<CR>",          desc = "Molten: eval line" },
      { "<leader>mr", run_or_rerun,                       desc = "Molten: re-eval cell" },
      { "<leader>mv", ":<C-u>MoltenEvaluateVisual<CR>gv", desc = "Molten: eval selection", mode = "v" },
      { "<leader>mo", ":noautocmd MoltenEnterOutput<CR>", desc = "Molten: enter output" },
      { "<leader>mh", hide_output,                        desc = "Molten: hide output (float)" },
      { "<leader>mt", toggle_virt_output,                 desc = "Molten: toggle inline output" },
      { "<leader>md", ":MoltenDelete<CR>",                desc = "Molten: delete cell" },
      { "<leader>mR", ":MoltenReevaluateAll<CR>",         desc = "Molten: re-eval all cells" },
      { "<leader>mD", debug_cell,                         desc = "Molten: debug cell" },
    },
  },
}
