--[[ 
    Better Autostrafer 1.0.1 by Michtar
    Forum Link: https://aimware.net/forum/thread/176961
    Credits: https://www.unknowncheats.me/wiki/Counter_Strike_Global_Offensive:Proper_auto-strafer
]]

local BUTTONS = {
    IN_SPEED = bit.lshift(1, 16)
}

local FLAGS = {
    ONGROUND = bit.lshift(1, 0)
}

local MOVETYPE = {
    NOCLIP = 8,
    LADDER = 9,
}

local tblOriginalElements = {
    AirStrafe = gui.Reference("Misc", "Movement", "Auto Strafer", "Air Strafe"),
    CircleStrafe = gui.Reference("Misc", "Movement", "Auto Strafer", "Circle Strafe"),
    SnakeStrafe = gui.Reference("Misc", "Movement", "Auto Strafer", "Snake Strafe"),
    WASDStrafe = gui.Reference("Misc", "Movement", "Auto Strafer", "WASD Strafe"),
    StrafeMode = gui.Reference("Misc", "Movement", "Auto Strafer", "Strafe Mode"),
    StrafeLimit = gui.Reference("Misc", "Movement", "Auto Strafer", "Strafe Limit"),
}

local ui_reference = gui.Reference("Misc", "Movement", "Auto Strafer")
local ui_disable_on_shift = gui.Checkbox(ui_reference, "lua.disable_on_shift", "Disable On Shift", true)
ui_disable_on_shift:SetDescription("Disable autostrafer while shifting.")
local ui_strafermode = gui.Combobox(ui_reference, "lua.mode", "Auto Strafer Mode", "Legit (Mouse)", "Rage (Directional)")
local ui_minimum_velocity = gui.Slider(ui_reference, "lua.minimum_speed", "Minimum Velocity", 5, 0, 50)
ui_minimum_velocity:SetDescription("Disable autostrafer while below a certain speed.")

local vecPreviousLocalAngles = EulerAngles(0, 0, 0)
local function LegitStrafer(pUserCmd, vecVelocity)
    local vecLocalAngles = engine.GetViewAngles()
    vecLocalAngles.z = 0

    if (vecPreviousLocalAngles == EulerAngles(0, 0, 0)) then vecPreviousLocalAngles = vecLocalAngles end
    local vecAngleDifference = vecLocalAngles - vecPreviousLocalAngles
    if (vecPreviousLocalAngles ~= vecLocalAngles) then vecPreviousLocalAngles = vecLocalAngles end
    if vecAngleDifference.y == 0 then return end

    local flVelocityAngle = EulerAngles(0, math.deg(math.atan2(vecVelocity.y, vecVelocity.x) - math.rad(vecLocalAngles.y)),0 )
    flVelocityAngle:Normalize()

    local bForward = flVelocityAngle.y < 90 and flVelocityAngle.y > -90
    if (bForward) then
        pUserCmd:SetSideMove(vecAngleDifference.y < 0 and -1 or 1)
    else
        pUserCmd:SetSideMove(vecAngleDifference.y > 0 and -1 or 1)
    end

    pUserCmd:SetForwardMove(0)
end

local function RageStrafer(pUserCmd, vecVelocity)
    local flSpeed = vecVelocity:Length2D()
    if flSpeed < ui_minimum_velocity:GetValue() then return end

    local function CalculateDelta()
        local flAirAccelerate = client.GetConVar("sv_airaccelerate")
        local flMaxSpeed = 300

        local term = 30.0 / flAirAccelerate / flMaxSpeed * 100.0 / flSpeed
        if term < 1.0 and term > -1.0 then
            return math.acos(term)
        end

        return 0.0
    end

    local flDeltaAir = CalculateDelta()
    if not flDeltaAir then return end

    local vecLocalAngles = engine.GetViewAngles()
    vecLocalAngles.z = 0
    local flVelocityAngle = math.atan2(vecVelocity.y, vecVelocity.x) - math.rad(vecLocalAngles.y)
    local flBestAngle = math.atan2(pUserCmd:GetSideMove(), pUserCmd:GetForwardMove())
    local function DeltaAngle(first, second)
        local delta = first - second
        local res = math.fmod(delta, math.pi * 2)

        if first > second then
            if res >= math.pi then
                res = res - math.pi * 2.0
            end
        else
            if res <= -math.pi then
                res = res + math.pi * 2.0
            end
        end

        return res
    end

    local flDeltaAngle = DeltaAngle(flVelocityAngle, flBestAngle)
    local flFinalMove = flDeltaAngle < 0.0 and flVelocityAngle + flDeltaAir or flVelocityAngle - flDeltaAir

    pUserCmd:SetForwardMove(math.cos(flFinalMove))
    pUserCmd:SetSideMove(math.sin(flFinalMove))
end

callbacks.Register("CreateMove", function (pUserCmd)
    if not pUserCmd then return end
    local pLocalPawn = entities.GetLocalPlayer()

    local m_MoveType = pLocalPawn:GetPropInt("m_MoveType") 
    local m_fFlags = pLocalPawn:GetPropInt("m_fFlags") 

    if not gui.GetValue("misc.strafe.enable")
        or not pLocalPawn:IsAlive()
        or (gui.GetValue("misc.strafe.disablenade") and pLocalPawn:GetWeaponType() == 9)
        or m_MoveType == MOVETYPE.LADDER or m_MoveType == MOVETYPE.NOCLIP
        or bit.band(m_fFlags, FLAGS.ONGROUND) ~= 0 
        or (ui_disable_on_shift:GetValue() and bit.band(pUserCmd:GetButtons(), BUTTONS.IN_SPEED) ~= 0) 
    then
        vecPreviousLocalAngles = EulerAngles(0, 0, 0)
        return 
    end

    tblOriginalElements.AirStrafe:SetValue(false)
    
    local vecVelocity = pLocalPawn:GetPropVector("m_vecVelocity")
    local iStraferMode = ui_strafermode:GetValue()
    if iStraferMode == 0 then
        LegitStrafer(pUserCmd, vecVelocity)
    elseif iStraferMode == 1 then
        RageStrafer(pUserCmd, vecVelocity)
    end
end)

for _, pElement in pairs(tblOriginalElements) do pElement:SetInvisible(true) end
callbacks.Register("Unload", function() for _, pElement in pairs(tblOriginalElements) do pElement:SetInvisible(false) end end)
