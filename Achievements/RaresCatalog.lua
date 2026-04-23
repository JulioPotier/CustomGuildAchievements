---------------------------------------
-- Achievement Definitions (Quest/Milestone catalog for Vanilla)
---------------------------------------
local addonName, addon = ...
local UnitLevel = UnitLevel
local UnitClass = UnitClass
local UnitFactionGroup = UnitFactionGroup
local GetItemCount = GetItemCount
local UnitRace = UnitRace
local table_insert = table.insert
local string_format = string.format
local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo("player")
local ClassColor = (addon and addon.GetClassColor())

function guildIsAdventureCo()
  return guildName == "Adventure Co"
end

local RaresAchievements = {
  --{ achId="Test001",  title="Sheep Test", tooltip="Kill " .. ClassColor .. "a Sheep|r (test)", icon=136071, points=10, targetNpcId=1933 },
  { achId="Test017",  title="Anduin Wrynn", tooltip="Talk to Anduin Wrynn", icon=135993, points=10, customIsCompleted = function() return UnitGUID("target") == 6740 end, },
  
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
    --title="Bambi??", 
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
  { achId="Test010",  title="Forest Spider Test", tooltip="Kill " .. ClassColor .. "a Forest Spider|r (test)", icon=134321, points=10, targetNpcId=30 },

}

function getClassConst() 
  local ucp = UnitClass("player")
  local c_tbl =
  {
    ["Paladin"] = "Interface\\AddOns\\CustomGuildAchievements\\Images\\Class_PALADIN.png",
  }

  local func = c_tbl[ucp]
  if(func) then
    return func
  else
    return nil
  end
end

if guildIsAdventureCo() then
  table.insert(RaresAchievements, 
    { 
      achId="advco01", 
      icon=getClassConst(),
      title="A " .. ClassColor .. UnitClass("player") .. "|r for " .. guildName, tooltip="As a fellow " .. ClassColor .. UnitClass("player") .. " " .. GetUnitName("player") .. "|r, you are now part of the " .. guildName .. ".\nStay safe and have fun." }
  )
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
-- Registration Logic
---------------------------------------

for _, def in ipairs(RaresAchievements) do
  if IsEligible(def) then
    if def.customKill then
      if addon and addon.RegisterCustomAchievement then
        addon.RegisterCustomAchievement(def.achId, def.customKill, def.customIsCompleted or function() return false end)
      end
    elseif def.customIsCompleted then
      if addon and addon.RegisterCustomAchievement then
        addon.RegisterCustomAchievement(def.achId, nil, def.customIsCompleted)
      end
    else
      if addon and addon.registerQuestAchievement then
        addon.registerQuestAchievement{
          achId           = def.achId,
          requiredQuestId = def.requiredQuestId,
          targetNpcId     = def.targetNpcId,
          requiredKills   = def.requiredKills,
          maxLevel        = def.level,
          faction         = def.faction,
          race            = def.race,
          class           = def.class,
          allowKillsBeforeQuest = def.allowKillsBeforeQuest,
        }
      end
    end
  end
end

-- Export to addon for internal use (e.g. RefreshAllAchievementPoints, AdminPanel)
if addon then
  addon.RaresAchievements = RaresAchievements
end

---------------------------------------
-- Helper Functions
---------------------------------------

-- Get kill tracker function for an achievement definition
local function GetKillTracker(def)
    if def.customKill then
        return def.customKill
    end
    if (def.targetNpcId or def.requiredKills) and addon and addon.GetAchievementFunction then
        return addon.GetAchievementFunction(def.achId, "Kill")
    end
    return nil
end

-- Get quest tracker function for an achievement definition
local function GetQuestTracker(def)
    if def.requiredQuestId and addon.GetAchievementFunction then
        return addon.GetAchievementFunction(def.achId, "Quest")
    end
    return nil
end

---------------------------------------
-- Deferred Registration Queue
---------------------------------------

-- Defer registration until PLAYER_LOGIN so IsEligible (UnitFactionGroup/UnitRace/UnitClass) is valid
if addon then
  addon.RegistrationQueue = addon.RegistrationQueue or {}
  local queue = addon.RegistrationQueue
  local RegisterAchievementDef = addon.RegisterAchievementDef

  for _, def in ipairs(RaresAchievements) do
    def.isRares = true
    table_insert(queue, function()
      if not IsEligible(def) then return end
      local killFn = GetKillTracker(def)
      local questFn = GetQuestTracker(def)
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
          questFn,
          def.staticPoints,
          def.zone,
          def
        )
      end
    end)
  end
end
