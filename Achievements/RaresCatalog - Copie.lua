-- Rares achievement definitions
local addonName, addon = ...
local ClassColor = (addon and addon.GetClassColor())
local UnitGUID = UnitGUID
local UnitClass = UnitClass
local UnitFactionGroup = UnitFactionGroup
local GetUnitName = GetUnitName
local strsplit = strsplit
local GetItemCount = GetItemCount
local UnitBuff = UnitBuff
local UnitRace = UnitRace
local table_insert = table.insert
local string_format = string.format

--[[
local QUEST_TIMEOUT = 0.3
local function ScrapeQTip(self)
  local tipName = self:GetName()
  local name, description = _G[tipName .. 'TextLeft1']:GetText(), _G[tipName ..'TextLeft2']:GetText()
  if name then
      --print(format('|cffffff00|Hunit:Creature-0-0-0-0-%d-0|h[%s]|h|r (%d) %s', self.npcID, name, self.npcID, description or ''))
    --end
    self:SetScript('OnTooltipSetUnit', nil)
    self.npcID = nil
    return name
  end
end

local QTips = {}
local function GetQTip()
  local now = GetTime()
  for i, tip in ipairs(QTips) do
    if not tip.npcID or now - tip.lastUpdate > QUEST_TIMEOUT + 0.2 then
      tip.lastUpdate = now
      return tip
    end
  end
  local tip = CreateFrame('GameTooltip',  'SemlarsQTip' .. (#QTips + 1), WorldFrame, 'GameTooltipTemplate')
  tip:Show()
  tip:SetHyperlink('unit:')
  tip.lastUpdate = now
  tinsert(QTips, tip)
  return tip
end

function GetNPCInfo(npcID)
  local tip = GetQTip()
  tip:SetOwner(WorldFrame, 'ANCHOR_NONE')
  tip.npcID = npcID or 0
  tip:SetScript('OnTooltipSetUnit', ScrapeQTip)
  tip:SetHyperlink('unit:Creature-0-0-0-0-' .. npcID .. '-0')
  C_Timer.After(QUEST_TIMEOUT, function() -- Run a second pass for uncached units or the event will never fire
    if tip.npcID == npcID then
      tip:SetHyperlink('unit:Creature-0-0-0-0-' .. npcID .. '-0')
    end
  end)
end
--]]

local RaresAchievements = {
  { achId="Test001",  title="Sheep Test", tooltip="Kill " .. ClassColor .. "a Sheep|r (test)", icon=136071, points=10, targetNpcId=1933 },
  
  {
    achId = "narg",
    title = "Narg the Taskmaster",
    level = nil,
    tooltip = "Find and kill " .. ClassColor .. "Narg the Taskmaster|r.\nLevel 10, not elite.",
    icon = 236448,
    targetNpcId = 79,
    faction = nil,
    points = 10,
    zone = "Elwynn Forest",
  },
  {
    achId = "morgaine",
    title = "Morgaine the Sly",
    level = nil,
    tooltip = "Find and kill " .. ClassColor .. "Morgaine the Sly|r.\nLevel 10, not elite.",
    icon = 236448,
    targetNpcId = 99,
    faction = nil,
    points = 10,
    zone = "Elwynn Forest",
  },
  {
    achId="TestDeerFawn",  
    title="Bambi??", 
    --level=60, 
    tooltip="Kill a Deer and their Fawn anywhere", 
    icon=236707, 
    points=10, 
    requiredKills = {
        [883] = 1,  -- Deer
        [890] = 1,  -- Fawn
    },
  },
  {
    achId="TestForestSpider",  
    title="Spiderman", 
    --level=60, 
    tooltip="Kill a Forest Spider anywhere", 
    icon=134321, 
    points=10, 
    targetNpcId=30,
  },
  {
    achId="TestCow",  
    title="Kill a Cow!?", 
    --level=60, 
    tooltip="Kill a Cow anywhere", 
    icon=136072, 
    points=10, 
    targetNpcId=2442,
  },
  {
    achId="TestChicken",  
    title="Kill a Chicken!?", 
    --level=60, 
    tooltip="Kill a Chicken anywhere", 
    icon=135996, 
    points=10, 
    targetNpcId=620,
  },
  {
    achId="TestRat",  
    title="Kill a Rat!?", 
    --level=60, 
    tooltip="Kill a Rat anywhere", 
    icon=134400, 
    points=10, 
    targetNpcId=4075
  },
  {
    achId="TestRabbit",  
    title="Kill a Rabbit!?", 
   -- level=60, 
    tooltip="Kill a Rabbit anywhere", 
    icon=254857, 
    points=10, 
    targetNpcId=721
  },
  {
    achId="TestSheep",  
    title="Kill a Sheep!?", 
    --level=60, 
    tooltip="Kill a Sheep anywhere", 
    icon=136071, 
    points=10, 
    targetNpcId=1933
  },
}

---------------------------------------
-- Helper Functions
---------------------------------------
local function GetKillTracker(def)
    if def.customKill then
        return def.customKill
    end
    if (def.targetNpcId or def.requiredKills) and addon and addon.GetAchievementFunction then
        return addon.GetAchievementFunction(def.achId, "Kill")
    end
    return nil
end

---------------------------------------
-- Registration Logic (deferred to queue so IsEligible is valid at PLAYER_LOGIN)
---------------------------------------

if addon then
  addon.RaresAchievements = RaresAchievements
end

local function IsEligible(def)
  -- Faction: "Alliance" / "Horde"
  if def.faction and select(2, UnitFactionGroup("player")) ~= def.faction then
    return false
  end

  -- Race: allow either raceFile or localized race name in the def
  if def.race then
    local raceName, raceFile = UnitRace("player")
    if def.race ~= raceFile and def.race ~= raceName then
      return false
    end
  end

  -- Class: use class file tokens ("MAGE","WARRIOR",...)
  if def.class then
    local _, classFile = UnitClass("player")
    if classFile ~= def.class then
      return false
    end
  end

  return true
end

---------------------------------------
-- Deferred Registration Queue
---------------------------------------
if addon then
  addon.RegistrationQueue = addon.RegistrationQueue or {}
  local queue = addon.RegistrationQueue
  local RegisterAchievementDef = addon.RegisterAchievementDef

  for _, def in ipairs(RaresAchievements) do
    def.isRares = true
    table_insert(queue, function()
      if not IsEligible(def) then return end
      local killFn = GetKillTracker(def)
      if RegisterAchievementDef then
        RegisterAchievementDef(def)
      end
      local CreateAchievementRow = addon.CreateAchievementRow
      local AchievementPanel = addon.AchievementPanel
      if CreateAchievementRow and AchievementPanel then
        CreateAchievementRow(
          AchievementPanel,
          def.achId,
          def.title,
          def.tooltip,
          def.icon,
          def.level,
          def.points or 0,
          killFn,
          nil,
          def.staticPoints,
          def.zone,
          def
        )
      end
    end)
  end
end

