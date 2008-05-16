
----------------------------
--      Localization      --
----------------------------

local L = {
	["Flight Form"] = "Flight Form",
	["Swift Flight Form"] = "Swift Flight Form",
}


------------------------------
--      Are you local?      --
------------------------------

local _, myclass = UnitClass("player")
local items, equipCheck, delayed, incombat, dbpc, mounted, isflight = {}, {}
local forms = myclass == "SHAMAN" and {"Ghost Wolf"} or myclass == "DRUID" and {"Cat Form", "Bear Form", "Travel Form", "Dire Bear Form", "Flight Form", "Swift Flight Form"}
local itemstrs = {carrot = "item:11122:%d+:%d+:%d+", crop = "item:25653:%d+:%d+:%d+", charm = "item:32481:%d+:%d+:%d+", whip = "item:32863:%d+:%d+:%d+", spurs = "item:%d+:464:%d+:%d+", gloves = "item:%d+:930:%d+:%d+"}
local itemslots = {carrot = 13, crop = 13, whip = 13, charm = 13, spurs = 8, gloves = 10}
local unknowns = {carrot = 13, crop = 13, whip = 13, charm = 13, spurs = 8, gloves = 10}


-------------------------------------
--      Namespace Declaration      --
-------------------------------------

MountMe = DongleStub("Dongle-1.0"):New("MountMe", CreateFrame("Frame"))
if tekDebug then MountMe:EnableDebug(1, tekDebug:GetFrame("MountMe")) end


------------------------------
--      Dongle Methods      --
------------------------------

function MountMe:Initialize()
	MountMeDB = MountMeDB or {BGsuspend = true, PvPsuspend = false}
	self.db = MountMeDB

	MountMeItemSwapDB = MountMeItemSwapDB or {}
	dbpc = MountMeItemSwapDB
end


function MountMe:Enable()
	self:ScanInventory()

	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_AURAS_CHANGED")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	if forms then self:RegisterEvent("TAXIMAP_OPENED") end
end


-------------------------------
--      Mount Detection      --
-------------------------------

MountMe:SetScript("OnUpdate", function(self)
	local m = IsMounted() or isflight
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
	if delayed then self:SwapReset()
	else for i, link in pairs(equipCheck) do EquipItemByName(link) end end
	incombat, delayed = nil, nil
end


function MountMe:PLAYER_AURAS_CHANGED()
	isflight = nil

	for i=1, GetNumShapeshiftForms() do
		local _, name, active = GetShapeshiftFormInfo(i)
		if active and (name == L["Flight Form"] or name == L["Swift Flight Form"]) then isflight = true end
	end
end


function MountMe:UNIT_INVENTORY_CHANGED()
	for itemtype,link in pairs(equipCheck) do
		if link == GetInventoryItemLink("player", itemslots[itemtype]) then equipCheck[itemtype] = nil end
	end
end


-----------------------------------
--      Speed item swapping      --
-----------------------------------

function MountMe:IsSuspended()
	-- While you can switch trinkets while inside an arena, you cannot once the match starts so we're disabled when inside arenas no matter what
	local _, instanceType = IsInInstance()
	if self.db.PvPsuspend and UnitIsPVP("player")
		or self.db.BGsuspend and instanceType == "pvp"
		or instanceType == "arena" then return true end
end


function MountMe:Swap(reset)
	if self:IsSuspended() or not HasFullControl() then return end
	if next(unknowns) then self:ScanInventory() end

	for i, matchstr in pairs(itemstrs) do
		local link = GetInventoryItemLink("player", itemslots[i])
		if items[i] and (not link or not string.match(link, matchstr)) and ((i ~= "charm" and not isflight) or (i == "charm" and isflight)) then
			-- Makes sure we don't change our originally equipped item if it's our charm mainly this is for Flight Form since spamming it can mess up our original item
			if link ~= items[i] and equipCheck[i] ~= link then dbpc[i] = link end
			EquipItemByName(items[i])
		end
	end
end


-- Reset our gear to the unmounted version
function MountMe:SwapReset()
	for i, link in pairs(dbpc) do
		dbpc[i] = nil
		equipCheck[i] = link
		EquipItemByName(link)
	end
end


----------------------------------
--      Speed item tracking     --
----------------------------------

function MountMe:ScanInventory()
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link then
				-- Check if we need to add it to our list of mounted items
				for i, matchstr in pairs(itemstrs) do
					if string.match(link, matchstr) then
						unknowns[i] = nil
						items[i] = link
						break
					end
				end
			end
		end
	end
end
