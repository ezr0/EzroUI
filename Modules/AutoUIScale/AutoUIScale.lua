local ADDON_NAME, ns = ...
local EzUI = ns.Addon

-- Create namespace
EzUI.AutoUIScale = EzUI.AutoUIScale or {}
local AutoUIScale = EzUI.AutoUIScale

function AutoUIScale:SetUIScale(scale)
    if not EzUI or not EzUI.ApplyGlobalUIScale then return end
    -- Apply scale to UIParent so the whole UI (and other addons) use it. Handles combat defer internally.
    EzUI:ApplyGlobalUIScale(scale)
    if EzUI.PixelScaleChanged then
        EzUI:PixelScaleChanged()
    end
end

function AutoUIScale:ApplySavedScale()
    -- Apply global UIParent scale so the entire UI (including other addons) is pixel-perfect.
    -- If the user has a saved scale, use it; otherwise apply the recommended scale for this resolution.
    if not EzUI then return end
    local savedScale
    if EzUI.db and EzUI.db.profile and EzUI.db.profile.general then
        savedScale = EzUI.db.profile.general.uiScale
    end
    if savedScale and type(savedScale) == "number" then
        AutoUIScale:SetUIScale(savedScale)
    else
        -- First load or no saved value: apply recommended pixel-perfect scale globally
        EzUI:ApplyGlobalUIScale(nil)
        if EzUI.PixelScaleChanged then
            EzUI:PixelScaleChanged()
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

