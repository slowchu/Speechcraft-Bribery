-- scripts/speechcraft_bribe/ui_close_on_global.lua
-- Optional tiny helper: ensure any dangling UI gets closed if dialogue ends due to global events.
local uiGlue = require("scripts/speechcraft_bribe.ui")
return {
  eventHandlers = {
    ForceCloseBribeUi = function() uiGlue.close() end,
  }
}
