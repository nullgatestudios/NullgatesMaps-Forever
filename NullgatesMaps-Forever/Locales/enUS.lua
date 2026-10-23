local addonName, BFM = ...

local L = setmetatable({}, {
    __index = function(_, key)
        return key
    end,
})

BFM.L = L

-- English Localization Strings
L["ADDON_TITLE"] = "NullgatesMaps-Forever"
L["MAP_PLAYER_COORDS"] = "Player: %s"
L["MAP_CURSOR_COORDS"] = "Cursor: %s"
L["COORDS_FORMAT"] = "%.1f, %.1f"
L["COORDS_NA"] = "--, --"
L["ZONE_UNKNOWN"] = "Unknown Zone"
