
----------------------------
--      Localization      --
----------------------------

local L = {
	dismount = true,
	Dismount = true,
	["Options for Dismounting."] = true,

	deshift = true,
	["Deshift on error"] = true,
	["Clears shapeshifts on \"Can't do that when shapeshifted\" errors."] = true,

}
for i,v in pairs(L) do if v == true then L[i] = i end end -- Too lazy to copy/paste right now


------------------------------
--      Are you local?      --
------------------------------

local _, myclass = UnitClass("player")
local shifterrors = {
	[ERR_CANT_INTERACT_SHAPESHIFTED] = true,
	[ERR_MOUNT_SHAPESHIFTED] = true,
	[ERR_NOT_WHILE_SHAPESHIFTED] = true,
	[ERR_NO_ITEMS_WHILE_SHAPESHIFTED] = true,
	[SPELL_FAILED_NOT_SHAPESHIFT] = true,
	[SPELL_FAILED_NO_ITEMS_WHILE_SHAPESHIFTED] = true,
	[SPELL_NOT_SHAPESHIFTED] = true,
	[SPELL_NOT_SHAPESHIFTED_NOSPACE] = true,
}


-------------------------------------
--      Namespace Declaration      --
-------------------------------------

MountMeEzDismount = MountMe:NewModule("EZDismount", "AceEvent-2.0", "AceDebug-2.0")
MountMe:RegisterDefaults("EZDismount", "profile", {
	taxi = true,
	deshift = true,
})
MountMeEzDismount.db = MountMe:AcquireDBNamespace("EZDismount")
MountMeEzDismount.consoleCmd = L["dismount"]
MountMeEzDismount.consoleOptions = {
	type = "group",
	name = L["Dismount"],
	desc = L["Options for Dismounting."],
	args = {
		[L["deshift"]] = {
			type = "toggle",
			name = L["Deshift on error"],
			desc = L["Clears shapeshifts on \"Can't do that when shapeshifted\" errors."],
			get = function() return MountMeEzDismount.db.profile.deshift end,
			set = function(v) MountMeEzDismount.db.profile.deshift = v end,
			hidden = myclass ~= "DRUID" and myclass ~= "SHAMAN",
		},
	}
}


---------------------------
--      Ace Methods      --
---------------------------

function MountMeEzDismount:OnEnable()
--~ 	self:RegisterEvent("TAXIMAP_OPENED")
	self:RegisterEvent("UI_ERROR_MESSAGE")
end


------------------------------
--			Event handling			--
------------------------------

function MountMeEzDismount:UI_ERROR_MESSAGE(msg)
	if UnitOnTaxi("player") then return
	elseif shifterrors[msg] and self.db.profile.deshift then return self:TriggerEvent("MountMe_Deshift") end
end


--~ function MountMeEzDismount:TAXIMAP_OPENED()
--~ 	if self.db.profile.taxi then Dismount() end
--~ end




