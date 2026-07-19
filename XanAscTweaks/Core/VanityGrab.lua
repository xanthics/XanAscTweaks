function XAT:getVanity()
	local next = table.remove(XAT.grablist)
	if C_VanityCollection.IsCollectionItemOwned(next) then RequestDeliverVanityCollectionItem(next) end
	if self.db.profile.displayOutput == true then
		DEFAULT_CHAT_FRAME:AddMessage(XAT:setColor("XAT") .. ": Grabbing " .. VANITY_ITEMS[next].name.. " (" .. next .. "). " .. #XAT.grablist .. " item(s) remaining.")
	end
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
		["Cleanse"] = true,
		["Curing"] = true,
		["Frogduck Morph Machine"] = true,
		["Genius Juice"] = true,
		["Harm Repellant Remedy"] = true,
		["Incantation Intensifier"] = true,
		["Interrupt Rod"] = true,
		["Long Haul Liquid"] = true,
		["Manastorm Cleanse"] = true,
		["Manastorm Curing"] = true,
		["Manastorm Purification"] = true,
		["Millhouse Mobility Mixture"] = true,
		["Motion Lotion"] = true,
		["Muscle Maxer"] = true,
		["Purification"] = true,
		["Purge-O-Matic"] = true,
		["Rage Rush Solution"] = true,
		["Reflex Booster"] = true,
		["Sprint Serum"] = true,
		["Taunting Tonic"] = true,
		["Tiny Ticking Time-Bomb"] = true,
		["Hearty Heal Upgrade"] = true,
	}

	if manastorm_items[v.name] then
		return v.name, 1, IsSpellKnown(v.learnedSpell) or not C_Config.GetBoolConfig("CONFIG_MANASTORM_ENABLED")
	end
	local name, rank = v.name:match("(.-) %(Rank (.-)%)")
	if name and manastorm_items[name] then 
			return name, tonumber(rank), IsSpellKnown(v.learnedSpell) or not C_Config.GetBoolConfig("CONFIG_MANASTORM_ENABLED")
	end
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
			[3001007] = true, -- Felforged Tome: Journeyman Riding
			[3001008] = true, -- Felforged Tome: Apprentice Riding
			[1030180] = true, -- Felforged Tome: Track Humanoids
			[79315] = true, -- Felforged Tome: Rush of Adrenaline V
			[101170] = true, -- Felforged Tome: Relentless V
			[79316] = true, -- Felforged Tome: Fel Blood V
		},
		["Alliance"] = {
		},
		["Horde"] = {
		},
	}

	-- some bundles contain a vanity spell that unlocks in your wardrobe but doesn't teach you the spell
	-- [spellID] = vanityID
	local nestedSpell = {
		[571959] = 902229, -- Stargazer's Blessing
		[499428] = 499587, -- Raid Marker - Bundle
	}

	local mCache = {}
	local mmm = {}
	local max_mmm = 0
	local known_mmm = 0
	for _, vanity_item in pairs(C_VanityCollection.GetAllItems()) do
		if C_VanityCollection.IsCollectionItemOwned(vanity_item.itemid) then
			if vanity_item.learnedSpell > 1 then
				local _, _, _, _, _, _, s = GetItemInfo(vanity_item.itemid)
				local name, rank, known = isManastorm(vanity_item)
				if name then
					if not mCache[name] or mCache[name].rank < rank then mCache[name] = { ["rank"] = rank, ["known"] = known, ["id"] = vanity_item.itemid, ["itemid"] = vanity_item.itemid } end
				elseif vanity_item.name:find("Millhouse Mobility Mixture %(Upgrade") then
					if C_Config.GetBoolConfig("CONFIG_MANASTORM_ENABLED") then
						local rank = tonumber(vanity_item.name:match("Millhouse Mobility Mixture %(Upgrade Rank (%d+)"))
						if rank > max_mmm then max_mmm = rank end
						if IsSpellKnown(vanity_item.learnedSpell) and rank > known_mmm then known_mmm = rank end
						mmm[rank] = { ["id"] = vanity_item.itemid, ["itemid"] = vanity_item.itemid }
					end
				elseif not (IsSpellKnown(vanity_item.learnedSpell) or known_spells[vanity_item.learnedSpell]) and not held_items[vanity_item.itemid] then
					if badItems["All"][vanity_item.itemid] or badItems[UnitFactionGroup("player")][vanity_item.itemid] or (vanity_item.name:find("Tome of") and not C_Player:IsHero()) then
						-- DEFAULT_CHAT_FRAME:AddMessage(XAT:setColor("XAT") .. ": Skipping " .. vanity_item.name .. " as it potentially gives an unusable item instead of the spell.")
					else
						table.insert(XAT.grablist, vanity_item.itemid)
					end
				end
			else
				if nestedSpell[vanity_item.itemid] and not held_items[vanity_item.itemid] then
					local spellid = nestedSpell[vanity_item.itemid]
					if not IsSpellKnown(spellid) then
						table.insert(XAT.grablist, vanity_item.itemid)
					end
				end
			end
		end
	end
	for _, v_i in pairs(mCache) do
		if not v_i.known and not held_items[v_i.itemid] then table.insert(XAT.grablist, v_i.id) end
	end
	for i = known_mmm + 1, max_mmm do
		if not held_items[mmm[i].itemid] then table.insert(XAT.grablist, mmm[i].id) end
	end
	if #XAT.grablist > 0 then
		DEFAULT_CHAT_FRAME:AddMessage(XAT:setColor("XAT") .. ": Grabbing " .. #XAT.grablist .. " unlearned vanity spells.")
		self.getVanityTimer = XAT:ScheduleRepeatingTimer("getVanity", 2)
	end
end
