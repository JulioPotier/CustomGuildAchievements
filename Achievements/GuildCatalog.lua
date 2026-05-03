---------------------------------------
-- Guild Achievement Definitions (Guild catalog for Vanilla)
---------------------------------------
local addonName, addon = ...
local table_insert = table.insert
local guildName = "|cffffd100" .. (GetGuildInfo("player") or "No Guild") .. "|r"
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
  --[7999] = "Tyrande Whisperwind",
}

GuildAchievements = {
  {
    achId = "GUILD-WELCOME",
    title = "A " .. playerClass .. " for " .. guildName .. "!",
    tooltip = "Welcome to " .. guildName .. ", " .. playerName .. "!\n\n. You are now a member of the guild, explore the world and complete achievements to progress in the guild. Have fun!",
    icon = (GetClassIcon and GetClassIcon()) or 136116,
    -- Core only auto-completes via customIsCompleted. Must use addon.IsInTargetGuild (set in
    -- CustomGuildAchievements.lua); IsInTargetGuild is not a global in this file — calling it was nil and pcall() failed.
    customIsCompleted = function()
      if type(addon.IsInTargetGuild) == "function" then
        return addon.IsInTargetGuild()
      end
      local gName = GetGuildInfo("player")
      return gName ~= nil and gName ~= ""
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
  -- // dropItemOn: buy bread and "offer" it to Stephanie Turner
  {
    achId = "GUILD-BUY-ME-SOME-BREAD-11",
    title = "Buy me some bread (bring item test)",
    tooltip =
      "Bring some bread to Stephanie Turner.",
    icon = 133964, -- INV_Misc_Food_11 (bread)
    points = 5,
    level = nil, -- no maxLevel: keep startNpc available at any level
    startNpc = {
      npcId = 6174, -- Stephanie Turner
      coords = { mapId = 1453, x = 0.570680975914, y = 0.61753934621811 }, -- Stormwind City (coords => map pin)
      window = {
        title = "Buy me some bread",
        text =
          "Hello " .. rawPlayerName .. "!\n\n"
          .. "Could you buy me a |cffffffff[Tough Hunk of Bread]|r from Thomas Miller?\n\n"
          .. "Bring it back here, I cannot go anywhere, I'm stuck here.",
        buttonLabel = "I'll be right back",
        buttonSound = "accept",
        callback = function()
          return false
        end,
      },
    },
    dropItemOn = { itemId = 4540, nbItem = 1, npcId = 6174 },
    zone = "Stormwind City",
  },
  -- // target some npc
  {
    achId = ACH_MEET_KINGS,
    title = "Royal Rush (custom tracker test)",
    tooltip = "Open gossip with a Royal Guard to start your run, then speak with the Kings before the timer expires.",
    icon = 135981,
    points = 10,
    level = 60,
    attemptEnabled = true,
    startNpc = {
      npcId = 1756,
      text = "\nRoyal rush\n\nHello " .. rawPlayerName .. "! You will have to find your way to the Stormwind Keep and speak with Anduin Wrynn to win this achievement.\n\nGood luck!",
      buttonLabel = "Accept quest",
    },
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
    achId = "GUILD-TALK-KATRANA-1749-03",
    title = "An audience with Lady Prestor (talk to test)",
    tooltip = "Speak with Lady Katrana Prestor in Stormwind.",
    icon = 135981,
    points = 5,
    level = 60,
    requiredTalkTo = {
      [1749] = "Lady Katrana Prestor",
    },
  },
  {
    achId = "GUILD-ATTEMPT-BARREL-MAGNI-3",
    title = "Barrel relay (3 attempts test)",
    tooltip = "Open a Water Barrel to start a run — you have three starts total. Reach Ironforge and speak with King Magni Bronzebeard before the timer runs out. Each new barrel open begins another try if you are not already in a run.",
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
    achId = "GUILD-ATTEMPT-NEVER-FASTERRR",
    title = "The Saddle Is Lava (no mount etc test)",
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
    --walkOnly = true,
    startNpc = {
      npcId = 68,
      window = {
        title = "The Saddle Is Lava",
        text = "Swear you will not mount, shapeshift for speed, use hunter running aspects, or Ghost Wolf — only foot travel allowed for this challenge.\n\nClick below to start your vow.",
        buttonLabel = "I swear (strict travel)",
        buttonSound = "accept",
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
    achId = "GUILD-TARGET-ANDUIN-1747-001",
    title = "Talk to someone important (secret tracker)",
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

  {
    achId = "GUILD-TARGET-HIGHLORD-1748-002",
    secretTitle = "A Knight from the Ebon Blade (secret target)",
    secretTooltip = "Speak with someone really important.",
    icon = 134902,
    points = 5,
    level = 60,
    zone = "Stormwind City",
    requiredTarget = {
      [1748] = "Highlord Bolvar Fordragon",
    },
    secret = true,
    secretTracker = true,
    title = "Thank you " .. rawPlayerName .. "!",
    tooltip = "I appreciate your help, " .. rawPlayerName .. "!",
    checkInteractDistance = true,
  },    -- // OPEN object
  {
    achId = "GUILD-OPEN-WATER-BARREL-3658",
    title = "A sip of water (open object test)",
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
    achId = "MURLOC-IN-DUSKWOOD-01",
    title = "Murloc in Duskwood (accurate zone kill test)",
    tooltip = "Find and kill a " .. classColor .. "Murloc|r in Duskwood.",
    icon = 134169,
    points = 5,
    level = nil,
    targetNpcId = 46,
    zone = "Duskwood",
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
    -- IMPORTANT: freeze `def` for the queued closure (PLAYER_LOGIN runs later).
    local d = def
    table_insert(queue, function()
      if (not d.onEmote) and (not d.customKill) and (d.targetNpcId or d.requiredKills or d.requiredQuestId) and addon.registerQuestAchievement then
        addon.registerQuestAchievement{
          achId = d.achId,
          requiredQuestId = d.requiredQuestId,
          targetNpcId = d.targetNpcId,
          requiredKills = d.requiredKills,
          maxLevel = d.level,
          faction = d.faction,
          race = d.race,
          class = d.class,
          allowKillsBeforeQuest = d.allowKillsBeforeQuest,
          zoneAccurate = d.zoneAccurate,
        }
      end
      if RegisterAchievementDef then
        RegisterAchievementDef(d)
      end
      if d.customIsCompleted and addon.RegisterCustomAchievement then
        addon.RegisterCustomAchievement(d.achId, nil, d.customIsCompleted)
      end
      local CreateAchievementRow = addon.CreateAchievementRow
      local AchievementPanel = addon.AchievementPanel
      if CreateAchievementRow and AchievementPanel then
        CreateAchievementRow(
          AchievementPanel,
          d.achId,
          d.title,
          d.tooltip,
          d.icon,
          d.level,
          d.points or 0,
          GetKillTracker(d),
          GetQuestTracker(d),
          d.staticPoints,
          d.zone,
          d
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