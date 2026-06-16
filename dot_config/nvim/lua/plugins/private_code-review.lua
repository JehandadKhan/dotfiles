-- Inline code review stack.
--
-- octo.nvim itself comes from LazyVim's `util.octo` extra (enabled in
-- lazyvim.json), which wires it up against whatever picker LazyVim is
-- configured with -- fzf-lua here -- and registers the `<leader>g*`
-- keymaps. It authenticates through the `gh` CLI (provisioned by the
-- jems installer), so there is no extra auth/token setup. The review
-- flow: `:Octo pr list` -> open a PR -> `:Octo review start` -> leave
-- inline comments on lines/ranges -> `:Octo review submit`.
--
-- This file only adds diffview.nvim, which octo uses as its review UI
-- and which doubles as a standalone side-by-side diff / file-history
-- viewer for arbitrary git revisions (no PR required).

return {
  -- Label the <leader>gv group in which-key.
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>gv", group = "diffview" },
      },
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewFileHistory",
    },
    -- Everything lives under the <leader>gv ("view") group prefix:
    -- <leader>gd/gD are taken by the fzf-lua extra (git_diff) and
    -- <leader>gh is gitsigns' "hunks" group, so diffview gets its own
    -- namespace to avoid shadowing either. Keeping gv a pure group
    -- (no bare <leader>gv leaf) avoids the which-key group-vs-leaf
    -- timeout.
    keys = {
      { "<leader>gvo", "<cmd>DiffviewOpen<cr>", desc = "Diffview: open" },
      { "<leader>gvc", "<cmd>DiffviewClose<cr>", desc = "Diffview: close" },
      { "<leader>gvh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: file history (current file)" },
      { "<leader>gvH", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview: file history (branch)" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        merge_tool = { layout = "diff3_mixed" },
      },
    },
  },
}
