# chezmoi dotfiles

Source directory for [chezmoi](https://chezmoi.io)-managed dotfiles. Files here
are deployed into `$HOME` with chezmoi's naming conventions:

- `dot_foo` → `~/.foo`
- `private_dot_foo` → `~/.foo` with `0600` permissions
- `*.tmpl` → rendered as a Go template before deployment
- `.chezmoiignore` → paths chezmoi must not deploy (uses *target* names, e.g.
  `.config/nvim/...`, not source names)

## Layout

| Path | Target | Notes |
| --- | --- | --- |
| `dot_claude/` | `~/.claude/` | Claude Code config. `dot_claude/CLAUDE.md` is the **global** instruction file loaded into every project — behavioral rules only, never session logs. |
| `dot_config/nvim/` | `~/.config/nvim/` | LazyVim-based Neovim config. `lazy-lock.json` is chezmoi-ignored so lazy.nvim owns it per machine. |
| `dot_gitconfig` | `~/.gitconfig` | |
| `dot_tmux.conf` | `~/.tmux.conf` | |
| `dot_zshrc` | `~/.zshrc` | |
| `private_dot_bashrc.tmpl` | `~/.bashrc` | Templated, mode `0600`. |

`CLAUDE.md` (this file) is listed in `.chezmoiignore` so it stays repo
documentation and is not deployed to `~/CLAUDE.md`.

## Progress log

### 2026-09-20 — reconcile diverged main, fix moved remote

- **Diverged branch.** `main` was 1 commit ahead / 2 behind `origin/main`.
  Checked with `git merge-tree --write-tree`: **no conflicts** — the two sides
  touched entirely disjoint files.
  - Local: `86be5cc` *fix gh helper, updated lazy vim repo names* —
    `dot_config/nvim/lua/plugins/extend-mini-files.lua`,
    `dot_config/nvim/lua/plugins/private_terraform.lua`, `dot_gitconfig`
  - Remote: `03b01a0` *enable python LSP in nvim*, `4f96e94` *fix venv failure
    due to mounting home directory in docker, add safe dirs to git*
- **Rebased** local onto `origin/main` (chosen over merge for linear history).
  Clean; local commit rewritten `86be5cc` → `ddaf7a5`.
- **Pushed** `main` to origin (`03b01a0..ddaf7a5`), with explicit approval.
- **Remote had moved.** GitHub returned `This repository moved` — the push
  succeeded via redirect. Updated the URL to match the new capitalization:
  ```
  git remote set-url origin https://github.com/JehandadKhan/dotfiles.git
  ```
  (was `.../jehandadkhan/dotfiles.git`). Verified with a fetch; `main` in sync.

### 2026-09-22 — default branch for new repos, remote URL capitalization

- **`init.defaultBranch`.** Was unset globally and absent from `dot_gitconfig`,
  so `git init` fell back to `master` with a hint. Added to `dot_gitconfig`:
  ```
  [init]
      defaultBranch = main
  ```
  Applied with `chezmoi apply ~/.gitconfig`; verified
  `git config --global --get init.defaultBranch` → `main`. Affects new repos
  only; existing repos keep their current branch names.
- **Committed and pushed** `40b408f` *git: default new repos to main branch*
  (`b3d295f..40b408f`), with explicit approval.
- **Remote URL corrected** to `git@github.com:JehandadKhan/dotfiles.git`.
- **Correction to the 2026-09-20 entry above.** That entry states the remote was
  set to `https://github.com/JehandadKhan/dotfiles.git`. This clone's remote was
  in fact still the original clone URL, `git@github.com:jehandadkhan/dotfiles.git`
  — SSH, not HTTPS, and lowercase. The reflog shows that string as the `clone:`
  source from 2026-05-07, unchanged since. So the `set-url` described on 09-20
  either ran in a different clone or was logged without being run; git keeps no
  record of `set-url`, so the two cannot be told apart after the fact. Nothing
  reverted it. Pushes worked throughout via GitHub's rename redirect, so the
  capitalization was cosmetic.
- **Note:** pushes here use SSH, so the `gh auth git-credential` helper in
  `dot_gitconfig` (HTTPS-only) is not exercised by them.
