-- install-lazyvim.sh: managed file (rewritten on every re-run)

return {
  {
    "3rd/image.nvim",
    -- Don't try to build the magick luarock; we use the imagemagick CLI
    -- (apt 'imagemagick' package) instead via processor = "magick_cli".
    build = false,
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "markdown", "vimwiki", "quarto" },
        },
      },
      max_width = 100,
      max_height = 12,
      max_height_window_percentage = 30,
      max_width_window_percentage = 100,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
    },
  },
}
