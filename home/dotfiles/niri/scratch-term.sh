#!/usr/bin/env bash
# Hyprland-style scratch terminal for niri (bound to Mod+Slash in config.kdl).
# Slides a full-height kitty in/out of the right edge, like the DMS notepad.
#
# niri will not move a floating window more than ~75 px off-screen, so a plain
# move can never slide fully out. Instead, hide *closes* the kitty window and
# show opens a fresh one; niri's window-open/window-close animations (custom
# shaders in config.kdl) do the slide. The shell survives because it lives in
# a tmux session ("scratch") that each new kitty simply re-attaches to.
set -eu

app=scratch-term

# niri's window JSON objects are flat up to "layout", so splitting on '{'
# leaves the fields we need on one line (no jq on this box).
win=$(niri msg -j windows | tr '{' '\n' | grep "\"app_id\":\"$app\"" || true)

if [ -z "$win" ]; then
    setsid -f kitty --class "$app" -e tmux new-session -A -s scratch >/dev/null 2>&1
elif printf '%s' "$win" | grep -q '"is_focused":true'; then
    niri msg action close-window --id "$(printf '%s' "$win" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)"
else
    # Open but not focused (maybe on another workspace): just go to it.
    niri msg action focus-window --id "$(printf '%s' "$win" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)"
fi
