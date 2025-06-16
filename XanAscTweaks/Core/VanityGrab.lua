function XAT:getVanity()
	DEFAULT_CHAT_FRAME:AddMessage(XAT:setColor("XAT") .. ": " .. #XAT.grablist .. " item(s) left to grab.")
	local next = table.remove(XAT.grablist)
	if C_VanityCollection.IsCollectionItemOwned(next) then RequestDeliverVanityCollectionItem(next) end
	if #XAT.grablist <= 0 then self:CancelTimer(self.getVanityTimer) end
end

local function findpartial(items, word)
	for _, s in ipairs(items) do
		if word:find(s) then return true end
	end
	return false
end

local function hasitem(itemID)
	local item, found, id
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			item = GetContainerItemLink(bag, slot)
			if item then
				found, _, id = item:find("^|c%x+|Hitem:(%d+):.+")
				if found and tonumber(id) == itemID then return true end
			end
		end
	end
	return false
end

local function helditems()
	local ret = {}
	local item, found, id
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			item = GetContainerItemLink(bag, slot)
			if item then
				found, _, id = item:find("^|c%x+|Hitem:(%d+):.+")
				if found then ret[tonumber(id)] = true end
			end
		end
	end
	return ret
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

	if name and manastorm_items[name] then return name, tonumber(rank), IsSpellKnown(v.learnedSpell) end
end

function XAT:grabVanity()
	XAT.grablist = {}
	local known_spells = {}
	local held_items = helditems()
	for i = 1, GetNumCompanions("CRITTER") do
		local _, _, sID = GetCompanionInfo("CRITTER", i)
		known_spells[sID] = true
	end
	for i = 1, GetNumCompanions("MOUNT") do
		local _, _, sID = GetCompanionInfo("MOUNT", i)
		known_spells[sID] = true
	end

	local badItems = {
		["All"] = {
			[222739] = true, -- Tome of Polymorph: Frogduck
		},
		["Alliance"] = {
			--			[1780054] = true, -- Stone of Retreat: Razor Hill
		},
		["Horde"] = {
			--			[1780051] = true, -- Stone of Retreat: Goldshire
		},
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
				if not mCache[name] or mCache[name].rank < rank then mCache[name] = { ["rank"] = rank, ["known"] = known, ["id"] = k, ["itemid"] = v.itemid } end
			elseif v.name:find("Millhouse Mobility Mixture %(Upgrade") then
				local rank = tonumber(v.name:match("Millhouse Mobility Mixture %(Upgrade Rank (%d+)"))
				if rank > max_mmm then max_mmm = rank end
				if IsSpellKnown(v.learnedSpell) and rank > known_mmm then known_mmm = rank end
				mmm[rank] = { ["id"] = k, ["itemid"] = v.itemid }
			elseif not (IsSpellKnown(v.learnedSpell) or known_spells[v.learnedSpell]) and not held_items[v.itemid] then
				if badItems["All"][v.itemid] or badItems[UnitFactionGroup("player")][v.itemid] then
					-- DEFAULT_CHAT_FRAME:AddMessage(XAT:setColor("XAT") .. ": Skipping " .. v.name .. " as it gives a potentially unusable item instead of the spell.")
				else
					table.insert(XAT.grablist, k)
				end
			end
		end
	end
	for k, v in pairs(mCache) do
		if not v.known and not held_items[v.itemid] then table.insert(XAT.grablist, v.id) end
	end
	for i = known_mmm + 1, max_mmm do
		if not held_items[mmm[i].itemid] then table.insert(XAT.grablist, mmm[i].id) end
	end
	if #XAT.grablist > 0 then
		DEFAULT_CHAT_FRAME:AddMessage(XAT:setColor("XAT") .. ": Grabbing " .. #XAT.grablist .. " unlearned vanity spells.")
		self.getVanityTimer = XAT:ScheduleRepeatingTimer("getVanity", 2)
	end
end
