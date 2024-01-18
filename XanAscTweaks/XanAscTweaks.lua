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

function XAT:printmsg(message)
    DEFAULT_CHAT_FRAME:AddMessage(XAT:setColor("XAT") .. ": " .. message)
end

-- toggle the state of a flag
local function toggle(var, text)
    if var then
        XAT:printmsg("`"..text.."` is deactivated.")
        return nil
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
        reload = true
	elseif cmd == "bau" then
		XanAscTweaks.filterBAU = toggle(XanAscTweaks.filterBAU, "Northrend Travel Guide")
        reload = true
	else
		XAT:printmsg("Use '/xat option` where option can be one of; say, yell, button, trial, altar, autobroadcast, new, ascension, world, coa, bau.")
        local options = {
            XanAscTweaks.filtersay and "Say is being filtered" or nil,
            XanAscTweaks.filteryell and "Yell is being filtered" or nil,
            XanAscTweaks.hideAscButton and "Ascension Button is being hidden" or nil,
            XanAscTweaks.filtertrial and "Trials Broadcasts are being filtered" or nil,
            XanAscTweaks.filterMEA and "Mystic Enchanting Altar Broadcasts are being filtered" or nil,
            XanAscTweaks.filterAuto and "Autobroadcasts are being filtered" or nil,
            XanAscTweaks.filterNew and "Newcomers is being removed from first chat window" or nil,
            XanAscTweaks.filterAscension and "Ascension is being removed from first chat window" or nil,
            XanAscTweaks.filterWorld and "World is being removed from first chat window" or nil,
            XanAscTweaks.filterCOA and "Conquest of Azeroth Travel Guide is being filtered" or nil,
            XanAscTweaks.filterBAU and "Northrend Travel Guide is being filtered" or nil,
        }
        for _,option in pairs(options) do
            if option then
                XAT:printmsg(option)
            end
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
        if event == "CHAT_MSG_SAY" and XanAscTweaks.filtersay then
            return true
        end
        if event == "CHAT_MSG_YELL" and XanAscTweaks.filteryell then
            return true
        end
    end
    return false
end

-- filter system messages to remove various unwanted messages
local function filtersystem(self, event, msg, ...)
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

-- At character login set up a command handler and our variables
function XAT:XanEventHandler(event, ...)
	self[event](self, event, ...)
end

-- check that saved variable are initialized
function XAT.frame:ADDON_LOADED(event, ...)
	self:UnregisterEvent("ADDON_LOADED")

    if XanAscTweaks == nil then
		XanAscTweaks = {
            filtersay = true,
            filteryell = true,
            hideAscButton = true,
            filtertrial = true,
            filterMEA = true,
            filterAuto = true,
            filterNew = true,
            filterAscension = true,
            filterWorld = true,
            filterCOA = true,
            filterBAU = true,
        }
	end
end

function XAT.frame:PLAYER_ENTERING_WORLD(event, ...)
    -- set up Ascension filters
    filters["Htrial:%d-:"] = XanAscTweaks.filtertrial -- Trials
    filters["Hitem:1179126"] = XanAscTweaks.filtertrial -- Mystic Enchanting Altar
    filters["%[.-Ascension.-Autobroadcast.-%]"] = XanAscTweaks.filtertrial -- Auto Broadcasts
    filters["%[.-Conquest of Azeroth Travel Guide.-%]"] = XanAscTweaks.filterCOA
    filters["%[.-Northrend Travel Guide.-%]"] = XanAscTweaks.filterBAU

    if XanAscTweaks.hideAscButton then
        LibDBIcon10_AscensionUICA2:Hide()
    end

    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", filtersystem)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", filterAll)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", filterAll)

    XAT:wait(1, XAT.hideNew, self)

	SLASH_XAT1 = "/xat"
	SlashCmdList["XAT"] = function(msg) XAT:CommandHandler(msg) end
end

-- Main
XAT.frame:RegisterEvent("ADDON_LOADED")
XAT.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
XAT.frame:SetScript("OnEvent", XAT.XanEventHandler)
