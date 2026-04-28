-- Achievements/CustomCatalog.lua
-- User-customizable catalog: keep your personal achievements here.

local addonName, addon = ...
local table_insert = table.insert
local guildName = "|cffffd100" .. (GetGuildInfo("player") or (_G.CGA_GUILD_NAME or "No Guild")) .. "|r"
local classColor = (addon and addon.GetClassColor and addon.GetClassColor()) or "|cffffd100"
local rawPlayerName = UnitName("player")
local playerName = classColor .. rawPlayerName .. "|r"
local playerClass = classColor .. UnitClass("player") .. "|r"

local CustomAchievements = {
  -- Example 1: target an NPC and /wave (locale-proof via DoEmote hook)
  {
    achId = "CUSTOM-EMOTE-HELLO-GUARD",
    title = "Polite citizen",
    tooltip = "Talk to Melris Malagan and perform a /wave (while standing close enough).",
    icon = 132485,
    points = 5,
    level = nil,
    targetNpcId = 12480, -- Melris Malagan
    onEmote = "hello",
    checkInteractDistance = true,
    withIcon = "gossip",
  },

  -- Example 2: simple kill achievement
  {
    achId = "CUSTOM-KILL-SPIDER-30",
    title = "Bug squasher",
    tooltip = "Kill a Forest Spider in Duskwood.",
    icon = 134321,
    points = 5,
    level = nil,
    targetNpcId = 30, -- Forest Spider
    zoneAccurate = 1431,
    zone = "Duskwood",
  },

  -- Example 2b: target a specific player by name (string targetNpcId)
  {
    achId = "CUSTOM-TARGET-PLAYER-NIGHTGLIMMER",
    title = "Found you",
    tooltip = "Target the player Nightglimmer.",
    icon = 134216, -- Elf icon
    points = 5,
    level = nil,
    targetNpcId = "Mavenrage",
  },

  -- Example 3: spend a few copper at Frederick Stover (merchant)
  {
    achId = "CUSTOM-BUY-BREAD-THOMAS-MILLER-3518",
    title = "Breadwinner",
    tooltip = "Buy some bread from Thomas Miller.",
    icon = 133784,
    points = 5,
    level = nil,
    startNpc = { npcId = 3518 }, -- Thomas Miller
    spendAtNpcId = 3518,
    spendCopper = 20, -- at least 20 copper
  },
  
  -- Example 4: spend a few copper at Topper McNabb (beggar)
  {
    achId = "CUSTOM-SPEND-GOLD-TOPPER-1402",
    title = "Alms for the poor",
    tooltip = "Could ye spare some coin?",
    icon = 133784,
    points = 5,
    level = nil,
    startNpc = {
      npcId = 1402,
      window = {
        title = "Topper McNabb",
        text = "Could ye spare some coin? 5 {gold} should do it.\n\nI will gladly pay you Tuesday for a hamburger today.",
        buttonLabel = "Give him the money",
        callback = function()
          local money = GetMoney and GetMoney() or 0
          local hasGold = money >= 50000 -- 5 gold in copper
          if hasGold then
            if addon and addon._cgaPlayWindowSound then addon._cgaPlayWindowSound("coins") end
            local c = ChatTypeInfo and ChatTypeInfo.SAY
            local msg = "Topper McNabb says: Thank you for your generosity " .. playerName .. ". Long life to " .. guildName .. "!"
            if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage and c then
              DEFAULT_CHAT_FRAME:AddMessage(msg, c.r, c.g, c.b)
              DEFAULT_CHAT_FRAME:AddMessage("Topper McNabb says: Wait, where is my gold??", c.r, c.g, c.b)
            else
              print(msg)
              print("Topper McNabb says: Wait, where is my gold??")
            end
            return true
          end

          if addon and addon._cgaPlayWindowSound then addon._cgaPlayWindowSound(SOUNDKIT.GS_TITLE_OPTION_EXIT) end

          -- NPC says message (say color)
          local c = ChatTypeInfo and ChatTypeInfo.SAY
          local failMsg = "Topper McNabb says: Damn, I won't eat anything again today..."
          if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage and c then
            DEFAULT_CHAT_FRAME:AddMessage(failMsg, c.r, c.g, c.b)
          else
            print(failMsg)
          end
          return false
        end,
      },
    },
    checkInteractDistance = true,
  },
  
}

-- Enable requiredTarget auto-discovery from target changes (shared utility).
if addon and type(addon.SetupRequiredTargetAutoTrack) == "function" then
  addon.SetupRequiredTargetAutoTrack(CustomAchievements, { throttleSeconds = 1.0 })
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

  for _, def in ipairs(CustomAchievements) do
    def.isGuild = true

    -- Also append to the main guild list for UIs that read addon.GuildAchievements.
    if addon.GuildAchievements then
      table_insert(addon.GuildAchievements, def)
    end

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

  addon.CustomAchievements = CustomAchievements
end

