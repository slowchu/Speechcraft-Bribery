local self = require('openmw.self')
local ui = require('openmw.ui')
local async = require('openmw.async')
local input = require('openmw.input')
local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')
local I = require('openmw.interfaces')

local settings = require('scripts.speechcraft_bribe.settings')
local Core = require('scripts.speechcraft_bribe.bribe_core')
local State = require('scripts.speechcraft_bribe.state')
local BribeUI = require('scripts.speechcraft_bribe.ui')

local currentMode = I.UI.getMode()
local dialogueTarget = nil

local function inDialogue()
  return currentMode == I.UI.MODE.Dialogue and dialogueTarget ~= nil and dialogueTarget:isValid()
end

local function getName(obj)
  local rec = types.NPC.record(obj)
  return rec and rec.name or obj.recordId
end

local function getStatTriplet(actor)
  local p = types.NPC.stats.skills.speechcraft(actor).modified
  local m = types.NPC.stats.skills.mercantile(actor).modified
  local a = types.Actor.stats.attributes.personality(actor).modified
  return { speechcraft = p, mercantile = m, personality = a }
end

local function getGoldCount(actor)
  local inv = actor.inventory
  local cnt = inv:countOf(settings.goldRecordId)
  return cnt or 0
end

local function ensureTrigger()
  if not input.triggers[settings.hotkeyName] then
    input.registerTrigger {
      key = settings.hotkeyName,
      l10n = settings.l10n,
      name = settings.hotkeyName_L10N,
      description = settings.hotkeyDesc_L10N,
    }
  end
  input.registerTriggerHandler(settings.hotkeyName, async:callback(function()
    if not inDialogue() then
      self:sendEvent('ShowMessage', { message = "Bribe: Only usable during dialogue." })
      return
    end
    local entry = State.read(dialogueTarget)
    if entry.triesLeft <= 0 then
      self:sendEvent('ShowMessage', { message = "Bribe: No tries left. Come back later." })
      return
    end
    BribeUI.open(getName(dialogueTarget), entry.triesLeft, (entry.inflation or 1) * 100 - 100, getGoldCount(self), "")
  end))
end

-- Called by UI
BribeUI.onSubmit = function(offer)
  if not inDialogue() then
    BribeUI.update("","", "", getGoldCount(self), "Not in dialogue.")
    return
  end
  local entry = State.read(dialogueTarget)
  if entry.triesLeft <= 0 then
    BribeUI.update(getName(dialogueTarget), entry.triesLeft, (entry.inflation or 1) * 100 - 100, getGoldCount(self), "No tries left.")
    return
  end
  local gold = getGoldCount(self)
  -- Prepare stats
  local pstats = getStatTriplet(self)
  local nstats = getStatTriplet(dialogueTarget)

  local result = Core.evaluateAttempt {
    offer = offer,
    inflation = entry.inflation or 1.0,
    playerStats = pstats,
    npcStats = nstats,
  }

  local status = Core.formatZoneMessage(result.zone)

  if result.goldTaken > 0 and gold < result.goldTaken then
    BribeUI.update(getName(dialogueTarget), entry.triesLeft, (entry.inflation or 1) * 100 - 100, gold, "Not enough gold.")
    return
  end

  -- Apply state changes
  if result.triesConsumed then
    entry = State.consumeTry(dialogueTarget)
  end
  if result.goldTaken > 0 then
    entry = State.onSuccess(dialogueTarget, result.inflationDelta)
  end

  -- Update UI & send effects to global
  local npcName = getName(dialogueTarget)
  local inflPct = (entry.inflation or 1) * 100 - 100
  local playerGold = getGoldCount(self)

  if result.goldTaken > 0 or result.dispDelta ~= 0 then
    core.sendGlobalEvent('SpeechcraftBribe_ApplyEffects', {
      npc = dialogueTarget,
      player = self,
      goldTaken = result.goldTaken,
      dispDelta = result.dispDelta,
      message = status,
    })
  else
    -- Feedback only
    self:sendEvent('ShowMessage', { message = status })
  end

  BribeUI.update(npcName, entry.triesLeft, inflPct, playerGold, status)
end

return {
  interfaceName = settings.mod .. ".player",
  interface = {},
  eventHandlers = {
    UiModeChanged = function(data)
      currentMode = I.UI.getMode()
      if currentMode == I.UI.MODE.Dialogue then
        dialogueTarget = data and data.arg or dialogueTarget
      else
        dialogueTarget = nil
        BribeUI.close()
      end
    end,
  },
  engineHandlers = {
    onInit = function()
      ensureTrigger()
    end,
  },
}
