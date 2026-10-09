-- =======================================================
-- SCRIPT: LASTE Wind/Temp Correction
-- VERSION: 14-06-2026 (ver. 1.1)
-- SCRIPTED BY: CaptMike
-- =======================================================
-- DESCRIPTION:
-- In an A-10 Thunderbolt II, LASTE stands for Low Altitude Safety
-- and Targeting Enhancement.
--
-- This script provides an in-cockpit weather data service 
-- for the A-10C and A-10C II modules via the F10 Radio Menu.
-- It dynamically probes localized weather and pressure data 
-- directly below the aircraft's current coordinate vector.
--
-- The output formats data matching the 4 physical CDU entry 
-- altitude tiers (00, 02, 08, 26). Wind parameters are 
-- packed into a raw 5-digit string (e.g., 08001) with no 
-- slashes, allowing direct entry into the CDU scratchpad.
-- Negative temperatures are prefixed with a minus sign (-).
--
-- Displays data via native DCS group text blocks for 5 
-- minutes, with an on-demand option to clear the layout.
-- Uses the MOOSE framework engine to handle weather tracking.
-- MOOSE Framework: https://github.com/FlightControl-Master/MOOSE
--
--
-- =======================================================
-- MISSION EDITOR SETUP INSTRUCTIONS:
-- =======================================================
-- 1. Create a trigger to load the MOOSE framework:
--    - TYPE: 4 MISSION START
--    - NAME: Load MOOSE
--    - ACTION: DO SCRIPT FILE -> Select your "Moose.lua" file.
--
-- 2. Create a delayed trigger to load this script file:
--    - TYPE: 1 ONCE
--    - NAME: Load LASTE Script
--    - CONDITION: TIME MORE (5) 
--      (This 5-second delay ensures MOOSE initializes first)
--    - ACTION: DO SCRIPT FILE -> Select this saved script file.
--
-- 3. In-Game Usage:
--    - Hop into any A-10C or A-10C II aircraft slot.
--    - Press your Communication Menu key (\) -> F10 Other.
--    - Select "LASTE" -> Opens the custom tool suite.
--    - Click "Request LASTE Winds" to view or "Clear LASTE Data" to close.
-- =======================================================

-- Print confirmation message directly to the dcs.log file upon execution
env.info("=== LASTE WIND/TEMP CORRECTION SYSTEM LOADED SUCCESSFULLY ===")

-- Global tracking table to manage F10 items natively across network slots
if not _G.LasteMultiplayerTrack then
    _G.LasteMultiplayerTrack = {
        Menus = {}
    }
end

-- Helper function to fetch and format magnetic variation via MOOSE
-- UTILS.GetMagneticDeclination() returns degrees (positive=East, negative=West)
local function GetMagneticVariationString()
    local ok, magVarDeg = pcall(function()
        return UTILS.GetMagneticDeclination()
    end)

    if not ok or magVarDeg == nil then return "N/A" end

    local sign = magVarDeg >= 0 and "+" or "-"
    return string.format("%s%.1f deg", sign, math.abs(magVarDeg))
end

-- Function to fetch and display weather safely using native Group environment
local function ShowLasteToGroup(GroupName)
    local dcsGroup = Group.getByName(GroupName)
    
    if dcsGroup and dcsGroup:isExist() then
        local dcsUnits = dcsGroup:getUnits()
        local dcsUnit = dcsUnits[1]
        
        if dcsUnit and dcsUnit:isExist() and dcsUnit:getLife() > 0 then
            local unitPos = dcsUnit:getPosition().p
            local PlayerPos = COORDINATE:NewFromVec3(unitPos)
            
            -- The 5 valid distinct physical CDU entry tiers
            local AltitudesFeet = {0, 1000, 2000, 8000, 26000}
            
            -- Fetch local sea-level barometric pressure (QNH) via native DCS atmosphere engine
            local sampleCoord = { x = unitPos.x, y = 0, z = unitPos.z }
            local _, rawPressurePascal = atmosphere.getTemperatureAndPressure(sampleCoord)
            
            -- Convert Pascals to inches of Mercury (inHg)
            local qnhInHg = rawPressurePascal * 0.000295300

            -- Fetch magnetic variation via MOOSE UTILS (map-wide constant)
            local magVarStr = GetMagneticVariationString()
            
            -- Clean, bold header style
            local Message = "===========================================\n"
            Message = Message .. "       LASTE WIND/TEMP CORRECTION DATA       \n"
            Message = Message .. "===========================================\n"
            Message = Message .. string.format("Location: %s\n", PlayerPos:ToStringMGRS())
            Message = Message .. string.format("Local Magnetic Variation: %s\n", magVarStr)
            Message = Message .. string.format("Current Ground QNH: A%.2f\n\n", qnhInHg)
            
            -- Master-aligned headers calibrated to baseline tracking
            Message = Message .. "ALT LAYER          ALT          WIND             TEMP\n"
            Message = Message .. "---------------------------------------------------------\n"
            
            -- Loop through altitudes, extract weather, and format
            for _, AltFeet in ipairs(AltitudesFeet) do
                local AltMeters = AltFeet * 0.3048
                local WindDir, WindSpeedms = PlayerPos:GetWind(AltMeters)
                local TempC = math.floor(PlayerPos:GetTemperature(AltMeters))
                local WindKnots = math.floor(WindSpeedms * 1.94384)
                local WindHeading = math.floor(WindDir)
                
                -- Format temperature for the CDU with consistent fixed-width alignment
                -- Positive temps padded to 3 chars (e.g. " 20"), negatives keep minus sign (e.g. "-32")
                local TempStr
                if TempC < 0 then
                    TempStr = string.format("-%d", math.abs(TempC))
                else
                    TempStr = string.format("%3d", TempC)
                end
                
                -- Format Wind Data string WITHOUT the slash (e.g., 08001)
                local WindString = string.format("%03d%02d", WindHeading, WindKnots)
                
                -- Calibrated space layouts tailored to offset proportional text drift perfectly
                if AltFeet == 0 then
                    Message = Message .. string.format("0000 ft                00              %s             %s\n", WindString, TempStr)
                elseif AltFeet == 1000 then
                    Message = Message .. string.format("1000 ft                01              %s             %s\n", WindString, TempStr)
                elseif AltFeet == 2000 then
                    Message = Message .. string.format("2000 ft                02              %s             %s\n", WindString, TempStr)
                elseif AltFeet == 8000 then
                    Message = Message .. string.format("8000 ft                08              %s             %s\n", WindString, TempStr)
                elseif AltFeet == 26000 then
                    Message = Message .. string.format("26000 ft              26              %s             %s\n", WindString, TempStr)
                end
            end
            
            Message = Message .. "---------------------------------------------------------\n\n"
            Message = Message .. "=== MANUAL DATA ENTRY STEPS ===\n"
            Message = Message .. "1. Turn Altimeter Pressure knob to match Ground QNH.\n"
            Message = Message .. "2. Press [SYS] on CDU -> OSB 06 [LASTE] -> OSB 07 [WIND].\n"
            Message = Message .. "3. Select/Create Altitude Layer First:\n"
            Message = Message .. "   Type ALT value into scratchpad -> Press target ALT OSB.\n"
            Message = Message .. "4. Enter Layer Editing Mode:\n"
            Message = Message .. "   Press OSB 07 [WNDEDIT] to open data fields for that altitude.\n"
            Message = Message .. "5. Input Target Data:\n"
            Message = Message .. "   Type Wind Entry (e.g. 08001) -> Press OSB 02 [WIND].\n"
            Message = Message .. "   Type Temp Entry (e.g. 19 or -32) -> Press OSB 03 [TEMP].\n"
            Message = Message .. "6. Press [WP] on the UFC to return to Steerpoint page."
            
            local groupID = dcsGroup:getID()
            trigger.action.outTextForGroup(groupID, "", 1, true)
            trigger.action.outTextForGroup(groupID, Message, 300, true)
        end
    end
end

-- Function called by the F10 menu item to clear the display instantly
local function ClearLasteDisplay(GroupName)
    local dcsGroup = Group.getByName(GroupName)
    if dcsGroup then
        local groupID = dcsGroup:getID()
        trigger.action.outTextForGroup(groupID, "", 1, true)
    end
end

-- Dedicated Multiplayer Safe Loop Scheduler Engine
local LastePlayerFilter = SET_CLIENT:New():FilterCoalitions("blue"):FilterStart()

SCHEDULER:New(nil, function()
    -- Scan all active blue client slots via MOOSE tracking filters
    LastePlayerFilter:ForEachClient(function(ClientUnit)
        if ClientUnit and ClientUnit:IsAlive() then
            local airframeType = ClientUnit:GetTypeName()
            
            if airframeType == "A-10C" or airframeType == "A-10C_2" then
                local ClientGroup = ClientUnit:GetGroup()
                
                if ClientGroup and ClientGroup:IsAlive() then
                    local groupName = ClientGroup:GetName()
                    local dcsGroup = Group.getByName(groupName)
                    
                    if dcsGroup then
                        local groupID = dcsGroup:getID()
                        
                        -- If this group ID doesn't have an active F10 menu record, construct it natively
                        if not _G.LasteMultiplayerTrack.Menus[groupID] then
                            -- Insert menus directly into the DCS mission commands network array passing the raw GroupName string
                            local rootMenu = missionCommands.addSubMenuForGroup(groupID, "LASTE")
                            missionCommands.addCommandForGroup(groupID, "Request LASTE Winds", rootMenu, ShowLasteToGroup, groupName)
                            missionCommands.addCommandForGroup(groupID, "Clear LASTE Data", rootMenu, ClearLasteDisplay, groupName)                                                      
                            _G.LasteMultiplayerTrack.Menus[groupID] = rootMenu
                        end
                    end
                end
            end
        end
    end)
end, {}, 1, 2)
