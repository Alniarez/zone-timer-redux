-- ZoneTimerRedux/Settings_Classic.lua
-- Settings panel for Classic clients using the canvas layout API.

local ZTR = ZoneTimerRedux

local configPanel = CreateFrame("Frame", nil, UIParent)
configPanel.name = "Zone Timer Redux"

if Settings and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterCanvasLayoutCategory(configPanel, "Zone Timer Redux")
    Settings.RegisterAddOnCategory(category)
end

local cfgTitle = configPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
cfgTitle:SetPoint("TOPLEFT", 16, -16)
cfgTitle:SetText("Zone Timer Redux Settings")

local sizeSlider = AlnUI:CreateSlider(configPanel, {
    width       = 260,
    min         = 100, max = 400, step = 10,
    value       = ZoneTimerSettings.width,
    labelFormat = "Window Size: %d",
    onChange    = function(value)
        ZoneTimerSettings.width = value
        ZoneTimerRedux.mainFrame:SetWidth(value)
    end,
})
sizeSlider:SetPoint("TOPLEFT", cfgTitle, "BOTTOMLEFT", 0, -40)

local opacitySlider = AlnUI:CreateSlider(configPanel, {
    width       = 260,
    min         = 0.1, max = 1.0, step = 0.1,
    value       = ZoneTimerSettings.opacity,
    labelFormat = "Window Opacity: %.1f",
    onChange    = function(value)
        ZoneTimerSettings.opacity = value
        ZoneTimerRedux.mainFrame:SetAlpha(value)
    end,
})
opacitySlider:SetPoint("TOPLEFT", sizeSlider, "BOTTOMLEFT", 0, -40)

local fontSlider = AlnUI:CreateSlider(configPanel, {
    width       = 260,
    min         = 8, max = 24, step = 1,
    value       = ZoneTimerSettings.fontSize,
    labelFormat = "Font Size: %d",
    onChange    = function(value)
        ZoneTimerSettings.fontSize = value
        if ZoneTimerRedux.SetFontSize then ZoneTimerRedux.SetFontSize(value) end
    end,
})
fontSlider:SetPoint("TOPLEFT", opacitySlider, "BOTTOMLEFT", 0, -40)

local alertsCheck = AlnUI:CreateCheckbox(configPanel, {
    label    = "Enable visual milestone alerts",
    checked  = ZoneTimerSettings.showAlerts ~= false,
    onChange = function(checked) ZoneTimerSettings.showAlerts = checked end,
})
alertsCheck:SetPoint("TOPLEFT", fontSlider, "BOTTOMLEFT", 0, -30)

local goldCheck = AlnUI:CreateCheckbox(configPanel, {
    label    = "Track Gold",
    checked  = ZoneTimerSettings.trackGold ~= false,
    onChange = function(checked)
        if ZoneTimerRedux.SetGoldTracking then ZoneTimerRedux.SetGoldTracking(checked) end
    end,
})
goldCheck:SetPoint("TOPLEFT", alertsCheck, "BOTTOMLEFT", 0, -20)

local themeCheck = AlnUI:CreateCheckbox(configPanel, {
    label    = "Use golden theme",
    checked  = ZoneTimerSettings.goldenTheme ~= false,
    onChange = function(checked)
        ZoneTimerSettings.goldenTheme = checked
        if ZoneTimerRedux.ApplyWindowTheme then ZoneTimerRedux.ApplyWindowTheme() end
    end,
})
themeCheck:SetPoint("TOPLEFT", goldCheck, "BOTTOMLEFT", 0, -20)

local resetCurrent = AlnUI:CreateButton(configPanel, {
    width   = 160,
    text    = "Reset Current Zone",
    onClick = function()
        if ZoneTimerRedux.ResetCurrentZone then ZoneTimerRedux.ResetCurrentZone() end
    end,
})
resetCurrent:SetPoint("TOPLEFT", themeCheck, "BOTTOMLEFT", 0, -30)

local resetAll = AlnUI:CreateButton(configPanel, {
    width   = 160,
    text    = "Reset All Zones",
    onClick = function()
        ZoneTimerSettings.times = {}
        ZoneTimerSettings.announcedMilestones = {}
    end,
})
resetAll:SetPoint("TOPLEFT", resetCurrent, "BOTTOMLEFT", 0, -10)

local tallyHeader = configPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
tallyHeader:SetPoint("TOPLEFT", resetAll, "BOTTOMLEFT", 0, -30)
tallyHeader:SetText("Tally")
tallyHeader:SetTextColor(1, 0.82, 0)

local tallySortCheck = AlnUI:CreateCheckbox(configPanel, {
    label    = "Sort by Gold by default",
    checked  = ZoneTimerSettings.tallySort == "gold",
    onChange = function(checked)
        ZoneTimerSettings.tallySort = checked and "gold" or "time"
        ZTR.sortMode = ZoneTimerSettings.tallySort
        if ZoneTimerRedux.SyncTallySort then ZoneTimerRedux.SyncTallySort() end
    end,
})
tallySortCheck:SetPoint("TOPLEFT", tallyHeader, "BOTTOMLEFT", 0, -10)
