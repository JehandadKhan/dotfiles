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

### 2026-09-23 — merge upstream, capture drifted targets, apply

- **Merged** `origin/main` (`40b408f`, `2226ea1`) into 4 local nvim commits;
  `CLAUDE.md` conflicted only because both sides appended a log entry — kept
  both in date order. Pushed as `2284164`.
- **Drift found before apply.** `chezmoi status` showed `MM` on two targets
  edited in place, never in source. A plain apply would have deleted them:
  - `~/.zshrc` — pyenv init (`PYENV_ROOT`, PATH prepend, `pyenv init -`).
  - `~/.claude/settings.json` — `"tui": "fullscreen"`.
  Captured both with `chezmoi re-add`, then `chezmoi apply` (brought over the
  `drun` Python-isolation env vars, `lang.python` extra, `init.defaultBranch`).
  `chezmoi status` clean afterwards. Lesson: run `chezmoi status`/`diff`
  before every apply; `MM` means local edits that apply would clobber.

### 2026-09-23 — debugger for notebook cells (`<leader>mD`)

- **Goal.** Line-by-line debugging in molten notebooks with minimal manual
  steps (no `debugpy.listen` in cells, breakpoints in the notebook buffer).
- **Design.** nvim-dap → `dot_config/nvim/scripts/nb_dap_bridge.py` (new, a
  stdio DAP adapter) → the kernel's built-in debugger over `debug_request` on
  the control channel — the path JupyterLab uses, on the kernel molten started.
  The bridge maps notebook lines ↔ ipykernel's per-cell temp files. Full
  mechanism and traps are in the jems repo `CLAUDE.md` ("Debugging cells").
- **Files.** `lazyvim.json` (+`dap.core` extra), `private_molten.lua`
  (`debug_cell`, kernel discovery, molten iopub patch), `private_jupytext.lua`
  (new-notebook cheatsheet gains a Debug line).
- **molten patch.** Upstream molten ignores `parent_header`, so debugger
  traffic marked paused cells Done and dropped their output. Patched at
  startup (own-execute msg_id filter), reverted on Lazy update/sync/restore.
  Candidate for an upstream PR.
- **Verified in the UI** (nvim in tmux, keystrokes + screen captures):
  breakpoint in a cell-1 function hit from cell 2 with the cursor in the
  notebook buffer; locals; step; continue; molten output shown; normal run
  after terminate; re-attach; terminate while paused; edited cell with a
  breakpoint in itself. Two bugs were found this way and fixed (Done-early
  output loss; `<leader>dt` killing the kernel).
- **Not verified:** the multi-kernel `vim.ui.select` picker; Linux (`ps -A -o`
  is POSIX, expected fine).
