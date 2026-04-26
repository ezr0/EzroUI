local ADDON_NAME, ns = ...
local EzroUI = ns.Addon

EzroUI.Tooltips = EzroUI.Tooltips or {}
local Tooltips = EzroUI.Tooltips

-- ── Power-type colours ────────────────────────────────────────────────────────
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

-- ── NPC reaction colours (1=Hated … 8=Exalted) ───────────────────────────────
local REACTION_COLORS = {
    [1] = { r=0.88, g=0.13, b=0.13 }, -- Hated
    [2] = { r=0.88, g=0.13, b=0.13 }, -- Hostile
    [3] = { r=1.00, g=0.50, b=0.00 }, -- Unfriendly
    [4] = { r=0.90, g=0.85, b=0.10 }, -- Neutral
    [5] = { r=0.20, g=0.80, b=0.20 }, -- Friendly
    [6] = { r=0.20, g=0.80, b=0.20 }, -- Honored
    [7] = { r=0.20, g=0.80, b=0.20 }, -- Revered
    [8] = { r=0.20, g=0.80, b=0.20 }, -- Exalted
}

local CLASSIFICATION_LABELS = {
    elite      = "Elite",
    rareelite  = "Rare Elite",
    worldboss  = "World Boss",
    rare       = "Rare",
}

-- ── Helpers ───────────────────────────────────────────────────────────────────

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
    if pct >= 0.5 then return (1 - pct) * 2, 1, 0
    else               return 1, pct * 2, 0
    end
end

--- Returns the player's current spec name, or nil if unavailable.
local function GetUnitSpec(unit)
    if UnitIsUnit(unit, "player") then
        if GetSpecialization and GetSpecializationInfo then
            local idx = GetSpecialization()
            if idx then
                local _, name = GetSpecializationInfo(idx)
                return name
            end
        end
    else
        if GetInspectSpecialization and GetSpecializationInfoByID then
            local specID = GetInspectSpecialization(unit)
            if specID and specID > 0 then
                local _, name = GetSpecializationInfoByID(specID)
                return name
            end
        end
    end
    return nil
end

local function GetReactionColor(unit)
    local reaction = UnitReaction(unit, "player")
    local c = reaction and REACTION_COLORS[reaction]
    if c then return c.r, c.g, c.b end
    return 0.70, 0.70, 0.70
end

-- ── Border ────────────────────────────────────────────────────────────────────

local tooltipBorder
local blizzBorderHidden = false

local function HideBlizzardBorder()
    if blizzBorderHidden then return end
    blizzBorderHidden = true
    local ns9 = GameTooltip.NineSlice
    if ns9 then
        for _, region in pairs({
            ns9.TopLeftCorner,    ns9.TopRightCorner,
            ns9.BottomLeftCorner, ns9.BottomRightCorner,
            ns9.TopEdge,  ns9.BottomEdge,
            ns9.LeftEdge, ns9.RightEdge,
        }) do
            if region and region.Hide then region:Hide() end
        end
    end
end

local function EnsureTooltipBorder()
    if tooltipBorder then return tooltipBorder end
    tooltipBorder = CreateFrame("Frame", "EzroUITooltipBorder", GameTooltip, "BackdropTemplate")
    tooltipBorder:SetPoint("TOPLEFT",     GameTooltip, "TOPLEFT",      -1,  1)
    tooltipBorder:SetPoint("BOTTOMRIGHT", GameTooltip, "BOTTOMRIGHT",   1, -1)
    tooltipBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1.5 })
    tooltipBorder:SetBackdropBorderColor(0, 0, 0, 0)
    tooltipBorder:SetFrameLevel(GameTooltip:GetFrameLevel() + 5)
    return tooltipBorder
end

local function ShowClassBorder(r, g, b)
    EnsureTooltipBorder():SetBackdropBorderColor(r, g, b, 1)
end

local function HideClassBorder()
    if tooltipBorder then tooltipBorder:SetBackdropBorderColor(0, 0, 0, 0) end
end

-- ── Core rebuild ──────────────────────────────────────────────────────────────

-- Guard prevents scheduling a second rebuild while one is in progress.
local isRebuilding = false

-- ── NPC tooltip ───────────────────────────────────────────────────────────────

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

    -- Name in reaction colour
    tooltip:AddLine(unitName or "Unknown", rr, rg, rb)

    -- Level  ·  classification  ·  creature type
    local lvlStr = (level and level > 0) and tostring(level) or "??"
    local parts  = {}
    if CLASSIFICATION_LABELS[classification] then
        table.insert(parts, CLASSIFICATION_LABELS[classification])
    end
    if creatureType and creatureType ~= "" then
        table.insert(parts, creatureType)
    end
    local infoRight = #parts > 0 and table.concat(parts, "  ·  ") or " "
    tooltip:AddDoubleLine("Level " .. lvlStr, infoRight, 0.50, 0.50, 0.50, 0.85, 0.85, 0.85)

    -- Health
    if hpMax and hpMax > 0 then
        local hr, hg, hb = GetHPColor(hp / hpMax)
        tooltip:AddDoubleLine("Health",
            Comma(hp) .. " / " .. Comma(hpMax) .. "  (" .. PctStr(hp, hpMax) .. ")",
            0.50, 0.50, 0.50, hr, hg, hb)
    end
end

-- ── Player tooltip ────────────────────────────────────────────────────────────

local function RebuildPlayerTooltip(tooltip, unit, db)
    -- Gather all data BEFORE ClearLines() so nothing is lost
    local unitName                  = UnitName(unit)
    local _, realm                  = UnitName(unit)
    local guildName, guildRank      = GetGuildInfo(unit)
    local className, classID        = UnitClass(unit)
    local level                     = UnitLevel(unit)
    local specName                  = GetUnitSpec(unit)
    local faction                   = UnitFactionGroup(unit)
    local hp,    hpMax              = UnitHealth(unit), UnitHealthMax(unit)
    local powerTypeID, powerToken   = UnitPowerType(unit)
    local power, powerMax           = UnitPower(unit), UnitPowerMax(unit)

    local classColor = classID and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classID]
    local cr, cg, cb = 1, 1, 1
    if classColor then cr, cg, cb = classColor.r, classColor.g, classColor.b end

    -- Fetch M+ score before ClearLines() so the API call isn't disrupted mid-rebuild
    local mythicScore, mythicR, mythicG, mythicB = 0, 0.6, 0.6, 0.6
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
                    if gs and (gs.currentSeasonScore or gs.score or 0) > 0 then summary = gs end
                end
            end
        end
        local s = summary and (summary.currentSeasonScore or summary.score) or 0
        if s and s > 0 then
            mythicScore = math.floor(s)
            mythicR, mythicG, mythicB = GetMythicPlusColor(mythicScore)
        end
    end

    -- Border (before ClearLines so it stays visible during rebuild)
    if db.classColoredBorder and classColor then
        ShowClassBorder(cr, cg, cb)
        if db.hideBlizzardBorder then HideBlizzardBorder() end
    end

    tooltip:ClearLines()

    -- Name in class colour; M+ score on the right side of the name line (top-right of tooltip)
    local nr, ng, nb = cr, cg, cb
    if db.classColorName == false then nr, ng, nb = 1, 1, 1 end
    if db.showMythicPlus ~= false and mythicScore > 0 then
        tooltip:AddDoubleLine(unitName or "Unknown", "M+ " .. mythicScore, nr, ng, nb, mythicR, mythicG, mythicB)
    else
        tooltip:AddLine(unitName or "Unknown", nr, ng, nb)
    end

    -- Guild: gold name, softer rank below
    if db.showGuild and guildName then
        tooltip:AddLine("<" .. guildName .. ">", 1.0, 0.82, 0.0)
        if guildRank and guildRank ~= "" then
            tooltip:AddLine(guildRank, 0.70, 0.60, 0.35)
        end
    end

    -- Server / Realm
    if db.showRealm then
        if not realm or realm == "" then
            realm = (GetNormalizedRealmName and GetNormalizedRealmName())
                 or (GetRealmName and GetRealmName())
        end
        if realm and realm ~= "" then
            tooltip:AddDoubleLine("Server", realm, 0.50, 0.50, 0.50, 0.70, 0.85, 1.0)
        end
    end

    -- Level · Spec · Class  (right side in class colour)
    if db.showLevel then
        local lvl     = (level and level > 0) and tostring(level) or "??"
        local specStr = specName and (specName .. " ") or ""
        local clsStr  = className or ""
        tooltip:AddDoubleLine("Level " .. lvl, specStr .. clsStr, 0.50, 0.50, 0.50, cr, cg, cb)
    end

    -- Faction
    if db.showFaction and faction then
        local fr, fg, fb
        if faction == "Alliance" then fr, fg, fb = 0.20, 0.45, 1.0
        else                          fr, fg, fb = 0.90, 0.20, 0.20
        end
        tooltip:AddLine(faction, fr, fg, fb)
    end

    -- Health
    if db.showHealth and hpMax and hpMax > 0 then
        local hr, hg, hb = GetHPColor(hp / hpMax)
        tooltip:AddDoubleLine("Health",
            Comma(hp) .. " / " .. Comma(hpMax) .. "  (" .. PctStr(hp, hpMax) .. ")",
            0.50, 0.50, 0.50, hr, hg, hb)
    end

    -- Power / Resource
    if db.showPower and powerMax and powerMax > 0 then
        local pc    = POWER_COLORS[powerTypeID] or { r=0.60, g=0.60, b=0.60 }
        local pName = powerToken and (
            _G["POWER_TYPE_" .. powerToken]
            or (powerToken:sub(1,1) .. powerToken:sub(2):lower())
        ) or "Power"
        tooltip:AddDoubleLine(pName,
            Comma(power) .. " / " .. Comma(powerMax) .. "  (" .. PctStr(power, powerMax) .. ")",
            0.50, 0.50, 0.50, pc.r, pc.g, pc.b)
    end

    -- PvP Rating (own character only — live data available)
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
                bestRating = info.rating
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

local function PopulateUnitTooltip(tooltip, unit)
    if isRebuilding then return end

    local db = GetDB()
    if not db or not db.enabled then return end
    if not unit or not UnitExists(unit) then HideClassBorder(); return end

    isRebuilding = true
    local ok, err
    if UnitIsPlayer(unit) then
        ok, err = xpcall(RebuildPlayerTooltip, function(e) return e end, tooltip, unit, db)
    elseif db.enhanceNPCs then
        ok, err = xpcall(RebuildNPCTooltip, function(e) return e end, tooltip, unit, db)
    else
        HideClassBorder()
    end
    isRebuilding = false

    if ok == false and err then
        geterrorhandler()(err)
    end
end

-- ── Hooks ─────────────────────────────────────────────────────────────────────

local function OnUnitTooltip(tooltip)
    local unit = select(2, tooltip:GetUnit())
    PopulateUnitTooltip(tooltip, unit)
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

local hooksApplied = false

function Tooltips:Initialize()
    if hooksApplied then return end
    hooksApplied = true

    EnsureTooltipBorder()

    if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
            if tooltip ~= GameTooltip then return end  -- only process the main tooltip
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

    GameTooltip:HookScript("OnHide", HideClassBorder)
end

function Tooltips:Refresh()
    if not hooksApplied then self:Initialize() end
end
