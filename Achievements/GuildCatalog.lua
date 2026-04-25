---------------------------------------
-- Guild Achievement Definitions (Guild catalog for Vanilla)
---------------------------------------
local addonName, addon = ...
local table_insert = table.insert
local guildName = "|cffffd100" .. (GetGuildInfo("player") or (_G.CGA_GUILD_NAME or "No Guild")) .. "|r"
local classColor = (addon and addon.GetClassColor and addon.GetClassColor()) or "|cffffd100"
local playerName = classColor .. UnitName("player") .. "|r"
local playerClass = classColor .. UnitClass("player") .. "|r"
local GuildAchievements

-- Helpers live in Utils/SharedUtils.lua (keeps this file data-only).
local GetClassIcon = addon and addon.GetClassIcon
local GetMergedMetTargets = addon and addon.GetMergedMetTargets
local CountRequiredTargetEntries = addon and addon.CountRequiredTargetEntries
local CountSatisfiedRequiredTargets = addon and addon.CountSatisfiedRequiredTargets

-- requiredTarget: same shape as dungeon requiredKills ({ [npcId] = 1 }); names from addon.GetBossName.
-- targetOrder is optional (tooltip/tracker display only); omit it so cible = n'importe quel ordre (UI trie par id PNJ).
local ACH_MEET_KINGS = "GUILD-240426-03"
local TARGETS_MEET_KINGS_LIST = {
  [1747] = "Anduin Wrynn",
  [2784] = "King Magni Bronzebeard",
  [7937] = "High Tinker Mekkatorque",
  [7999] = "Tyrande Whisperwind",
}

GuildAchievements = {
  {
    achId = "GUILD-WELCOME",
    title = "A " .. playerClass .. " for " .. guildName .. "!",
    tooltip = "Welcome to Adventure Co " .. playerName .. "!\n\nWe're so glad to have you with us!\nOur Guild is about friendship, support and surviving hardcore together - no one should walk the road alone.\n\nGlad to have you on board, and may your journey be long and full of fun! \n\n/Rentjärn - " .. guildName .. " Guild Master",
    icon = (GetClassIcon and GetClassIcon()) or 136116,
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
      local met = (GetMergedMetTargets and GetMergedMetTargets(p)) or {}
      local need = (CountRequiredTargetEntries and CountRequiredTargetEntries(TARGETS_MEET_KINGS_LIST)) or 0
      local got = (CountSatisfiedRequiredTargets and CountSatisfiedRequiredTargets(met, TARGETS_MEET_KINGS_LIST)) or 0
      return need > 0 and got >= need
    end,
  },
  -- // TALK TO KATRANA (TEST)
  {
    achId = "GUILD-TALK-KATRANA-1749",
    title = "An audience with Lady Prestor",
    tooltip = "Speak with Lady Katrana Prestor in Stormwind.",
    icon = 135981,
    points = 5,
    level = 60,
    requiredTalkTo = {
      [1749] = "Lady Katrana Prestor",
    },
  },
  -- // Target Anduin Wrynn
  {
    achId = "GUILD-TARGET-ANDUIN-1747",
    title = "Talk to someone important",
    tooltip = "Speak with someone important.",
    icon = 134902,
    points = 5,
    level = 60,
    zone = "Stormwind City",
    requiredTarget = {
      [1747] = "Anduin Wrynn",
    },
    trackTargetOnChange = true,
    secretTracker = true,
  },  
  -- // OPEN WATER BARREL (TEST)
  {
    achId = "GUILD-OPEN-WATER-BARREL-3658",
    title = "A sip of water",
    tooltip = "Open a Water Barrel (GameObject ID 3658).",
    icon = 132797,
    points = 5,
    level = 60,
    requiredOpenObject = {
      [3658] = 1, -- Water Barrel
    },
  },
  {
    achId = "Murloc in Duskwood",
    title = "Murloc in Duskwood",
    level = nil,
    tooltip = "Find and kill a " .. classColor .. "Murloc|r in",
    icon = 134169,
    targetNpcId = 46,
    zone = "Duskwood",
    -- UiMapID (locale-neutral); kill counts only in this zone tree. Verify in-game: /run print(C_Map.GetBestMapForUnit("player"))
    zoneAccurate = 1431,
  },
}

-- Enable requiredTarget auto-discovery from target changes (shared utility).
if addon and type(addon.SetupRequiredTargetAutoTrack) == "function" then
  addon.SetupRequiredTargetAutoTrack(GuildAchievements, { throttleSeconds = 1.0 })
end

-- Defer registration until PLAYER_LOGIN (UnitClass/UnitFactionGroup valid, and core is ready).
if addon then
  addon.RegistrationQueue = addon.RegistrationQueue or {}
  local queue = addon.RegistrationQueue
  local RegisterAchievementDef = addon.RegisterAchievementDef

  local function GetKillTracker(def)
    if def.customKill then
      return def.customKill
    end
    if (def.targetNpcId or def.requiredKills) and addon.GetAchievementFunction then
      return addon.GetAchievementFunction(def.achId, "Kill")
    end
    return nil
  end

  local function GetQuestTracker(def)
    if def.requiredQuestId and addon.GetAchievementFunction then
      return addon.GetAchievementFunction(def.achId, "Quest")
    end
    return nil
  end

  for _, def in ipairs(GuildAchievements) do
    def.isGuild = true
    table_insert(queue, function()
      if not def.customKill and (def.targetNpcId or def.requiredKills or def.requiredQuestId) and addon.registerQuestAchievement then
        addon.registerQuestAchievement{
          achId = def.achId,
          requiredQuestId = def.requiredQuestId,
          targetNpcId = def.targetNpcId,
          requiredKills = def.requiredKills,
          maxLevel = def.level,
          faction = def.faction,
          race = def.race,
          class = def.class,
          allowKillsBeforeQuest = def.allowKillsBeforeQuest,
          zoneAccurate = def.zoneAccurate,
        }
      end
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
          GetKillTracker(def),
          GetQuestTracker(def),
          def.staticPoints,
          def.zone,
          def
        )
      end
    end)
  end

  addon.GuildAchievements = GuildAchievements
end
