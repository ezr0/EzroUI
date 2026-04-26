--[[
    EzroUI Unit Frames - Options Integration
    Provides options panel integration for the addon's configuration system
]]

local ADDON_NAME, ns = ...
local EzroUI = ns.Addon
EzroUI.PartyFrames = EzroUI.PartyFrames or {}
local UnitFrames = EzroUI.PartyFrames

-- ============================================================================
-- OPTIONS CREATION FUNCTIONS
-- ============================================================================

--[[
    Create party frame options table for EzroUI config
    @return table - AceConfig options table
]]
function ns.CreatePartyFrameOptions()
    -- Check if UnitFrames is initialized
    if UnitFrames and UnitFrames.BuildEzroUIOptions then
        return UnitFrames:BuildEzroUIOptions("party", "Party Frames", 45)
    end
    
    -- Fallback if module not ready
    return {
        type = "group",
        name = "Party Frames",
        order = 45,
        args = {
            fallback = {
                type = "description",
                name = "Party frame options are not available yet. Please reload your UI.",
                order = 1,
            },
        },
    }
end

--[[
    Create raid frame options table for EzroUI config
    @return table - AceConfig options table
]]
function ns.CreateRaidFrameOptions()
    -- Check if UnitFrames is initialized
    if UnitFrames and UnitFrames.BuildEzroUIOptions then
        return UnitFrames:BuildEzroUIOptions("raid", "Raid Frames", 46)
    end
    
    -- Fallback if module not ready
    return {
        type = "group",
        name = "Raid Frames",
        order = 46,
        args = {
            fallback = {
                type = "description",
                name = "Raid frame options are not available yet. Please reload your UI.",
                order = 1,
            },
        },
    }
end

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================

-- Create slash commands for quick access
SLASH_EZFRAMES1 = "/ezframes"
SLASH_EZFRAMES2 = "/nf"
SlashCmdList["EZFRAMES"] = function(msg)
    msg = msg:lower():trim()
    
    if msg == "party" then
        -- Open party frame options
        if Settings and Settings.OpenToCategory then
            Settings.OpenToCategory("EzroUI|Party Frames")
        elseif InterfaceOptionsFrame_OpenToCategory then
            InterfaceOptionsFrame_OpenToCategory("EzroUI")
        end
    elseif msg == "raid" then
        -- Open raid frame options
        if Settings and Settings.OpenToCategory then
            Settings.OpenToCategory("EzroUI|Raid Frames")
        elseif InterfaceOptionsFrame_OpenToCategory then
            InterfaceOptionsFrame_OpenToCategory("EzroUI")
        end
    elseif msg == "test" then
        UnitFrames:ToggleTestMode("party")
    elseif msg == "test raid" or msg == "testraid" then
        UnitFrames:ToggleTestMode("raid")
    elseif msg == "move" or msg == "movers" then
        UnitFrames:ToggleMovers()
    elseif msg == "reset party" then
        UnitFrames:ResetProfile("party")
        print("|cFF00FF00EzroUI:|r Party frame settings reset to defaults.")
    elseif msg == "reset raid" then
        UnitFrames:ResetProfile("raid")
        print("|cFF00FF00EzroUI:|r Raid frame settings reset to defaults.")
    elseif msg == "help" or msg == "" then
        print("|cFF00FF00EzroUI Party/Raid Frames Commands:|r")
        print("  /ezframes party - Open party frame options")
        print("  /ezframes raid - Open raid frame options")
        print("  /ezframes test - Toggle test mode")
        print("  /ezframes move - Toggle movers")
        print("  /ezframes reset party - Reset party settings")
        print("  /ezframes reset raid - Reset raid settings")
    else
        print("|cFF00FF00EzroUI:|r Unknown command. Use '/ezframes help' for available commands.")
            end
        end
        
-- ============================================================================
-- OPTION REGISTRATION
-- ============================================================================

--[[
    Register options with EzroUI's config system
    Called during addon initialization
]]
function UnitFrames:RegisterOptions()
    -- This would integrate with EzroUI's main config system
    -- The exact implementation depends on how EzroUI handles option registration
    
    -- For now, we expose the creation functions for the main addon to call
    if ns.RegisterOptionsCallback then
        ns.RegisterOptionsCallback("PartyFrames", ns.CreatePartyFrameOptions)
        ns.RegisterOptionsCallback("RaidFrames", ns.CreateRaidFrameOptions)
            end
        end

-- ============================================================================
-- PROFILE CALLBACKS
-- ============================================================================

--[[
    Called when profile changes
    @param newProfile string - New profile name
]]
function UnitFrames:OnProfileChanged(newProfile)
    -- Reinitialize with new profile settings
    self:SyncProfile()
    
    -- Update all frames
    self:UpdateAllFrames()
    
    -- Update layouts
    self:UpdatePartyLayout()
    self:UpdateRaidLayout()
end

--[[
    Called when profile is copied
    @param sourceProfile string - Source profile name
]]
function UnitFrames:OnProfileCopied(sourceProfile)
    self:OnProfileChanged(sourceProfile)
end

--[[
    Called when profile is reset
]]
function UnitFrames:OnProfileReset()
    -- Reset to defaults
    self:SyncProfile()
    self:UpdateAllFrames()
    self:UpdatePartyLayout()
    self:UpdateRaidLayout()
end

-- ============================================================================
-- MINIMAP BUTTON
-- ============================================================================

local minimapButton = nil

--[[
    Create minimap button for quick access
]]
function UnitFrames:CreateMinimapButton()
    if minimapButton then return end
    
    -- Check for LibDBIcon
    local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
    
    if not LDB or not LDBIcon then return end
    
    local dataObject = LDB:NewDataObject("EzroUIFrames", {
        type = "launcher",
        icon = "Interface\\AddOns\\EzroUI\\Media\\EzroUI",
        OnClick = function(self, button)
            if button == "LeftButton" then
                UnitFrames:ToggleMovers()
            elseif button == "RightButton" then
                -- Open options
                if Settings and Settings.OpenToCategory then
                    Settings.OpenToCategory("EzroUI")
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("EzroUI Frames")
            tooltip:AddLine(" ")
            tooltip:AddLine("|cFFFFFFFFLeft-click:|r Toggle movers")
            tooltip:AddLine("|cFFFFFFFFRight-click:|r Open options")
        end,
    })
    
    -- Register with LibDBIcon
    local minimapDB = {
        hide = false,
        minimapPos = 220,
        lock = false,
    }
    
    LDBIcon:Register("EzroUIFrames", dataObject, minimapDB)
    minimapButton = true
end
