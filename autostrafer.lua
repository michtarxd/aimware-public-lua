--[[ credits:
    https://www.unknowncheats.me/wiki/Counter_Strike_Global_Offensive:Proper_auto-strafer
]]

local FL_ONGROUND = bit.lshift(1, 0)
local MOVETYPE_NOCLIP = 8
local MOVETYPE_LADDER = 9

local tblOriginalElements = {
    AirStrafe = gui.Reference("Misc", "Movement", "Auto Strafer", "Air Strafe"),
    CircleStrafe = gui.Reference("Misc", "Movement", "Auto Strafer", "Circle Strafe"),
    SnakeStrafe = gui.Reference("Misc", "Movement", "Auto Strafer", "Snake Strafe"),
    WASDStrafe = gui.Reference("Misc", "Movement", "Auto Strafer", "WASD Strafe"),
    StrafeMode = gui.Reference("Misc", "Movement", "Auto Strafer", "Strafe Mode"),
    StrafeLimit = gui.Reference("Misc", "Movement", "Auto Strafer", "Strafe Limit"),
}

local ui_reference = gui.Reference("Misc", "Movement", "Auto Strafer")
local ui_strafermode = gui.Combobox(ui_reference, "lua.mode", "Auto Strafer Mode", "Legit (Mouse)", "Rage")

local vecAnglesPrevious = EulerAngles(0, 0, 0)
local function LegitStrafer(pUserCmd, vecVelocity)
    local vecAngles = engine.GetViewAngles()
    if (vecAnglesPrevious == EulerAngles(0, 0, 0)) then vecAnglesPrevious = vecAngles end
    local vecAngleDifference = vecAngles - vecAnglesPrevious
    if (vecAnglesPrevious ~= vecAngles) then vecAnglesPrevious = vecAngles end
    if vecAngleDifference.y == 0 then return end

    local flVelocityAngle = EulerAngles(0, math.deg(math.atan2(vecVelocity.y, vecVelocity.x) - math.rad(vecAngles.y)),0 )
    flVelocityAngle:Normalize()
    print(flVelocityAngle.y)

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

    if not gui.GetValue("misc.strafe.enable") or not pLocalPawn:IsAlive() or (gui.GetValue("misc.strafe.disablenade") and pLocalPawn:GetWeaponType() == 9) or m_MoveType == MOVETYPE_LADDER or m_MoveType == MOVETYPE_NOCLIP or bit.band(m_fFlags, FL_ONGROUND) ~= 0 then 
        vecAnglesPrevious = EulerAngles(0, 0, 0)
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