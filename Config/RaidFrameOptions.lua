local ADDON_NAME, ns = ...
local EzUI = ns.Addon

function ns.CreateRaidFrameOptions()
    if EzUI and EzUI.PartyFrames and EzUI.PartyFrames.BuildEzUIOptions then
        return EzUI.PartyFrames:BuildEzUIOptions("raid", "Raid Frames", 46)
    end

    return {
        type = "group",
        name = "Raid Frames",
        order = 46,
        args = {
            fallback = {
                type = "description",
                name = "Raid frame options are not available yet.",
                order = 1,
            },
        },
    }
end
