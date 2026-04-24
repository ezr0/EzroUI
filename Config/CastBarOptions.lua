local ADDON_NAME, ns = ...
local EzUI = ns.Addon
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
        order = 7,
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
                        get = function() return EzUI.db.profile.castBar.enabled end,
                        set = function(_, val)
                            EzUI.db.profile.castBar.enabled = val
                            EzUI:UpdateCastBarLayout()
                        end,
                    },
                    testCast = {
                        type  = "execute",
                        name  = "Test Cast Bar",
                        desc  = "Show a fake cast so you can preview and tweak the bar without casting.",
                        order = 3,
                        func  = function()
                            EzUI:ShowTestCastBar()
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
                            if EzUI.db.profile.unitFrames and EzUI.db.profile.unitFrames.enabled then
                                opts["EzUI_Player"] = "Player Frame (Custom)"
                            end
                            local viewerOpts = GetViewerOptions()
                            for k, v in pairs(viewerOpts) do
                                opts[k] = v
                            end
                            opts["UIParent"] = "Screen Center"
                            return opts
                        end,
                        get = function() return EzUI.db.profile.castBar.attachTo end,
                        set = function(_, val)
                            EzUI.db.profile.castBar.attachTo = val
                            EzUI:UpdateCastBarLayout()
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
                        get = function() return EzUI.db.profile.castBar.anchorPoint or "CENTER" end,
                        set = function(_, val)
                            EzUI.db.profile.castBar.anchorPoint = val
                            EzUI:UpdateCastBarLayout()
                        end,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        order = 12,
                        width = "normal",
                        min = 6, max = 100, step = 1,
                        get = function() return EzUI.db.profile.castBar.height end,
                        set = function(_, val)
                            EzUI.db.profile.castBar.height = val
                            EzUI:UpdateCastBarLayout()
                        end,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        desc = "0 = automatic width based on icons",
                        order = 13,
                        width = "normal",
                        min = 0, max = 1000, step = 1,
                        get = function() return EzUI.db.profile.castBar.width end,
                        set = function(_, val)
                            EzUI.db.profile.castBar.width = val
                            EzUI:UpdateCastBarLayout()
                        end,
                    },
                    offsetY = {
                        type = "range",
                        name = "Vertical Offset",
                        desc = "Distance from the icon viewer",
                        order = 14,
                        width = "full",
                        min = -500, max = 500, step = 1,
                        get = function() return EzUI.db.profile.castBar.offsetY end,
                        set = function(_, val)
                            EzUI.db.profile.castBar.offsetY = val
                            EzUI:UpdateCastBarLayout()
                        end,
                    },
                    offsetX = {
                        type = "range",
                        name = "Horizontal Offset",
                        desc = "Horizontal distance from the anchor point",
                        order = 15,
                        width = "full",
                        min = -500, max = 500, step = 1,
                        get = function() return EzUI.db.profile.castBar.offsetX or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.castBar.offsetX = val
                            EzUI:UpdateCastBarLayout()
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
                            local override = EzUI.db.profile.castBar.texture
                            if override and override ~= "" then
                                return override
                            end
                            -- Return global texture name when override is nil
                            return EzUI.db.profile.general.globalTexture or "Ez"
                        end,
                        set = function(_, val)
                            EzUI.db.profile.castBar.texture = val
                            EzUI:UpdateCastBarLayout()
                        end,
                    },
                    useClassColor = {
                        type = "toggle",
                        name = "Use Class Color",
                        desc = "Use your class color instead of custom color",
                        order = 22,
                        width = "normal",
                        get = function() return EzUI.db.profile.castBar.useClassColor end,
                        set = function(_, val)
                            EzUI.db.profile.castBar.useClassColor = val
                            EzUI:UpdateCastBarLayout()
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
                            local c = EzUI.db.profile.castBar.color
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 1, 0.7, 0, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzUI.db.profile.castBar.color = { r, g, b, a }
                            EzUI:UpdateCastBarLayout()
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
                            local c = EzUI.db.profile.castBar.bgColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.1, 0.1, 0.1, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzUI.db.profile.castBar.bgColor = { r, g, b, a }
                            EzUI:UpdateCastBarLayout()
                        end,
                    },
                    textSize = {
                        type = "range",
                        name = "Text Size",
                        order = 25,
                        width = "normal",
                        min = 6, max = 40, step = 1,
                        get = function() return EzUI.db.profile.castBar.textSize end,
                        set = function(_, val)
                            EzUI.db.profile.castBar.textSize = val
                            EzUI:UpdateCastBarLayout()
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
                        get = function() return EzUI.db.profile.castBar.nameOffsetX or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.castBar.nameOffsetX = val
                            EzUI:UpdateCastBarLayout()
                        end,
                    },
                    nameOffsetY = {
                        type = "range",
                        name = "Name Text Offset Y",
                        order = 25.3,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzUI.db.profile.castBar.nameOffsetY or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.castBar.nameOffsetY = val
                            EzUI:UpdateCastBarLayout()
                        end,
                    },
                    timeOffsetX = {
                        type = "range",
                        name = "Time Text Offset X",
                        order = 25.4,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzUI.db.profile.castBar.timeOffsetX or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.castBar.timeOffsetX = val
                            EzUI:UpdateCastBarLayout()
                        end,
                    },
                    timeOffsetY = {
                        type = "range",
                        name = "Time Text Offset Y",
                        order = 25.5,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzUI.db.profile.castBar.timeOffsetY or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.castBar.timeOffsetY = val
                            EzUI:UpdateCastBarLayout()
                        end,
                    },
                    showTimeText = {
                        type = "toggle",
                        name = "Show Time Text",
                        desc = "Show the remaining cast time on the cast bar",
                        order = 26,
                        width = "normal",
                        get = function() return EzUI.db.profile.castBar.showTimeText ~= false end,
                        set = function(_, val)
                            EzUI.db.profile.castBar.showTimeText = val
                            EzUI:UpdateCastBarLayout()
                        end,
                    },
                    showIcon = {
                        type = "toggle",
                        name = "Show Cast Icon",
                        desc = "Hide the spell icon if you prefer a bar-only look",
                        order = 27,
                        width = "normal",
                        get = function() return EzUI.db.profile.castBar.showIcon ~= false end,
                        set = function(_, val)
                            EzUI.db.profile.castBar.showIcon = val
                            EzUI:UpdateCastBarLayout()
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
                            local val = EzUI.db.profile.castBar.showEmpoweredTicks
                            return val ~= false  -- Default to true if nil
                        end,
                        set = function(_, val)
                            EzUI.db.profile.castBar.showEmpoweredTicks = val
                            -- Reinitialize empowered stages if currently showing an empowered cast
                            if EzUI.castBar and EzUI.castBar.isEmpowered and EzUI.castBar.numStages and EzUI.castBar.numStages > 0 then
                                if EzUI.CastBars and EzUI.CastBars.InitializeEmpoweredStages then
                                    -- Force reinitialize to apply the setting change
                                    C_Timer.After(0.01, function()
                                        if EzUI.castBar and EzUI.castBar.isEmpowered then
                                            EzUI.CastBars:InitializeEmpoweredStages(EzUI.castBar)
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
                            local val = EzUI.db.profile.castBar.showEmpoweredStageColors
                            return val ~= false  -- Default to true if nil
                        end,
                        set = function(_, val)
                            EzUI.db.profile.castBar.showEmpoweredStageColors = val
                            -- Reinitialize empowered stages if currently showing an empowered cast
                            if EzUI.castBar and EzUI.castBar.isEmpowered and EzUI.castBar.numStages and EzUI.castBar.numStages > 0 then
                                if EzUI.CastBars and EzUI.CastBars.InitializeEmpoweredStages then
                                    -- Force reinitialize to apply the setting change
                                    C_Timer.After(0.01, function()
                                        if EzUI.castBar and EzUI.castBar.isEmpowered then
                                            EzUI.CastBars:InitializeEmpoweredStages(EzUI.castBar)
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
                            local c = EzUI.db.profile.castBar.empoweredStageColors and EzUI.db.profile.castBar.empoweredStageColors[1]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.3, 0.75, 1, 1
                        end,
                        set = function(_, r, g, b, a)
                            if not EzUI.db.profile.castBar.empoweredStageColors then
                                EzUI.db.profile.castBar.empoweredStageColors = {}
                            end
                            EzUI.db.profile.castBar.empoweredStageColors[1] = { r, g, b, a or 1 }
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
                            local c = EzUI.db.profile.castBar.empoweredStageColors and EzUI.db.profile.castBar.empoweredStageColors[2]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.4, 1, 0.4, 1
                        end,
                        set = function(_, r, g, b, a)
                            if not EzUI.db.profile.castBar.empoweredStageColors then
                                EzUI.db.profile.castBar.empoweredStageColors = {}
                            end
                            EzUI.db.profile.castBar.empoweredStageColors[2] = { r, g, b, a or 1 }
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
                            local c = EzUI.db.profile.castBar.empoweredStageColors and EzUI.db.profile.castBar.empoweredStageColors[3]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 1, 0.85, 0, 1
                        end,
                        set = function(_, r, g, b, a)
                            if not EzUI.db.profile.castBar.empoweredStageColors then
                                EzUI.db.profile.castBar.empoweredStageColors = {}
                            end
                            EzUI.db.profile.castBar.empoweredStageColors[3] = { r, g, b, a or 1 }
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
                            local c = EzUI.db.profile.castBar.empoweredStageColors and EzUI.db.profile.castBar.empoweredStageColors[4]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 1, 0.5, 0, 1
                        end,
                        set = function(_, r, g, b, a)
                            if not EzUI.db.profile.castBar.empoweredStageColors then
                                EzUI.db.profile.castBar.empoweredStageColors = {}
                            end
                            EzUI.db.profile.castBar.empoweredStageColors[4] = { r, g, b, a or 1 }
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
                            local c = EzUI.db.profile.castBar.empoweredStageColors and EzUI.db.profile.castBar.empoweredStageColors[5]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 1, 0.2, 0.2, 1
                        end,
                        set = function(_, r, g, b, a)
                            if not EzUI.db.profile.castBar.empoweredStageColors then
                                EzUI.db.profile.castBar.empoweredStageColors = {}
                            end
                            EzUI.db.profile.castBar.empoweredStageColors[5] = { r, g, b, a or 1 }
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
                        get = function() return EzUI.db.profile.targetCastBar.enabled end,
                        set = function(_, val)
                            EzUI.db.profile.targetCastBar.enabled = val
                            EzUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    testCast = {
                        type  = "execute",
                        name  = "Test Target Cast Bar",
                        desc  = "Show a fake cast so you can preview and tweak the bar without a target casting. Unit Must Be active to test.",
                        order = 3,
                        func  = function()
                            EzUI:ShowTestTargetCastBar()
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
                            if EzUI.db.profile.unitFrames and EzUI.db.profile.unitFrames.enabled then
                                opts["EzUI_Target"] = "Target Frame (Custom)"
                            end
                            local viewerOpts = GetViewerOptions()
                            for k, v in pairs(viewerOpts) do
                                opts[k] = v
                            end
                            opts["TargetFrame"] = "Default Target Frame"
                            opts["UIParent"] = "Screen Center"
                            return opts
                        end,
                        get = function() return EzUI.db.profile.targetCastBar.attachTo end,
                        set = function(_, val)
                            EzUI.db.profile.targetCastBar.attachTo = val
                            EzUI:UpdateTargetCastBarLayout()
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
                        get = function() return EzUI.db.profile.targetCastBar.anchorPoint or "CENTER" end,
                        set = function(_, val)
                            EzUI.db.profile.targetCastBar.anchorPoint = val
                            EzUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        order = 12,
                        width = "normal",
                        min = 6, max = 40, step = 1,
                        get = function() return EzUI.db.profile.targetCastBar.height end,
                        set = function(_, val)
                            EzUI.db.profile.targetCastBar.height = val
                            EzUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        desc = "0 = automatic width based on anchor",
                        order = 13,
                        width = "normal",
                        min = 0, max = 1000, step = 1,
                        get = function() return EzUI.db.profile.targetCastBar.width end,
                        set = function(_, val)
                            EzUI.db.profile.targetCastBar.width = val
                            EzUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    offsetY = {
                        type = "range",
                        name = "Vertical Offset",
                        desc = "Distance from the anchor frame",
                        order = 14,
                        width = "full",
                        min = -500, max = 500, step = 1,
                        get = function() return EzUI.db.profile.targetCastBar.offsetY end,
                        set = function(_, val)
                            EzUI.db.profile.targetCastBar.offsetY = val
                            EzUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    offsetX = {
                        type = "range",
                        name = "Horizontal Offset",
                        desc = "Horizontal distance from the anchor point",
                        order = 15,
                        width = "full",
                        min = -500, max = 500, step = 1,
                        get = function() return EzUI.db.profile.targetCastBar.offsetX or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.targetCastBar.offsetX = val
                            EzUI:UpdateTargetCastBarLayout()
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
                            local override = EzUI.db.profile.targetCastBar.texture
                            if override and override ~= "" then
                                return override
                            end
                            -- Return global texture name when override is nil
                            return EzUI.db.profile.general.globalTexture or "Ez"
                        end,
                        set = function(_, val)
                            EzUI.db.profile.targetCastBar.texture = val
                            EzUI:UpdateTargetCastBarLayout()
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
                            local c = EzUI.db.profile.targetCastBar.interruptibleColor or EzUI.db.profile.targetCastBar.color
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 1, 0, 0, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzUI.db.profile.targetCastBar.interruptibleColor = { r, g, b, a }
                            -- keep base color in sync for legacy fallback
                            EzUI.db.profile.targetCastBar.color = { r, g, b, a }
                            EzUI:UpdateTargetCastBarLayout()
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
                            local c = EzUI.db.profile.targetCastBar.nonInterruptibleColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.6, 0.6, 0.6, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzUI.db.profile.targetCastBar.nonInterruptibleColor = { r, g, b, a }
                            EzUI:UpdateTargetCastBarLayout()
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
                            local c = EzUI.db.profile.targetCastBar.interruptedColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.8, 0.2, 0.2, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzUI.db.profile.targetCastBar.interruptedColor = { r, g, b, a }
                            EzUI:UpdateTargetCastBarLayout()
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
                            local c = EzUI.db.profile.targetCastBar.bgColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.1, 0.1, 0.1, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzUI.db.profile.targetCastBar.bgColor = { r, g, b, a }
                            EzUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    textSize = {
                        type = "range",
                        name = "Text Size",
                        order = 26,
                        width = "normal",
                        min = 6, max = 40, step = 1,
                        get = function() return EzUI.db.profile.targetCastBar.textSize end,
                        set = function(_, val)
                            EzUI.db.profile.targetCastBar.textSize = val
                            EzUI:UpdateTargetCastBarLayout()
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
                        get = function() return EzUI.db.profile.targetCastBar.nameOffsetX or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.targetCastBar.nameOffsetX = val
                            EzUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    nameOffsetY = {
                        type = "range",
                        name = "Name Text Offset Y",
                        order = 26.3,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzUI.db.profile.targetCastBar.nameOffsetY or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.targetCastBar.nameOffsetY = val
                            EzUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    timeOffsetX = {
                        type = "range",
                        name = "Time Text Offset X",
                        order = 26.4,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzUI.db.profile.targetCastBar.timeOffsetX or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.targetCastBar.timeOffsetX = val
                            EzUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    timeOffsetY = {
                        type = "range",
                        name = "Time Text Offset Y",
                        order = 26.5,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzUI.db.profile.targetCastBar.timeOffsetY or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.targetCastBar.timeOffsetY = val
                            EzUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    showTimeText = {
                        type = "toggle",
                        name = "Show Time Text",
                        desc = "Show the remaining cast time on the cast bar",
                        order = 27,
                        width = "normal",
                        get = function() return EzUI.db.profile.targetCastBar.showTimeText ~= false end,
                        set = function(_, val)
                            EzUI.db.profile.targetCastBar.showTimeText = val
                            EzUI:UpdateTargetCastBarLayout()
                        end,
                    },
                    showIcon = {
                        type = "toggle",
                        name = "Show Cast Icon",
                        desc = "Hide the spell icon if you prefer a bar-only look",
                        order = 28,
                        width = "normal",
                        get = function() return EzUI.db.profile.targetCastBar.showIcon ~= false end,
                        set = function(_, val)
                            EzUI.db.profile.targetCastBar.showIcon = val
                            EzUI:UpdateTargetCastBarLayout()
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
                        get = function() return EzUI.db.profile.focusCastBar.enabled end,
                        set = function(_, val)
                            EzUI.db.profile.focusCastBar.enabled = val
                            EzUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    testCast = {
                        type  = "execute",
                        name  = "Test Focus Cast Bar",
                        desc  = "Show a fake cast so you can preview and tweak the bar without a focus casting. Unit Must Be active to test.",
                        order = 3,
                        func  = function()
                            EzUI:ShowTestFocusCastBar()
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
                            if EzUI.db.profile.unitFrames and EzUI.db.profile.unitFrames.enabled then
                                opts["EzUI_Focus"] = "Focus Frame (Custom)"
                            end
                            local viewerOpts = GetViewerOptions()
                            for k, v in pairs(viewerOpts) do
                                opts[k] = v
                            end
                            opts["FocusFrame"] = "Default Focus Frame"
                            opts["UIParent"] = "Screen Center"
                            return opts
                        end,
                        get = function() return EzUI.db.profile.focusCastBar.attachTo end,
                        set = function(_, val)
                            EzUI.db.profile.focusCastBar.attachTo = val
                            EzUI:UpdateFocusCastBarLayout()
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
                        get = function() return EzUI.db.profile.focusCastBar.anchorPoint or "CENTER" end,
                        set = function(_, val)
                            EzUI.db.profile.focusCastBar.anchorPoint = val
                            EzUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        order = 12,
                        width = "normal",
                        min = 6, max = 40, step = 1,
                        get = function() return EzUI.db.profile.focusCastBar.height end,
                        set = function(_, val)
                            EzUI.db.profile.focusCastBar.height = val
                            EzUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        desc = "0 = automatic width based on anchor",
                        order = 13,
                        width = "normal",
                        min = 0, max = 1000, step = 1,
                        get = function() return EzUI.db.profile.focusCastBar.width end,
                        set = function(_, val)
                            EzUI.db.profile.focusCastBar.width = val
                            EzUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    offsetY = {
                        type = "range",
                        name = "Vertical Offset",
                        desc = "Distance from the anchor frame",
                        order = 14,
                        width = "full",
                        min = -500, max = 500, step = 1,
                        get = function() return EzUI.db.profile.focusCastBar.offsetY end,
                        set = function(_, val)
                            EzUI.db.profile.focusCastBar.offsetY = val
                            EzUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    offsetX = {
                        type = "range",
                        name = "Horizontal Offset",
                        desc = "Horizontal distance from the anchor point",
                        order = 15,
                        width = "full",
                        min = -500, max = 500, step = 1,
                        get = function() return EzUI.db.profile.focusCastBar.offsetX or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.focusCastBar.offsetX = val
                            EzUI:UpdateFocusCastBarLayout()
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
                            local override = EzUI.db.profile.focusCastBar.texture
                            if override and override ~= "" then
                                return override
                            end
                            -- Return global texture name when override is nil
                            return EzUI.db.profile.general.globalTexture or "Ez"
                        end,
                        set = function(_, val)
                            EzUI.db.profile.focusCastBar.texture = val
                            EzUI:UpdateFocusCastBarLayout()
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
                            local c = EzUI.db.profile.focusCastBar.interruptibleColor or EzUI.db.profile.focusCastBar.color
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 1, 0, 0, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzUI.db.profile.focusCastBar.interruptibleColor = { r, g, b, a }
                            -- keep base color in sync for legacy fallback
                            EzUI.db.profile.focusCastBar.color = { r, g, b, a }
                            EzUI:UpdateFocusCastBarLayout()
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
                            local c = EzUI.db.profile.focusCastBar.nonInterruptibleColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.6, 0.6, 0.6, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzUI.db.profile.focusCastBar.nonInterruptibleColor = { r, g, b, a }
                            EzUI:UpdateFocusCastBarLayout()
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
                            local c = EzUI.db.profile.focusCastBar.interruptedColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.8, 0.2, 0.2, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzUI.db.profile.focusCastBar.interruptedColor = { r, g, b, a }
                            EzUI:UpdateFocusCastBarLayout()
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
                            local c = EzUI.db.profile.focusCastBar.bgColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.1, 0.1, 0.1, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzUI.db.profile.focusCastBar.bgColor = { r, g, b, a }
                            EzUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    textSize = {
                        type = "range",
                        name = "Text Size",
                        order = 26,
                        width = "normal",
                        min = 6, max = 40, step = 1,
                        get = function() return EzUI.db.profile.focusCastBar.textSize end,
                        set = function(_, val)
                            EzUI.db.profile.focusCastBar.textSize = val
                            EzUI:UpdateFocusCastBarLayout()
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
                        get = function() return EzUI.db.profile.focusCastBar.nameOffsetX or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.focusCastBar.nameOffsetX = val
                            EzUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    nameOffsetY = {
                        type = "range",
                        name = "Name Text Offset Y",
                        order = 26.3,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzUI.db.profile.focusCastBar.nameOffsetY or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.focusCastBar.nameOffsetY = val
                            EzUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    timeOffsetX = {
                        type = "range",
                        name = "Time Text Offset X",
                        order = 26.4,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzUI.db.profile.focusCastBar.timeOffsetX or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.focusCastBar.timeOffsetX = val
                            EzUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    timeOffsetY = {
                        type = "range",
                        name = "Time Text Offset Y",
                        order = 26.5,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzUI.db.profile.focusCastBar.timeOffsetY or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.focusCastBar.timeOffsetY = val
                            EzUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    showTimeText = {
                        type = "toggle",
                        name = "Show Time Text",
                        desc = "Show the remaining cast time on the cast bar",
                        order = 27,
                        width = "normal",
                        get = function() return EzUI.db.profile.focusCastBar.showTimeText ~= false end,
                        set = function(_, val)
                            EzUI.db.profile.focusCastBar.showTimeText = val
                            EzUI:UpdateFocusCastBarLayout()
                        end,
                    },
                    showIcon = {
                        type = "toggle",
                        name = "Show Cast Icon",
                        desc = "Hide the spell icon if you prefer a bar-only look",
                        order = 28,
                        width = "normal",
                        get = function() return EzUI.db.profile.focusCastBar.showIcon ~= false end,
                        set = function(_, val)
                            EzUI.db.profile.focusCastBar.showIcon = val
                            EzUI:UpdateFocusCastBarLayout()
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
                        get = function() return EzUI.db.profile.bossCastBar.enabled end,
                        set = function(_, val)
                            EzUI.db.profile.bossCastBar.enabled = val
                            EzUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    testCast = {
                        type  = "execute",
                        name  = "Test Boss Cast Bars",
                        desc  = "Show fake casts on boss frames so you can preview and tweak the bars. Boss frames must be in preview mode.",
                        order = 3,
                        func  = function()
                            EzUI:ShowTestBossCastBars()
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
                        get = function() return EzUI.db.profile.bossCastBar.anchorPoint or "BOTTOM" end,
                        set = function(_, val)
                            EzUI.db.profile.bossCastBar.anchorPoint = val
                            EzUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        order = 13,
                        width = "normal",
                        min = 6, max = 40, step = 1,
                        get = function() return EzUI.db.profile.bossCastBar.height end,
                        set = function(_, val)
                            EzUI.db.profile.bossCastBar.height = val
                            EzUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        desc = "0 = automatic width based on anchor",
                        order = 14,
                        width = "normal",
                        min = 0, max = 1000, step = 1,
                        get = function() return EzUI.db.profile.bossCastBar.width end,
                        set = function(_, val)
                            EzUI.db.profile.bossCastBar.width = val
                            EzUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    offsetX = {
                        type = "range",
                        name = "Horizontal Offset",
                        order = 15,
                        width = "normal",
                        min = -200, max = 200, step = 1,
                        get = function() return EzUI.db.profile.bossCastBar.offsetX or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.bossCastBar.offsetX = val
                            EzUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    offsetY = {
                        type = "range",
                        name = "Vertical Offset",
                        order = 16,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzUI.db.profile.bossCastBar.offsetY or -1 end,
                        set = function(_, val)
                            EzUI.db.profile.bossCastBar.offsetY = val
                            EzUI:UpdateAllBossCastBarLayouts()
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
                        get = function() return EzUI.db.profile.bossCastBar.texture end,
                        set = function(_, val)
                            EzUI.db.profile.bossCastBar.texture = val
                            EzUI:UpdateAllBossCastBarLayouts()
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
                            local c = EzUI.db.profile.bossCastBar.interruptibleColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.5, 0.5, 1.0, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            EzUI.db.profile.bossCastBar.interruptibleColor = { r, g, b, a }
                            EzUI:UpdateAllBossCastBarLayouts()
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
                            local c = EzUI.db.profile.bossCastBar.nonInterruptibleColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.6, 0.6, 0.6, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            EzUI.db.profile.bossCastBar.nonInterruptibleColor = { r, g, b, a }
                            EzUI:UpdateAllBossCastBarLayouts()
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
                            local c = EzUI.db.profile.bossCastBar.interruptedColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.8, 0.2, 0.2, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            EzUI.db.profile.bossCastBar.interruptedColor = { r, g, b, a }
                            EzUI:UpdateAllBossCastBarLayouts()
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
                            local c = EzUI.db.profile.bossCastBar.bgColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.1, 0.1, 0.1, 1
                        end,
                        set = function(_, r, g, b, a)
                            EzUI.db.profile.bossCastBar.bgColor = { r, g, b, a }
                            EzUI:UpdateAllBossCastBarLayouts()
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
                        get = function() return EzUI.db.profile.bossCastBar.nameOffsetX or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.bossCastBar.nameOffsetX = val
                            EzUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    nameOffsetY = {
                        type = "range",
                        name = "Name Text Offset Y",
                        order = 26.2,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzUI.db.profile.bossCastBar.nameOffsetY or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.bossCastBar.nameOffsetY = val
                            EzUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    timeOffsetX = {
                        type = "range",
                        name = "Time Text Offset X",
                        order = 26.3,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzUI.db.profile.bossCastBar.timeOffsetX or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.bossCastBar.timeOffsetX = val
                            EzUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    timeOffsetY = {
                        type = "range",
                        name = "Time Text Offset Y",
                        order = 26.4,
                        width = "normal",
                        min = -100, max = 100, step = 1,
                        get = function() return EzUI.db.profile.bossCastBar.timeOffsetY or 0 end,
                        set = function(_, val)
                            EzUI.db.profile.bossCastBar.timeOffsetY = val
                            EzUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    showTimeText = {
                        type = "toggle",
                        name = "Show Time Text",
                        desc = "Show the remaining cast time on the cast bar",
                        order = 27,
                        width = "normal",
                        get = function() return EzUI.db.profile.bossCastBar.showTimeText ~= false end,
                        set = function(_, val)
                            EzUI.db.profile.bossCastBar.showTimeText = val
                            EzUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                    showIcon = {
                        type = "toggle",
                        name = "Show Cast Icon",
                        desc = "Hide the spell icon if you prefer a bar-only look",
                        order = 28,
                        width = "normal",
                        get = function() return EzUI.db.profile.bossCastBar.showIcon ~= false end,
                        set = function(_, val)
                            EzUI.db.profile.bossCastBar.showIcon = val
                            EzUI:UpdateAllBossCastBarLayouts()
                        end,
                    },
                },
            },
        },
    }
end

ns.CreateCastBarOptions = CreateCastBarOptions

