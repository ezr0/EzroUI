local ADDON_NAME, ns = ...
local EzroUI = ns.Addon

local function CreateTooltipOptions()
    local function GetDB()
        if not EzroUI.db or not EzroUI.db.profile then return nil end
        EzroUI.db.profile.tooltips = EzroUI.db.profile.tooltips or {}
        return EzroUI.db.profile.tooltips
    end

    local function RefreshTooltips()
        if EzroUI.Tooltips and EzroUI.Tooltips.Refresh then
            EzroUI.Tooltips:Refresh()
        end
    end

    return {
        type  = "group",
        name  = "Tooltips",
        order = 5,
        args  = {
            header = {
                type  = "header",
                name  = "Player Tooltip",
                order = 1,
            },
            enabled = {
                type  = "toggle",
                name  = "Enable",
                desc  = "Show enhanced player details in unit tooltips.",
                width = "full",
                order = 2,
                get = function()
                    local db = GetDB()
                    return db and db.enabled ~= false
                end,
                set = function(_, val)
                    local db = GetDB()
                    if db then db.enabled = val end
                    RefreshTooltips()
                end,
            },
            classColoredBorder = {
                type  = "toggle",
                name  = "Class Coloured Border",
                desc  = "Colour the tooltip border with the unit's class colour when hovering over a player.",
                width = "full",
                order = 3,
                get = function()
                    local db = GetDB()
                    return db and db.classColoredBorder ~= false
                end,
                set = function(_, val)
                    local db = GetDB()
                    if db then db.classColoredBorder = val end
                end,
            },
            hideBlizzardBorder = {
                type  = "toggle",
                name  = "Hide Blizzard Border",
                desc  = "Remove the default Blizzard tooltip border so only the class-colour border is visible.",
                width = "full",
                order = 4,
                get = function()
                    local db = GetDB()
                    return db and db.hideBlizzardBorder ~= false
                end,
                set = function(_, val)
                    local db = GetDB()
                    if db then db.hideBlizzardBorder = val end
                end,
            },
            classColorName = {
                type  = "toggle",
                name  = "Class Colour Player Name",
                desc  = "Colour the player name at the top of the tooltip in their class colour.",
                width = "full",
                order = 5,
                get = function()
                    local db = GetDB()
                    return db and db.classColorName ~= false
                end,
                set = function(_, val)
                    local db = GetDB()
                    if db then db.classColorName = val end
                end,
            },
            detailsHeader = {
                type  = "header",
                name  = "Displayed Details",
                order = 9,
            },
            showLevel = {
                type  = "toggle",
                name  = "Level, Race & Class",
                desc  = "Show the player's level, race, and class.",
                width = "full",
                order = 10,
                get = function()
                    local db = GetDB()
                    return db and db.showLevel ~= false
                end,
                set = function(_, val)
                    local db = GetDB()
                    if db then db.showLevel = val end
                end,
            },
            showGuild = {
                type  = "toggle",
                name  = "Guild Info",
                desc  = "Show guild name and rank.",
                width = "full",
                order = 11,
                get = function()
                    local db = GetDB()
                    return db and db.showGuild ~= false
                end,
                set = function(_, val)
                    local db = GetDB()
                    if db then db.showGuild = val end
                end,
            },
            showRealm = {
                type  = "toggle",
                name  = "Server / Realm",
                desc  = "Show the player's realm name.",
                width = "full",
                order = 12,
                get = function()
                    local db = GetDB()
                    return db and db.showRealm ~= false
                end,
                set = function(_, val)
                    local db = GetDB()
                    if db then db.showRealm = val end
                end,
            },
            showFaction = {
                type  = "toggle",
                name  = "Faction",
                desc  = "Show whether the player is Horde or Alliance.",
                width = "full",
                order = 12.5,
                get = function()
                    local db = GetDB()
                    return db and db.showFaction ~= false
                end,
                set = function(_, val)
                    local db = GetDB()
                    if db then db.showFaction = val end
                end,
            },
            showHealth = {
                type  = "toggle",
                name  = "Health",
                desc  = "Show current / max health with percentage.",
                width = "full",
                order = 13,
                get = function()
                    local db = GetDB()
                    return db and db.showHealth ~= false
                end,
                set = function(_, val)
                    local db = GetDB()
                    if db then db.showHealth = val end
                end,
            },
            showPower = {
                type  = "toggle",
                name  = "Resource / Power",
                desc  = "Show current / max resource (mana, energy, rage, etc.) with percentage.",
                width = "full",
                order = 14,
                get = function()
                    local db = GetDB()
                    return db and db.showPower ~= false
                end,
                set = function(_, val)
                    local db = GetDB()
                    if db then db.showPower = val end
                end,
            },
            showMythicPlus = {
                type  = "toggle",
                name  = "Mythic+ Rating",
                desc  = "Show the current season Mythic+ score. Requires the player to be in your group or otherwise visible.",
                width = "full",
                order = 15,
                get = function()
                    local db = GetDB()
                    return db and db.showMythicPlus ~= false
                end,
                set = function(_, val)
                    local db = GetDB()
                    if db then db.showMythicPlus = val end
                end,
            },
            showPvP = {
                type  = "toggle",
                name  = "PvP Rating",
                desc  = "Show the highest PvP bracket rating. Live data is available for your own character; others require an inspect.",
                width = "full",
                order = 16,
                get = function()
                    local db = GetDB()
                    return db and db.showPvP ~= false
                end,
                set = function(_, val)
                    local db = GetDB()
                    if db then db.showPvP = val end
                end,
            },
            npcHeader = {
                type  = "header",
                name  = "NPC Tooltips",
                order = 19,
            },
            enhanceNPCs = {
                type  = "toggle",
                name  = "Enhance NPC Tooltips",
                desc  = "Replace default NPC tooltips with a clean layout: name coloured by reaction, level, classification (Elite/Rare/Boss), creature type, and health bar.",
                width = "full",
                order = 20,
                get = function()
                    local db = GetDB()
                    return db and db.enhanceNPCs ~= false
                end,
                set = function(_, val)
                    local db = GetDB()
                    if db then db.enhanceNPCs = val end
                end,
            },
        },
    }
end

ns.CreateTooltipOptions = CreateTooltipOptions
