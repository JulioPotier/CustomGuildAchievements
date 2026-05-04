-- Achievements/AdventureCoAchievements.lua
-- Guild-only catalog (Adventure Co): not registered for other guilds (reduces noise on CurseForge installs).
-- Anyone can still edit this file to enable the same achievements; this is not a security boundary.

local addonName, addon = ...
local table_insert = table.insert

-- Exact match on GetGuildInfo("player") display name. Add aliases if the guild was renamed.
local ADVENTURE_CO_GUILD_ALLOWLIST = {
	["Adventure Co"] = true,
}

local function IsAdventureCoGuildMember()
	local g = GetGuildInfo("player")
	return type(g) == "string" and g ~= "" and ADVENTURE_CO_GUILD_ALLOWLIST[g] == true
end

-- Forward declaration: assigned below; used to stop roster polling after a successful register.
local rosterFrame

local guildName = "|cffffd100" .. (GetGuildInfo("player") or "No Guild") .. "|r"
local classColor = (addon and addon.GetClassColor and addon.GetClassColor()) or "|cffffd100"
local rawPlayerName = UnitName("player")
local playerName = classColor .. rawPlayerName .. "|r"
local playerClass = classColor .. UnitClass("player") .. "|r"

local CustomAchievements = {
	-- Example 1: target an NPC and /wave (locale-proof via DoEmote hook)
	{
		achId = "CUSTOM-EMOTE-HELLO-GUARD-01",
		title = "Polite citizen (emote test)",
		tooltip = "Go to Melris Malagan and perform a /bow (while standing close enough).",
		icon = 132485,
		points = 5,
		level = nil,
		targetNpcId = 12480, -- Melris Malagan
		onEmote = "bow",
		checkInteractDistance = true,
		withIcon = "gossip",
	},

	-- Example 2: simple kill achievement
	{
		achId = "CUSTOM-KILL-RAT-CHAIN-TEST-00001",
		title = "Rat killer (chain test)",
		tooltip = "Kill a Rat in Stormwind City.",
		icon = 132367,
		points = 5,
		level = nil,
		targetNpcId = 4075, -- Rat
		zoneAccurate = 1453,
		zone = "Stormwind City",
	},
	{
		achId = "CUSTOM-KILL-RAT-CHAIN-TEST-00002",
		title = "Rat killer II",
		tooltip = "Kill another Rat in Stormwind City.",
		icon = 132367,
		points = 5,
		level = nil,
		targetNpcId = 4075, -- Rat
		zoneAccurate = 1453,
		zone = "Stormwind City",
		unlockedBy = "CUSTOM-KILL-RAT-CHAIN-TEST-00001",
	},
	{
		achId = "CUSTOM-KILL-RAT-CHAIN-TEST-00003",
		title = "Rat killer III",
		tooltip = "Kill yet another Rat in Stormwind City.",
		icon = 132367,
		points = 5,
		level = nil,
		targetNpcId = 4075, -- Rat
		zoneAccurate = 1453,
		zone = "Stormwind City",
		unlockedBy = "CUSTOM-KILL-RAT-CHAIN-TEST-00002",
	},
	{
		achId = "CUSTOM-ITEM-7723-INBAG-001",
		title = "Keep a Shiny Red Apple in bag (item test)",
		tooltip = "Have a Shiny Red Apple in your inventory.",
		icon = 136116,
		points = 5,
		level = nil,
		customItem = function()
			return GetItemCount(4536, false) > 0 -- false = no bank, true = bank
		end,
	},
	{
		achId = "CUSTOM-ITEM-4536-USE-001",
		title = "Eat a Shiny Red Apple (use item test)",
		tooltip = "Use a Shiny Red Apple. Right-click it from your bags.",
		icon = 136116,
		points = 5,
		level = nil,
		unlockedBy = "CUSTOM-ITEM-7723-INBAG-001",
		useItem = 4536,
	},
	{
		achId = "CUSTOM-ITEM-7723-EQUIPPED-001",
		title = "Wear your Guild Tabard (slot test)",
		tooltip = "Have your Guild Tabard equipped to show your guild pride.",
		icon = 136116,
		points = 5,
		level = nil,
		customItem = function()
			-- Classic equipment slots: 1..19 (head..ranged slot order; includes offhand).
			for slot = 1, 19 do
				local id = GetInventoryItemID("player", slot)
				if id == 5976 then
					return true
				end
			end
			return false
		end,
	},
	{
		achId = "CUSTOM-ATTEMPT-FALL-DAMAGE-5PV-01",
		title = "Leap of Faith (3 tries)",
		tooltip = "Open gossip with a Stormwind Guard to start a run. You have 3 attempts total to lose at least 5% HP from a single fall. Best fall % is kept across attempts.",
		icon = 132886,
		points = 10,
		level = nil,
		attemptEnabled = true,
		attemptsAllowed = 3,
		requiredFallHpLossPct = 5,
		startNpc = {
			npcId = 68, -- Stormwind Guard
			coords = { mapId = 1453, x = 0.64055508375168, y = 0.75485122203827 }, -- Stormwind City (coords => map pin)
			window = {
				title = "Leap of Faith",
				text = "Take a dangerous fall and lose at least 5% of your health in one impact.\n\nYou only have 3 starts total, but your best fall percentage is preserved across attempts.",
				buttonLabel = "Start attempt",
				buttonSound = "accept",
				callback = function(def, npcId)
					if addon and addon.AttemptActivate then
						addon.AttemptActivate(def.achId, "npc:" .. tostring(npcId), nil)
					end
					return false
				end,
			},
		},
		customIsCompleted = function()
			if not addon or not addon.GetProgress then
				return false
			end
			local p = addon.GetProgress("CUSTOM-ATTEMPT-FALL-DAMAGE-5PV-01") or {}
			local done = tonumber(p.fallSuccessCount) or 0
			return done >= 3
		end,
	},

	-- Example 2b: target a specific player by name (string targetNpcId)
	{
		achId = "CUSTOM-TARGET-PLAYER-MACARONADE-01",
		title = "Found you (target player test)",
		tooltip = "Target the player Macaronade.",
		icon = 134216, -- Elf icon
		points = 5,
		level = nil,
		targetNpcId = "Macaronade",
	},

	-- Example 3: spend a few copper at Frederick Stover (merchant)
	{
		achId = "CUSTOM-BUY-BREAD-THOMAS-MILLER-3518-01",
		title = "Breadwinner (spend at vendor test)",
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
		achId = "CUSTOM-SPEND-GOLD-TOPPER-1402-01",
		title = "Alms for the poor (spend at npc test 2)",
		tooltip = "Could ye spare some coin?",
		icon = 133784,
		points = 5,
		level = nil,
		startNpc = {
			npcId = 1402,
			window = {
				title = "Topper McNabb",
				text = "Could ye spare some coin? 2 {gold} should do it.\n\nI will gladly pay you Tuesday for a hamburger today.",
				buttonLabel = "Give him the money",
				callback = function()
					local money = GetMoney and GetMoney() or 0
					local hasGold = money >= 20000 -- 2 gold in copper
					if hasGold then
						if addon and addon._cgaPlayWindowSound then addon._cgaPlayWindowSound("coins") end
						local c = ChatTypeInfo and ChatTypeInfo.SAY
						local msg = "Topper McNabb says: Thank you for your generosity " .. playerName .. ". Long life to " .. guildName .. "!"
						if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage and c then
							DEFAULT_CHAT_FRAME:AddMessage(msg, c.r, c.g, c.b)
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
	-- Example 5: complete all those achievements
	{
		achId = "CUSTOM-COMBO-0001",
		title = "Complete those 5 achievements (combo test)",
		tooltip = "You have completed 5 achievements.",
		icon = 236685,
		points = 0,
		level = 50,
		achiIds = {
			"CUSTOM-EMOTE-HELLO-GUARD-01",
			"CUSTOM-KILL-RAT-4075",
			"CUSTOM-TARGET-PLAYER-MACARONADE-01",
			"CUSTOM-BUY-BREAD-THOMAS-MILLER-3518-01",
			"CUSTOM-SPEND-GOLD-TOPPER-1402-01",
		},
	},
	-- Example 6: complete any 5 achievements
	{
		achId = "CUSTOM-COMBO-0002",
		title = "Achievement Hunter I (combo test 2)",
		tooltip = "Complete any 5 achievements.",
		icon = 134321,
		points = 0,
		level = 50,
		nbAchis = 5,
	},
}

local function RegisterAdventureCoCatalog()
	if not addon then
		return
	end
	if addon._adventureCoCatalogApplied then
		return
	end
	if not IsAdventureCoGuildMember() then
		addon.CustomAchievements = {}
		return
	end

	local initAlreadyFinalized = addon._CGA_InitFinalized == true
	addon._adventureCoCatalogApplied = true

	if type(addon.SetupRequiredTargetAutoTrack) == "function" then
		addon.SetupRequiredTargetAutoTrack(CustomAchievements, { throttleSeconds = 1.0 })
	end

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
		local d = def

		if addon.GuildAchievements then
			table_insert(addon.GuildAchievements, d)
		end

		if (not d.onEmote) and (not d.customKill) and (d.targetNpcId or d.requiredKills or d.requiredQuestId) and addon.registerQuestAchievement then
			addon.registerQuestAchievement({
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
			})
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
	end

	addon.CustomAchievements = CustomAchievements

	if initAlreadyFinalized and addon.RefreshPanelsAfterDeferredAchievementCatalog then
		pcall(addon.RefreshPanelsAfterDeferredAchievementCatalog)
	end

	if rosterFrame then
		rosterFrame:UnregisterAllEvents()
	end
end

if addon then
	addon.RegistrationQueue = addon.RegistrationQueue or {}
	table_insert(addon.RegistrationQueue, function()
		RegisterAdventureCoCatalog()
	end)

	-- If guild name was not ready during the main registration pass, retry when roster updates.
	rosterFrame = CreateFrame("Frame")
	rosterFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
	rosterFrame:SetScript("OnEvent", function()
		RegisterAdventureCoCatalog()
	end)
end
