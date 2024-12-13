-- XAT lets us communicate between files (Addon Namespace)
local _, XAT = ...
XAT.__index = XAT

XAT.frame = CreateFrame("Frame") -- used multiple times
local filters = {}
local reload                     -- track whether a change has been made that requires a reload to take effect

function XAT:getVanity()
	DEFAULT_CHAT_FRAME:AddMessage(XAT:setColor("XAT") .. ": " .. #XAT.grablist .. " item(s) left to grab.")
	local next = table.remove(XAT.grablist)
	if C_VanityCollection.IsCollectionItemOwned(next) then
		RequestDeliverVanityCollectionItem(next)
	end
	if #XAT.grablist > 0 then
		XAT:wait(1, XAT.getVanity, self)
	end
end

local function findpartial(items, word)
	for _, s in ipairs(items) do
		if word:find(s) then
			return true
		end
	end
	return false
end

local function hasitem(itemID)
	local item, found, id
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			item = GetContainerItemLink(bag, slot)
			if item then
				found, _, id = item:find('^|c%x+|Hitem:(%d+):.+')
				if found and tonumber(id) == itemID then
					return true
				end
			end
		end
	end
	return false
end

local function isManastorm(v)
	local manastorm_items = {
		["Chakra Chug"] = true,
		["Genius Juice"] = true,
		["Harm Repellant Remedy"] = true,
		["Incantation Intensifier"] = true,
		["Interrupt Rod"] = true,
		["Long Haul Liquid"] = true,
		["Manastorm Cleanse"] = true,
		["Manastorm Curing"] = true,
		["Manastorm Purification"] = true,
		["Motion Lotion"] = true,
		["Muscle Maxer"] = true,
		["Rage Rush Solution"] = true,
		["Reflex Booster"] = true,
		["Sprint Serum"] = true,
		["Taunting Tonic"] = true,
		["Tiny Ticking Time-Bomb"] = true,
		["Hearty Heal Upgrade"] = true,
		["Cleanse"] = true,
		["Purification"] = true,
	}
	local name, rank = v.name:match("(.-) %(Rank (.-)%)")

	if name and manastorm_items[name] then
		return name, tonumber(rank), IsSpellKnown(v.learnedSpell)
	end
end

function XAT:grabVanity()
	XAT.grablist = {}
	local known_spells = {}
	for i = 1, GetNumCompanions("CRITTER") do
		local _, _, sID = GetCompanionInfo("CRITTER", i)
		known_spells[sID] = true
	end
	for i = 1, GetNumCompanions("MOUNT") do
		local _, _, sID = GetCompanionInfo("MOUNT", i)
		known_spells[sID] = true
	end

	local badItems = {
		["Alliance"] = {
			--			[1780054] = true, -- Stone of Retreat: Razor Hill
		},
		["Horde"] = {
			--			[1780051] = true, -- Stone of Retreat: Goldshire
		}
	}

	local mCache = {}
	local mmm = {}
	local max_mmm = 0
	local known_mmm = 0
	for k, v in pairs(VANITY_ITEMS) do
		if C_VanityCollection.IsCollectionItemOwned(k) and v.learnedSpell > 1 then
			local _, _, _, _, _, _, s = GetItemInfo(v.itemid)
			--			if (((fullchecks[v.name] or findpartial(partialchecks, v.name)) and not IsSpellKnown(v.learnedSpell)) or
			local name, rank, known = isManastorm(v)
			if name then
				if not mCache[name] or mCache[name].rank < rank then
					mCache[name] = { ["rank"] = rank, ["known"] = known, ["id"] = k, ["itemid"] = v.itemid }
				end
			elseif v.name:find("Millhouse Mobility Mixture %(Upgrade") then
				local rank = tonumber(v.name:match("Millhouse Mobility Mixture %(Upgrade Rank (%d+)"))
				if rank > max_mmm then max_mmm = rank end
				if IsSpellKnown(v.learnedSpell) and rank > known_mmm then known_mmm = rank end
				mmm[rank] = { ["id"] = k, ["itemid"] = v.itemid }
			elseif not (IsSpellKnown(v.learnedSpell) or known_spells[v.learnedSpell]) and not hasitem(v.itemid) then
				if badItems[UnitFactionGroup("player")][v.itemid] then
					DEFAULT_CHAT_FRAME:AddMessage(XAT:setColor("XAT") ..
						": Skipping" .. v.name .. " as it is bugged and gives an unusable item instead of the spell.")
				else
					table.insert(XAT.grablist, k)
				end
			end
		end
	end
	for k, v in pairs(mCache) do
		if not v.known and not hasitem(v.itemid) then
			table.insert(XAT.grablist, v.id)
		end
	end
	for i = known_mmm + 1, max_mmm do
		if not hasitem(mmm[i].itemid) then
			table.insert(XAT.grablist, mmm[i].id)
		end
	end
	if #XAT.grablist > 0 then
		DEFAULT_CHAT_FRAME:AddMessage(XAT:setColor("XAT") ..
			": Grabbing " .. #XAT.grablist .. " unlearned vanity spells.")
		XAT:wait(1, XAT.getVanity, self)
	end
end

-- add color markup to a string
function XAT:setColor(val)
	return "|cFFFFBF00" .. val .. "|r"
end

local function status(val)
	if val then
		return "|cFF00FF00On|r"
	end
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
			local opttext = { "filtersay", "filteryell", "hideAscButton", "filtertrial", "filterMEA", "filterAuto", "filterNew", "filterAscension", "filterWorld", "filterCOA", "filterBAU", "filterBAUAsc", "filterKeeper", "filterMotherlode", "filterDP", "filterTwitch", "autoGrabVanity", "filterALeader", "filterHLeader" }
			for _, v in ipairs(opttext) do
				XanAscTweaks[v] = true
			end
			reload = true
		elseif args == "off" then
			XanAscTweaks = {}
			reload = true
		else
			XAT:printmsg("Invalid option.  'on' or 'off'")
		end
	elseif cmd == "afkmsg" then
		if args == "" then
			XanAscTweaks.afkmsg = nil
			XanAscTweaks.afm_msg = nil
			XAT:printmsg("`afkmsg` is deactivated.")
		else
			XanAscTweaks.afm_msg = args
			XanAscTweaks.afkmsg = true
			XAT:printmsg("`afkmsg` is now active.")
		end
	elseif cmd == "say" then
		XanAscTweaks.filtersay = toggle(XanAscTweaks.filtersay, "say")
		reload = true
	elseif cmd == "yell" then
		XanAscTweaks.filteryell = toggle(XanAscTweaks.filteryell, "yell")
		reload = true
	elseif cmd == "button" then
		XanAscTweaks.hideAscButton = toggle(XanAscTweaks.hideAscButton, "button")
		reload = true
	elseif cmd == "trial" then
		XanAscTweaks.filtertrial = toggle(XanAscTweaks.filtertrial, "trial")
		reload = true
	elseif cmd == "altar" then
		XanAscTweaks.filterMEA = toggle(XanAscTweaks.filterMEA, "altar")
		reload = true
	elseif cmd == "autobroadcast" then
		XanAscTweaks.filterAuto = toggle(XanAscTweaks.filterAuto, "autobroadcast")
		reload = true
	elseif cmd == "new" then
		XanAscTweaks.filterNew = toggle(XanAscTweaks.filterNew, "Newcomers chat")
		reload = true
	elseif cmd == "ascension" then
		XanAscTweaks.filterAscension = toggle(XanAscTweaks.filterAscension, "Ascension chat")
		reload = true
	elseif cmd == "world" then
		XanAscTweaks.filterWorld = toggle(XanAscTweaks.filterWorld, "World chat")
		reload = true
	elseif cmd == "coa" then
		XanAscTweaks.filterCOA = toggle(XanAscTweaks.filterCOA, "Conquest of Azeroth Travel Guide")
		reload = true
	elseif cmd == "bau" then
		XanAscTweaks.filterBAU = toggle(XanAscTweaks.filterBAU, "Northrend Travel Guide")
		reload = true
	elseif cmd == "bauchat" then
		XanAscTweaks.filterBAUAsc = toggle(XanAscTweaks.filterBAUAsc, "bau in chat")
		reload = true
	elseif cmd == "keeper" then
		XanAscTweaks.filterKeeper = toggle(XanAscTweaks.filterKeeper, "Keeper's Scroll")
		reload = true
	elseif cmd == "motherlode" then
		XanAscTweaks.filterMotherlode = toggle(XanAscTweaks.filterMotherlode, "The Motherlode")
		reload = true
	elseif cmd == "dp" then
		XanAscTweaks.filterDP = toggle(XanAscTweaks.filterDP, "dp in chat")
		reload = true
	elseif cmd == "twitch" then
		XanAscTweaks.filterTwitch = toggle(XanAscTweaks.filterTwitch, "Twitch in chat")
		reload = true
	elseif cmd == "vanity" then
		XanAscTweaks.autoGrabVanity = toggle(XanAscTweaks.autoGrabVanity, "Auto-grab Vanity")
		if XanAscTweaks.autoGrabVanity then
			XAT:grabVanity()
		end
	elseif cmd == "aleader" then
		XanAscTweaks.filterALeader = toggle(XanAscTweaks.filterALeader, "Alliance Leader Spawn Alerts")
		reload = true
	elseif cmd == "hleader" then
		XanAscTweaks.filterHLeader = toggle(XanAscTweaks.filterHLeader, "Horde Leader Spawn Alerts")
		reload = true
	else
		XAT:printmsg("Use '/xat all on|off' to quickly toggle all options.  Or use '/xat option` where option can be one of;")
		local options = {
			status(XanAscTweaks.filtersay) .. " `say` removed in rest areas",
			status(XanAscTweaks.filteryell) .. " `yell` removed in rest areas",
			status(XanAscTweaks.hideAscButton) .. " `button` is hiding Ascension Button",
			status(XanAscTweaks.filtertrial) .. " `trial` Broadcasts are being filtered",
			status(XanAscTweaks.filterMEA) .. " `altar` is hiding Mystic Enchanting Altar Broadcasts",
			status(XanAscTweaks.filterAuto) .. " `autobroadcast` messages are being hidden",
			status(XanAscTweaks.filterNew) .. " `new` is removing Newcomers from first chat tab",
			status(XanAscTweaks.filterAscension) .. " `ascension` is removing Ascension from first chat tab",
			status(XanAscTweaks.filterWorld) .. " `world`  is removing World from first chat tab",
			status(XanAscTweaks.filterCOA) .. " `coa` is filtering Conquest of Azeroth Travel Guide",
			status(XanAscTweaks.filterBAU) .. " `bau` is filtering Northrend Travel Guide",
			status(XanAscTweaks.filterBAUAsc) .. " `bauchat` is hiding BAU from Ascension and Newcomers",
			status(XanAscTweaks.filterKeeper) .. " `keeper` is filtering Keeper's Scrolls",
			status(XanAscTweaks.filterMotherlode) .. " `motherlode` is filtering Motherlodes",
			status(XanAscTweaks.filterDP) .. " `dp` is hiding messages that contain dp and don't contain dps",
			status(XanAscTweaks.filterTwitch) .. " `twitch` is hiding twitch links in Ascension and Newcomers",
			status(XanAscTweaks.autoGrabVanity) .. " `vanity` is automatically grabbing unlearned vanity spells.",
			status(XanAscTweaks.filterALeader) .. " `aleader` is hiding Alliance Leader spawn alerts.",
			status(XanAscTweaks.filterHLeader) .. " `hleader` is hiding Horde Leader spawn alerts.",
			status(XanAscTweaks.afkmsg) .. " `afkmsg` is replacing your default afk message with a custom one.",
		}
		for _, option in pairs(options) do
			XAT:printmsg(option, true)
		end
	end
	if reload then
		XAT:printmsg("changes pending /reload")
	end
end

-- Ascension likes to enable some channels in default chat frame on login.  Disable them.
function XAT:hideNew()
	if XanAscTweaks.filterNew then
		ChatFrame_RemoveChannel(DEFAULT_CHAT_FRAME, "Newcomers")
	end
	if XanAscTweaks.filterAscension then
		ChatFrame_RemoveChannel(DEFAULT_CHAT_FRAME, "Ascension")
	end
	if XanAscTweaks.filterWorld then
		ChatFrame_RemoveChannel(DEFAULT_CHAT_FRAME, "World")
	end
end

-- hide say/yell when in a city
local function filterAll(self, event, ...)
	if IsResting() then
		if XanAscTweaks.filtersay and event == "CHAT_MSG_SAY" then
			return true
		end
		if XanAscTweaks.filteryell and event == "CHAT_MSG_YELL" then
			return true
		end
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
	return XanAscTweaks.filterMEA and msg:find("Use this to empower your character with powerful enchants")
end

-- remove BAU and DP from newcomers and ascension
local function filterChannel(self, event, msg, ...)
	local channel = select(8, ...)
	channel = channel:lower()
	if event ~= "CHAT_MSG_CHANNEL" or not msg or (channel ~= "ascension" and channel ~= "newcomers") then return false end

	local msglower = msg:lower()

	if XanAscTweaks.filterBAUAsc and msglower:find("bau") then
		return true
	end
	if XanAscTweaks.filterDP and not msglower:find("dps") and msglower:find("dp") then
		return true
	end
	if XanAscTweaks.filterTwitch and msglower:find("twitch") then
		return true
	end
	return false
end

-- At character login set up a command handler and our variables
function XAT:XanEventHandler(event, ...)
	self[event](self, event, ...)
end

-- check that saved variable are initialized
function XAT.frame:ADDON_LOADED(event, ...)
	self:UnregisterEvent("ADDON_LOADED")

	if XanAscTweaks == nil then
		XanAscTweaks = {}
	end
end

function XAT.frame:PLAYER_ENTERING_WORLD(event, ...)
	-- set up Ascension filters
	filters["Htrial:%d-:"] = XanAscTweaks.filtertrial or nil -- Trials
	filters["%[.-Resolute.-Mode.-%]"] = XanAscTweaks.filtertrial or nil
	filters["%[.-Nightmare.-%]"] = XanAscTweaks.filtertrial or nil
	filters["Hitem:1179126"] = XanAscTweaks.filterMEA or nil                  -- Mystic Enchanting Altar
	filters["%[.-Ascension.-Autobroadcast.-%]"] = XanAscTweaks.filterAuto or nil -- Auto Broadcasts
	filters["%[.-Conquest of Azeroth Travel Guide.-%]"] = XanAscTweaks.filterCOA or nil
	filters["%[.-Northrend Travel Guide.-%]"] = XanAscTweaks.filterBAU or nil
	filters["%[.-Keeper's.-Scroll.-%]"] = XanAscTweaks.filterKeeper or nil
	filters["%[.-The.-Motherlode.-%]"] = XanAscTweaks.filterMotherlode or nil
	filters["|TInterface\\Icons\\inv_alliancewareffort:16|t.-has spawned"] = XanAscTweaks.filterALeader or nil
	filters["|TInterface\\Icons\\inv_hordewareffort:16|t.-has spawned"] = XanAscTweaks.filterHLeader or nil

	if XanAscTweaks.autoGrabVanity then
		XAT:wait(5, XAT.grabVanity, self)
	end

	if XanAscTweaks.hideAscButton then
		LibDBIcon10_AscensionUICA2:Hide()
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", filterSystem)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", filterAll)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", filterAll)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", filterEmote)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", filterChannel)

	XAT:wait(1, XAT.hideNew, self)

	SLASH_XAT1 = "/xat"
	SlashCmdList["XAT"] = function(msg) XAT:CommandHandler(msg) end
end

function XAT.frame:PLAYER_FLAGS_CHANGED(...)
	XAT.frame:UnregisterEvent("PLAYER_FLAGS_CHANGED")
	if UnitIsAFK("player") then
		SendChatMessage("", "AFK")           -- disables AFK
		SendChatMessage(XanAscTweaks.afm_msg, "AFK") -- re-enables with custom msg
	end
end

local p_mam = string.gsub(MARKED_AFK_MESSAGE, "%%s", "%(%.%+%)")
function XAT.frame:CHAT_MSG_SYSTEM(event, msg, ...)
	if XanAscTweaks.afkmsg then
		local afk_msg = msg:match(p_mam)
		if afk_msg and afk_msg == "Away" then
			XAT.frame:RegisterEvent("PLAYER_FLAGS_CHANGED")
		end
	end
end

-- Main
XAT.frame:RegisterEvent("ADDON_LOADED")
XAT.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
XAT.frame:RegisterEvent("CHAT_MSG_SYSTEM")
XAT.frame:SetScript("OnEvent", XAT.XanEventHandler)
