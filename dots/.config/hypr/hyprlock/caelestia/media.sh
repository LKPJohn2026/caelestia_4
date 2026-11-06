#!/usr/bin/env bash
# caelestia4 hyprlock: media card (current player via playerctl)
source "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ii/scripts/caelestia4/tr.sh" 2>/dev/null || { tr_() { printf '%s' "$1"; }; tr_pad() { printf '%s  ' "$1"; }; }
status=$(playerctl status 2>/dev/null)
if [[ -z "$status" || "$status" == "Stopped" ]]; then
  printf '<span alpha="70%%">%s</span>\n' "$(tr_ "Nothing playing")"; exit 0
fi
esc() { sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }
trunc() { awk -v n=34 '{ if (length($0) > n) print substr($0, 1, n-1) "…"; else print }'; }
title=$(playerctl metadata title 2>/dev/null | trunc | esc)
artist=$(playerctl metadata artist 2>/dev/null | trunc | esc)
icon=$([[ "$status" == "Playing" ]] && echo "▶ $(tr_ "Playing")" || echo "⏸ $(tr_ "Paused")")
printf '<b>%s</b>\n<span alpha="70%%">%s</span>\n<span alpha="70%%">%s</span>\n' "${title:-$(tr_ "Unknown")}" "${artist:-}" "$icon"
