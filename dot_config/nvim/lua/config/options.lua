-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here






-- >>> install-lazyvim.sh managed block (do not edit between markers)
-- Disable format on save (override LazyVim default)
vim.g.autoformat = false

-- Point nvim at the dedicated venv so pynvim / jupyter_client are resolvable
-- (required for molten-nvim's :MoltenInit).
vim.g.python3_host_prog = "/Users/jehandad/.local/share/nvim-venv/bin/python"

-- macOS only: brew imagemagick ships zero registered fonts, which makes
-- image.nvim's SVG->PNG conversion fail. Our type.xml at
-- ~/.config/ImageMagick-7 fills the gap; this env var tells magick to
-- read it. Set inside nvim so child processes inherit regardless of
-- launch path (shell, GUI, etc.).
vim.env.MAGICK_CONFIGURE_PATH = "/Users/jehandad/.config/ImageMagick-7:/opt/homebrew/etc/ImageMagick-7"
-- <<< install-lazyvim.sh managed block
