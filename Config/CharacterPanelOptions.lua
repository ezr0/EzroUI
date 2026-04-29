local ADDON_NAME, ns = ...
local EzroUI = ns.Addon

local function CreateCharacterPanelOptions()
    return {
        type  = "group",
        name  = "Character Panel",
        order = 5,
        args  = {
            header = {
                type  = "header",
                name  = "Character Panel Settings",
                order = 1,
            },
            enabled = {
                type  = "toggle",
                name  = "Enable Character Panel",
                desc  = "Show item level, enchants, missing enchants, sockets, and durability on the character and inspect frames. Also applies the modern dark skin.",
                width = "full",
                order = 2,
                get   = function()
                    local db = EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.qol
                    if not db then return true end
                    if db.characterPanel == nil then return true end
                    return db.characterPanel
                end,
                set   = function(_, val)
                    if not EzroUI.db or not EzroUI.db.profile then return end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.characterPanel = val
                    if EzroUI.CharacterPanel and EzroUI.CharacterPanel.Refresh then
                        EzroUI.CharacterPanel:Refresh()
                    end
                end,
            },
            positionHeader = {
                type  = "header",
                name  = "Frame Position",
                order = 10,
            },
            positionDesc = {
                type  = "description",
                name  = "Drag the Character Panel by its title bar to reposition it. The position is saved between sessions.",
                order = 11,
                width = "full",
            },
            resetPosition = {
                type  = "execute",
                name  = "Reset Position to Centre",
                desc  = "Moves the Character Panel back to the centre of the screen and clears the saved position.",
                width = "full",
                order = 12,
                func  = function()
                    if not EzroUI.db or not EzroUI.db.profile then return end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.characterPanelPos = nil
                    if CharacterFrame then
                        CharacterFrame:ClearAllPoints()
                        CharacterFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                    end
                end,
            },
            defaultsHeader = {
                type  = "header",
                name  = "Reset",
                order = 20,
            },
            restoreDefaults = {
                type  = "execute",
                name  = "Restore All Defaults",
                desc  = "Re-enables the Character Panel and resets its position to the default.",
                width = "full",
                order = 21,
                func  = function()
                    if not EzroUI.db or not EzroUI.db.profile then return end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.characterPanel    = true
                    EzroUI.db.profile.qol.characterPanelPos = nil
                    if CharacterFrame then
                        CharacterFrame:ClearAllPoints()
                        CharacterFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                    end
                    if EzroUI.CharacterPanel and EzroUI.CharacterPanel.Refresh then
                        EzroUI.CharacterPanel:Refresh()
                    end
                    -- Notify AceConfig so the enable toggle refreshes visually
                    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                    if AceConfigRegistry then
                        AceConfigRegistry:NotifyChange(ADDON_NAME)
                    end
                end,
            },
        },
    }
end

ns.CreateCharacterPanelOptions = CreateCharacterPanelOptions
