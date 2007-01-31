
local mounted, flying
local MountMe = MountMe


local f = CreateFrame("Frame")
f.name = "MountMeMountEvent"
f:SetScript("OnUpdate", function()
	local m, f = IsMounted(), IsFlying()
	if m == mounted and f == flying then return end

	if m and not mounted then MountMe:TriggerMessage("MountMe_Mounted")
	elseif not m and mounted then MountMe:TriggerMessage("MountMe_Dismounted") end

	if f and not flying then MountMe:TriggerMessage("MountMe_Flying")
	elseif not f and flying then MountMe:TriggerMessage("MountMe_Landed") end

	flying = f
	mounted = m
end)


