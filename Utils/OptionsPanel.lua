local addonName, addon = ...
local GetCharDB = addon and addon.GetCharDB
local GetGuildInfo = GetGuildInfo

local function ShouldShowAdventureCoTabardDecor()
    local g = GetGuildInfo and GetGuildInfo("player")
    local want = (_G.CGA_TABARD_GUILD_NAME) or "Adventure Co"
    return g and want and g == want
end

local function UpdateAdventureCoTabardDecor(texture)
    if not texture then return end
    if ShouldShowAdventureCoTabardDecor() then
        texture:Show()
    else
        texture:Hide()
    end
end

-- Load AceSerializer (still needed for old format fallback)
local AceSerialize = LibStub("AceSerializer-3.0")

-- Use the standalone encoding functions from DataEncoding.lua
-- EncodeData and DecodeData are available globally after DataEncoding.lua loads

-- Helper function to get settings
local function GetSetting(settingName, defaultValue)
    if type(GetCharDB) == "function" then
        local _, cdb = GetCharDB()
        if cdb and cdb.settings then
            local value = cdb.settings[settingName]
            if value ~= nil then
                return value
            end
        end
    end
    return defaultValue
end

-- Helper function to set settings
local function SetSetting(settingName, value)
    if type(GetCharDB) == "function" then
        local _, cdb = GetCharDB()
        if cdb then
            cdb.settings = cdb.settings or {}
            cdb.settings[settingName] = value
        end
    end
end

-- Helper function to check if screenshots are disabled (called before Screenshot in HardcoreAchievements.lua)
local function ShouldTakeScreenshot()
    if type(GetCharDB) == "function" then
        local _, cdb = GetCharDB()
        if cdb and cdb.settings and cdb.settings.disableScreenshots then
            return false
        end
    end
    return true
end

-- Helper function to check if solo achievements mode is enabled
local function IsSoloModeEnabled()
    if type(GetCharDB) == "function" then
        local _, cdb = GetCharDB()
        if cdb and cdb.settings and cdb.settings.soloAchievements then
            return true
        end
    end
    return false
end

-- Helper function to check if award on kill is enabled
local function IsAwardOnKillEnabled()
    return false
end

-- Helper function to check if achievements should be announced in guild chat (default: true)
local function ShouldAnnounceInGuildChat()
    if type(GetCharDB) == "function" then
        local _, cdb = GetCharDB()
        if cdb and cdb.settings then
            if cdb.settings.announceInGuildChat == false then
                return false
            end
            return true
        end
    end
    return true
end

local CGA_ISSUES_URL = "https://github.com/JulioPotier/CustomGuildAchievements/issues"
if StaticPopupDialogs and not StaticPopupDialogs["CGA_COPY_ISSUES_URL"] then
    StaticPopupDialogs["CGA_COPY_ISSUES_URL"] = {
        text = "Copy the URL (Ctrl+C) and open it in your browser:",
        button1 = OKAY,
        hasEditBox = 1,
        editBoxWidth = 380,
        maxLetters = #CGA_ISSUES_URL + 8,
        OnShow = function(self)
            self.editBox:SetText(CGA_ISSUES_URL)
            self.editBox:HighlightText()
            self.editBox:SetFocus()
        end,
        EditBoxOnEnterPressed = function(self)
            self:GetParent():Hide()
        end,
        timeout = 0,
        exclusive = 0,
        whileDead = 1,
        hideOnEscape = 1,
    }
end

-- =========================================================
-- Backup/Restore Database Frame (Unified with Tabs)
-- =========================================================

-- Unified backup/restore frame (will be created on first use)
local backupRestoreFrame = nil
local activeTab = "Backup" -- "Backup" or "Restore"

-- Function to switch tabs
local function SwitchTab(tabName)
    activeTab = tabName
    local frame = backupRestoreFrame
    if not frame then return end
    
    -- Update tab selection
    for _, tab in pairs(frame.tabs) do
        if tab.tabName == tabName then
            PanelTemplates_SelectTab(tab)
        else
            PanelTemplates_DeselectTab(tab)
        end
    end
    
    -- Show/hide content panels
    if tabName == "Backup" then
        frame.backupPanel:Show()
        frame.restorePanel:Hide()
    else
        frame.backupPanel:Hide()
        frame.restorePanel:Show()
        -- Auto-focus the import edit box when switching to restore tab
        if frame.restorePanel.editBox then
            frame.restorePanel.editBox:SetText("Paste your backup string here...")
            frame.restorePanel.editBox:SetFocus()
            frame.restorePanel.editBox:HighlightText()
        end
    end
end

local function CreateBackupRestoreFrame()
    if backupRestoreFrame then return backupRestoreFrame end
    
    -- Create the main frame
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(600, 335)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:Hide()
    
    -- Title background
    local titlebg = frame:CreateTexture(nil, "BORDER")
    titlebg:SetTexture(251966) --"Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background"
    titlebg:SetPoint("TOPLEFT", 9, -6)
    titlebg:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -28, -24)
    
    -- Dialog background
    local dialogbg = frame:CreateTexture(nil, "BACKGROUND")
    dialogbg:SetTexture(136548) --"Interface\\PaperDollInfoFrame\\UI-Character-CharacterTab-L1"
    dialogbg:SetPoint("TOPLEFT", 8, -12)
    dialogbg:SetPoint("BOTTOMRIGHT", -6, 8)
    dialogbg:SetTexCoord(0.255, 1, 0.29, 1)
    
    -- Borders
    local topleft = frame:CreateTexture(nil, "BORDER")
    topleft:SetTexture(251963) --"Interface\\PaperDollInfoFrame\\UI-GearManager-Border"
    topleft:SetWidth(64)
    topleft:SetHeight(64)
    topleft:SetPoint("TOPLEFT")
    topleft:SetTexCoord(0.501953125, 0.625, 0, 1)
    
    local topright = frame:CreateTexture(nil, "BORDER")
    topright:SetTexture(251963)
    topright:SetWidth(64)
    topright:SetHeight(64)
    topright:SetPoint("TOPRIGHT")
    topright:SetTexCoord(0.625, 0.75, 0, 1)
    
    local top = frame:CreateTexture(nil, "BORDER")
    top:SetTexture(251963)
    top:SetHeight(64)
    top:SetPoint("TOPLEFT", topleft, "TOPRIGHT")
    top:SetPoint("TOPRIGHT", topright, "TOPLEFT")
    top:SetTexCoord(0.25, 0.369140625, 0, 1)
    
    local bottomleft = frame:CreateTexture(nil, "BORDER")
    bottomleft:SetTexture(251963)
    bottomleft:SetWidth(64)
    bottomleft:SetHeight(64)
    bottomleft:SetPoint("BOTTOMLEFT")
    bottomleft:SetTexCoord(0.751953125, 0.875, 0, 1)
    
    local bottomright = frame:CreateTexture(nil, "BORDER")
    bottomright:SetTexture(251963)
    bottomright:SetWidth(64)
    bottomright:SetHeight(64)
    bottomright:SetPoint("BOTTOMRIGHT")
    bottomright:SetTexCoord(0.875, 1, 0, 1)
    
    local bottom = frame:CreateTexture(nil, "BORDER")
    bottom:SetTexture(251963)
    bottom:SetHeight(64)
    bottom:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMRIGHT")
    bottom:SetPoint("BOTTOMRIGHT", bottomright, "BOTTOMLEFT")
    bottom:SetTexCoord(0.376953125, 0.498046875, 0, 1)
    
    local left = frame:CreateTexture(nil, "BORDER")
    left:SetTexture(251963)
    left:SetWidth(64)
    left:SetPoint("TOPLEFT", topleft, "BOTTOMLEFT")
    left:SetPoint("BOTTOMLEFT", bottomleft, "TOPLEFT")
    left:SetTexCoord(0.001953125, 0.125, 0, 1)
    
    local right = frame:CreateTexture(nil, "BORDER")
    right:SetTexture(251963)
    right:SetWidth(64)
    right:SetPoint("TOPRIGHT", topright, "BOTTOMRIGHT")
    right:SetPoint("BOTTOMRIGHT", bottomright, "TOPRIGHT")
    right:SetTexCoord(0.1171875, 0.2421875, 0, 1)
    
    -- Title
    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOP", 0, -7)
    titleText:SetText("Backup and Restore Database")
    titleText:SetTextColor(1, 1, 1, 1)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", 2, 2)
    closeButton:SetScript("OnClick", function(self)
        frame:Hide()
    end)
    
    -- Make frame movable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- =========================================================
    -- Create Tabs
    -- =========================================================
    local backupTab = CreateFrame("Button", "HardcoreAchievementsBackupTab", frame, "CharacterFrameTabButtonTemplate")
    backupTab:SetFrameStrata("FULLSCREEN")
    backupTab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 8)
    backupTab:SetText("Backup")
    backupTab.tabName = "Backup"
    backupTab:SetScript("OnLoad", nil)
    backupTab:SetScript("OnShow", nil)
    backupTab:SetScript("OnClick", function() SwitchTab("Backup") end)
    
    local restoreTab = CreateFrame("Button", "HardcoreAchievementsRestoreTab", frame, "CharacterFrameTabButtonTemplate")
    restoreTab:SetFrameStrata("FULLSCREEN")
    restoreTab:SetPoint("LEFT", backupTab, "RIGHT")
    restoreTab:SetText("Restore")
    restoreTab.tabName = "Restore"
    restoreTab:SetScript("OnLoad", nil)
    restoreTab:SetScript("OnShow", nil)
    restoreTab:SetScript("OnClick", function() SwitchTab("Restore") end)
    
    frame.tabs = { backupTab, restoreTab }
    local tabSize = 200 / 2
    PanelTemplates_TabResize(backupTab, nil, tabSize, tabSize)
    PanelTemplates_TabResize(restoreTab, nil, tabSize, tabSize)
    PanelTemplates_SelectTab(backupTab)
    PanelTemplates_DeselectTab(restoreTab)
    
    -- =========================================================
    -- Backup Panel
    -- =========================================================
    local backupPanel = CreateFrame("Frame", nil, frame)
    backupPanel:SetAllPoints(frame)
    backupPanel:SetFrameLevel(frame:GetFrameLevel() + 1)
    
    -- Instructions text
    local instructionsText = backupPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    instructionsText:SetPoint("TOP", titleText, "BOTTOM", 0, -10)
    instructionsText:SetText("Copy the text below and save it as a backup. This includes all characters, achievements, progress, and settings.")
    instructionsText:SetTextColor(0.8, 0.8, 0.8, 1)
    instructionsText:SetWidth(550)
    instructionsText:SetJustifyH("CENTER")
    
    -- Static black background rectangle for text area with backdrop
    local backupBgFrame = CreateFrame("Frame", nil, backupPanel, "BackdropTemplate")
    backupBgFrame:SetPoint("TOP", instructionsText, "BOTTOM", -10, -10)
    backupBgFrame:SetSize(550, 260)
    backupBgFrame:SetFrameLevel(backupPanel:GetFrameLevel() - 1) -- Behind scroll frame
    
    backupBgFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 64,
        edgeSize = 16,
        insets = {
            left = 3,
            right = 3,
            top = 3,
            bottom = 3,
        },
    })
    backupBgFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.95) -- Darker, more solid background
    backupBgFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8) -- Softer border
    
    -- Scroll frame for the serialized data
    local backupScrollFrame = CreateFrame("ScrollFrame", nil, backupPanel, "UIPanelScrollFrameTemplate")
    backupScrollFrame:SetPoint("TOP", instructionsText, "BOTTOM", -5, -15)
    backupScrollFrame:SetSize(550, 250)
    
    -- Edit box for the serialized data (read-only)
    local backupEditBox = CreateFrame("EditBox", nil, backupScrollFrame)
    backupEditBox:SetMultiLine(true)
    backupEditBox:SetFontObject("GameFontHighlightSmall")
    backupEditBox:SetWidth(530)
    backupEditBox:SetHeight(250)
    backupEditBox:SetAutoFocus(true)
    backupEditBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        frame:Hide()
    end)
    
    -- Make read-only (allow selection but prevent editing)
    backupEditBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    
    backupEditBox:SetScript("OnChar", function(self)
        -- Prevent any text input - restore original text
        if self.originalText then
            self:SetText(self.originalText)
        end
    end)
    
    backupScrollFrame:SetScrollChild(backupEditBox)
    backupPanel.editBox = backupEditBox
    
    -- =========================================================
    -- Restore Panel
    -- =========================================================
    local restorePanel = CreateFrame("Frame", nil, frame)
    restorePanel:SetAllPoints(frame)
    restorePanel:SetFrameLevel(frame:GetFrameLevel() + 1)
    restorePanel:Hide()
    
    -- Warning text
    local warningText = restorePanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    warningText:SetPoint("TOP", titleText, "BOTTOM", 0, -10)
    warningText:SetText("|cffff0000WARNING:|r This will replace your entire database including all characters, achievements, progress, and settings. Paste your backup string below and click Import.")
    warningText:SetTextColor(1, 0.8, 0.8, 1)
    warningText:SetWidth(550)
    warningText:SetJustifyH("CENTER")
    
    -- Static black background rectangle for text area with backdrop
    local restoreBgFrame = CreateFrame("Frame", nil, restorePanel, "BackdropTemplate")
    restoreBgFrame:SetPoint("TOP", warningText, "BOTTOM", -10, -10)
    restoreBgFrame:SetSize(550, 230)
    restoreBgFrame:SetFrameLevel(restorePanel:GetFrameLevel() - 1) -- Behind scroll frame
    
    restoreBgFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 64,
        edgeSize = 16,
        insets = {
            left = 3,
            right = 3,
            top = 3,
            bottom = 3,
        },
    })
    restoreBgFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.95) -- Darker, more solid background
    restoreBgFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8) -- Softer border
    
    -- Scroll frame for the input
    local restoreScrollFrame = CreateFrame("ScrollFrame", nil, restorePanel, "UIPanelScrollFrameTemplate")
    restoreScrollFrame:SetPoint("TOP", warningText, "BOTTOM", -5, -15)
    restoreScrollFrame:SetSize(550, 210)
    
    -- Edit box for pasting the serialized data
    local restoreEditBox = CreateFrame("EditBox", nil, restoreScrollFrame)
    restoreEditBox:SetMultiLine(true)
    restoreEditBox:SetFontObject("GameFontHighlightSmall")
    restoreEditBox:SetWidth(530)
    restoreEditBox:SetHeight(200)
    restoreEditBox:SetAutoFocus(true)
    restoreEditBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        frame:Hide()
    end)
    
    restoreScrollFrame:SetScrollChild(restoreEditBox)
    restorePanel.editBox = restoreEditBox
    
    -- Import button
    local importButton = CreateFrame("Button", nil, restorePanel, "UIPanelButtonTemplate")
    importButton:SetPoint("TOP", restoreScrollFrame, "BOTTOM", 0, -15)
    importButton:SetText("Import Database and Reload UI")
    importButton:SetWidth(210)
    importButton:SetHeight(30)
    importButton:SetScript("OnClick", function(self)
        local text = restoreEditBox:GetText()
        if not text or text:match("^%s*$") then
            print("|cffff0000Custom Guild Achievements:|r No data provided to import.")
            return
        end
        
        -- Try to decode and deserialize
        local success, data = addon.DecodeData(text)
        if not success then
            -- Fallback: try old format (non-encoded) for backward compatibility
            local oldSuccess, oldData = AceSerialize:Deserialize(text)
            if oldSuccess then
                success = true
                data = oldData
                print("|cffffd100Custom Guild Achievements:|r Using old format (non-encoded) backup.")
            else
                print("|cffff0000Custom Guild Achievements:|r Failed to import database. Invalid backup string.")
                return
            end
        end
        
        -- Validate that it looks like the full database structure
        if type(data) ~= "table" or not data.chars or type(data.chars) ~= "table" then
            print("|cffff0000Custom Guild Achievements:|r Invalid backup data format. Expected full database structure with 'chars' table.")
            return
        end
        
        -- Import the entire database structure
        if addon and addon.CustomGuildAchievementsDB then
            -- Deep copy function
            local function DeepCopy(orig)
                local orig_type = type(orig)
                local copy
                if orig_type == 'table' then
                    copy = {}
                    for orig_key, orig_value in next, orig, nil do
                        copy[DeepCopy(orig_key)] = DeepCopy(orig_value)
                    end
                    setmetatable(copy, DeepCopy(getmetatable(orig)))
                else
                    copy = orig
                end
                return copy
            end
            
            -- Replace the entire database with imported data (write to SavedVariables global so it persists)
            local imported = DeepCopy(data)
            CustomGuildAchievementsDB = imported
            if addon then addon.CustomGuildAchievementsDB = CustomGuildAchievementsDB end
            
            print("|cff00ff00Custom Guild Achievements:|r Database imported successfully! All characters and settings have been restored.")
            print("|cffffd100Custom Guild Achievements:|r Reloading UI...")
            
            -- Close the frame
            frame:Hide()
            
            -- Reload UI to ensure everything is properly refreshed
            ReloadUI()
        else
            print("|cffff0000Custom Guild Achievements:|r Database not available.")
        end
    end)
    
    -- Store references
    frame.backupPanel = backupPanel
    frame.restorePanel = restorePanel
    
    backupRestoreFrame = frame
    return frame
end

-- Function to export database
local function ExportDatabase()
    -- Access the full database structure
    if not addon or not addon.CustomGuildAchievementsDB then
        print("|cffff0000Custom Guild Achievements:|r No database found.")
        return
    end
    
    -- Create a deep copy of the entire database structure
    local function DeepCopy(orig)
        local orig_type = type(orig)
        local copy
        if orig_type == 'table' then
            copy = {}
            for orig_key, orig_value in next, orig, nil do
                copy[DeepCopy(orig_key)] = DeepCopy(orig_value)
            end
            setmetatable(copy, DeepCopy(getmetatable(orig)))
        else
            copy = orig
        end
        return copy
    end
    
    local exportData = DeepCopy(addon.CustomGuildAchievementsDB)
    
    -- Serialize, compress, and encode the data
    local encoded = addon.EncodeData(exportData)
    
    -- Show the unified backup/restore frame with Backup tab active
    local frame = CreateBackupRestoreFrame()
    SwitchTab("Backup")
    frame.backupPanel.editBox:SetText(encoded)
    frame.backupPanel.editBox.originalText = encoded
    frame.backupPanel.editBox:HighlightText() -- Select all text for easy copying
    frame:Show()
end

-- Create the main options panel
local function CreateOptionsPanel()
    -- Create the panel frame
    local panel = CreateFrame("Frame")
    
    -- Create title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Custom Guild Achievements")
    --title:SetFont("Interface\\Addons\\MyAddon\\Fonts\\MyCustomFont.ttf", 20)
    title:SetTextColor(1, 1, 1, 1)

    -- Version (from .toc metadata when available)
    local version = "1.5333"
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        local ok, v = pcall(C_AddOns.GetAddOnMetadata, addonName, "Version")
        if ok and v and v ~= "" then version = v end
    elseif GetAddOnMetadata then
        local v = GetAddOnMetadata(addonName, "Version")
        if v and v ~= "" then version = v end
    end
    local versionText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    versionText:SetPoint("LEFT", title, "RIGHT", 10, 0)
    versionText:SetText("|cff888888v" .. tostring(version) .. "|r")

    -- Decorative guild tabard image
    local tabard = panel:CreateTexture(nil, "ARTWORK")
    tabard:SetTexture("Interface\\AddOns\\CustomGuildAchievements\\Images\\tabard-guild.png")
    -- Keep a "tabard-like" aspect ratio (taller than wide) to avoid squishing.
    tabard:SetSize(96, 96)
    tabard:SetPoint("TOPRIGHT", -22, -10)
    tabard:SetAlpha(1)
    UpdateAdventureCoTabardDecor(tabard)
    
    -- Create subtitle/description
    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Configure settings for the Custom Guild Achievements addon")
    subtitle:SetTextColor(0.7, 0.7, 0.7, 1)

    panel.divider = panel:CreateTexture(nil, "ARTWORK")
    panel.divider:SetAtlas("Options_HorizontalDivider", true)
    panel.divider:SetPoint("TOP", 0, -60)
    
    -- =========================================================
    -- Miscellaneous Category
    -- =========================================================
    local miscCategoryTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    miscCategoryTitle:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -40)
    miscCategoryTitle:SetText("|cff008066Miscellaneous|r")
    
    -- Helper function to add tooltip to checkboxes
    local function AddTooltipToCheckbox(cb, tooltipText)
        cb.tooltip = tooltipText
        cb:SetScript("OnEnter", function(self)
            if self.tooltip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, true)
                GameTooltip:Show()
            end
        end)
        cb:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end

    -- Disable Screenshots checkbox
    local disableScreenshotsCB = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    disableScreenshotsCB:SetPoint("TOPLEFT", miscCategoryTitle, "BOTTOMLEFT", 0, -8)
    disableScreenshotsCB.Text:SetText("Disable Screenshots")
    disableScreenshotsCB:SetChecked(GetSetting("disableScreenshots", false))
    disableScreenshotsCB:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        SetSetting("disableScreenshots", isChecked)
    end)
    AddTooltipToCheckbox(disableScreenshotsCB, "Prevent the addon from taking screenshots when achievements are completed.")

    -- Announce achievements in guild chat checkbox
    local announceInGuildChatCB = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    announceInGuildChatCB:SetPoint("TOPLEFT", disableScreenshotsCB, "BOTTOMLEFT", 0, -8)
    announceInGuildChatCB.Text:SetText("Announce achievements in guild chat")
    announceInGuildChatCB:SetChecked(GetSetting("announceInGuildChat", true))
    announceInGuildChatCB:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        SetSetting("announceInGuildChat", isChecked)
    end)
    AddTooltipToCheckbox(announceInGuildChatCB, "If enabled, achievements will be announced in guild chat when completed.")

    -- =========================================================
    -- User Interface Category
    -- =========================================================
    local uiCategoryTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    uiCategoryTitle:SetPoint("TOPLEFT", announceInGuildChatCB, "BOTTOMLEFT", 0, -15)
    uiCategoryTitle:SetText("|cff008066User Interface|r")
    
    -- Reset Achievements Tab button
    local resetTabButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetTabButton:SetPoint("TOPLEFT", uiCategoryTitle, "BOTTOMLEFT", 0, -8)
    resetTabButton:SetText("Reset Achievements Tab Position")
    resetTabButton:SetWidth(220)
    resetTabButton:SetHeight(25)
    resetTabButton:SetScript("OnClick", function(self)
        if addon and type(addon.ResetTabPosition) == "function" then
            addon.ResetTabPosition()
        end
    end)
    AddTooltipToCheckbox(resetTabButton, "Used to reset the position of the Achievements tab in case it's hidden")
    
    -- =========================================================
    -- Backup & Restore Category
    -- =========================================================
    local backupCategoryTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    backupCategoryTitle:SetPoint("TOPLEFT", resetTabButton, "BOTTOMLEFT", 0, -15)
    backupCategoryTitle:SetText("|cff008066Backup & Restore|r")
    
    -- Backup and Restore Database button (opens unified frame with tabs)
    local backupRestoreButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    backupRestoreButton:SetPoint("TOPLEFT", backupCategoryTitle, "BOTTOMLEFT", 0, -8)
    backupRestoreButton:SetText("Backup and Restore Database")
    backupRestoreButton:SetWidth(220)
    backupRestoreButton:SetHeight(25)
    backupRestoreButton:SetScript("OnClick", function(self)
        -- Open the frame and switch to Backup tab, then load backup data
        local frame = CreateBackupRestoreFrame()
        SwitchTab("Backup")
        ExportDatabase()
    end)
    AddTooltipToCheckbox(backupRestoreButton, "Open the backup and restore window with tabs for exporting or importing your database")
    
    -- =========================================================
    -- Support & Contact Category
    -- =========================================================
    local supportCategoryTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    supportCategoryTitle:SetPoint("TOPLEFT", backupRestoreButton, "BOTTOMLEFT", 0, -15)
    supportCategoryTitle:SetText("|cff008066Support & Contact|r")
    
    -- Support text
    local supportText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    supportText:SetPoint("TOPLEFT", supportCategoryTitle, "BOTTOMLEFT", 0, -8)
    supportText:SetText("Found a bug or want to make an appeal? Please provide clear evidence of your player name, level, and what the issue is.")
    supportText:SetTextColor(0.8, 0.8, 0.8, 1)
    supportText:SetWidth(600)
    supportText:SetJustifyH("LEFT")
    supportText:SetJustifyV("TOP")

    -- Logs button
    local logsButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    logsButton:SetPoint("TOPLEFT", supportText, "BOTTOMLEFT", 0, -12)
    logsButton:SetText("Logs")
    logsButton:SetWidth(120)
    logsButton:SetHeight(25)
    logsButton:SetScript("OnClick", function()
        if addon and addon.EventLogShow then
            addon.EventLogShow()
        end
    end)
    AddTooltipToCheckbox(logsButton, "Click to open Logs")

    -- =========================================================
    -- Credits
    -- =========================================================
    local creditsCategoryTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    creditsCategoryTitle:SetPoint("TOPLEFT", logsButton, "BOTTOMLEFT", 0, -15)
    creditsCategoryTitle:SetText("|cff008066Credits|r")
    
    -- Credits text
    local creditsText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    creditsText:SetPoint("TOPLEFT", creditsCategoryTitle, "BOTTOMLEFT", 0, -8)
    creditsText:SetText("Forked from |cffffff00HardcoreAchievements|r\nDev by |cffffff00Kirby2112|r")
    creditsText:SetTextColor(0.8, 0.8, 0.8, 1)
    creditsText:SetWidth(600)
    creditsText:SetJustifyH("LEFT")
    creditsText:SetJustifyV("TOP")

    local issuesIntro = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    issuesIntro:SetPoint("TOPLEFT", creditsText, "BOTTOMLEFT", 0, -12)
    issuesIntro:SetWidth(600)
    issuesIntro:SetJustifyH("LEFT")
    issuesIntro:SetJustifyV("TOP")
    issuesIntro:SetText("Report bugs / issues:")
    issuesIntro:SetTextColor(0.8, 0.8, 0.8, 1)

    local issuesButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    issuesButton:SetPoint("TOPLEFT", issuesIntro, "BOTTOMLEFT", 0, -8)
    issuesButton:SetText("GitHub Issues")
    issuesButton:SetWidth(150)
    issuesButton:SetHeight(25)
    issuesButton:SetScript("OnClick", function()
        if C_Link and type(C_Link.OpenURL) == "function" then
            C_Link.OpenURL(CGA_ISSUES_URL)
        else
            StaticPopup_Show("CGA_COPY_ISSUES_URL")
        end
    end)
    AddTooltipToCheckbox(issuesButton, CGA_ISSUES_URL)
    
    -- Store references for future use
    panel.checkboxes = {
        disableScreenshots = disableScreenshotsCB,
        announceInGuildChat = announceInGuildChatCB,
        modernRows = modernRowsCB,
    }
    panel.modernRows = modernRowsCB
    panel.buttons = {
        resetAchievementsTab = resetTabButton,
        backupRestore = backupRestoreButton,
    }

    -- Refresh function to update checkboxes when panel is shown
    panel.refresh = function(self)
        -- Update checkbox state from database
        if disableScreenshotsCB then
            disableScreenshotsCB:SetChecked(GetSetting("disableScreenshots", false))
        end
        if announceInGuildChatCB then
            announceInGuildChatCB:SetChecked(GetSetting("announceInGuildChat", true))
        end
        if modernRowsCB then
            modernRowsCB:SetChecked(GetSetting("modernRows", true))
        end
        UpdateAdventureCoTabardDecor(tabard)
    end
    
    -- Register with Settings API (newer API for Classic Era)
    local category = Settings.RegisterCanvasLayoutCategory(panel, "Custom Guild Achievements")
    Settings.RegisterAddOnCategory(category)
    
    -- Store category in addon table (similar to BugSack pattern)
    -- Access addon table from global namespace
    addon.settingsCategory = category
    
    return panel
end

-- Initialize the options panel when the addon loads
local optionsPanel = CreateOptionsPanel()

local function ShowBackupRestore()
    local frame = CreateBackupRestoreFrame()
    SwitchTab("Backup")
    ExportDatabase()
end

if addon then
    addon.ShouldTakeScreenshot = ShouldTakeScreenshot
    addon.IsSoloModeEnabled = IsSoloModeEnabled
    addon.IsAwardOnKillEnabled = IsAwardOnKillEnabled
    addon.ShouldAnnounceInGuildChat = ShouldAnnounceInGuildChat
    addon.ShowBackupRestore = ShowBackupRestore
    addon.OptionsPanel = optionsPanel
end