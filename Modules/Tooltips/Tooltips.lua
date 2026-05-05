local ADDON_NAME, ns = ...
local EzroUI = ns.Addon

EzroUI.Tooltips = EzroUI.Tooltips or {}
local Tooltips = EzroUI.Tooltips

-- Power-type colours
local POWER_COLORS = {
    [Enum and Enum.PowerType and Enum.PowerType.Mana          or 0]  = { r=0.00, g=0.44, b=0.87 },
    [Enum and Enum.PowerType and Enum.PowerType.Rage          or 1]  = { r=0.78, g=0.25, b=0.25 },
    [Enum and Enum.PowerType and Enum.PowerType.Focus         or 2]  = { r=1.00, g=0.49, b=0.04 },
    [Enum and Enum.PowerType and Enum.PowerType.Energy        or 3]  = { r=1.00, g=0.96, b=0.41 },
    [Enum and Enum.PowerType and Enum.PowerType.ComboPoints   or 4]  = { r=1.00, g=0.96, b=0.41 },
    [Enum and Enum.PowerType and Enum.PowerType.Runic         or 6]  = { r=0.00, g=0.82, b=1.00 },
    [Enum and Enum.PowerType and Enum.PowerType.SoulShards    or 7]  = { r=0.50, g=0.32, b=0.55 },
    [Enum and Enum.PowerType and Enum.PowerType.LunarPower    or 8]  = { r=0.30, g=0.52, b=0.90 },
    [Enum and Enum.PowerType and Enum.PowerType.HolyPower     or 9]  = { r=0.95, g=0.90, b=0.60 },
    [Enum and Enum.PowerType and Enum.PowerType.Maelstrom     or 11] = { r=0.00, g=0.50, b=1.00 },
    [Enum and Enum.PowerType and Enum.PowerType.Chi           or 12] = { r=0.71, g=1.00, b=0.92 },
    [Enum and Enum.PowerType and Enum.PowerType.Insanity      or 13] = { r=0.40, g=0.00, b=0.80 },
    [Enum and Enum.PowerType and Enum.PowerType.ArcaneCharges or 16] = { r=0.22, g=0.45, b=0.87 },
    [Enum and Enum.PowerType and Enum.PowerType.Fury          or 17] = { r=0.79, g=0.26, b=1.00 },
    [Enum and Enum.PowerType and Enum.PowerType.Pain          or 18] = { r=1.00, g=0.61, b=0.00 },
    [Enum and Enum.PowerType and Enum.PowerType.Essence       or 19] = { r=0.00, g=0.82, b=1.00 },
}

-- NPC reaction colours (1=Hated ... 8=Exalted)
local REACTION_COLORS = {
    [1] = { r=0.88, g=0.13, b=0.13 },
    [2] = { r=0.88, g=0.13, b=0.13 },
    [3] = { r=1.00, g=0.50, b=0.00 },
    [4] = { r=0.90, g=0.85, b=0.10 },
    [5] = { r=0.20, g=0.80, b=0.20 },
    [6] = { r=0.20, g=0.80, b=0.20 },
    [7] = { r=0.20, g=0.80, b=0.20 },
    [8] = { r=0.20, g=0.80, b=0.20 },
}

local CLASSIFICATION_LABELS = {
    elite      = "Elite",
    rareelite  = "Rare Elite",
    worldboss  = "World Boss",
    rare       = "Rare",
}

-- Helpers

local function GetDB()
    return EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.tooltips
end

local function Comma(n)
    local s = tostring(math.floor(n))
    return s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function PctStr(cur, max)
    if max <= 0 then return "" end
    return math.floor(cur / max * 100 + 0.5) .. "%"
end

local function GetMythicPlusColor(score)
    if C_DungeonScore and C_DungeonScore.GetDungeonScoreRarityColor then
        local c = C_DungeonScore.GetDungeonScoreRarityColor(score)
        if c then return c.r, c.g, c.b end
    end
    if     score >= 2500 then return 1.0,  0.50, 0.0
    elseif score >= 2000 then return 0.70, 0.30, 1.0
    elseif score >= 1500 then return 0.10, 0.60, 1.0
    elseif score >= 750  then return 0.10, 0.90, 0.10
    else                       return 0.60, 0.60, 0.60
    end
end

local function GetPvPRatingColor(rating)
    if     rating >= 2400 then return 1.0,  0.82, 0.0
    elseif rating >= 2100 then return 1.0,  0.50, 0.0
    elseif rating >= 1800 then return 0.40, 0.70, 1.0
    elseif rating >= 1400 then return 0.20, 0.80, 0.20
    else                       return 0.70, 0.70, 0.70
    end
end

local function GetHPColor(pct)
    if pct >= 0.5 then
        return (1 - pct) * 2, 1, 0
    else
        return 1, pct * 2, 0
    end
end

local function GetReactionColor(unit)
    local reaction = UnitReaction(unit, "player")
    local c = reaction and REACTION_COLORS[reaction]
    if c then return c.r, c.g, c.b end
    return 0.70, 0.70, 0.70
end

-- Frames (created once during Initialize)

local tooltipBorder     = nil
local healthBar         = nil
local healthBarLabel    = nil
local blizzBorderHidden = false
local healthUnit        = nil  -- unit whose health the bar is tracking

local function HideBlizzardBorder()
    if blizzBorderHidden then return end
    blizzBorderHidden = true
    local ns9 = GameTooltip.NineSlice
    if not ns9 then return end
    for _, region in pairs({
        ns9.TopLeftCorner,    ns9.TopRightCorner,
        ns9.BottomLeftCorner, ns9.BottomRightCorner,
        ns9.TopEdge,  ns9.BottomEdge,
        ns9.LeftEdge, ns9.RightEdge,
    }) do
        if region and region.Hide then region:Hide() end
    end
end

local function ShowClassBorder(r, g, b)
    if tooltipBorder then
        tooltipBorder:SetBackdropBorderColor(r, g, b, 1)
    end
end

local function HideClassBorder()
    if tooltipBorder then
        tooltipBorder:SetBackdropBorderColor(0, 0, 0, 0)
    end
end

local function RefreshHealthBarVisuals(hp, hpMax)
    if not healthBar or not hp or not hpMax or hpMax <= 0 then return end
    local pct = hp / hpMax
    local r, g, b = GetHPColor(pct)
    healthBar:SetMinMaxValues(0, hpMax)
    healthBar:SetValue(hp)
    healthBar:SetStatusBarColor(r, g, b, 1)
    if healthBarLabel then
        healthBarLabel:SetText(Comma(hp) .. " / " .. Comma(hpMax) .. "  (" .. PctStr(hp, hpMax) .. ")")
    end
end

local function ShowHealthBar(hp, hpMax, unit)
    if not healthBar then return end
    healthUnit = unit
    RefreshHealthBarVisuals(hp, hpMax)
    healthBar:ClearAllPoints()
    healthBar:SetPoint("TOPLEFT",  GameTooltip, "BOTTOMLEFT",   0, -4)
    healthBar:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT",  0, -4)
    healthBar:Show()
end

local function HideHealthBar()
    if healthBar then healthBar:Hide() end
    healthUnit = nil
end

-- Rebuild: NPC

local isRebuilding = false

local function RebuildNPCTooltip(tooltip, unit, db)
    local unitName       = UnitName(unit)
    local level          = UnitLevel(unit)
    local creatureType   = UnitCreatureType(unit)
    local classification = UnitClassification(unit)
    local hp, hpMax      = UnitHealth(unit), UnitHealthMax(unit)
    local rr, rg, rb     = GetReactionColor(unit)

    ShowClassBorder(rr, rg, rb)
    if db.hideBlizzardBorder then HideBlizzardBorder() end

    tooltip:ClearLines()

    tooltip:AddLine(unitName or "Unknown", rr, rg, rb)

    local lvlStr = (level and level > 0) and tostring(level) or "??"
    local parts  = {}
    if CLASSIFICATION_LABELS[classification] then
        table.insert(parts, CLASSIFICATION_LABELS[classification])
    end
    if creatureType and creatureType ~= "" then
        table.insert(parts, creatureType)
    end
    local infoRight = (#parts > 0) and table.concat(parts, "  ·  ") or " "
    tooltip:AddDoubleLine("Level " .. lvlStr, infoRight, 0.50, 0.50, 0.50, 0.85, 0.85, 0.85)

    if hpMax and hpMax > 0 then
        ShowHealthBar(hp, hpMax, unit)
    else
        HideHealthBar()
    end
end

-- Rebuild: Player

local function RebuildPlayerTooltip(tooltip, unit, db)
    -- Collect all data before ClearLines()
    local unitName, realm         = UnitName(unit)
    local guildName, guildRank    = GetGuildInfo(unit)
    local className, classToken   = UnitClass(unit)   -- classToken e.g. "DEATHKNIGHT"
    local raceName                = UnitRace(unit)
    local level                   = UnitLevel(unit)
    local faction                 = UnitFactionGroup(unit)
    local hp, hpMax               = UnitHealth(unit), UnitHealthMax(unit)
    local powerType, powerToken   = UnitPowerType(unit)
    local power, powerMax         = UnitPower(unit), UnitPowerMax(unit)

    -- Resolve class colour via token string key
    local classColor = classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
    local cr, cg, cb = 1, 1, 1
    if classColor then
        cr, cg, cb = classColor.r, classColor.g, classColor.b
    end

    -- Mythic+ score (fetched before ClearLines)
    local mythicScore               = 0
    local mythicR, mythicG, mythicB = 0.6, 0.6, 0.6
    if db.showMythicPlus ~= false and C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        local summary
        if UnitIsUnit(unit, "player") then
            summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
        else
            summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
            local s0 = summary and (summary.currentSeasonScore or summary.score) or 0
            if s0 == 0 then
                local guid = UnitGUID(unit)
                if guid then
                    local gs = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(guid)
                    if gs and ((gs.currentSeasonScore or gs.score or 0) > 0) then
                        summary = gs
                    end
                end
            end
        end
        local s = summary and (summary.currentSeasonScore or summary.score) or 0
        if s and s > 0 then
            mythicScore             = math.floor(s)
            mythicR, mythicG, mythicB = GetMythicPlusColor(mythicScore)
        end
    end

    -- Class-coloured border (set before ClearLines so it persists)
    if db.classColoredBorder and classColor then
        ShowClassBorder(cr, cg, cb)
        if db.hideBlizzardBorder then HideBlizzardBorder() end
    end

    tooltip:ClearLines()

    -- 1. Player name in class colour  |  M+ rating top-right
    local nr, ng, nb = cr, cg, cb
    if db.classColorName == false then nr, ng, nb = 1, 1, 1 end
    if db.showMythicPlus ~= false and mythicScore > 0 then
        tooltip:AddDoubleLine(unitName or "Unknown", "M+ " .. mythicScore, nr, ng, nb, mythicR, mythicG, mythicB)
    else
        tooltip:AddLine(unitName or "Unknown", nr, ng, nb)
    end

    -- 2. Guild name (gold)  +  3. Guild rank (muted gold)
    if db.showGuild and guildName then
        tooltip:AddLine("<" .. guildName .. ">", 1.0, 0.82, 0.0)
        if guildRank and guildRank ~= "" then
            tooltip:AddLine(guildRank, 0.70, 0.60, 0.35)
        end
    end

    -- 4. Level  |  Race (white)  Class (class colour via embedded code)
    if db.showLevel then
        local lvl      = (level and level > 0) and tostring(level) or "??"
        local classHex = string.format("%02x%02x%02x",
            math.floor(cr * 255), math.floor(cg * 255), math.floor(cb * 255))
        local raceStr  = raceName and (raceName .. " ") or ""
        local clsStr   = "|cff" .. classHex .. (className or "") .. "|r"
        tooltip:AddDoubleLine("Level " .. lvl, raceStr .. clsStr, 0.50, 0.50, 0.50, 1, 1, 1)
    end

    -- 5. Server
    if db.showRealm then
        if not realm or realm == "" then
            realm = (GetNormalizedRealmName and GetNormalizedRealmName())
                 or (GetRealmName and GetRealmName())
        end
        if realm and realm ~= "" then
            tooltip:AddDoubleLine("Server", realm, 0.50, 0.50, 0.50, 0.70, 0.85, 1.0)
        end
    end

    -- 6. Location
    if db.showLocation ~= false then
        local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit(unit)
        if mapID then
            local mapInfo = C_Map.GetMapInfo(mapID)
            if mapInfo and mapInfo.name then
                tooltip:AddDoubleLine("Location", mapInfo.name, 0.50, 0.50, 0.50, 0.60, 1.0, 0.60)
            end
        end
    end

    -- 7. Health bar
    if db.showHealth and hpMax and hpMax > 0 then
        ShowHealthBar(hp, hpMax, unit)
    else
        HideHealthBar()
    end

    -- 8. Power / Resource
    if db.showPower and powerMax and powerMax > 0 then
        local pc    = POWER_COLORS[powerType] or { r=0.60, g=0.60, b=0.60 }
        local pName = powerToken and (
            _G["POWER_TYPE_" .. powerToken]
            or (powerToken:sub(1, 1) .. powerToken:sub(2):lower())
        ) or "Power"
        tooltip:AddDoubleLine(
            pName,
            Comma(power) .. " / " .. Comma(powerMax) .. "  (" .. PctStr(power, powerMax) .. ")",
            0.50, 0.50, 0.50, pc.r, pc.g, pc.b)
    end

    -- 9. PvP Rating (own character only)
    if db.showPvP and UnitIsUnit(unit, "player") and C_PvP and C_PvP.GetRatingInfo then
        local BRACKETS = {
            { id = 0, name = "2v2"          },
            { id = 1, name = "3v3"          },
            { id = 2, name = "RBG"          },
            { id = 3, name = "Solo Shuffle" },
        }
        local bestRating, bestBracket = 0, nil
        for _, bracket in ipairs(BRACKETS) do
            local ok, info = pcall(C_PvP.GetRatingInfo, bracket.id)
            if ok and info and info.rating and info.rating > bestRating then
                bestRating  = info.rating
                bestBracket = bracket.name
            end
        end
        if bestRating > 0 and bestBracket then
            local r, g, b = GetPvPRatingColor(bestRating)
            tooltip:AddDoubleLine(
                "Best PvP (" .. bestBracket .. ")", tostring(bestRating),
                0.50, 0.50, 0.50, r, g, b)
        end
    end
end

-- Dispatch

local function PopulateUnitTooltip(tooltip, unit)
    if isRebuilding then return end
    local db = GetDB()
    if not db or not db.enabled then return end
    if not unit or not UnitExists(unit) then
        HideClassBorder()
        HideHealthBar()
        return
    end

    isRebuilding = true
    local ok, err
    if UnitIsPlayer(unit) then
        ok, err = xpcall(RebuildPlayerTooltip, function(e) return e .. "\n" .. debugstack() end, tooltip, unit, db)
    elseif db.enhanceNPCs then
        ok, err = xpcall(RebuildNPCTooltip,    function(e) return e .. "\n" .. debugstack() end, tooltip, unit, db)
    else
        HideClassBorder()
        HideHealthBar()
    end
    isRebuilding = false

    if ok == false and err then
        geterrorhandler()(err)
    end
end

local function OnUnitTooltip(tooltip)
    local unit = select(2, tooltip:GetUnit())
    PopulateUnitTooltip(tooltip, unit)
end

-- Lifecycle

local hooksApplied = false

function Tooltips:Initialize()
    if hooksApplied then return end
    hooksApplied = true

    -- Border frame (no global name to avoid reload conflicts)
    tooltipBorder = CreateFrame("Frame", nil, GameTooltip, "BackdropTemplate")
    tooltipBorder:SetPoint("TOPLEFT",     GameTooltip, "TOPLEFT",      -1,  1)
    tooltipBorder:SetPoint("BOTTOMRIGHT", GameTooltip, "BOTTOMRIGHT",   1, -1)
    tooltipBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1.5 })
    tooltipBorder:SetBackdropBorderColor(0, 0, 0, 0)
    tooltipBorder:SetFrameLevel(GameTooltip:GetFrameLevel() + 5)

    -- Health bar: parented to UIParent at TOOLTIP strata, anchored below GameTooltip.
    healthBar = CreateFrame("StatusBar", nil, UIParent)
    healthBar:SetFrameStrata("TOOLTIP")
    healthBar:SetFrameLevel(128)
    healthBar:SetHeight(20)
    healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    healthBar:SetStatusBarColor(0.2, 0.8, 0.2, 1)
    healthBar:SetMinMaxValues(0, 1)
    healthBar:SetValue(1)

    -- Dark background
    local hpBg = healthBar:CreateTexture(nil, "BACKGROUND")
    hpBg:SetAllPoints(healthBar)
    hpBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    hpBg:SetVertexColor(0.07, 0.07, 0.07, 1)

    -- Border matching tooltip border
    local hpBorderFrame = CreateFrame("Frame", nil, healthBar, "BackdropTemplate")
    hpBorderFrame:SetPoint("TOPLEFT",     healthBar, "TOPLEFT",     -1,  1)
    hpBorderFrame:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT",  1, -1)
    hpBorderFrame:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    hpBorderFrame:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)
    hpBorderFrame:SetFrameLevel(healthBar:GetFrameLevel() + 1)

    -- HP text centred in the bar
    healthBarLabel = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    healthBarLabel:SetPoint("CENTER", healthBar, "CENTER", 0, 0)
    healthBarLabel:SetTextColor(1, 1, 1, 1)

    -- Live-update health every 0.2 s while bar is visible
    local hpUpdateElapsed = 0
    healthBar:SetScript("OnUpdate", function(self, dt)
        hpUpdateElapsed = hpUpdateElapsed + dt
        if hpUpdateElapsed < 0.2 then return end
        hpUpdateElapsed = 0
        if not healthUnit then return end
        local hp    = UnitHealth(healthUnit)
        local hpMax = UnitHealthMax(healthUnit)
        if hp and hpMax and hpMax > 0 then
            RefreshHealthBarVisuals(hp, hpMax)
        end
    end)

    healthBar:Hide()

    -- Hook tooltip population
    if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
            if tooltip ~= GameTooltip then return end
            local db = GetDB()
            if not db or not db.enabled then return end
            OnUnitTooltip(tooltip)
        end)
    elseif GameTooltip:HasScript("OnTooltipSetUnit") then
        GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
            local db = GetDB()
            if not db or not db.enabled then return end
            OnUnitTooltip(tooltip)
        end)
    end

    GameTooltip:HookScript("OnHide", function()
        HideClassBorder()
        HideHealthBar()
    end)
end

function Tooltips:Refresh()
    if not hooksApplied then self:Initialize() end
end