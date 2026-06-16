-- chezmoi-managed; the jems install.sh does not touch this file.
--
-- `octo` is included so render-markdown renders octo.nvim's PR/issue and
-- review buffers (their filetype is `octo`, and the util.octo extra
-- registers the markdown treesitter parser for it). Without `octo` in
-- both `ft` (so lazy.nvim loads the plugin for octo buffers) and
-- `file_types` (so render-markdown actually renders them), GitHub
-- markdown in octo shows up raw.

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
    ft = { "markdown", "quarto", "octo" },
    opts = {
      file_types = { "markdown", "quarto", "octo" },
      completions = { lsp = { enabled = true } },
    },
  },
}
