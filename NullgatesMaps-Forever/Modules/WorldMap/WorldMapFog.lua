--[[
    Nullgate's Maps - Forever
    Modules/WorldMap/WorldMapFog.lua - Fog of War / Map Reveal with Customizable Tint & Opacity
]]

local addonName, BFM = ...

local WorldMapFog = {}
BFM:RegisterModule("WorldMapFog", WorldMapFog)

local FogData = BFM.FogData or {}

local mod, ceil, tonumber, strsplit = math.fmod, math.ceil, tonumber, strsplit
local ipairs, pairs, wipe, tinsert = ipairs, pairs, wipe, table.insert

local tintedTextures = {}

local function TexturePool_ResetVertexColor(pool, texture)
    texture:SetVertexColor(1, 1, 1, 1)
    texture:Hide()
    texture:ClearAllPoints()
end

function WorldMapFog:OnInitialize()
    self:HookMapExplorationPins()

    if WorldMapFrame and WorldMapFrame.HookScript then
        WorldMapFrame:HookScript("OnShow", function()
            WorldMapFog:HookMapExplorationPins()
        end)
    end
end

function WorldMapFog:HookMapExplorationPins()
    if not WorldMapFrame or not WorldMapFrame.EnumeratePinsByTemplate then return end

    for pin in WorldMapFrame:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
        if not pin.bfmFogHooked then
            pin.bfmFogHooked = true
            hooksecurefunc(pin, "RefreshOverlays", function(pinSelf, fullUpdate)
                WorldMapFog:OnPinRefreshOverlays(pinSelf, fullUpdate)
            end)
            if pin.overlayTexturePool then
                pin.overlayTexturePool.resetterFunc = TexturePool_ResetVertexColor
            end
        end
    end
end

function WorldMapFog:OnPinRefreshOverlays(pin, fullUpdate)
    -- Reset previously tinted textures back to normal vertex color
    for _, tex in pairs(tintedTextures) do
        tex:SetVertexColor(1, 1, 1, 1)
    end
    wipe(tintedTextures)

    local cfg = BFM.db and BFM.db.worldmap
    if not cfg or cfg.fogClear == false then
        return
    end

    local mapCanvas = pin:GetMap()
    if not mapCanvas then return end

    local mapID = mapCanvas:GetMapID() or (WorldMapFrame and WorldMapFrame.mapID)
    if not mapID then return end

    local artID = C_Map.GetMapArtID(mapID)
    if not artID or not FogData[artID] then return end
    local zoneFogData = FogData[artID]

    local canvasContainer = mapCanvas.GetCanvasContainer and mapCanvas:GetCanvasContainer() or mapCanvas.ScrollContainer
    if not canvasContainer or type(canvasContainer.zoomLevels) ~= "table" or #canvasContainer.zoomLevels == 0 then
        return
    end

    pin.layerIndex = canvasContainer:GetCurrentLayerIndex()
    local layers = C_Map.GetMapArtLayers(mapID)
    local layerInfo = layers and layers[pin.layerIndex]
    if not layerInfo then return end

    local TILE_SIZE_WIDTH = layerInfo.tileWidth
    local TILE_SIZE_HEIGHT = layerInfo.tileHeight

    -- Store already explored tiles in a lookup table
    local exploredTilesKeyed = {}
    local exploredMapTextures = C_MapExplorationInfo.GetExploredMapTextures(mapID)
    if exploredMapTextures then
        for _, exploredTextureInfo in ipairs(exploredMapTextures) do
            local key = exploredTextureInfo.textureWidth .. ":" .. exploredTextureInfo.textureHeight .. ":" .. exploredTextureInfo.offsetX .. ":" .. exploredTextureInfo.offsetY
            exploredTilesKeyed[key] = true
        end
    end

    local r = (cfg.fogColor and cfg.fogColor.r) or 0.90
    local g = (cfg.fogColor and cfg.fogColor.g) or 0.90
    local b = (cfg.fogColor and cfg.fogColor.b) or 1.00
    local a = cfg.fogAlpha or 0.60

    for key, files in pairs(zoneFogData) do
        if not exploredTilesKeyed[key] then
            local widthStr, heightStr, offsetXStr, offsetYStr = strsplit(":", key)
            local width = tonumber(widthStr)
            local height = tonumber(heightStr)
            local offsetX = tonumber(offsetXStr)
            local offsetY = tonumber(offsetYStr)

            if width and height and offsetX and offsetY then
                local fileDataIDs = { strsplit(",", files) }
                local numTexturesWide = ceil(width / TILE_SIZE_WIDTH)
                local numTexturesTall = ceil(height / TILE_SIZE_HEIGHT)
                local texturePixelWidth, textureFileWidth, texturePixelHeight, textureFileHeight

                for j = 1, numTexturesTall do
                    if j < numTexturesTall then
                        texturePixelHeight = TILE_SIZE_HEIGHT
                        textureFileHeight = TILE_SIZE_HEIGHT
                    else
                        texturePixelHeight = mod(height, TILE_SIZE_HEIGHT)
                        if texturePixelHeight == 0 then
                            texturePixelHeight = TILE_SIZE_HEIGHT
                        end
                        textureFileHeight = 16
                        while textureFileHeight < texturePixelHeight do
                            textureFileHeight = textureFileHeight * 2
                        end
                    end

                    for k = 1, numTexturesWide do
                        local texture = pin.overlayTexturePool:Acquire()
                        tinsert(tintedTextures, texture)

                        if k < numTexturesWide then
                            texturePixelWidth = TILE_SIZE_WIDTH
                            textureFileWidth = TILE_SIZE_WIDTH
                        else
                            texturePixelWidth = mod(width, TILE_SIZE_WIDTH)
                            if texturePixelWidth == 0 then
                                texturePixelWidth = TILE_SIZE_WIDTH
                            end
                            textureFileWidth = 16
                            while textureFileWidth < texturePixelWidth do
                                textureFileWidth = textureFileWidth * 2
                            end
                        end

                        texture:SetSize(texturePixelWidth, texturePixelHeight)
                        texture:SetTexCoord(0, texturePixelWidth / textureFileWidth, 0, texturePixelHeight / textureFileHeight)
                        texture:SetPoint("TOPLEFT", offsetX + (TILE_SIZE_WIDTH * (k - 1)), -(offsetY + (TILE_SIZE_HEIGHT * (j - 1))))

                        local fileID = tonumber(fileDataIDs[((j - 1) * numTexturesWide) + k])
                        if fileID then
                            texture:SetTexture(fileID, nil, nil, "TRILINEAR")
                        end

                        texture:SetDrawLayer("ARTWORK", -1)
                        texture:Show()

                        if fullUpdate and pin.textureLoadGroup then
                            pin.textureLoadGroup:AddTexture(texture)
                        end

                        texture:SetVertexColor(r, g, b, a)
                    end
                end
            end
        end
    end
end

function WorldMapFog:Refresh()
    if not WorldMapFrame or not WorldMapFrame:IsShown() then return end
    if not WorldMapFrame:GetMapID() then return end

    local canvasContainer = WorldMapFrame.GetCanvasContainer and WorldMapFrame:GetCanvasContainer() or WorldMapFrame.ScrollContainer
    if not canvasContainer or type(canvasContainer.zoomLevels) ~= "table" or #canvasContainer.zoomLevels == 0 then
        return
    end

    if not WorldMapFrame.EnumeratePinsByTemplate then return end

    for pin in WorldMapFrame:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
        if pin.RefreshOverlays then
            pin:RefreshOverlays(true)
        end
    end
end
