-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Force 2-space indentation for filetypes whose bundled ftplugin sets
-- something else (python -> sw=4, rust -> sw=4). Those ftplugins run after
-- lua/config/options.lua and set buffer-local values, which beat the global
-- defaults, so the override has to happen on FileType. Go is deliberately
-- excluded: gofmt requires real tabs.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("indent_two_spaces", { clear = true }),
  pattern = { "python", "rust" },
  callback = function()
    vim.bo.expandtab = true
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
    vim.bo.softtabstop = 2
  end,
})
