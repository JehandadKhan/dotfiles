#!/usr/bin/env bash
# Claude Code Stop/Notification hook (wired in ~/.claude/settings.json).
# Rings the bell in the tmux pane running this Claude session — tmux then
# flags that window in the status bar (window-status-bell-style in
# ~/.tmux.conf) and forwards the bell to the terminal — and flashes a
# message naming the pane. No-op outside tmux.
#   $1 = what happened ("done", "needs input")
[ -z "$TMUX_PANE" ] && exit 0
tty=$(tmux display -p -t "$TMUX_PANE" '#{pane_tty}') || exit 0
printf '\a' > "$tty"
tmux display-message -t "$TMUX_PANE" -d 4000 "Claude ${1:-done}: #S:#I.#P ($(basename "$PWD"))"
exit 0
