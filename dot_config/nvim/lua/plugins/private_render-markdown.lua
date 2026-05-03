-- install-lazyvim.sh: managed file (rewritten on every re-run)

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
    ft = { "markdown", "quarto" },
    opts = {
      file_types = { "markdown", "quarto" },
      completions = { lsp = { enabled = true } },
    },
  },
}
