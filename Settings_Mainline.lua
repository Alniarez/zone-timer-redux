-- ZoneTimerRedux/Settings_Mainline.lua
-- Settings panel using the native Settings API.
-- Guard: exits cleanly on any client that does not yet have RegisterVerticalLayoutCategory.

if not (Settings and Settings.RegisterVerticalLayoutCategory) then return end

local ZTR = ZoneTimerRedux

local category = Settings.RegisterVerticalLayoutCategory("Zone Timer Redux")

local function InitializeSettings()

    -- ── Appearance ────────────────────────────────────────────────────────────

    local goldenThemeSetting = Settings.RegisterAddOnSetting(
        category,
        "ZTR_GOLDEN_THEME",
        "goldenTheme",
        ZoneTimerSettings,
        Settings.VarType.Boolean,
        "Golden theme",
        true
    )
    Settings.CreateCheckbox(
        category,
        goldenThemeSetting,
        "Use a gold border and header on the timer and tally windows."
    )
    Settings.SetOnValueChangedCallback("ZTR_GOLDEN_THEME", function()
        ZoneTimerSettings.goldenTheme = Settings.GetValue("ZTR_GOLDEN_THEME")
        if ZoneTimerRedux.ApplyWindowTheme then ZoneTimerRedux.ApplyWindowTheme() end
    end)

    -- ── Window ────────────────────────────────────────────────────────────────

    local widthSetting = Settings.RegisterAddOnSetting(
        category,
        "ZTR_WIDTH",
        "width",
        ZoneTimerSettings,
        Settings.VarType.Number,
        "Window width",
        220
    )
    local widthOptions = Settings.CreateSliderOptions(100, 400, 10)
    widthOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        return tostring(value)
    end)
    Settings.CreateSlider(category, widthSetting, widthOptions, "Width of the main timer window in pixels.")
    Settings.SetOnValueChangedCallback("ZTR_WIDTH", function()
        local value = Settings.GetValue("ZTR_WIDTH")
        ZoneTimerSettings.width = value
        ZoneTimerRedux.mainFrame:SetWidth(value)
    end)

    local opacitySetting = Settings.RegisterAddOnSetting(
        category,
        "ZTR_OPACITY",
        "opacity",
        ZoneTimerSettings,
        Settings.VarType.Number,
        "Window opacity",
        1.0
    )
    local opacityOptions = Settings.CreateSliderOptions(0.1, 1.0, 0.1)
    opacityOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        return string.format("%.1f", value)
    end)
    Settings.CreateSlider(category, opacitySetting, opacityOptions, "Opacity of the main timer window.")
    Settings.SetOnValueChangedCallback("ZTR_OPACITY", function()
        local value = Settings.GetValue("ZTR_OPACITY")
        ZoneTimerSettings.opacity = value
        ZoneTimerRedux.mainFrame:SetAlpha(value)
    end)

    local fontSizeSetting = Settings.RegisterAddOnSetting(
        category,
        "ZTR_FONT_SIZE",
        "fontSize",
        ZoneTimerSettings,
        Settings.VarType.Number,
        "Font size",
        12
    )
    local fontOptions = Settings.CreateSliderOptions(8, 24, 1)
    fontOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        return tostring(value)
    end)
    Settings.CreateSlider(category, fontSizeSetting, fontOptions, "Font size for the main timer window.")
    Settings.SetOnValueChangedCallback("ZTR_FONT_SIZE", function()
        local value = Settings.GetValue("ZTR_FONT_SIZE")
        ZoneTimerSettings.fontSize = value
        if ZoneTimerRedux.SetFontSize then ZoneTimerRedux.SetFontSize(value) end
    end)

    -- ── Tracking ──────────────────────────────────────────────────────────────

    local alertsSetting = Settings.RegisterAddOnSetting(
        category,
        "ZTR_SHOW_ALERTS",
        "showAlerts",
        ZoneTimerSettings,
        Settings.VarType.Boolean,
        "Visual milestone alerts",
        true
    )
    Settings.CreateCheckbox(
        category,
        alertsSetting,
        "Show a toast notification when you reach a time milestone in a zone."
    )
    Settings.SetOnValueChangedCallback("ZTR_SHOW_ALERTS", function()
        ZoneTimerSettings.showAlerts = Settings.GetValue("ZTR_SHOW_ALERTS")
    end)

    local goldSetting = Settings.RegisterAddOnSetting(
        category,
        "ZTR_TRACK_GOLD",
        "trackGold",
        ZoneTimerSettings,
        Settings.VarType.Boolean,
        "Track gold",
        true
    )
    Settings.CreateCheckbox(
        category,
        goldSetting,
        "Track gold earned per zone and display it on the timer."
    )
    Settings.SetOnValueChangedCallback("ZTR_TRACK_GOLD", function()
        if ZoneTimerRedux.SetGoldTracking then
            ZoneTimerRedux.SetGoldTracking(Settings.GetValue("ZTR_TRACK_GOLD"))
        end
    end)

    -- ── Tally ─────────────────────────────────────────────────────────────────

    local addonLayout = SettingsPanel:GetLayout(category)
    addonLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Tally"))

    -- Bridge: tallySort is stored as "gold"/"time" but the checkbox needs a boolean.
    local tallySortProxy = { sortByGold = (ZoneTimerSettings.tallySort == "gold") }
    local tallySortSetting = Settings.RegisterAddOnSetting(
        category,
        "ZTR_TALLY_GOLD_SORT",
        "sortByGold",
        tallySortProxy,
        Settings.VarType.Boolean,
        "Sort by gold by default",
        false
    )
    Settings.CreateCheckbox(
        category,
        tallySortSetting,
        "Sort the tally window by gold earned instead of time spent."
    )
    Settings.SetOnValueChangedCallback("ZTR_TALLY_GOLD_SORT", function()
        local checked = Settings.GetValue("ZTR_TALLY_GOLD_SORT")
        ZoneTimerSettings.tallySort = checked and "gold" or "time"
        ZTR.sortMode = ZoneTimerSettings.tallySort
        if ZoneTimerRedux.SyncTallySort then ZoneTimerRedux.SyncTallySort() end
    end)

    -- ── Data ──────────────────────────────────────────────────────────────────

    addonLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Data"))

    addonLayout:AddInitializer(CreateSettingsButtonInitializer(
        "Reset current zone",
        "Reset",
        function()
            if ZoneTimerRedux.ResetCurrentZone then ZoneTimerRedux.ResetCurrentZone() end
        end,
        "Clears the recorded time for the zone you are currently in.",
        true
    ))

    addonLayout:AddInitializer(CreateSettingsButtonInitializer(
        "Reset all zones",
        "Reset All",
        function()
            ZoneTimerSettings.times = {}
            ZoneTimerSettings.announcedMilestones = {}
        end,
        "Clears all recorded zone times and milestone data.",
        true
    ))

    Settings.RegisterAddOnCategory(category)
end

InitializeSettings()
