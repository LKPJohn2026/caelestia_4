#!/usr/bin/env bash
# caelestia4 hyprlock: system card (like Caelestia's lock "Fetch")
. /etc/os-release
printf '<b>%s@%s</b>\n' "$USER" "$(hostname)"
printf '<span alpha="70%%">HĐH</span>      %s\n' "$PRETTY_NAME"
printf '<span alpha="70%%">Nhân</span>     %s\n' "$(uname -r)"
printf '<span alpha="70%%">WM</span>      Hyprland\n'
printf '<span alpha="70%%">Đã chạy</span>  %s\n' "$(awk '{ s = int($1); d = int(s / 86400); h = int(s % 86400 / 3600); m = int(s % 3600 / 60); out = (d ? d " ngày " : "") (h ? h " giờ " : "") m " phút"; print out }' /proc/uptime)"
