#!/usr/bin/env bash
# caelestia4 hyprlock: media card (current player via playerctl)
status=$(playerctl status 2>/dev/null)
if [[ -z "$status" || "$status" == "Stopped" ]]; then
  echo '<span alpha="70%">Nothing playing</span>'; exit 0
fi
esc() { sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }
trunc() { awk -v n=34 '{ if (length($0) > n) print substr($0, 1, n-1) "…"; else print }'; }
title=$(playerctl metadata title 2>/dev/null | trunc | esc)
artist=$(playerctl metadata artist 2>/dev/null | trunc | esc)
icon=$([[ "$status" == "Playing" ]] && echo "▶" || echo "⏸")
printf '<b>%s</b>\n<span alpha="70%%">%s</span>\n<span alpha="70%%">%s %s</span>\n' "${title:-Unknown}" "${artist:-}" "$icon" "$status"
