-- Player UI for the bribery minigame.
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')

local settings = require('scripts.speechcraft_bribe.settings')

local M = {}

local windowElement = nil
local lastNpc = nil
local lastStatusText = ""

local function destroy()
  if windowElement ~= nil then
    windowElement:destroy()
    windowElement = nil
  end
end

local function statusTextLabel()
  return {
    type = ui.TYPE.Text,
    name = "status",
    props = { text = lastStatusText, wordWrap = true, autoSize = true, },
  }
end

local function row(children)
  return { type = ui.TYPE.Container, content = children }
end

local function spacer(h)
  return { type = ui.TYPE.Widget, props = { size = util.vector2(0, h or 8) } }
end

local function labelledText(label, valueName)
  return row({
    { type = ui.TYPE.Text, props = { text = label .. ": ", autoSize = true } },
    { type = ui.TYPE.Text, name = valueName, props = { text = "", autoSize = true } },
  })
end

local function setText(name, value)
  if windowElement and windowElement.content[name] then
    windowElement.content[name].props.text = value
    windowElement:update()
  end
end

local function parseOffer(text)
  local v = tonumber((text or ""):gsub("[^%d]", "")) or 0
  if v < 0 then v = 0 end
  return math.floor(v)
end

local function makeLayout(npcName, triesLeft, inflationPct)
  return {
    layer = "Windows",
    type = ui.TYPE.Flex,
    props = {
      size = util.vector2(480, 220),
      anchor = util.vector2(0.5, 0.5),
      relativePosition = util.vector2(0.5, 0.5),
    },
    content = ui.content({
      {
        type = ui.TYPE.Window,
        props = { title = "Bribe: " .. npcName },
        content = ui.content({
          spacer(4),
          labelledText("Tries left", "tries"),
          labelledText("Inflation", "inflation"),
          spacer(6),
          row({
            { type = ui.TYPE.Text, props = { text = "Offer (gold): ", autoSize = true } },
            {
              type = ui.TYPE.TextEdit,
              name = "offer_input",
              props = { text = "", size = util.vector2(150, 24) },
              events = {
                textChanged = async:callback(function(newText, layout)
                  -- Keep digits only
                  local clean = tostring(parseOffer(newText))
                  if clean ~= newText then
                    layout.props.text = clean
                    if windowElement then windowElement:update() end
                  end
                end),
              },
            },
            {
              type = ui.TYPE.Widget,
              props = { size = util.vector2(10, 1) }
            },
            {
              type = ui.TYPE.Text,
              name = "gold_info",
              props = { text = "", autoSize = true },
            }
          }),
          spacer(6),
          statusTextLabel(),
          spacer(10),
          row({
            {
              type = ui.TYPE.Text,
              props = { text = "[ Submit ]", autoSize = true },
              events = {
                mouseClick = async:callback(function(_, layout)
                  if not windowElement then return end
                  local offerStr = windowElement.content.offer_input.props.text or "0"
                  local offer = parseOffer(offerStr)
                  -- Player script handles the attempt
                  M.onSubmit(offer)
                end),
              },
            },
            { type = ui.TYPE.Widget, props = { size = util.vector2(16, 1) } },
            {
              type = ui.TYPE.Text,
              props = { text = "[ Cancel ]", autoSize = true },
              events = {
                mouseClick = async:callback(function() destroy() end),
              },
            },
          }),
          spacer(4),
        }),
      },
    }),
  }
end

function M.open(npcName, triesLeft, inflationPct, playerGold, statusText)
  lastStatusText = statusText or ""
  if windowElement == nil then
    windowElement = ui.create(makeLayout(npcName, triesLeft, inflationPct))
  end
  setText("tries", tostring(triesLeft))
  setText("inflation", string.format("%.0f%%", inflationPct))
  setText("gold_info", string.format("Your gold: %d", playerGold))
  setText("status", lastStatusText)
end

function M.update(npcName, triesLeft, inflationPct, playerGold, statusText)
  if windowElement ~= nil then
    M.open(npcName, triesLeft, inflationPct, playerGold, statusText)
  end
end

function M.close()
  destroy()
end

-- Hook from player.lua
M.onSubmit = function(_) end

return M
