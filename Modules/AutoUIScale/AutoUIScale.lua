local ADDON_NAME, ns = ...
local EzroUI = ns.Addon

-- Create namespace
EzroUI.AutoUIScale = EzroUI.AutoUIScale or {}
local AutoUIScale = EzroUI.AutoUIScale

function AutoUIScale:SetUIScale(scale)
    if not EzroUI or not EzroUI.ApplyGlobalUIScale then return end
    -- Apply scale to UIParent so the whole UI (and other addons) use it. Handles combat defer internally.
    EzroUI:ApplyGlobalUIScale(scale)
    if EzroUI.PixelScaleChanged then
        EzroUI:PixelScaleChanged()
    end
end

function AutoUIScale:ApplySavedScale()
    -- Apply global UIParent scale so the entire UI (including other addons) is pixel-perfect.
    -- If the user has a saved scale, use it; otherwise apply the recommended scale for this resolution.
    if not EzroUI then return end
    local savedScale
    if EzroUI.db and EzroUI.db.profile and EzroUI.db.profile.general then
        savedScale = EzroUI.db.profile.general.uiScale
    end
    if savedScale and type(savedScale) == "number" then
        AutoUIScale:SetUIScale(savedScale)
    else
        -- First load or no saved value: apply recommended pixel-perfect scale globally
        EzroUI:ApplyGlobalUIScale(nil)
        if EzroUI.PixelScaleChanged then
            EzroUI:PixelScaleChanged()
        end
    end
end

function AutoUIScale:Initialize()
    -- Apply saved scale immediately
    self:ApplySavedScale()
    
    -- Also register for PLAYER_LOGIN to apply it as early as possible
    -- This ensures the scale is set before edit mode initializes
    if not self.loginHandlerRegistered then
        self.loginHandlerRegistered = true
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("PLAYER_LOGIN")
        frame:SetScript("OnEvent", function(self, event)
            if event == "PLAYER_LOGIN" then
                AutoUIScale:ApplySavedScale()
                self:UnregisterEvent("PLAYER_LOGIN")
            end
        end)
    end
end

