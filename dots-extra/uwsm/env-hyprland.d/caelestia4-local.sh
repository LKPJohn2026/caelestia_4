# caelestia4: env of the uwsm Hyprland session, yours to change: tools/uwsm-setup.sh installs it if it's missing and then
# keeps it (~/.config/uwsm/env-hyprland.d/). Mirrors ~/.config/hypr/custom/env.lua.

# Hyprland picks a GPU by itself. Told only when the optional udev rule named the discrete one
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

# fcitx5 (Vietnamese via Bamboo). GTK uses Wayland text-input natively, so GTK_IM_MODULE is deliberately unset.
export XMODIFIERS=@im=fcitx
export QT_IM_MODULE=fcitx
export QT_IM_MODULES="wayland;fcitx"
export SDL_IM_MODULE=fcitx

# No KDE in XDG_CURRENT_DESKTOP since Plasma went (2026-10-28): the keys moved from KWallet to gnome-keyring
# (docs/dev/kde-removal.md, phase 3). Chromium / Electron pick their key store from it and an unknown desktop gets
# the unencrypted "basic" store, so Brave, Vesktop and Claude are given --password-store=gnome-libsecret (their
# flags files / launcher) by tools/keyring-switch.sh finish.
export XDG_CURRENT_DESKTOP=Hyprland

# Dates and times in Vietnamese (weekday / month names in the shell, end-4 widgets and apps of this session).
# /etc/locale.conf sets every LC_* except LANG to en_US; only the time format changes here, numbers etc. stay en_US.
export LC_TIME=vi_VN.UTF-8
