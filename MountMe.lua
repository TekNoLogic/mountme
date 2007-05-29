
----------------------------
--      Localization      --
----------------------------

local L = {}


------------------------------
--      Are you local?      --
------------------------------

local BS = AceLibrary("Babble-Spell-2.2")
local _, myclass = UnitClass("player")
local mounted, flying


-------------------------------------
--      Namespace Declaration      --
-------------------------------------

local mm = DongleStub("Dongle-1.0"):New("MountMe")
MountMe = mm


------------------------------
--      Event Handlers      --
------------------------------

function mm:Enable()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", SetMapToCurrentZone)
	self:RegisterEvent("MountMe_Deshift")
end


function mm:MountMe_Deshift()
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


-------------------------------
--      Mount Detection      --
-------------------------------

local f = CreateFrame("Frame")
f.name = "MountMeMountEvent"
f:SetScript("OnUpdate", function()
	local m, f = IsMounted(), IsFlying()
	if m == mounted and f == flying then return end

	if m and not mounted then mm:TriggerMessage("MountMe_Mounted")
	elseif not m and mounted then mm:TriggerMessage("MountMe_Dismounted") end

	if f and not flying then mm:TriggerMessage("MountMe_Flying")
	elseif not f and flying then mm:TriggerMessage("MountMe_Landed") end

	flying = f
	mounted = m
end)


