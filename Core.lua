
BINDING_HEADER_MOUNTME = "MountMe"


----------------------------
--      Localization      --
----------------------------

local L = AceLibrary("AceLocale-2.2"):new("MountMe")

L:RegisterTranslations("enUS", function() return {
	now = true,
	["Mount Me Now!"] = true,
	["Mounts with the best available mount or travel form"] = true,
} end)


------------------------------
--      Are you local?      --
------------------------------

-- AceLibrary("PeriodicTable-Misc-2.0") -- For InBed
-- AceLibrary("SpecialEvents-Equipped-2.0") -- For InBed
local pt = AceLibrary("PeriodicTable-Core-2.0")
local selearn = AceLibrary("SpecialEvents-LearnSpell-2.0")
local sebreath = not IsSwimming and AceLibrary("SpecialEvents-Breath-2.0")
local semove = AceLibrary("SpecialEvents-Movement-2.0")
local seaura = AceLibrary("SpecialEvents-Aura-2.0")
local semount = AceLibrary("SpecialEvents-Mount-2.0")
local compost = AceLibrary("Compost-2.0")
local tablet = AceLibrary("Tablet-2.0")
local dewdrop = AceLibrary("Dewdrop-2.0")
local crayon = AceLibrary("Crayon-2.0")
local BS = AceLibrary("Babble-Spell-2.2")

local _, myclass = UnitClass("player")
local spellmounts = {[BS["Summon Felsteed"]] = 60, [BS["Summon Warhorse"]] = 60, [BS["Summon Dreadsteed"]] = 100, [BS["Summon Charger"]] = 100}
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

MountMe = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceModuleCore-2.0", "AceConsole-2.0", "AceDB-2.0", "AceDebug-2.0", "FuBarPlugin-2.0")
MountMe:RegisterDB("MountMeDB", "MountMeDBPerChar")
MountMe.cmdtable = {type = "group", handler = MountMe, args = {
	[L["now"]] = {
		type = "execute",
		name = L["Mount Me Now!"],
		desc = L["Mounts with the best available mount or travel form"],
		func = "Now",
		order = 1,
	},
}}
MountMe:RegisterChatCommand({"/mme", "/mountme"}, MountMe.cmdtable)
MountMe.hasIcon = defaulticon
MountMe.independentProfile = true
MountMe.OnMenuRequest = MountMe.cmdtable


---------------------------
--      Ace Methods      --
---------------------------

function MountMe:OnInitialize()
	for name,module in self:IterateModules() do
		if module.consoleOptions then
			self.cmdtable.args[module.consoleCmd] = module.consoleOptions
		end
	end
end


function MountMe:OnEnable()
	mmitemswap = self:HasModule("ItemSwap") and self:GetModule("ItemSwap")

	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", SetMapToCurrentZone)
	self:RegisterEvent("SpecialEvents_Mounted")
	self:RegisterEvent("SpecialEvents_Dismounted")
	self:RegisterEvent("SpecialEvents_PlayerBuffGained")
	self:RegisterEvent("SpecialEvents_PlayerBuffLost")
	self:RegisterEvent("MountMe_Dismount")
	self:RegisterEvent("MountMe_Deshift")
	self:RegisterEvent("SpecialEvents_EquipmentChanged")
end


-----------------------------
--      FuBar Methods      --
-----------------------------

function MountMe:OnTextUpdate()
	local s = 0
	for _,val in pairs(buffs) do s = s + val end
	for _,val in pairs(boosts) do s = s + val end
	self:SetText(string.format("|cff%s%s%%|r", crayon:GetThresholdHexColor(s, 0, 60, 75, 100, 125), s))
end


function MountMe:OnTooltipUpdate()
	local cat = tablet:AddCategory("text", "Buffs", "columns", 2)
	for i,val in pairs(buffs) do cat:AddLine("text", i, "text2", string.format("+%d%%", val)) end

	local cat2 = tablet:AddCategory("text", "Boosts", "columns", 2)
	for i,val in pairs(boosts) do
		local link = GetInventoryItemLink("player", itemslots[i])
		if link then _, _, link = string.find(link, "(item:%d+:%d+:%d+:%d+)") end
		local name = link and GetItemInfo(link)
		cat2:AddLine("text", name, "text2", string.format("+%d%%", val))
	end
end


------------------------------
--      Event Handlers      --
------------------------------


function MountMe:SpecialEvents_Mounted(buff, speed, idx)
	buffs[buff] = speed
	self:SpecialEvents_EquipmentChanged(true)
	self:SetIcon(GetPlayerBuffTexture(GetPlayerBuff(idx, "HELPFUL")))
	self:Update()
end


function MountMe:SpecialEvents_Dismounted(buff)
	mountused = nil
	buffs[buff] = nil
	self:SpecialEvents_EquipmentChanged(true)
	self:SetIcon(defaulticon)
	self:Update()
end


function MountMe:SpecialEvents_PlayerBuffGained(buff, idx)
	if buffspeeds[buff] then
		buffs[buff] = buffspeeds[buff]
		self:SetIcon(GetPlayerBuffTexture(GetPlayerBuff(idx, "HELPFUL")))
		self:Update()
	end
end


function MountMe:SpecialEvents_PlayerBuffLost(buff)
	if buffs[buff] then self:SetIcon(defaulticon) end
	buffs[buff] = nil
	self:Update()
end


function MountMe:SpecialEvents_EquipmentChanged(i)
	if not mmitemswap then return end

	if invslots[i] then
		local mounted = semount:PlayerMounted()
		for item,val in pairs(itemslots) do
			boosts[item] = mounted and mmitemswap:CheckItem(item, val) and itemboosts[item]
		end
		if i ~= true then self:Update() end
	end
end


function MountMe:MountMe_Dismount()
	local mount = semount:PlayerMounted()
	local mountidx = seaura:UnitHasBuff("player", mount)

	if mountused and mount and not UnitOnTaxi("player") then
		self:Debug("Cancelling ".. mount.. " with item ".. mountused[1].. ":".. mountused[2])
		UseContainerItem(unpack(mountused))
		return true
	elseif (mountidx and mount and not UnitOnTaxi("player")) then
		mountidx = GetPlayerBuff(mountidx, "HELPFUL")
		self:Debug("Cancelling ".. mount.. " in buff#".. mountidx)
		CancelPlayerBuff(mountidx)
		return true
	end
end


function MountMe:MountMe_Deshift()
	if myclass == "DRUID" then
		for i=1,GetNumShapeshiftForms() do
			local _, _, active = GetShapeshiftFormInfo(i)
			if active then
				self:Debug("Cancelling form ".. i)
				CastShapeshiftForm(i)
				return true
			end
		end
	elseif myclass == "SHAMAN" then
		local i = seaura:UnitHasBuff("player", BS["Ghost Wolf"])
		if i then
			i = GetPlayerBuff(i, "HELPFUL")
			self:Debug("Cancelling Ghost Wolf in buff#".. i)
			CancelPlayerBuff(i)
			return true
		end
	end
end


------------------------------
--      Mount handling      --
------------------------------

function MountMe:Now()
	if UnitAffectingCombat("player") then return end
	if IsSwimming() then
		if myclass == "DRUID" and UnitLevel("player") >= 16 then
			self:Debug("Casting Aquaman")
			CastShapeshiftForm(2)
		end
		return
	else
		local bag, slot = self:GetRandomMount()
		local moving = semove:PlayerMoving()
		local ininstance = IsInInstance()

		local stspells, clearout = not moving

		if self:MountMe_Deshift() or self:MountMe_Dismount() then return
		elseif bag and slot and not moving and not breath then
			self:Debug("Mounting with item @ "..bag..":"..slot)
			UseContainerItem(bag, slot)
			mountused = {bag, slot}
			if not ininstance then clearout = true end
		elseif bag and not moving and not breath then
			self:Debug("Mounting with spell "..bag)
			mountused = nil
			CastSpellByName(bag)
		elseif myclass == "SHAMAN" and UnitLevel("player") >= 20 and not moving then
			self:Debug("Casting ".. BS["Ghost Wolf"])
			CastSpellByName(BS["Ghost Wolf"])
		end

		if clearout then return end

		if myclass == "HUNTER" and UnitLevel("player") then
			if not seaura:UnitHasBuff("player", BS["Aspect of the Cheetah"]) and selearn:SpellKnown(BS["Aspect of the Cheetah"]) then
				CastSpellByName(BS["Aspect of the Cheetah"])
			elseif selearn:SpellKnown(BS["Aspect of the Pack"]) then CastSpellByName(BS["Aspect of the Pack"]) end
		elseif myclass == "DRUID" and UnitLevel("player") >= 30 then
			self:Debug("Casting travel form")
			CastShapeshiftForm(4)
		end
	end
end


--~ MountMe.OnClick = MountMe.Now


local function GetRandomMount()
	if UnitLevel("player") < 40 then return end

	local found = {[60] = {}, [100] = {}}
	local inaq = GetZoneText() == "Ahn'Qiraj"

	if inaq then
		for bag,slot,val in pt:BagIter("mountsaq") do
			local name = GetItemInfo(GetContainerItemLink(bag, slot))
			table.insert(found[val], name)
		end
	end

	if table.getn(found[100]) == 0 then
		for bag,slot,val in pt:BagIter("mounts") do
			local name = GetItemInfo(GetContainerItemLink(bag, slot))
			table.insert(found[val], name)
		end

		for name,speed in pairs(spellmounts) do
			if selearn:SpellKnown(name) then table.insert(found[speed], name) end
		end
	end

	local norms, epics = table.getn(found[60]), table.getn(found[100])

	if epics > 0 then return found[100][math.random(1, epics)] end
	if norms > 0 then return found[60][math.random(1, norms)] end
end


-------------------------------------


local f = CreateFrame("Button", "MountMeFrame", UIParent, "SecureActionButtonTemplate")

f:EnableMouse(true)
--~ f:SetMovable(true)
f:SetPoint("CENTER", UIParent, "CENTER",-150,-150)
f:SetWidth(50)
f:SetHeight(50)

f:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 16,
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
	insets = {left = 4, right = 4, top = 4, bottom = 4},
})

f:Show()

f:SetScript("PreClick", function(button, down)
	if InCombatLockdown() then return end

	if IsSwimming() then
		if GetItemInfo(GetInventoryItemLink("player", 16)) == "Hydrocane" then
			f:SetAttribute("type1", ATTRIBUTE_NOOP)
		else
			f:SetAttribute("type1", ATTRIBUTE_NOOP)
			f:SetAttribute("type1", "macro")
			f:SetAttribute("macrotext", "/equip Hydrocane")
		end
	elseif IsMounted() then
		f:SetAttribute("type1", ATTRIBUTE_NOOP)
		MountMe:MountMe_Dismount()
	elseif MountMe:MountMe_Deshift() then
		f:SetAttribute("type1", ATTRIBUTE_NOOP)
	else
		-- Use our mount item
		local rand = GetRandomMount()
		if not rand then return end
		local isspell = spellmounts[rand]
		f:SetAttribute("type1", isspell and "spell" or "item")
		f:SetAttribute(isspell and "spell" or "item", rand)
	end
end)

