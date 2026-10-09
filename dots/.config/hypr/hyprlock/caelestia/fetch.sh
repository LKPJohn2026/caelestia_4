#!/usr/bin/env bash
# caelestia4 hyprlock: system card (like Caelestia's lock "Fetch")
. /etc/os-release
printf '<b>%s@%s</b>\n' "$USER" "$(hostname)"
printf '<span alpha="70%%">OS</span>      %s\n' "$PRETTY_NAME"
printf '<span alpha="70%%">Kernel</span>  %s\n' "$(uname -r)"
printf '<span alpha="70%%">WM</span>      Hyprland\n'
printf '<span alpha="70%%">Uptime</span>  %s\n' "$(uptime -p | sed 's/^up //')"
