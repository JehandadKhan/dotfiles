-- install-lazyvim.sh: managed file (rewritten on every re-run)

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
      { "<leader>mi", ":MoltenInit<CR>",                       desc = "Molten: init kernel" },
      { "<leader>me", ":MoltenEvaluateOperator<CR>",           desc = "Molten: eval operator" },
      { "<leader>ml", ":MoltenEvaluateLine<CR>",               desc = "Molten: eval line" },
      { "<leader>mr", ":MoltenReevaluateCell<CR>",             desc = "Molten: re-eval cell" },
      { "<leader>mv", ":<C-u>MoltenEvaluateVisual<CR>gv",      desc = "Molten: eval selection", mode = "v" },
      { "<leader>mo", ":noautocmd MoltenEnterOutput<CR>",      desc = "Molten: enter output" },
      { "<leader>mh", ":MoltenHideOutput<CR>",                 desc = "Molten: hide output" },
      { "<leader>md", ":MoltenDelete<CR>",                     desc = "Molten: delete cell" },
    },
  },
}
