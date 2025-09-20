-- Per-player, per-NPC state (tries & inflation). Player script only.
local storage = require('openmw.storage')
local core = require('openmw.core')
local time = require('openmw_aux.time')
local settings = require('scripts.speechcraft_bribe.settings')

local State = {}
local SECTION = 'speechcraft_bribe_state'

local function getSection()
  return storage.playerSection(SECTION)
end

local function nowGameHours()
  -- core.getGameTime() returns game time in seconds (per docs). Convert to hours.
  return core.getGameTime() / (60 * 60)
end

local function keyForNpc(npc)
  -- Use object.id (unique per reference). Fall back to recordId if needed.
  return npc.id or npc.recordId
end

local function maybeDecayInflation(infl, lastUpdateHours, currentHours)
  if settings.inflationDecayPerDay <= 0 then return infl end
  local elapsedDays = math.max(0, (currentHours - lastUpdateHours) / 24.0)
  if elapsedDays <= 0 then return infl end
  local dec = settings.inflationDecayPerDay * elapsedDays
  local newInfl = math.max(settings.inflationStart, infl - dec)
  return newInfl
end

function State.read(npc)
  local sec = getSection()
  local key = keyForNpc(npc)
  local entry = sec:get(key) or {}
  local hours = nowGameHours()

  -- Reset tries if cooldown expired
  if entry.resetAtGameHour and hours >= entry.resetAtGameHour then
    entry.triesLeft = settings.triesMax
    entry.resetAtGameHour = nil
  end

  -- Init if new
  if not entry.inflation then entry.inflation = settings.inflationStart end
  if not entry.triesLeft then entry.triesLeft = settings.triesMax end
  if not entry.lastUpdate then entry.lastUpdate = hours end

  -- Optional decay
  entry.inflation = maybeDecayInflation(entry.inflation, entry.lastUpdate, hours)
  entry.lastUpdate = hours

  -- Clamp inflation
  if entry.inflation > settings.inflationCap then
    entry.inflation = settings.inflationCap
  end

  -- Persist back any changes
  sec:set(key, entry)
  return entry
end

function State.save(npc, entry)
  local sec = getSection()
  local key = keyForNpc(npc)
  sec:set(key, entry)
end

function State.consumeTry(npc)
  local entry = State.read(npc)
  if entry.triesLeft > 0 then
    entry.triesLeft = entry.triesLeft - 1
    if entry.triesLeft <= 0 then
      entry.resetAtGameHour = nowGameHours() + settings.cooldownHours
    end
  end
  State.save(npc, entry)
  return entry
end

function State.onSuccess(npc, inflationDelta)
  local entry = State.read(npc)
  entry.inflation = math.min(settings.inflationCap, (entry.inflation or settings.inflationStart) + (inflationDelta or 0))
  State.save(npc, entry)
  return entry
end

return State
