---
name: project-status
description: Status update for projects tracked in the Obsidian vault (Projects/*.md), built from each project's linked code repo (git log, CLAUDE.md, TODO.md), its GitHub repos (PRs, issues) and the daily notes. Use when the user asks for a project status, progress update, weekly or biweekly summary of a workstream, "what happened on X", or wants to link or unlink a repo to a project.
argument-hint: "<project | all> [days]"
---

# Project status

The vault is `/mnt/c/Users/jkhan/Documents/Obsidian Vault`. A note in `Projects/` is a code project only when its frontmatter links code:

- `repo:` is the local clone in WSL (`~/repos/...`).
- `remotes:` lists the GitHub repos where the work happens.
- `remote_filter:` (optional) adds GitHub search qualifiers for busy upstream repos, e.g. `label:"AMD GPU"`.

Directories in `~/repos` that no note links are not projects. Ignore them.

## Steps

1. **Arguments.** Project: a note name, a repo dir name, a unique part of a name, or `all`. If none is given, use the linked project for the current repo; if there isn't one, ask. Window: days, default 14 ("2w" means 14).
2. **Facts in one call:**
   - one project: `vault-sync report "<project>" --days <N> --fetch`
   - all: `vault-sync report --all --days <N> --fetch`

   The report prints:
   - the note's description and Notes section
   - local repo state, CLAUDE.md/TODO.md status sections and commits in the window
   - PRs merged on GitHub in the window, plus the state of issue/PR links written in the note
   - daily-note lines that mention the project, with their standup owner

   If it says no linked project matches, run `vault-sync list` and ask the user what to link (see Linking).
3. **Go deeper only where the report is thin:** read the repo's CLAUDE.md or TODO.md in full, use `gh pr view <url>` for a PR, or open a daily note.
4. **Write the update in chat:**
   - One headline line with the overall state.
   - Then **Done**, **In flight**, **Blocked / decisions needed** and **Next** as bullets. Give each bullet an owner (first name, as in the vault) and a source: a PR/issue URL or `[[YYYY-MM-DD]]`.
   - For `all`, write one short block per project. For a multi-day team summary, use the format in the vault's CLAUDE.md (one line per workstream with owners).
   - Use only facts from the report. When a source had nothing in the window, say so.
   - Don't count automated commits as team work: upstream syncs on forks (e.g. ROCm/maxtext `rocm-main`) and bot bump PRs.
5. **Don't write the update into the vault unless the user asks.** If they do, put it under a dated heading in the project note's `## Notes` section, or in today's daily note. Never put it between `vault-sync` markers. Never write task checkbox syntax. Refresh the synced blocks with `vault-sync --repo "<project>" --remotes`.

## Linking

Ask the user before you link or unlink anything, and confirm the note name and remotes.

- `vault-sync list` shows linked notes and the repos under `~/repos` that no note links.
- `vault-sync link ~/repos/<dir> [--note "<Note name>"] [--remote OWNER/REPO ...] [--filter '<qualifiers>']` links a local repo. It creates the note if needed and syncs it.
- `vault-sync link --note "<Note name>" --remote OWNER/REPO` links a team project that has no local clone.
- `vault-sync unlink "<Note name>" [--remotes]` removes a link.
