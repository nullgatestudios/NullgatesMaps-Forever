--[[
    Nullgate's Maps - Forever
    Core/Config.lua - Data Layer: DB Defaults, Profiles, Get/Set Accessors, & Notification Hooks
]]

local addonName, BFM = ...

local defaultProfileSettings = {
    minimap = {
        square = true,
        squareIcons = true,
        hideDielFrame = true,
        borderStyle = "flat",
        classColorBorder = false,
        borderSize = 1,
        borderColor = { r = 0, g = 0, b = 0, a = 1 },
        backdropColor = { r = 0, g = 0, b = 0, a = 0.8 },
        trackerScale = 0.85,
        calendarScale = 0.80,
        timeScale = 0.85,
        size = 140,
        unlocked = false,
        position = nil,
        questIndicator = true,
        enableMouseWheelZoom = true,
        showCoords = true,
        showZone = true,
        infoBarHeight = 18,
        coordsFont = "Nata Sans Bold",
        coordsFontSize = 10,
        coordsFontOutline = "OUTLINE",
    },
    worldmap = {
        showCoords = true,
        overlayHeight = 22,
        backdropColor = { r = 0, g = 0, b = 0, a = 0.65 },
        fogClear = true,
        fogColor = { r = 0.90, g = 0.90, b = 1.00 },
        fogAlpha = 0.60,
        coordsFont = "Nata Sans Bold",
        coordsFontSize = 11,
        coordsFontOutline = "OUTLINE",
    },
}

local defaultWindowSettings = {
    width = 760,
    height = 520,
    point = "CENTER",
    relativePoint = "CENTER",
    xOfs = 0,
    yOfs = 0,
    lastTab = "general",
}

local function DeepCopy(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = type(v) == "table" and DeepCopy(v) or v
    end
    return copy
end

local function MergeDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then
                dst[k] = {}
            end
            MergeDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

--[[-----------------------------------------------------------------------------
    Database & Profile Initialization (With Auto-Migration from Legacy Schemas)
-------------------------------------------------------------------------------]]
function BFM:InitDB()
    if type(NullgatesMapsDB) ~= "table" then
        NullgatesMapsDB = {}
    end

    -- Persistent UI window bounds
    if type(NullgatesMapsDB.configWindow) ~= "table" then
        NullgatesMapsDB.configWindow = DeepCopy(defaultWindowSettings)
    else
        MergeDefaults(NullgatesMapsDB.configWindow, defaultWindowSettings)
    end

    -- Profile layer initialization & backward-compatibility migration
    if type(NullgatesMapsDB.profiles) ~= "table" then
        NullgatesMapsDB.profiles = {}

        -- If user upgraded from v1.0.01 - v1.0.04 with flat settings:
        if type(NullgatesMapsDB.minimap) == "table" or type(NullgatesMapsDB.worldmap) == "table" then
            NullgatesMapsDB.profiles["Default"] = {
                minimap = NullgatesMapsDB.minimap or DeepCopy(defaultProfileSettings.minimap),
                worldmap = NullgatesMapsDB.worldmap or DeepCopy(defaultProfileSettings.worldmap),
            }
            NullgatesMapsDB.minimap = nil
            NullgatesMapsDB.worldmap = nil
        end
    end

    if not NullgatesMapsDB.activeProfile or NullgatesMapsDB.activeProfile == "" then
        NullgatesMapsDB.activeProfile = "Default"
    end

    if not NullgatesMapsDB.profiles[NullgatesMapsDB.activeProfile] then
        NullgatesMapsDB.profiles[NullgatesMapsDB.activeProfile] = DeepCopy(defaultProfileSettings)
    end

    -- Ensure active profile has all required sub-tables & defaults
    MergeDefaults(NullgatesMapsDB.profiles[NullgatesMapsDB.activeProfile], defaultProfileSettings)

    -- Bind active profile to BFM.db and configWindow
    BFM.db = NullgatesMapsDB.profiles[NullgatesMapsDB.activeProfile]
    BFM.db.configWindow = NullgatesMapsDB.configWindow
end

--[[-----------------------------------------------------------------------------
    Profile Accessors & Management
-------------------------------------------------------------------------------]]
function BFM:GetActiveProfile()
    return (NullgatesMapsDB and NullgatesMapsDB.activeProfile) or "Default"
end

function BFM:GetProfiles()
    local list = {}
    if NullgatesMapsDB and NullgatesMapsDB.profiles then
        for name in pairs(NullgatesMapsDB.profiles) do
            table.insert(list, name)
        end
    end
    if #list == 0 then table.insert(list, "Default") end
    table.sort(list)
    return list
end

function BFM:SetActiveProfile(name)
    if not name or name == "" then return end
    self:InitDB()
    if not NullgatesMapsDB.profiles[name] then
        local cur = NullgatesMapsDB.profiles[NullgatesMapsDB.activeProfile]
        NullgatesMapsDB.profiles[name] = DeepCopy(cur or defaultProfileSettings)
    else
        MergeDefaults(NullgatesMapsDB.profiles[name], defaultProfileSettings)
    end
    NullgatesMapsDB.activeProfile = name
    BFM.db = NullgatesMapsDB.profiles[name]
    BFM.db.configWindow = NullgatesMapsDB.configWindow

    if NullgatesMapsForever and NullgatesMapsForever.ApplySettings then
        NullgatesMapsForever:ApplySettings()
    end

    if BFM.standaloneFrame and BFM.standaloneFrame:IsShown() and BFM.standaloneFrame.SyncAll then
        BFM.standaloneFrame:SyncAll()
    end
end

function BFM:CreateProfile(name, fromName)
    if not name or name == "" then return end
    self:InitDB()
    -- Never overwrite existing profile!
    if not NullgatesMapsDB.profiles[name] then
        local source = fromName and NullgatesMapsDB.profiles[fromName]
        if not source then
            source = NullgatesMapsDB.profiles[self:GetActiveProfile()] or defaultProfileSettings
        end
        NullgatesMapsDB.profiles[name] = DeepCopy(source)
    end
    self:SetActiveProfile(name)
end

function BFM:SaveCurrentAs(name)
    if not name or name == "" then return end
    self:InitDB()
    local cur = NullgatesMapsDB.profiles[self:GetActiveProfile()]
    NullgatesMapsDB.profiles[name] = DeepCopy(cur or defaultProfileSettings)
    self:SetActiveProfile(name)
end

function BFM:DeleteProfile(name)
    if not name or name == "Default" then return end
    self:InitDB()
    NullgatesMapsDB.profiles[name] = nil
    if NullgatesMapsDB.activeProfile == name then
        self:SetActiveProfile("Default")
    end
end

function BFM:CopyProfile(fromName, toName)
    self:InitDB()
    if NullgatesMapsDB.profiles[fromName] then
        NullgatesMapsDB.profiles[toName] = DeepCopy(NullgatesMapsDB.profiles[fromName])
    end
end

function BFM:ResetProfile(name)
    name = name or self:GetActiveProfile()
    self:InitDB()
    NullgatesMapsDB.profiles[name] = DeepCopy(defaultProfileSettings)
    if NullgatesMapsDB.activeProfile == name then
        BFM.db = NullgatesMapsDB.profiles[name]
        BFM.db.configWindow = NullgatesMapsDB.configWindow
        if NullgatesMapsForever and NullgatesMapsForever.ApplySettings then
            NullgatesMapsForever:ApplySettings()
        end
    end
    if BFM.standaloneFrame and BFM.standaloneFrame:IsShown() and BFM.standaloneFrame.SyncAll then
        BFM.standaloneFrame:SyncAll()
    end
end

--[[-----------------------------------------------------------------------------
    Settings Change Notification Dispatcher
-------------------------------------------------------------------------------]]
function BFM:NotifySettingsChanged(settingName)
    local squareModule = BFM.modules["SquareMinimap"]
    if squareModule then
        if settingName == "borderSize" or settingName == "borderColor" or settingName == "backdropColor" or settingName == "borderStyle" or settingName == "classColorBorder" then
            squareModule:UpdateBorder()
        elseif settingName == "trackerScale" or settingName == "calendarScale" then
            squareModule:PositionElements()
        elseif settingName == "timeScale" then
            squareModule:PositionClock()
        elseif settingName == "hideDielFrame" then
            squareModule:UpdateDielFrame()
        elseif settingName == "squareIcons" then
            squareModule:ScanMinimapButtons()
        elseif settingName == "size" then
            squareModule:SetMinimapSize(BFM.db.minimap.size)
        elseif settingName == "unlocked" then
            squareModule:UpdateMoveOverlay()
        elseif settingName == "questIndicator" then
            squareModule:UpdateQuestZoneIndicator()
        end
    end

    local coordsModule = BFM.modules["MinimapCoords"]
    if coordsModule and (settingName == "showCoords" or settingName == "showZone") then
        if coordsModule.UpdateVisibility then
            coordsModule:UpdateVisibility()
        end
    end

    local worldMapModule = BFM.modules["WorldMapCoords"]
    if worldMapModule and (settingName == "worldMapCoords" or settingName == "showCoords") then
        if worldMapModule.UpdateVisibility then
            worldMapModule:UpdateVisibility()
        end
    end

    local fogModule = BFM.modules["WorldMapFog"]
    if fogModule and (settingName == "fogClear" or settingName == "fogColor" or settingName == "fogAlpha") then
        if fogModule.Refresh then
            fogModule:Refresh()
        end
    end
end
