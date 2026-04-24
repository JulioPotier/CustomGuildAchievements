---------------------------------------
-- Guild Achievement Definitions (Guild catalog for Vanilla)
---------------------------------------
local addonName, addon = ...
local table_insert = table.insert
local strsplit = strsplit
local guildName = "|cffffd100" .. (GetGuildInfo("player") or (_G.CGA_GUILD_NAME or "No Guild")) .. "|r"
local classColor = (addon and addon.GetClassColor and addon.GetClassColor()) or "|cffffd100"
local playerName = classColor .. UnitName("player") .. "|r"
local playerClass = classColor .. UnitClass("player") .. "|r"
-- Forward declare so helper functions above can reference it (Lua locals are not visible before declaration).
local GuildAchievements
-- requiredTarget: same shape as dungeon requiredKills ({ [npcId] = 1 }); names from addon.GetBossName.
-- targetOrder is optional (tooltip/tracker display only); omit it so cible = n'importe quel ordre (UI trie par id PNJ).
local ACH_MEET_KINGS = "GUILD-240426-03"
local TARGETS_MEET_KINGS_LIST = {
  [1747] = 1, -- Anduin Wrynn
  [2784] = 1, -- King Magni Bronzebeard
  [7937] = 1, -- High Tinker Mekkatorque
  --[7999] = 1, -- Tyrande Whisperwind
}

local function GetTargetNpcId()
  if not UnitExists("target") then return nil end
  local guid = UnitGUID("target")
  if not guid then return nil end
  local npcId = select(6, strsplit("-", guid))
  return npcId and tonumber(npcId) or nil
end

function GetClassIcon() 
  local ucp = UnitClass("player")
  local c_tbl =
  {
    ["Paladin"] = "Interface\\AddOns\\CustomGuildAchievements\\Images\\Class_PALADIN.png",
    ["Warrior"] = "Interface\\AddOns\\CustomGuildAchievements\\Images\\Class_WARRIOR.png",
    ["Hunter"] = "Interface\\AddOns\\CustomGuildAchievements\\Images\\Class_HUNTER.png",
    ["Rogue"] = "Interface\\AddOns\\CustomGuildAchievements\\Images\\Class_ROGUE.png",
    ["Priest"] = "Interface\\AddOns\\CustomGuildAchievements\\Images\\Class_PRIEST.png",
    --["Shaman"] = "Interface\\AddOns\\CustomGuildAchievements\\Images\\Class_SHAMAN.png",
    ["Mage"] = "Interface\\AddOns\\CustomGuildAchievements\\Images\\Class_MAGE.png",
    ["Warlock"] = "Interface\\AddOns\\CustomGuildAchievements\\Images\\Class_WARLOCK.png",
    ["Druid"] = "Interface\\AddOns\\CustomGuildAchievements\\Images\\Class_DRUID.png",
  }

  local func = c_tbl[ucp]
  if(func) then
    return func
  else
    return nil
  end
end

local function GetMergedMetTargets(p)
  if type(p) ~= "table" then return {} end
  local out = {}
  local function merge(src)
    if type(src) ~= "table" then return end
    for k, v in pairs(src) do
      if v then
        out[k] = true
        local kn = tonumber(k)
        if kn then out[kn] = true end
      end
    end
  end
  merge(p.metTargets)
  merge(p.metKings)
  return out
end

local function CountSatisfiedRequiredTargets(met, required)
  if type(met) ~= "table" or type(required) ~= "table" then return 0 end
  local n = 0
  for npcId, need in pairs(required) do
    if type(need) == "table" then
      local any = false
      for _, id in pairs(need) do
        local idn = tonumber(id) or id
        if met[idn] or met[id] or met[tostring(idn)] then
          any = true
          break
        end
      end
      if any then
        n = n + 1
      end
    else
      local idn = tonumber(npcId) or npcId
      if met[idn] or met[npcId] or met[tostring(idn)] then
        n = n + 1
      end
    end
  end
  return n
end

local function CountRequiredTargetEntries(required)
  local n = 0
  if type(required) ~= "table" then return 0 end
  for _ in pairs(required) do
    n = n + 1
  end
  return n
end

local function RequiredTargetContains(requiredTarget, npcId)
  if type(requiredTarget) ~= "table" or not npcId then return false end
  local need = requiredTarget[npcId] or requiredTarget[tostring(npcId)]
  if need ~= nil then return true end
  -- Support "any-of" entries: { [slot] = {id1,id2,...} }.
  for _, v in pairs(requiredTarget) do
    if type(v) == "table" then
      for _, id in pairs(v) do
        local idn = tonumber(id) or id
        if idn == npcId or tostring(idn) == tostring(npcId) then
          return true
        end
      end
    end
  end
  return false
end

local function RefreshTargetsProgressFromTarget()
  if not addon or addon.Disabled then return end
  if not (addon.GetProgress and addon.SetProgress) then return end

  local npcId = GetTargetNpcId()
  if not npcId then
    return
  end

  -- Update all guild achievements that use requiredTarget tracking on PLAYER_TARGET_CHANGED.
  -- This makes progress strictly scoped by achievementId even when multiple achievements share targets.
  for _, def in ipairs(GuildAchievements or {}) do
    if def and def.achId and def.trackTargetOnChange and RequiredTargetContains(def.requiredTarget, npcId) then
      local p = addon.GetProgress(def.achId) or {}
      p.metTargets = type(p.metTargets) == "table" and p.metTargets or {}
      if not p.metTargets[npcId] then
        p.metTargets[npcId] = true
        addon.SetProgress(def.achId, "metTargets", p.metTargets)
      end
    end
  end
end

-- Track targets across time; you can only have one target at a time, so we persist progress in SavedVariables.
local kingsTracker = CreateFrame("Frame")
kingsTracker:RegisterEvent("PLAYER_TARGET_CHANGED")
kingsTracker:RegisterEvent("PLAYER_LOGIN")
kingsTracker:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    -- In case of login race, try once after a tick
    C_Timer.After(0, RefreshTargetsProgressFromTarget)
  end
  RefreshTargetsProgressFromTarget()
end)

GuildAchievements = {
  {
    achId = "GUILD-WELCOME",
    title = "A " .. playerClass .. " for " .. guildName .. "!",
    tooltip = "As a fellow " .. playerClass .. ", you are now part of " .. guildName .. ". We wish you the best, " .. playerName .. "! Stay safe, help others, and have fun.",
    icon = GetClassIcon(),
    -- Core only auto-completes via customIsCompleted. Must use addon.IsInTargetGuild (set in
    -- CustomGuildAchievements.lua); IsInTargetGuild is not a global in this file — calling it was nil and pcall() failed.
    customIsCompleted = function()
      if type(addon.IsInTargetGuild) == "function" then
        return addon.IsInTargetGuild()
      end
      local guildName = GetGuildInfo("player")
      return guildName and guildName == (_G.CGA_GUILD_NAME or "Adventure Co")
    end,
  },
  -- // SELFOUND
  {
    achId = "GUILD-SELFFOUND",
    title = "Soul of Iron",
    tooltip = "When you have the Self-Found buff, you are self-found!",
    icon = 134902,
    points = 50,
    level = 1,
    secret = true,
    hiddenUntilComplete = true,
    customIsCompleted = function()
      if type(addon.IsSelfFound) == "function" then
        return addon.IsSelfFound() == true
      end
      -- Fallback if the core function isn't available yet (should be rare).
      if type(_G.IsSelfFound) == "function" then
        return _G.IsSelfFound() == true
      end
      return false
    end,
  },
  -- // KINGS
  {
    achId = ACH_MEET_KINGS,
    title = "Meet them all.",
    tooltip = "Meet the Kings of the Alliance realms.",
    icon = 236683,
    points = 40,
    level = 60,
    requiredTarget = TARGETS_MEET_KINGS_LIST,
    trackTargetOnChange = true,
    customIsCompleted = function()
      if not addon or not addon.GetProgress then
        return false
      end
      local p = addon.GetProgress(ACH_MEET_KINGS) or {}
      local met = GetMergedMetTargets(p)
      local need = CountRequiredTargetEntries(TARGETS_MEET_KINGS_LIST)
      return need > 0 and CountSatisfiedRequiredTargets(met, TARGETS_MEET_KINGS_LIST) >= need
    end,
  },
}

-- Defer registration until PLAYER_LOGIN (UnitClass/UnitFactionGroup valid, and core is ready).
if addon then
  addon.RegistrationQueue = addon.RegistrationQueue or {}
  local queue = addon.RegistrationQueue
  local RegisterAchievementDef = addon.RegisterAchievementDef

  for _, def in ipairs(GuildAchievements) do
    def.isGuild = true
    table_insert(queue, function()
      if RegisterAchievementDef then
        RegisterAchievementDef(def)
      end
      if def.customIsCompleted and addon.RegisterCustomAchievement then
        addon.RegisterCustomAchievement(def.achId, nil, def.customIsCompleted)
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
          nil,
          nil,
          def.staticPoints,
          def.zone,
          def
        )
      end
    end)
  end

  addon.GuildAchievements = GuildAchievements
end
