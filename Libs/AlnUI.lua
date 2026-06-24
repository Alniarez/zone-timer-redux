-- Libs/AlnUI.lua
-- Reusable UI helpers. Can be embedded in any addon.
-- Namespace: AlnUI

AlnUI = AlnUI or {}

local THEMES = {
    gold = {
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        header   = "Interface\\DialogFrame\\UI-DialogBox-Gold-Header",
    },
    standard = {
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        header   = "Interface\\DialogFrame\\UI-DialogBox-Header",
    },
}

--------------------------------------------------
-- AlnUI:CreateDialog(opts) -> frame
--
-- opts (all optional):
--   name          string  global frame name
--   title         string  title text shown in the header banner
--   titleWidth    number  width of the header banner (default 256)
--   width         number  (default 400)
--   height        number  (default 300)
--   parent        frame   (default UIParent)
--   strata        string  frame strata
--   level         number  frame level
--   theme         string  "gold" (default) or "standard"
--   noCloseButton bool    omit the close button (default false)
--
-- Returns a hidden, movable frame anchored to CENTER with:
--   frame.titleText    FontString (nil if no title given)
--   frame.titleBanner  Texture    (nil if no title given)
--   frame.closeButton  Button     (nil if noCloseButton)
--------------------------------------------------

function AlnUI:CreateDialog(opts)
    opts = opts or {}

    local theme = THEMES[opts.theme] or THEMES.standard

    local frame = CreateFrame(
        "Frame",
        opts.name or nil,
        opts.parent or UIParent,
        "BackdropTemplate"
    )

    frame:SetSize(opts.width or 400, opts.height or 300)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = theme.edgeFile,
        edgeSize = 32,
        insets   = { left = 8, right = 8, top = 8, bottom = 8 },
    })

    if opts.strata then frame:SetFrameStrata(opts.strata) end
    if opts.level  then frame:SetFrameLevel(opts.level) end

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop",  frame.StopMovingOrSizing)
    frame:Hide()

    if opts.title then
        local banner = frame:CreateTexture(nil, "OVERLAY")
        banner:SetTexture(theme.header)
        banner:SetSize(opts.titleWidth or 256, 64)
        banner:SetPoint("TOP", frame, "TOP", 0, 12)
        frame.titleBanner = banner

        local t = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        t:SetPoint("TOP", frame, "TOP", 0, 0)
        t:SetText(opts.title)
        frame.titleText = t

        local dragHandle = CreateFrame("Frame", nil, frame)
        dragHandle:SetSize(opts.titleWidth or 256, 12)
        dragHandle:SetPoint("TOP", frame, "TOP", 0, 12)
        dragHandle:EnableMouse(true)
        dragHandle:RegisterForDrag("LeftButton")
        dragHandle:SetScript("OnDragStart", function() frame:StartMoving() end)
        dragHandle:SetScript("OnDragStop",  function() frame:StopMovingOrSizing() end)
    end

    if not opts.noCloseButton then
        local cb = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        cb:SetPoint("TOPRIGHT", -10, -10)
        frame.closeButton = cb
    end

    return frame
end

--------------------------------------------------
-- AlnUI:CreateColumnRow(parent, opts, cols) -> fontstrings[]
--
-- Creates a horizontal row of FontStrings on `parent`.
--
-- opts (all optional):
--   anchorTo  frame   frame to anchor the first column to (default parent)
--   x         number  x offset for the first column (default 0)
--   y         number  y offset for the first column (default 0)
--   font      string  font template for all columns (default "GameFontHighlight")
--
-- cols[i]:
--   width    number  column width
--   justify  string  "LEFT" or "RIGHT" (default "LEFT")
--   gap      number  gap before this column from the previous (default 0)
--   text     string  initial text (optional)
--   wordWrap bool    set to false to disable word wrap (default true)
--
-- Returns an array of FontStrings in column order.
--------------------------------------------------

function AlnUI:CreateColumnRow(parent, opts, cols)
    opts = opts or {}

    local font     = opts.font or "GameFontHighlight"
    local anchorTo = opts.anchorTo or parent
    local x        = opts.x or 0
    local y        = opts.y or 0
    local result   = {}
    local prev     = nil

    for i, col in ipairs(cols) do
        local fs = parent:CreateFontString(nil, "OVERLAY", font)
        fs:SetWidth(col.width)
        fs:SetJustifyH(col.justify or "LEFT")
        if col.wordWrap == false then fs:SetWordWrap(false) end
        if col.text then fs:SetText(col.text) end

        if i == 1 then
            fs:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", x, y)
        else
            fs:SetPoint("LEFT", prev, "RIGHT", col.gap or 0, 0)
        end

        prev      = fs
        result[i] = fs
    end

    return result
end

--------------------------------------------------
-- AlnUI:CreateScrollFrame(parent, opts) -> scroll, content
--
-- Creates a UIPanelScrollFrameTemplate scroll frame with a content
-- child frame inside it.
--
-- opts (all optional):
--   x1, y1        number  TOPLEFT offset from parent (default 0, 0)
--   x2, y2        number  BOTTOMRIGHT offset from parent (default 0, 0)
--   contentWidth  number  initial content width  (default 0)
--   contentHeight number  initial content height (default 0)
--   childType     string  type for the child frame (default "Frame")
--
-- Returns: scroll, content
--------------------------------------------------

function AlnUI:CreateScrollFrame(parent, opts)
    opts = opts or {}

    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     opts.x1 or 0,  opts.y1 or 0)
    scroll:SetPoint("BOTTOMRIGHT", opts.x2 or 0,  opts.y2 or 0)

    local content = CreateFrame(opts.childType or "Frame", nil, scroll)
    content:SetSize(opts.contentWidth or 0, opts.contentHeight or 0)
    scroll:SetScrollChild(content)

    return scroll, content
end

--------------------------------------------------
-- AlnUI:CreateSlider(parent, opts) -> slider
--
-- Wraps OptionsSliderTemplate with a label below it.
--
-- opts (all optional):
--   name        string  global frame name
--   width       number  slider width (default 200)
--   min         number  minimum value (default 0)
--   max         number  maximum value (default 100)
--   step        number  value step (default 1)
--   value       number  initial value; also fires onChange once on init
--   labelFormat string  format string passed to string.format(fmt, value)
--                       to auto-update the label on value change
--   onChange    func    called as onChange(value) on every value change
--
-- Returns the slider frame with:
--   slider.label  FontString below the slider
--------------------------------------------------

function AlnUI:CreateSlider(parent, opts)
    opts = opts or {}

    local slider = CreateFrame("Slider", opts.name or nil, parent, "OptionsSliderTemplate")
    slider:SetWidth(opts.width or 200)
    slider:SetMinMaxValues(opts.min or 0, opts.max or 100)
    slider:SetValueStep(opts.step or 1)
    slider:SetObeyStepOnDrag(true)

    slider.label = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    slider.label:SetPoint("TOP", slider, "BOTTOM", 0, -4)

    local fmt = opts.labelFormat
    slider:SetScript("OnValueChanged", function(_, value)
        if fmt then
            slider.label:SetText(string.format(fmt, value))
        end
        if opts.onChange then opts.onChange(value) end
    end)

    if opts.value ~= nil then
        slider:SetValue(opts.value)
    end

    return slider
end

--------------------------------------------------
-- AlnUI:CreateCheckbox(parent, opts) -> checkbutton
--
-- Wraps UICheckButtonTemplate with a label to its right.
--
-- opts (all optional):
--   name      string  global frame name
--   label     string  label text
--   checked   bool    initial checked state
--   onChange  func    called as onChange(checked) on click
--
-- Returns the CheckButton with:
--   checkbox.label  FontString to the right of the button
--------------------------------------------------

function AlnUI:CreateCheckbox(parent, opts)
    opts = opts or {}

    local cb = CreateFrame("CheckButton", opts.name or nil, parent, "UICheckButtonTemplate")

    cb.label = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    cb.label:SetPoint("LEFT", cb, "RIGHT", 4, 1)
    cb.label:SetText(opts.label or "")

    if opts.checked ~= nil then
        cb:SetChecked(opts.checked)
    end

    cb:SetScript("OnClick", function(self)
        if opts.onChange then opts.onChange(self:GetChecked()) end
    end)

    return cb
end

--------------------------------------------------
-- AlnUI:CreateButton(parent, opts) -> button
--
-- Wraps UIPanelButtonTemplate.
--
-- opts (all optional):
--   name    string  global frame name
--   width   number  (default 120)
--   height  number  (default 24)
--   text    string  button label
--   onClick func    OnClick handler
--
-- Returns the Button.
--------------------------------------------------

function AlnUI:CreateButton(parent, opts)
    opts = opts or {}

    local btn = CreateFrame("Button", opts.name or nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(opts.width or 120, opts.height or 24)
    btn:SetText(opts.text or "")

    if opts.onClick then
        btn:SetScript("OnClick", opts.onClick)
    end

    return btn
end

--------------------------------------------------
-- AlnUI:ShowToast(opts)
--
-- Creates and shows a temporary centered-top notification that fades
-- in, holds, then fades out and hides itself.
--
-- opts (all optional):
--   width    number  (default 400)
--   height   number  (default 100)
--   icon     string  texture path; shown on the left at 64x64
--   title    string  large text centered slightly above middle
--   text     string  body text centered at middle
--   sound    number  sound ID played on fade-in
--   fadeIn   number  fade-in duration in seconds (default 0.3)
--   duration number  seconds before fade-out begins (default 5)
--   fadeOut  number  fade-out duration in seconds (default 1)
--
-- Returns the frame (hidden after animation completes).
--------------------------------------------------

function AlnUI:ShowToast(opts)
    opts = opts or {}

    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetSize(opts.width or 400, opts.height or 100)
    f:SetPoint("TOP", UIParent, "TOP", 0, -200)
    f:SetFrameStrata("HIGH")
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 32,
        insets   = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    f:SetAlpha(0)
    f:Show()

    -- When an icon is present (left=10, size=64), shift text to center in the
    -- space to its right so the text never overlaps the icon.
    local textXOffset = 0
    if opts.icon then
        local icon = f:CreateTexture(nil, "ARTWORK")
        icon:SetSize(64, 64)
        icon:SetPoint("LEFT", 16, 0)
        icon:SetTexture(opts.icon)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        textXOffset = 40  -- (iconX=16 + iconSize=64) / 2
    end

    if opts.title then
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("CENTER", f, "CENTER", textXOffset, 12)
        title:SetJustifyH("CENTER")
        title:SetText(opts.title)
    end

    if opts.text then
        local msg = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        msg:SetPoint("CENTER", f, "CENTER", textXOffset, -10)
        msg:SetJustifyH("CENTER")
        msg:SetText(opts.text)
    end

    local duration = opts.duration or 5

    -- Fade in directly — no deferred C_Timer needed for the initial animation.
    local fadeInGroup = f:CreateAnimationGroup()
    local fi = fadeInGroup:CreateAnimation("Alpha")
    fi:SetFromAlpha(0)
    fi:SetToAlpha(1)
    fi:SetDuration(opts.fadeIn or 0.3)
    fadeInGroup:SetToFinalAlpha(true)
    if opts.sound then PlaySound(opts.sound, "Master") end
    fadeInGroup:Play()

    C_Timer.After(duration, function()
        local fadeOutGroup = f:CreateAnimationGroup()
        local fo = fadeOutGroup:CreateAnimation("Alpha")
        fo:SetFromAlpha(1)
        fo:SetToAlpha(0)
        fo:SetDuration(opts.fadeOut or 1)
        fadeOutGroup:SetToFinalAlpha(true)
        fadeOutGroup:SetScript("OnFinished", function() f:Hide() end)
        fadeOutGroup:Play()
    end)

    return f
end
