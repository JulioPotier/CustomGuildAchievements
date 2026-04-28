local addonName, addon = ...
local UnitBuff = UnitBuff
local UnitClass = UnitClass
local GetClassColor = GetClassColor
local CreateFrame = CreateFrame

-- =========================================================
-- Settings Helpers
-- =========================================================

-- Get a setting value from character database
local function GetSetting(settingName, defaultValue)
    if addon and type(addon.GetCharDB) == "function" then
        local _, cdb = addon.GetCharDB()
        if cdb and cdb.settings then
            local value = cdb.settings[settingName]
            if value ~= nil then
                return value
            end
        end
    end
    return defaultValue
end

-- Set a setting value in character database
local function SetSetting(settingName, value)
    if addon and type(addon.GetCharDB) == "function" then
        local _, cdb = addon.GetCharDB()
        if cdb then
            cdb.settings = cdb.settings or {}
            cdb.settings[settingName] = value
        end
    end
end

-- =========================================================
-- Class Color Helper
-- =========================================================

-- Cache the class color string (player's class doesn't change during session)
local cachedClassColor = nil

-- Initialize class color cache
local function InitializeClassColor()
    if not cachedClassColor then
        -- Use the same method as the original implementation for compatibility
        cachedClassColor = "|c" .. select(4, GetClassColor(select(2, UnitClass("player"))))
    end
    return cachedClassColor
end

local function GetClassColor()
    -- Return cached value, initializing if needed
    if not cachedClassColor then
        InitializeClassColor()
    end
    return cachedClassColor
end

-- Initialize on PLAYER_LOGIN event
local classColorFrame = CreateFrame("Frame")
classColorFrame:RegisterEvent("PLAYER_LOGIN")
classColorFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        InitializeClassColor()
        self:UnregisterAllEvents()
    end
end)

-- =========================================================
-- Character Panel Tab Management
-- =========================================================

-- Get the Character Frame achievement tab
local function GetAchievementTab()
    return _G["CharacterFrameTab" .. (CharacterFrame.numTabs + 1)]
end

-- Check if tab is the achievement tab
local function IsAchievementTab(tab)
    if not tab or not tab.GetText then return false end
    local tabText = tab:GetText()
    if not tabText then return false end
    return tabText:find("Achievement") ~= nil or (_G.ACHIEVEMENTS and tabText:find(_G.ACHIEVEMENTS))
end

-- Show or hide the Character Panel achievement tab based on useCharacterPanel setting
local function UpdateCharacterPanelTabVisibility()
    -- Get the actual Tab frame directly (more reliable than searching by name)
    local tab = nil
    if addon and type(addon.GetTab) == "function" then
        tab = addon.GetTab()
    end
    
    -- Fallback to finding by name if getter not available
    if not tab then
        tab = GetAchievementTab()
        if not tab or not IsAchievementTab(tab) then 
            -- Tab not found, but still call LoadTabPosition which will handle it
            if addon and type(addon.LoadTabPosition) == "function" then
                addon.LoadTabPosition()
            end
            return 
        end
    end
    
    local useCharacterPanel = GetSetting("useCharacterPanel", true)
    
    if useCharacterPanel then
        -- Show custom tab (Character Panel mode) - LoadTabPosition will handle the actual showing
        -- Also restore vertical tab if it was in vertical mode
        if addon and type(addon.LoadTabPosition) == "function" then
            addon.LoadTabPosition()
        end
    else
        -- Hide custom tab (Dashboard mode) - hide immediately
        if tab then
            tab:Hide()
            -- Also hide square frame if it exists
            if tab.squareFrame then
                tab.squareFrame:Hide()
                tab.squareFrame:EnableMouse(false)
            end
        end
        -- Also hide vertical tab immediately
        if addon and type(addon.HideVerticalTab) == "function" then
            addon.HideVerticalTab()
        end
    end
end

-- Set useCharacterPanel setting and update tab visibility
local function SetUseCharacterPanel(enabled)
    SetSetting("useCharacterPanel", enabled)
    
    -- Sync showCustomTab with useCharacterPanel to keep them in sync
    if addon and type(addon.GetCharDB) == "function" then
        local _, cdb = addon.GetCharDB()
        if cdb then
            cdb.settings = cdb.settings or {}
            cdb.settings.showCustomTab = enabled
        end
    end
    
    UpdateCharacterPanelTabVisibility()
    
    -- Reload tab position only when enabling (positioning). When disabling, we already hid it directly.
    if enabled and addon and type(addon.LoadTabPosition) == "function" then
        addon.LoadTabPosition()
    end
end

-- =========================================================
-- Self Found: returns true if player has Self-Found buff, else false.
-- Other files: local IsSelfFound = addon.IsSelfFound; call IsSelfFound() for true/false.
-- =========================================================

local function IsSelfFound()
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, spellId = UnitBuff("player", i)
        if not name then break end
        if spellId == 431567 or name == "Self-Found Adventurer" then
            return true
        end
    end
    return false
end

-- =========================================================
-- Achievement Display Values (centralized for frames and links)
-- =========================================================
local function IsSecretSource(source)
    return source and (
        source.secret or source.isSecretAchievement or
        source.secretTitle or source.secretTooltip or source.secretIcon or source.secretPoints
    ) or false
end

-- Returns icon, title, tooltip, points to display.
-- For frames: pass row/srow with .completed; useSourceCompletion=true (default).
-- For links: pass def; useSourceCompletion=false, viewerCompleted=ViewerHasCompletedAchievement(achId).
-- skipSecrecy: if true (e.g. guild-first), never use secret placeholders.
local function GetAchievementDisplayValues(source, options)
    if not source then return 136116, "Achievement", "", 0 end
    options = options or {}
    local useSourceCompletion = options.useSourceCompletion ~= false
    local viewerCompleted = options.viewerCompleted or false
    local skipSecrecy = options.skipSecrecy or false
    
    local completed = useSourceCompletion and (source.completed == true) or viewerCompleted
    local isSecret = not skipSecrecy and IsSecretSource(source)
    local useSecret = isSecret and not completed
    
    if useSecret then
        return
            source.secretIcon or 134400,
            source.secretTitle or "Secret",
            source.secretTooltip or "Hidden",
            tonumber(source.secretPoints) or 0
    end
    local icon = (source.Icon and source.Icon.GetTexture and source.Icon:GetTexture()) or source.icon or source.revealIcon or 136116
    local title = (source.Title and source.Title.GetText and source.Title:GetText()) or source.title or source.revealTitle or (source.id or source.achId or "")
    local tooltip = source.tooltip or source.revealTooltip or ""
    local points = tonumber(source.points) or 0
    return icon, title, tooltip, points
end

-- =========================================================
-- Guild / Required Target Helpers (shared)
-- =========================================================

local strsplit = strsplit
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local GetTime = GetTime
local C_Timer = C_Timer

local function GetClassIcon()
    local ucp = UnitClass("player")
    local c_tbl =
    {
        ["Paladin"] = "Interface\\AddOns\\CustomGuildAchievements\\Images\\Class_PALADIN.png",
        ["Warrior"] = "Interface\\AddOns\\CustomGuildAchievements\\Images\\Class_WARRIOR.png",
        ["Hunter"] = "Interface\\AddOns\\CustomGuildAchievements\\Images\\Class_HUNTER.png",
        ["Rogue"] = "Interface\\AddOns\\CustomGuildAchievements\\Images\\Class_ROGUE.png",
        ["Priest"] = "Interface\\AddOns\\CustomGuildAchievements\\Images\\Class_PRIEST.png",
        ["Shaman"] = "Interface\\AddOns\\CustomGuildAchievements\\Images\\Class_SHAMAN.png",
        ["Mage"] = "Interface\\AddOns\\CustomGuildAchievements\\Images\\Class_MAGE.png",
        ["Warlock"] = "Interface\\AddOns\\CustomGuildAchievements\\Images\\Class_WARLOCK.png",
        ["Druid"] = "Interface\\AddOns\\CustomGuildAchievements\\Images\\Class_DRUID.png",
    }

    return c_tbl[ucp]
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
            if any then n = n + 1 end
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

local function GetTargetNpcId()
    if not UnitExists("target") then return nil end
    local guid = UnitGUID("target")
    if not guid then return nil end
    local npcId = select(6, strsplit("-", guid))
    return npcId and tonumber(npcId) or nil
end

-- Auto-discover requiredTarget progress on target changes.
-- Option B throttle: 1 write/sec for the same npcId; allow immediate write when npcId changes.
local function SetupRequiredTargetAutoTrack(defs, opts)
    if not addon then return end
    opts = opts or {}
    local throttleSeconds = tonumber(opts.throttleSeconds) or 1.0
    local lastNpcId, lastAt = nil, 0

    local function Refresh()
        if not addon or addon.Disabled then return end
        if not (addon.GetProgress and addon.SetProgress) then return end

        local npcId = GetTargetNpcId()
        if not npcId then return end

        local now = GetTime and GetTime() or 0
        if lastNpcId == npcId then
            if now > 0 and (now - (tonumber(lastAt) or 0)) < throttleSeconds then
                return
            end
        end
        lastNpcId, lastAt = npcId, now

        for _, def in ipairs(defs or {}) do
            if def and def.achId and RequiredTargetContains(def.requiredTarget, npcId) then
                local p = addon.GetProgress(def.achId) or {}
                p.metTargets = type(p.metTargets) == "table" and p.metTargets or {}
                if not p.metTargets[npcId] then
                    p.metTargets[npcId] = true
                    addon.SetProgress(def.achId, "metTargets", p.metTargets)
                end
            end
        end
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGIN" then
            -- In case of login race, try once after a tick
            if C_Timer and C_Timer.After then
                C_Timer.After(0, Refresh)
            end
        end
        Refresh()
    end)
    return f
end

-- =========================================================
-- Achievement Definition Registration
-- =========================================================

-- Unified function to register achievement definitions to AchievementDefs
-- This ensures all achievement types (quest, dungeon, raid, meta, etc.) use the same structure
-- Parameters:
--   def: The achievement definition table (from Catalog files)
--   overrides: Optional table of field overrides (e.g., { level = nil } for raids)
local function RegisterAchievementDef(def, overrides)
    if not def or not def.achId or not addon then
        return
    end
    addon.AchievementDefs = addon.AchievementDefs or {}
    local isSecretDef = IsSecretSource(def)
    
    -- Build the definition entry with all common fields
    local achDef = {
        achId = def.achId,
        title = def.title,
        tooltip = def.tooltip,
        icon = def.icon,
        points = def.points or 0,
        level = def.level,
        -- Attempt / opt-in run state (transport only; logic elsewhere)
        attemptEnabled = def.attemptEnabled,
        timerSet = def.timerSet,
        failOnMount = def.failOnMount,
        failOnDruidCatForm = def.failOnDruidCatForm,
        failOnDruidTravelForm = def.failOnDruidTravelForm,
        failOnHunterAspect = def.failOnHunterAspect,
        failOnShamanGhostWolf = def.failOnShamanGhostWolf,
        walkOnly = def.walkOnly,
        startNpc = def.startNpc,
        startNpcId = def.startNpcId,
        startObjectId = def.startObjectId,
        attemptsAllowed = def.attemptsAllowed,
        -- Optional single-metric data display
        dataLabel = def.dataLabel,
        dataFormat = def.dataFormat,
        dataMode = def.dataMode,
        -- Quest-specific fields
        targetNpcId = def.targetNpcId,
        -- Emote trigger (opt-in): requires targeting targetNpcId and performing the emote (e.g. "wave")
        onEmote = def.onEmote,
        -- Optional proximity gate (opt-in): require CheckInteractDistance("target", 2) at trigger time.
        checkInteractDistance = def.checkInteractDistance,
        requiredKills = def.requiredKills,
        requiredTarget = def.requiredTarget,
        requiredTalkTo = def.requiredTalkTo,
        -- Optional display order for requiredTarget lists (tracker/tooltip); never used for completion logic.
        targetOrder = def.targetOrder,
        requiredQuestId = def.requiredQuestId,
        -- Dungeon/Raid-specific fields
        mapID = def.requiredMapId or def.mapID,
        mapName = def.mapName or def.title,
        bossOrder = def.bossOrder,
        -- Meta-specific fields
        requiredAchievements = def.requiredAchievements,
        achievementOrder = def.achievementOrder,
        -- Common fields
        faction = def.faction,
        race = def.race,
        class = def.class,
        zone = def.zone,
        zoneAccurate = def.zoneAccurate,
        explorationZone = def.explorationZone,
        explorationThreshold = def.explorationThreshold,
        -- Type flags
        isQuest = def.isQuest or false,
        isRaid = def.isRaid or false,
        isHeroicDungeon = def.isHeroicDungeon or false,
        isMetaAchievement = def.isMetaAchievement or false,
        isContinentExploration = def.isContinentExploration or false,
        isVariation = def.isVariation or false,
        baseAchId = def.baseAchId,
        -- Secret achievement fields (for links and UI)
        secret = isSecretDef,
        isSecretAchievement = isSecretDef,
        secretTitle = def.secretTitle,
        secretTooltip = def.secretTooltip,
        secretIcon = def.secretIcon,
        secretPoints = def.secretPoints,
        -- Link display (sender-stable title/tooltip)
        linkUsesSenderTitle = def.linkUsesSenderTitle,
        linkTitle = def.linkTitle,
        linkTooltip = def.linkTooltip,
        -- Tracker/tooltip disclosure controls
        secretTracker = def.secretTracker,
    }
    
    -- Apply any overrides (e.g., raids might set level = nil)
    if overrides then
        for key, value in pairs(overrides) do
            achDef[key] = value
        end
    end
    
    addon.AchievementDefs[tostring(def.achId)] = achDef
end

---------------------------------------
-- Export: internal (addon)
---------------------------------------
-- Minimal NPC name lookup when DungeonCommon has not registered yet (e.g. guild-only TOC).
-- Overwritten by DungeonCommon.registerDungeonAchievement when dungeon defs load.
if addon and type(addon.GetBossName) ~= "function" then
    function addon.GetBossName(npcId)
        if not npcId then return "Mob #?" end
        local id = tonumber(npcId) or npcId
        local t = addon._DungeonBossNameLookup
        if t then
            local n = t[id] or t[tostring(id)]
            if n then return n end
        end
        return ("Mob #%s"):format(tostring(id))
    end
end

if addon then
    addon.GetSetting = GetSetting
    addon.GetClassColor = GetClassColor
    addon.GetClassIcon = GetClassIcon
    addon.GetAchievementDisplayValues = GetAchievementDisplayValues
    addon.UpdateCharacterPanelTabVisibility = UpdateCharacterPanelTabVisibility
    addon.SetUseCharacterPanel = SetUseCharacterPanel
    addon.RegisterAchievementDef = RegisterAchievementDef
    addon.RequiredTargetContains = RequiredTargetContains
    addon.GetMergedMetTargets = GetMergedMetTargets
    addon.CountSatisfiedRequiredTargets = CountSatisfiedRequiredTargets
    addon.CountRequiredTargetEntries = CountRequiredTargetEntries
    addon.SetupRequiredTargetAutoTrack = SetupRequiredTargetAutoTrack
    addon.IsSelfFound = IsSelfFound
end