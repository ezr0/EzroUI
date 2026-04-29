local ADDON_NAME, ns = ...
local EzroUI = ns.Addon
local LSM = LibStub("LibSharedMedia-3.0")

local function GetViewerOptions()
    return {
        ["EssentialCooldownViewer"] = "Essential Cooldowns",
        ["UtilityCooldownViewer"] = "Utility Cooldowns",
        ["BuffIconCooldownViewer"] = "Buff Icons",
    }
end

local function CreateCastBarOptions()
    return {
        type = "group",
        name = "Cast Bars",
        order = 4,
        childGroups = "tab",
        args = {
            player = {
                type = "group",
                name = "Player",
                order = 1,
                args = {
                    header = {
                        type = "header",
                        name = "Player Cast Bar Settings",
                        order = 1,
                    },
                    enabled = {
                        type = "toggle",
                        name = "Enable Cast Bar",
                        desc = "Show a bar when casting or channeling spells",
                        width = "full",
                        order = 2,
                        get = function() return EzroUI.db.profile.castBar.enabled end,
                        set = function(_, val)
                            EzroUI.db.profile.castBar.enabled = val
                            EzroUI:UpdateCastBarLayout()
                        end,
                    },
                    testCast = {
                        type  = "execute",
                        name  = "Test Cast Bar",
                        desc  = "Show a fake cast so you can preview and tweak the bar without casting.",
                        order = 3,
                        func  = function()
                            EzroUI:ShowTestCastBar()
                        end,
                    },
                    positionHeader = {
                        type = "header",
                        name = "Position & Size",
                        order = 10,
                    },
                    attachTo = {
                        type = "select",
                        name = "Attach To",
                        desc = "Which frame to attach this bar to",
                        order = 11,
                        width = "full",
                        values = function()
                            local opts = {}
                            if EzroUI.db.profile.unitFrames and EzroUI.db.profile.unitFrames.enabled then
                                opts["EzroUI_Player"] = "Player Frame (Custom)"
                            end
                            local viewerOpts = GetViewerOptions()
                            for k, v in pairs(viewerOpts) do
                                opts[k] = v
                            end
                            opts["UIParent"] = "Screen Center"
                            return opts
                        end,
                        get = function() return EzroUI.db.profile.castBar.attachTo end,
                        set = function(_, val)
                            EzroUI.db.profile.castBar.attachTo = val
                            EzroUI:UpdateCastBarLayout()
                        end,
                    },
                    anchorPoint = {
                        type = "select",
                        name = "Anchor Point",
                        desc = "Which point of the attached frame to anchor to (moves with frame when it resizes)",
                        order = 12,
                        width = "full",
                        values = {
                            ["CENTER"] = "Center",
                            ["BOTTOM"] = "Bottom",
                            ["TOP"] = "Top",
                        },
                        get = function() return EzroUI.db.profile.castBar.anchorPoint or "CENTER" end,
                        set = function(_, val)
                            EzroUI.db.profile.castBar.anchorPoint = val
                            EzroUI:UpdateCastBarLayout()
                        end,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        order = 12,
                        width = "normal",
                        min = 6, max = 100, step = 1,
                        get = function() return EzroUI.db.profile.castBar.height end,
                        set = function(_, val)
                            EzroUI.db.profile.castBar.height = val
                            EzroUI:UpdateCastBarLayout()
                        end,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        desc = "0 = automatic width based on icons",
                        order = 13,
                        width = "normal",
                        min = 0, max = 1000, step = 1,
                        get = function() return EzroUI.db.profile.castBar.width end,
                        set = function(_, val)
                            EzroUI.db.profile.castBar.width = val
                            EzroUI:UpdateCastBarLayout()
                        end,
                    },
                    offsetY = {
                        type = "range",
                        name = "Vertical Offset",
                        desc = "Distance from the icon viewer",
                        order = 14,
                        width = "full",
                        min = -500, max = 500, step = 1,
                        get = function() return EzroUI.db.profile.castBar.offsetY end,
                        set = function(_, val)
                            EzroUI.db.profile.castBar.offsetY = val
                            EzroUI:UpdateCastBarLayout()
                        end,
                    },
                    offsetX = {
                        type = "range",
                        name = "Horizontal Offset",
                        desc = "Horizontal distance from the anchor point",
                        order = 15,
                        width = "full",
                        min = -500, max = 500, step = 1,
                        get = function() return EzroUI.db.profile.castBar.offsetX or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.castBar.offsetX = val
                            EzroUI:UpdateCastBarLayout()
                        end,
                    },
                    
                    appearanceHeader = {
                        type = "header",
                        name = "Appearance",
                        order = 20,
                    },
                    texture = {
                        type = "select",
                        name = "Texture",
                        order = 21,
                        width = "full",
                        values = function()
                            local hashTable = LSM:HashTable("statusbar")
                            local names = {}
                            for name, _ in pairs(hashTable) do
                                names[name] = name
                            end
                            return names
                        end,
                        get = function() 
                            local override = EzroUI.db.profile.castBar.texture
                            if override and override ~= "" then
                                return override
                            end
                            -- Return global texture name when override is nil
                            return EzroUI.db.profile.general.globalTexture or "Ez"
                        end,
                        set = function(_, val)
                            EzroUI.db.profile.castBar.texture = val
                            EzroUI:UpdateCastBarLayout()
                        end,
                    },
                    useClassColor = {
                        type = "toggle",
                        name = "Use Class Color",
                        desc = "Use your class color instead of custom color",
                        order = 22,
                        width = "normal",
                        get = function() return EzroUI.db.profile.castBar.useClassColor end,
                        set = function(_, val)
                            EzroUI.db.profile.castBar.useClassColor = val
                            EzroUI:UpdateCastBarLayout()
                        end,
                    },
                    barColor = {
                        type = "color",
                        name = "Custom Color",
                        desc = "Used when class color is disabled",
                    order = 23,
                    width = "normal",
                    hasAlpha = true,
                    get = function()
                            local c = EzroUI.db.profile.castBar.color
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 1, 0.7, 0, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzroUI.db.profile.castBar.color = { r, g, b, a }
                            EzroUI:UpdateCastBarLayout()
                        end,
                    },
                    bgColor = {
                        type = "color",
                        name = "Background Color",
                        desc = "Color of the bar background",
                        order = 24,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = EzroUI.db.profile.castBar.bgColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.1, 0.1, 0.1, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzroUI.db.profile.castBar.bgColor = { r, g, b, a }
                            EzroUI:UpdateCastBarLayout()
                        end,
                    },
                    textSize = {
                        type = "range",
                        name = "Text Size",
                        order = 25,
                        width = "normal",
                        min = 6, max = 40, step = 1,
                        get = function() return EzroUI.db.profile.castBar.textSize end,
                        set = function(_, val)
                            EzroUI.db.profile.castBar.textSize = val
                            EzroUI:UpdateCastBarLayout()
                        end,
                    },
                    textPositionHeader = {
                        type = "header",
                        name = "Text Position",
                        order = 25.1,
                    },
                    nameOffsetX = {
                        type = "range",
                        name = "Name Text Offset X",
                        order = 25.2,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzroUI.db.profile.castBar.nameOffsetX or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.castBar.nameOffsetX = val
                            EzroUI:UpdateCastBarLayout()
                        end,
                    },
                    nameOffsetY = {
                        type = "range",
                        name = "Name Text Offset Y",
                        order = 25.3,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzroUI.db.profile.castBar.nameOffsetY or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.castBar.nameOffsetY = val
                            EzroUI:UpdateCastBarLayout()
                        end,
                    },
                    timeOffsetX = {
                        type = "range",
                        name = "Time Text Offset X",
                        order = 25.4,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzroUI.db.profile.castBar.timeOffsetX or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.castBar.timeOffsetX = val
                            EzroUI:UpdateCastBarLayout()
                        end,
                    },
                    timeOffsetY = {
                        type = "range",
                        name = "Time Text Offset Y",
                        order = 25.5,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzroUI.db.profile.castBar.timeOffsetY or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.castBar.timeOffsetY = val
                            EzroUI:UpdateCastBarLayout()
                        end,
                    },
                    showTimeText = {
                        type = "toggle",
                        name = "Show Time Text",
                        desc = "Show the remaining cast time on the cast bar",
                        order = 26,
                        width = "normal",
                        get = function() return EzroUI.db.profile.castBar.showTimeText ~= false end,
                        set = function(_, val)
                            EzroUI.db.profile.castBar.showTimeText = val
                            EzroUI:UpdateCastBarLayout()
                        end,
                    },
                    showIcon = {
                        type = "toggle",
                        name = "Show Cast Icon",
                        desc = "Hide the spell icon if you prefer a bar-only look",
                        order = 27,
                        width = "normal",
                        get = function() return EzroUI.db.profile.castBar.showIcon ~= false end,
                        set = function(_, val)
                            EzroUI.db.profile.castBar.showIcon = val
                            EzroUI:UpdateCastBarLayout()
                        end,
                    },
                    empoweredHeader = {
                        type = "header",
                        name = "Empowered Cast Settings",
                        order = 28,
                    },
                    showEmpoweredTicks = {
                        type = "toggle",
                        name = "Show Empowered Cast Ticks",
                        desc = "Show tick marks on empowered casts to indicate stage boundaries",
                        order = 29,
                        width = "normal",
                        get = function() 
                            local val = EzroUI.db.profile.castBar.showEmpoweredTicks
                            return val ~= false  -- Default to true if nil
                        end,
                        set = function(_, val)
                            EzroUI.db.profile.castBar.showEmpoweredTicks = val
                            -- Reinitialize empowered stages if currently showing an empowered cast
                            if EzroUI.castBar and EzroUI.castBar.isEmpowered and EzroUI.castBar.numStages and EzroUI.castBar.numStages > 0 then
                                if EzroUI.CastBars and EzroUI.CastBars.InitializeEmpoweredStages then
                                    -- Force reinitialize to apply the setting change
                                    C_Timer.After(0.01, function()
                                        if EzroUI.castBar and EzroUI.castBar.isEmpowered then
                                            EzroUI.CastBars:InitializeEmpoweredStages(EzroUI.castBar)
                                        end
                                    end)
                                end
                            end
                        end,
                    },
                    showEmpoweredStageColors = {
                        type = "toggle",
                        name = "Show Empowered Stage Colors",
                        desc = "Show colored backgrounds and foregrounds for each stage. Disable to only show ticks.",
                        order = 29.5,
                        width = "normal",
                        get = function() 
                            local val = EzroUI.db.profile.castBar.showEmpoweredStageColors
                            return val ~= false  -- Default to true if nil
                        end,
                        set = function(_, val)
                            EzroUI.db.profile.castBar.showEmpoweredStageColors = val
                            -- Reinitialize empowered stages if currently showing an empowered cast
                            if EzroUI.castBar and EzroUI.castBar.isEmpowered and EzroUI.castBar.numStages and EzroUI.castBar.numStages > 0 then
                                if EzroUI.CastBars and EzroUI.CastBars.InitializeEmpoweredStages then
                                    -- Force reinitialize to apply the setting change
                                    C_Timer.After(0.01, function()
                                        if EzroUI.castBar and EzroUI.castBar.isEmpowered then
                                            EzroUI.CastBars:InitializeEmpoweredStages(EzroUI.castBar)
                                        end
                                    end)
                                end
                            end
                        end,
                    },
                    empoweredStage1Color = {
                        type = "color",
                        name = "Stage 1 Color",
                        desc = "Background and foreground color for stage 1 of empowered casts",
                        order = 30,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = EzroUI.db.profile.castBar.empoweredStageColors and EzroUI.db.profile.castBar.empoweredStageColors[1]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.3, 0.75, 1, 1
                        end,
                        set = function(_, r, g, b, a)
                            if not EzroUI.db.profile.castBar.empoweredStageColors then
                                EzroUI.db.profile.castBar.empoweredStageColors = {}
                            end
                            EzroUI.db.profile.castBar.empoweredStageColors[1] = { r, g, b, a or 1 }
                        end,
                    },
                    empoweredStage2Color = {
                        type = "color",
                        name = "Stage 2 Color",
                        desc = "Background and foreground color for stage 2 of empowered casts",
                        order = 31,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = EzroUI.db.profile.castBar.empoweredStageColors and EzroUI.db.profile.castBar.empoweredStageColors[2]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.4, 1, 0.4, 1
                        end,
                        set = function(_, r, g, b, a)
                            if not EzroUI.db.profile.castBar.empoweredStageColors then
                                EzroUI.db.profile.castBar.empoweredStageColors = {}
                            end
                            EzroUI.db.profile.castBar.empoweredStageColors[2] = { r, g, b, a or 1 }
                        end,
                    },
                    empoweredStage3Color = {
                        type = "color",
                        name = "Stage 3 Color",
                        desc = "Background and foreground color for stage 3 of empowered casts",
                        order = 32,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = EzroUI.db.profile.castBar.empoweredStageColors and EzroUI.db.profile.castBar.empoweredStageColors[3]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 1, 0.85, 0, 1
                        end,
                        set = function(_, r, g, b, a)
                            if not EzroUI.db.profile.castBar.empoweredStageColors then
                                EzroUI.db.profile.castBar.empoweredStageColors = {}
                            end
                            EzroUI.db.profile.castBar.empoweredStageColors[3] = { r, g, b, a or 1 }
                        end,
                    },
                    empoweredStage4Color = {
                        type = "color",
                        name = "Stage 4 Color",
                        desc = "Background and foreground color for stage 4 of empowered casts",
                        order = 33,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = EzroUI.db.profile.castBar.empoweredStageColors and EzroUI.db.profile.castBar.empoweredStageColors[4]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 1, 0.5, 0, 1
                        end,
                        set = function(_, r, g, b, a)
                            if not EzroUI.db.profile.castBar.empoweredStageColors then
                                EzroUI.db.profile.castBar.empoweredStageColors = {}
                            end
                            EzroUI.db.profile.castBar.empoweredStageColors[4] = { r, g, b, a or 1 }
                        end,
                    },
                    empoweredStage5Color = {
                        type = "color",
                        name = "Stage 5 Color",
                        desc = "Background and foreground color for stage 5 of empowered casts",
                        order = 34,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = EzroUI.db.profile.castBar.empoweredStageColors and EzroUI.db.profile.castBar.empoweredStageColors[5]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 1, 0.2, 0.2, 1
                        end,
                        set = function(_, r, g, b, a)
                            if not EzroUI.db.profile.castBar.empoweredStageColors then
                                EzroUI.db.profile.castBar.empoweredStageColors = {}
                            end
                            EzroUI.db.profile.castBar.empoweredStageColors[5] = { r, g, b, a or 1 }
                        end,
                    },
                },
            },
            target = {
                type = "group",
                name = "Target",
                order = 2,
                args = {
                    header = {
                        type = "header",
                        name = "Target Cast Bar Settings",
                        order = 1,
                    },
                    enabled = {
                        type = "toggle",
                        name = "Enable Target Cast Bar",
                        desc = "Show a bar when your target is casting or channeling spells",
                        width = "full",
                        order = 2,
                        get = function() return EzroUI.db.profile.targetCastBar.enabled end,
                        set = function(_, val)
                            EzroUI.db.profile.targetCastBar.enabled = val
                            EzroUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    testCast = {
                        type  = "execute",
                        name  = "Test Target Cast Bar",
                        desc  = "Show a fake cast so you can preview and tweak the bar without a target casting. Unit Must Be active to test.",
                        order = 3,
                        func  = function()
                            EzroUI:ShowTestTargetCastBar()
                        end,
                    },
                    positionHeader = {
                        type = "header",
                        name = "Position & Size",
                        order = 10,
                    },
                    attachTo = {
                        type = "select",
                        name = "Attach To",
                        desc = "Which frame to attach this bar to",
                        order = 11,
                        width = "full",
                        values = function()
                            local opts = {}
                            if EzroUI.db.profile.unitFrames and EzroUI.db.profile.unitFrames.enabled then
                                opts["EzroUI_Target"] = "Target Frame (Custom)"
                            end
                            local viewerOpts = GetViewerOptions()
                            for k, v in pairs(viewerOpts) do
                                opts[k] = v
                            end
                            opts["TargetFrame"] = "Default Target Frame"
                            opts["UIParent"] = "Screen Center"
                            return opts
                        end,
                        get = function() return EzroUI.db.profile.targetCastBar.attachTo end,
                        set = function(_, val)
                            EzroUI.db.profile.targetCastBar.attachTo = val
                            EzroUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    anchorPoint = {
                        type = "select",
                        name = "Anchor Point",
                        desc = "Which point of the attached frame to anchor to (moves with frame when it resizes)",
                        order = 12,
                        width = "full",
                        values = {
                            ["CENTER"] = "Center",
                            ["BOTTOM"] = "Bottom",
                            ["TOP"] = "Top",
                        },
                        get = function() return EzroUI.db.profile.targetCastBar.anchorPoint or "CENTER" end,
                        set = function(_, val)
                            EzroUI.db.profile.targetCastBar.anchorPoint = val
                            EzroUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        order = 12,
                        width = "normal",
                        min = 6, max = 40, step = 1,
                        get = function() return EzroUI.db.profile.targetCastBar.height end,
                        set = function(_, val)
                            EzroUI.db.profile.targetCastBar.height = val
                            EzroUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        desc = "0 = automatic width based on anchor",
                        order = 13,
                        width = "normal",
                        min = 0, max = 1000, step = 1,
                        get = function() return EzroUI.db.profile.targetCastBar.width end,
                        set = function(_, val)
                            EzroUI.db.profile.targetCastBar.width = val
                            EzroUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    offsetY = {
                        type = "range",
                        name = "Vertical Offset",
                        desc = "Distance from the anchor frame",
                        order = 14,
                        width = "full",
                        min = -500, max = 500, step = 1,
                        get = function() return EzroUI.db.profile.targetCastBar.offsetY end,
                        set = function(_, val)
                            EzroUI.db.profile.targetCastBar.offsetY = val
                            EzroUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    offsetX = {
                        type = "range",
                        name = "Horizontal Offset",
                        desc = "Horizontal distance from the anchor point",
                        order = 15,
                        width = "full",
                        min = -500, max = 500, step = 1,
                        get = function() return EzroUI.db.profile.targetCastBar.offsetX or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.targetCastBar.offsetX = val
                            EzroUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    
                    appearanceHeader = {
                        type = "header",
                        name = "Appearance",
                        order = 20,
                    },
                    texture = {
                        type = "select",
                        name = "Bar Texture",
                        order = 21,
                        width = "full",
                        values = function()
                            local hashTable = LSM:HashTable("statusbar")
                            local names = {}
                            for name, _ in pairs(hashTable) do
                                names[name] = name
                            end
                            return names
                        end,
                        get = function() 
                            local override = EzroUI.db.profile.targetCastBar.texture
                            if override and override ~= "" then
                                return override
                            end
                            -- Return global texture name when override is nil
                            return EzroUI.db.profile.general.globalTexture or "Ez"
                        end,
                        set = function(_, val)
                            EzroUI.db.profile.targetCastBar.texture = val
                            EzroUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    barColor = {
                        type = "color",
                        name = "Interruptible Color",
                        desc = "Color when the cast can be interrupted",
                        order = 22,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = EzroUI.db.profile.targetCastBar.interruptibleColor or EzroUI.db.profile.targetCastBar.color
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 1, 0, 0, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzroUI.db.profile.targetCastBar.interruptibleColor = { r, g, b, a }
                            -- keep base color in sync for legacy fallback
                            EzroUI.db.profile.targetCastBar.color = { r, g, b, a }
                            EzroUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    nonInterruptibleColor = {
                        type = "color",
                        name = "Non-Interruptible Color",
                        desc = "Color when the cast cannot be interrupted",
                        order = 23,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = EzroUI.db.profile.targetCastBar.nonInterruptibleColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.6, 0.6, 0.6, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzroUI.db.profile.targetCastBar.nonInterruptibleColor = { r, g, b, a }
                            EzroUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    interruptedColor = {
                        type = "color",
                        name = "Interrupted Color",
                        desc = "Color briefly used when the cast is interrupted",
                        order = 24,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = EzroUI.db.profile.targetCastBar.interruptedColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.8, 0.2, 0.2, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzroUI.db.profile.targetCastBar.interruptedColor = { r, g, b, a }
                            EzroUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    bgColor = {
                        type = "color",
                        name = "Background Color",
                        desc = "Color of the bar background",
                        order = 25,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = EzroUI.db.profile.targetCastBar.bgColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.1, 0.1, 0.1, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzroUI.db.profile.targetCastBar.bgColor = { r, g, b, a }
                            EzroUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    textSize = {
                        type = "range",
                        name = "Text Size",
                        order = 26,
                        width = "normal",
                        min = 6, max = 40, step = 1,
                        get = function() return EzroUI.db.profile.targetCastBar.textSize end,
                        set = function(_, val)
                            EzroUI.db.profile.targetCastBar.textSize = val
                            EzroUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    textPositionHeader = {
                        type = "header",
                        name = "Text Position",
                        order = 26.1,
                    },
                    nameOffsetX = {
                        type = "range",
                        name = "Name Text Offset X",
                        order = 26.2,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzroUI.db.profile.targetCastBar.nameOffsetX or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.targetCastBar.nameOffsetX = val
                            EzroUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    nameOffsetY = {
                        type = "range",
                        name = "Name Text Offset Y",
                        order = 26.3,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzroUI.db.profile.targetCastBar.nameOffsetY or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.targetCastBar.nameOffsetY = val
                            EzroUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    timeOffsetX = {
                        type = "range",
                        name = "Time Text Offset X",
                        order = 26.4,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzroUI.db.profile.targetCastBar.timeOffsetX or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.targetCastBar.timeOffsetX = val
                            EzroUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    timeOffsetY = {
                        type = "range",
                        name = "Time Text Offset Y",
                        order = 26.5,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzroUI.db.profile.targetCastBar.timeOffsetY or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.targetCastBar.timeOffsetY = val
                            EzroUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    showTimeText = {
                        type = "toggle",
                        name = "Show Time Text",
                        desc = "Show the remaining cast time on the cast bar",
                        order = 27,
                        width = "normal",
                        get = function() return EzroUI.db.profile.targetCastBar.showTimeText ~= false end,
                        set = function(_, val)
                            EzroUI.db.profile.targetCastBar.showTimeText = val
                            EzroUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    showIcon = {
                        type = "toggle",
                        name = "Show Cast Icon",
                        desc = "Hide the spell icon if you prefer a bar-only look",
                        order = 28,
                        width = "normal",
                        get = function() return EzroUI.db.profile.targetCastBar.showIcon ~= false end,
                        set = function(_, val)
                            EzroUI.db.profile.targetCastBar.showIcon = val
                            EzroUI:UpdateTargetCastBarLayout()
                        end,
                    },
                },
            },
            focus = {
                type = "group",
                name = "Focus",
                order = 3,
                args = {
                    header = {
                        type = "header",
                        name = "Focus Cast Bar Settings",
                        order = 1,
                    },
                    enabled = {
                        type = "toggle",
                        name = "Enable Focus Cast Bar",
                        desc = "Show a bar when your focus is casting or channeling spells",
                        width = "full",
                        order = 2,
                        get = function() return EzroUI.db.profile.focusCastBar.enabled end,
                        set = function(_, val)
                            EzroUI.db.profile.focusCastBar.enabled = val
                            EzroUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    testCast = {
                        type  = "execute",
                        name  = "Test Focus Cast Bar",
                        desc  = "Show a fake cast so you can preview and tweak the bar without a focus casting. Unit Must Be active to test.",
                        order = 3,
                        func  = function()
                            EzroUI:ShowTestFocusCastBar()
                        end,
                    },
                    positionHeader = {
                        type = "header",
                        name = "Position & Size",
                        order = 10,
                    },
                    attachTo = {
                        type = "select",
                        name = "Attach To",
                        desc = "Which frame to attach this bar to",
                        order = 11,
                        width = "full",
                        values = function()
                            local opts = {}
                            if EzroUI.db.profile.unitFrames and EzroUI.db.profile.unitFrames.enabled then
                                opts["EzroUI_Focus"] = "Focus Frame (Custom)"
                            end
                            local viewerOpts = GetViewerOptions()
                            for k, v in pairs(viewerOpts) do
                                opts[k] = v
                            end
                            opts["FocusFrame"] = "Default Focus Frame"
                            opts["UIParent"] = "Screen Center"
                            return opts
                        end,
                        get = function() return EzroUI.db.profile.focusCastBar.attachTo end,
                        set = function(_, val)
                            EzroUI.db.profile.focusCastBar.attachTo = val
                            EzroUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    anchorPoint = {
                        type = "select",
                        name = "Anchor Point",
                        desc = "Which point of the attached frame to anchor to (moves with frame when it resizes)",
                        order = 12,
                        width = "full",
                        values = {
                            ["CENTER"] = "Center",
                            ["BOTTOM"] = "Bottom",
                            ["TOP"] = "Top",
                        },
                        get = function() return EzroUI.db.profile.focusCastBar.anchorPoint or "CENTER" end,
                        set = function(_, val)
                            EzroUI.db.profile.focusCastBar.anchorPoint = val
                            EzroUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        order = 12,
                        width = "normal",
                        min = 6, max = 40, step = 1,
                        get = function() return EzroUI.db.profile.focusCastBar.height end,
                        set = function(_, val)
                            EzroUI.db.profile.focusCastBar.height = val
                            EzroUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        desc = "0 = automatic width based on anchor",
                        order = 13,
                        width = "normal",
                        min = 0, max = 1000, step = 1,
                        get = function() return EzroUI.db.profile.focusCastBar.width end,
                        set = function(_, val)
                            EzroUI.db.profile.focusCastBar.width = val
                            EzroUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    offsetY = {
                        type = "range",
                        name = "Vertical Offset",
                        desc = "Distance from the anchor frame",
                        order = 14,
                        width = "full",
                        min = -500, max = 500, step = 1,
                        get = function() return EzroUI.db.profile.focusCastBar.offsetY end,
                        set = function(_, val)
                            EzroUI.db.profile.focusCastBar.offsetY = val
                            EzroUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    offsetX = {
                        type = "range",
                        name = "Horizontal Offset",
                        desc = "Horizontal distance from the anchor point",
                        order = 15,
                        width = "full",
                        min = -500, max = 500, step = 1,
                        get = function() return EzroUI.db.profile.focusCastBar.offsetX or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.focusCastBar.offsetX = val
                            EzroUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    
                    appearanceHeader = {
                        type = "header",
                        name = "Appearance",
                        order = 20,
                    },
                    texture = {
                        type = "select",
                        name = "Bar Texture",
                        order = 21,
                        width = "full",
                        values = function()
                            local hashTable = LSM:HashTable("statusbar")
                            local names = {}
                            for name, _ in pairs(hashTable) do
                                names[name] = name
                            end
                            return names
                        end,
                        get = function() 
                            local override = EzroUI.db.profile.focusCastBar.texture
                            if override and override ~= "" then
                                return override
                            end
                            -- Return global texture name when override is nil
                            return EzroUI.db.profile.general.globalTexture or "Ez"
                        end,
                        set = function(_, val)
                            EzroUI.db.profile.focusCastBar.texture = val
                            EzroUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    barColor = {
                        type = "color",
                        name = "Interruptible Color",
                        desc = "Color when the cast can be interrupted",
                        order = 22,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = EzroUI.db.profile.focusCastBar.interruptibleColor or EzroUI.db.profile.focusCastBar.color
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 1, 0, 0, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzroUI.db.profile.focusCastBar.interruptibleColor = { r, g, b, a }
                            -- keep base color in sync for legacy fallback
                            EzroUI.db.profile.focusCastBar.color = { r, g, b, a }
                            EzroUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    nonInterruptibleColor = {
                        type = "color",
                        name = "Non-Interruptible Color",
                        desc = "Color when the cast cannot be interrupted",
                        order = 23,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = EzroUI.db.profile.focusCastBar.nonInterruptibleColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.6, 0.6, 0.6, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzroUI.db.profile.focusCastBar.nonInterruptibleColor = { r, g, b, a }
                            EzroUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    interruptedColor = {
                        type = "color",
                        name = "Interrupted Color",
                        desc = "Color briefly used when the cast is interrupted",
                        order = 24,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = EzroUI.db.profile.focusCastBar.interruptedColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.8, 0.2, 0.2, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzroUI.db.profile.focusCastBar.interruptedColor = { r, g, b, a }
                            EzroUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    bgColor = {
                        type = "color",
                        name = "Background Color",
                        desc = "Color of the bar background",
                        order = 25,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = EzroUI.db.profile.focusCastBar.bgColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.1, 0.1, 0.1, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzroUI.db.profile.focusCastBar.bgColor = { r, g, b, a }
                            EzroUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    textSize = {
                        type = "range",
                        name = "Text Size",
                        order = 26,
                        width = "normal",
                        min = 6, max = 40, step = 1,
                        get = function() return EzroUI.db.profile.focusCastBar.textSize end,
                        set = function(_, val)
                            EzroUI.db.profile.focusCastBar.textSize = val
                            EzroUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    textPositionHeader = {
                        type = "header",
                        name = "Text Position",
                        order = 26.1,
                    },
                    nameOffsetX = {
                        type = "range",
                        name = "Name Text Offset X",
                        order = 26.2,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzroUI.db.profile.focusCastBar.nameOffsetX or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.focusCastBar.nameOffsetX = val
                            EzroUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    nameOffsetY = {
                        type = "range",
                        name = "Name Text Offset Y",
                        order = 26.3,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzroUI.db.profile.focusCastBar.nameOffsetY or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.focusCastBar.nameOffsetY = val
                            EzroUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    timeOffsetX = {
                        type = "range",
                        name = "Time Text Offset X",
                        order = 26.4,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzroUI.db.profile.focusCastBar.timeOffsetX or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.focusCastBar.timeOffsetX = val
                            EzroUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    timeOffsetY = {
                        type = "range",
                        name = "Time Text Offset Y",
                        order = 26.5,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzroUI.db.profile.focusCastBar.timeOffsetY or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.focusCastBar.timeOffsetY = val
                            EzroUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    showTimeText = {
                        type = "toggle",
                        name = "Show Time Text",
                        desc = "Show the remaining cast time on the cast bar",
                        order = 27,
                        width = "normal",
                        get = function() return EzroUI.db.profile.focusCastBar.showTimeText ~= false end,
                        set = function(_, val)
                            EzroUI.db.profile.focusCastBar.showTimeText = val
                            EzroUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    showIcon = {
                        type = "toggle",
                        name = "Show Cast Icon",
                        desc = "Hide the spell icon if you prefer a bar-only look",
                        order = 28,
                        width = "normal",
                        get = function() return EzroUI.db.profile.focusCastBar.showIcon ~= false end,
                        set = function(_, val)
                            EzroUI.db.profile.focusCastBar.showIcon = val
                            EzroUI:UpdateFocusCastBarLayout()
                        end,
                    },
                },
            },
            boss = {
                type = "group",
                name = "Boss",
                order = 4,
                args = {
                    header = {
                        type = "header",
                        name = "Boss Cast Bar Settings",
                        order = 1,
                    },
                    enabled = {
                        type = "toggle",
                        name = "Enable Boss Cast Bars",
                        desc = "Show cast bars when boss units are casting or channeling spells",
                        width = "full",
                        order = 2,
                        get = function() return EzroUI.db.profile.bossCastBar.enabled end,
                        set = function(_, val)
                            EzroUI.db.profile.bossCastBar.enabled = val
                            EzroUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    testCast = {
                        type  = "execute",
                        name  = "Test Boss Cast Bars",
                        desc  = "Show fake casts on boss frames so you can preview and tweak the bars. Boss frames must be in preview mode.",
                        order = 3,
                        func  = function()
                            EzroUI:ShowTestBossCastBars()
                        end,
                    },
                    positionHeader = {
                        type = "header",
                        name = "Position & Size",
                        order = 10,
                    },
                    anchorPoint = {
                        type = "select",
                        name = "Anchor Point",
                        desc = "Which point of the attached frame to anchor to",
                        order = 12,
                        width = "full",
                        values = {
                            ["CENTER"] = "Center",
                            ["BOTTOM"] = "Bottom",
                            ["TOP"] = "Top",
                        },
                        get = function() return EzroUI.db.profile.bossCastBar.anchorPoint or "BOTTOM" end,
                        set = function(_, val)
                            EzroUI.db.profile.bossCastBar.anchorPoint = val
                            EzroUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        order = 13,
                        width = "normal",
                        min = 6, max = 40, step = 1,
                        get = function() return EzroUI.db.profile.bossCastBar.height end,
                        set = function(_, val)
                            EzroUI.db.profile.bossCastBar.height = val
                            EzroUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        desc = "0 = automatic width based on anchor",
                        order = 14,
                        width = "normal",
                        min = 0, max = 1000, step = 1,
                        get = function() return EzroUI.db.profile.bossCastBar.width end,
                        set = function(_, val)
                            EzroUI.db.profile.bossCastBar.width = val
                            EzroUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    offsetX = {
                        type = "range",
                        name = "Horizontal Offset",
                        order = 15,
                        width = "normal",
                        min = -200, max = 200, step = 1,
                        get = function() return EzroUI.db.profile.bossCastBar.offsetX or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.bossCastBar.offsetX = val
                            EzroUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    offsetY = {
                        type = "range",
                        name = "Vertical Offset",
                        order = 16,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzroUI.db.profile.bossCastBar.offsetY or -1 end,
                        set = function(_, val)
                            EzroUI.db.profile.bossCastBar.offsetY = val
                            EzroUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    appearanceHeader = {
                        type = "header",
                        name = "Appearance",
                        order = 20,
                    },
                    texture = {
                        type = "select",
                        name = "Bar Texture",
                        desc = "Texture used for the cast bar",
                        order = 21,
                        width = "full",
                        dialogControl = "LSM30_Statusbar",
                        values = LSM:HashTable("statusbar"),
                        get = function() return EzroUI.db.profile.bossCastBar.texture end,
                        set = function(_, val)
                            EzroUI.db.profile.bossCastBar.texture = val
                            EzroUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    interruptibleColor = {
                        type = "color",
                        name = "Interruptible Color",
                        desc = "Color used for interruptible casts",
                        order = 22,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = EzroUI.db.profile.bossCastBar.interruptibleColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.5, 0.5, 1.0, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            EzroUI.db.profile.bossCastBar.interruptibleColor = { r, g, b, a }
                            EzroUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    nonInterruptibleColor = {
                        type = "color",
                        name = "Non-Interruptible Color",
                        desc = "Color used for non-interruptible casts",
                        order = 23,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = EzroUI.db.profile.bossCastBar.nonInterruptibleColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.6, 0.6, 0.6, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            EzroUI.db.profile.bossCastBar.nonInterruptibleColor = { r, g, b, a }
                            EzroUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    interruptedColor = {
                        type = "color",
                        name = "Interrupted Color",
                        desc = "Color briefly used when the cast is interrupted",
                        order = 24,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = EzroUI.db.profile.bossCastBar.interruptedColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.8, 0.2, 0.2, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            EzroUI.db.profile.bossCastBar.interruptedColor = { r, g, b, a }
                            EzroUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    bgColor = {
                        type = "color",
                        name = "Background Color",
                        desc = "Color of the bar background",
                        order = 25,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = EzroUI.db.profile.bossCastBar.bgColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.1, 0.1, 0.1, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzroUI.db.profile.bossCastBar.bgColor = { r, g, b, a }
                            EzroUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    textPositionHeader = {
                        type = "header",
                        name = "Text Position",
                        order = 26,
                    },
                    nameOffsetX = {
                        type = "range",
                        name = "Name Text Offset X",
                        order = 26.1,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzroUI.db.profile.bossCastBar.nameOffsetX or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.bossCastBar.nameOffsetX = val
                            EzroUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    nameOffsetY = {
                        type = "range",
                        name = "Name Text Offset Y",
                        order = 26.2,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzroUI.db.profile.bossCastBar.nameOffsetY or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.bossCastBar.nameOffsetY = val
                            EzroUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    timeOffsetX = {
                        type = "range",
                        name = "Time Text Offset X",
                        order = 26.3,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzroUI.db.profile.bossCastBar.timeOffsetX or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.bossCastBar.timeOffsetX = val
                            EzroUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    timeOffsetY = {
                        type = "range",
                        name = "Time Text Offset Y",
                        order = 26.4,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzroUI.db.profile.bossCastBar.timeOffsetY or 0 end,
                        set = function(_, val)
                            EzroUI.db.profile.bossCastBar.timeOffsetY = val
                            EzroUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    showTimeText = {
                        type = "toggle",
                        name = "Show Time Text",
                        desc = "Show the remaining cast time on the cast bar",
                        order = 27,
                        width = "normal",
                        get = function() return EzroUI.db.profile.bossCastBar.showTimeText ~= false end,
                        set = function(_, val)
                            EzroUI.db.profile.bossCastBar.showTimeText = val
                            EzroUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    showIcon = {
                        type = "toggle",
                        name = "Show Cast Icon",
                        desc = "Hide the spell icon if you prefer a bar-only look",
                        order = 28,
                        width = "normal",
                        get = function() return EzroUI.db.profile.bossCastBar.showIcon ~= false end,
                        set = function(_, val)
                            EzroUI.db.profile.bossCastBar.showIcon = val
                            EzroUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                },
            },
        },
    }
end

ns.CreateCastBarOptions = CreateCastBarOptions

