local addonName, BFM = ...

local MinimapCoords = {}
BFM:RegisterModule("MinimapCoords", MinimapCoords)

local infoBar
local zoneText
local coordsText
local elapsedTimer = 0

local function GetPlayerMapCoords()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nil, nil end

    local position = C_Map.GetPlayerMapPosition(mapID, "player")
    if not position then return nil, nil end

    local x, y = position:GetXY()
    if not x or not y or (x == 0 and y == 0) then return nil, nil end

    return x * 100, y * 100
end

local function GetZonePVPInfo()
    if C_PvP and C_PvP.GetZonePVPInfo then
        return C_PvP.GetZonePVPInfo()
    elseif _G.GetZonePVPInfo then
        return _G.GetZonePVPInfo()
    end
    return nil, nil, nil
end

local function GetZoneColor()
    local pvpType, isSubZonePVP, factionName = GetZonePVPInfo()
    if pvpType == "sanctuary" then
        return 0.41, 0.8, 0.94
    elseif pvpType == "arena" or pvpType == "combat" then
        return 1.0, 0.1, 0.1
    elseif pvpType == "friendly" then
        return 0.1, 1.0, 0.1
    elseif pvpType == "hostile" then
        return 1.0, 0.1, 0.1
    elseif pvpType == "contested" then
        return 1.0, 0.7, 0.0
    end
    return 1.0, 0.92, 0.65
end


function MinimapCoords:UpdateZoneText()
    if not zoneText then return end

    local text = GetMinimapZoneText()
    if not text or text == "" then
        text = GetSubZoneText()
    end
    if not text or text == "" then
        text = GetZoneText()
    end
    if not text or text == "" then
        text = BFM.L["ZONE_UNKNOWN"]
    end

    zoneText:SetText(text)
    local r, g, b = GetZoneColor()
    zoneText:SetTextColor(r, g, b)
end

function MinimapCoords:UpdateCoordinates()
    if not coordsText then return end

    local x, y = GetPlayerMapCoords()
    if x and y then
        coordsText:SetFormattedText(BFM.L["COORDS_FORMAT"], x, y)
    else
        coordsText:SetText(BFM.L["COORDS_NA"])
    end
end

function MinimapCoords:CreateInfoBar()
    if infoBar then return end

    local height = (BFM.db and BFM.db.minimap and BFM.db.minimap.infoBarHeight) or 18

    infoBar = CreateFrame("Button", "BFM_MinimapInfoBar", Minimap)
    infoBar:SetHeight(height)
    infoBar:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
    infoBar:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)
    infoBar:SetFrameLevel(Minimap:GetFrameLevel() + 15)

    -- Background
    local bg = infoBar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.65)

    -- Top divider line
    local line = infoBar:CreateTexture(nil, "BORDER")
    line:SetPoint("TOPLEFT", infoBar, "TOPLEFT", 0, 0)
    line:SetPoint("TOPRIGHT", infoBar, "TOPRIGHT", 0, 0)
    line:SetHeight(1)
    line:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    -- Subzone FontString (Left aligned)
    zoneText = infoBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zoneText:SetPoint("LEFT", infoBar, "LEFT", 4, 0)
    zoneText:SetPoint("RIGHT", infoBar, "RIGHT", -55, 0)
    zoneText:SetJustifyH("LEFT")
    zoneText:SetWordWrap(false)

    -- Player Coordinates FontString (Right aligned)
    coordsText = infoBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    coordsText:SetPoint("RIGHT", infoBar, "RIGHT", -4, 0)
    coordsText:SetWidth(50)
    coordsText:SetJustifyH("RIGHT")

    self:UpdateFonts()

    -- Click action: toggle World Map
    infoBar:EnableMouse(true)
    infoBar:RegisterForClicks("AnyUp")
    infoBar:SetScript("OnClick", function()
        if ToggleWorldMap then
            ToggleWorldMap()
        end
    end)

    infoBar:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(GetMinimapZoneText() or GetZoneText(), 1, 1, 1)
        local subZone = GetSubZoneText()
        if subZone and subZone ~= "" and subZone ~= GetMinimapZoneText() then
            GameTooltip:AddLine(subZone, 0.8, 0.8, 0.8)
        end
        local pvpType = GetZonePVPInfo()
        if pvpType then
            local r, g, b = GetZoneColor()
            GameTooltip:AddLine(pvpType:upper(), r, g, b)
        end
        local x, y = GetPlayerMapCoords()
        if x and y then
            GameTooltip:AddDoubleLine("Coordinates:", string.format("%.1f, %.1f", x, y), 0.7, 0.7, 0.7, 1, 1, 1)
        end
        GameTooltip:AddLine("Click to toggle World Map", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)

    infoBar:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Throttled OnUpdate (0.1s)
    infoBar:SetScript("OnUpdate", function(self, dt)
        elapsedTimer = elapsedTimer + dt
        if elapsedTimer >= BFM.Constants.COORDS_UPDATE_INTERVAL then
            elapsedTimer = 0
            if MinimapCoords:IsQuestTrackerLocationBarActive() then
                MinimapCoords:UpdateVisibility()
            else
                MinimapCoords:UpdateCoordinates()
            end
        end
    end)

    -- Zone Change Events & Quest Tracker Watcher
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ZONE_CHANGED")
    eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:SetScript("OnEvent", function(self, event, arg1)
        MinimapCoords:HookQuestTracker()
        MinimapCoords:UpdateZoneText()
        MinimapCoords:UpdateCoordinates()
        MinimapCoords:UpdateVisibility()
    end)
end

function MinimapCoords:IsQuestTrackerLocationBarActive()
    local locFrame = _G["NullgateQuestTrackerLocationBar"]
    if locFrame and locFrame:IsShown() then
        return true
    end

    local BQT = _G["NullgatesQuestTrackerForever"] or _G["NullgateQuestTracker"]
    if BQT and BQT.GetDB then
        local db = BQT:GetDB()
        if db and db.databars and db.databars.enableLocationBar then
            return true
        end
    end

    local rawDB = _G["NullgatesQuestTrackerDB"]
    if rawDB then
        if rawDB.databars and rawDB.databars.enableLocationBar then
            return true
        end
        if rawDB.profiles then
            for _, prof in pairs(rawDB.profiles) do
                if type(prof) == "table" and prof.databars and prof.databars.enableLocationBar then
                    return true
                end
            end
        end
    end

    return false
end

function MinimapCoords:HookQuestTracker()
    local locFrame = _G["NullgateQuestTrackerLocationBar"]
    if locFrame and not self.locFrameHooked then
        self.locFrameHooked = true
        locFrame:HookScript("OnShow", function()
            MinimapCoords:UpdateVisibility()
        end)
        locFrame:HookScript("OnHide", function()
            MinimapCoords:UpdateVisibility()
        end)
    end

    local BQT = _G["NullgatesQuestTrackerForever"] or _G["NullgateQuestTracker"]
    if BQT and not self.bqtHooked then
        self.bqtHooked = true
        if BQT.ApplySettings then
            hooksecurefunc(BQT, "ApplySettings", function()
                MinimapCoords:UpdateVisibility()
            end)
        end
    end
end

function MinimapCoords:UpdateFonts()
    if not infoBar then return end
    local db = (BFM.db and BFM.db.minimap) or {}
    local fontName = db.coordsFont or "Nata Sans Bold"
    local fontSize = db.coordsFontSize or 10
    local outline = db.coordsFontOutline or "OUTLINE"
    if outline == "None" or outline == "NONE" then outline = "" end

    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local fontPath = (LSM and LSM:Fetch("font", fontName, true))
    if not fontPath or fontPath == "" then
        fontPath = "Fonts\\FRIZQT__.TTF"
    end

    if zoneText then
        pcall(function() zoneText:SetFont(fontPath, fontSize, outline) end)
    end
    if coordsText then
        pcall(function() coordsText:SetFont(fontPath, fontSize, outline) end)
    end
end

function MinimapCoords:UpdateLayout()
    if not infoBar then return end
    self:UpdateFonts()
    infoBar:ClearAllPoints()
    infoBar:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
    infoBar:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)
    self:UpdateZoneText()
    self:UpdateCoordinates()
end

function MinimapCoords:UpdateVisibility()
    if not infoBar then return end
    local shouldShow = BFM.db and BFM.db.minimap and (BFM.db.minimap.showCoords ~= false)

    -- Auto-hide built-in location bar if Nullgate's Quest Tracker location databar is active
    if shouldShow and self:IsQuestTrackerLocationBarActive() then
        shouldShow = false
    end

    if shouldShow then
        infoBar:Show()
    else
        infoBar:Hide()
    end
end

function MinimapCoords:OnInitialize()
    self:CreateInfoBar()
    self:HookQuestTracker()
    self:UpdateZoneText()
    self:UpdateCoordinates()
    self:UpdateVisibility()
end

function MinimapCoords:OnEnable()
    self:HookQuestTracker()
    self:UpdateZoneText()
    self:UpdateCoordinates()
    self:UpdateVisibility()
end

