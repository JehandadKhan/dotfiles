-- install-lazyvim.sh: managed file (rewritten on every re-run)

-- Insert basedpyright's inferred types as real annotations.
--
-- basedpyright's type inlay hints (`big: list[int]`, `-> int`) carry LSP
-- textEdits that turn them into source -- the "double-click the hint" feature in
-- VS Code. Applied raw they are messy, so this filters and fixes them up:
--   * type hints only (kind 1); parameter-name hints (`line=`) are skipped;
--   * a bare `Any` is skipped -- it documents nothing;
--   * each hint carries its own import edit, all aimed at line 0, so the same
--     `from typing import Any` would land N times, above everything -- in an
--     .ipynb that is above the jupytext header. Imports are deduplicated,
--     dropped if already present, and inserted after the first import block
--     (else after the first `# %%` code-cell marker / leading comments).
-- Hints are requested directly for the range rather than read from
-- vim.lsp.inlay_hint's cache, which only covers what has been on screen.

local HINT_TYPE = 1

local function import_lines(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local present = {}
  for _, l in ipairs(lines) do
    local mod, names = l:match("^from%s+(%S+)%s+import%s+(.+)$")
    if mod then
      for n in names:gmatch("[%w_]+") do
        present["from " .. mod .. " import " .. n] = true
      end
    elseif l:match("^import%s") then
      present[vim.trim(l)] = true
    end
  end
  return lines, present
end

--- 0-indexed line to insert new imports at.
local function import_anchor(lines, is_notebook)
  local first, last
  for i, l in ipairs(lines) do
    if l:match("^import%s") or l:match("^from%s+%S+%s+import%s") then
      first = first or i
      last = i
    elseif first and not l:match("^%s*$") then
      break -- end of the first import block
    end
  end
  if last then
    return last
  end
  for i, l in ipairs(lines) do
    if is_notebook then
      if l:match("^%s*#%s*%%%%%s*$") then
        return i -- just under the first code-cell marker
      end
    elseif not (l:match("^%s*#") or l:match("^%s*$")) then
      return i - 1 -- after shebang / leading comments
    end
  end
  return 0
end

local function apply_type_hints(buf, first, last)
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf -- apply_text_edits rejects 0
  local client = vim.lsp.get_clients({ bufnr = buf, name = "basedpyright" })[1]
  if not client then
    vim.notify("basedpyright is not attached", vim.log.levels.WARN)
    return
  end
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(buf),
    range = { start = { line = first - 1, character = 0 }, ["end"] = { line = last, character = 0 } },
  }
  client:request("textDocument/inlayHint", params, function(err, hints)
    if err then
      vim.notify("inlay hints: " .. err.message, vim.log.levels.ERROR)
      return
    end
    local edits, wanted = {}, {}
    for _, h in ipairs(hints or {}) do
      local label = type(h.label) == "string" and h.label
        or table.concat(vim.tbl_map(function(p) return p.value end, h.label))
      -- the request range is fuzzy at its end: keep only hints on the asked lines
      local on_line = h.position.line >= first - 1 and h.position.line <= last - 1
      if on_line and h.kind == HINT_TYPE and h.textEdits and not label:match("^[:%->%s]*Any$") then
        for _, e in ipairs(h.textEdits) do
          -- import edits come as "from x import Y\n\n\n" or, when the file
          -- already has imports, "\nfrom x import Y": match the trimmed text
          local t = vim.trim(e.newText)
          local imp = t:match("^(from%s+%S+%s+import%s+[%w_]+)$") or t:match("^(import%s+%S+)$")
          if imp then
            wanted[imp] = true
          else
            table.insert(edits, e)
          end
        end
      end
    end
    if #edits == 0 then
      vim.notify("No type hints to apply here")
      return
    end
    local lines, present = import_lines(buf)
    local new = {}
    for imp in pairs(wanted) do
      if not present[imp] then
        table.insert(new, imp)
      end
    end
    table.sort(new)
    if #new > 0 then
      local at = import_anchor(lines, vim.api.nvim_buf_get_name(buf):match("%.ipynb$") ~= nil)
      table.insert(edits, {
        range = { start = { line = at, character = 0 }, ["end"] = { line = at, character = 0 } },
        newText = table.concat(new, "\n") .. "\n",
      })
    end
    vim.lsp.util.apply_text_edits(edits, buf, client.offset_encoding)
    vim.notify(("Applied %d type annotation(s)%s"):format(#edits - (#new > 0 and 1 or 0),
      #new > 0 and (", added " .. table.concat(new, "; ")) or ""))
  end, buf)
end

return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      clangd = {
        mason = false,
      },
      -- install.d/07-basedpyright.sh installs basedpyright globally via npm and
      -- removes any stray pyright. LazyVim's lang.python extra enables pyright
      -- by default, so without this both would be configured and we would get
      -- duplicate diagnostics on the same buffer. Disable pyright, and point
      -- basedpyright at the npm-installed binary rather than a Mason copy.
      --
      -- Note pyright "working" today is misleading: basedpyright's npm package
      -- ships its own pyright/pyright-langserver shims, so the pyright config
      -- resolves to a binary that runs -- but under pyright's defaults, not
      -- basedpyright's stricter ones.
      pyright = {
        enabled = false,
      },
      basedpyright = {
        mason = false,
        keys = {
          {
            "<leader>ct",
            function()
              local a, b = vim.fn.line("v"), vim.fn.line(".")
              if vim.fn.mode():match("[vV\22]") then
                vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
              else
                a = b
              end
              apply_type_hints(0, math.min(a, b), math.max(a, b))
            end,
            mode = { "n", "x" },
            desc = "Add inferred types (line / selection)",
          },
          {
            "<leader>cT",
            function()
              apply_type_hints(0, 1, vim.api.nvim_buf_line_count(0))
            end,
            desc = "Add inferred types (buffer)",
          },
        },
      },
    },
  },
}
