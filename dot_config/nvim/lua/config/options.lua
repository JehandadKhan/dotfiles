-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable format on save (override LazyVim default).
vim.g.autoformat = false

-- Use basedpyright as the Python LSP instead of LazyVim's default `pyright`.
-- jems/install.sh installs basedpyright globally (and removes any stray
-- pyright); the lang.python extra picks up this var when it builds its
-- server table, enabling only the selected LSP (so pyright stays off and
-- there are no duplicate diagnostics). This must live here, not in a
-- plugin spec: the extra reads vim.g.lazyvim_python_lsp at spec-collection
-- time, which runs before plugin/*.lua files, so setting it in a plugin
-- spec is too late. See lua/plugins/private_python.lua for the Mason side.
vim.g.lazyvim_python_lsp = "basedpyright"

-- Point nvim at the dedicated venv so pynvim / jupyter_client are resolvable
-- (required for molten-nvim's :MoltenInit). The venv is created by
-- jems/install-lazyvim.sh at this exact path.
vim.g.python3_host_prog = vim.fn.expand("$HOME/.local/share/nvim-venv/bin/python")

-- macOS only: brew imagemagick ships zero registered fonts, which makes
-- image.nvim's SVG->PNG conversion fail with `unable to read font ''`.
-- Our user-level type.xml at ~/.config/ImageMagick-7/type.xml fills the
-- gap; this env var tells magick to read it. Setting it inside nvim
-- means image.nvim's spawned magick subprocesses inherit it regardless
-- of how nvim was launched.
if vim.fn.has("mac") == 1 then
  local brew_prefix = vim.fn.isdirectory("/opt/homebrew") == 1
    and "/opt/homebrew"
    or "/usr/local"
  vim.env.MAGICK_CONFIGURE_PATH = vim.fn.expand("$HOME/.config/ImageMagick-7")
    .. ":" .. brew_prefix .. "/etc/ImageMagick-7"
end
