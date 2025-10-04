local addon = LibStub("AceAddon-3.0"):NewAddon("XanAscTweaks", "AceTimer-3.0", "AceEvent-3.0")
_G.XAT = addon
local L = LibStub("AceLocale-3.0"):GetLocale("XanAscTweaks")

local currentVersion = 1 -- [int] current version of options, to notify when things are added

local filters = {}
local reload -- track whether a change has been made that requires a reload to take effect

local defaults = {
    ["profile"] = {
        filtersay = false,
        filteryell = false,
        hideAscButton = false,
        filtertrial = false,
        filterMEA = false,
        filterAuto = false,
        filterNew = false,
        filterAscension = false,
        filterWorld = false,
        filterTravelGuide = false,
        filterBAUAsc = false,
        filterKeeper = false,
        filterMotherlode = false,
        filterDP = false,
        filterTwitch = false,
        filterDiscord = false,
        autoGrabVanity = false,
        filterALeader = false,
        filterHLeader = false,
        afkmsg = false,
        afk_msg = "",
		filterCriminal = false,
        filterHardcore = false,
		filterKeeperScroll = false,
        filterPosture = false,
    },
}

-- so that enable/disable all works with any option except afk
local opttext = {}
for k, v in pairs(defaults.profile) do
	if k ~= "afkmsg" and k ~= "afk_msg" then
		tinsert(opttext, k)
	end
end


-- update chat system filters
local function updateFilter()
	filters["Htrial:%d-:"] = addon.db.profile.filtertrial or nil -- Trials
	filters["%[.-Resolute.-Mode.-%]"] = addon.db.profile.filtertrial or nil
	filters["%[.-Nightmare.-%]"] = addon.db.profile.filtertrial or nil
	filters["Hitem:1179126"] = addon.db.profile.filterMEA or nil -- Mystic Enchanting Altar
	filters["%[.-Ascension.-Autobroadcast.-%]"] = addon.db.profile.filterAuto or nil -- Auto Broadcasts
	filters["%[.-Travel Guide.-%]"] = addon.db.profile.filterTravelGuide or nil
	filters["%[.-Keeper's.-Scroll.-%]"] = addon.db.profile.filterKeeper or nil
	filters["%[.-The.-Motherlode.-%]"] = addon.db.profile.filterMotherlode or nil
	filters["|TInterface\\Icons\\inv_alliancewareffort:16|t.-has spawned"] = addon.db.profile.filterALeader or nil
	filters["|TInterface\\Icons\\inv_hordewareffort:16|t.-has spawned"] = addon.db.profile.filterHLeader or nil
    filters["%[.-Criminal Intent.-%]"] = addon.db.profile.filterCriminal or nil
    filters["%[.-Hardcore.-%]"] = addon.db.profile.filterHardcore or nil
    filters["%[.-Keeper's Scroll.-%]"] = addon.db.profile.filterKeeperScroll or nil
    filters["%[.-Posture Check.-%]"] = addon.db.profile.filterPosture or nil
end

local function config_toggle_get(info) return addon.db.profile[info[#info]] end
local function config_toggle_set(info, v) addon.db.profile[info[#info]] = v end

local options = {
	["type"] = "group",
	["handler"] = XAT,
	["get"] = "OptionsGet",
	["set"] = "OptionsSet",
	["args"] = {
		main = {
			type = "group",
			name = L["Options"],
			order = 12,
			cmdHidden = true,
			args = {
				chatMessageFilters = {
					type = "multiselect",
					name = L["Chat Message Filters"],
					order = 2,
					style = "dropdown",
					values = function()
						local r = {}

						r["filtersay"] = L["/Say in Rest"]
						r["filteryell"] = L["/Yell in Rest"]
						r["filtertrial"] = L["Trial Messages"]
						r["filterMEA"] = L["Mystic Enchant Altars"]
						r["filterAuto"] = L["Asc Autobroadcasts"]
						r["filterTravelGuide"] = L["Travel Guides"]
						r["filterBAUAsc"] = L["'bau' in chat"]
						r["filterKeeper"] = L["Keeper Scrolls"]
						r["filterMotherlode"] = L["Motherlodes"]
						r["filterDP"] = L["'dp' in chat"]
						r["filterTwitch"] = L["'twitch' in chat"]
						r["filterDiscord"] = L["'discord.gg' in chat"]
						r["filterALeader"] = L["Alliance Leader Messages"]
						r["filterHLeader"] = L["Horde Leader Messages"]
						r["filterCriminal"] = L["Criminal Intent Messages"]
						r["filterHardcore"] = L["Hardcore Mode Messages"]
						r["filterKeeperScroll"] = L["Keeper's Scroll Messages"]
						r["filterPosture"] = L["Posture Check Messages"]

						return r
					end,
					get = function(info, key) return addon.db.profile[key] end,
					set = function(info, key, value)
						addon.db.profile[key] = value
						updateFilter()
					end,
				},
				miscOptions = {
					type = "multiselect",
					name = L["Miscellaneous Options"],
					width = "full",
					order = 3,
					style = "dropdown",
					values = function()
						local r = {}

						r["hideAscButton"] = L["Hide Character Advancement Button"]
						r["filterNew"] = L["Remove Newcomer Chat on tab 1"]
						r["filterAscension"] = L["Remove Ascension Chat on tab 1"]
						r["filterWorld"] = L["Remove World Chat on tab 1"]
						r["autoGrabVanity"] = L["Automatically grab unknown Vanity Spells"]

						return r
					end,
					get = function(info, key) return addon.db.profile[key] end,
					set = function(info, key, value)
						addon.db.profile[key] = value
						XAT:printmsg("changes pending /reload")
					end,
				},
				autoSwitch = {
					name = L["Custom AFK"],
					type = "group",
					guiInline = true,
					order = 4,
					args = {
						afkmsg = {
							type = "toggle",
							name = L["Custom AFK Message"],
							desc = L["Should Default AFK message be replaced"],
							order = 12,
							get = config_toggle_get,
							set = config_toggle_set,
						},
						afk_msg = {
							type = "input",
							name = L["AFK Message"],
							desc = L["Enter a message to automatically set"],
							width = "double",
							get = function(info) return addon.db.profile.afk_msg end,
							set = function(info, value)
								-- Don't allow empty entries or the default "Away"
								if value == "" or gsub(value, "%s+", "") == "" or value == "Away" or gsub(value, "%s+", "") == "Away" then
									addon.db.profile.afkmsg = nil
									return
								end
								addon.db.profile.afk_msg = value
							end,
						},
					},
				},
			},
		},
		profiles = nil, -- reserved for profile options
	},
}

-- add color markup to a string
function XAT:setColor(val) return "|cFFFFBF00" .. val .. "|r" end

local function status(val)
	if val then return "|cFF00FF00On|r" end
	return "|cFFFF0000Off|r"
end

function XAT:printmsg(message, ...)
	local hideheader = ...
	if hideheader then
		DEFAULT_CHAT_FRAME:AddMessage(message)
	else
		DEFAULT_CHAT_FRAME:AddMessage(XAT:setColor("XAT") .. ": " .. message)
	end
end

-- toggle the state of a flag
local function toggle(var, text)
	if var then
		XAT:printmsg("`" .. text .. "` is deactivated.")
		return
	else
		XAT:printmsg("`" .. text .. "` is now active.")
		return true
	end
end

-- handle slash commands
function XAT:CommandHandler(msg)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
	if cmd == "all" then
		if args == "on" then
			for _, v in ipairs(opttext) do
				self.db.profile[v] = true
			end
			reload = true
		elseif args == "off" then
			for _, v in ipairs(opttext) do
				self.db.profile[v] = false
			end
			reload = true
		else
			XAT:printmsg("Invalid option.  'on' or 'off'")
		end
		updateFilter()
	elseif cmd == "afkmsg" then
		if args == "" or args == "Away" then
			self.db.profile.afkmsg = nil
			self.db.profile.afk_msg = nil
			XAT:printmsg("`afkmsg` is deactivated.  Be sure to include a string to activate or update.")
		else
			self.db.profile.afk_msg = args
			self.db.profile.afkmsg = true
			XAT:printmsg("`afkmsg` is now active.")
		end
	elseif cmd == "say" then
		self.db.profile.filtersay = toggle(self.db.profile.filtersay, "say")
	elseif cmd == "yell" then
		self.db.profile.filteryell = toggle(self.db.profile.filteryell, "yell")
	elseif cmd == "button" then
		self.db.profile.hideAscButton = toggle(self.db.profile.hideAscButton, "button")
		reload = true
	elseif cmd == "trial" then
		self.db.profile.filtertrial = toggle(self.db.profile.filtertrial, "trial")
		updateFilter()
	elseif cmd == "altar" then
		self.db.profile.filterMEA = toggle(self.db.profile.filterMEA, "altar")
		updateFilter()
	elseif cmd == "autobroadcast" then
		self.db.profile.filterAuto = toggle(self.db.profile.filterAuto, "autobroadcast")
		updateFilter()
	elseif cmd == "new" then
		self.db.profile.filterNew = toggle(self.db.profile.filterNew, "Newcomers chat")
		reload = true
	elseif cmd == "ascension" then
		self.db.profile.filterAscension = toggle(self.db.profile.filterAscension, "Ascension chat")
		reload = true
	elseif cmd == "world" then
		self.db.profile.filterWorld = toggle(self.db.profile.filterWorld, "World chat")
		reload = true
	elseif cmd == "travel" then
		self.db.profile.filterTravelGuide = toggle(self.db.profile.filterTravelGuide, "Travel Guide")
		updateFilter()
	elseif cmd == "bauchat" then
		self.db.profile.filterBAUAsc = toggle(self.db.profile.filterBAUAsc, "bau in chat")
	elseif cmd == "keeper" then
		self.db.profile.filterKeeper = toggle(self.db.profile.filterKeeper, "Keeper's Scroll")
		updateFilter()
	elseif cmd == "motherlode" then
		self.db.profile.filterMotherlode = toggle(self.db.profile.filterMotherlode, "The Motherlode")
		updateFilter()
	elseif cmd == "dp" then
		self.db.profile.filterDP = toggle(self.db.profile.filterDP, "dp in chat")
	elseif cmd == "twitch" then
		self.db.profile.filterTwitch = toggle(self.db.profile.filterTwitch, "Twitch in chat")
	elseif cmd == "discord" then
		self.db.profile.DiscordTwitch = toggle(self.db.profile.filterDiscord, "Discord in chat")
	elseif cmd == "vanity" then
		self.db.profile.autoGrabVanity = toggle(self.db.profile.autoGrabVanity, "Auto-grab Vanity")
		if self.db.profile.autoGrabVanity then XAT:grabVanity() end
	elseif cmd == "aleader" then
		self.db.profile.filterALeader = toggle(self.db.profile.filterALeader, "Alliance Leader Spawn Alerts")
		updateFilter()
	elseif cmd == "hleader" then
		self.db.profile.filterHLeader = toggle(self.db.profile.filterHLeader, "Horde Leader Spawn Alerts")
		updateFilter()
	elseif cmd == "criminal" then
		self.db.profile.filterCriminal = toggle(self.db.profile.filterCriminal, "Criminal Intent Messages")
		updateFilter()
	elseif cmd == "hardcore" then
		self.db.profile.filterHardcore = toggle(self.db.profile.filterHardcore, "Hardcore Mode Messages")
		updateFilter()
	elseif cmd == "keeperscroll" then
		self.db.profile.filterKeeperScroll = toggle(self.db.profile.filterKeeperScroll, "Keeper's Scroll Messages")
		updateFilter()
	elseif cmd == "posture" then
		self.db.profile.filterPosture = toggle(self.db.profile.filterPosture, "Posture Check Messages")
		updateFilter()
	else
		XAT:printmsg("Use '/xat all on|off' to quickly toggle all options.  Or use '/xat option` where option can be one of;")
		local options = {
			status(self.db.profile.filtersay) .. " `say` removed in rest areas",
			status(self.db.profile.filteryell) .. " `yell` removed in rest areas",
			status(self.db.profile.hideAscButton) .. " `button` is hiding Ascension Button",
			status(self.db.profile.filtertrial) .. " `trial` Broadcasts are being filtered",
			status(self.db.profile.filterMEA) .. " `altar` is hiding Mystic Enchanting Altar Broadcasts",
			status(self.db.profile.filterAuto) .. " `autobroadcast` messages are being hidden",
			status(self.db.profile.filterNew) .. " `new` is removing Newcomers from first chat tab",
			status(self.db.profile.filterAscension) .. " `ascension` is removing Ascension from first chat tab",
			status(self.db.profile.filterWorld) .. " `world`  is removing World from first chat tab",
			status(self.db.profile.filterTravelGuide) .. " `travel` is filtering all Travel Guides to alpha realms",
			status(self.db.profile.filterBAUAsc) .. " `bauchat` is hiding BAU from Ascension and Newcomers",
			status(self.db.profile.filterKeeper) .. " `keeper` is filtering Keeper's Scrolls",
			status(self.db.profile.filterMotherlode) .. " `motherlode` is filtering Motherlodes",
			status(self.db.profile.filterDP) .. " `dp` is hiding messages that contain dp and don't contain dps",
			status(self.db.profile.filterTwitch) .. " `twitch` is hiding twitch links in Ascension and Newcomers",
			status(self.db.profile.filterDiscord) .. " `discord` is hiding discord links in Ascension and Newcomers",
			status(self.db.profile.autoGrabVanity) .. " `vanity` is automatically grabbing unlearned vanity spells.",
			status(self.db.profile.filterALeader) .. " `aleader` is hiding Alliance Leader spawn alerts.",
			status(self.db.profile.filterHLeader) .. " `hleader` is hiding Horde Leader spawn alerts.",
			status(self.db.profile.afkmsg) .. " `afkmsg` is replacing your default afk message with a custom one.",
			status(self.db.profile.filterCriminal) .. " `criminal` is hiding Criminal Intent messages.",
			status(self.db.profile.filterHardcore) .. " `hardcore` is hiding Hardcore mode messages.",
			status(self.db.profile.filterKeeperScroll) .. " `keeperscroll` is hiding Keeper's Scroll messages.",
			status(self.db.profile.filterPosture) .. " `posture` is hiding Posture Check messages.",
		}
		for _, option in pairs(options) do
			XAT:printmsg(option, true)
		end
	end
	if reload then XAT:printmsg("changes pending /reload") end
end

-- Ascension likes to enable some channels in default chat frame on login.  Disable them.
function XAT:hideNew()
	if self.db.profile.filterNew then ChatFrame_RemoveChannel(DEFAULT_CHAT_FRAME, "Newcomers") end
	if self.db.profile.filterAscension then ChatFrame_RemoveChannel(DEFAULT_CHAT_FRAME, "Ascension") end
	if self.db.profile.filterWorld then ChatFrame_RemoveChannel(DEFAULT_CHAT_FRAME, "World") end
end

-- hide say/yell when in a city
local function filterAll(self, event, ...)
	if IsResting() then
		if addon.db.profile.filtersay and event == "CHAT_MSG_SAY" then return true end
		if addon.db.profile.filteryell and event == "CHAT_MSG_YELL" then return true end
	end
	return false
end

-- filter system messages to remove various unwanted messages
local function filterSystem(self, event, msg, ...)
	if event ~= "CHAT_MSG_SYSTEM" or not msg then return false end
	for filter, _ in pairs(filters) do
		if msg:find(filter) then
			-- match found, suppress the message
			return true
		end
	end
	-- did not match a filter
	return false
end

-- filter system messages to remove various unwanted messages
local function filterEmote(self, event, msg, ...)
	if event ~= "CHAT_MSG_EMOTE" or not msg then return false end
	return addon.db.profile.filterMEA and msg:find("Use this to empower.-powerful enchants")
end

-- remove BAU and DP from newcomers and ascension
local function filterChannel(self, event, msg, ...)
	local channel = select(8, ...)
	channel = channel:lower()
	if event ~= "CHAT_MSG_CHANNEL" or not msg or (channel ~= "ascension" and channel ~= "newcomers") then return false end

	local msglower = msg:lower()

	if addon.db.profile.filterBAUAsc and msglower:find("bau") then return true end
	if addon.db.profile.filterDP and not msglower:find("dps") and msglower:find("dp") then return true end
	if addon.db.profile.filterTwitch and msglower:find("twitch") then return true end
	if addon.db.profile.filterDiscord and msglower:find("discord.gg") then return true end
	return false
end

-- check that saved variable are initialized
function XAT:ADDON_LOADED(event, ...)
	self:UnregisterEvent("ADDON_LOADED")

	if XanAscTweaks == nil then XanAscTweaks = {} end
end

function XAT:PLAYER_FLAGS_CHANGED(...)
	XAT:UnregisterEvent("PLAYER_FLAGS_CHANGED")
	if UnitIsAFK("player") then
		SendChatMessage("", "AFK") -- disables AFK
		SendChatMessage(self.db.profile.afk_msg, "AFK") -- re-enables with custom msg
	end
end

local p_mam = string.gsub(MARKED_AFK_MESSAGE, "%%s", "%(%.%+%)")
function XAT:CHAT_MSG_SYSTEM(event, msg, ...)
	if self.db.profile.afkmsg then
		local afk_msg = msg:match(p_mam)
		if afk_msg and afk_msg == "Away" then self:RegisterEvent("PLAYER_FLAGS_CHANGED") end
	end
end

local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("XanAscTweaks", defaults, L["Default"])

	--	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	--	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	--	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

	AceConfig:RegisterOptionsTable(self.name, options)
	self.optionsFrame = LibStub("LibAboutPanel").new(nil, self.name)
	self.optionsFrame.General = AceConfigDialog:AddToBlizOptions(self.name, L["General"], self.name, "main")
	self.optionsFrame.General = AceConfigDialog:AddToBlizOptions(self.name, L["Profiles"], self.name, "profiles")
	--	AceConfig:RegisterOptionsTable(self.name .. "SlashCmd", options_slashcmd, { "xantweaks", "xat" })
	-- set up Ascension filters
	updateFilter()

	if self.db.profile.autoGrabVanity then XAT:ScheduleTimer("grabVanity", 5) end

	if self.db.profile.hideAscButton and LibDBIcon10_AscensionUICA2 then LibDBIcon10_AscensionUICA2:Hide() end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", filterSystem)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", filterAll)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", filterAll)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", filterEmote)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", filterChannel)

	XAT:ScheduleTimer("hideNew", 1)

	SLASH_XAT1 = "/xat"
	SlashCmdList["XAT"] = function(msg) XAT:CommandHandler(msg) end

	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("CHAT_MSG_SYSTEM")

	if self.db.profile.version == nil then
		XAT:printmsg("This appears to be your first time using XanAscTweaks.  Please check the options to see what is available.")
		self.db.profile.version = currentVersion
	elseif self.db.profile.version < currentVersion then
		XAT:printmsg("XanAscTweaks has changed settings.  Please check the options.")
		self.db.profile.version = currentVersion
	end
end
