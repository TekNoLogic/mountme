
----------------------------
--      Localization      --
----------------------------

local L = {
	["Warsong Gulch"] = "Warsong Gulch",
	["Arathi Basin"] = "Arathi Basin",
	["Alterac Valley"] = "Alterac Valley",
}


------------------------------
--      Are you local?      --
------------------------------

local items, delayed, incombat, tempdisable, dbpc = {}
local unknowns = {carrot = 13, spurs = 8, gloves = 10}
local itemslots = {carrot = 13, spurs = 8, gloves = 10}
local itemstrs = {carrot = "item:11122:%d+:%d+:%d+", spurs = "item:%d+:464:%d+:%d+", gloves = "item:%d+:930:%d+:%d+"}
local battlegrounds = {
	[L["Warsong Gulch"]] = true,
	[L["Arathi Basin"]] = true,
	[L["Alterac Valley"]] = true,
}


-------------------------------------
--      Namespace Declaration      --
-------------------------------------

MountMeItemSwap = MountMe:NewModule("MountMe-ItemSwap")
MountMeItemSwap.db = {profile ={BGsuspend = true, PvPsuspend = false}} -- temp fix until Dongle gets DB namespaces


---------------------------
--      Ace Methods      --
---------------------------

function MountMeItemSwap:Initialize()
	MountMeItemSwapDB = MountMeItemSwapDB or {}
	dbpc = MountMeItemSwapDB
end


function MountMeItemSwap:Enable()
	self:ScanInventory()

	self:RegisterMessage("MountMe_Mounted")
	self:RegisterMessage("MountMe_Dismounted")

	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
end


------------------------------
--      Event Handlers      --
------------------------------

function MountMeItemSwap:MountMe_Mounted()
	self:Debug(1, "Mounted")
	self:Swap()
end


function MountMeItemSwap:MountMe_Dismounted()
	self:Debug(1, "Dismounted")
	if incombat then delayed = true
	else self:SwapReset() end
end


function MountMeItemSwap:PLAYER_REGEN_DISABLED()
	incombat = true
end


function MountMeItemSwap:PLAYER_REGEN_ENABLED()
	if delayed then self:SwapReset() end
	incombat = nil
	delayed = nil
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
	if self:IsSuspended() then return end
	if next(unknowns) then self:ScanInventory() end

	for i in pairs(itemstrs) do
		if items[i] and not self:CheckItem(i, itemslots[i]) then
			dbpc[i] = GetInventoryItemLink("player", itemslots[i])
			self:EquipItem(items[i])
		end
	end
end


function MountMeItemSwap:SwapReset()
	for i,link in pairs(dbpc) do
		self:EquipItem(link)
		dbpc[i] = nil
	end
end


function MountMeItemSwap:EquipItem(a1, a2)
	if type(a1) == "string" then
		for bag=0,4 do
			for slot=1,GetContainerNumSlots(bag) do
				local link = GetContainerItemLink(bag, slot)
				if link and a1 == link then
					self:Debug(1, "Equipping", link)
					PickupContainerItem(bag, slot)
					AutoEquipCursorItem()
					return true
				end
			end
		end
	else
		if not GetContainerItemLink(a1, a2) then return end
		self:Debug(1, "Equipping", GetContainerItemLink(a1, a2))
		PickupContainerItem(a1, a2)
		AutoEquipCursorItem()
		return true
	end
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
					if dbpc[i] and link == dbpc[i] and self:CheckItem(i, itemslots[i]) then
						items[i] = link
						if not IsMounted() then self:EquipItem(bag, slot) end
					end
				end

				local itemtype = self:CheckItem(bag, slot)
				if itemtype then
					unknowns[itemtype] = nil
					items[itemtype] = link
				end
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

