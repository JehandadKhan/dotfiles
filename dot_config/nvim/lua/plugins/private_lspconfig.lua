-- install-lazyvim.sh: managed file (rewritten on every re-run)

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
      },
    },
  },
}
