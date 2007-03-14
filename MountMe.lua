
BINDING_HEADER_MOUNTME = "MountMe"


----------------------------
--      Localization      --
----------------------------

local L = {
	now = "now",
	["Mount Me Now!"] = "Mount Me Now!",
	["Mounts with the best available mount or travel form"] = "Mounts with the best available mount or travel form",
}


------------------------------
--      Are you local?      --
------------------------------

-- AceLibrary("SpecialEvents-Equipped-2.0") -- For InBed
local pt = AceLibrary("PeriodicTable-2.0")
local selearn = AceLibrary("SpecialEvents-LearnSpell-2.0")
local semove = AceLibrary("SpecialEvents-Movement-2.0")
local seaura = AceLibrary("SpecialEvents-Aura-2.0")
local semount = AceLibrary("SpecialEvents-Mount-2.0")
local BS = AceLibrary("Babble-Spell-2.2")

local frame
local _, myclass = UnitClass("player")
local spellmounts = {[BS["Summon Felsteed"]] = 60, [BS["Summon Warhorse"]] = 60, [BS["Summon Dreadsteed"]] = 100, [BS["Summon Charger"]] = 100}


-------------------------------------
--      Namespace Declaration      --
-------------------------------------

--~ MountMe = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceConsole-2.0", "AceDB-2.0")
--~ MountMe:RegisterDB("MountMeDB", "MountMeDBPerChar")
--~ MountMe.cmdtable = {type = "group", handler = MountMe, args = {}}
--~ MountMe:RegisterChatCommand({"/mme", "/mountme"}, MountMe.cmdtable)

MountMe = DongleStub("Dongle-Beta1"):New("MountMe")


---------------------------
--      Ace Methods      --
---------------------------

function MountMe:Initialize()
	frame = CreateFrame("Button", "MountMeFrame", UIParent, "SecureActionButtonTemplate")

	frame.SetManyAttributes = DongleStub("DongleUtils-Beta0").SetManyAttributes
	frame:EnableMouse(true)
	frame:SetScript("PreClick", MountMe.PreClick)
	frame:Hide()

--~ 	frame:SetMovable(true)
--~ 	frame:SetPoint("CENTER", UIParent, "CENTER",-150,-150)
--~ 	frame:SetWidth(50)
--~ 	frame:SetHeight(50)
--~ 	frame:SetBackdrop({
--~ 		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 16,
--~ 		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
--~ 		insets = {left = 4, right = 4, top = 4, bottom = 4},
--~ 	})


--~ 	for name,module in self:IterateModules() do
--~ 		if module.consoleOptions then
--~ 			self.cmdtable.args[module.consoleCmd] = module.consoleOptions
--~ 		end
--~ 	end
end


function MountMe:Enable()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", SetMapToCurrentZone)
	self:RegisterEvent("MountMe_Deshift")
end


------------------------------
--      Event Handlers      --
------------------------------

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

function MountMe:GetRandomMount()
	if UnitLevel("player") < 40 then return end

	local norms, epics = {}, {}
	local found = {[60] = norms, [100] = epics}

	if GetZoneText() == "Ahn'Qiraj" then
		for bag,slot,val in pt:BagIter("Mounts - AQ") do
			local name = GetItemInfo(GetContainerItemLink(bag, slot))
			self:Debug(1, "Found AQ mount", name)
			table.insert(found[val], name)
		end
	end

	if #epics == 0 then
		for bag,slot,val in pt:BagIter("Mounts") do
			local name = GetItemInfo(GetContainerItemLink(bag, slot))
			self:Debug(1, "Found mount", name)
			table.insert(found[val], name)
		end

		for name,speed in pairs(spellmounts) do
			if selearn:SpellKnown(name) then
				self:Debug(1, "Found spell", name)
				table.insert(found[speed], name)
			end
		end
	end

	self:Debug(1, "Epics found", #epics, "Norms found", #norms)
	if #epics > 0 then return epics[math.random(#epics)] end
	if #norms > 0 then return norms[math.random(#norms)] end
end


function MountMe.PreClick(button, down)
	local lvl = UnitLevel("player")
	if InCombatLockdown() then return end

	if IsSwimming() then
		if myclass == "DRUID" and UnitLevel("player") >= 16 then CastShapeshiftForm(2)
		elseif GetItemInfo(GetInventoryItemLink("player", 16)) == "Hydrocane" then frame:SetAttribute("type1", ATTRIBUTE_NOOP)
		else frame:SetManyAttributes("type1", "macro", "macrotext", "/equip Hydrocane") end
	elseif IsMounted() then
		Dismount()
		frame:SetAttribute("type1", ATTRIBUTE_NOOP)
	elseif MountMe:MountMe_Deshift() then frame:SetAttribute("type1", ATTRIBUTE_NOOP)
	elseif myclass == "SHAMAN" and lvl < 40 and lvl >= 20 then frame:SetManyAttributes("type1", "spell", "spell", BS["Ghost Wolf"])
	elseif semove:PlayerMoving() then
		if myclass == "DRUID" and UnitLevel("player") >= 30 then CastShapeshiftForm(4)
		elseif myclass == "HUNTER" and UnitLevel("player") then
			if not GetPlayerBuffName("player", BS["Aspect of the Cheetah"]) and selearn:SpellKnown(BS["Aspect of the Cheetah"]) then
				frame:SetManyAttributes("type1", "spell", "spell", BS["Aspect of the Cheetah"])
			elseif selearn:SpellKnown(BS["Aspect of the Pack"]) then frame:SetManyAttributes("type1", "spell", "spell", BS["Aspect of the Pack"])
			else frame:SetAttribute("type1", ATTRIBUTE_NOOP) end
		else frame:SetAttribute("type1", ATTRIBUTE_NOOP) end
	else
		-- Use our mount item
		local rand = MountMe:GetRandomMount()
		if not rand then return end
		local isspell = spellmounts[rand]
		frame:SetAttribute("type1", isspell and "spell" or "item")
		frame:SetAttribute(isspell and "spell" or "item", rand)
	end
end

