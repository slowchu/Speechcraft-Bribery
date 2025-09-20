-- Settings UI: binds the trigger into Options > Scripts page.
local I = require('openmw.interfaces')
local settings = require('scripts.speechcraft_bribe.settings')

local pageKey = settings.mod .. ".page"
local groupControls = settings.mod .. ".controls"

I.Settings.registerPage {
  key = pageKey,
  l10n = settings.l10n,
  name = "Speechcraft Bribe",
  description = "Configure the Speechcraft Bribery Minigame.",
}

I.Settings.registerGroup {
  key = groupControls,
  page = pageKey,
  l10n = settings.l10n,
  name = "Controls",
  description = "Hotkeys and input.",
}

I.Settings.registerSetting {
  key = settings.mod .. ".bribe_hotkey",
  page = pageKey,
  group = groupControls,
  l10n = settings.l10n,
  name = "Bribe hotkey",
  description = "Press during dialogue to open the bribe window.",
  default = "", -- must be a string for inputBinding
  renderer = "inputBinding",
  argument = {
    type = "trigger",
    key = settings.hotkeyName,
  },
}
