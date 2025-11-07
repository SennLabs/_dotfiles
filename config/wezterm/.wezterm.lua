-- Pull in the wezterm API
local wezterm = require 'wezterm'
local act = wezterm.action
-- This will hold the configuration.
local config = wezterm.config_builder()


-- OS Specific settings
-- Unix/Linux
local HomePath = os.getenv("HOME")
if HomePath then
  --config.default_prog = { '/usr/bin/bash', '-l' }
end

-- Windows
local WinDir = os.getenv("windir")
if WinDir then
  config.default_prog = { 'pwsh.exe', '-NoLogo' }
end




-- For example, changing the initial geometry for new windows:
--config.initial_cols = 120
--config.initial_rows = 28

-- or, changing the font size and color scheme.
--config.font_size = 10
config.color_scheme = 'Andromeda'
-- config.color_scheme = 'Blazer'
-- config.color_scheme = 'Dracula'
-- config.color_scheme = 'Firewatch'
-- config.color_scheme = 'FishTank'


config.keys = {
  {
    key = 'v',
    mods = 'CTRL',
    action = act.PasteFrom("Clipboard"),
  },
  {
    key = 'n',
    mods = 'CTRL',
    action = act.SpawnTab("DefaultDomain"),
  },

}


config.mouse_bindings = {
    {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelection 'ClipboardAndPrimarySelection',
    },
    {
    event={Up={streak=1, button="Right"}},
    mods="ALT",
    action= act.CopyTo("Clipboard"),
    },
    {
    event={Up={streak=1, button="Left"}},
    mods="ALT",
    action= act.PasteFrom("Clipboard"),
    },

}






-- Finally, return the configuration to wezterm:
return config