return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {

      cmd = {
        "clangd",
        "--all-scopes-completion",
        "--background-index",
        "--clang-tidy",
        "--compile_args_from=filesystem", -- lsp-> does not come from compie_commands.json
        "--completion-parse=always",
        "--completion-style=bundled",
        "--cross-file-rename",
        "--debug-origin",
        "--enable-config", -- clangd 11+ supports reading from .clangd configuration file
        "--fallback-style=Qt",
        "--folding-ranges",
        "--function-arg-placeholders",
        "--header-insertion=iwyu",
        "--pch-storage=memory", -- could also be disk
        "--suggest-missing-includes",
        "-j=4", -- number of workers
        -- "--resource-dir="
        "--log=error",
        --[[ "--query-driver=/usr/bin/g++", ]]
      },
      filetypes = { "c", "cpp", "objc", "objcpp" },
      single_file_support = true,
      init_options = {
        compilationDatabasePath = vim.fn.getcwd() .. "/build",
      },
      commands = {},
    },
  },
}
