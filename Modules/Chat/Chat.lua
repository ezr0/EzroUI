local ADDON_NAME, ns = ...
local EzroUI = ns.Addon

EzroUI.Chat = EzroUI.Chat or {}
local Chat = EzroUI.Chat

-- ============================================================
--  CONSTANTS
-- ============================================================
local SHORT_CHANNEL_NAMES = {
    ["General"]         = "G",
    ["Trade"]           = "T",
    ["LocalDefense"]    = "LD",
    ["LookingForGroup"] = "LFG",
    ["WorldDefense"]    = "WD",
    ["GuildRecruitment"]= "GR",
    ["Realm"]           = "R",
}

local CHANNEL_EVENT_ABBREV = {
    CHAT_MSG_SAY            = "S",
    CHAT_MSG_YELL           = "Y",
    CHAT_MSG_WHISPER        = "W",
    CHAT_MSG_WHISPER_INFORM = "W",
    CHAT_MSG_PARTY          = "P",
    CHAT_MSG_PARTY_LEADER   = "P",
    CHAT_MSG_RAID           = "R",
    CHAT_MSG_RAID_LEADER    = "RL",
    CHAT_MSG_RAID_WARNING   = "RW",
    CHAT_MSG_GUILD          = "G",
    CHAT_MSG_OFFICER        = "O",
    CHAT_MSG_BATTLEGROUND   = "BG",
    CHAT_MSG_BATTLEGROUND_LEADER = "BGL",
    CHAT_MSG_INSTANCE_CHAT  = "I",
    CHAT_MSG_INSTANCE_CHAT_LEADER = "IL",
    CHAT_MSG_EMOTE          = "E",
    CHAT_MSG_TEXT_EMOTE     = "E",
    CHAT_MSG_SYSTEM         = "Sys",
    CHAT_MSG_CHANNEL        = "Chan",
}

local TIMESTAMP_FORMATS = {
    ["HH:MM"]      = "%H:%M",
    ["HH:MM:SS"]   = "%H:%M:%S",
    ["hh:MM am/pm"]= "%I:%M %p",
}

-- Spam filter history: eventType+sender → {lastMsg, count, lastTime}
local spamHistory = {}

-- URL pattern
local URL_PATTERN = "https?://[%w%.%-_~:/?#%[%]@!$&'%(%)%*%+,;=%%]+"

-- ============================================================
--  UTILITY HELPERS
-- ============================================================
local function cfg()
    return EzroUI.db.profile.chat
end

local function CreateBorder(frame)
    if frame.__EzroUIBorder then return frame.__EzroUIBorder end
    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    local offset = EzroUI:Scale(1)
    border:SetPoint("TOPLEFT",     frame, -offset,  offset)
    border:SetPoint("BOTTOMRIGHT", frame,  offset, -offset)
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    border:SetBackdropBorderColor(0, 0, 0, 1)
    border:SetFrameLevel(frame:GetFrameLevel() + 1)
    frame.__EzroUIBorder = border
    return border
end

local function ApplyBackground(frame, r, g, b, a)
    if not frame then return end
    if frame.SetBackdrop then
        if not frame.__EzroUIBackdropSet then
            frame:SetBackdrop({
                bgFile  = "Interface\\Buttons\\WHITE8x8",
                tile    = false,
                tileSize = 0,
                insets  = { left=0, right=0, top=0, bottom=0 },
            })
            frame.__EzroUIBackdropSet = true
        end
        frame:SetBackdropColor(r, g, b, a)
    elseif frame.CreateTexture then
        if not frame.__EzroUIBg then
            local bg = frame:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            frame.__EzroUIBg = bg
        end
        frame.__EzroUIBg:SetColorTexture(r, g, b, a)
    end
end

local function GetClassColor(className)
    if className and RAID_CLASS_COLORS and RAID_CLASS_COLORS[className] then
        local c = RAID_CLASS_COLORS[className]
        return c.r, c.g, c.b
    end
    return 1, 1, 1
end

-- Simple name→class cache populated by CHAT_MSG events
local nameClassCache = {}

local function CacheNameClass(name, className)
    if name and className and className ~= "" then
        nameClassCache[name] = className:upper()
    end
end

-- ============================================================
--  TIMESTAMPS
-- ============================================================
local function BuildTimestamp()
    local c = cfg()
    if not c or not c.timestamps then return "" end
    local fmt = TIMESTAMP_FORMATS[c.timestampFormat] or "%H:%M"
    local t   = date(fmt)
    local r, g, b = c.timestampColor[1], c.timestampColor[2], c.timestampColor[3]
    return string.format("|cff%02x%02x%02x[%s]|r ", r*255, g*255, b*255, t)
end

-- ============================================================
--  SHORT CHANNEL NAMES
-- ============================================================
local function ShortenChannel(text)
    local c = cfg()
    if not c or not c.shortChannelNames then return text end

    -- Replace numbered channel prefixes like [1. General] → [G]
    text = text:gsub("%[(%d+)%. ([^%]]+)%]", function(num, name)
        local short = SHORT_CHANNEL_NAMES[name] or name:sub(1,1)
        return "["..short.."]"
    end)

    -- Replace bare channel tags like |Hchannel:...|h[...]|h
    text = text:gsub("|Hchannel:([^|]*)|h%[([^%]]*)%]|h", function(id, name)
        local short = SHORT_CHANNEL_NAMES[name] or name:sub(1,1)
        return "|Hchannel:"..id.."|h["..short.."]|h"
    end)

    return text
end

-- ============================================================
--  CLASS-COLORED NAMES
-- ============================================================
local function ColorName(name, className)
    if not name or name == "" then return name end
    local c = cfg()
    if not c or not c.classColoredNames then return name end

    local cls = className and className:upper() or nameClassCache[name]
    if cls then
        local r, g, b = GetClassColor(cls)
        return string.format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, name)
    end
    return name
end

-- ============================================================
--  URL HIGHLIGHTING
-- ============================================================
local function HighlightURLs(text)
    local c = cfg()
    if not c or not c.highlightURLs then return text end
    return (text:gsub(URL_PATTERN, function(url)
        -- Wrap URL in a yellow hyperlink-style color
        return "|cff00aaff"..url.."|r"
    end))
end

-- ============================================================
--  SPAM FILTER
-- ============================================================
local function IsSpam(event, sender, message)
    local c = cfg()
    if not c or not c.spamFilter then return false end

    local key     = (event or "").."_"..(sender or "")
    local now     = GetTime()
    local window  = c.spamWindow or 10
    local maxRep  = c.spamMaxRepeat or 3

    local entry = spamHistory[key]
    if not entry then
        spamHistory[key] = { msg = message, count = 1, time = now }
        return false
    end

    if entry.msg == message and (now - entry.time) < window then
        entry.count = entry.count + 1
        if entry.count > maxRep then
            return true
        end
    else
        entry.msg   = message
        entry.count = 1
        entry.time  = now
    end
    return false
end

-- ============================================================
--  CHAT FONT HELPERS
-- ============================================================
local function ApplyFontToString(fs)
    if not fs then return end
    local c = cfg()
    if not c then return end
    local font, size, flags = fs:GetFont()
    if not font then return end
    local newSize  = c.fontSize or size or 12
    local newFlags = c.fontOutline and "OUTLINE" or (flags or "")
    fs:SetFont(font, newSize, newFlags)
    fs:SetShadowOffset(0, 0)
end

local function ApplyFontToAllStrings(frame)
    if not frame or frame:IsForbidden() then return end
    if frame.GetFontString then
        ApplyFontToString(frame:GetFontString())
    end
    if frame.GetRegions then
        for _, r in ipairs({ frame:GetRegions() }) do
            if r and r.GetObjectType and r:GetObjectType() == "FontString" then
                ApplyFontToString(r)
            end
        end
    end
    for _, child in ipairs({ frame:GetChildren() }) do
        ApplyFontToAllStrings(child)
    end
end

-- ============================================================
--  COPY CHAT BUTTON
-- ============================================================
local copyFrame

local function BuildCopyFrame()
    if copyFrame then return end

    copyFrame = CreateFrame("Frame", "EzroUIChatCopy", UIParent, "BasicFrameTemplateWithInset")
    copyFrame:SetSize(600, 400)
    copyFrame:SetPoint("CENTER")
    copyFrame:SetMovable(true)
    copyFrame:EnableMouse(true)
    copyFrame:RegisterForDrag("LeftButton")
    copyFrame:SetScript("OnDragStart", copyFrame.StartMoving)
    copyFrame:SetScript("OnDragStop",  copyFrame.StopMovingOrSizing)
    copyFrame:Hide()

    copyFrame.title = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    copyFrame.title:SetPoint("TOP", copyFrame, "TOP", 0, -5)
    copyFrame.title:SetText("Copy Chat")

    local scroll = CreateFrame("ScrollFrame", nil, copyFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     copyFrame, "TOPLEFT",  10, -30)
    scroll:SetPoint("BOTTOMRIGHT", copyFrame, "BOTTOMRIGHT", -28, 10)
    copyFrame.scroll = scroll

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(560)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function() copyFrame:Hide() end)
    scroll:SetScrollChild(editBox)
    copyFrame.editBox = editBox

    -- Close with Escape
    tinsert(UISpecialFrames, "EzroUIChatCopy")
end

local function ShowCopyFrame(chatFrame)
    BuildCopyFrame()
    local lines = {}
    -- ScrollingMessageFrame: GetNumMessages / GetMessageInfo
    if chatFrame.GetNumMessages then
        for i = 1, chatFrame:GetNumMessages() do
            local text = chatFrame:GetMessageInfo(i)
            if text then lines[#lines+1] = text end
        end
    end
    local content = table.concat(lines, "\n")
    copyFrame.editBox:SetText(content)
    copyFrame.editBox:HighlightText()
    copyFrame:Show()
end

-- ============================================================
--  TAB SKINNING
-- ============================================================
local function SkinChatTab(tab)
    if not tab or tab.__EzroUITabSkinned then return end
    tab.__EzroUITabSkinned = true

    -- Hide all existing tab textures
    local texturesToHide = {
        "Left", "Middle", "Right",
        "LeftActive", "MiddleActive", "RightActive",
        "LeftHighlight", "MiddleHighlight", "RightHighlight",
        "ActiveLeft", "ActiveMiddle", "ActiveRight",
        "HighlightLeft", "HighlightMiddle", "HighlightRight",
    }
    for _, name in ipairs(texturesToHide) do
        local t = tab[name]
        if t then t:SetAlpha(0) end
        local g = _G[tab:GetName() and (tab:GetName() .. name) or ""]
        if g then g:SetAlpha(0) end
    end

    -- Apply black background
    if not tab.__EzroUITabBg then
        local bg = tab:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0.6)
        tab.__EzroUITabBg = bg
    end

    -- Highlight on hover
    if not tab.__EzroUITabHooked then
        tab.__EzroUITabHooked = true
        tab:HookScript("OnEnter", function(self)
            self.__EzroUITabBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        end)
        tab:HookScript("OnLeave", function(self)
            self.__EzroUITabBg:SetColorTexture(0, 0, 0, 0.6)
        end)
    end

    CreateBorder(tab)
end

local function SkinAllTabs()
    local c = cfg()
    if not c or not c.skinTabs then return end
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local tab = _G["ChatFrame"..i.."Tab"]
        if tab then SkinChatTab(tab) end
    end
end

-- ============================================================
--  CHAT BUBBLE SKINNING
-- ============================================================
local chatBubbleHooked = false

local function SkinChatBubbles()
    local c = cfg()
    if not c or not c.skinBubbles then return end
    if chatBubbleHooked then return end
    chatBubbleHooked = true

    hooksecurefunc("ChatFrame_AddMessageEventFilter", function() end)   -- keep as no-op

    -- Hook the bubble frame template via UIParent OnUpdate trick
    local scanner = CreateFrame("Frame")
    scanner:SetScript("OnUpdate", function()
        for _, frame in pairs({ WorldFrame:GetChildren() }) do
            if frame:IsVisible() and frame.GetChildren then
                for _, child in pairs({ frame:GetChildren() }) do
                    if child and child.String and not child.__EzroUIBubbleSkinned then
                        child.__EzroUIBubbleSkinned = true
                        -- Hide default artwork
                        for _, r in pairs({ child:GetRegions() }) do
                            if r and r.GetObjectType then
                                local t = r:GetObjectType()
                                if t == "Texture" then r:SetAlpha(0) end
                            end
                        end
                        -- Apply dark backdrop
                        ApplyBackground(child, 0, 0, 0, 0.7)
                        CreateBorder(child)
                        -- Style text
                        if child.String then
                            local fs = child.String
                            local font, size = fs:GetFont()
                            if font then fs:SetFont(font, size or 12, "OUTLINE") end
                            fs:SetShadowOffset(0, 0)
                        end
                    end
                end
            end
        end
    end)
end

-- ============================================================
--  CHAT FADE (mouse-over fade)
-- ============================================================
local fadedFrames = {}

local function SetupChatFade(chatFrame)
    local c = cfg()
    if not c or not c.fadingChat then return end
    if chatFrame.__EzroUIFadeSetup then return end
    chatFrame.__EzroUIFadeSetup = true

    local idleAlpha   = c.fadeAlpha   or 0.3
    local activeAlpha = 1.0

    -- Set initial state
    chatFrame:SetAlpha(idleAlpha)
    fadedFrames[chatFrame] = idleAlpha

    if not chatFrame.__EzroUIFadeHooked then
        chatFrame.__EzroUIFadeHooked = true
        chatFrame:HookScript("OnEnter", function(self)
            UIFrameFadeIn(self, 0.3, self:GetAlpha(), activeAlpha)
        end)
        chatFrame:HookScript("OnLeave", function(self)
            local cfg2 = EzroUI.db.profile.chat
            if cfg2 and cfg2.fadingChat then
                UIFrameFadeOut(self, 1.0, self:GetAlpha(), cfg2.fadeAlpha or 0.3)
            end
        end)
    end
end

local function TeardownChatFade(chatFrame)
    if not chatFrame then return end
    chatFrame.__EzroUIFadeSetup = nil
    chatFrame:SetAlpha(1.0)
    fadedFrames[chatFrame] = nil
end

-- ============================================================
--  SCROLLBAR AUTO-HIDE
-- ============================================================
local function SetupScrollbarAutoHide(chatFrame)
    local c = cfg()
    if not c then return end
    if chatFrame.__EzroUIScrollbarSetup then return end
    chatFrame.__EzroUIScrollbarSetup = true

    local scrollBar
    if chatFrame.ScrollBar then
        scrollBar = chatFrame.ScrollBar
    else
        local name = chatFrame:GetName()
        if name then scrollBar = _G[name.."ScrollBar"] end
    end
    if not scrollBar then return end

    local function UpdateVisibility()
        local c2 = EzroUI.db.profile.chat
        if c2 and c2.autoHideScrollbar then
            scrollBar:SetAlpha(0)
        else
            scrollBar:SetAlpha(1)
        end
    end

    UpdateVisibility()

    if not scrollBar.__EzroUIScrollHooked then
        scrollBar.__EzroUIScrollHooked = true
        chatFrame:HookScript("OnEnter", function()
            local c2 = EzroUI.db.profile.chat
            if c2 and c2.autoHideScrollbar then
                scrollBar:SetAlpha(1)
            end
        end)
        chatFrame:HookScript("OnLeave", function()
            local c2 = EzroUI.db.profile.chat
            if c2 and c2.autoHideScrollbar then
                scrollBar:SetAlpha(0)
            end
        end)
    end
end

-- ============================================================
--  STICKY CHANNELS
-- ============================================================
local stickyChannels = {}  -- frameIndex → channelType string

local function SetupStickyChannels(chatFrame)
    local c = cfg()
    if not c or not c.stickyChannels then return end
    if chatFrame.__EzroUIStickyHooked then return end
    chatFrame.__EzroUIStickyHooked = true

    -- Remember channel when user sends a message
    if chatFrame.editBox then
        chatFrame.editBox:HookScript("OnEnterPressed", function(self)
            local c2 = EzroUI.db.profile.chat
            if not c2 or not c2.stickyChannels then return end
            local chanType = self:GetAttribute("chatType")
            if chanType then
                local idx = chatFrame.__EzroUIIndex or 1
                stickyChannels[idx] = chanType
            end
        end)

        -- Restore sticky channel when edit box opens
        chatFrame.editBox:HookScript("OnShow", function(self)
            local c2 = EzroUI.db.profile.chat
            if not c2 or not c2.stickyChannels then return end
            local idx = chatFrame.__EzroUIIndex or 1
            local saved = stickyChannels[idx]
            if saved and self.SetAttribute then
                self:SetAttribute("chatType", saved)
            end
        end)
    end
end

-- ============================================================
--  CHANNEL COLORING  (post-message hook via AddMessage)
-- ============================================================
-- These override the channel-header color of incoming messages when enabled
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

local function GetChannelColor(channelType)
    local c = cfg()
    if not c or not c.channelColoring then return nil end

    -- User-overridden colors take precedence
    local custom = c.channelColors and c.channelColors[channelType]
    if custom then return custom[1], custom[2], custom[3] end

    -- Fall back to defaults
    local def = DEFAULT_CHANNEL_COLORS[channelType]
    if def then return def[1], def[2], def[3] end
    return nil
end

-- ============================================================
--  EDIT BOX HELPERS  (unchanged from original, cleaned up)
-- ============================================================
local function CleanEditBoxTextures(editBox)
    if not editBox then return end
    for _, region in ipairs({ editBox:GetRegions() }) do
        if region and region.GetObjectType then
            if region:GetObjectType() == "Texture" then
                if region ~= editBox.__EzroUIBg and region ~= editBox.__EzroUIBorder then
                    region:Hide()
                end
            end
        end
    end
    for _, name in ipairs({ "FocusLeft","FocusMid","FocusRight","Header","HeaderSuffix",
                              "LanguageHeader","Prompt","NewcomerHint" }) do
        local f = editBox[name]
        if f and f.Hide then f:Hide() end
    end
end

local function StyleEditBox(editBox)
    if not editBox then return end
    local c = cfg()
    if not c or not c.enabled then return end
    local font, size, flags = editBox:GetFont()
    if font then
        local newFlags = (flags and flags:find("OUTLINE")) and flags or "OUTLINE"
        editBox:SetFont(font, c.fontSize or size or 12, newFlags)
    end
    editBox:SetShadowOffset(0, 0)
end

-- ============================================================
--  FRAME SKINNING  (refactored)
-- ============================================================
function Chat:SkinChatFrame(chatFrame)
    if not chatFrame or chatFrame:IsForbidden() then return end
    if chatFrame.__EzroUISkinned then return end

    local c = cfg()
    if not c or not c.enabled then return end

    chatFrame.__EzroUISkinned = true

    -- Un-clamp
    if chatFrame.SetClampedToScreen then
        chatFrame:SetClampedToScreen(false)
    end

    -- Background & border
    local bg = c.backgroundColor or { 0.1, 0.1, 0.1, 1 }
    ApplyBackground(chatFrame, bg[1], bg[2], bg[3], bg[4] or 1)
    CreateBorder(chatFrame)

    -- Neutralise the Blizzard Background child
    if chatFrame.Background then
        local b = chatFrame.Background
        b:SetAlpha(0)
        if b.SetClampedToScreen then b:SetClampedToScreen(false) end
        if not b.__EzroUIAlphaHooked then
            b.__EzroUIAlphaHooked = true
            local orig = b.SetAlpha
            b.SetAlpha = function(self, _) orig(self, 0) end
        end
    end

    -- Hide default blizzard textures
    local fname = chatFrame:GetName()
    if fname then
        for _, suffix in ipairs({ "RightTexture","LeftTexture","MidTexture","TopTexture",
                                   "BottomTexture","TopRightTexture","TopLeftTexture",
                                   "BottomRightTexture","BottomLeftTexture" }) do
            local t = _G[fname..suffix]
            if t then t:Hide() end
        end
    end

    -- ---- Edit Box -------------------------------------------
    local editBox = chatFrame.editBox
    if not editBox and fname then
        editBox = _G[fname.."EditBox"]
    end
    if editBox then
        CleanEditBoxTextures(editBox)
        local ebg = c.backgroundColor or { 0.1, 0.1, 0.1, 1 }
        ApplyBackground(editBox, ebg[1], ebg[2], ebg[3], ebg[4] or 1)
        CreateBorder(editBox)
        StyleEditBox(editBox)
        editBox:SetAlpha(1.0)

        -- Lock alpha at 1
        if not editBox.__EzroUIAlphaHooked then
            editBox.__EzroUIAlphaHooked = true
            local orig = editBox.SetAlpha
            editBox.SetAlpha = function(self, _) orig(self, 1.0) end
        end

        -- Width matching
        local function MatchWidth()
            if InCombatLockdown() then return end
            local w = chatFrame:GetWidth()
            if not w then return end
            editBox:ClearAllPoints()
            editBox:SetPoint("BOTTOMLEFT",  chatFrame, "BOTTOMLEFT",  0, 0)
            editBox:SetPoint("BOTTOMRIGHT", chatFrame, "BOTTOMRIGHT", 0, 0)
        end
        MatchWidth()
        if not chatFrame.__EzroUIEditBoxHooked then
            chatFrame.__EzroUIEditBoxHooked = true
            chatFrame:HookScript("OnSizeChanged", MatchWidth)
            editBox:HookScript("OnShow",  MatchWidth)
            C_Timer.NewTicker(0.5, MatchWidth)
        end

        -- Keep primary edit box always visible
        local primaryEditBox = _G.ChatFrameEditBox or _G.ChatFrame1EditBox
        if editBox == primaryEditBox and not editBox.__EzroUIShowHooked then
            editBox.__EzroUIShowHooked = true
            editBox:Show()
            editBox:HookScript("OnHide", function(self) self:Show() end)
            local origHide = editBox.Hide
            editBox.Hide = function(self) origHide(self); self:Show() end
        end

        -- Hide content when focus lost
        if editBox == primaryEditBox and not editBox.__EzroUIContentHooked then
            editBox.__EzroUIContentHooked = true
            local function SetContentVisible(self, vis)
                if not self.__EzroUITextColor then
                    local r, g, b, a = self:GetTextColor()
                    self.__EzroUITextColor = { r or 1, g or 1, b or 1, a or 1 }
                end
                local tc = self.__EzroUITextColor
                self:SetTextColor(tc[1], tc[2], tc[3], vis and tc[4] or 0)
                for _, n in ipairs({ "Prompt","Header","HeaderSuffix","LanguageHeader","NewcomerHint",
                                     "FocusLeft","FocusMid","FocusRight" }) do
                    local f = self[n] or self[n:lower()]
                    if f and f.SetAlpha then f:SetAlpha(vis and 1 or 0) end
                end
            end
            SetContentVisible(editBox, editBox:HasFocus())
            editBox:HookScript("OnEditFocusGained", function(self) SetContentVisible(self, true) end)
            editBox:HookScript("OnEditFocusLost",   function(self) SetContentVisible(self, false) end)
            editBox:HookScript("OnShow", function(self) SetContentVisible(self, self:HasFocus()) end)
        end
    end

    -- ---- Font strings ---------------------------------------
    ApplyFontToAllStrings(chatFrame)
    if chatFrame.AddMessage then
        hooksecurefunc(chatFrame, "AddMessage", function(self, ...)
            C_Timer.After(0, function() ApplyFontToAllStrings(self) end)
        end)
    end

    -- ---- Button / scroll frame ------------------------------
    if chatFrame.buttonFrame then chatFrame.buttonFrame:Hide() end
    if chatFrame.ScrollBar   and chatFrame.ScrollBar.SetBackdrop then
        chatFrame.ScrollBar:SetBackdrop(nil)
    end

    -- ---- Selection highlight alpha --------------------------
    local sel = chatFrame.Selection
    if sel then
        if sel.Center          then sel.Center:SetAlpha(0.3) end
        if sel.MouseOverHighlight then sel.MouseOverHighlight:SetAlpha(0.3) end
    end

    -- ---- Copy button ----------------------------------------
    if c.copyButton then
        Chat:AddCopyButton(chatFrame)
    end

    -- ---- Tab skinning ---------------------------------------
    SkinAllTabs()

    -- ---- Chat fade ------------------------------------------
    SetupChatFade(chatFrame)

    -- ---- Scrollbar auto-hide --------------------------------
    SetupScrollbarAutoHide(chatFrame)

    -- ---- Sticky channels ------------------------------------
    SetupStickyChannels(chatFrame)
end

-- ============================================================
--  COPY BUTTON (per frame)
-- ============================================================
function Chat:AddCopyButton(chatFrame)
    if not chatFrame or chatFrame.__EzroUICopyBtn then return end
    chatFrame.__EzroUICopyBtn = true

    local btn = CreateFrame("Button", nil, chatFrame)
    btn:SetSize(14, 14)
    btn:SetPoint("TOPRIGHT", chatFrame, "TOPRIGHT", -2, -2)
    btn:SetAlpha(0)

    local tex = btn:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    btn.tex = tex

    btn:SetScript("OnClick", function() ShowCopyFrame(chatFrame) end)
    btn:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
    btn:SetScript("OnLeave", function(self) self:SetAlpha(0) end)

    -- show faintly on chatFrame hover
    chatFrame:HookScript("OnEnter", function() btn:SetAlpha(0.6) end)
    chatFrame:HookScript("OnLeave", function() btn:SetAlpha(0) end)
end

-- ============================================================
--  SKIN ALL / HOOKS / REFRESH
-- ============================================================
function Chat:SkinAllChatFrames()
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local cf = _G["ChatFrame"..i]
        if cf then
            cf.__EzroUIIndex = i
            self:SkinChatFrame(cf)
        end
    end
    if DEFAULT_CHAT_FRAME then
        self:SkinChatFrame(DEFAULT_CHAT_FRAME)
    end
    SkinAllTabs()
end

function Chat:HookChatFrameCreation()
    local function ReSkinAll()
        C_Timer.After(0.1, function() Chat:SkinAllChatFrames() end)
    end
    if FCF_OpenNewWindow    then hooksecurefunc("FCF_OpenNewWindow",    ReSkinAll) end
    if FCF_OpenTemporaryWindow then hooksecurefunc("FCF_OpenTemporaryWindow", ReSkinAll) end
    if FCF_SelectDockFrame  then
        hooksecurefunc("FCF_SelectDockFrame", function(cf)
            C_Timer.After(0.1, function()
                if cf then Chat:SkinChatFrame(cf) end
                Chat:SkinAllChatFrames()
            end)
        end)
    end
    if FCF_DockFrame then
        hooksecurefunc("FCF_DockFrame", function(cf)
            C_Timer.After(0.1, function() if cf then Chat:SkinChatFrame(cf) end end)
        end)
    end
    C_Timer.NewTicker(2.0, function() Chat:SkinAllChatFrames() end)
end

-- ============================================================
--  MESSAGE FILTER HOOKS  (timestamps, class colors, URLs, spam)
-- ============================================================
function Chat:HookMessageFilters()
    -- We hook AddMessage on every chat frame to transform text before display
    local function TransformMessage(self, text, r, g, b, id, ...)
        -- text transformations are done via ChatFrame_AddMessageEventFilter
        -- which is the proper API for this
    end

    -- Use the official Blizzard filter API
    -- Filters receive (self, event, message, sender, ...) and return (shouldBlock, newMessage, ...)
    local function EzroFilter(self, event, message, sender, language, channelString,
                               playerName2, specialFlags, zoneChannelID, channelIndex,
                               channelName, unknown, lineID, guid, bnSenderID, isMobile,
                               isSubtitle, hideSenderInLetterbox, supressRaidIcons)

        local c = cfg()
        if not c or not c.enabled then return false end

        -- Cache class for sender
        if sender and guid then
            local _, _, classFileName = GetPlayerInfoByGUID(guid)
            if classFileName then CacheNameClass(sender, classFileName) end
        end

        -- Spam filter
        if IsSpam(event, sender, message) then
            return true  -- block
        end

        local newMessage = message

        -- Short channel names
        newMessage = ShortenChannel(newMessage)

        -- URL highlighting
        newMessage = HighlightURLs(newMessage)

        -- Class-color sender name in the message body
        -- (sender replacement in the message text)
        if sender and sender ~= "" then
            local c2 = cfg()
            if c2 and c2.classColoredNames then
                local coloredSender = ColorName(sender, nil)
                if coloredSender ~= sender then
                    newMessage = newMessage:gsub(
                        "|H(.-)|h%[" .. sender:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1") .. "%]|h",
                        function(link)
                            return "|H"..link.."|h["..coloredSender.."]|h"
                        end
                    )
                end
            end
        end

        -- Timestamp prepend
        if c.timestamps then
            local ts = BuildTimestamp()
            newMessage = ts .. newMessage
        end

        if newMessage ~= message then
            return false, newMessage, sender, language, channelString, playerName2,
                   specialFlags, zoneChannelID, channelIndex, channelName, unknown,
                   lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox,
                   supressRaidIcons
        end
        return false
    end

    -- Register filter for common chat event types
    local events = {
        "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
        "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_RAID_WARNING", "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
        "CHAT_MSG_BATTLEGROUND", "CHAT_MSG_BATTLEGROUND_LEADER",
        "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
        "CHAT_MSG_CHANNEL", "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE", "CHAT_MSG_SYSTEM",
    }
    for _, ev in ipairs(events) do
        ChatFrame_AddMessageEventFilter(ev, EzroFilter)
    end

    -- Cache classes from GUID-bearing events
    local classEvents = { "CHAT_MSG_SAY","CHAT_MSG_YELL","CHAT_MSG_PARTY",
                          "CHAT_MSG_PARTY_LEADER","CHAT_MSG_RAID","CHAT_MSG_RAID_LEADER",
                          "CHAT_MSG_GUILD","CHAT_MSG_WHISPER" }
    for _, ev in ipairs(classEvents) do
        EzroUI:RegisterEvent(ev, function(_, event, msg, sender, _, _, _, _, _, _, _, _, _, guid)
            if guid and sender then
                local _, _, classFileName = GetPlayerInfoByGUID(guid)
                if classFileName then CacheNameClass(sender, classFileName) end
            end
        end)
    end
end

-- ============================================================
--  QUICK JOIN TOAST BUTTON
-- ============================================================
local function ApplyQuickJoinOffset(button, offsetX, offsetY)
    if not button then return end
    local point, relativeTo, relativePoint, xOfs, yOfs = button:GetPoint(1)
    if not point or not relativeTo then return end

    if not button.__EzroUIBaseAnchor or button.__EzroUIBaseAnchor.relativeTo ~= relativeTo then
        local curX = button.__EzroUILastOffsetX or 0
        local curY = button.__EzroUILastOffsetY or 0
        button.__EzroUIBaseAnchor = {
            point = point, relativeTo = relativeTo,
            relativePoint = relativePoint or point,
            xOfs = (xOfs or 0) - curX, yOfs = (yOfs or 0) - curY,
        }
    end
    local base = button.__EzroUIBaseAnchor
    local lastX = button.__EzroUILastOffsetX or 0
    local lastY = button.__EzroUILastOffsetY or 0
    button.__EzroUILastOffsetX = offsetX
    button.__EzroUILastOffsetY = offsetY
    if offsetX ~= lastX or offsetY ~= lastY
       or math.abs((xOfs or 0) - (base.xOfs + offsetX)) > 0.1
       or math.abs((yOfs or 0) - (base.yOfs + offsetY)) > 0.1 then
        button:ClearAllPoints()
        button:SetPoint(base.point, base.relativeTo, base.relativePoint,
                        base.xOfs + offsetX, base.yOfs + offsetY)
    end
end

function Chat:UpdateQuickJoinToastButton()
    local c = cfg()
    if not c then return end
    local qb = _G.QuickJoinToastButton
    if not qb then return end

    if c.hideQuickJoinToastButton then
        qb:Hide()
        if not qb.__EzroUIHideHooked then
            qb.__EzroUIHideHooked = true
            qb:HookScript("OnShow", function(self)
                if (EzroUI.db.profile.chat or {}).hideQuickJoinToastButton then
                    self:Hide()
                end
            end)
        end
    end

    local ox = c.quickJoinToastButtonOffsetX or 31
    local oy = c.quickJoinToastButtonOffsetY or -23
    if not qb.__EzroUISetPointHooked then
        qb.__EzroUISetPointHooked = true
        hooksecurefunc(qb, "SetPoint", function(self)
            self.__EzroUIBaseAnchor = nil
            C_Timer.After(0, function()
                local c2 = EzroUI.db.profile.chat
                if c2 and not c2.hideQuickJoinToastButton then
                    ApplyQuickJoinOffset(self, c2.quickJoinToastButtonOffsetX or 31,
                                               c2.quickJoinToastButtonOffsetY or -23)
                end
            end)
        end)
        if not qb.__EzroUIShowHooked then
            qb.__EzroUIShowHooked = true
            qb:HookScript("OnShow", function(self)
                C_Timer.After(0.1, function()
                    local c2 = EzroUI.db.profile.chat
                    if c2 and not c2.hideQuickJoinToastButton then
                        ApplyQuickJoinOffset(self, c2.quickJoinToastButtonOffsetX or 31,
                                                   c2.quickJoinToastButtonOffsetY or -23)
                    end
                end)
            end)
        end
    end
    if not c.hideQuickJoinToastButton and qb:GetPoint(1) then
        ApplyQuickJoinOffset(qb, ox, oy)
    end
end

-- ============================================================
--  EDIT MODE / CLAMP DISABLE
-- ============================================================
function Chat:DisableChatFrameClamping()
    local function Disable(frame)
        if not frame then return end
        if frame.SetClampedToScreen and not frame.__EzroUIClampDisabled then
            frame.__EzroUIClampDisabled = true
            frame:SetClampedToScreen(false)
            frame:HookScript("OnShow", function(self)
                if self.SetClampedToScreen then self:SetClampedToScreen(false) end
            end)
        end
    end
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local cf = _G["ChatFrame"..i]
        Disable(cf)
        if cf and cf.Background then Disable(cf.Background) end
    end
    Disable(DEFAULT_CHAT_FRAME)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.Background then
        Disable(DEFAULT_CHAT_FRAME.Background)
    end
end

function Chat:SetChatSelectionAlpha()
    local function SetAlpha(sel)
        if not sel then return end
        local items = { sel.Center, sel.MouseOverHighlight }
        for _, item in ipairs(items) do
            if item then
                item:SetAlpha(0.3)
                if not item.__EzroUIAlphaHooked then
                    item.__EzroUIAlphaHooked = true
                    item:HookScript("OnShow", function(self) self:SetAlpha(0.3) end)
                end
            end
        end
    end
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local cf = _G["ChatFrame"..i]
        if cf then SetAlpha(cf.Selection) end
    end
    if DEFAULT_CHAT_FRAME then SetAlpha(DEFAULT_CHAT_FRAME.Selection) end
end

-- ============================================================
--  REFRESH ALL
-- ============================================================
function Chat:RefreshAll()
    -- Clear skinned flags so everything re-skins with new settings
    local function ClearFlags(frame)
        if not frame then return end
        frame.__EzroUISkinned         = nil
        frame.__EzroUIClampDisabled   = nil
        frame.__EzroUIFadeSetup       = nil
        frame.__EzroUIScrollbarSetup  = nil
        frame.__EzroUICopyBtn         = nil
        frame.__EzroUITabSkinned      = nil
        if frame.Background then
            frame.Background.__EzroUIClampDisabled = nil
        end
    end
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        ClearFlags(_G["ChatFrame"..i])
        local tab = _G["ChatFrame"..i.."Tab"]
        if tab then tab.__EzroUITabSkinned = nil end
    end
    ClearFlags(DEFAULT_CHAT_FRAME)

    -- Restore fade for disabled state
    if not (cfg() or {}).fadingChat then
        for i = 1, NUM_CHAT_WINDOWS or 10 do
            local cf = _G["ChatFrame"..i]
            if cf then TeardownChatFade(cf) end
        end
        if DEFAULT_CHAT_FRAME then TeardownChatFade(DEFAULT_CHAT_FRAME) end
    end

    self:SkinAllChatFrames()
    self:UpdateQuickJoinToastButton()
    self:DisableChatFrameClamping()
    SkinChatBubbles()
end

-- ============================================================
--  INITIALIZE
-- ============================================================
function Chat:Initialize()
    if self.initialized then return end
    self.initialized = true

    C_Timer.After(0.5, function()
        self:SkinAllChatFrames()
        self:HookChatFrameCreation()
        self:UpdateQuickJoinToastButton()
        self:DisableChatFrameClamping()
        self:HookMessageFilters()
        SkinChatBubbles()
    end)

    EzroUI:RegisterEvent("PLAYER_LOGIN", function()
        C_Timer.After(0.5, function()
            self:SkinAllChatFrames()
            self:UpdateQuickJoinToastButton()
            self:DisableChatFrameClamping()
            SkinChatBubbles()
        end)
    end)

    C_Timer.NewTicker(1.0, function() self:UpdateQuickJoinToastButton() end)

    -- Edit mode hooks
    if EditModeManagerFrame then
        local function OnEditModeEnter()
            C_Timer.After(0.1, function()
                self:DisableChatFrameClamping()
                self:SetChatSelectionAlpha()
            end)
        end
        if EditModeManagerFrame.RegisterCallback then
            EditModeManagerFrame:RegisterCallback("EditModeEnter", OnEditModeEnter)
        end
        if EditModeManagerFrame.HookScript then
            EditModeManagerFrame:HookScript("OnShow", OnEditModeEnter)
        end
        if EditModeManagerFrame.EnterEditMode then
            hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function()
                C_Timer.After(0.1, function() Chat:SetChatSelectionAlpha() end)
            end)
        end
    end

    C_Timer.NewTicker(2.0, function()
        self:DisableChatFrameClamping()
        self:SetChatSelectionAlpha()
    end)
end
