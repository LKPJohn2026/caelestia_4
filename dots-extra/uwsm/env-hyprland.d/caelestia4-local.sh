# caelestia4: env of the uwsm Hyprland session, yours to change: tools/uwsm-setup.sh installs it if it's missing and then
# keeps it (~/.config/uwsm/env-hyprland.d/). Mirrors ~/.config/hypr/custom/env.lua.

# Hyprland picks a GPU by itself. This is the only place that tells it, and only when the optional udev rule named the discrete one
# (system/udev/99-caelestia4-dgpu.rules) and a monitor is on it
if [ -e /dev/dri/nvidia-dgpu ]; then
    _card=$(basename "$(readlink -f /dev/dri/nvidia-dgpu)")
    for _status in /sys/class/drm/"$_card"-*/status; do
        if [ "$(cat "$_status" 2>/dev/null)" = connected ]; then
            export AQ_DRM_DEVICES=/dev/dri/nvidia-dgpu
            break
        fi
    done
    unset _card _status
fi

# fcitx5, if it's installed. GTK uses Wayland text-input natively, so GTK_IM_MODULE is deliberately unset.
if command -v fcitx5 >/dev/null 2>&1; then
    export XMODIFIERS=@im=fcitx
    export QT_IM_MODULE=fcitx
    export QT_IM_MODULES="wayland;fcitx"
    export SDL_IM_MODULE=fcitx
fi

# No KDE in XDG_CURRENT_DESKTOP since Plasma went (2026-10-28): the keys moved from KWallet to gnome-keyring
# (docs/dev/kde-removal.md, phase 3). Chromium / Electron pick their key store from it and an unknown desktop gets
# the unencrypted "basic" store, so Brave, Vesktop and Claude are given --password-store=gnome-libsecret (their
# flags files / launcher) by tools/keyring-switch.sh finish.
export XDG_CURRENT_DESKTOP=Hyprland

# Dates and times in another language than the system's (weekday / month names in the shell and this session's apps).
# The locale must be generated (locale -a).
# export LC_TIME=vi_VN.UTF-8
