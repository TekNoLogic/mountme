
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

local _, myclass = UnitClass("player")
local forms = myclass == "SHAMAN" and {"Ghost Wolf"} or myclass == "DRUID" and {"Cat Form", "Bear Form", "Travel Form", "Dire Bear Form"}
local items, delayed, incombat, tempdisable, dbpc, mounted = {}
local unknowns = {carrot = 13, crop = 13, whip = 13, spurs = 8, gloves = 10}
local itemslots = {carrot = 13, crop = 13, whip = 13, spurs = 8, gloves = 10}
local itemstrs = {carrot = "item:11122:%d+:%d+:%d+", crop = "item:25653:%d+:%d+:%d+", whip = "item:32863:%d+:%d+:%d+", spurs = "item:%d+:464:%d+:%d+", gloves = "item:%d+:930:%d+:%d+"}
local battlegrounds = {
	[L["Warsong Gulch"]] = true,
	[L["Arathi Basin"]] = true,
	[L["Alterac Valley"]] = true,
}


-------------------------------------
--      Namespace Declaration      --
-------------------------------------

MountMe = DongleStub("Dongle-1.0"):New("MountMe", CreateFrame("Frame"))
if tekDebug then MountMe:EnableDebug(1, tekDebug:GetFrame("MountMe")) end
MountMe.db = {profile ={BGsuspend = true, PvPsuspend = false}} -- temp fix until Dongle gets DB namespaces


------------------------------
--      Dongle Methods      --
------------------------------

function MountMe:Initialize()
	MountMeItemSwapDB = MountMeItemSwapDB or {}
	dbpc = MountMeItemSwapDB
end


function MountMe:Enable()
	if forms then self:RegisterEvent("TAXIMAP_OPENED") end

	self:ScanInventory()

	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
end


-------------------------------
--      Mount Detection      --
-------------------------------

MountMe:SetScript("OnUpdate", function(self)
	local m = IsMounted()
	if m == mounted then return end

	if m then
		self:Debug(1, "Mounted")
		self:Swap()
	else
		self:Debug(1, "Dismounted")
		if incombat then delayed = true
		else self:SwapReset() end
	end

	mounted = m
end)


------------------------------
--      Event Handlers      --
------------------------------

function MountMe:TAXIMAP_OPENED()
	for _,form in pairs(forms) do CancelPlayerBuff(form) end
end


function MountMe:PLAYER_REGEN_DISABLED()
	incombat = true
end


function MountMe:PLAYER_REGEN_ENABLED()
	if delayed then self:SwapReset() end
	incombat = nil
	delayed = nil
end


-----------------------------------
--      Speed item swapping      --
-----------------------------------

function MountMe:IsSuspended()
	return tempdisable
		or self.db.profile.PvPsuspend and UnitIsPVP("player")
		or self.db.profile.BGsuspend and battlegrounds[GetZoneText()]
end


function MountMe:Swap(reset)
	if self:IsSuspended() or not HasFullControl() then return end
	if next(unknowns) then self:ScanInventory() end

	for i in pairs(itemstrs) do
		if items[i] and not self:CheckItem(i, itemslots[i]) then
			dbpc[i] = GetInventoryItemLink("player", itemslots[i])
			self:EquipItem(items[i])
		end
	end
end


function MountMe:SwapReset()
	for i,link in pairs(dbpc) do
		self:EquipItem(link)
		dbpc[i] = nil
	end
end


function MountMe:EquipItem(a1, a2)
	if type(a1) == "string" then
		for bag=0,4 do
			for slot=1,GetContainerNumSlots(bag) do
				local link = GetContainerItemLink(bag, slot)
				if link and a1 == link then
					self:Debug(1, "Equipping", link)
					if CursorHasItem() or CursorHasMoney() or CursorHasSpell() then ClearCursor() end
					PickupContainerItem(bag, slot)
					AutoEquipCursorItem()
					return true
				end
			end
		end
	else
		if not GetContainerItemLink(a1, a2) then return end
		self:Debug(1, "Equipping", GetContainerItemLink(a1, a2))
		if CursorHasItem() or CursorHasMoney() or CursorHasSpell() then ClearCursor() end
		PickupContainerItem(a1, a2)
		AutoEquipCursorItem()
		return true
	end
end


----------------------------------
--			Speed item tracking			--
----------------------------------

function MountMe:ScanInventory()
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


function MountMe:CheckItem(bag, slot)
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

