-- install.sh: terraform CLI + terraformls + tflint are installed via
-- system package manager (apt/hashicorp on Linux, brew on macOS), not
-- Mason. Match the clangd pattern in private_lspconfig.lua so Mason
-- doesn't shadow them.
--
-- Treesitter on jammy: the upstream tree-sitter CLI (the one Mason and
-- npm's tree-sitter-cli both ship) links against glibc 2.39+, which
-- Ubuntu 22.04 (glibc 2.35) doesn't have. Compiling parsers from
-- source via rustup also fails on jammy because current tree-sitter-cli
-- transitive deps need cargo 1.85+. Rather than fight that, drop hcl
-- and terraform from the treesitter `ensure_installed` list and pull
-- in `hashivim/vim-terraform` for pure-vimscript syntax highlighting
-- and formatting on `.tf` / `.hcl` files. terraformls still handles
-- LSP; tflint still handles linting via the LazyVim extra; vim-
-- terraform fills the highlighting gap with no compilation needed.

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        terraformls = {
          mason = false,
        },
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      for i = #opts.ensure_installed, 1, -1 do
        if opts.ensure_installed[i] == "tflint" then
          table.remove(opts.ensure_installed, i)
        end
      end
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      for i = #opts.ensure_installed, 1, -1 do
        if opts.ensure_installed[i] == "hcl" or opts.ensure_installed[i] == "terraform" then
          table.remove(opts.ensure_installed, i)
        end
      end
      opts.ignore_install = opts.ignore_install or {}
      table.insert(opts.ignore_install, "hcl")
      table.insert(opts.ignore_install, "terraform")
    end,
  },
  {
    "hashivim/vim-terraform",
    ft = { "terraform", "hcl", "terraform-vars" },
  },
}
