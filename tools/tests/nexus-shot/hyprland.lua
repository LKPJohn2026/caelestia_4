-- caelestia4 Nexus screenshots: the test compositor's whole config (run.sh fills in the mode)
hl.monitor({ output = "", mode = "@MODE@@60", position = "0x0", scale = 1 })
hl.config({
  misc = { disable_hyprland_logo = true, disable_splash_rendering = true, disable_xdg_env_checks = true },
  xwayland = { enabled = false },
  ecosystem = { no_update_news = true },
  animations = { enabled = false },
})
-- as dots/.config/hypr/hyprland/rules.lua
hl.window_rule({match = {class = "^(org.quickshell)$", title = "^(Nexus — .*)$" }, float = true})
hl.window_rule({match = {class = "^(org.quickshell)$", title = "^(Nexus — .*)$" }, center = true})
