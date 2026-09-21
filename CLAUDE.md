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

### 2026-09-21 — default 2-space indentation in nvim

- **Goal.** Two spaces for new files in Neovim.
- **`lua/config/options.lua`** — set `expandtab`/`shiftwidth`/`tabstop`/
  `softtabstop` explicitly. These are global defaults; mostly they just pin
  what LazyVim already did, so on their own they changed nothing observable.
- **`lua/config/autocmds.lua`** — the actual fix. Bundled ftplugins
  (`ftplugin/python.vim`, rust) run *after* `options.lua` and set
  **buffer-local** values, which beat globals. A `FileType` autocmd
  (augroup `indent_two_spaces`, patterns `python`, `rust`) re-applies 2
  spaces after them. **Go is excluded on purpose** — gofmt requires real
  tabs, so forcing spaces there would fight the formatter on every save.
- **Testing gotcha.** `nvim --headless` does **not** source
  `lua/config/autocmds.lua`: LazyVim loads it on `VeryLazy`, which fires off
  `UIEnter`, and that never happens headless. A headless probe reported
  `registered=0` and `sw=4`, which looks like the config is broken but is a
  probe artifact. Verify with a real TTY instead:
  `script -q /dev/null nvim -c "lua ..." file.py`
- **Verified** (real TTY): python/rust `sw=2 ts=2 sts=2 et=true`; go still
  `sw=0 ts=2 et=false`; lua/js/ts/md/json/yaml/sh/c already at 2, unchanged.
- **Note.** The deployed `~/.config/nvim/lua/config/options.lua` had been
  stale — missing the committed `vim.g.lazyvim_python_lsp = "basedpyright"`
  line. `chezmoi apply` brought it over along with this change.
