local ADDON_NAME, ns = ...
local EzUI = ns.Addon

function ns.CreatePartyFrameOptions()
    if EzUI and EzUI.PartyFrames and EzUI.PartyFrames.BuildEzUIOptions then
        return EzUI.PartyFrames:BuildEzUIOptions("party", "Party Frames", 45)
    end

    return {
        type = "group",
        name = "Party Frames",
        order = 45,
        args = {
            fallback = {
                type = "description",
                name = "Party frame options are not available yet.",
                order = 1,
            },
        },
    }
end
