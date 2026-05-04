-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable format on save (override LazyVim default).
vim.g.autoformat = false

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
