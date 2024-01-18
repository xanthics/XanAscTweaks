-- XAT lets us communicate between files (Addon Namespace)
local _, XAT = ...
XAT.__index = XAT

local waitTable = {}
local waitFrame = nil

function XAT:waitOnUpdate(elapse)
	local count = #waitTable
	local i = 1
	while ( i <= count )
	do
		local waitRecord = tremove(waitTable,i)
		local d = tremove(waitRecord,1)
		local f = tremove(waitRecord,1)
		local p = tremove(waitRecord,1)

		if ( d > elapse ) then
			tinsert(waitTable, i, {d-elapse, f, p})
			i = i + 1
		else
			count = count - 1
			f(unpack(p))
		end
	end

	if ( #waitTable == 0 ) then
		waitFrame:SetScript("onUpdate", nil)
	end
end

function XAT:wait(delay, func, ...)
	if ( type(delay) ~= "number" or type(func) ~= "function" ) then
		return false
	end

	if ( waitFrame == nil ) then
		waitFrame = CreateFrame("Frame", "WaitFrame", UIParent)
	end

	waitFrame:SetScript("onUpdate", XAT.waitOnUpdate)

	tinsert(waitTable, {delay, func, {...}})

	return true
end

function XAT:clearWait()
	waitTable = {}
end
