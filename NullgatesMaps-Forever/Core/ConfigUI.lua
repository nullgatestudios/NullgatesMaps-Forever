--[[
    Nullgate's Maps - Forever
    Core/ConfigUI.lua - Standalone Master Configuration Window & BAC Embed UI
    Tabs: General Settings, Minimap Settings, World Map Settings
]]

local addonName, BFM = ...

local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil

-- Reusable backdrop definitions matching Nullgate's Addon Config
local MAIN_WINDOW_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

local INSET_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 12,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

-- UI Color Palette: Dark slate/iron with gold accents
local COLORS = {
    bgSlate      = { 0.08, 0.10, 0.13, 0.96 },
    sidebarBg    = { 0.06, 0.07, 0.09, 0.92 },
    contentBg    = { 0.05, 0.06, 0.08, 0.94 },
    goldBorder   = { 0.82, 0.68, 0.28, 1.00 },
    goldMuted    = { 0.50, 0.42, 0.20, 0.85 },
    goldText     = { 1.00, 0.82, 0.25 },       -- #FFD140
    whiteText    = { 0.90, 0.92, 0.94 },
    dimText      = { 0.55, 0.58, 0.63 },
    tabNormal    = { 0.12, 0.14, 0.17, 0.65 },
    tabHighlight = { 0.20, 0.22, 0.27, 0.80 },
    tabActive    = { 0.22, 0.19, 0.12, 0.95 },
}

-- Preset definitions
local BORDER_STYLES = {
    { key = "flat",    label = "Flat (Modern Sleek 1px)" },
    { key = "tooltip", label = "Blizzard Tooltip" },
    { key = "dialog",  label = "Blizzard Dialog" },
    { key = "none",    label = "None (Borderless)" },
}

local FOG_PRESETS = {
    { key = "softhaze",   label = "Soft Haze",        r = 0.80, g = 0.90, b = 1.00, a = 0.60 },
    { key = "parchment",  label = "Parchment Shadow", r = 0.85, g = 0.75, b = 0.55, a = 0.55 },
    { key = "fullvis",    label = "Full Visibility",  r = 1.00, g = 1.00, b = 1.00, a = 1.00 },
}

local OUTLINE_OPTIONS = {
    { key = "OUTLINE",      label = "Outline" },
    { key = "THICKOUTLINE", label = "Thick Outline" },
    { key = "NONE",         label = "None" },
}

local standaloneFrame

local function SetupAutoScroll(scrollFrame, scrollChild)
    if not (scrollFrame and scrollChild) then return end
    local scrollBar = _G[scrollFrame:GetName() and (scrollFrame:GetName() .. "ScrollBar")]

    local function UpdateScrollState()
        local frameHeight = scrollFrame:GetHeight()
        local childHeight = scrollChild:GetHeight()
        if not frameHeight or frameHeight <= 0 then return end
        if childHeight <= frameHeight + 2 then
            if scrollBar and scrollBar:IsShown() then
                scrollBar:Hide()
            end
            scrollFrame:EnableMouseWheel(false)
            scrollFrame:SetVerticalScroll(0)
        else
            if scrollBar and not scrollBar:IsShown() then
                scrollBar:Show()
            end
            scrollFrame:EnableMouseWheel(true)
        end
    end

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local frameHeight = self:GetHeight()
        local childHeight = scrollChild:GetHeight()
        if not frameHeight or childHeight <= frameHeight + 2 then return end
        local cur = self:GetVerticalScroll()
        local maxScroll = math.max(0, childHeight - frameHeight)
        local step = 32
        local newScroll = cur - (delta * step)
        if newScroll < 0 then newScroll = 0 end
        if newScroll > maxScroll then newScroll = maxScroll end
        self:SetVerticalScroll(newScroll)
    end)

    scrollFrame:HookScript("OnSizeChanged", UpdateScrollState)
    scrollChild:HookScript("OnSizeChanged", UpdateScrollState)
    scrollFrame:HookScript("OnShow", UpdateScrollState)
    UpdateScrollState()
    return UpdateScrollState
end

--[[-----------------------------------------------------------------------------
    Helper: Section Header
-------------------------------------------------------------------------------]]
local function CreateSectionHeader(parent, text, xOfs, yOfs)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", xOfs or 16, yOfs or -10)
    header:SetText(text)
    header:SetTextColor(COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])

    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    divider:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
    divider:SetColorTexture(COLORS.goldMuted[1], COLORS.goldMuted[2], COLORS.goldMuted[3], 0.5)

    return header, divider
end

--[[-----------------------------------------------------------------------------
    Helper: Checkbox
-------------------------------------------------------------------------------]]
local function CreateStyledCheckbox(parent, labelText, tooltipText, getFunc, setFunc)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(22, 22)

    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", cb, "RIGHT", 6, 1)
    text:SetText(labelText)
    text:SetWordWrap(true)
    text:SetJustifyH("LEFT")
    cb.Text = text

    if tooltipText then
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(labelText, COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
            GameTooltip:AddLine(tooltipText, COLORS.whiteText[1], COLORS.whiteText[2], COLORS.whiteText[3], true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    cb:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
        if setFunc then
            setFunc(checked)
        end
    end)

    cb.Sync = function()
        if getFunc then
            cb:SetChecked(getFunc() == true)
        end
    end

    return cb
end

--[[-----------------------------------------------------------------------------
    Helper: Slider (Non-overlapping value text & proper vertical clearance)
-------------------------------------------------------------------------------]]
local function CreateStyledSlider(parent, name, labelText, tooltipText, minVal, maxVal, step, getFunc, setFunc, formatStr)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetWidth(190)
    slider:SetHeight(16)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    -- Label anchored to TOPLEFT of slider
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 4)
    label:SetText(labelText)
    label:SetTextColor(COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
    slider.Label = label

    local lowText = _G[slider:GetName() .. "Low"]
    local highText = _G[slider:GetName() .. "High"]
    local valText = _G[slider:GetName() .. "Text"]

    if lowText then
        lowText:SetText(tostring(minVal))
        lowText:SetTextColor(COLORS.dimText[1], COLORS.dimText[2], COLORS.dimText[3])
    end
    if highText then
        highText:SetText(tostring(maxVal))
        highText:SetTextColor(COLORS.dimText[1], COLORS.dimText[2], COLORS.dimText[3])
    end

    -- Value text anchored to TOPRIGHT of slider to prevent ANY overlap with label
    if valText then
        valText:ClearAllPoints()
        valText:SetPoint("BOTTOMRIGHT", slider, "TOPRIGHT", 0, 4)
        valText:SetJustifyH("RIGHT")
        valText:SetTextColor(COLORS.whiteText[1], COLORS.whiteText[2], COLORS.whiteText[3])
    end

    formatStr = formatStr or "%d"

    slider:SetScript("OnValueChanged", function(self, value)
        local steppedValue = math.floor((value / step) + 0.5) * step
        if valText then
            valText:SetText(string.format(formatStr, steppedValue))
        end
        if not self.isSyncing and setFunc then
            setFunc(steppedValue)
        end
    end)

    if tooltipText then
        slider:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(labelText, COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
            GameTooltip:AddLine(tooltipText, COLORS.whiteText[1], COLORS.whiteText[2], COLORS.whiteText[3], true)
            GameTooltip:Show()
        end)
        slider:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    slider.Sync = function(self)
        if getFunc then
            local cur = getFunc() or minVal
            self.isSyncing = true
            self:SetValue(cur)
            self.isSyncing = false
            if valText then
                valText:SetText(string.format(formatStr, cur))
            end
        end
    end

    return slider
end

--[[-----------------------------------------------------------------------------
    Helper: Button
-------------------------------------------------------------------------------]]
local function CreateStyledButton(parent, text, width, height, onClick, tooltipText)
    local btn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    btn:SetSize(width or 120, height or 22)
    btn:SetBackdrop(INSET_BACKDROP)
    btn:SetBackdropColor(unpack(COLORS.tabNormal))
    btn:SetBackdropBorderColor(unpack(COLORS.goldMuted))

    local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
    btnText:SetText(text)
    btn.Text = btnText

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(COLORS.tabHighlight))
        self:SetBackdropBorderColor(unpack(COLORS.goldBorder))
        if tooltipText then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(text, COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
            GameTooltip:AddLine(tooltipText, COLORS.whiteText[1], COLORS.whiteText[2], COLORS.whiteText[3], true)
            GameTooltip:Show()
        end
    end)

    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(COLORS.tabNormal))
        self:SetBackdropBorderColor(unpack(COLORS.goldMuted))
        if tooltipText then
            GameTooltip:Hide()
        end
    end)

    btn:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
        if onClick then
            onClick(self)
        end
    end)

    return btn
end

--[[-----------------------------------------------------------------------------
    Helper: Color Picker
-------------------------------------------------------------------------------]]
local function OpenColorPicker(initialColor, onColorChanged)
    local r = initialColor and initialColor.r or 0
    local g = initialColor and initialColor.g or 0
    local b = initialColor and initialColor.b or 0
    local a = initialColor and initialColor.a or 1

    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b, opacity = a, hasOpacity = true,
            swatchFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = OpacitySliderFrame and OpacitySliderFrame:GetValue() or 1
                onColorChanged(nr, ng, nb, na)
            end,
            opacityFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = OpacitySliderFrame and OpacitySliderFrame:GetValue() or 1
                onColorChanged(nr, ng, nb, na)
            end,
            cancelFunc = function(prev)
                if prev then
                    onColorChanged(prev.r or r, prev.g or g, prev.b or b, prev.opacity or a)
                else
                    onColorChanged(r, g, b, a)
                end
            end,
        })
    else
        ColorPickerFrame.hasOpacity = true
        ColorPickerFrame.opacity = a
        ColorPickerFrame.func = function()
            local nr, ng, nb = ColorPickerFrame:GetColorRGB()
            local na = OpacitySliderFrame and OpacitySliderFrame:GetValue() or 1
            onColorChanged(nr, ng, nb, na)
        end
        ColorPickerFrame.opacityFunc = ColorPickerFrame.func
        ColorPickerFrame.cancelFunc = function()
            onColorChanged(r, g, b, a)
        end
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame:Show()
    end
end

--[[-----------------------------------------------------------------------------
    Helper: Dropdown & Font Dropdown (Custom Dark Slate & Gold Popup)
-------------------------------------------------------------------------------]]
local sharedDropdownMenu = nil
local sharedDropdownCatcher = nil

local function GetOrCreateLocalDropdownMenu()
    if sharedDropdownMenu then return sharedDropdownMenu end

    sharedDropdownCatcher = CreateFrame("Button", "BFM_DropdownCatcher", UIParent)
    sharedDropdownCatcher:SetFrameStrata("FULLSCREEN_DIALOG")
    sharedDropdownCatcher:SetFrameLevel(98)
    sharedDropdownCatcher:SetAllPoints(UIParent)
    sharedDropdownCatcher:EnableMouse(true)
    sharedDropdownCatcher:Hide()
    sharedDropdownCatcher:SetScript("OnClick", function()
        if sharedDropdownMenu then sharedDropdownMenu:Hide() end
    end)

    local menu = CreateFrame("Frame", "BFM_DropdownMenu", UIParent, BACKDROP_TEMPLATE)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetFrameLevel(99)
    menu:SetClampedToScreen(true)
    menu:SetBackdrop(INSET_BACKDROP)
    menu:SetBackdropColor(0.08, 0.10, 0.13, 0.98)
    menu:SetBackdropBorderColor(unpack(COLORS.goldBorder))
    menu:EnableMouse(true)
    menu:Hide()

    menu:SetScript("OnShow", function()
        sharedDropdownCatcher:Show()
    end)
    menu:SetScript("OnHide", function()
        sharedDropdownCatcher:Hide()
    end)

    local scrollFrame = CreateFrame("ScrollFrame", "BFM_DropdownScrollFrame", menu, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -22, 4)
    menu.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(150, 100)
    scrollFrame:SetScrollChild(scrollChild)
    menu.scrollChild = scrollChild

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local maxS = math.max(0, scrollChild:GetHeight() - self:GetHeight())
        local newS = math.min(maxS, math.max(0, cur - (delta * 22)))
        self:SetVerticalScroll(newS)
    end)

    menu.buttons = {}
    sharedDropdownMenu = menu
    return menu
end

local function NormalizeDropdownItems(items)
    local list = {}
    if type(items) == "table" then
        if #items > 0 then
            for _, item in ipairs(items) do
                if type(item) == "table" then
                    local val = (item.value ~= nil) and item.value or ((item.key ~= nil) and item.key or item[1])
                    local text = item.text or item.label or item[2] or tostring(val)
                    table.insert(list, { key = val, label = text, value = val, text = text })
                else
                    table.insert(list, { key = item, label = tostring(item), value = item, text = tostring(item) })
                end
            end
        else
            for k, v in pairs(items) do
                table.insert(list, { key = k, label = tostring(v), value = k, text = tostring(v) })
            end
            table.sort(list, function(a, b) return a.label:lower() < b.label:lower() end)
        end
    end
    return list
end

local function GetAvailableFonts()
    local fonts = {}
    local seen = {}
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM and LSM.List then
        local lsmList = LSM:List("font")
        if lsmList then
            for _, f in ipairs(lsmList) do
                if not seen[f] then
                    table.insert(fonts, { key = f, label = f })
                    seen[f] = true
                end
            end
        end
    end
    local standardFonts = {
        "Nata Sans Regular", "Nata Sans Bold", "Nata Sans Medium",
        "NullgateUI Regular", "NullgateUI Bold",
        "Friz Quadrata TT", "Arial Narrow", "Skurri", "Morpheus"
    }
    for _, f in ipairs(standardFonts) do
        if not seen[f] then
            table.insert(fonts, { key = f, label = f })
            seen[f] = true
        end
    end
    table.sort(fonts, function(a, b) return a.label:lower() < b.label:lower() end)
    return fonts
end

local function CreateStyledDropdown(parent, labelPrefix, width, height, optionsList, getFunc, setFunc, tooltipText, isFont)
    width = width or 190
    height = height or 22
    local btn = CreateStyledButton(parent, "", width, height, nil, tooltipText)

    local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arrow:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
    arrow:SetText("|cFFFFD100v|r")

    local function GetOptions()
        if type(optionsList) == "function" then
            return NormalizeDropdownItems(optionsList())
        end
        return NormalizeDropdownItems(optionsList)
    end

    local function UpdateLabel()
        local cur = getFunc and getFunc()
        local opts = GetOptions()
        local foundLabel = tostring(cur or "Default")
        for _, opt in ipairs(opts) do
            if opt.key == cur or opt.value == cur then
                foundLabel = opt.label or opt.text
                break
            end
        end
        if labelPrefix and labelPrefix ~= "" then
            btn.Text:SetText(string.format("%s: |cFFFFD100%s|r", labelPrefix, foundLabel))
        else
            btn.Text:SetText(string.format("|cFFFFD100%s|r", foundLabel))
        end
        if isFont then
            local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
            local fPath = LSM and LSM:Fetch("font", cur, true)
            if fPath then
                pcall(function() btn.Text:SetFont(fPath, 11, "") end)
            end
        end
    end

    btn:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
        local menu = GetOrCreateLocalDropdownMenu()
        if menu:IsShown() and menu.currentButton == self then
            menu:Hide()
            return
        end

        local curOpts = GetOptions()
        local curVal = getFunc and getFunc()
        menu.currentButton = self

        for _, b in ipairs(menu.buttons) do b:Hide() end

        local btnHeight = 22
        local maxVisible = 8
        local visibleCount = math.min(#curOpts, maxVisible)
        local menuWidth = math.max(width, 160)
        local totalContentHeight = #curOpts * btnHeight

        local hasScroll = (#curOpts > maxVisible)
        menu.scrollChild:SetSize(menuWidth - (hasScroll and 28 or 10), totalContentHeight)

        local scrollBar = _G["BFM_DropdownScrollFrameScrollBar"]
        if scrollBar then
            if hasScroll then
                scrollBar:Show()
                menu.scrollFrame:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -22, 4)
            else
                scrollBar:Hide()
                menu.scrollFrame:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -4, 4)
            end
        end

        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
        local selectedIndex = 1

        for i, itm in ipairs(curOpts) do
            local b = menu.buttons[i]
            if not b then
                b = CreateFrame("Button", nil, menu.scrollChild, BACKDROP_TEMPLATE)
                b:SetHeight(btnHeight)
                b:SetBackdrop(INSET_BACKDROP)

                b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                b.text:SetPoint("LEFT", b, "LEFT", 8, 0)
                b.text:SetPoint("RIGHT", b, "RIGHT", -8, 0)
                b.text:SetJustifyH("LEFT")

                b:SetScript("OnEnter", function(s)
                    s:SetBackdropColor(0.20, 0.22, 0.28, 0.95)
                    s:SetBackdropBorderColor(unpack(COLORS.goldBorder))
                end)
                b:SetScript("OnLeave", function(s)
                    if s.isActive then
                        s:SetBackdropColor(0.22, 0.19, 0.12, 0.95)
                        s:SetBackdropBorderColor(unpack(COLORS.goldBorder))
                    else
                        s:SetBackdropColor(0.10, 0.12, 0.15, 0.50)
                        s:SetBackdropBorderColor(unpack(COLORS.goldMuted))
                    end
                end)
                menu.buttons[i] = b
            end

            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", menu.scrollChild, "TOPLEFT", 2, -((i - 1) * btnHeight))
            b:SetPoint("RIGHT", menu.scrollChild, "RIGHT", -2, 0)

            local isActive = (itm.key == curVal or itm.value == curVal)
            b.isActive = isActive
            if isActive then
                selectedIndex = i
                b.text:SetText("|cFFFFD100* |r" .. itm.label)
                b:SetBackdropColor(0.22, 0.19, 0.12, 0.95)
                b:SetBackdropBorderColor(unpack(COLORS.goldBorder))
            else
                b.text:SetText("   " .. itm.label)
                b:SetBackdropColor(0.10, 0.12, 0.15, 0.50)
                b:SetBackdropBorderColor(unpack(COLORS.goldMuted))
            end

            if isFont and LSM then
                local fPath = LSM:Fetch("font", itm.key, true)
                if fPath then
                    pcall(function() b.text:SetFont(fPath, 11, "") end)
                end
            else
                b.text:SetFontObject("GameFontHighlightSmall")
            end

            local chosenKey = itm.key
            local chosenOpt = itm
            b:SetScript("OnClick", function()
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
                if setFunc then
                    setFunc(chosenKey, chosenOpt)
                end
                UpdateLabel()
                menu:Hide()
            end)
            b:Show()
        end

        local menuHeight = (visibleCount * btnHeight) + 8
        menu:SetSize(menuWidth, menuHeight)

        local screenHeight = UIParent:GetHeight() or 768
        local btnBottom = self:GetBottom() or (screenHeight / 2)
        menu:ClearAllPoints()
        if btnBottom < (menuHeight + 20) then
            menu:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 2)
        else
            menu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
        end

        menu:Show()
        menu:Raise()

        if hasScroll then
            local scrollPos = math.max(0, math.min(totalContentHeight - (visibleCount * btnHeight), (selectedIndex - 1) * btnHeight))
            menu.scrollFrame:SetVerticalScroll(scrollPos)
        else
            menu.scrollFrame:SetVerticalScroll(0)
        end
    end)

    btn.Sync = UpdateLabel
    UpdateLabel()
    return btn
end

local function CreateStyledFontDropdown(parent, labelPrefix, width, height, getFunc, setFunc, tooltipText)
    return CreateStyledDropdown(parent, labelPrefix, width, height, GetAvailableFonts, getFunc, setFunc, tooltipText, true)
end

-- Backward compatibility alias
local function CreateStyledCycleButton(parent, labelPrefix, width, height, optionsList, getFunc, setFunc, tooltipText)
    return CreateStyledDropdown(parent, labelPrefix, width, height, optionsList, getFunc, setFunc, tooltipText)
end

--[[-----------------------------------------------------------------------------
    Helper: Tab Button (Matching Quest Tracker / BAC sub-tab styling)
-------------------------------------------------------------------------------]]
local function CreateStyledTabButton(parent, id, text, width, height, onClick)
    local btn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    btn:SetSize(width or 130, height or 24)
    btn:SetBackdrop(INSET_BACKDROP)
    btn:SetBackdropColor(unpack(COLORS.tabNormal))
    btn:SetBackdropBorderColor(unpack(COLORS.goldMuted))

    local title = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    title:SetPoint("CENTER", btn, "CENTER", 0, 0)
    title:SetText(text)
    btn.title = title

    local indicator = btn:CreateTexture(nil, "OVERLAY")
    indicator:SetHeight(2)
    indicator:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 4, 1)
    indicator:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -4, 1)
    indicator:SetColorTexture(COLORS.goldBorder[1], COLORS.goldBorder[2], COLORS.goldBorder[3], 1.0)
    indicator:Hide()
    btn.indicator = indicator

    btn:SetScript("OnEnter", function(self)
        if not self.isActive then
            self:SetBackdropColor(unpack(COLORS.tabHighlight))
            self:SetBackdropBorderColor(unpack(COLORS.goldBorder))
        end
    end)

    btn:SetScript("OnLeave", function(self)
        if not self.isActive then
            self:SetBackdropColor(unpack(COLORS.tabNormal))
            self:SetBackdropBorderColor(unpack(COLORS.goldMuted))
        end
    end)

    btn:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
        if onClick then onClick(id) end
    end)

    btn.SetActive = function(self, active)
        self.isActive = active
        if active then
            self:SetBackdropColor(unpack(COLORS.tabActive))
            self:SetBackdropBorderColor(unpack(COLORS.goldBorder))
            self.title:SetTextColor(COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
            self.indicator:Show()
        else
            self:SetBackdropColor(unpack(COLORS.tabNormal))
            self:SetBackdropBorderColor(unpack(COLORS.goldMuted))
            self.title:SetTextColor(COLORS.whiteText[1], COLORS.whiteText[2], COLORS.whiteText[3])
            self.indicator:Hide()
        end
    end

    return btn
end

--[[-----------------------------------------------------------------------------
    TAB 1 BUILDER: General Settings
-------------------------------------------------------------------------------]]
function BFM:BuildGeneralTab(content, syncList, isEmbed)
    local pfx = isEmbed and "BFM_BAC_" or "BFM_Standalone_"
    local yOfs = -10

    -- Section 1: Addon Info & Master Config Status
    CreateSectionHeader(content, "INTEGRATION & STATUS", 12, yOfs)
    yOfs = yOfs - 32

    local titleLine = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    titleLine:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    titleLine:SetText("|cFFFFD100Nullgate's Maps|r  -  |cFF8899A6World of Warcraft Forever|r")
    yOfs = yOfs - 22

    local infoLine = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    infoLine:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    infoLine:SetText(string.format("|cFFFFD100Version:|r %s    |cFFFFD100Interface:|r 16001    |cFFFFD100Author:|r Nullgate", BFM.Version or "1.0.05"))
    yOfs = yOfs - 22

    local bacLoaded = _G["NullgatesAddonConfigForever"] ~= nil or _G["NullgatesAddonConfig"] ~= nil
    local statusLine = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusLine:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    statusLine:SetText(string.format("|cFFFFD100Master Config Hub:|r %s", bacLoaded and "|cFF00FF00Connected (/nac)|r" or "|cFF8899A6Standalone Mode|r"))
    yOfs = yOfs - 26

    local desc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    desc:SetWidth(450)
    desc:SetJustifyH("LEFT")
    desc:SetText("A modular square minimap and world map suite featuring custom borders, button scaling, throttled coordinates HUD, and full World Map Fog of War reveal.")
    desc:SetTextColor(COLORS.dimText[1], COLORS.dimText[2], COLORS.dimText[3])
    yOfs = yOfs - 45

    -- Section 2: Profile Management
    CreateSectionHeader(content, "PROFILE MANAGEMENT", 12, yOfs)
    yOfs = yOfs - 32

    local profileLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    profileLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    profileLabel:SetText(string.format("Active Profile: |cFFFFD100%s|r", BFM:GetActiveProfile()))
    if syncList then
        table.insert(syncList, {
            Sync = function()
                profileLabel:SetText(string.format("Active Profile: |cFFFFD100%s|r", BFM:GetActiveProfile()))
            end
        })
    end
    yOfs = yOfs - 24

    local cycleProfileBtn = CreateStyledButton(content, "Switch Profile", 130, 22, function()
        local list = BFM:GetProfiles()
        local cur = BFM:GetActiveProfile()
        local nextIndex = 1
        for i, name in ipairs(list) do
            if name == cur then
                nextIndex = (i % #list) + 1
                break
            end
        end
        local newProfile = list[nextIndex] or "Default"
        BFM:SetActiveProfile(newProfile)
        profileLabel:SetText(string.format("Active Profile: |cFFFFD100%s|r", newProfile))
        if content.SyncAll then content.SyncAll() end
        print(string.format("|cFFFFD100Nullgate's Maps|r: Switched to profile '|cFFFFD100%s|r'.", newProfile))
    end, "Cycles through available saved profiles.")
    cycleProfileBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)

    local resetProfileBtn = CreateStyledButton(content, "Reset Current Profile", 150, 22, function()
        local cur = BFM:GetActiveProfile()
        BFM:ResetProfile(cur)
        if content.SyncAll then content.SyncAll() end
        print(string.format("|cFFFFD100Nullgate's Maps|r: Profile '|cFFFFD100%s|r' reset to defaults.", cur))
    end, "Resets current profile settings back to defaults without affecting other profiles.")
    resetProfileBtn:SetPoint("LEFT", cycleProfileBtn, "RIGHT", 10, 0)
    yOfs = yOfs - 36

    -- Section 3: Slash Commands Reference
    CreateSectionHeader(content, "SLASH COMMANDS & SHORTCUTS", 12, yOfs)
    yOfs = yOfs - 32

    local commands = {
        { cmd = "/nmaps",              desc = "Toggle settings window" },
        { cmd = "/nmaps movers",       desc = "Toggle click-to-drag minimap movement overlay" },
        { cmd = "/nmaps profile <cmd>",desc = "Profile manager (list, set <name>, create, delete)" },
        { cmd = "/nmaps size <num>",   desc = "Adjust minimap pixel size (100 - 512)" },
        { cmd = "/nmaps resetpos",     desc = "Restore default top-right minimap anchor" },
        { cmd = "/nmaps reset",        desc = "Reset current active profile to defaults" },
        { cmd = "/nmaps fog",          desc = "Toggle World Map Fog of War reveal" },
        { cmd = "/nmaps quest",        desc = "Toggle square quest zone indicator" },
        { cmd = "/nmaps diel",         desc = "Toggle sun/moon day-night dial (DielFrame)" },
        { cmd = "/nmaps icons",        desc = "Toggle square minimap icon perimeter" },
        { cmd = "/nmaps coords",       desc = "Toggle minimap coordinate & subzone bar" },
        { cmd = "/nmaps status",       desc = "Print current active settings to chat" },
    }

    for _, entry in ipairs(commands) do
        local line = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        line:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOfs)
        line:SetText(string.format("|cFFFFD100%s|r  -  %s", entry.cmd, entry.desc))
        yOfs = yOfs - 20
    end

    yOfs = yOfs - 20

    -- Section 4: Defaults & Reset
    CreateSectionHeader(content, "FACTORY DEFAULTS", 12, yOfs)
    yOfs = yOfs - 32

    local resetAllBtn = CreateStyledButton(content, "Reset All Settings", 150, 24, function()
        wipe(NullgatesMapsDB)
        BFM:InitDB()
        BFM:ApplySettings()
        if content.SyncAll then content.SyncAll() end
        print("|cFFFFD100Nullgate's Maps|r: All settings restored to factory defaults.")
    end, "Resets all minimap and world map settings back to default values.")
    resetAllBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)

    yOfs = yOfs - 40
    content:SetHeight(math.abs(yOfs))
end

--[[-----------------------------------------------------------------------------
    TAB 2 BUILDER: Minimap Settings
-------------------------------------------------------------------------------]]
function BFM:BuildMinimapTab(content, syncList, isEmbed)
    local pfx = isEmbed and "BFM_BAC_" or "BFM_Standalone_"
    local yOfs = -10

    -- Section 1: Sizing & Geometry
    CreateSectionHeader(content, "SIZING & GEOMETRY", 12, yOfs)
    yOfs = yOfs - 34

    local sizeSlider = CreateStyledSlider(content, pfx .. "MinimapSize", "Minimap Size (Pixels):",
        "Adjusts the dimensions of the square minimap in pixels (100 - 512px). Automatically re-projects map tiles instantly.",
        100, 512, 5,
        function() return BFM.db.minimap.size or 140 end,
        function(val)
            BFM.db.minimap.size = val
            BFM:ApplySettings()
        end
    )
    sizeSlider:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    table.insert(syncList, sizeSlider)

    local borderSlider = CreateStyledSlider(content, pfx .. "BorderSize", "Border Thickness:",
        "Controls the pixel thickness of the square minimap border (1 - 5px, applied to Flat style).",
        1, 5, 1,
        function() return BFM.db.minimap.borderSize or 1 end,
        function(val)
            BFM.db.minimap.borderSize = val
            BFM:ApplySettings()
        end
    )
    borderSlider:SetPoint("TOPLEFT", content, "TOPLEFT", 240, yOfs)
    table.insert(syncList, borderSlider)

    yOfs = yOfs - 55

    -- Section 2: Appearance & Border
    CreateSectionHeader(content, "APPEARANCE & BORDER", 12, yOfs)
    yOfs = yOfs - 34

    local borderStyleBtn = CreateStyledDropdown(content, "Border", 200, 22, BORDER_STYLES,
        function() return BFM.db.minimap.borderStyle or "flat" end,
        function(val)
            BFM.db.minimap.borderStyle = val
            BFM:ApplySettings()
        end,
        "Select from available border styles:\n• Flat: Sleek pixel-perfect border\n• Blizzard Tooltip: Rounded tooltip corners\n• Blizzard Dialog: Classic window border\n• None: Clean borderless edge"
    )
    borderStyleBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    table.insert(syncList, borderStyleBtn)

    local cbClassColor = CreateStyledCheckbox(content, "Class-Colored Border",
        "Automatically tint the minimap border using your character's class color.",
        function() return BFM.db.minimap.classColorBorder == true end,
        function(checked)
            BFM.db.minimap.classColorBorder = checked
            BFM:ApplySettings()
        end
    )
    cbClassColor:SetPoint("TOPLEFT", content, "TOPLEFT", 240, yOfs + 2)
    table.insert(syncList, cbClassColor)

    yOfs = yOfs - 38

    local borderColorBtn = CreateStyledButton(content, "Border Color", 120, 22, function()
        local cur = BFM.db.minimap.borderColor or { r = 0, g = 0, b = 0, a = 1 }
        OpenColorPicker(cur, function(r, g, b, a)
            BFM.db.minimap.borderColor = { r = r, g = g, b = b, a = a }
            BFM:ApplySettings()
        end)
    end, "Choose a custom color and opacity for the minimap border (used when Class-Colored Border is disabled).")
    borderColorBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)

    local backdropColorBtn = CreateStyledButton(content, "Backdrop Color", 130, 22, function()
        local cur = BFM.db.minimap.backdropColor or { r = 0, g = 0, b = 0, a = 0.8 }
        OpenColorPicker(cur, function(r, g, b, a)
            BFM.db.minimap.backdropColor = { r = r, g = g, b = b, a = a }
            BFM:ApplySettings()
        end)
    end, "Choose a custom color and opacity for the minimap background canvas fill.")
    backdropColorBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 150, yOfs)

    yOfs = yOfs - 45

    -- Section 3: Button Scaling
    CreateSectionHeader(content, "BUTTON SCALING", 12, yOfs)
    yOfs = yOfs - 34

    local trackerScaleSlider = CreateStyledSlider(content, pfx .. "TrackerScale", "Tracking Button Scale:",
        "Adjusts the scale of the Minimap Tracking icon (50% - 150%).",
        50, 150, 5,
        function() return math.floor(((BFM.db.minimap.trackerScale or 0.85) * 100) + 0.5) end,
        function(val)
            BFM.db.minimap.trackerScale = val / 100
            BFM:ApplySettings()
        end,
        "%d%%"
    )
    trackerScaleSlider:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    table.insert(syncList, trackerScaleSlider)

    local calendarScaleSlider = CreateStyledSlider(content, pfx .. "CalendarScale", "Calendar Button Scale:",
        "Adjusts the scale of the Game Time / Calendar icon (50% - 150%).",
        50, 150, 5,
        function() return math.floor(((BFM.db.minimap.calendarScale or 0.80) * 100) + 0.5) end,
        function(val)
            BFM.db.minimap.calendarScale = val / 100
            BFM:ApplySettings()
        end,
        "%d%%"
    )
    calendarScaleSlider:SetPoint("TOPLEFT", content, "TOPLEFT", 240, yOfs)
    table.insert(syncList, calendarScaleSlider)

    yOfs = yOfs - 55

    local timeScaleSlider = CreateStyledSlider(content, pfx .. "TimeScale", "Clock Button Scale:",
        "Adjusts the scale of the docked Time Manager Clock (50% - 150%).",
        50, 150, 5,
        function() return math.floor(((BFM.db.minimap.timeScale or 0.85) * 100) + 0.5) end,
        function(val)
            BFM.db.minimap.timeScale = val / 100
            BFM:ApplySettings()
        end,
        "%d%%"
    )
    timeScaleSlider:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    table.insert(syncList, timeScaleSlider)

    yOfs = yOfs - 55

    -- Section 4: Movement & Positioning
    CreateSectionHeader(content, "MOVEMENT & POSITIONING", 12, yOfs)
    yOfs = yOfs - 34

    local cbUnlock = CreateStyledCheckbox(content, "Unlock Minimap (Click & Drag)",
        "Enables dragging the minimap freely across the screen. You can also hold Alt + Left Click to drag at any time.",
        function() return BFM.db.minimap.unlocked == true end,
        function(checked)
            BFM.db.minimap.unlocked = checked
            BFM:ApplySettings()
        end
    )
    cbUnlock:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    table.insert(syncList, cbUnlock)

    local resetBtn = CreateStyledButton(content, "Reset Position", 110, 22, function()
        NullgatesMapsForever:ResetPosition()
        print("|cFFFFD100Nullgate's Maps|r: Minimap position reset to default.")
    end, "Restores the minimap to its default top-right anchor position.")
    resetBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 280, yOfs - 1)

    yOfs = yOfs - 42

    -- Section 5: Features & Clutter
    CreateSectionHeader(content, "FEATURES & CLUTTER", 12, yOfs)
    yOfs = yOfs - 34

    local cbQuest = CreateStyledCheckbox(content, "Square Quest Zone Indicator",
        "Conforms active quest objective boundaries to the square minimap perimeter, replacing the default circular quest blob rings.",
        function() return BFM.db.minimap.questIndicator ~= false end,
        function(checked)
            BFM.db.minimap.questIndicator = checked
            BFM:ApplySettings()
        end
    )
    cbQuest:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    table.insert(syncList, cbQuest)

    yOfs = yOfs - 28

    local cbIcons = CreateStyledCheckbox(content, "Follow Square Minimap Perimeter",
        "Constrains addon minimap buttons along the square perimeter rather than orbiting in a circle.",
        function() return BFM.db.minimap.squareIcons ~= false end,
        function(checked)
            BFM.db.minimap.squareIcons = checked
            BFM:ApplySettings()
        end
    )
    cbIcons:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    table.insert(syncList, cbIcons)

    yOfs = yOfs - 28

    local cbDiel = CreateStyledCheckbox(content, "Hide Day/Night Cycle (DielFrame)",
        "Hides the sun and moon dial texture docked to the MinimapCluster.",
        function() return BFM.db.minimap.hideDielFrame ~= false end,
        function(checked)
            BFM.db.minimap.hideDielFrame = checked
            BFM:ApplySettings()
        end
    )
    cbDiel:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    table.insert(syncList, cbDiel)

    yOfs = yOfs - 28

    local cbZoom = CreateStyledCheckbox(content, "Enable Mouse Wheel Zoom",
        "Allows scrolling the mouse wheel up and down on the minimap to zoom in and out with clamped boundaries.",
        function() return BFM.db.minimap.enableMouseWheelZoom ~= false end,
        function(checked)
            BFM.db.minimap.enableMouseWheelZoom = checked
            BFM:ApplySettings()
        end
    )
    cbZoom:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    table.insert(syncList, cbZoom)

    yOfs = yOfs - 42

    -- Section 6: Minimap Coordinates & HUD
    CreateSectionHeader(content, "MINIMAP COORDINATES & HUD", 12, yOfs)
    yOfs = yOfs - 34

    local cbMinimapCoords = CreateStyledCheckbox(content, "Show Minimap Coordinates & Subzone Bar",
        "Displays live player coordinates (xx.x, yy.y) and reactive subzone text docked at the bottom of the minimap.",
        function() return BFM.db.minimap.showCoords ~= false end,
        function(checked)
            BFM.db.minimap.showCoords = checked
            BFM:ApplySettings()
        end
    )
    cbMinimapCoords:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    table.insert(syncList, cbMinimapCoords)

    local note1 = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note1:SetPoint("TOPLEFT", cbMinimapCoords, "BOTTOMLEFT", 26, -4)
    note1:SetText("Updates at throttled 0.1s rate. Automatically hidden if Quest Tracker Location Bar is active.")
    note1:SetTextColor(COLORS.dimText[1], COLORS.dimText[2], COLORS.dimText[3])

    yOfs = yOfs - 42

    local minimapFontDropdown = CreateStyledFontDropdown(content, "Font", 210, 22,
        function() return BFM.db.minimap.coordsFont or "Nata Sans Bold" end,
        function(val)
            BFM.db.minimap.coordsFont = val
            BFM:ApplySettings()
        end,
        "Select the typography face for minimap coordinates and subzone bar."
    )
    minimapFontDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    table.insert(syncList, minimapFontDropdown)

    local minimapOutlineDropdown = CreateStyledDropdown(content, "Outline", 150, 22, OUTLINE_OPTIONS,
        function() return BFM.db.minimap.coordsFontOutline or "OUTLINE" end,
        function(val)
            BFM.db.minimap.coordsFontOutline = val
            BFM:ApplySettings()
        end,
        "Select the font outline rendering style for minimap coordinates."
    )
    minimapOutlineDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", 240, yOfs)
    table.insert(syncList, minimapOutlineDropdown)

    yOfs = yOfs - 48

    local minimapFontSizeSlider = CreateStyledSlider(content, pfx .. "CoordsFontSize", "Coordinates Font Size:",
        "Controls the font size for minimap subzone and coordinates text (8 - 18 pt).",
        8, 18, 1,
        function() return BFM.db.minimap.coordsFontSize or 10 end,
        function(val)
            BFM.db.minimap.coordsFontSize = val
            BFM:ApplySettings()
        end,
        "%d pt"
    )
    minimapFontSizeSlider:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    table.insert(syncList, minimapFontSizeSlider)

    yOfs = yOfs - 55
    content:SetHeight(math.abs(yOfs))
end

--[[-----------------------------------------------------------------------------
    TAB 3 BUILDER: World Map Settings
-------------------------------------------------------------------------------]]
function BFM:BuildWorldMapTab(content, syncList, isEmbed)
    local pfx = isEmbed and "BFM_BAC_" or "BFM_Standalone_"
    local yOfs = -10

    -- Section 1: Coordinates Overlay
    CreateSectionHeader(content, "WORLD MAP CANVAS OVERLAYS", 12, yOfs)
    yOfs = yOfs - 34

    local cbWorldCoords = CreateStyledCheckbox(content, "Show World Map Coordinate Overlay",
        "Displays live player coordinates and cursor-hover coordinates docked at the bottom of the World Map canvas.",
        function() return BFM.db.worldmap.showCoords ~= false end,
        function(checked)
            BFM.db.worldmap.showCoords = checked
            BFM:ApplySettings()
        end
    )
    cbWorldCoords:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    table.insert(syncList, cbWorldCoords)

    local note2 = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note2:SetPoint("TOPLEFT", cbWorldCoords, "BOTTOMLEFT", 26, -4)
    note2:SetText("Uses modern MapCanvasDataProviderMixin architecture with normalized canvas projection.")
    note2:SetTextColor(COLORS.dimText[1], COLORS.dimText[2], COLORS.dimText[3])

    yOfs = yOfs - 42

    local worldFontDropdown = CreateStyledFontDropdown(content, "Font", 210, 22,
        function() return BFM.db.worldmap.coordsFont or "Nata Sans Bold" end,
        function(val)
            BFM.db.worldmap.coordsFont = val
            BFM:ApplySettings()
        end,
        "Select the typography face for world map coordinates overlay."
    )
    worldFontDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    table.insert(syncList, worldFontDropdown)

    local worldOutlineDropdown = CreateStyledDropdown(content, "Outline", 150, 22, OUTLINE_OPTIONS,
        function() return BFM.db.worldmap.coordsFontOutline or "OUTLINE" end,
        function(val)
            BFM.db.worldmap.coordsFontOutline = val
            BFM:ApplySettings()
        end,
        "Select the font outline rendering style for world map coordinates."
    )
    worldOutlineDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", 240, yOfs)
    table.insert(syncList, worldOutlineDropdown)

    yOfs = yOfs - 48

    local worldFontSizeSlider = CreateStyledSlider(content, pfx .. "WorldCoordsFontSize", "Coordinates Font Size:",
        "Controls the font size for world map player and cursor coordinate labels (8 - 20 pt).",
        8, 20, 1,
        function() return BFM.db.worldmap.coordsFontSize or 11 end,
        function(val)
            BFM.db.worldmap.coordsFontSize = val
            BFM:ApplySettings()
        end,
        "%d pt"
    )
    worldFontSizeSlider:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    table.insert(syncList, worldFontSizeSlider)

    yOfs = yOfs - 55

    -- Section 2: Fog of War / Map Reveal
    CreateSectionHeader(content, "FOG OF WAR / MAP REVEAL", 12, yOfs)
    yOfs = yOfs - 34

    local cbFog = CreateStyledCheckbox(content, "Reveal Unexplored Map Areas (Fog of War)",
        "Removes parchment fog from unvisited zones, rendering full terrain artwork with customizable tint and opacity.",
        function() return BFM.db.worldmap.fogClear ~= false end,
        function(checked)
            BFM.db.worldmap.fogClear = checked
            BFM:ApplySettings()
        end
    )
    cbFog:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    table.insert(syncList, cbFog)

    yOfs = yOfs - 38

    local fogAlphaSlider = CreateStyledSlider(content, pfx .. "FogAlpha", "Unexplored Overlay Opacity:",
        "Controls the transparency of revealed unexplored terrain overlays (10% - 100%).",
        10, 100, 5,
        function() return math.floor(((BFM.db.worldmap.fogAlpha or 0.60) * 100) + 0.5) end,
        function(val)
            BFM.db.worldmap.fogAlpha = val / 100
            BFM:ApplySettings()
        end,
        "%d%%"
    )
    fogAlphaSlider:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    table.insert(syncList, fogAlphaSlider)

    yOfs = yOfs - 55

    local fogColorBtn = CreateStyledButton(content, "Overlay Tint Color", 150, 22, function()
        local cur = BFM.db.worldmap.fogColor or { r = 0.90, g = 0.90, b = 1.00 }
        OpenColorPicker({ r = cur.r, g = cur.g, b = cur.b, a = BFM.db.worldmap.fogAlpha or 0.60 }, function(r, g, b, a)
            BFM.db.worldmap.fogColor = { r = r, g = g, b = b }
            BFM.db.worldmap.fogAlpha = a
            BFM:ApplySettings()
            if fogAlphaSlider and fogAlphaSlider.Sync then fogAlphaSlider:Sync() end
        end)
    end, "Choose a custom color tint and opacity for unvisited map overlays.")
    fogColorBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)

    local presetBtn = CreateStyledDropdown(content, "Preset", 190, 22, FOG_PRESETS,
        function()
            local curC = BFM.db.worldmap.fogColor or {}
            local curA = BFM.db.worldmap.fogAlpha or 0.60
            for _, p in ipairs(FOG_PRESETS) do
                if math.abs((curC.r or 1) - p.r) < 0.05
                   and math.abs((curC.g or 1) - p.g) < 0.05
                   and math.abs((curC.b or 1) - p.b) < 0.05
                   and math.abs(curA - p.a) < 0.05 then
                    return p.key
                end
            end
            return FOG_PRESETS[1].key
        end,
        function(key, opt)
            if opt then
                BFM.db.worldmap.fogColor = { r = opt.r, g = opt.g, b = opt.b }
                BFM.db.worldmap.fogAlpha = opt.a
                BFM:ApplySettings()
                if fogAlphaSlider and fogAlphaSlider.Sync then fogAlphaSlider:Sync() end
            end
        end,
        "Select from curated visual presets for unexplored territory."
    )
    presetBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 180, yOfs)
    table.insert(syncList, presetBtn)

    yOfs = yOfs - 38

    local note3 = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note3:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOfs)
    note3:SetWidth(450)
    note3:SetJustifyH("LEFT")
    note3:SetText("Discovered zones always render at full 100% natural color. Unexplored zones display using your chosen tint and opacity.")
    note3:SetTextColor(COLORS.dimText[1], COLORS.dimText[2], COLORS.dimText[3])

    yOfs = yOfs - 45
    content:SetHeight(math.abs(yOfs))
end

--[[-----------------------------------------------------------------------------
    Standalone Master Frame Initialization (With Horizontal Tabs matching Quest Tracker)
-------------------------------------------------------------------------------]]
function BFM:CreateStandaloneConfigFrame()
    if standaloneFrame then return standaloneFrame end

    local db = (BFM.db and BFM.db.configWindow) or {}
    local width = db.width or 680
    local height = db.height or 540
    local point = db.point or "CENTER"
    local relPoint = db.relativePoint or "CENTER"
    local xOfs = db.xOfs or 0
    local yOfs = db.yOfs or 0

    local f = CreateFrame("Frame", "NullgatesMapsConfigFrame", UIParent, BACKDROP_TEMPLATE)
    f:SetSize(width, height)
    f:SetPoint(point, UIParent, relPoint, xOfs, yOfs)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetResizable(true)

    tinsert(UISpecialFrames, "NullgatesMapsConfigFrame")

    if f.SetResizeBounds then
        f:SetResizeBounds(580, 420, 1100, 850)
    else
        f:SetMinResize(580, 420)
        f:SetMaxResize(1100, 850)
    end

    f:SetBackdrop(MAIN_WINDOW_BACKDROP)
    f:SetBackdropColor(unpack(COLORS.bgSlate))
    f:SetBackdropBorderColor(unpack(COLORS.goldBorder))

    -- Title Bar Area (Draggable)
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetHeight(32)
    titleBar:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -6)
    titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -32, -6)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")

    titleBar:SetScript("OnDragStart", function()
        f:StartMoving()
    end)

    titleBar:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local pt, _, relPt, x, y = f:GetPoint()
        if BFM.db then
            BFM.db.configWindow = BFM.db.configWindow or {}
            BFM.db.configWindow.point = pt
            BFM.db.configWindow.relativePoint = relPt or pt
            BFM.db.configWindow.xOfs = math.floor(x + 0.5)
            BFM.db.configWindow.yOfs = math.floor(y + 0.5)
        end
    end)

    -- Title Icon
    local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(18, 18)
    titleIcon:SetPoint("LEFT", titleBar, "LEFT", 6, 0)
    titleIcon:SetTexture("Interface\\Icons\\INV_Misc_Map02")
    titleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Title Text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleIcon, "RIGHT", 8, 0)
    titleText:SetText("|cFFFFD100Nullgate's Maps|r  |cFF8899A6Forever|r")

    -- Version Subtitle
    local versionText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    versionText:SetPoint("LEFT", titleText, "RIGHT", 8, -1)
    versionText:SetText("v" .. (BFM.Version or "1.0.05"))

    -- Refresh Button in Title Bar
    local refreshBtn = CreateStyledButton(titleBar, "Refresh", 70, 20, function()
        NullgatesMapsForever:ApplySettings()
        if f.SyncAll then f:SyncAll() end
        print("|cFFFFD100Nullgate's Maps|r: Settings refreshed.")
    end, "Reapplies all visual settings and refreshes map projections.")
    refreshBtn:SetPoint("RIGHT", titleBar, "RIGHT", -6, 0)

    -- Toggle Movers Button in Title Bar (Standardized standalone mover button)
    local btnMovers = CreateStyledButton(titleBar, "Toggle Movers", 100, 20, function()
        local newState = NullgatesMapsForever:ToggleMovers()
        print(string.format("|cFFFFD100Nullgate's Maps|r: Minimap Movers %s.", newState and "|cFF00FF00Unlocked|r" or "|cFFFF0000Locked|r"))
    end, "Toggles minimap anchor mover overlay for click-and-drag repositioning.")
    btnMovers:SetPoint("RIGHT", refreshBtn, "LEFT", -6, 0)
    f.btnMovers = btnMovers

    -- Gold Divider below Title Bar
    local titleDivider = f:CreateTexture(nil, "ARTWORK")
    titleDivider:SetHeight(1)
    titleDivider:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -36)
    titleDivider:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -36)
    titleDivider:SetColorTexture(COLORS.goldBorder[1], COLORS.goldBorder[2], COLORS.goldBorder[3], 0.6)

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(28, 28)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function()
        f:Hide()
    end)

    -- Bottom-right Resize Grip
    local resizeGrip = CreateFrame("Button", nil, f)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4)
    resizeGrip:EnableMouse(true)

    local gripTex = resizeGrip:CreateTexture(nil, "ARTWORK")
    gripTex:SetAllPoints(resizeGrip)
    gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

    resizeGrip:SetScript("OnEnter", function()
        gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    end)
    resizeGrip:SetScript("OnLeave", function()
        gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    end)
    resizeGrip:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            f:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeGrip:SetScript("OnMouseUp", function()
        f:StopMovingOrSizing()
        if BFM.db then
            BFM.db.configWindow = BFM.db.configWindow or {}
            BFM.db.configWindow.width = math.floor(f:GetWidth() + 0.5)
            BFM.db.configWindow.height = math.floor(f:GetHeight() + 0.5)
        end
    end)

    -- Footer hint text
    local footerText = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footerText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 8)
    footerText:SetText("|cFF667788Use /nmaps to toggle this window|r")

    -- Horizontal Tab Bar (Top row, matching Quest Tracker in BAC)
    local tabBar = CreateFrame("Frame", nil, f)
    tabBar:SetHeight(28)
    tabBar:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -42)
    tabBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -42)

    -- Inset Content Box below Tabs
    local insetBox = CreateFrame("Frame", nil, f, BACKDROP_TEMPLATE)
    insetBox:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -4)
    insetBox:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 26)
    insetBox:SetBackdrop(INSET_BACKDROP)
    insetBox:SetBackdropColor(unpack(COLORS.contentBg))
    insetBox:SetBackdropBorderColor(unpack(COLORS.goldMuted))

    local tabDefs = {
        { id = "general",  label = "General Settings",   width = 140, builder = BFM.BuildGeneralTab },
        { id = "minimap",  label = "Minimap Settings",   width = 140, builder = BFM.BuildMinimapTab },
        { id = "worldmap", label = "World Map Settings", width = 150, builder = BFM.BuildWorldMapTab },
    }

    local tabBtns = {}
    local tabScrolls = {}
    local syncLists = {}

    local function SelectTab(tabID)
        if BFM.db and BFM.db.configWindow then
            BFM.db.configWindow.lastTab = tabID
        end

        for id, btn in pairs(tabBtns) do
            btn:SetActive(id == tabID)
        end

        for id, scroll in pairs(tabScrolls) do
            if id == tabID then
                scroll:Show()
                if syncLists[id] then
                    for _, widget in ipairs(syncLists[id]) do
                        if widget.Sync then widget:Sync() end
                    end
                end
            else
                scroll:Hide()
            end
        end
    end

    local lastBtn = nil
    for _, def in ipairs(tabDefs) do
        local btn = CreateStyledTabButton(tabBar, def.id, def.label, def.width, 24, function(id)
            SelectTab(id)
        end)
        if lastBtn then
            btn:SetPoint("LEFT", lastBtn, "RIGHT", 6, 0)
        else
            btn:SetPoint("LEFT", tabBar, "LEFT", 0, 0)
        end
        lastBtn = btn
        tabBtns[def.id] = btn

        -- ScrollFrame for this tab inside insetBox
        local scroll = CreateFrame("ScrollFrame", "BFM_StandaloneScroll_" .. def.id, insetBox, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", insetBox, "TOPLEFT", 6, -6)
        scroll:SetPoint("BOTTOMRIGHT", insetBox, "BOTTOMRIGHT", -26, 6)

        local child = CreateFrame("Frame", nil, scroll)
        child:SetSize(width - 50, 600)
        scroll:SetScrollChild(child)
        SetupAutoScroll(scroll, child)

        local sList = {}
        syncLists[def.id] = sList
        child.SyncAll = function()
            for _, widget in ipairs(sList) do
                if widget.Sync then widget:Sync() end
            end
        end

        def.builder(BFM, child, sList, false)
        scroll:Hide()
        tabScrolls[def.id] = scroll
    end

    f.SyncAll = function()
        for _, sList in pairs(syncLists) do
            for _, widget in ipairs(sList) do
                if widget.Sync then widget:Sync() end
            end
        end
    end

    f:SetScript("OnShow", function()
        local last = (BFM.db and BFM.db.configWindow and BFM.db.configWindow.lastTab) or "general"
        SelectTab(last)
    end)

    f:SetScript("OnHide", function()
        if BFM.db and BFM.db.minimap and BFM.db.minimap.unlocked then
            BFM.db.minimap.unlocked = false
            BFM:ApplySettings()
        end
    end)

    standaloneFrame = f
    return f
end

function BFM:ToggleConfigUI()
    local f = self:CreateStandaloneConfigFrame()
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
    end
end

function BFM:ShowConfigUI()
    local f = self:CreateStandaloneConfigFrame()
    f:Show()
end

--[[-----------------------------------------------------------------------------
    Master Config (BAC) Embed UI Builder (With Horizontal Tabs matching Quest Tracker)
-------------------------------------------------------------------------------]]
function BFM:BuildEmbedUI(parent, isMasterHub)
    if not parent then return end
    isMasterHub = (isMasterHub ~= false)
    parent.isMasterHub = isMasterHub

    -- Top Horizontal Tab Bar
    local tabBar = CreateFrame("Frame", "BFM_BAC_TabBar", parent)
    tabBar:SetHeight(28)
    tabBar:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    tabBar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)

    -- Inset Content Box below Tabs
    local insetBox = CreateFrame("Frame", "BFM_BAC_InsetBox", parent, BACKDROP_TEMPLATE)
    insetBox:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -4)
    insetBox:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 4)
    insetBox:SetBackdrop(INSET_BACKDROP)
    insetBox:SetBackdropColor(unpack(COLORS.contentBg))
    insetBox:SetBackdropBorderColor(unpack(COLORS.goldMuted))

    local tabDefs = {
        { id = "general",  label = "General Settings",   width = 140, builder = BFM.BuildGeneralTab },
        { id = "minimap",  label = "Minimap Settings",   width = 140, builder = BFM.BuildMinimapTab },
        { id = "worldmap", label = "World Map Settings", width = 150, builder = BFM.BuildWorldMapTab },
    }

    local tabBtns = {}
    local tabScrolls = {}
    local syncLists = {}

    local function SelectEmbedTab(tabID)
        if BFM.db and BFM.db.configWindow then
            BFM.db.configWindow.lastTab = tabID
        end

        for id, btn in pairs(tabBtns) do
            btn:SetActive(id == tabID)
        end

        for id, scroll in pairs(tabScrolls) do
            if id == tabID then
                scroll:Show()
                if syncLists[id] then
                    for _, widget in ipairs(syncLists[id]) do
                        if widget.Sync then widget:Sync() end
                    end
                end
            else
                scroll:Hide()
            end
        end
    end

    local lastBtn = nil
    for _, def in ipairs(tabDefs) do
        local btn = CreateStyledTabButton(tabBar, def.id, def.label, def.width, 24, function(id)
            SelectEmbedTab(id)
        end)
        if lastBtn then
            btn:SetPoint("LEFT", lastBtn, "RIGHT", 6, 0)
        else
            btn:SetPoint("LEFT", tabBar, "LEFT", 0, 0)
        end
        lastBtn = btn
        tabBtns[def.id] = btn

        -- ScrollFrame for this tab
        local scroll = CreateFrame("ScrollFrame", "BFM_BACScroll_" .. def.id, insetBox, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", insetBox, "TOPLEFT", 6, -6)
        scroll:SetPoint("BOTTOMRIGHT", insetBox, "BOTTOMRIGHT", -26, 6)

        local child = CreateFrame("Frame", nil, scroll)
        child:SetSize(470, 600)
        scroll:SetScrollChild(child)
        SetupAutoScroll(scroll, child)

        local sList = {}
        syncLists[def.id] = sList
        child.SyncAll = function()
            for _, widget in ipairs(sList) do
                if widget.Sync then widget:Sync() end
            end
        end

        def.builder(BFM, child, sList, true)
        scroll:Hide()
        tabScrolls[def.id] = scroll
    end

    local function SyncAllTabs()
        for _, sList in pairs(syncLists) do
            for _, widget in ipairs(sList) do
                if widget.Sync then widget:Sync() end
            end
        end
    end

    parent:HookScript("OnShow", function()
        local last = (BFM.db and BFM.db.configWindow and BFM.db.configWindow.lastTab) or "general"
        SelectEmbedTab(last)
        SyncAllTabs()
    end)

    parent:HookScript("OnHide", function()
        if BFM.db and BFM.db.minimap and BFM.db.minimap.unlocked then
            BFM.db.minimap.unlocked = false
            BFM:ApplySettings()
        end
    end)

    parent.refresh = SyncAllTabs
    SelectEmbedTab((BFM.db and BFM.db.configWindow and BFM.db.configWindow.lastTab) or "general")

    return parent
end
