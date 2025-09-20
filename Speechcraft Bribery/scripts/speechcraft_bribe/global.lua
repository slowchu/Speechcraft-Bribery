-- Global glue for inventory/disposition changes.
local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')

local settings = require('scripts/speechcraft_bribe.settings')

local function takeGold(player, amount)
  if amount <= 0 then return true end
  local inv = player.inventory
  local goldItem = inv:find(settings.goldRecordId)
  if not goldItem then return false end
  local have = inv:countOf(settings.goldRecordId) or 0
  if have < amount then return false end

  -- Remove exact amount. We may need to split stack multiple times.
  local remain = amount
  while remain > 0 do
    local stack = inv:find(settings.goldRecordId)
    if not stack then break end
    local toRemove = math.min(stack.count, remain)
    local part = stack
    if toRemove < stack.count then
      part = stack:split(toRemove) -- only allowed in global
    end
    part:remove() -- only allowed in global
    remain = remain - toRemove
  end
  return true
end

local function applyDisposition(npc, player, delta)
  if delta == 0 then return end
  -- Only allowed in global scripts or on self (docs).
  types.NPC.modifyBaseDisposition(npc, player, delta)
end

return {
  eventHandlers = {
    SpeechcraftBribe_ApplyEffects = function(data)
      local npc = data.npc
      local player = data.player
      local goldTaken = math.max(0, math.floor(data.goldTaken or 0))
      local dispDelta = math.floor(data.dispDelta or 0)
      local message = data.message or ""

      local ok = true
      if goldTaken > 0 then
        ok = takeGold(player, goldTaken)
      end
      if not ok then
        player:sendEvent('ShowMessage', { message = "You do not have enough gold." })
        return
      end

      applyDisposition(npc, player, dispDelta)

      if message ~= "" then
        player:sendEvent('ShowMessage', { message = message })
      end
    end,
  },
}
