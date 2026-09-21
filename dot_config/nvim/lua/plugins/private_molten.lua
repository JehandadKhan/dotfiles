-- install-lazyvim.sh: managed file (rewritten on every re-run)

-- Molten has no concept of `# %%` markers. A "cell" to molten is an
-- extmark-backed span (CodeCell) created by an evaluate call; :MoltenReevaluateCell
-- searches those spans for one containing the cursor and errors "Not in a cell"
-- when none match. So the `# %%` markers have to be translated into a span by us,
-- via vim.fn.MoltenEvaluateRange(start, end) -- 1-indexed, inclusive -- which is
-- what registers the extmarks that make re-eval work later.

local CELL_PAT = "^%s*#%s*%%%%" -- matches `# %%`, `#%%`, `# %% [markdown]`

--- Find the 1-indexed inclusive line range of the `# %%` cell under the cursor.
--- The marker line itself is included (it is a comment, harmless to the kernel,
--- and keeps the extmark anchored to the cell header so re-eval stays stable).
local function cell_range()
  local cur = vim.api.nvim_win_get_cursor(0)[1]
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

--- Evaluate the cell under the cursor, creating the molten span.
local function run_cell()
  local start, stop = cell_range()
  -- a cell that is nothing but its `# %%` marker has no code to run; sending it
  -- would register an empty span and produce an empty output block
  local lines = vim.api.nvim_buf_get_lines(0, start - 1, stop, false)
  local has_code = false
  for _, l in ipairs(lines) do
    if not l:match("^%s*$") and not l:match(CELL_PAT) then
      has_code = true
      break
    end
  end
  if not has_code then
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

return {
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    dependencies = { "3rd/image.nvim" },
    build = ":UpdateRemotePlugins",
    ft = { "python", "markdown", "quarto" },
    init = function()
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
    },
  },
}
