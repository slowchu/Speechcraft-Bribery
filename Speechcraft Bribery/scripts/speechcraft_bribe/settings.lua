local M = {}

-- Mod namespace (used for settings page key, storage, etc.)
M.mod = "speechcraft_bribe"
M.l10n = "SpeechcraftBribe"

-- Records / constants
M.goldRecordId = "gold_001"

-- Input
M.hotkeyName = "speechcraft_bribe_open"
M.hotkeyName_L10N = "hotkey_bribe_open_name"
M.hotkeyDesc_L10N = "hotkey_bribe_open_desc"

-- Tries & cooldown
M.triesMax = 3
M.cooldownHours = 24

-- Inflation
M.inflationStart = 1.0
M.inflationCap   = 2.5 -- hard cap
M.inflationAddSuccess = 0.05
M.inflationAddCritical = 0.10
M.inflationDecayPerDay = 0.0 -- set > 0 to allow slow decay, 0 disables

-- Requirement formula
M.baseFloor = 25                 -- constant floor
M.diffWeight = 2.25              -- how much stat delta matters
M.closeNoTry = true              -- close zone does not consume tries

-- Threshold ratios (offer / requirement)
M.thresholds = {
  insulting = 0.50,  -- [0, insulting)
  low       = 0.85,  -- [insulting, low)
  close     = 0.99,  -- [low, close]
  success   = 1.15,  -- (1.0, success]
  critical  = 1.30,  -- (success, critical]
  -- > critical is overpay
}

-- Disposition deltas
M.disposition = {
  insulting = -1,
  low = 0,
  close = 0,
  success = 5,
  critical = 10,
  overpay = 6, -- slightly less than critical, diminishing returns
}

-- UI behavior
M.showMsgInDialogue = true

return M
