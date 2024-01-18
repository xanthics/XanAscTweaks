-- XAT lets us communicate between files (Addon Namespace)
local _, XAT = ...
XAT.__index = XAT

XAT.frame = CreateFrame("Frame") -- used multiple times
local filters = {}
local reload -- track whether a change has been made that requires a reload to take effect

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
		XAT:printmsg("`"..text.."` is deactivated.")
		return false
	else
		XAT:printmsg("`"..text.."` is now active.")
		return true
	end
end

-- handle slash commands
function XAT:CommandHandler(msg)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
	if cmd == "say" then
		XanAscTweaks.filtersay = toggle(XanAscTweaks.filtersay, "say")
	elseif cmd == "yell" then
		XanAscTweaks.filteryell = toggle(XanAscTweaks.filteryell, "yell")
	elseif cmd == "button" then
		XanAscTweaks.hideAscButton = toggle(XanAscTweaks.hideAscButton, "button")
		reload = true
	elseif cmd == "trial" then
		XanAscTweaks.filtertrial = toggle(XanAscTweaks.filtertrial, "trial")
	elseif cmd == "altar" then
		XanAscTweaks.filterMEA = toggle(XanAscTweaks.filterMEA, "altar")
	elseif cmd == "autobroadcast" then
		XanAscTweaks.filterAuto = toggle(XanAscTweaks.filterAuto, "autobroadcast")
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
	elseif cmd == "bau" then
		XanAscTweaks.filterBAU = toggle(XanAscTweaks.filterBAU, "Northrend Travel Guide")
	elseif cmd == "bauchat" then
		XanAscTweaks.filterBAUAsc = toggle(XanAscTweaks.filterBAUAsc, "bau in chat")
	elseif cmd == "dp" then
		XanAscTweaks.filterDP = toggle(XanAscTweaks.filterDP, "dp in chat")
	elseif cmd == "twitch" then
		XanAscTweaks.filterTwitch = toggle(XanAscTweaks.filterTwitch, "Twitch in chat")
 	else
		XAT:printmsg("Use '/xat option` where option can be one of;")
		local options = {
			status(XanAscTweaks.filtersay).." `say` removed in rest areas",
			status(XanAscTweaks.filteryell).." `yell` removed in rest areas",
			status(XanAscTweaks.hideAscButton).." `button` is hiding Ascension Button",
			status(XanAscTweaks.filtertrial).." `trial` Broadcasts are being filtered",
			status(XanAscTweaks.filterMEA).." `altar` is hiding Mystic Enchanting Altar Broadcasts",
			status(XanAscTweaks.filterAuto).." `autobroadcast` messages are being hidden",
			status(XanAscTweaks.filterNew).." `new` is removing Newcomers from first chat tab",
			status(XanAscTweaks.filterAscension).." `ascension` is removing Ascension from first chat tab",
			status(XanAscTweaks.filterWorld).." `world`  is removing World from first chat tab",
			status(XanAscTweaks.filterCOA).." `coa` is filtering Conquest of Azeroth Travel Guide",
			status(XanAscTweaks.filterBAU).." `bau` is filtering Northrend Travel Guide",
			status(XanAscTweaks.filterBAUAsc).." `bauchat` is hiding BAU from Ascension and Newcomers",
			status(XanAscTweaks.filterDP).." `dp` is hiding messages that contain dp and don't contain dps",
			status(XanAscTweaks.filterTwitch).." `twitch` is hiding twitch links in Ascension and Newcomers",
		}
		for _,option in pairs(options) do
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

	for filter,_ in pairs(filters) do
		if msg:find(filter) then
			-- match found, suppress the message
			return true
		end
	end
	-- did not match a filter
	return false
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
		for _,v in pairs({"filtersay", "filteryell", "hideAscButton", "filtertrial", "filterMEA", "filterAuto", "filterNew", 
						  "filterAscension", "filterWorld", "filterCOA", "filterBAU", "filterBAUAsc", "filterDP", "filterTwitch"}) do
			XanAscTweaks[v] = true
		end
	end
end

function XAT.frame:PLAYER_ENTERING_WORLD(event, ...)
	-- set up Ascension filters
	filters["Htrial:%d-:"] = XanAscTweaks.filtertrial -- Trials
	filters["%[.-Resolute.-Mode.-%]"] = XanAscTweaks.filtertrial
	filters["%[.-Nightmare.-%]"] = XanAscTweaks.filtertrial
	filters["Hitem:1179126"] = XanAscTweaks.filterMEA -- Mystic Enchanting Altar
	filters["%[.-Ascension.-Autobroadcast.-%]"] = XanAscTweaks.filterAuto -- Auto Broadcasts
	filters["%[.-Conquest of Azeroth Travel Guide.-%]"] = XanAscTweaks.filterCOA
	filters["%[.-Northrend Travel Guide.-%]"] = XanAscTweaks.filterBAU

	if XanAscTweaks.hideAscButton then
		LibDBIcon10_AscensionUICA2:Hide()
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", filterSystem)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", filterAll)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", filterAll)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", filterChannel)

	XAT:wait(1, XAT.hideNew, self)

	SLASH_XAT1 = "/xat"
	SlashCmdList["XAT"] = function(msg) XAT:CommandHandler(msg) end
end

-- Main
XAT.frame:RegisterEvent("ADDON_LOADED")
XAT.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
XAT.frame:SetScript("OnEvent", XAT.XanEventHandler)
