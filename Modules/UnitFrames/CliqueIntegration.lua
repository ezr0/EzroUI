local ADDON_NAME, ns = ...
local EzUI = ns.Addon

-- Get UnitFrames module
local UF = EzUI.UnitFrames
if not UF then
    error("EzUI: UnitFrames module not initialized! Load UnitFrames.lua first.")
end

-- Clique Integration for Unit Frames
-- This module registers EzUI unit frames with Clique for click-casting support

local isEzUI = C_AddOns.IsAddOnLoaded("nUI") or C_AddOns.IsAddOnLoaded("EzUI")

if not isEzUI then
    return -- Exit if EzUI isn't active
end

local function TryRegister()
    -- Check if Clique is active
    if not ClickCastFrames then 
        return false -- Clique not loaded yet, keep trying
    end
    
    local playerFrame = _G["EzUI_Player"]
    if playerFrame then
        local frames = {
            playerFrame, 
            _G["EzUI_Target"], 
            _G["EzUI_Focus"], 
            _G["EzUI_Pet"]
        }
        
        for _, frame in ipairs(frames) do
            if frame then
                -- Add to Clique if not already there
                ClickCastFrames[frame] = true
                
                -- Modern WoW attribute for click-cast pass-through
                if not InCombatLockdown() then
                    frame:SetAttribute("clickcast_onenter", [=[
                        local header = self:GetParent()
                        if header and header:GetAttribute("clickcast_button") then
                            header:RunAttribute("clickcast_onenter")
                        end
                    ]=])
                    
                    frame:EnableMouse(true)
                    frame:RegisterForClicks("AnyUp")
                end
            end
        end
        print("|cFF00FF00Bridge:|r EzUI & Clique linked successfully.")
        return true -- Found and fixed the frames!
    end
    return false -- Frames not spawned yet, try again.
end

-- Runs every 2 seconds, up to 10 times. Stops once TryRegister returns true.
-- This handles cases where Clique loads after EzUI or frames are created later
C_Timer.NewTicker(2, function(self)
    if TryRegister() then
        self:Cancel()
    end
end, 10)

