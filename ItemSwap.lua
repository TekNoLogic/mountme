
----------------------------
--      Localization      --
----------------------------

local L = AceLibrary("AceLocale-2.2"):new("MountMe ItemSwap")

L:RegisterTranslations("enUS", function() return {
	rein = "Reindeer",

	swap = true,
	Swap = true,
	["Options for automatic speed item swapping."] = true,

	temp = true,
	["Suspend temporarily"] = true,
	["Suspend item swaps temporarily, this setting does not persist across sessions."] = true,

	pvp = true,
	["Suspend when PvP"] = true,
	["Suspend item swaps when the player is PvP flagged."] = true,

	bg = true,
	["Suspend in BG"] = true,
	["Suspend item swaps when the player is in a battleground."] = true,
} end)


------------------------------
--      Are you local?      --
------------------------------

local seequip = AceLibrary("SpecialEvents-Equipped-2.0")
local sebags = AceLibrary("SpecialEvents-Bags-2.0")
local semount = AceLibrary("SpecialEvents-Mount-2.0")
local BZ = AceLibrary("Babble-Zone-2.2")

local items, delayed, incombat, raindelay, tempdisable = {}
local itemslots = {carrot = 13, spurs = 8, gloves = 10}
local itemstrs = {carrot = "item:11122:%d+:%d+:%d+", spurs = "item:%d+:464:%d+:%d+", gloves = "item:%d+:930:%d+:%d+"}
local battlegrounds = {
	[BZ["Warsong Gulch"]] = true,
	[BZ["Arathi Basin"]] = true,
	[BZ["Alterac Valley"]] = true,
}


-------------------------------------
--      Namespace Declaration      --
-------------------------------------

MountMeItemSwap = MountMe:NewModule("ItemSwap", "AceEvent-2.0", "AceDebug-2.0")
MountMe:RegisterDefaults("ItemSwap", "profile", {
	BGsuspend = true,
	PvPsuspend = false,
})
MountMeItemSwap.db = MountMe:AcquireDBNamespace("ItemSwap")
MountMeItemSwap.consoleCmd = L["swap"]
MountMeItemSwap.consoleOptions = {
	type = "group",
	name = L["Swap"],
	desc = L["Options for automatic speed item swapping."],
	args = {
		[L["temp"]] = {
			type = "toggle",
			name = L["Suspend temporarily"],
			desc = L["Suspend item swaps temporarily, this setting does not persist across sessions."],
			get = function() return tempdisable end,
			set = function(v) tempdisable = v end,
		},
		[L["pvp"]] = {
			type = "toggle",
			name = L["Suspend when PvP"],
			desc = L["Suspend item swaps when the player is PvP flagged."],
			get = function() return MountMeItemSwap.db.profile.PvPsuspend end,
			set = function(v) MountMeItemSwap.db.profile.PvPsuspend = v end,
		},
		[L["bg"]] = {
			type = "toggle",
			name = L["Suspend in BG"],
			desc = L["Suspend item swaps when the player is in a battleground."],
			get = function() return MountMeItemSwap.db.profile.BGsuspend end,
			set = function(v) MountMeItemSwap.db.profile.BGsuspend = v end,
		},
	}
}


---------------------------
--      Ace Methods      --
---------------------------

function MountMeItemSwap:OnEnable()
	self:ScanInventory()

	self:RegisterEvent("SpecialEvents_Mounted")
	self:RegisterEvent("SpecialEvents_Dismounted")
	self:RegisterEvent("SpecialEvents_BagSlotUpdate")
	self:RegisterEvent("SpecialEvents_EquipmentChanged")

	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
end


------------------------------
--      Event Handlers      --
------------------------------

function MountMeItemSwap:SpecialEvents_Mounted(mount)
	if mount == L.rein then raindelay = true
	else self:Swap() end
end


function MountMeItemSwap:SpecialEvents_Dismounted()
	if incombat then delayed = true
	else self:Swap(true) end
end


function MountMeItemSwap:PLAYER_REGEN_DISABLED()
	if not raindelay then incombat = true end
end


function MountMeItemSwap:PLAYER_REGEN_ENABLED()
	if raindelay then raindelay = nil
	elseif delayed then self:Swap(true) end
	incombat = nil
	delayed = nil
end


function MountMeItemSwap:SpecialEvents_EquipmentChanged()
	if raindelay and not incombat then
		raindelay = nil
		self:Swap()
	end
end


function MountMeItemSwap:SpecialEvents_BagSlotUpdate(bag, slot)
	local itype = self:CheckItem(bag, slot)

	if itype then
		items[itype] = {bag, slot}
	else
		for i in pairs(itemstrs) do
			local s = items[i]
			if s and s[1] == bag and s[2] == slot and not self:CheckItem(i, itemslots[i]) then
				items[i] = nil
				return
			end
		end
	end
end


-----------------------------------
--      Speed item swapping      --
-----------------------------------

function MountMeItemSwap:IsSuspended()
	return tempdisable
		or self.db.profile.PvPsuspend and UnitIsPVP("player")
		or self.db.profile.BGsuspend and battlegrounds[GetZoneText()]
end


function MountMeItemSwap:Swap(reset)
	if self:IsSuspended() then return
	elseif reset then
		for i in pairs(itemstrs) do
			if items[i] and self:CheckItem(i, itemslots[i]) then self:EquipItem(items[i][1], items[i][2]) end
		end
	else
		for i in pairs(itemstrs) do
			if items[i] and not self:CheckItem(i, itemslots[i]) then
				self:EquipItem(items[i][1], items[i][2])
				self.db.char[i] = GetInventoryItemLink("player", itemslots[i])
				self:EquipItem(items[i][1], items[i][2])
			end
		end
	end
end


function MountMeItemSwap:EquipItem(bag, slot)
	if not GetContainerItemLink(bag, slot) then return end
	self:Debug("Equipping", GetContainerItemLink(bag, slot))
	PickupContainerItem(bag, slot)
	AutoEquipCursorItem()
end


----------------------------------
--			Speed item tracking			--
----------------------------------

function MountMeItemSwap:ScanInventory()
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link then
				for i in pairs(itemstrs) do
					if self.db.char[i] and link == self.db.char[i] and self:CheckItem(i, itemslots[i]) then
						items[i] = {bag, slot}
						if not semount:PlayerMounted() then self:EquipItem(bag, slot) end
					end
				end

				local itemtype = self:CheckItem(bag, slot)
				if itemtype then items[itemtype] = {bag, slot} end
			end
		end
	end
end


function MountMeItemSwap:CheckItem(bag, slot)
	assert(bag and slot, "You must pass two args!")

	if type(bag) == "string" then
		assert(itemstrs[bag], "Invalid item type: "..bag)
		local link = GetInventoryItemLink("player", slot)
		if link and string.find(link, itemstrs[bag]) then return true end
	else
		for item,str in pairs(itemstrs) do
			local link = GetContainerItemLink(bag, slot)
			if link and string.find(link, str) then return item end
		end
	end
end

