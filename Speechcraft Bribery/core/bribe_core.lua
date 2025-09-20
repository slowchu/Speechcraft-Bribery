-- Core, pure Lua (no OpenMW requires).
-- Responsible only for math and zone classification.
local settings = require('scripts.speechcraft_bribe.settings')

local Core = {}

local clamp = function(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

-- playerStats/npcStats: { speechcraft, mercantile, personality }
-- inflation >= 1.0
function Core.computeRequirement(playerStats, npcStats, inflation)
  local diff = {
    speechcraft = (npcStats.speechcraft or 0) - (playerStats.speechcraft or 0),
    mercantile  = (npcStats.mercantile or 0)  - (playerStats.mercantile or 0),
    personality = (npcStats.personality or 0) - (playerStats.personality or 0),
  }
  -- Weighted sum; speechcraft/mercantile matter most, personality moderate
  local difficulty = 0.5 * math.max(0, diff.personality)
                    + 1.0 * math.max(0, diff.mercantile)
                    + 1.2 * math.max(0, diff.speechcraft)

  local base = settings.baseFloor + settings.diffWeight * difficulty
  base = base * (inflation or 1.0)
  return math.max(base, 1)
end

-- Returns zone string
local function classifyRatio(ratio, th)
  if ratio < th.insulting then return 'insulting' end
  if ratio < th.low       then return 'low' end
  if ratio <= th.close    then return 'close' end -- <= 0.99
  if ratio <= th.success  then return 'success' end
  if ratio <= th.critical then return 'critical' end
  return 'overpay'
end

-- Evaluate an attempt.
-- Inputs: offer (>=0), inflation, playerStats, npcStats
-- Returns table:
-- {
--   requirement, ratio, zone,
--   goldTaken, dispDelta, triesConsumed,
--   inflationDelta
-- }
function Core.evaluateAttempt(args)
  local offer       = math.max(0, math.floor(args.offer or 0))
  local inflation   = args.inflation or settings.inflationStart
  local pstats      = args.playerStats or {}
  local nstats      = args.npcStats or {}

  local requirement = Core.computeRequirement(pstats, nstats, inflation)
  local ratio = 0
  if requirement > 0 then ratio = offer / requirement end

  local zone = classifyRatio(ratio, settings.thresholds)

  local dispCfg = settings.disposition
  local dispDelta = 0
  local triesConsumed = false
  local goldTaken = 0
  local inflationDelta = 0

  if zone == 'insulting' then
    dispDelta = dispCfg.insulting
    triesConsumed = true
    goldTaken = 0
  elseif zone == 'low' then
    dispDelta = dispCfg.low
    triesConsumed = true
    goldTaken = 0
  elseif zone == 'close' then
    dispDelta = dispCfg.close
    triesConsumed = not settings.closeNoTry and true or false
    goldTaken = 0
  elseif zone == 'success' then
    dispDelta = dispCfg.success
    triesConsumed = false
    goldTaken = offer
    inflationDelta = settings.inflationAddSuccess
  elseif zone == 'critical' then
    dispDelta = dispCfg.critical
    triesConsumed = false
    goldTaken = offer
    inflationDelta = settings.inflationAddCritical
  else -- overpay
    dispDelta = dispCfg.overpay
    triesConsumed = false
    goldTaken = offer
    inflationDelta = settings.inflationAddCritical
  end

  return {
    requirement = requirement,
    ratio = ratio,
    zone = zone,
    goldTaken = goldTaken,
    dispDelta = dispDelta,
    triesConsumed = triesConsumed,
    inflationDelta = inflationDelta,
  }
end

function Core.formatZoneMessage(zone)
  if zone == 'insulting' then return "Insulting offer." end
  if zone == 'low' then return "Too low." end
  if zone == 'close' then return "Close... you're almost there." end
  if zone == 'success' then return "Success!" end
  if zone == 'critical' then return "Perfect offer!" end
  return "Overpaying... generosity noted."
end

return Core
