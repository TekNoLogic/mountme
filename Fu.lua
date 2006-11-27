
------------------------------
--      Are you local?      --
------------------------------

-- AceLibrary("SpecialEvents-Equipped-2.0") -- For InBed
local semount = AceLibrary("SpecialEvents-Mount-2.0")
local tablet = AceLibrary("Tablet-2.0")
local dewdrop = AceLibrary("Dewdrop-2.0")
local crayon = AceLibrary("Crayon-2.0")
local BS = AceLibrary("Babble-Spell-2.2")

local defaulticon = "Interface\\Icons\\Ability_Kick"
local buffs, boosts, mountused, mmitemswap = {}, {}
local itemslots = {carrot = 13, spurs = 8, gloves = 10}
local itemboosts = {carrot = 3, spurs = 8, gloves = 4}
local invslots = {[8] = true, [10] = true, [13] = true, [14] = true, [true] = true}
local buffspeeds = {
	[BS["Aspect of the Pack"]] = 30,
	[BS["Aspect of the Cheetah"]] = 30,
	[BS["Ghost Wolf"]] = 40,
	[BS["Travel Form"]] = 40,
	[BS["Aquatic Form"]] = 50,
}


-------------------------------------
--      Namespace Declaration      --
-------------------------------------

MountMeFu = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceConsole-2.0", "AceDB-2.0", "FuBarPlugin-2.0")
--~ MountMe:RegisterDB("MountMeDB", "MountMeDBPerChar")
MountMeFu.hasIcon = defaulticon
MountMeFu.independentProfile = true
--~ MountMeFu.OnMenuRequest = MountMe.cmdtable


---------------------------
--      Ace Methods      --
---------------------------

function MountMeFu:OnEnable()
--~ 	mmitemswap = MountMe:HasModule("ItemSwap") and MountMe:GetModule("ItemSwap")

	self:RegisterEvent("SpecialEvents_Mounted")
	self:RegisterEvent("SpecialEvents_Dismounted")
	self:RegisterEvent("SpecialEvents_PlayerBuffGained")
	self:RegisterEvent("SpecialEvents_PlayerBuffLost")
	self:RegisterEvent("SpecialEvents_EquipmentChanged")
end


-----------------------------
--      FuBar Methods      --
-----------------------------

function MountMeFu:OnTextUpdate()
	local s = 0
	for _,val in pairs(buffs) do s = s + val end
	for _,val in pairs(boosts) do s = s + val end
	self:SetText(string.format("|cff%s%s%%|r", crayon:GetThresholdHexColor(s, 0, 60, 75, 100, 125), s))
end


function MountMeFu:OnTooltipUpdate()
	local cat = tablet:AddCategory("text", "Buffs", "columns", 2)
	for i,val in pairs(buffs) do cat:AddLine("text", i, "text2", string.format("+%d%%", val)) end

	local cat2 = tablet:AddCategory("text", "Boosts", "columns", 2)
	for i,val in pairs(boosts) do
		local link = GetInventoryItemLink("player", itemslots[i])
		local name = link and GetItemInfo(link)
		cat2:AddLine("text", name, "text2", string.format("+%d%%", val))
	end
end


------------------------------
--      Event Handlers      --
------------------------------


function MountMeFu:SpecialEvents_Mounted(buff, speed, idx)
	buffs[buff] = speed
	self:SpecialEvents_EquipmentChanged(true)
	self:SetIcon(GetPlayerBuffTexture(GetPlayerBuff(idx, "HELPFUL")))
	self:Update()
end


function MountMeFu:SpecialEvents_Dismounted(buff)
	mountused = nil
	buffs[buff] = nil
	self:SpecialEvents_EquipmentChanged(true)
	self:SetIcon(defaulticon)
	self:Update()
end


function MountMeFu:SpecialEvents_PlayerBuffGained(buff, idx)
	if buffspeeds[buff] then
		buffs[buff] = buffspeeds[buff]
		self:SetIcon(GetPlayerBuffTexture(GetPlayerBuff(idx, "HELPFUL")))
		self:Update()
	end
end


function MountMeFu:SpecialEvents_PlayerBuffLost(buff)
	if buffs[buff] then self:SetIcon(defaulticon) end
	buffs[buff] = nil
	self:Update()
end


function MountMeFu:SpecialEvents_EquipmentChanged(i)
	if not mmitemswap then return end

	if invslots[i] then
		local mounted = semount:PlayerMounted()
		for item,val in pairs(itemslots) do
			boosts[item] = mounted and mmitemswap:CheckItem(item, val) and itemboosts[item]
		end
		if i ~= true then self:Update() end
	end
end


--~ MountMeFu.OnClick = MountMe.Now



