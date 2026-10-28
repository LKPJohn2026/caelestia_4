# caelestia4: machine-specific env for the uwsm Hyprland session (this PC: RTX 5090 + AMD iGPU, shared with Plasma).
# Install to ~/.config/uwsm/env-hyprland.d/ (tools/uwsm-setup.sh does). Mirrors ~/.config/hypr/custom/env.lua.

# Render on the GPU that drives the monitor
export AQ_DRM_DEVICES=/dev/dri/nvidia-dgpu

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
