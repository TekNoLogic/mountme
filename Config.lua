if IS_WRATH_BUILD == nil then IS_WRATH_BUILD = (select(4, GetBuildInfo()) >= 30000) end
if not IS_WRATH_BUILD then InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToFrame end

local MountMe = MountMe
if not MountMe then return end


local GAP = 8
local tekcheck = LibStub("tekKonfig-Checkbox")


local frame = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
frame.name = "MountMe"
frame:Hide()
frame:SetScript("OnShow", function()
	local title, subtitle = LibStub("tekKonfig-Heading").new(frame, "MountMe", "These settings allow you to choose when to swap mount speed equipment.")

	local raidswap = tekcheck.new(frame, nil, "Swap when in a raid instance", "TOPLEFT", subtitle, "BOTTOMLEFT", -2, -GAP)
	raidswap.tiptext = "Enable equipment swapping when in a raid instance."
	raidswap:SetChecked(not MountMe.db.raidsuspend)
	local checksound = raidswap:GetScript("OnClick")
	raidswap:SetScript("OnClick", function(self) checksound(self); MountMe.db.raidsuspend = not MountMe.db.raidsuspend end)

	local pvpswap = tekcheck.new(frame, nil, "Swap when PvP flagged", "TOPLEFT", raidswap, "BOTTOMLEFT", 0, -GAP)
	pvpswap.tiptext = "Enable equipment swapping when PvP flagged."
	pvpswap:SetChecked(not MountMe.db.PvPsuspend)

	local bgswap, bgswaplabel = tekcheck.new(frame, nil, "Swap in Battlegrounds", "TOPLEFT", pvpswap, "BOTTOMLEFT", GAP*2, -GAP)
	bgswap.tiptext = "Enable equipment swapping when in a battleground."
	bgswap:SetChecked(not MountMe.db.BGsuspend)
	if MountMe.db.PvPsuspend then
		bgswap:Disable()
		bgswaplabel:SetFontObject(GameFontDisable)
	else
		bgswap:Enable()
		bgswaplabel:SetFontObject(GameFontHighlight)
	end

	pvpswap:SetScript("OnClick", function(self)
		checksound(self)
		MountMe.db.PvPsuspend = not MountMe.db.PvPsuspend
		if MountMe.db.PvPsuspend then
			bgswap:Disable()
			bgswaplabel:SetFontObject(GameFontDisable)
		else
			bgswap:Enable()
			bgswaplabel:SetFontObject(GameFontHighlight)
		end
	end)
	bgswap:SetScript("OnClick", function(self) checksound(self); MountMe.db.BGsuspend = not MountMe.db.BGsuspend end)

	frame:SetScript("OnShow", nil)
end)

InterfaceOptions_AddCategory(frame)


LibStub("tekKonfig-AboutPanel").new("MountMe", "MountMe")


----------------------------------------
--      Quicklaunch registration      --
----------------------------------------

LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("MountMe", {
	type = "launcher",
	icon = "Interface\\Icons\\Ability_Mount_WhiteTiger",
	OnClick = function() InterfaceOptionsFrame_OpenToCategory(frame) end,
})
