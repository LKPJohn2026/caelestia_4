# shellcheck shell=bash
# caelestia4: sourced by the tools that install into the config. The desktop's own files look in ~/.config (Hyprland's Lua
# config, hyprlock's includes): anywhere else it wouldn't start, or a tool would stop halfway.
if [[ -n "${XDG_CONFIG_HOME:-}" && "$(realpath -m -- "$XDG_CONFIG_HOME")" != "$(realpath -m -- "$HOME/.config")" ]]; then
  echo "XDG_CONFIG_HOME is $XDG_CONFIG_HOME: this desktop only works with its config in ~/.config. Nothing was changed." >&2
  echo "Unset it for this command and for the session (or make it point at ~/.config), then run this again." >&2
  exit 1
fi
