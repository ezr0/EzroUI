local ADDON_NAME, ns = ...
local EzroUI = ns.Addon

local function CreateQOLOptions()
    return {
        type = "group",
        name = "QoL",
        order = 4,
        args = {
            header = {
                type = "header",
                name = "Quality of Life",
                order = 1,
            },
            characterPanel = {
                type = "toggle",
                name = "Character Panel Enhancements",
                desc = "Show item level, enchants, missing enchants, sockets, and durability on character and inspect frames.",
                width = "full",
                order = 1.5,
                get = function()
                    local db = EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.qol
                    if not db then
                        return true
                    end
                    if db.characterPanel == nil then
                        return true
                    end
                    return db.characterPanel
                end,
                set = function(_, val)
                    if not EzroUI.db or not EzroUI.db.profile then
                        return
                    end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.characterPanel = val
                    if EzroUI.CharacterPanel and EzroUI.CharacterPanel.Refresh then
                        EzroUI.CharacterPanel:Refresh()
                    end
                end,
            },
            hideBagsBar = {
                type = "toggle",
                name = "Hide Bags Bar",
                desc = "Hide the default Bags Bar frame.",
                width = "full",
                order = 2,
                get = function()
                    local db = EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.qol
                    return db and db.hideBagsBar or false
                end,
                set = function(_, val)
                    if not EzroUI.db or not EzroUI.db.profile then
                        return
                    end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.hideBagsBar = val
                    if EzroUI.QOL and EzroUI.QOL.Refresh then
                        EzroUI.QOL:Refresh()
                    end
                end,
            },
            tooltipIDs = {
                type = "toggle",
                name = "Show Tooltip IDs",
                desc = "Show spell, item, unit, quest, and other IDs in tooltips.",
                width = "full",
                order = 3,
                get = function()
                    local db = EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.qol
                    return db and db.tooltipIDs or false
                end,
                set = function(_, val)
                    if not EzroUI.db or not EzroUI.db.profile then
                        return
                    end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.tooltipIDs = val
                    if EzroUI.QOL and EzroUI.QOL.Refresh then
                        EzroUI.QOL:Refresh()
                    end
                end,
            },
            microMenuSkinning = {
                type = "toggle",
                name = "Micro Menu Skinning",
                desc = "Skin the Micro Menu buttons. Disable to keep Blizzard styling (requires reload to fully revert).",
                width = "full",
                order = 4,
                get = function()
                    local db = EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.qol
                    if not db then
                        return true
                    end
                    if db.microMenuSkinning == nil then
                        return true
                    end
                    return db.microMenuSkinning
                end,
                set = function(_, val)
                    if not EzroUI.db or not EzroUI.db.profile then
                        return
                    end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.microMenuSkinning = val
                    if val and EzroUI.StyleMicroButtons then
                        EzroUI:StyleMicroButtons()
                    end
                end,
            },
            automationHeader = {
                type = "header",
                name = "Automation",
                order = 5,
            },
            autoRepair = {
                type = "select",
                name = "Auto Repair",
                desc = "Automatically repair gear when visiting a merchant.",
                width = "full",
                order = 5.1,
                values = {
                    off = "Off",
                    personal = "Personal",
                    guildFirst = "Guild Bank First",
                },
                get = function()
                    local db = EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.qol
                    return db and db.autoRepair or "off"
                end,
                set = function(_, val)
                    if not EzroUI.db or not EzroUI.db.profile then
                        return
                    end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.autoRepair = val
                end,
            },
            sellJunk = {
                type = "toggle",
                name = "Sell Grey Items",
                desc = "Automatically sell poor-quality items when visiting a merchant.",
                width = "full",
                order = 5.2,
                get = function()
                    local db = EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.qol
                    return db and db.sellJunk or false
                end,
                set = function(_, val)
                    if not EzroUI.db or not EzroUI.db.profile then
                        return
                    end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.sellJunk = val
                end,
            },
            autoInsertKey = {
                type = "toggle",
                name = "Auto Insert M+ Keys",
                desc = "Automatically insert a keystone when the M+ window opens.",
                width = "full",
                order = 5.3,
                get = function()
                    local db = EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.qol
                    return db and db.autoInsertKey or false
                end,
                set = function(_, val)
                    if not EzroUI.db or not EzroUI.db.profile then
                        return
                    end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.autoInsertKey = val
                end,
            },
            autoAcceptInvites = {
                type = "toggle",
                name = "Auto Accept Invites (Guild/Friends)",
                desc = "Automatically accept party invites from guild members or friends.",
                width = "full",
                order = 5.4,
                get = function()
                    local db = EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.qol
                    return db and db.autoAcceptInvites or false
                end,
                set = function(_, val)
                    if not EzroUI.db or not EzroUI.db.profile then
                        return
                    end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.autoAcceptInvites = val
                end,
            },
            fastAutoLoot = {
                type = "toggle",
                name = "Faster Auto Loot",
                desc = "Instantly loot all items and fix stuck loot.",
                width = "full",
                order = 5.5,
                get = function()
                    local db = EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.qol
                    return db and db.fastAutoLoot or false
                end,
                set = function(_, val)
                    if not EzroUI.db or not EzroUI.db.profile then
                        return
                    end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.fastAutoLoot = val
                end,
            },
            autoDeleteConfirm = {
                type = "toggle",
                name = "Auto-Fill Delete Confirmation",
                desc = "Automatically fills in DELETE when destroying high-quality items.",
                width = "full",
                order = 5.6,
                get = function()
                    local db = EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.qol
                    return db and db.autoDeleteConfirm or false
                end,
                set = function(_, val)
                    if not EzroUI.db or not EzroUI.db.profile then
                        return
                    end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.autoDeleteConfirm = val
                end,
            },
            autoAcceptQuest = {
                type = "toggle",
                name = "Auto Accept Quests",
                desc = "Automatically accept quests from NPCs.",
                width = "full",
                order = 5.7,
                get = function()
                    local db = EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.qol
                    return db and db.autoAcceptQuest or false
                end,
                set = function(_, val)
                    if not EzroUI.db or not EzroUI.db.profile then
                        return
                    end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.autoAcceptQuest = val
                end,
            },
            autoTurnInQuest = {
                type = "toggle",
                name = "Auto Turn In Quests",
                desc = "Automatically turn in quests with a single reward choice.",
                width = "full",
                order = 5.8,
                get = function()
                    local db = EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.qol
                    return db and db.autoTurnInQuest or false
                end,
                set = function(_, val)
                    if not EzroUI.db or not EzroUI.db.profile then
                        return
                    end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.autoTurnInQuest = val
                end,
            },
            raidBuffsHeader = {
                type = "header",
                name = "Missing Raid Buffs Panel",
                order = 6,
            },
            raidBuffsEnabled = {
                type = "toggle",
                name = "Enable Missing Raid Buffs",
                width = "full",
                order = 6.1,
                get = function()
                    local db = EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.qol
                    return db and db.raidBuffs and db.raidBuffs.enabled or false
                end,
                set = function(_, val)
                    if not EzroUI.db or not EzroUI.db.profile then
                        return
                    end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.raidBuffs = EzroUI.db.profile.qol.raidBuffs or {}
                    EzroUI.db.profile.qol.raidBuffs.enabled = val
                    if EzroUI.RaidBuffs and EzroUI.RaidBuffs.ForceUpdate then
                        EzroUI.RaidBuffs:ForceUpdate()
                    end
                end,
            },
            raidBuffsGroupOnly = {
                type = "toggle",
                name = "Show Only When In Group",
                width = "full",
                order = 6.2,
                get = function()
                    local db = EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.qol
                    return db and db.raidBuffs and db.raidBuffs.showOnlyInGroup or false
                end,
                set = function(_, val)
                    if not EzroUI.db or not EzroUI.db.profile then
                        return
                    end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.raidBuffs = EzroUI.db.profile.qol.raidBuffs or {}
                    EzroUI.db.profile.qol.raidBuffs.showOnlyInGroup = val
                    if EzroUI.RaidBuffs and EzroUI.RaidBuffs.ForceUpdate then
                        EzroUI.RaidBuffs:ForceUpdate()
                    end
                end,
            },
            raidBuffsInstanceOnly = {
                type = "toggle",
                name = "Show Only In Instance",
                width = "full",
                order = 6.3,
                get = function()
                    local db = EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.qol
                    return db and db.raidBuffs and db.raidBuffs.showOnlyInInstance or false
                end,
                set = function(_, val)
                    if not EzroUI.db or not EzroUI.db.profile then
                        return
                    end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.raidBuffs = EzroUI.db.profile.qol.raidBuffs or {}
                    EzroUI.db.profile.qol.raidBuffs.showOnlyInInstance = val
                    if EzroUI.RaidBuffs and EzroUI.RaidBuffs.ForceUpdate then
                        EzroUI.RaidBuffs:ForceUpdate()
                    end
                end,
            },
            raidBuffsProviderMode = {
                type = "toggle",
                name = "Also Show Buffs You Can Provide",
                width = "full",
                order = 6.4,
                get = function()
                    local db = EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.qol
                    return db and db.raidBuffs and db.raidBuffs.providerMode or false
                end,
                set = function(_, val)
                    if not EzroUI.db or not EzroUI.db.profile then
                        return
                    end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.raidBuffs = EzroUI.db.profile.qol.raidBuffs or {}
                    EzroUI.db.profile.qol.raidBuffs.providerMode = val
                    if EzroUI.RaidBuffs and EzroUI.RaidBuffs.ForceUpdate then
                        EzroUI.RaidBuffs:ForceUpdate()
                    end
                end,
            },
            raidBuffsIconSize = {
                type = "range",
                name = "Icon Size",
                min = 20,
                max = 128,
                step = 2,
                width = "full",
                order = 6.5,
                get = function()
                    local db = EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.qol
                    return db and db.raidBuffs and db.raidBuffs.iconSize or 32
                end,
                set = function(_, val)
                    if not EzroUI.db or not EzroUI.db.profile then
                        return
                    end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.raidBuffs = EzroUI.db.profile.qol.raidBuffs or {}
                    EzroUI.db.profile.qol.raidBuffs.iconSize = val
                    if EzroUI.RaidBuffs and EzroUI.RaidBuffs.ForceUpdate then
                        EzroUI.RaidBuffs:ForceUpdate()
                    end
                end,
            },
            raidBuffsBorderColor = {
                type = "color",
                name = "Icon Border Color",
                hasAlpha = true,
                width = "full",
                order = 6.6,
                get = function()
                    local db = EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.qol
                    local color = db and db.raidBuffs and db.raidBuffs.borderColor
                    if color then
                        return color[1], color[2], color[3], color[4] or 1
                    end
                    return 0, 0, 0, 1
                end,
                set = function(_, r, g, b, a)
                    if not EzroUI.db or not EzroUI.db.profile then
                        return
                    end
                    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
                    EzroUI.db.profile.qol.raidBuffs = EzroUI.db.profile.qol.raidBuffs or {}
                    EzroUI.db.profile.qol.raidBuffs.borderColor = { r, g, b, a or 1 }
                    if EzroUI.RaidBuffs and EzroUI.RaidBuffs.ForceUpdate then
                        EzroUI.RaidBuffs:ForceUpdate()
                    end
                end,
            },
            raidBuffsPreview = {
                type = "execute",
                name = "Toggle Preview",
                width = "full",
                order = 6.7,
                func = function()
                    if EzroUI.RaidBuffs and EzroUI.RaidBuffs.TogglePreview then
                        EzroUI.RaidBuffs:TogglePreview()
                    end
                end,
            },
        },
    }
end

ns.CreateQOLOptions = CreateQOLOptions


