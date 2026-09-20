-- PDF viewing in nvim, via pdfreader.nvim (rendered pages + a text mode).
--
-- install.sh installs poppler (macOS) / poppler-utils (Linux), which
-- supplies pdftotext + pdfinfo + pdftoppm. ImageMagick (`magick`) and
-- ghostscript come from the same step (gs arrives as an imagemagick
-- dependency; IM needs it for its PDF delegate). Nothing else to install.
--
-- Rendered mode gives you the real page: figures, tables, layout, and
-- scanned PDFs (which pure text extraction can't read at all, since
-- there's no text layer). `:PDFReader setViewMode text` switches to
-- extracted text when you'd rather search and yank.
--
-- Use kitty. Rendering needs the Kitty graphics protocol *plus* its
-- unicode-placeholder extension, which anchors images to text-grid cells
-- so the terminal clips them; kitty and ghostty have it, wezterm does
-- not (placeholders = false in snacks/image/terminal.lua) and pages get
-- painted over the statusline and splits there.
--
-- Why the is_supported_terminal override: pdfreader's validation.lua
-- hardcodes `{ "kitty", "ghostty" }` and string-matches $TERM, then
-- silently forces text mode on a miss. Inside tmux that check fails even
-- in kitty, because $TERM is tmux-256color, not xterm-kitty. But the
-- plugin renders through folke/snacks.nvim, whose own terminal table has
-- a proper tmux entry that wraps escapes in the \ePtmux; passthrough and
-- runs `tmux set -p allow-passthrough all` itself. So pdfreader's gate
-- is strictly narrower than the renderer behind it. Rather than fork the
-- plugin (lazy.nvim would clobber the edit on the next update) we
-- replace the function and delegate to snacks, so this keeps working as
-- snacks adds terminals instead of pinning a second stale allowlist.
-- Upstream fix is a one-line PR to that table.
--
-- NB: pdfreader owns `BufEnter *.pdf` internally. Don't add a separate
-- BufReadCmd *.pdf autocmd for text extraction — two handlers on the
-- same buffer fight over its contents. Use the plugin's text view mode.

return {
  -- pdfreader renders via snacks.image, which LazyVim ships but leaves
  -- off by default (snacks.config.image.enabled is nil out of the box).
  --
  -- snacks.image also claims *.pdf itself: it lists "pdf" in its own
  -- supported formats and installs a `BufReadCmd *.pdf` that converts the
  -- file into a snacks preview buffer (filetype becomes markdown). That
  -- races pdfreader for the same file — and snacks wins, since its
  -- BufReadCmd fires at read time. The result looks like it works (pages
  -- render, because snacks renders them) but no pdfreader keymap is ever
  -- attached, so `n` stays Vim's next-match and errors with
  -- "E486: Pattern not found". Strip pdf from snacks' format list so it
  -- keeps doing the drawing for pdfreader without also hijacking the
  -- buffer.
  {
    "folke/snacks.nvim",
    opts = {
      image = {
        enabled = true,
        -- snacks' default list (lua/snacks/image/init.lua) minus "pdf".
        -- It builds its BufReadCmd pattern straight from this table, so
        -- dropping pdf is what keeps it off *.pdf buffers. If a snacks
        -- update adds a format, add it here too.
        formats = {
          "png",
          "jpg",
          "jpeg",
          "gif",
          "bmp",
          "webp",
          "tiff",
          "heic",
          "avif",
          "mp4",
          "mov",
          "avi",
          "mkv",
          "webm",
          "icns",
        },
      },
    },
  },
  {
    "r-pletnev/pdfreader.nvim",
    -- Must be loaded before the PDF buffer is read, not after: the plugin
    -- installs its `BufEnter *.pdf` autocmd (and the n/p/z/q/e keymaps)
    -- inside setup(). `event = "VeryLazy"` is too late — it fires after
    -- the file is already open, so the autocmd misses the first BufEnter
    -- and no keymap is bound. `cmd = "PDFReader"` is likewise too late.
    lazy = false,
    dependencies = { "folke/snacks.nvim", "nvim-telescope/telescope.nvim" },
    config = function()
      local validation = require("pdfreader.validation")
      validation.is_supported_terminal = function()
        local ok, env = pcall(function()
          return require("snacks.image.terminal").env()
        end)
        -- On error, say yes and let snacks decide at draw time rather
        -- than silently downgrading to text mode.
        if not ok or type(env) ~= "table" then
          return true
        end
        return env.supported ~= false
      end
      require("pdfreader").setup({})
    end,
  },
}
