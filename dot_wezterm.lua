local wezterm = require("wezterm")

local config = {}
if wezterm.config_builder then
   config = wezterm.config_builder()
end

config.font = wezterm.font("UbuntuMono Nerd Font Mono")
config.font_size = 16.0

config.window_decorations = "RESIZE"
config.color_scheme = "Catppuccin Mocha"

return config