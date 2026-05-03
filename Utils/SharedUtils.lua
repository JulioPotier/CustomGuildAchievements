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
        -- Optional merchant spend trigger (opt-in): require spending copper at a specific NPC (merchant).
        spendAtNpcId = def.spendAtNpcId,
        spendCopper = def.spendCopper,
        -- Cursor hint icon keyword / texture / FileID (optional).
        withIcon = def.withIcon or def.withicon,
        requiredKills = def.requiredKills,
        requiredTarget = def.requiredTarget,
        requiredTalkTo = def.requiredTalkTo,
        -- Optional display order for requiredTarget lists (tracker/tooltip); never used for completion logic.
        targetOrder = def.targetOrder,
        -- dropItemOn: { itemId, nbItem, npcId } (array style). Intercept bag pickup + target NPC to complete.
        dropItemOn = def.dropItemOn,
        -- useItem: numeric itemId or { itemId = n } — hook UseContainerItem / spell cast (see SetupUseItemTrigger).
        useItem = def.useItem,
        requiredQuestId = def.requiredQuestId,
        -- Dungeon/Raid-specific fields
        mapID = def.requiredMapId or def.mapID,
        mapName = def.mapName or def.title,
        bossOrder = def.bossOrder,
        -- Meta-specific fields
        requiredAchievements = def.requiredAchievements,
        -- Lightweight dependency trigger alias (auto-complete when all done, auto-fail if any failed)
        achiIds = def.achiIds,
        -- Generic count trigger: complete when character has completed at least N addon achievements.
        nbAchis = def.nbAchis,
        -- Visibility / chain unlock: hide until these achievements are completed.
        -- String: single id. Table: all must be completed to unlock.
        unlockedBy = def.unlockedBy,
        achievementOrder = def.achievementOrder,
        -- Common fields
        faction = def.faction,
        race = def.race,
        class = def.class,
        -- Eligibility gate: if true, hide+block for non self-found characters (custom field).
        selfFoundOnly = def.selfFoundOnly,
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

-- =========================================================
-- dropItemOn trigger (bag pickup + target NPC)
-- =========================================================

local function getSimpleNpcIdFromUnit(unit)
    if not unit or not UnitExists(unit) or UnitIsPlayer(unit) then return nil end
    local guid = UnitGUID(unit)
    if not guid then return nil end
    local unitType, _, _, _, _, id = strsplit("-", guid)
    if unitType == "Creature" or unitType == "Vehicle" or unitType == "Pet" then
        return tonumber(id)
    end
    return nil
end

local function getContainerItemLinkCompat(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then
        return C_Container.GetContainerItemLink(bag, slot)
    end
    if GetContainerItemLink then
        return GetContainerItemLink(bag, slot)
    end
    return nil
end

local function getContainerItemInfoCompat(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        return C_Container.GetContainerItemInfo(bag, slot)
    end
    if GetContainerItemInfo then
        local texture, itemCount, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID = GetContainerItemInfo(bag, slot)
        return {
            iconFileID = texture,
            stackCount = itemCount,
            isLocked = locked,
            quality = quality,
            itemLink = itemLink,
            itemID = itemID,
        }
    end
    return nil
end

local function EnsureDropItemOnState()
    if not addon then return nil end
    addon._cgaDropItemOn = addon._cgaDropItemOn or {
        hooked = false,
        last = { t = 0, fromBag = false, itemId = nil, count = nil, link = nil },
        defs = nil, -- map achId -> cfg { itemId, nbItem, npcId }
    }
    return addon._cgaDropItemOn
end

local function BuildDropItemOnDefs()
    if not addon then return nil end
    local defs = addon.AchievementDefs or {}
    local result = {}
    for achId, def in pairs(defs) do
        local d = def
        local cfg = d and d.dropItemOn
        if type(cfg) == "table" then
            -- Required named keys for readability:
            -- dropItemOn = { itemId = 4540, nbItem = 1, npcId = 6174 }
            local itemId = tonumber(cfg.itemId)
            local nbItem = tonumber(cfg.nbItem) or 1
            local npcId = tonumber(cfg.npcId)
            if itemId and npcId then
                result[tostring(achId)] = { itemId = itemId, nbItem = nbItem, npcId = npcId }
            end
        end
    end
    return result
end

local function EnsureUseItemState()
    if not addon then return nil end
    addon._cgaUseItem = addon._cgaUseItem or {
        hooked = false,
        defs = nil, -- map achId -> cfg { itemId }
    }
    return addon._cgaUseItem
end

local function BuildUseItemDefs()
    if not addon then return nil end
    local defs = addon.AchievementDefs or {}
    local result = {}
    for achId, def in pairs(defs) do
        local d = def
        local cfg = d and d.useItem
        local itemId = nil
        if type(cfg) == "number" then
            itemId = tonumber(cfg)
        elseif type(cfg) == "table" then
            itemId = tonumber(cfg.itemId or cfg.id)
        end
        if itemId then
            result[tostring(achId)] = { itemId = itemId }
        end
    end
    return result
end

-- spellId -> { itemId, ... } (useful when hooksecurefunc on UseContainerItem runs *after*
-- consume: stack-count-1 slots may already be empty).
local function BuildUseItemSpellToItems(defMap)
    local rev = {}
    if not defMap then return rev end
    for _, cfg in pairs(defMap) do
        local itemId = cfg and tonumber(cfg.itemId)
        if itemId and itemId > 0 and type(GetItemSpell) == "function" then
            local ok, a, b = pcall(GetItemSpell, itemId)
            local spellId = nil
            if ok and b and type(b) == "number" and b > 0 then
                spellId = b
            elseif ok and a and type(a) == "string" and a ~= "" and type(GetSpellInfo) == "function" then
                local gok, seventh = pcall(function()
                    return select(7, GetSpellInfo(a))
                end)
                if gok then
                    spellId = tonumber(seventh)
                end
            end
            if spellId and spellId > 0 then
                rev[spellId] = rev[spellId] or {}
                table.insert(rev[spellId], itemId)
            end
        end
    end
    return rev
end

local function RefreshUseItemCaches(st)
    if not st then return end
    st.defs = BuildUseItemDefs()
    st.spellToItems = BuildUseItemSpellToItems(st.defs)
end

local function CompleteAchievementById(achId)
    if not addon or not achId then return false end
    local id = tostring(achId)

    -- Respect chain lock: only complete if unlocked (when the engine exposes the helper)
    local def = addon.AchievementDefs and addon.AchievementDefs[id]
    if def and def.unlockedBy and addon.IsUnlockedBy and type(addon.IsUnlockedBy) == "function" then
        if not addon.IsUnlockedBy(def) then
            return false
        end
    end

    local row = addon.GetAchievementRow and addon.GetAchievementRow(id)
    if row then
        -- Prefer toast path when available so completion looks consistent across triggers.
        if addon.MarkRowCompletedWithToast and type(addon.MarkRowCompletedWithToast) == "function" then
            return addon.MarkRowCompletedWithToast(row) == true
        end
        if addon.MarkRowCompleted and type(addon.MarkRowCompleted) == "function" then
            return addon.MarkRowCompleted(row) == true
        end
    end

    -- If the UI row isn't built yet, persist directly.
    if addon.GetCharDB and type(addon.GetCharDB) == "function" then
        local _, cdb = addon.GetCharDB()
        if cdb then
            local skId = addon.GetAchievementStorageKey and addon.GetAchievementStorageKey(id)
            if not skId then return false end
            cdb.achievements = cdb.achievements or {}
            cdb.achievements[skId] = cdb.achievements[skId] or {}
            local rec = cdb.achievements[skId]
            if rec.completed == true then
                return false
            end
            rec.completed = true
            rec.completedAt = rec.completedAt or (time and time() or 0)
            rec.level = rec.level or (UnitLevel("player") or nil)
            if addon.UpdateTotalPoints then addon.UpdateTotalPoints() end
            if addon.RestoreCompletionsFromDB then addon.RestoreCompletionsFromDB() end
            return true
        end
    end
    return false
end

local function TryMatchDropItemOn()
    if not addon or addon.Disabled then return end
    local st = EnsureDropItemOnState()
    if not st then return end
    st.defs = st.defs or BuildDropItemOnDefs()
    if not st.defs or not next(st.defs) then return end

    -- Must be holding an item on the cursor that originated from a bag pickup.
    local last = st.last
    if not last or last.fromBag ~= true or not last.itemId then return end
    if type(GetCursorInfo) == "function" then
        local ctype, cid = GetCursorInfo()
        if ctype ~= "item" or tonumber(cid) ~= tonumber(last.itemId) then
            return
        end
    else
        return
    end

    local npcId = getSimpleNpcIdFromUnit("target")
    if not npcId then return end
    -- Global rule for dropItemOn: require trade-distance proximity to the targeted NPC.
    -- (The client doesn't support NPC trade windows; this is our generic "close enough" gate.)
    if type(CheckInteractDistance) == "function" then
        -- 2 = trade distance (also used elsewhere for "close enough" gates)
        if not CheckInteractDistance("target", 2) then
            return
        end
    end

    for achId, cfg in pairs(st.defs) do
        if cfg and cfg.itemId == last.itemId and cfg.npcId == npcId then
            local need = tonumber(cfg.nbItem) or 1
            local have = tonumber(last.count) or 1
            if have >= need then
                -- Cancel the drag (puts it back) and complete the achievement.
                if ClearCursor then
                    ClearCursor()
                end
                CompleteAchievementById(achId)
                return
            end
        end
    end
end

local function SetupUseItemTrigger()
    if not addon or addon.Disabled then return end
    local st = EnsureUseItemState()
    if not st or st.hooked then return end
    st.hooked = true
    RefreshUseItemCaches(st)

    local function tryCompleteForItemId(itemId)
        if not itemId then return end
        if not st.defs or not next(st.defs) then
            RefreshUseItemCaches(st)
        end
        if not st.defs or not next(st.defs) then return end
        local idNum = tonumber(itemId)
        if not idNum then return end
        for achId, cfg in pairs(st.defs) do
            if cfg and tonumber(cfg.itemId) == idNum then
                CompleteAchievementById(achId)
            end
        end
    end

    local function tryCompleteForSpellId(spellId)
        local sid = tonumber(spellId)
        if not sid or sid <= 0 then return end
        if not st.spellToItems or not next(st.spellToItems) then
            RefreshUseItemCaches(st)
        end
        local list = st.spellToItems and st.spellToItems[sid]
        if not list then return end
        for i = 1, #list do
            tryCompleteForItemId(list[i])
        end
    end

    local function onUseContainerItem(a, b, c, d)
        local bag, slot
        if type(a) == "table" then
            bag, slot = b, c -- hooksecurefunc(C_Container, "UseContainerItem", ...)
        else
            bag, slot = a, b -- hooksecurefunc("UseContainerItem", ...)
        end
        local itemID = nil
        if GetContainerItemID then
            itemID = GetContainerItemID(bag, slot)
        end
        if not itemID then
            local info = getContainerItemInfoCompat(bag, slot)
            itemID = (info and info.itemID) or nil
        end
        if not itemID then
            local link = getContainerItemLinkCompat(bag, slot)
            if link and GetItemInfoInstant then
                itemID = select(1, GetItemInfoInstant(link))
            end
        end
        tryCompleteForItemId(itemID)
    end

    local function onUseInventoryItem(slot)
        local itemID = (GetInventoryItemID and GetInventoryItemID("player", slot)) or nil
        tryCompleteForItemId(itemID)
    end

    local function onUseItemByName(nameOrLinkOrID)
        local itemID = tonumber(nameOrLinkOrID)
        if not itemID and GetItemInfoInstant and nameOrLinkOrID then
            itemID = select(1, GetItemInfoInstant(nameOrLinkOrID))
        end
        tryCompleteForItemId(itemID)
    end

    -- Bag UI often calls *both* legacy global and C_Container; hook every path that exists
    -- (previously only one branch ran, so clic-droit sac pouvait ne jamais appeler notre hook).
    if type(UseContainerItem) == "function" then
        hooksecurefunc("UseContainerItem", onUseContainerItem)
    end
    if C_Container and type(C_Container.UseContainerItem) == "function" then
        hooksecurefunc(C_Container, "UseContainerItem", onUseContainerItem)
    end

    if type(UseInventoryItem) == "function" then
        hooksecurefunc("UseInventoryItem", onUseInventoryItem)
    end

    if type(UseItemByName) == "function" then
        hooksecurefunc("UseItemByName", onUseItemByName)
    end

    -- Barre d’action : UseAction ne passe pas par UseContainerItem.
    local function onUseAction(actionSlot)
        if not actionSlot or type(GetActionInfo) ~= "function" then return end
        local t, id = GetActionInfo(actionSlot)
        if t == "item" and id then
            tryCompleteForItemId(id)
        end
    end
    if type(UseAction) == "function" then
        hooksecurefunc("UseAction", onUseAction)
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LOGIN")
    f:RegisterEvent("BAG_UPDATE_DELAYED")
    f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    f:RegisterEvent("UNIT_SPELLCAST_SENT")
    f:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_LOGIN" or event == "BAG_UPDATE_DELAYED" then
            RefreshUseItemCaches(st)
            return
        end
        if event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_SENT" then
            local unit, _, _, spellId
            if event == "UNIT_SPELLCAST_SUCCEEDED" then
                unit, _, spellId = ...
            else
                unit, _, _, spellId = ...
            end
            if unit == "player" and spellId then
                tryCompleteForSpellId(spellId)
            end
        end
    end)
end

local function SetupDropItemOnTrigger()
    if not addon then return end
    local st = EnsureDropItemOnState()
    if not st or st.hooked then return end
    st.hooked = true
    st.defs = BuildDropItemOnDefs()

    local function onPickupContainerItem(a, b, c)
        local bag, slot
        if type(a) == "table" then
            bag, slot = b, c -- hooksecurefunc(C_Container, "PickupContainerItem", ...)
        else
            bag, slot = a, b -- hooksecurefunc("PickupContainerItem", ...)
        end

        local link = getContainerItemLinkCompat(bag, slot)
        local info = getContainerItemInfoCompat(bag, slot)

        st.last.t = (GetTime and GetTime()) or 0
        st.last.fromBag = true
        st.last.link = link
        st.last.count = (info and info.stackCount) or nil
        local itemID = (info and info.itemID) or nil
        if not itemID and link and GetItemInfoInstant then
            itemID = select(1, GetItemInfoInstant(link))
        end
        st.last.itemId = itemID

        -- If the player is already targeting the NPC, complete immediately.
        TryMatchDropItemOn()
    end

    if PickupContainerItem then
        hooksecurefunc("PickupContainerItem", onPickupContainerItem)
    elseif C_Container and C_Container.PickupContainerItem then
        hooksecurefunc(C_Container, "PickupContainerItem", onPickupContainerItem)
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", function()
        -- Refresh defs (catalog may have registered after we were hooked).
        st.defs = BuildDropItemOnDefs()
        TryMatchDropItemOn()
    end)
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
    addon.SetupDropItemOnTrigger = SetupDropItemOnTrigger
    addon.SetupUseItemTrigger = SetupUseItemTrigger
    addon.IsSelfFound = IsSelfFound
end