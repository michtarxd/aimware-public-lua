--[[ 
    Spectator list autohide 1.0.0 by Michtar
]]

local function GetSpectators(pTarget)
	local vecSpectators = {}

	local vecPlayers = entities.FindByClass("CCSPlayerController")
	for _, pController in pairs(vecPlayers) do
		local pPlayerPawn = pController:GetPropInt("m_hPawn") > 1 and pController:GetPropEntity("m_hPawn") or nil
		if not pPlayerPawn then goto continue end

		if pPlayerPawn:GetClass() ~= "C_CSObserverPawn" then goto continue end

		local pSpecTarget = pPlayerPawn:GetPropInt("m_hDetectParentChange") > 1 and pPlayerPawn:GetPropEntity("m_hDetectParentChange") or nil
		if not pSpecTarget then goto continue end
		
		if pSpecTarget:GetIndex() ~= pTarget:GetIndex() then goto continue end

		table.insert(vecSpectators, pSpecTarget)
		::continue::
	end

	return vecSpectators
end

local refMenu = gui.Reference("Menu")
local refTab = gui.Reference("Misc", "General", "Extra")
local refOriginal = refTab:Reference("Show Spectators")
refOriginal:SetInvisible(true)

local refNewCheckbox = gui.Checkbox(refTab, "misc.showspecvisible", "Show Spectators", false)
refNewCheckbox:SetDescription("See who is spectating you.")

callbacks.Register("Draw", function()
	local bShowSpectators = false
	local pLocal = entities.GetLocalPlayer()
	if pLocal and pLocal:IsAlive() then
		local vecSpectators = GetSpectators(pLocal)
		bShowSpectators = #vecSpectators > 0
	end

	if refMenu:IsActive() then bShowSpectators = true end
	gui.SetValue("misc.showspec", refNewCheckbox:GetValue() and bShowSpectators)
end)

callbacks.Register("Unload", function ()
	refOriginal:SetInvisible(false)
end)