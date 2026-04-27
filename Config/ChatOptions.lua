local ADDON_NAME, ns = ...
local EzroUI = ns.Addon

-- Helper
local function chat() return EzroUI.db.profile.chat end
local function refresh()
    if EzroUI.Chat and EzroUI.Chat.RefreshAll then
        EzroUI.Chat:RefreshAll()
    end
end

-- Channel color sub-table builder
local CHANNEL_NAMES = {
    SAY            = "Say",
    YELL           = "Yell",
    WHISPER        = "Whisper",
    WHISPER_INFORM = "Whisper (outgoing)",
    PARTY          = "Party",
    PARTY_LEADER   = "Party Leader",
    RAID           = "Raid",
    RAID_LEADER    = "Raid Leader",
    RAID_WARNING   = "Raid Warning",
    GUILD          = "Guild",
    OFFICER        = "Officer",
    BATTLEGROUND   = "Battleground",
    EMOTE          = "Emote",
    SYSTEM         = "System",
    CHANNEL        = "Channel",
    INSTANCE_CHAT  = "Instance Chat",
}

local DEFAULT_CHANNEL_COLORS = {
    SAY            = { 1.00, 1.00, 1.00 },
    YELL           = { 1.00, 0.25, 0.25 },
    WHISPER        = { 1.00, 0.50, 1.00 },
    WHISPER_INFORM = { 1.00, 0.50, 1.00 },
    PARTY          = { 0.67, 0.67, 1.00 },
    PARTY_LEADER   = { 0.40, 0.80, 1.00 },
    RAID           = { 1.00, 0.73, 0.00 },
    RAID_LEADER    = { 1.00, 0.60, 0.00 },
    RAID_WARNING   = { 1.00, 0.30, 0.30 },
    GUILD          = { 0.25, 1.00, 0.25 },
    OFFICER        = { 0.25, 0.75, 0.25 },
    BATTLEGROUND   = { 1.00, 0.73, 0.25 },
    EMOTE          = { 1.00, 0.50, 0.25 },
    SYSTEM         = { 1.00, 1.00, 0.00 },
    CHANNEL        = { 0.80, 0.80, 0.80 },
    INSTANCE_CHAT  = { 0.80, 1.00, 1.00 },
}

local function BuildChannelColorArgs()
    local args = {}
    local i = 1
    for key, label in pairs(CHANNEL_NAMES) do
        local k = key  -- upvalue
        args[k] = {
            type  = "color",
            name  = label,
            order = i,
            hasAlpha = false,
            get = function()
                local saved = chat().channelColors and chat().channelColors[k]
                if saved then return saved[1], saved[2], saved[3] end
                local def = DEFAULT_CHANNEL_COLORS[k]
                return def and def[1] or 1, def and def[2] or 1, def and def[3] or 1
            end,
            set = function(_, r, g, b)
                if not chat().channelColors then
                    chat().channelColors = {}
                end
                chat().channelColors[k] = { r, g, b }
            end,
        }
        i = i + 1
    end
    return args
end

local function CreateChatOptions()
    return {
        type  = "group",
        name  = "Chat",
        order = 3,
        args  = {

            -- ======================================================
            --  GENERAL
            -- ======================================================
            headerGeneral = {
                type  = "header",
                name  = "General",
                order = 1,
            },
            enabled = {
                type  = "toggle",
                name  = "Enable Chat Skinning",
                desc  = "Apply custom styling to chat frames",
                width = "full",
                order = 2,
                get   = function() return chat().enabled end,
                set   = function(_, v) chat().enabled = v; refresh() end,
            },
            backgroundColor = {
                type     = "color",
                name     = "Background Color",
                desc     = "Color and opacity of chat frame backgrounds",
                order    = 3,
                width    = "full",
                hasAlpha = true,
                get = function()
                    local c = chat().backgroundColor
                    return c[1], c[2], c[3], c[4] or 1
                end,
                set = function(_, r, g, b, a)
                    chat().backgroundColor = { r, g, b, a or 1 }
                    refresh()
                end,
            },
            spacerGen = { type="description", name=" ", order=4 },

            -- ======================================================
            --  FONT
            -- ======================================================
            headerFont = {
                type  = "header",
                name  = "Font",
                order = 10,
            },
            fontSize = {
                type  = "range",
                name  = "Font Size",
                desc  = "Size of chat message text",
                width = "full",
                min   = 6,
                max   = 24,
                step  = 1,
                order = 11,
                get   = function() return chat().fontSize or 12 end,
                set   = function(_, v) chat().fontSize = v; refresh() end,
            },
            fontOutline = {
                type  = "toggle",
                name  = "Font Outline",
                desc  = "Add an outline to chat text for readability",
                width = "full",
                order = 12,
                get   = function() return chat().fontOutline end,
                set   = function(_, v) chat().fontOutline = v; refresh() end,
            },
            spacerFont = { type="description", name=" ", order=13 },

            -- ======================================================
            --  TIMESTAMPS
            -- ======================================================
            headerTimestamps = {
                type  = "header",
                name  = "Timestamps",
                order = 20,
            },
            timestamps = {
                type  = "toggle",
                name  = "Show Timestamps",
                desc  = "Prepend a timestamp to every chat message",
                width = "full",
                order = 21,
                get   = function() return chat().timestamps end,
                set   = function(_, v) chat().timestamps = v end,
            },
            timestampFormat = {
                type   = "select",
                name   = "Timestamp Format",
                desc   = "Format used for the timestamp",
                width  = "full",
                order  = 22,
                values = {
                    ["HH:MM"]       = "HH:MM  (24-hour)",
                    ["HH:MM:SS"]    = "HH:MM:SS  (24-hour with seconds)",
                    ["hh:MM am/pm"] = "hh:MM am/pm  (12-hour)",
                },
                get    = function() return chat().timestampFormat or "HH:MM" end,
                set    = function(_, v) chat().timestampFormat = v end,
            },
            timestampColor = {
                type     = "color",
                name     = "Timestamp Color",
                desc     = "Color of the timestamp text",
                order    = 23,
                hasAlpha = false,
                get = function()
                    local c = chat().timestampColor or { 0.6, 0.6, 0.6 }
                    return c[1], c[2], c[3]
                end,
                set = function(_, r, g, b)
                    chat().timestampColor = { r, g, b }
                end,
            },
            spacerTS = { type="description", name=" ", order=24 },

            -- ======================================================
            --  NAMES & CHANNELS
            -- ======================================================
            headerNames = {
                type  = "header",
                name  = "Names & Channels",
                order = 30,
            },
            classColoredNames = {
                type  = "toggle",
                name  = "Class-Colored Names",
                desc  = "Color player names in chat by their class",
                width = "full",
                order = 31,
                get   = function() return chat().classColoredNames end,
                set   = function(_, v) chat().classColoredNames = v end,
            },
            shortChannelNames = {
                type  = "toggle",
                name  = "Short Channel Names",
                desc  = "Abbreviate channel names (e.g. General → G, Trade → T)",
                width = "full",
                order = 32,
                get   = function() return chat().shortChannelNames end,
                set   = function(_, v) chat().shortChannelNames = v end,
            },
            highlightURLs = {
                type  = "toggle",
                name  = "Highlight URLs",
                desc  = "Highlight http/https links in chat messages",
                width = "full",
                order = 33,
                get   = function() return chat().highlightURLs end,
                set   = function(_, v) chat().highlightURLs = v end,
            },
            spacerNames = { type="description", name=" ", order=34 },

            -- ======================================================
            --  CHANNEL COLORS
            -- ======================================================
            headerChanColors = {
                type  = "header",
                name  = "Channel Colors",
                order = 40,
            },
            channelColoring = {
                type  = "toggle",
                name  = "Enable Channel Coloring",
                desc  = "Apply custom colors to each chat channel type",
                width = "full",
                order = 41,
                get   = function() return chat().channelColoring end,
                set   = function(_, v) chat().channelColoring = v end,
            },
            channelColorGroup = {
                type   = "group",
                name   = "Channel Colors",
                order  = 42,
                inline = true,
                args   = BuildChannelColorArgs(),
            },
            spacerCC = { type="description", name=" ", order=43 },

            -- ======================================================
            --  APPEARANCE
            -- ======================================================
            headerAppearance = {
                type  = "header",
                name  = "Appearance",
                order = 50,
            },
            skinTabs = {
                type  = "toggle",
                name  = "Skin Chat Tabs",
                desc  = "Apply custom styling to chat tab buttons",
                width = "full",
                order = 51,
                get   = function() return chat().skinTabs end,
                set   = function(_, v) chat().skinTabs = v; refresh() end,
            },
            skinBubbles = {
                type  = "toggle",
                name  = "Skin Chat Bubbles",
                desc  = "Apply custom styling to in-world speech bubbles",
                width = "full",
                order = 52,
                get   = function() return chat().skinBubbles end,
                set   = function(_, v) chat().skinBubbles = v; refresh() end,
            },
            copyButton = {
                type  = "toggle",
                name  = "Copy Button",
                desc  = "Show a button (top-right of frame, visible on hover) to copy chat text",
                width = "full",
                order = 53,
                get   = function() return chat().copyButton end,
                set   = function(_, v) chat().copyButton = v; refresh() end,
            },
            autoHideScrollbar = {
                type  = "toggle",
                name  = "Auto-Hide Scrollbar",
                desc  = "Hide the scrollbar until you hover over the chat frame",
                width = "full",
                order = 54,
                get   = function() return chat().autoHideScrollbar end,
                set   = function(_, v) chat().autoHideScrollbar = v; refresh() end,
            },
            spacerApp = { type="description", name=" ", order=55 },

            -- ======================================================
            --  CHAT FADE
            -- ======================================================
            headerFade = {
                type  = "header",
                name  = "Chat Fade",
                order = 60,
            },
            fadingChat = {
                type  = "toggle",
                name  = "Fade Chat When Inactive",
                desc  = "Chat frames fade out when not moused over and reappear on hover",
                width = "full",
                order = 61,
                get   = function() return chat().fadingChat end,
                set   = function(_, v) chat().fadingChat = v; refresh() end,
            },
            fadeAlpha = {
                type  = "range",
                name  = "Idle Opacity",
                desc  = "Chat frame opacity when not being moused over",
                width = "full",
                min   = 0,
                max   = 1,
                step  = 0.05,
                order = 62,
                get   = function() return chat().fadeAlpha or 0.3 end,
                set   = function(_, v) chat().fadeAlpha = v; refresh() end,
            },
            spacerFade = { type="description", name=" ", order=63 },

            -- ======================================================
            --  BEHAVIOUR
            -- ======================================================
            headerBehaviour = {
                type  = "header",
                name  = "Behaviour",
                order = 70,
            },
            stickyChannels = {
                type  = "toggle",
                name  = "Sticky Channels",
                desc  = "Remember the last channel used per chat frame and restore it when typing",
                width = "full",
                order = 71,
                get   = function() return chat().stickyChannels end,
                set   = function(_, v) chat().stickyChannels = v; refresh() end,
            },
            spacerBeh = { type="description", name=" ", order=72 },

            -- ======================================================
            --  SPAM FILTER
            -- ======================================================
            headerSpam = {
                type  = "header",
                name  = "Spam Filter",
                order = 80,
            },
            spamFilter = {
                type  = "toggle",
                name  = "Enable Spam Filter",
                desc  = "Block messages that repeat more than N times within a time window",
                width = "full",
                order = 81,
                get   = function() return chat().spamFilter end,
                set   = function(_, v) chat().spamFilter = v end,
            },
            spamMaxRepeat = {
                type  = "range",
                name  = "Max Repeats",
                desc  = "How many times the same message can appear before being blocked",
                width = "full",
                min   = 1,
                max   = 10,
                step  = 1,
                order = 82,
                get   = function() return chat().spamMaxRepeat or 3 end,
                set   = function(_, v) chat().spamMaxRepeat = v end,
            },
            spamWindow = {
                type  = "range",
                name  = "Time Window (sec)",
                desc  = "Time window in seconds for spam detection",
                width = "full",
                min   = 1,
                max   = 60,
                step  = 1,
                order = 83,
                get   = function() return chat().spamWindow or 10 end,
                set   = function(_, v) chat().spamWindow = v end,
            },
            spacerSpam = { type="description", name=" ", order=84 },

            -- ======================================================
            --  QUICK JOIN
            -- ======================================================
            headerQuickJoin = {
                type  = "header",
                name  = "Quick Join Toast Button",
                order = 90,
            },
            hideQuickJoinToastButton = {
                type  = "toggle",
                name  = "Hide Quick Join Toast Button",
                desc  = "Hide the Quick Join toast button that appears in chat",
                width = "full",
                order = 91,
                get   = function() return chat().hideQuickJoinToastButton end,
                set   = function(_, v)
                    chat().hideQuickJoinToastButton = v
                    if EzroUI.Chat and EzroUI.Chat.UpdateQuickJoinToastButton then
                        EzroUI.Chat:UpdateQuickJoinToastButton()
                    end
                end,
            },
            quickJoinToastButtonOffsetX = {
                type  = "range",
                name  = "Quick Join X Offset",
                desc  = "Horizontal offset for the Quick Join toast button",
                width = "full",
                min   = -500,
                max   = 500,
                step  = 1,
                order = 92,
                get   = function() return chat().quickJoinToastButtonOffsetX or 31 end,
                set   = function(_, v)
                    chat().quickJoinToastButtonOffsetX = v
                    if EzroUI.Chat and EzroUI.Chat.UpdateQuickJoinToastButton then
                        EzroUI.Chat:UpdateQuickJoinToastButton()
                    end
                end,
            },
            quickJoinToastButtonOffsetY = {
                type  = "range",
                name  = "Quick Join Y Offset",
                desc  = "Vertical offset for the Quick Join toast button",
                width = "full",
                min   = -500,
                max   = 500,
                step  = 1,
                order = 93,
                get   = function() return chat().quickJoinToastButtonOffsetY or -23 end,
                set   = function(_, v)
                    chat().quickJoinToastButtonOffsetY = v
                    if EzroUI.Chat and EzroUI.Chat.UpdateQuickJoinToastButton then
                        EzroUI.Chat:UpdateQuickJoinToastButton()
                    end
                end,
            },
        },
    }
end

ns.CreateChatOptions = CreateChatOptions
