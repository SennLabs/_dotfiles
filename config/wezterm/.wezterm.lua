-- Pull in the wezterm API
local wezterm = require 'wezterm'
local act = wezterm.action
-- This will hold the configuration.
local config = wezterm.config_builder()


-- OS specific settings.
-- target_triple is wezterm's own build target, which is a reliable OS check.
-- Sniffing $HOME is not: Git Bash and MSYS set it on Windows too.
if wezterm.target_triple:find('windows') then
  config.default_prog = { 'pwsh.exe', '-NoLogo' }
else
  -- Resolved via PATH on purpose: bash is /bin/bash on Debian/Ubuntu and
  -- /usr/bin/bash on Fedora, and a hardcoded path fails to launch on one of them.
  config.default_prog = { 'bash', '-l' }
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
    key = 'c',
    mods = 'CTRL',
    action = wezterm.action_callback(function(window, pane)
      local has_selection = window:get_selection_text_for_pane(pane) ~= ''
      if has_selection then
        window:perform_action(act.CopyTo 'ClipboardAndPrimarySelection', pane)
        window:perform_action(act.ClearSelection, pane)
      else
        window:perform_action(act.SendKey{key='c', mods='CTRL'}, pane)
      end
    end),
  },
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
