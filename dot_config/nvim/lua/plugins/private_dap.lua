-- Debugger UI tuned for notebooks, where variables are often large lists, arrays
-- and dataframes. The stock dap-ui/virtual-text setup renders those badly:
--   * the Scopes pane is a fixed 40 columns and each value is one unwrapped
--     line, so `big list = [0, 1, 2, ...` is cut at the pane border;
--   * nvim-dap-virtual-text writes the entire repr inline after the code line
--     (`def g(xs = [0, 1, 2, 3, ... ]`), running off-screen.
-- Paging is debugpy's, not ours: expanding a container shows 100 children and a
-- `more` node; expand that for the next page.

local MAX_INLINE = 60 -- chars of a value shown as virtual text in code

local function truncate(s, n)
  s = s:gsub("%s+", " ")
  if vim.fn.strchars(s) > n then
    s = vim.fn.strcharpart(s, 0, n) .. "…"
  end
  return s
end

return {
  {
    "rcarriga/nvim-dap-ui",
    opts = {
      -- wrap long values instead of cutting them at the pane border (dap-ui
      -- applies this per window itself, overriding any autocmd'd 'wrap')
      wrap = true,
      layouts = {
        {
          elements = {
            { id = "scopes", size = 0.55 },
            { id = "watches", size = 0.15 },
            { id = "stacks", size = 0.2 },
            { id = "breakpoints", size = 0.1 },
          },
          size = 0.33, -- fraction of the editor width, instead of a fixed 40 columns
          position = "left",
        },
        { elements = { "repl", "console" }, size = 10, position = "bottom" },
      },
    },
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    opts = {
      display_callback = function(variable, _, _, _, options)
        local value = truncate(variable.value, MAX_INLINE)
        if options.virt_text_pos == "inline" then
          return " = " .. value
        end
        return variable.name .. " = " .. value
      end,
    },
  },
}
