
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
local semove = AceLibrary("SpecialEvents-Movement-2.0")
local seaura = AceLibrary("SpecialEvents-Aura-2.0")
local semount = AceLibrary("SpecialEvents-Mount-2.0")
local BS = AceLibrary("Babble-Spell-2.2")

local _, myclass = UnitClass("player")
local spellmounts = {[BS["Summon Felsteed"]] = 60, [BS["Summon Warhorse"]] = 60, [BS["Summon Dreadsteed"]] = 100, [BS["Summon Charger"]] = 100}


-------------------------------------
--      Namespace Declaration      --
-------------------------------------

--~ MountMe = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceConsole-2.0", "AceDB-2.0")
--~ MountMe:RegisterDB("MountMeDB", "MountMeDBPerChar")
--~ MountMe.cmdtable = {type = "group", handler = MountMe, args = {
--~ 	[L["now"]] = {
--~ 		type = "execute",
--~ 		name = L["Mount Me Now!"],
--~ 		desc = L["Mounts with the best available mount or travel form"],
--~ 		func = "Now",
--~ 		order = 1,
--~ 	},
--~ }}
--~ MountMe:RegisterChatCommand({"/mme", "/mountme"}, MountMe.cmdtable)

MountMe = {}

DongleStub("Dongle"):New(MountMe, "MountMe")


---------------------------
--      Ace Methods      --
---------------------------

function MountMe:Initialize()
--~ 	for name,module in self:IterateModules() do
--~ 		if module.consoleOptions then
--~ 			self.cmdtable.args[module.consoleCmd] = module.consoleOptions
--~ 		end
--~ 	end
end


function MountMe:Enable()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", SetMapToCurrentZone)
	self:RegisterEvent("MountMe_Dismount")
	self:RegisterEvent("MountMe_Deshift")
end


------------------------------
--      Event Handlers      --
------------------------------


function MountMe:MountMe_Dismount()
	if not IsMounted() or UnitOnTaxi("player") then return end

	local mount = semount:PlayerMounted()
	local buff = GetPlayerBuffName(mount)

	if buff then
		CancelPlayerBuff(buff)
		return true
	end
end


function MountMe:MountMe_Deshift()
	if myclass == "DRUID" then
		for i=1,GetNumShapeshiftForms() do
			local _, _, active = GetShapeshiftFormInfo(i)
			if active then
				CastShapeshiftForm(i)
				return true
			end
		end
	elseif myclass == "SHAMAN" then
		local i = GetPlayerBuffName(BS["Ghost Wolf"])
		if i then
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
			UseContainerItem(bag, slot)
			if not ininstance then clearout = true end
		elseif bag and not moving and not breath then
			CastSpellByName(bag)
		elseif myclass == "SHAMAN" and UnitLevel("player") >= 20 and not moving then
			CastSpellByName(BS["Ghost Wolf"])
		end

		if clearout then return end

		if myclass == "HUNTER" and UnitLevel("player") then
			if not seaura:UnitHasBuff("player", BS["Aspect of the Cheetah"]) and selearn:SpellKnown(BS["Aspect of the Cheetah"]) then
				CastSpellByName(BS["Aspect of the Cheetah"])
			elseif selearn:SpellKnown(BS["Aspect of the Pack"]) then CastSpellByName(BS["Aspect of the Pack"]) end
		elseif myclass == "DRUID" and UnitLevel("player") >= 30 then
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

