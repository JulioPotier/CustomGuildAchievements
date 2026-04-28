---------------------------------------
-- Guild Achievement Definitions (Guild catalog for Vanilla)
---------------------------------------
local addonName, addon = ...
local table_insert = table.insert
local guildName = "|cffffd100" .. (GetGuildInfo("player") or (_G.CGA_GUILD_NAME or "No Guild")) .. "|r"
local classColor = (addon and addon.GetClassColor and addon.GetClassColor()) or "|cffffd100"
local rawPlayerName = UnitName("player")
local playerName = classColor .. rawPlayerName .. "|r"
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
  -- // target some npc
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
  -- // TALK TO someone
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
  -- // Attempt: gossip with Lady Prestor (1749) starts the run; speak with Anduin (1747) before timer ends
  --[[
  {
    achId = "GUILD-ATTEMPT-ROYAL-RUSH-TEST7",
    title = "Royal rush",
    tooltip = "Open gossip with Lady Katrana Prestor in Stormwind Keep to start your run, then speak with Anduin Wrynn before the timer expires.",
    icon = 135981,
    points = 10,
    level = 60,
    attemptEnabled = true,
    startNpc = {
      npcId = 1749,
      text = "\nRoyal rush\n\nHello " .. rawPlayerName .. "! You will have to find your way to the Stormwind Keep and speak with Anduin Wrynn to win this achievement.\n\nTry your best at Adventure Co.",
      buttonLabel = "Accept quest",
      
      -- onClick = function(cfg, npcId, def)
      --   if addon and addon.AttemptActivate then
      --     addon.AttemptActivate(cfg.achId, "npc:" .. tostring(npcId), nil)
      --   end
      -- end,
    },
    timerSet = 300,
    zone = "5 min",
    requiredTarget = {
      [1747] = "Anduin Wrynn",
    },
  },--]]
  -- // Attempt: loot a Water Barrel (3658) starts each try; up to 3 runs; speak with Magni in Ironforge
  {
    achId = "GUILD-ATTEMPT-BARREL-MAGNI-3",
    title = "Barrel relay (3 tries)",
    tooltip = "Open a Water Barrel (object 3658) to start a run — you have three starts total. Reach Ironforge and speak with King Magni Bronzebeard before the timer runs out. Each new barrel open begins another try if you are not already in a run.",
    icon = 132797,
    points = 15,
    level = 60,
    attemptEnabled = true,
    -- Single-metric run stat (best time). Implementation stores/prints later; this declares the intent.
    dataLabel = "Best time",
    dataFormat = "time",
    dataMode = "min",
    attemptsAllowed = 3,
    startObjectId = 3658,
    timerSet = 1200,
    requiredTalkTo = {
      [2784] = "King Magni Bronzebeard",
    },
  },
  -- // Attempt: no mount / druid forms / hunter aspects / ghost wolf when flags are set (each optional)
  {
    achId = "GUILD-ATTEMPT-NEVER-FAST",
    title = "The Saddle Is Lava",
    tooltip = "Talk to any Stormwind Guard to start your vow. Then head to King Magni Bronzebeard in Ironforge without shortcut movement.\n\nWhile the attempt is active: you must stay in walk (no run toggle). Mounting, Cat Form, Travel Form, hunter Cheetah/Pack aspects, or Ghost Wolf fail the achievement (each controlled by its own flag). Potions, gear and passive talents do not.",
    icon = 132261,
    points = 10,
    level = 60,
    attemptEnabled = true,
    failOnMount = true,
    failOnDruidCatForm = true,
    failOnDruidTravelForm = true,
    failOnHunterAspect = true,
    failOnShamanGhostWolf = true,
    walkOnly = true,
    startNpc = {
      npcId = 68,
      window = {
        title = "The Saddle Is Lava",
        text = "Swear you will not mount, shapeshift for speed, use hunter running aspects, or Ghost Wolf — only foot travel allowed for this challenge.\n\nClick below to start your vow.",
        buttonLabel = "I swear (strict travel)",
        buttonSound = "coins",
        callback = function(def, npcId)
          if addon and addon.AttemptActivate then
            addon.AttemptActivate(def.achId, "npc:" .. tostring(npcId), nil)
          end
          return false
        end,
      },
    },
    timerSet = 900,
    requiredTalkTo = {
      [2784] = "King Magni Bronzebeard",
    },
  },
  -- // Target secret
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
    checkInteractDistance = true,
  },  
  -- // OPEN object
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
  -- // Accurate zone kill count
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
  -- // Emote trigger: target an NPC and /wave
  {
    achId = "GUILD-EMOTE-WAVE-46",
    title = "Say hello to the Stormwind Guard",
    level = nil,
    tooltip = "Target a Stormwind Guard and perform a /wave.",
    icon = 135993,
    points = 5,
    targetNpcId = 68,
    onEmote = "wave",
    checkInteractDistance = true,
    withIcon = "bubble",
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
    if (not def.onEmote) and (def.targetNpcId or def.requiredKills) and addon.GetAchievementFunction then
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
      if (not def.onEmote) and (not def.customKill) and (def.targetNpcId or def.requiredKills or def.requiredQuestId) and addon.registerQuestAchievement then
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

--[[
Gossip / talk
Interface\\GossipFrame\\GossipGossipIcon (default bubble)
Interface\\GossipFrame\\BinderGossipIcon
Interface\\GossipFrame\\VendorGossipIcon
Interface\\GossipFrame\\TaxiGossipIcon
Interface\\GossipFrame\\HealerGossipIcon
Interface\\GossipFrame\\TrainerGossipIcon
(and many others in Interface\\GossipFrame\\*GossipIcon)

Quests
Interface\\GossipFrame\\AvailableQuestIcon
Interface\\GossipFrame\\ActiveQuestIcon
Interface\\GossipFrame\\IncompleteQuestIcon
Interface\\GossipFrame\\DailyQuestIcon
(and many others in Interface\\GossipFrame\\*QuestIcon)

Clear markers
Interface\\TargetingFrame\\UI-RaidTargetingIcons (spritesheet : star/circle/diamond… via SetTexCoord) (and many others in Interface\\TargetingFrame\\*RaidTargetingIcons)
Interface\\COMMON\\Indicator-Yellow / Interface\\COMMON\\Indicator-Red (depending on version)

Alerts / interaction
Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew
Interface\\DialogFrame\\UI-Dialog-Icon-AlertOther
Interface\\Buttons\\UI-GroupLoot-Pass-Up (cross)
Interface\\Buttons\\UI-CheckBox-Check (checkmark)
Icons (FileID) (and many others in Interface\\Buttons\\*Button)
(FileID) startNpc.icon 

Interface\\Common\\, Interface\\Buttons\\, Interface\\DialogFrame\\
]]