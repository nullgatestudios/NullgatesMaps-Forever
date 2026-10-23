local addonName, BFM = ...

local WorldMapCoords = {}
BFM:RegisterModule("WorldMapCoords", WorldMapCoords)

-- MapCanvas DataProvider implementation
local BFM_CoordsDataProvider = CreateFromMixins(MapCanvasDataProviderMixin)

local overlayFrame
local playerText
local cursorText
local updateTimer = 0

function BFM_CoordsDataProvider:OnAdded(owningMap)
    MapCanvasDataProviderMixin.OnAdded(self, owningMap)
    WorldMapCoords:CreateOverlayFrame(owningMap)
end

function BFM_CoordsDataProvider:OnRemoved(owningMap)
    MapCanvasDataProviderMixin.OnRemoved(self, owningMap)
    if overlayFrame then
        overlayFrame:Hide()
    end
end

function BFM_CoordsDataProvider:OnShow()
    if overlayFrame and BFM.db.worldmap.showCoords then
        overlayFrame:Show()
    end
    self:RefreshAllData()
end

function BFM_CoordsDataProvider:OnHide()
    if overlayFrame then
        overlayFrame:Hide()
    end
end

function BFM_CoordsDataProvider:RefreshAllData(fromOnShow)
    WorldMapCoords:UpdateCoords()
end

function BFM_CoordsDataProvider:RemoveAllData()
    if playerText then
        playerText:SetFormattedText(BFM.L["MAP_PLAYER_COORDS"], BFM.L["COORDS_NA"])
    end
    if cursorText then
        cursorText:SetFormattedText(BFM.L["MAP_CURSOR_COORDS"], BFM.L["COORDS_NA"])
    end
end

function WorldMapCoords:CreateOverlayFrame(mapCanvas)
    if overlayFrame then return end

    local scrollContainer = mapCanvas.ScrollContainer
    if not scrollContainer then return end

    local height = (BFM.db and BFM.db.worldmap and BFM.db.worldmap.overlayHeight) or 22

    overlayFrame = CreateFrame("Frame", "BFM_WorldMapCoordsOverlay", scrollContainer)
    overlayFrame:SetPoint("BOTTOMLEFT", scrollContainer, "BOTTOMLEFT", 0, 0)
    overlayFrame:SetPoint("BOTTOMRIGHT", scrollContainer, "BOTTOMRIGHT", 0, 0)
    overlayFrame:SetHeight(height)
    overlayFrame:SetFrameLevel(scrollContainer:GetFrameLevel() + 25)

    -- Background
    local bg = overlayFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    local c = (BFM.db and BFM.db.worldmap and BFM.db.worldmap.backdropColor) or { r = 0, g = 0, b = 0, a = 0.65 }
    bg:SetColorTexture(c.r, c.g, c.b, c.a)

    -- Top accent line
    local line = overlayFrame:CreateTexture(nil, "BORDER")
    line:SetPoint("TOPLEFT", overlayFrame, "TOPLEFT", 0, 0)
    line:SetPoint("TOPRIGHT", overlayFrame, "TOPRIGHT", 0, 0)
    line:SetHeight(1)
    line:SetColorTexture(0.25, 0.25, 0.25, 0.85)

    -- Player coordinate label (Left)
    playerText = overlayFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    playerText:SetPoint("LEFT", overlayFrame, "LEFT", 12, 0)
    playerText:SetJustifyH("LEFT")
    playerText:SetFormattedText(BFM.L["MAP_PLAYER_COORDS"], BFM.L["COORDS_NA"])

    -- Cursor coordinate label (Right)
    cursorText = overlayFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cursorText:SetPoint("RIGHT", overlayFrame, "RIGHT", -12, 0)
    cursorText:SetJustifyH("RIGHT")
    cursorText:SetFormattedText(BFM.L["MAP_CURSOR_COORDS"], BFM.L["COORDS_NA"])

    self:UpdateFonts()

    -- Continuous live update loop
    overlayFrame:SetScript("OnUpdate", function(self, dt)
        updateTimer = updateTimer + dt
        if updateTimer >= (BFM.Constants.WORLDMAP_UPDATE_INTERVAL or 0.05) then
            updateTimer = 0
            WorldMapCoords:UpdateCoords()
        end
    end)
end

function WorldMapCoords:UpdateFonts()
    if not overlayFrame then return end
    local db = (BFM.db and BFM.db.worldmap) or {}
    local fontName = db.coordsFont or "Nata Sans Bold"
    local fontSize = db.coordsFontSize or 11
    local outline = db.coordsFontOutline or "OUTLINE"
    if outline == "None" or outline == "NONE" then outline = "" end

    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local fontPath = (LSM and LSM:Fetch("font", fontName, true))
    if not fontPath or fontPath == "" then
        fontPath = "Fonts\\FRIZQT__.TTF"
    end

    if playerText then
        pcall(function() playerText:SetFont(fontPath, fontSize, outline) end)
    end
    if cursorText then
        pcall(function() cursorText:SetFont(fontPath, fontSize, outline) end)
    end
end

function WorldMapCoords:UpdateCoords()
    if not WorldMapFrame or not WorldMapFrame:IsShown() then return end

    local mapID = WorldMapFrame:GetMapID()

    -- 1. Update Player Coordinates
    local playerCoordStr = BFM.L["COORDS_NA"]
    if mapID then
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        if pos then
            local px, py = pos:GetXY()
            if px and py and (px ~= 0 or py ~= 0) then
                playerCoordStr = string.format(BFM.L["COORDS_FORMAT"], px * 100, py * 100)
            end
        end
    end
    if playerText then
        playerText:SetFormattedText(BFM.L["MAP_PLAYER_COORDS"], playerCoordStr)
    end

    -- 2. Update Cursor Coordinates
    local cursorCoordStr = BFM.L["COORDS_NA"]
    local scrollContainer = WorldMapFrame.ScrollContainer
    if scrollContainer and scrollContainer:IsMouseOver() then
        local cx, cy
        if scrollContainer.GetNormalizedCursorPosition then
            cx, cy = scrollContainer:GetNormalizedCursorPosition()
        elseif scrollContainer.GetCursorPosition and scrollContainer.NormalizeUIPosition then
            local rawX, rawY = scrollContainer:GetCursorPosition()
            cx, cy = scrollContainer:NormalizeUIPosition(rawX, rawY)
        end

        -- Verify cursor coordinates fall strictly within map canvas [0, 1] bounds
        if cx and cy and cx >= 0.0 and cx <= 1.0 and cy >= 0.0 and cy <= 1.0 then
            cursorCoordStr = string.format(BFM.L["COORDS_FORMAT"], cx * 100, cy * 100)
        end
    end
    if cursorText then
        cursorText:SetFormattedText(BFM.L["MAP_CURSOR_COORDS"], cursorCoordStr)
    end
end

function WorldMapCoords:UpdateVisibility()
    if not overlayFrame then return end
    if BFM.db and BFM.db.worldmap and (BFM.db.worldmap.showCoords ~= false) and WorldMapFrame:IsShown() then
        overlayFrame:Show()
    else
        overlayFrame:Hide()
    end
end

function WorldMapCoords:OnInitialize()
    if WorldMapFrame and WorldMapFrame.AddDataProvider then
        WorldMapFrame:AddDataProvider(BFM_CoordsDataProvider)
    end
end

function WorldMapCoords:OnEnable()
    self:UpdateVisibility()
    self:UpdateCoords()
end

