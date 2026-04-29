local ADDON_NAME, ns = ...
local EzroUI = ns.Addon

EzroUI.CharacterPanel = EzroUI.CharacterPanel or {}
local CharacterPanel = EzroUI.CharacterPanel

-- ======================================================================
-- CharacterPanelSkin – Flat reskin matching the /ezroui menu aesthetic.
--
--  • Flat dark backgrounds (bgDark/bgMedium/bgLight) from GUI.lua theme.
--  • Class-colour accent bar on active tab (left edge) + text tint.
--  • Quality-coloured 1px border around every item slot icon.
--  • Enchant-status dot (green = enchanted, red = missing) per eligible slot.
--  • Subtle red icon tint for unenchanted slots at max level.
--  • Right-panel (Attributes / Enhancements) skinning:
--      – Class-colour accented category headers.
--      – Alternating-row tint on every stat line.
--      – Styled scroll bar.
-- ======================================================================

local isMop = select(4, GetBuildInfo()) >= 50000 and select(4, GetBuildInfo()) < 60000

local GetInventoryItemLink    = GetInventoryItemLink
local GetInventoryItemQuality = (C_Item and C_Item.GetInventoryItemQuality)
                                    and C_Item.GetInventoryItemQuality
                                    or  GetInventoryItemQuality
local GetDetailedItemLevelInfo = (C_Item and C_Item.GetDetailedItemLevelInfo)
                                    and C_Item.GetDetailedItemLevelInfo
                                    or  GetDetailedItemLevelInfo
local UnitLevel               = UnitLevel
local GetExpansionForLevel    = GetExpansionForLevel

-- ---------- class colour (mirrors GUI.lua THEME.accent) -------------
local function GetClassColor()
    local _, class = UnitClass("player")
    if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return c.r, c.g, c.b
    end
    return 0.160, 0.700, 0.860   -- default teal fallback
end

-- ---------- shared palette (mirrors GUI.lua THEME) -------------------
local PAL = {}
do
    local cr, cg, cb = GetClassColor()
    PAL = {
        -- main backgrounds
        frameBg     = { 0.085, 0.095, 0.120, 0.97 },   -- bgDark
        headerBg    = { 0.115, 0.130, 0.155, 1.00 },   -- bgMedium
        headerSep   = { cr * 0.6, cg * 0.6, cb * 0.6, 0.80 },  -- dim class line
        outerBorder = { 0.080, 0.080, 0.090, 0.95 },   -- border
        insetBg     = { 0.065, 0.075, 0.095, 0.50 },   -- slightly lighter than frameBg

        -- tabs
        tabActive   = { 0.165, 0.180, 0.220, 1.00 },   -- bgLight
        tabInactive = { 0.085, 0.095, 0.120, 0.92 },   -- bgDark
        tabLine     = { cr, cg, cb, 1.00 },             -- class colour accent bar
        tabTextOn   = { cr, cg, cb, 1.00 },             -- class colour text when active
        tabTextOff  = { 0.72, 0.72, 0.78, 1.00 },       -- textDim

        -- category headers
        catBg       = { 0.115, 0.130, 0.155, 1.00 },   -- bgMedium
        catLine     = { cr, cg, cb, 0.80 },             -- class colour bottom sep
        catTopLine  = { 0.080, 0.080, 0.090, 0.90 },   -- border
        catText     = { cr, cg, cb, 1.00 },             -- class colour text

        -- stat rows
        rowOdd      = { 0.115, 0.130, 0.155, 0.30 },   -- bgMedium tinted
        rowEven     = { 0.085, 0.095, 0.120, 0.15 },   -- bgDark tinted
        statName    = { 0.72,  0.72,  0.78,  1.00 },   -- textDim
        statValue   = { 0.96,  0.96,  0.98,  1.00 },   -- text

        -- scroll bar
        scrollTrack = { 0.065, 0.075, 0.095, 0.90 },
        scrollThumb = { cr * 0.5, cg * 0.5, cb * 0.5, 1.00 },  -- class colour half-bright
    }
end

-- ---------- quality colours (r, g, b) --------------------------------
local QUALITY_COLORS = {
    [0] = { 0.62, 0.62, 0.62 },
    [1] = { 0.78, 0.78, 0.78 },
    [2] = { 0.12, 1.00, 0.00 },
    [3] = { 0.00, 0.44, 0.87 },
    [4] = { 0.64, 0.21, 0.93 },
    [5] = { 1.00, 0.50, 0.00 },
    [6] = { 0.90, 0.80, 0.50 },
    [7] = { 0.00, 0.80, 1.00 },
}

-- ---------- slots we show on the character frame ----------------------
local CHARACTER_SLOTS = {
    "CharacterHeadSlot",
    "CharacterNeckSlot",
    "CharacterShoulderSlot",
    "CharacterBackSlot",
    "CharacterChestSlot",
    "CharacterWristSlot",
    "CharacterHandsSlot",
    "CharacterWaistSlot",
    "CharacterLegsSlot",
    "CharacterFeetSlot",
    "CharacterFinger0Slot",
    "CharacterFinger1Slot",
    "CharacterTrinket0Slot",
    "CharacterTrinket1Slot",
    "CharacterMainHandSlot",
    "CharacterSecondaryHandSlot",
}

-- ---------- enchantable slot tables per expansion --------------------
local ENCHANTABLE_BY_EXPANSION = {
    [10] = {
        [INVSLOT_HEAD]     = true,
        [INVSLOT_SHOULDER] = true,
        [INVSLOT_BACK]     = true,
        [INVSLOT_CHEST]    = true,
        [INVSLOT_WRIST]    = true,
        [INVSLOT_LEGS]     = true,
        [INVSLOT_FEET]     = true,
        [INVSLOT_MAINHAND] = true,
        [INVSLOT_FINGER1]  = true,
        [INVSLOT_FINGER2]  = true,
    },
    [9] = {
        [INVSLOT_HEAD]     = true,
        [INVSLOT_SHOULDER] = true,
        [INVSLOT_BACK]     = true,
        [INVSLOT_CHEST]    = true,
        [INVSLOT_WRIST]    = true,
        [INVSLOT_WAIST]    = true,
        [INVSLOT_LEGS]     = true,
        [INVSLOT_FEET]     = true,
        [INVSLOT_MAINHAND] = true,
        [INVSLOT_FINGER1]  = true,
        [INVSLOT_FINGER2]  = true,
    },
}
local DEFAULT_ENCHANTABLE = {
    [INVSLOT_HEAD]     = true,
    [INVSLOT_SHOULDER] = true,
    [INVSLOT_BACK]     = true,
    [INVSLOT_CHEST]    = true,
    [INVSLOT_WRIST]    = true,
    [INVSLOT_WAIST]    = true,
    [INVSLOT_LEGS]     = true,
    [INVSLOT_FEET]     = true,
    [INVSLOT_MAINHAND] = true,
    [INVSLOT_OFFHAND]  = true,
    [INVSLOT_FINGER1]  = true,
    [INVSLOT_FINGER2]  = true,
}
-- MoP has a simpler, fixed set
local MOP_ENCHANTABLE = {
    [INVSLOT_SHOULDER] = true,
    [INVSLOT_BACK]     = true,
    [INVSLOT_CHEST]    = true,
    [INVSLOT_WRIST]    = true,
    [INVSLOT_LEGS]     = true,
    [INVSLOT_HAND]     = true,
    [INVSLOT_FEET]     = true,
    [INVSLOT_MAINHAND] = true,
    [INVSLOT_OFFHAND]  = true,
}

-- ---------- helpers --------------------------------------------------

local function LinkHasEnchant(link)
    if not link then return false end
    local enchantId = link:match("item:%d+:(%d+):")
    return enchantId and enchantId ~= "" and enchantId ~= "0"
end

local function CanSlotBeEnchanted(unit, slot)
    if isMop then
        return MOP_ENCHANTABLE[slot] or false
    end
    local expansion = GetExpansionForLevel and GetExpansionForLevel(UnitLevel(unit))
    local tbl = (expansion and ENCHANTABLE_BY_EXPANSION[expansion]) or DEFAULT_ENCHANTABLE
    return tbl[slot] or false
end

-- Zero-out every Texture region on a frame (strips Blizzard art).
local function HideFrameTextures(frame)
    if not frame then return end
    local ok, numRegions = pcall(frame.GetNumRegions, frame)
    if not ok then return end
    for i = 1, numRegions do
        local region = select(i, frame:GetRegions())
        if region then
            local typeOk, isTexture = pcall(region.IsObjectType, region, "Texture")
            if typeOk and isTexture then
                pcall(region.SetAlpha, region, 0)
            end
        end
    end
end

-- Count FontStrings and Textures among a frame's regions.
local function CountRegionTypes(frame)
    local fs, tx = 0, 0
    local ok, n = pcall(frame.GetNumRegions, frame)
    if not ok then return fs, tx end
    for i = 1, n do
        local r = select(i, frame:GetRegions())
        if r then
            local ok2, isFS = pcall(r.IsObjectType, r, "FontString")
            if ok2 and isFS then fs = fs + 1 end
            local ok3, isTX = pcall(r.IsObjectType, r, "Texture")
            if ok3 and isTX then tx = tx + 1 end
        end
    end
    return fs, tx
end

-- ======================================================================
-- CHARACTER FRAME SHELL RESKIN
-- ======================================================================

local function SkinCharacterFrame()
    if not CharacterFrame or CharacterFrame._EzroSkinned then return end
    CharacterFrame._EzroSkinned = true

    -- Strip all Blizzard art
    pcall(function() if CharacterFrame.NineSlice then CharacterFrame.NineSlice:Hide() end end)
    HideFrameTextures(CharacterFrame)

    -- Hide portrait / class model – without its ring art it looks cropped
    pcall(function()
        for _, name in ipairs({ "CharacterFramePortrait", "CharacterFramePortraitFrame",
                                 "CharacterPortraitFrame", "CharacterFrameClassPortrait" }) do
            local f = _G[name]
            if f then f:Hide() end
        end
        if CharacterFrame.portrait then CharacterFrame.portrait:Hide() end
        if CharacterFrame.Portrait then CharacterFrame.Portrait:Hide() end
    end)

    -- Flat dark background (bgDark)
    local bg = CharacterFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetAllPoints()
    bg:SetColorTexture(PAL.frameBg[1], PAL.frameBg[2], PAL.frameBg[3], PAL.frameBg[4])

    -- Slightly lighter title-bar strip (bgMedium)
    local hdrBg = CharacterFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
    hdrBg:SetPoint("TOPLEFT",  CharacterFrame, "TOPLEFT",   1, -1)
    hdrBg:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -1, -1)
    hdrBg:SetHeight(26)
    hdrBg:SetColorTexture(PAL.headerBg[1], PAL.headerBg[2], PAL.headerBg[3], PAL.headerBg[4])

    -- Class-colour accent line below the title bar
    local hdrSep = CharacterFrame:CreateTexture(nil, "BACKGROUND", nil, -6)
    hdrSep:SetPoint("TOPLEFT",  CharacterFrame, "TOPLEFT",   1, -27)
    hdrSep:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -1, -27)
    hdrSep:SetHeight(1)
    hdrSep:SetColorTexture(PAL.headerSep[1], PAL.headerSep[2], PAL.headerSep[3], PAL.headerSep[4])

    -- Thin 1px border using border colour (not heavy)
    local border = CreateFrame("Frame", nil, CharacterFrame, "BackdropTemplate")
    border:SetAllPoints()
    border:SetFrameLevel(CharacterFrame:GetFrameLevel())
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    border:SetBackdropBorderColor(PAL.outerBorder[1], PAL.outerBorder[2], PAL.outerBorder[3], PAL.outerBorder[4])

    -- Title text: use GUI text colour (near-white)
    pcall(function()
        if CharacterFrameTitleText then
            CharacterFrameTitleText:SetTextColor(0.96, 0.96, 0.98, 1)
        end
    end)

    -- Left inset (item slot area)
    pcall(function()
        local inset = CharacterFrameInset
        if inset then
            pcall(function() if inset.NineSlice then inset.NineSlice:Hide() end end)
            HideFrameTextures(inset)
            local ibg = inset:CreateTexture(nil, "BACKGROUND", nil, -8)
            ibg:SetAllPoints()
            ibg:SetColorTexture(PAL.insetBg[1], PAL.insetBg[2], PAL.insetBg[3], PAL.insetBg[4])
        end
    end)

    -- Right inset (stats/enhancements) base background
    pcall(function()
        local insetRight = CharacterFrameInsetRight
        if insetRight then
            pcall(function() if insetRight.NineSlice then insetRight.NineSlice:Hide() end end)
            HideFrameTextures(insetRight)
            if not insetRight._EzroBg then
                insetRight._EzroBg = true
                local rbg = insetRight:CreateTexture(nil, "BACKGROUND", nil, -8)
                rbg:SetAllPoints()
                rbg:SetColorTexture(PAL.insetBg[1], PAL.insetBg[2], PAL.insetBg[3], PAL.insetBg[4])
            end
        end
    end)
end

-- ======================================================================
-- TAB BUTTON SKINNING  (mirrors GUI.lua CreateTabButton)
-- ======================================================================

local function SkinTabButton(tab)
    if not tab or tab._EzroTabSkin then return end
    tab._EzroTabSkin = true

    -- Strip Blizzard textures
    pcall(function()
        for _, k in ipairs({ "Left","Middle","Right",
                             "LeftActive","MiddleActive","RightActive",
                             "LeftDisabled","MiddleDisabled","RightDisabled",
                             "LeftHighlight","MiddleHighlight","RightHighlight" }) do
            if tab[k] then tab[k]:SetAlpha(0) end
        end
        if tab.NineSlice then tab.NineSlice:Hide() end
    end)
    HideFrameTextures(tab)

    -- Flat background (bgDark by default)
    local bg = tab:CreateTexture(nil, "BACKGROUND", nil, -2)
    bg:SetAllPoints()
    bg:SetColorTexture(PAL.tabInactive[1], PAL.tabInactive[2], PAL.tabInactive[3], PAL.tabInactive[4])
    tab._EzroBg = bg

    -- Hover highlight layer (bgLight, hidden by default)
    local hi = tab:CreateTexture(nil, "BORDER", nil, -1)
    hi:SetAllPoints()
    hi:SetColorTexture(PAL.tabActive[1], PAL.tabActive[2], PAL.tabActive[3], 0.35)
    hi:Hide()
    tab._EzroHi = hi

    -- Left-edge class-colour accent bar (2px, shown when active)
    local accentBar = tab:CreateTexture(nil, "ARTWORK", nil, 1)
    accentBar:SetWidth(2)
    accentBar:SetPoint("TOPLEFT",    tab, "TOPLEFT",    0, 0)
    accentBar:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
    accentBar:SetColorTexture(PAL.tabLine[1], PAL.tabLine[2], PAL.tabLine[3], 1)
    accentBar:Hide()
    tab._EzroLine = accentBar

    -- Text colour
    pcall(function()
        local text = tab.Text or (tab.GetFontString and tab:GetFontString())
        if text then text:SetTextColor(PAL.tabTextOff[1], PAL.tabTextOff[2], PAL.tabTextOff[3], 1) end
    end)

    -- Hover scripts
    tab:HookScript("OnEnter", function(self)
        if not self._EzroActive then self._EzroHi:Show() end
    end)
    tab:HookScript("OnLeave", function(self)
        if not self._EzroActive then self._EzroHi:Hide() end
    end)
end

local function SetTabActive(tab, active)
    if not tab or not tab._EzroTabSkin then return end
    tab._EzroActive = active
    if active then
        tab._EzroBg:SetColorTexture(PAL.tabActive[1], PAL.tabActive[2], PAL.tabActive[3], PAL.tabActive[4])
        tab._EzroHi:Show()
        tab._EzroLine:Show()
        pcall(function()
            local t = tab.Text or (tab.GetFontString and tab:GetFontString())
            if t then t:SetTextColor(PAL.tabTextOn[1], PAL.tabTextOn[2], PAL.tabTextOn[3], 1) end
        end)
    else
        tab._EzroBg:SetColorTexture(PAL.tabInactive[1], PAL.tabInactive[2], PAL.tabInactive[3], PAL.tabInactive[4])
        tab._EzroHi:Hide()
        tab._EzroLine:Hide()
        pcall(function()
            local t = tab.Text or (tab.GetFontString and tab:GetFontString())
            if t then t:SetTextColor(PAL.tabTextOff[1], PAL.tabTextOff[2], PAL.tabTextOff[3], 1) end
        end)
    end
end

local function RefreshTabStates()
    if not CharacterFrame then return end
    local selected = PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(CharacterFrame) or 1
    for i = 1, 8 do
        local tab = _G["CharacterFrameTab" .. i]
        if not tab then break end
        SetTabActive(tab, i == selected)
    end
end

local function SkinAllTabs()
    for i = 1, 8 do
        local tab = _G["CharacterFrameTab" .. i]
        if not tab then break end
        SkinTabButton(tab)
        if not tab._EzroTabHook then
            tab._EzroTabHook = true
            pcall(function()
                tab:HookScript("OnClick", function()
                    C_Timer.After(0.02, RefreshTabStates)
                    -- WoW may reposition the frame on tab switch; re-apply saved pos
                    C_Timer.After(0.15, RestoreCharacterFramePos)
                end)
            end)
        end
    end
    C_Timer.After(0.05, RefreshTabStates)
end

-- ======================================================================
-- RIGHT PANEL: STATS / ATTRIBUTES / ENHANCEMENTS
-- ======================================================================

local function SkinScrollBar(sb)
    if not sb or sb._EzroSBSkin then return end
    sb._EzroSBSkin = true
    pcall(function()
        HideFrameTextures(sb)
        local track = sb:CreateTexture(nil, "BACKGROUND", nil, -2)
        track:SetAllPoints()
        track:SetColorTexture(PAL.scrollTrack[1], PAL.scrollTrack[2], PAL.scrollTrack[3], PAL.scrollTrack[4])
    end)
    pcall(function()
        local thumb = sb.ThumbTexture or sb.thumb or _G[(sb:GetName() or "") .. "ThumbTexture"]
        if thumb then
            -- Class-colour half-bright thumb
            thumb:SetColorTexture(PAL.scrollThumb[1], PAL.scrollThumb[2], PAL.scrollThumb[3], PAL.scrollThumb[4])
        end
    end)
    pcall(function()
        local up   = sb.ScrollUpButton   or _G[(sb:GetName() or "") .. "ScrollUpButton"]
        local down = sb.ScrollDownButton or _G[(sb:GetName() or "") .. "ScrollDownButton"]
        if up   then HideFrameTextures(up)   end
        if down then HideFrameTextures(down) end
    end)
end

-- Style a stats-pane category header (e.g. "ATTRIBUTES", "ENHANCEMENTS").
local function SkinCategoryHeader(frame)
    if not frame or frame._EzroCatSkin then return end
    frame._EzroCatSkin = true

    -- bgMedium background
    local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -2)
    bg:SetAllPoints()
    bg:SetColorTexture(PAL.catBg[1], PAL.catBg[2], PAL.catBg[3], PAL.catBg[4])

    -- Class-colour left accent bar (2px, matching GUI sidebar active state)
    local accentBar = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    accentBar:SetWidth(2)
    accentBar:SetPoint("TOPLEFT",    frame, "TOPLEFT",    0, 0)
    accentBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    accentBar:SetColorTexture(PAL.catLine[1], PAL.catLine[2], PAL.catLine[3], PAL.catLine[4])

    -- Top hairline (border colour)
    local topLine = frame:CreateTexture(nil, "BACKGROUND", nil, -3)
    topLine:SetHeight(1)
    topLine:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, 0)
    topLine:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    topLine:SetColorTexture(PAL.catTopLine[1], PAL.catTopLine[2], PAL.catTopLine[3], PAL.catTopLine[4])

    -- Class-colour text + outline
    pcall(function()
        local ok, n = pcall(frame.GetNumRegions, frame)
        if not ok then return end
        for i = 1, n do
            local r = select(i, frame:GetRegions())
            local ok2, isFS = pcall(r.IsObjectType, r, "FontString")
            if ok2 and isFS then
                r:SetTextColor(PAL.catText[1], PAL.catText[2], PAL.catText[3], 1)
                local path, size = r:GetFont()
                if path and size then r:SetFont(path, size, "OUTLINE") end
            end
        end
    end)
end

-- Style an individual stat row.  Guards only the background creation; text
-- colours are always re-applied so recycled frames stay correctly coloured.
local function SkinStatRow(frame, rowIndex)
    if not frame then return end

    local c = (rowIndex and rowIndex % 2 == 0) and PAL.rowEven or PAL.rowOdd

    if not frame._EzroStatSkin then
        frame._EzroStatSkin = true
        local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -4)
        bg:SetAllPoints()
        bg:SetColorTexture(c[1], c[2], c[3], c[4])
        frame._EzroStatBg = bg
    elseif frame._EzroStatBg then
        frame._EzroStatBg:SetColorTexture(c[1], c[2], c[3], c[4])
    end

    -- Always re-apply text colours (frames may be recycled for different stats)
    pcall(function()
        local ok, n = pcall(frame.GetNumRegions, frame)
        if not ok then return end
        local fontStrings = {}
        for i = 1, n do
            local r = select(i, frame:GetRegions())
            local ok2, isFS = pcall(r.IsObjectType, r, "FontString")
            if ok2 and isFS then table.insert(fontStrings, r) end
        end
        table.sort(fontStrings, function(a, b)
            local _, _, _, ax = pcall(a.GetPoint, a, 1)
            local _, _, _, bx = pcall(b.GetPoint, b, 1)
            return (type(ax) == "number" and ax or 0) < (type(bx) == "number" and bx or 0)
        end)
        for idx, r in ipairs(fontStrings) do
            if idx == 1 then
                r:SetTextColor(PAL.statName[1],  PAL.statName[2],  PAL.statName[3],  1)
            else
                r:SetTextColor(PAL.statValue[1], PAL.statValue[2], PAL.statValue[3], 1)
            end
        end
    end)
end

-- Walk a frame tree and skin category headers and stat rows.
-- Depth limit of 6 handles Midnight's ScrollBox nesting:
--   InsetRight → StatsPane → ScrollFrame → scrollChild → rows (depth 4-5)
local function ScanAndSkinChildren(parent, rowCounter, depth)
    if not parent or depth > 6 then return rowCounter end
    local ok, n = pcall(parent.GetNumChildren, parent)
    if not ok or n == 0 then return rowCounter end

    for i = 1, n do
        local child = select(i, parent:GetChildren())
        if child then
            local h  = child:GetHeight()
            local w  = child:GetWidth()
            local fs = CountRegionTypes(child)
            local ok2, nc = pcall(child.GetNumChildren, child)
            local numChildren = ok2 and nc or 0

            if w > 40 then
                -- Category header: wider range to catch Midnight ~18px headers
                if h >= 14 and h <= 50 and fs >= 1 and numChildren == 0 then
                    SkinCategoryHeader(child)
                elseif h >= 8 and h < 30 and fs >= 1 and numChildren <= 2 then
                    rowCounter = rowCounter + 1
                    SkinStatRow(child, rowCounter)
                elseif numChildren > 0 then
                    rowCounter = ScanAndSkinChildren(child, rowCounter, depth + 1)
                end
            elseif numChildren > 0 then
                -- Narrow container – still recurse (could be a scroll child wrapper)
                rowCounter = ScanAndSkinChildren(child, rowCounter, depth + 1)
            end
        end
    end
    return rowCounter
end

-- Skin a scroll pane and its visible content.
local function SkinScrollPane(pane)
    if not pane then return end

    if not pane._EzroPaneBg then
        pane._EzroPaneBg = true
        local bg = pane:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetAllPoints()
        bg:SetColorTexture(0.03, 0.03, 0.05, 0.35)
    end

    pcall(function()
        local sb = pane.ScrollBar or _G[(pane:GetName() or "") .. "ScrollBar"]
        if sb then SkinScrollBar(sb) end
    end)

    local scrollChild
    pcall(function() scrollChild = pane:GetScrollChild() end)
    -- Midnight uses ScrollBox which wraps an inner ScrollFrame
    if not scrollChild then
        pcall(function()
            if pane.ScrollFrame then
                scrollChild = pane.ScrollFrame:GetScrollChild()
            end
        end)
    end
    if not scrollChild then
        pcall(function()
            if pane.scrollFrame then
                scrollChild = pane.scrollFrame:GetScrollChild()
            end
        end)
    end
    if scrollChild then
        ScanAndSkinChildren(scrollChild, 0, 1)
        return
    end
    ScanAndSkinChildren(pane, 0, 1)
end

local rightPanelHookSet = false

local function SkinRightPanel()
    SkinAllTabs()

    -- Try all known stats-pane names across WoW versions (incl. Midnight ScrollBox names)
    for _, paneName in ipairs({
        "CharacterStatsPane", "CharacterAttributesPane",
        "CharacterEnhancementsPane", "PaperDollSidebarFrame",
        "PaperDollFrame",
    }) do
        local pane = _G[paneName]
        if pane then SkinScrollPane(pane) end
    end

    -- Legacy explicit frame names
    for i = 1, 20 do
        local cat = _G["PaperDollStatCategory" .. i] or _G["CharacterStatCategory" .. i]
        if cat then SkinCategoryHeader(cat) end
        local row = _G["PaperDollStatFrame" .. i]
        if row then SkinStatRow(row, i) end
    end

    -- Deep scan of the right inset to catch any pane not found by name
    if CharacterFrameInsetRight then
        ScanAndSkinChildren(CharacterFrameInsetRight, 0, 1)
    end

    if not rightPanelHookSet then
        rightPanelHookSet = true

        if PaperDollFrame_SetStat then
            hooksecurefunc("PaperDollFrame_SetStat", function(statFrame)
                if statFrame and not statFrame._EzroStatSkin then
                    SkinStatRow(statFrame, 1)
                end
            end)
        end

        if PaperDollFrame_UpdateStats then
            hooksecurefunc("PaperDollFrame_UpdateStats", function()
                C_Timer.After(0.05, function()
                    if CharacterFrame and CharacterFrame:IsShown() then
                        SkinRightPanel()
                        UpdateIlvlColor()
                    end
                end)
            end)
        end

        -- Re-skin when each tab is clicked (switches between Attributes/Enhancements pages)
        for i = 1, 8 do
            local tab = _G["CharacterFrameTab" .. i]
            if not tab then break end
            if not tab._EzroRightHook then
                tab._EzroRightHook = true
                pcall(function()
                    tab:HookScript("OnClick", function()
                        C_Timer.After(0.08, function()
                            if CharacterFrame and CharacterFrame:IsShown() then
                                SkinRightPanel()
                            end
                        end)
                    end)
                end)
            end
        end
    end
end

-- ======================================================================
-- SLOT BUTTON SKINS  (quality border + enchant dot)
-- ======================================================================

local function SkinSlotButton(button)
    if button._EzroSkin then return end
    button._EzroSkin = true

    -- Quality-coloured 1px border frame around the button icon
    local borderFrame = CreateFrame("Frame", nil, button, "BackdropTemplate")
    borderFrame:SetPoint("TOPLEFT",     button, "TOPLEFT",     -2,  2)
    borderFrame:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT",  2, -2)
    borderFrame:SetFrameLevel(button:GetFrameLevel() + 5)
    borderFrame:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    borderFrame:SetBackdropBorderColor(0.18, 0.18, 0.22, 0.55)
    button._EzroBorderFrame = borderFrame

    -- Enchant-status dot (top-right corner of icon, 7×7 px square)
    local enchantDot = button:CreateTexture(nil, "OVERLAY", nil, 6)
    enchantDot:SetSize(7, 7)
    enchantDot:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
    enchantDot:SetTexture("Interface\\Buttons\\WHITE8x8")
    enchantDot:Hide()
    button._EzroEnchantDot = enchantDot

    -- Subtle red overlay for missing-enchant slots
    local dimOverlay = button:CreateTexture(nil, "OVERLAY", nil, 1)
    dimOverlay:SetAllPoints(button)
    dimOverlay:SetColorTexture(0.85, 0.0, 0.0, 0.0)
    button._EzroDimOverlay = dimOverlay
end

local function UpdateSlotButtonSkin(button, unit)
    unit = unit or "player"
    if not button._EzroSkin then SkinSlotButton(button) end

    local slot = button:GetID()
    if not slot or slot == 0 then return end

    local itemLink = GetInventoryItemLink(unit, slot)

    -- Quality border colour
    if button._EzroBorderFrame then
        if itemLink then
            local quality = GetInventoryItemQuality(unit, slot)
            local c = quality and QUALITY_COLORS[quality]
            if c then
                button._EzroBorderFrame:SetBackdropBorderColor(c[1], c[2], c[3], 0.88)
            else
                button._EzroBorderFrame:SetBackdropBorderColor(0.30, 0.30, 0.30, 0.70)
            end
        else
            button._EzroBorderFrame:SetBackdropBorderColor(0.15, 0.15, 0.18, 0.45)
        end
        button._EzroBorderFrame:Show()
    end

    -- Enchant dot + dim overlay
    if button._EzroEnchantDot and button._EzroDimOverlay then
        local isMaxLvl = IsLevelAtEffectiveMaxLevel
                         and IsLevelAtEffectiveMaxLevel(UnitLevel(unit))
        local canEnchant = CanSlotBeEnchanted(unit, slot)

        if itemLink and canEnchant and isMaxLvl then
            if LinkHasEnchant(itemLink) then
                button._EzroEnchantDot:SetVertexColor(0.20, 0.90, 0.20, 1)
                button._EzroEnchantDot:Show()
                button._EzroDimOverlay:SetColorTexture(0.85, 0.0, 0.0, 0.0)
            else
                button._EzroEnchantDot:SetVertexColor(0.90, 0.15, 0.15, 1)
                button._EzroEnchantDot:Show()
                button._EzroDimOverlay:SetColorTexture(0.85, 0.0, 0.0, 0.12)
            end
        else
            button._EzroEnchantDot:Hide()
            button._EzroDimOverlay:SetColorTexture(0.85, 0.0, 0.0, 0.0)
        end
    end
end

local function HideSlotButtonSkin(button)
    if not button._EzroSkin then return end
    if button._EzroBorderFrame then button._EzroBorderFrame:Hide() end
    if button._EzroEnchantDot  then button._EzroEnchantDot:Hide() end
    if button._EzroDimOverlay  then button._EzroDimOverlay:SetColorTexture(0, 0, 0, 0) end
end

-- ======================================================================
-- ITEM LEVEL TEXT COLOURING
-- ======================================================================

-- Map average equipped ilvl to a WoW item quality tier.
-- Thresholds are tuned for Midnight expansion where gear sits in the ~200-300 range.
local function GetIlvlQualityTier(ilvl)
    if     ilvl >= 290 then return 6   -- Artifact gold   (BiS / Mythic)
    elseif ilvl >= 272 then return 4   -- Epic     purple (Mythic raid / high keys)
    elseif ilvl >= 252 then return 3   -- Rare     blue   (Heroic / mid keys)
    elseif ilvl >= 226 then return 2   -- Uncommon green  (Normal / low keys)
    else                    return 1   -- Common   white
    end
end

-- Recursively search frame+children (capped at depth) for FontStrings whose
-- text looks like an item level number (integer OR decimal, e.g. "215" or "215.3")
-- in the range 100-999, and recolour them.
local function ColorIlvlFontStrings(frame, r, g, b, depth)
    if not frame or depth > 4 then return end
    pcall(function()
        local ok, n = pcall(frame.GetNumRegions, frame)
        if ok and n > 0 then
            for i = 1, n do
                local reg = select(i, frame:GetRegions())
                local ok2, isFS = pcall(reg.IsObjectType, reg, "FontString")
                if ok2 and isFS then
                    local txt = reg:GetText()
                    if txt then
                        -- match plain integer OR decimal ilvl (e.g. "215" or "215.3")
                        local num = tonumber(txt:match("^(%d+%.?%d*)$"))
                        if num and num >= 100 and num <= 999 then
                            reg:SetTextColor(r, g, b, 1)
                        end
                    end
                end
            end
        end
        local ok3, nc = pcall(frame.GetNumChildren, frame)
        if ok3 and nc > 0 then
            for i = 1, nc do
                local child = select(i, frame:GetChildren())
                if child then ColorIlvlFontStrings(child, r, g, b, depth + 1) end
            end
        end
    end)
end

local function UpdateIlvlColor()
    local _, equipped = GetAverageItemLevel and GetAverageItemLevel()
    if not equipped or equipped < 1 then return end
    local tier = GetIlvlQualityTier(math.floor(equipped))
    -- Use our own table so we never depend on GetItemQualityColor's return type
    local col  = QUALITY_COLORS[tier] or QUALITY_COLORS[1]
    local r, g, b = col[1], col[2], col[3]

    -- Try every known global FontString name for the ilvl display
    pcall(function()
        for _, candidate in ipairs({
            _G["PaperDollItemLevelText"],
            _G["PaperDollItemLevel"]      and _G["PaperDollItemLevel"].itemLevel,
            _G["PaperDollItemLevel"]      and _G["PaperDollItemLevel"].ItemLevel,
            _G["CharacterItemLevelText"],
            _G["CharacterStatFrameItemLevel"],
        }) do
            if candidate and type(candidate.SetTextColor) == "function" then
                candidate:SetTextColor(r, g, b, 1)
            end
        end
    end)

    -- Broad scan of the entire CharacterFrame tree (depth 6) so we find the
    -- ilvl FontString regardless of where Midnight puts it.
    if CharacterFrame then ColorIlvlFontStrings(CharacterFrame, r, g, b, 1) end
end

-- ======================================================================
-- FRAME MOVABILITY
-- ======================================================================

-- Saves the current CharacterFrame position into the AceDB profile.
local function SaveCharacterFramePos()
    if not EzroUI.db or not EzroUI.db.profile then return end
    EzroUI.db.profile.qol = EzroUI.db.profile.qol or {}
    local point, _, rp, x, y = CharacterFrame:GetPoint()
    if not point then return end
    EzroUI.db.profile.qol.characterPanelPos = {
        point = point,
        rp    = rp or point,
        x     = x  or 0,
        y     = y  or 0,
    }
end

-- Restores a previously saved CharacterFrame position from the AceDB profile.
-- SetUserPlaced(true) prevents WoW from resetting the position on next show.
local function RestoreCharacterFramePos()
    if not EzroUI.db or not EzroUI.db.profile then return end
    local qol = EzroUI.db.profile.qol
    if not qol then return end
    local pos = qol.characterPanelPos
    if not pos or not pos.point then return end
    CharacterFrame:ClearAllPoints()
    CharacterFrame:SetPoint(pos.point, UIParent, pos.rp or pos.point, pos.x or 0, pos.y or 0)
    pcall(function() CharacterFrame:SetUserPlaced(true) end)
end

-- Enables dragging on CharacterFrame (called once; guarded by _EzroMovable).
-- A transparent drag-handle is placed over the title bar because child frames
-- inside CharacterFrame would otherwise consume mouse events before they
-- reach the parent, making HookScript("OnDragStart") on CharacterFrame itself
-- unreliable.
local function MakeCharacterFrameMovable()
    if not CharacterFrame or CharacterFrame._EzroMovable then return end
    CharacterFrame._EzroMovable = true

    pcall(function() CharacterFrame:SetMovable(true) end)
    pcall(function() CharacterFrame:SetClampedToScreen(true) end)

    -- Drag handle sits above all frame children in the title-bar region.
    local handle = CreateFrame("Frame", "EzroUI_CharFrameDragHandle", CharacterFrame)
    handle:SetPoint("TOPLEFT",  CharacterFrame, "TOPLEFT",   24, -2)
    handle:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -24, -2)
    handle:SetHeight(26)
    handle:SetFrameLevel(CharacterFrame:GetFrameLevel() + 20)
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")

    -- Change cursor to indicate draggability
    handle:SetScript("OnEnter", function() SetCursor("Interface\\CURSOR\\UI-Cursor-Move") end)
    handle:SetScript("OnLeave", function() ResetCursor() end)

    handle:SetScript("OnDragStart", function()
        CharacterFrame:StartMoving()
    end)

    handle:SetScript("OnDragStop", function()
        CharacterFrame:StopMovingOrSizing()
        SaveCharacterFramePos()
    end)
end

-- ======================================================================
-- HOOKS & EXTENSION OF EXISTING CharacterPanel METHODS
-- ======================================================================

local skinHookSet = false

local function SetupSkinHooks()
    if skinHookSet then return end
    skinHookSet = true

    MakeCharacterFrameMovable()

    hooksecurefunc("PaperDollItemSlotButton_Update", function(button)
        if CharacterPanel:IsActive() then
            UpdateSlotButtonSkin(button, "player")
        end
    end)

    if CharacterFrame then
        CharacterFrame:HookScript("OnShow", function()
            -- Two timers: first fires immediately after the current frame to
            -- restore position before WoW renders; second at 0.15s covers any
            -- delayed repositioning WoW does during tab-switch show cycles.
            C_Timer.After(0,    RestoreCharacterFramePos)
            C_Timer.After(0.15, RestoreCharacterFramePos)
            if not CharacterPanel:IsActive() then return end
            SkinCharacterFrame()
            SkinRightPanel()
            for _, slotName in ipairs(CHARACTER_SLOTS) do
                local btn = _G[slotName]
                if btn then UpdateSlotButtonSkin(btn, "player") end
            end
            -- Ticker: try to colour ilvl every 0.2s for 3s after open.
            -- This beats any race with Blizzard's async ilvl writes.
            local tries = 0
            local ticker
            ticker = C_Timer.NewTicker(0.2, function()
                tries = tries + 1
                UpdateIlvlColor()
                if tries >= 15 then ticker:Cancel() end
            end)
        end)
    end

    -- Hook Blizzard's ilvl update functions directly so we recolour immediately
    -- after the game refreshes the number (covers tab switches, gear changes, etc.)
    for _, fnName in ipairs({
        "PaperDollItemLevel_UpdateItem",
        "PaperDollItemLevel_Update",
        "PaperDollFrame_UpdateStats",
    }) do
        if _G[fnName] then
            hooksecurefunc(fnName, function()
                if CharacterFrame and CharacterFrame:IsShown() then
                    C_Timer.After(0.05, UpdateIlvlColor)
                end
            end)
        end
    end

    -- PAPERDOLL_UPDATE fires in Midnight whenever the paperdoll is refreshed
    local ilvlEventWatcher = CreateFrame("Frame")
    ilvlEventWatcher:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    ilvlEventWatcher:RegisterEvent("UNIT_INVENTORY_CHANGED")
    -- Midnight-era event that fires when the character stat panel updates
    pcall(function() ilvlEventWatcher:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE") end)
    pcall(function() ilvlEventWatcher:RegisterEvent("PAPERDOLL_UPDATE") end)
    ilvlEventWatcher:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_INVENTORY_CHANGED" and unit ~= "player" then return end
        if CharacterFrame and CharacterFrame:IsShown() then
            C_Timer.After(0.1, UpdateIlvlColor)
        end
    end)
end

-- Extend Refresh to also refresh skins
local originalRefresh = CharacterPanel.Refresh

function CharacterPanel:Refresh()
    if originalRefresh then originalRefresh(self) end

    SetupSkinHooks()

    if self:IsActive() then
        SkinCharacterFrame()
        SkinRightPanel()
        for _, slotName in ipairs(CHARACTER_SLOTS) do
            local btn = _G[slotName]
            if btn then UpdateSlotButtonSkin(btn, "player") end
        end
        C_Timer.After(0.1, UpdateIlvlColor)
    else
        for _, slotName in ipairs(CHARACTER_SLOTS) do
            local btn = _G[slotName]
            if btn then HideSlotButtonSkin(btn) end
        end
    end
end

-- Extend UpdateAllCharacterSlots to also update slot skins
local originalUpdateAll = CharacterPanel.UpdateAllCharacterSlots

function CharacterPanel:UpdateAllCharacterSlots()
    if originalUpdateAll then originalUpdateAll(self) end
    if not self:IsActive() then return end
    for _, slotName in ipairs(CHARACTER_SLOTS) do
        local btn = _G[slotName]
        if btn then UpdateSlotButtonSkin(btn, "player") end
    end
end

-- ======================================================================
-- BOOTSTRAP
-- ======================================================================

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function(self, event)
    if event ~= "PLAYER_LOGIN" then return end
    self:UnregisterEvent("PLAYER_LOGIN")

    if CharacterPanel.Initialize and not CharacterPanel.initialized then
        CharacterPanel:Initialize()
    end

    SetupSkinHooks()
    RestoreCharacterFramePos()

    if CharacterFrame and CharacterFrame:IsShown() then
        SkinCharacterFrame()
        SkinRightPanel()
        C_Timer.After(0.2, UpdateIlvlColor)
    end
end)

