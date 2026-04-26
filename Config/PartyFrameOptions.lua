local ADDON_NAME, ns = ...
local EzroUI = ns.Addon

function ns.CreatePartyFrameOptions()
    if EzroUI and EzroUI.PartyFrames and EzroUI.PartyFrames.BuildEzroUIOptions then
        return EzroUI.PartyFrames:BuildEzroUIOptions("party", "Party Frames", 45)
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
