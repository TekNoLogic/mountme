
----------------------------
--      Localization      --
----------------------------

local L = {
	dismount = true,
	Dismount = true,
	["Options for Dismounting."] = true,

	dazed = true,
	["Clear when Dazed"] = true,
	["Removes Aspect of the Cheetah/Pack when Dazed."] = true,

	taxi = true,
	["Dismount at flightmaster"] = true,
	["Dismounts when the flight map is opened."] = true,

	deshift = true,
	["Deshift on error"] = true,
	["Clears shapeshifts on \"Can't do that when shapeshifted\" errors."] = true,

	dismount = true,
	["Dismount on error"] = true,
	["Dismounts on \"Can't do that when mounted\" errors."] = true,

	stand = true,
	["Stand on error"] = true,
	["Stand on \"You must be standing to do that\" errors."] = true,
}
for i,v in pairs(L) do if v == true then L[i] = i end end -- Too lazy to copy/paste right now


------------------------------
--      Are you local?      --
------------------------------

local _, myclass = UnitClass("player")
local standerrors = {
	[ERR_CANTATTACK_NOTSTANDING] = true,
	[ERR_LOOT_NOTSTANDING] = true,
	[ERR_TAXINOTSTANDING] = true,
	[SPELL_FAILED_NOT_STANDING] = true,
}
local mounterrors = {
	[ERR_ATTACK_MOUNTED] = true,
	[SPELL_FAILED_NOT_MOUNTED] = true,
	[PLAYER_LOGOUT_FAILED_ERROR] = true,
}
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
	dismount = true,
	stand = true,
	clearondaze = true,
})
MountMeEzDismount.db = MountMe:AcquireDBNamespace("EZDismount")
MountMeEzDismount.consoleCmd = L["dismount"]
MountMeEzDismount.consoleOptions = {
	type = "group",
	name = L["Dismount"],
	desc = L["Options for Dismounting."],
	args = {
		[L["taxi"]] = {
			type = "toggle",
			name = L["Dismount at flightmaster"],
			desc = L["Dismounts when the flight map is opened."],
			get = function() return MountMeEzDismount.db.profile.taxi end,
			set = function(v) MountMeEzDismount.db.profile.taxi = v end,
		},
		[L["deshift"]] = {
			type = "toggle",
			name = L["Deshift on error"],
			desc = L["Clears shapeshifts on \"Can't do that when shapeshifted\" errors."],
			get = function() return MountMeEzDismount.db.profile.deshift end,
			set = function(v) MountMeEzDismount.db.profile.deshift = v end,
			hidden = myclass ~= "DRUID" and myclass ~= "SHAMAN",
		},
		[L["dismount"]] = {
			type = "toggle",
			name = L["Dismount on error"],
			desc = L["Dismounts on \"Can't do that when mounted\" errors."],
			get = function() return MountMeEzDismount.db.profile.dismount end,
			set = function(v) MountMeEzDismount.db.profile.dismount = v end,
		},
		[L["stand"]] = {
			type = "toggle",
			name = L["Stand on error"],
			desc = L["Stand on \"You must be standing to do that\" errors."],
			get = function() return MountMeEzDismount.db.profile.stand end,
			set = function(v) MountMeEzDismount.db.profile.stand = v end,
		},
	}
}


---------------------------
--      Ace Methods      --
---------------------------

function MountMeEzDismount:OnEnable()
	self:RegisterEvent("TAXIMAP_OPENED")
	self:RegisterEvent("UI_ERROR_MESSAGE")
end


------------------------------
--			Event handling			--
------------------------------

function MountMeEzDismount:UI_ERROR_MESSAGE(msg)
	if UnitOnTaxi("player") then return
	elseif mounterrors[msg] and self.db.profile.dismount then return Dismount()
	elseif shifterrors[msg] and self.db.profile.deshift then return self:TriggerEvent("MountMe_Deshift")
	elseif standerrors[msg] and self.db.profile.stand then return SitOrStand() end
end


function MountMeEzDismount:TAXIMAP_OPENED()
	if self.db.profile.taxi then Dismount() end
end




