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
-- This file adds diffview.nvim (which octo uses as its review UI and
-- which doubles as a standalone side-by-side diff / file-history viewer
-- for arbitrary git revisions, no PR required), plus one octo.nvim opts
-- override.
--
-- octo scope workaround: octo's PR/issue GraphQL queries pull in
-- Projects-v2 fields by default, which the GitHub API only returns when
-- the `gh` token carries the `read:project` scope. The token the jems
-- installer provisions (via `gh auth login`) has repo/read:org/workflow/
-- gist but not read:project, so without this octo errors with
-- "Your token has not been granted the required scopes ... ['read:project']".
-- Two flags are needed, because LazyVim's util.octo extra sets
-- `default_to_projects_v2 = true`, which steers octo down the Projects-v2
-- codepath that requires read:project regardless of suppression:
--   * default_to_projects_v2 = false -- override the extra so octo does
--     not default to the v2 path (LazyVim deep-merges table opts, so this
--     wins over the extra's `true`).
--   * suppress_missing_scope.projects_v2 = true -- belt-and-suspenders:
--     drop the v2 fields from queries if anything still requests them.
-- Together the existing token scopes (repo/read:org/workflow/gist)
-- suffice -- no PAT, no re-auth. The tradeoff is the `Octo card*`
-- (Projects v2) commands won't work; PR review / comments / approvals do.

return {
  -- Keep octo off the Projects-v2 path so a token without the
  -- read:project scope works (see header comment).
  {
    "pwntester/octo.nvim",
    opts = {
      default_to_projects_v2 = false,
      suppress_missing_scope = {
        projects_v2 = true,
      },
    },
  },
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
