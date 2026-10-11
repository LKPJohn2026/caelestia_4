# caelestia4: machine-specific env for the uwsm Hyprland session (this PC: RTX 5090 + AMD iGPU, shared with Plasma).
# Install to ~/.config/uwsm/env-hyprland.d/ (tools/uwsm-setup.sh does). Mirrors ~/.config/hypr/custom/env.lua.

# Render on the GPU that drives the monitor
export AQ_DRM_DEVICES=/dev/dri/nvidia-dgpu

# fcitx5 (Vietnamese via Bamboo). GTK uses Wayland text-input natively, so GTK_IM_MODULE is deliberately unset.
export XMODIFIERS=@im=fcitx
export QT_IM_MODULE=fcitx
export QT_IM_MODULES="wayland;fcitx"
export SDL_IM_MODULE=fcitx

# Chromium/Electron pick their key store from XDG_CURRENT_DESKTOP: with KDE in the list they use KWallet like in
# Plasma, so switching sessions doesn't log apps out. uwsm set it to "Hyprland" from the session entry before this
# file runs. NOTE: with KDE in the list, XDG autostart's OnlyShowIn=KDE entries (plasmashell, powerdevil, …) would
# match, which is why tools/uwsm-setup.sh masks XDG autostart for this compositor.
export XDG_CURRENT_DESKTOP=Hyprland:KDE
export KDE_SESSION_VERSION=6
