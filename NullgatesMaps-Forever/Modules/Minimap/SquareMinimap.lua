local addonName, BFM = ...

local SquareMinimap = {}
BFM:RegisterModule("SquareMinimap", SquareMinimap)

local borderFrame
local borderTextures = {}
local backdropTexture
local moveOverlay
local questIndicator
local hookedButtons = {}
local activeQuestBlobs = {}

local function StripFrame(frame)
    if not frame then return end
    frame:Hide()
    if frame.UnregisterAllEvents then
        frame:UnregisterAllEvents()
    end
    frame:SetAlpha(0)
    if frame.HookScript then
        frame:HookScript("OnShow", frame.Hide)
    else
        frame:SetScript("OnShow", frame.Hide)
    end
end

local function StripTexture(texture)
    if not texture then return end
    texture:SetAlpha(0)
    texture:Hide()
    if texture.SetTexture then
        texture:SetTexture(nil)
    end
    if texture.SetAtlas then
        texture:SetAtlas("")
    end
end

-- 1. Square Stencil Mask & Clutter Stripping
function SquareMinimap:ApplySquareMask()
    Minimap:SetMaskTexture(BFM.Constants.MINIMAP_MASK)

    if not self.maskHooked and Minimap.SetMaskTexture then
        hooksecurefunc(Minimap, "SetMaskTexture", function(self, mask)
            if mask ~= BFM.Constants.MINIMAP_MASK then
                Minimap:SetMaskTexture(BFM.Constants.MINIMAP_MASK)
            end
        end)
        self.maskHooked = true
    end
end

function SquareMinimap:UpdateDielFrame()
    if not MinimapCluster then return end

    local dielFrame = MinimapCluster.DielFrame
    if not dielFrame then return end

    local shouldHide = BFM.db and BFM.db.minimap and (BFM.db.minimap.hideDielFrame ~= false)

    if shouldHide then
        dielFrame:Hide()
        dielFrame:SetAlpha(0)
        if dielFrame.UnregisterAllEvents then
            dielFrame:UnregisterAllEvents()
        end
        if not self.dielHooked then
            if dielFrame.HookScript then
                dielFrame:HookScript("OnShow", function(self)
                    if BFM.db and BFM.db.minimap and BFM.db.minimap.hideDielFrame ~= false then
                        self:Hide()
                    end
                end)
            end
            self.dielHooked = true
        end
    else
        dielFrame:SetAlpha(1)
        dielFrame:Show()
        dielFrame:RegisterEvent("DIEL_CYCLE_CHANGED")
        if C_DateAndTime and C_DateAndTime.IsDayTime and dielFrame.Background then
            local isDayTime = C_DateAndTime.IsDayTime()
            local atlas = isDayTime and "UI-HUD-Minimap-DayCycle" or "UI-HUD-Minimap-NightCycle"
            dielFrame.Background:SetAtlas(atlas, true)
        end
    end
end

function SquareMinimap:StripDefaultArtwork()
    local framesToStrip = {
        MinimapBorder,
        MinimapBorderTop,
        MinimapNorthTag,
        MinimapZoomIn,
        MinimapZoomOut,
        MiniMapWorldMapButton,
        MinimapBackdrop,
    }

    if MinimapCluster then
        if MinimapCluster.BorderTop then
            MinimapCluster.BorderTop.ignoreInLayout = true
            MinimapCluster.BorderTop:ClearAllPoints()
            MinimapCluster.BorderTop:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
            table.insert(framesToStrip, MinimapCluster.BorderTop)
        end
        if MinimapCluster.ZoneTextButton then
            MinimapCluster.ZoneTextButton.ignoreInLayout = true
            MinimapCluster.ZoneTextButton:ClearAllPoints()
            MinimapCluster.ZoneTextButton:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
            table.insert(framesToStrip, MinimapCluster.ZoneTextButton)
        end
        if MinimapCluster.Tracking and MinimapCluster.Tracking.Background then
            StripTexture(MinimapCluster.Tracking.Background)
        end
        if MinimapCluster.MinimapContainer then
            MinimapCluster.MinimapContainer:ClearAllPoints()
            MinimapCluster.MinimapContainer:SetAllPoints(MinimapCluster)
        end
        Minimap:ClearAllPoints()
        Minimap:SetAllPoints(MinimapCluster.MinimapContainer or MinimapCluster)
        MinimapCluster:SetClampRectInsets(0, 0, -20, 0)
        MinimapCluster:SetHitRectInsets(0, 0, 0, 0)
        MinimapCluster:SetClampedToScreen(true)
    end


    if Minimap then
        if Minimap.ZoomIn then table.insert(framesToStrip, Minimap.ZoomIn) end
        if Minimap.ZoomOut then table.insert(framesToStrip, Minimap.ZoomOut) end
        if Minimap.ZoomHitArea then table.insert(framesToStrip, Minimap.ZoomHitArea) end
    end

    for _, frame in ipairs(framesToStrip) do
        StripFrame(frame)
    end

    StripTexture(MinimapCompassTexture)
    StripTexture(MinimapCompassTextureUnderlay)
    if MiniMapTrackingBorder then
        StripTexture(MiniMapTrackingBorder)
    end

    self:UpdateDielFrame()
    self:SuppressRoundQuestBlobRings()
end

-- 2. Square Quest Zone Indicator & Round Ring Suppression
function SquareMinimap:SuppressRoundQuestBlobRings()
    if Minimap.SetQuestBlobRingAlpha then Minimap:SetQuestBlobRingAlpha(0) end
    if Minimap.SetTaskBlobRingAlpha then Minimap:SetTaskBlobRingAlpha(0) end
    if Minimap.SetArchBlobRingAlpha then Minimap:SetArchBlobRingAlpha(0) end
end

function SquareMinimap:SetupQuestZoneIndicator()
    if questIndicator or not borderFrame then return end

    questIndicator = CreateFrame("Frame", "BFM_SquareQuestZoneIndicator", borderFrame)
    questIndicator:SetAllPoints(Minimap)
    questIndicator:SetFrameLevel(borderFrame:GetFrameLevel() + 5)
    questIndicator:Hide()

    questIndicator.top = questIndicator:CreateTexture(nil, "OVERLAY")
    questIndicator.bottom = questIndicator:CreateTexture(nil, "OVERLAY")
    questIndicator.left = questIndicator:CreateTexture(nil, "OVERLAY")
    questIndicator.right = questIndicator:CreateTexture(nil, "OVERLAY")

    local animGroup = questIndicator:CreateAnimationGroup()
    animGroup:SetLooping("BOUNCE")
    local alphaAnim = animGroup:CreateAnimation("Alpha")
    alphaAnim:SetFromAlpha(0.6)
    alphaAnim:SetToAlpha(1.0)
    alphaAnim:SetDuration(1.2)
    questIndicator.anim = animGroup

    self:UpdateQuestZoneIndicator()
end

function SquareMinimap:UpdateQuestZoneIndicator()
    if not questIndicator then return end

    local thickness = math.max(2, (BFM.db.minimap.borderSize or 1) + 1)
    local r, g, b = 1.0, 0.82, 0.0

    questIndicator.top:ClearAllPoints()
    questIndicator.top:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -thickness, thickness)
    questIndicator.top:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", thickness, thickness)
    questIndicator.top:SetHeight(thickness)
    questIndicator.top:SetColorTexture(r, g, b, 0.95)

    questIndicator.bottom:ClearAllPoints()
    questIndicator.bottom:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -thickness, -thickness)
    questIndicator.bottom:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", thickness, -thickness)
    questIndicator.bottom:SetHeight(thickness)
    questIndicator.bottom:SetColorTexture(r, g, b, 0.95)

    questIndicator.left:ClearAllPoints()
    questIndicator.left:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -thickness, thickness)
    questIndicator.left:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -thickness, -thickness)
    questIndicator.left:SetWidth(thickness)
    questIndicator.left:SetColorTexture(r, g, b, 0.95)

    questIndicator.right:ClearAllPoints()
    questIndicator.right:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", thickness, thickness)
    questIndicator.right:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", thickness, -thickness)
    questIndicator.right:SetWidth(thickness)
    questIndicator.right:SetColorTexture(r, g, b, 0.95)
end

function SquareMinimap:SetQuestZoneIndicatorShown(show)
    if not questIndicator then return end
    if show and (BFM.db and BFM.db.minimap and BFM.db.minimap.questIndicator ~= false) then
        self:UpdateQuestZoneIndicator()
        questIndicator:Show()
        if not questIndicator.anim:IsPlaying() then
            questIndicator.anim:Play()
        end
    else
        questIndicator.anim:Stop()
        questIndicator:Hide()
    end
end

-- 3. Customizable Square Border
function SquareMinimap:CreateBorderFrame()
    if borderFrame then return end

    backdropTexture = Minimap:CreateTexture("BFM_MinimapBackdropTexture", "BACKGROUND", nil, -8)
    backdropTexture:SetAllPoints(Minimap)

    borderFrame = CreateFrame("Frame", "BFM_SquareMinimapBorder", Minimap)
    borderFrame:SetAllPoints(Minimap)
    borderFrame:SetFrameLevel(Minimap:GetFrameLevel() + 10)

    borderTextures.top = borderFrame:CreateTexture(nil, "OVERLAY")
    borderTextures.bottom = borderFrame:CreateTexture(nil, "OVERLAY")
    borderTextures.left = borderFrame:CreateTexture(nil, "OVERLAY")
    borderTextures.right = borderFrame:CreateTexture(nil, "OVERLAY")

    self:UpdateBorder()
    self:SetupQuestZoneIndicator()
end

function SquareMinimap:UpdateBorder()
    if not borderFrame then return end

    local cfg = BFM.db.minimap
    local style = cfg.borderStyle or "flat"
    local thickness = cfg.borderSize or 1
    local bc = cfg.borderColor or BFM.Constants.DEFAULT_BORDER_COLOR
    local bg = cfg.backdropColor or BFM.Constants.DEFAULT_BACKDROP_COLOR

    if cfg.classColorBorder then
        local _, classFileName = UnitClass("player")
        local classColor = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classFileName]) or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFileName])
        if classColor then
            bc = { r = classColor.r, g = classColor.g, b = classColor.b, a = bc.a or 1 }
        end
    end

    backdropTexture:SetColorTexture(bg.r, bg.g, bg.b, bg.a)

    if style == "none" then
        borderTextures.top:Hide()
        borderTextures.bottom:Hide()
        borderTextures.left:Hide()
        borderTextures.right:Hide()
        if borderFrame.backdropFrame then borderFrame.backdropFrame:Hide() end
    elseif style == "tooltip" or style == "dialog" then
        borderTextures.top:Hide()
        borderTextures.bottom:Hide()
        borderTextures.left:Hide()
        borderTextures.right:Hide()

        if not borderFrame.backdropFrame then
            local bf = CreateFrame("Frame", nil, borderFrame, BackdropTemplateMixin and "BackdropTemplate" or nil)
            bf:SetFrameLevel(borderFrame:GetFrameLevel() + 2)
            borderFrame.backdropFrame = bf
        end
        local edgeFile = (style == "dialog") and "Interface\\DialogFrame\\UI-DialogBox-Border" or "Interface\\Tooltips\\UI-Tooltip-Border"
        local edgeSize = (style == "dialog") and 16 or 14
        local inset = (style == "dialog") and 4 or 3
        borderFrame.backdropFrame:ClearAllPoints()
        borderFrame.backdropFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -inset, inset)
        borderFrame.backdropFrame:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", inset, -inset)
        borderFrame.backdropFrame:SetBackdrop({
            edgeFile = edgeFile,
            edgeSize = edgeSize,
        })
        borderFrame.backdropFrame:SetBackdropBorderColor(bc.r, bc.g, bc.b, bc.a)
        borderFrame.backdropFrame:Show()
    else -- "flat"
        if borderFrame.backdropFrame then borderFrame.backdropFrame:Hide() end
        borderTextures.top:Show()
        borderTextures.bottom:Show()
        borderTextures.left:Show()
        borderTextures.right:Show()

        borderTextures.top:ClearAllPoints()
        borderTextures.top:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -thickness, thickness)
        borderTextures.top:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", thickness, thickness)
        borderTextures.top:SetHeight(thickness)
        borderTextures.top:SetColorTexture(bc.r, bc.g, bc.b, bc.a)

        borderTextures.bottom:ClearAllPoints()
        borderTextures.bottom:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -thickness, -thickness)
        borderTextures.bottom:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", thickness, -thickness)
        borderTextures.bottom:SetHeight(thickness)
        borderTextures.bottom:SetColorTexture(bc.r, bc.g, bc.b, bc.a)

        borderTextures.left:ClearAllPoints()
        borderTextures.left:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -thickness, thickness)
        borderTextures.left:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -thickness, -thickness)
        borderTextures.left:SetWidth(thickness)
        borderTextures.left:SetColorTexture(bc.r, bc.g, bc.b, bc.a)

        borderTextures.right:ClearAllPoints()
        borderTextures.right:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", thickness, thickness)
        borderTextures.right:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", thickness, -thickness)
        borderTextures.right:SetWidth(thickness)
        borderTextures.right:SetColorTexture(bc.r, bc.g, bc.b, bc.a)
    end

    self:UpdateQuestZoneIndicator()
end

-- 4. Minimap Resizing
function SquareMinimap:RefreshMinimapTexture()
    self:ApplySquareMask()

    local currentZoom = Minimap:GetZoom()
    local maxZoom = (Minimap:GetZoomLevels() or 1) - 1
    if currentZoom < maxZoom then
        Minimap:SetZoom(currentZoom + 1)
        Minimap:SetZoom(currentZoom)
    elseif currentZoom > 0 then
        Minimap:SetZoom(currentZoom - 1)
        Minimap:SetZoom(currentZoom)
    else
        Minimap:SetZoom(0)
    end

    if Minimap.UpdateBlips then
        pcall(Minimap.UpdateBlips, Minimap)
    end
    if Minimap_Update then
        pcall(Minimap_Update)
    end
end

function SquareMinimap:SetMinimapSize(size)
    if not size or size < 80 then size = 140 end
    if size > 512 then size = 512 end
    BFM.db.minimap.size = size

    if MinimapCluster then
        MinimapCluster:SetSize(size, size)
        if MinimapCluster.SetFixedSize then
            pcall(MinimapCluster.SetFixedSize, MinimapCluster, size, size)
        end
        MinimapCluster.fixedWidth = size
        MinimapCluster.fixedHeight = size
        MinimapCluster.widthPadding = 0
        MinimapCluster.heightPadding = 0
        MinimapCluster.ignoreAllChildren = true
        MinimapCluster:SetClampRectInsets(0, 0, -20, 0)
        MinimapCluster:SetHitRectInsets(0, 0, 0, 0)
        MinimapCluster:SetClampedToScreen(true)

        if MinimapCluster.MinimapContainer then
            MinimapCluster.MinimapContainer:ClearAllPoints()
            MinimapCluster.MinimapContainer:SetAllPoints(MinimapCluster)
            MinimapCluster.MinimapContainer:SetSize(size, size)
        end
    end

    Minimap:ClearAllPoints()
    if MinimapCluster and MinimapCluster.MinimapContainer then
        Minimap:SetAllPoints(MinimapCluster.MinimapContainer)
    elseif MinimapCluster then
        Minimap:SetAllPoints(MinimapCluster)
    end
    Minimap:SetSize(size, size)

    if MinimapBackdrop then
        MinimapBackdrop:ClearAllPoints()
        MinimapBackdrop:SetAllPoints(Minimap)
        MinimapBackdrop:SetSize(size, size)
    end

    self:RefreshMinimapTexture()
    self:UpdateBorder()
    self:PositionElements()
    self:PositionClock()
    self:ScanMinimapButtons()

    local coordsModule = BFM.modules["MinimapCoords"]
    if coordsModule and coordsModule.UpdateLayout then
        coordsModule:UpdateLayout()
    end
end

-- 5. Minimap Movement & Dragging
function SquareMinimap:SavePosition()
    if not MinimapCluster then return end
    local point, relativeTo, relativePoint, x, y = MinimapCluster:GetPoint()
    if point and x and y then
        BFM.db.minimap.position = {
            point = point,
            relativePoint = relativePoint or point,
            x = math.floor(x + 0.5),
            y = math.floor(y + 0.5),
        }
    end
end

function SquareMinimap:RestorePosition()
    if not MinimapCluster then return end
    local pos = BFM.db and BFM.db.minimap and BFM.db.minimap.position
    self.isPositioning = true
    MinimapCluster:SetMovable(true)
    MinimapCluster:ClearAllPoints()
    if pos and pos.point and pos.x and pos.y then
        MinimapCluster:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x, pos.y)
        if MinimapCluster.SetUserPlaced then
            pcall(MinimapCluster.SetUserPlaced, MinimapCluster, true)
        end
    else
        MinimapCluster:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -10, -10)
        if MinimapCluster.SetUserPlaced then
            pcall(MinimapCluster.SetUserPlaced, MinimapCluster, false)
        end
    end
    self.isPositioning = false
end

function SquareMinimap:ResetPosition()
    if not MinimapCluster then return end
    BFM.db.minimap.position = nil
    self.isPositioning = true
    MinimapCluster:SetMovable(true)
    MinimapCluster:ClearAllPoints()
    MinimapCluster:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -10, -10)
    if MinimapCluster.SetUserPlaced then
        pcall(MinimapCluster.SetUserPlaced, MinimapCluster, false)
    end
    self.isPositioning = false
end


function SquareMinimap:CreateMoveOverlay()
    if moveOverlay then return end

    moveOverlay = CreateFrame("Button", "BFM_MinimapMoveOverlay", Minimap)
    moveOverlay:SetAllPoints(Minimap)
    moveOverlay:SetFrameLevel(Minimap:GetFrameLevel() + 25)
    moveOverlay:EnableMouse(true)
    moveOverlay:RegisterForDrag("LeftButton")
    moveOverlay:Hide()

    local bg = moveOverlay:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.0, 0.6, 1.0, 0.4)

    local text = moveOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("CENTER")
    text:SetText("|cff00c0ffMinimap Unlocked|r\nClick & Drag to Move")
    text:SetJustifyH("CENTER")

    moveOverlay:SetScript("OnDragStart", function()
        MinimapCluster:SetMovable(true)
        MinimapCluster:SetClampRectInsets(0, 0, -20, 0)
        MinimapCluster:StartMoving()
    end)
    moveOverlay:SetScript("OnDragStop", function()
        MinimapCluster:StopMovingOrSizing()
        SquareMinimap:SavePosition()
    end)

    -- Also allow Alt-drag directly on Minimap even when locked
    Minimap:HookScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and (IsAltKeyDown() or (BFM.db and BFM.db.minimap and BFM.db.minimap.unlocked)) then
            MinimapCluster:SetMovable(true)
            MinimapCluster:SetClampRectInsets(0, 0, -20, 0)
            MinimapCluster:StartMoving()
            SquareMinimap.isMinimapDragging = true
        end
    end)
    Minimap:HookScript("OnMouseUp", function(self, button)
        if SquareMinimap.isMinimapDragging then
            MinimapCluster:StopMovingOrSizing()
            SquareMinimap.isMinimapDragging = false
            SquareMinimap:SavePosition()
        end
    end)
end

function SquareMinimap:UpdateMoveOverlay()
    if not moveOverlay then
        self:CreateMoveOverlay()
    end
    if BFM.db and BFM.db.minimap and BFM.db.minimap.unlocked then
        moveOverlay:Show()
    else
        moveOverlay:Hide()
    end
end

function SquareMinimap:ToggleMovers(state)
    if not BFM.db or not BFM.db.minimap then return false end
    if state ~= nil then
        BFM.db.minimap.unlocked = state
    else
        BFM.db.minimap.unlocked = not BFM.db.minimap.unlocked
    end
    self:UpdateMoveOverlay()
    return BFM.db.minimap.unlocked
end

function SquareMinimap:IsMoversUnlocked()
    return (BFM.db and BFM.db.minimap and BFM.db.minimap.unlocked == true) or false
end

-- 6. Mouse Wheel Zoom
function SquareMinimap:SetupMouseWheelZoom()
    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(self, delta)
        if BFM.db and BFM.db.minimap and BFM.db.minimap.enableMouseWheelZoom == false then
            return
        end
        local currentZoom = Minimap:GetZoom()
        local maxZoom = Minimap:GetZoomLevels() - 1

        if delta > 0 then
            if currentZoom < maxZoom then
                Minimap:SetZoom(currentZoom + 1)
            end
        elseif delta < 0 then
            if currentZoom > 0 then
                Minimap:SetZoom(currentZoom - 1)
            end
        end
    end)
end

-- 7. Positioning Interface Elements
function SquareMinimap:PositionElements()
    local trackerScale = (BFM.db and BFM.db.minimap and BFM.db.minimap.trackerScale) or 0.85
    local calendarScale = (BFM.db and BFM.db.minimap and BFM.db.minimap.calendarScale) or 0.80

    local trackingFrame = (MinimapCluster and MinimapCluster.Tracking) or MiniMapTracking or MiniMapTrackingFrame
    if trackingFrame then
        trackingFrame:ClearAllPoints()
        trackingFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 2, -2)
        trackingFrame:SetScale(trackerScale)
    end

    local mailFrame = (MinimapCluster and MinimapCluster.IndicatorFrame) or MiniMapMailFrame
    if mailFrame then
        mailFrame:ClearAllPoints()
        mailFrame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -2, -2)
        mailFrame:SetScale(0.85)
    end

    local compartment = AddonCompartmentFrame or (MinimapCluster and MinimapCluster.AddonCompartmentButton) or AddonCompartmentButton
    if compartment then
        compartment:ClearAllPoints()
        compartment:SetPoint("BOTTOMRIGHT", Minimap, "TOPRIGHT", 0, 4)
        compartment:SetScale(0.85)
    end

    if GameTimeFrame then
        GameTimeFrame:ClearAllPoints()
        GameTimeFrame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 2, 2)
        GameTimeFrame:SetScale(calendarScale)
    end

    self:PositionClock()
end

function SquareMinimap:PositionClock()
    local clockBtn = TimeManagerClockButton
    if not clockBtn then
        if not self.timeManagerWatcher then
            local watcher = CreateFrame("Frame")
            watcher:RegisterEvent("ADDON_LOADED")
            watcher:SetScript("OnEvent", function(f, event, name)
                if name == "Blizzard_TimeManager" or TimeManagerClockButton then
                    SquareMinimap:PositionClock()
                    f:UnregisterAllEvents()
                end
            end)
            self.timeManagerWatcher = watcher
        end
        return
    end

    local timeScale = (BFM.db and BFM.db.minimap and BFM.db.minimap.timeScale) or 0.85

    clockBtn.ignoreInLayout = true
    clockBtn:SetParent(Minimap)
    clockBtn:SetFrameLevel(Minimap:GetFrameLevel() + 15)
    clockBtn:ClearAllPoints()
    clockBtn:SetPoint("TOP", Minimap, "TOP", 0, -2)
    clockBtn:SetScale(timeScale)

    if not clockBtn.bfmBg then
        local bg = clockBtn:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT", clockBtn, "TOPLEFT", 4, -1)
        bg:SetPoint("BOTTOMRIGHT", clockBtn, "BOTTOMRIGHT", -2, 1)
        bg:SetColorTexture(0, 0, 0, 0.55)
        clockBtn.bfmBg = bg
    end

    if not self.clockHooked then
        hooksecurefunc(clockBtn, "SetPoint", function(self, point, relTo)
            if not SquareMinimap.isPositioningClock and relTo ~= Minimap then
                SquareMinimap.isPositioningClock = true
                self:ClearAllPoints()
                self:SetPoint("TOP", Minimap, "TOP", 0, -2)
                SquareMinimap.isPositioningClock = false
            end
        end)
        self.clockHooked = true
    end
end


-- 8. Square Minimap Icon Projection
function SquareMinimap:ProjectButtonToSquare(button)
    if not button or button.__bfm_repositioning then return end
    if not (BFM.db and BFM.db.minimap and BFM.db.minimap.squareIcons ~= false) then return end

    local numPoints = button:GetNumPoints()
    if numPoints == 0 then return end

    local point, relativeTo, relativePoint, x, y = button:GetPoint()
    if (relativeTo == Minimap or relativeTo == MinimapCluster or relativeTo == MinimapBackdrop) and x and y then
        local dist = math.sqrt(x * x + y * y)
        local halfWidth = (Minimap:GetWidth() or 140) / 2
        local halfHeight = (Minimap:GetHeight() or 140) / 2
        local radius = math.max(halfWidth, halfHeight)

        if dist > radius * 0.4 and dist < radius * 1.8 then
            local maxCoord = math.max(math.abs(x), math.abs(y))
            if maxCoord > 0 then
                local targetRadius = radius + 2
                local factor = targetRadius / maxCoord
                local targetX = x * factor
                local targetY = y * factor

                button.__bfm_repositioning = true
                button:ClearAllPoints()
                button:SetPoint("CENTER", Minimap, "CENTER", targetX, targetY)
                button.__bfm_repositioning = false
            end
        end
    end
end

function SquareMinimap:HookMinimapButton(button)
    if not button or hookedButtons[button] then return end
    hookedButtons[button] = true

    if button.HookScript then
        hooksecurefunc(button, "SetPoint", function(btn, pt, relTo, relPt, x, y)
            if not btn.__bfm_repositioning and (relTo == Minimap or relTo == MinimapBackdrop) then
                SquareMinimap:ProjectButtonToSquare(btn)
            end
        end)
    end

    self:ProjectButtonToSquare(button)
end

function SquareMinimap:RefreshLibDBIcon()
    if LibStub then
        local LDBIcon = LibStub("LibDBIcon-1.0", true)
        if LDBIcon and LDBIcon.GetButtonList and LDBIcon.Refresh then
            for _, buttonName in ipairs(LDBIcon:GetButtonList()) do
                LDBIcon:Refresh(buttonName)
            end
        end
    end
end

function SquareMinimap:ScanMinimapButtons()
    if not (BFM.db and BFM.db.minimap and BFM.db.minimap.squareIcons ~= false) then return end

    self:RefreshLibDBIcon()

    local children = { Minimap:GetChildren() }
    for _, child in ipairs(children) do
        if child and not child:IsForbidden() then
            local name = child:GetName() or ""
            if not child.__bfm_ignore and child ~= borderFrame and child ~= MinimapBackdrop and child ~= moveOverlay and not string.find(name, "BFM_") then
                if child:IsObjectType("Button") or (child:IsObjectType("Frame") and child:HasScript("OnMouseDown")) then
                    self:HookMinimapButton(child)
                end
            end
        end
    end
end

-- 9. Lifecycle
function SquareMinimap:OnInitialize()
    self:ApplySquareMask()
    self:StripDefaultArtwork()
    self:CreateBorderFrame()
    self:CreateMoveOverlay()
    self:SetupMouseWheelZoom()
    self:PositionElements()
    self:ScanMinimapButtons()

    -- Quest zone indicator event listener
    local questEventFrame = CreateFrame("Frame")
    questEventFrame:RegisterEvent("PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED")
    questEventFrame:RegisterEvent("QUEST_LOG_UPDATE")
    questEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    questEventFrame:SetScript("OnEvent", function(self, event, arg1, arg2)
        if event == "PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED" then
            local questID, isInside = arg1, arg2
            activeQuestBlobs[questID] = isInside
            local anyInside = false
            for _, inside in pairs(activeQuestBlobs) do
                if inside then
                    anyInside = true
                    break
                end
            end
            SquareMinimap:SetQuestZoneIndicatorShown(anyInside)
        elseif event == "PLAYER_ENTERING_WORLD" then
            table.wipe(activeQuestBlobs)
            SquareMinimap:SetQuestZoneIndicatorShown(false)
            SquareMinimap:RestorePosition()
            SquareMinimap:SuppressRoundQuestBlobRings()
        end
    end)
end

function SquareMinimap:OnEnable()
    self:ApplySquareMask()
    self:UpdateDielFrame()
    self:SuppressRoundQuestBlobRings()
    self:PositionElements()

    if BFM.db and BFM.db.minimap and BFM.db.minimap.size then
        self:SetMinimapSize(BFM.db.minimap.size)
    else
        self:UpdateBorder()
    end

    self:RestorePosition()
    self:UpdateMoveOverlay()
    self:ScanMinimapButtons()

    -- Ensure position persists if Blizzard layout triggers
    if MinimapCluster and not self.positionHooked then
        hooksecurefunc(MinimapCluster, "SetPoint", function()
            if not SquareMinimap.isPositioning and BFM.db and BFM.db.minimap and BFM.db.minimap.position then
                SquareMinimap:RestorePosition()
            end
        end)
        self.positionHooked = true
    end

    if MinimapCluster and not self.layoutHooked then
        if MinimapCluster.Layout then
            hooksecurefunc(MinimapCluster, "Layout", function(cluster)
                local s = BFM.db and BFM.db.minimap and BFM.db.minimap.size or 140
                cluster:SetSize(s, s)
                cluster.fixedWidth = s
                cluster.fixedHeight = s
                cluster.widthPadding = 0
                cluster.heightPadding = 0
                cluster:SetClampRectInsets(0, 0, -20, 0)
                if cluster.MinimapContainer then
                    cluster.MinimapContainer:ClearAllPoints()
                    cluster.MinimapContainer:SetAllPoints(cluster)
                    cluster.MinimapContainer:SetSize(s, s)
                end
                Minimap:ClearAllPoints()
                Minimap:SetAllPoints(cluster.MinimapContainer or cluster)
                Minimap:SetSize(s, s)
            end)
        end
        self.layoutHooked = true
    end

    if MinimapCluster and MinimapCluster.MinimapContainer and not self.containerHooked then
        hooksecurefunc(MinimapCluster.MinimapContainer, "SetPoint", function(container)
            if not SquareMinimap.isReanchoringContainer then
                SquareMinimap.isReanchoringContainer = true
                container:ClearAllPoints()
                container:SetAllPoints(MinimapCluster)
                SquareMinimap.isReanchoringContainer = false
            end
        end)
        self.containerHooked = true
    end

    if Minimap and not self.minimapPointHooked then
        hooksecurefunc(Minimap, "SetPoint", function(m)
            if not SquareMinimap.isReanchoringMinimap then
                SquareMinimap.isReanchoringMinimap = true
                m:ClearAllPoints()
                m:SetAllPoints(MinimapCluster and MinimapCluster.MinimapContainer or MinimapCluster)
                SquareMinimap.isReanchoringMinimap = false
            end
        end)
        self.minimapPointHooked = true
    end

    Minimap:HookScript("OnEnter", function()
        SquareMinimap:ScanMinimapButtons()
    end)
    if C_Timer and C_Timer.After then
        C_Timer.After(2, function()
            SquareMinimap:ScanMinimapButtons()
        end)
    end
end
