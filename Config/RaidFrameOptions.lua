local ADDON_NAME, ns = ...
local EzroUI = ns.Addon

function ns.CreateRaidFrameOptions()
    if EzroUI and EzroUI.PartyFrames and EzroUI.PartyFrames.BuildEzroUIOptions then
        return EzroUI.PartyFrames:BuildEzroUIOptions("raid", "Raid Frames", 46)
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
