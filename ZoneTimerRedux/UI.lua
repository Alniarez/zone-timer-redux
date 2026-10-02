-- ZoneTimerRedux/UI.lua

local ZTR = ZoneTimerRedux

-- ── Milestone alert ───────────────────────────────────────────────────────────

-- The theme picked in the settings, for every window and toast
local function windowTheme()
    return ZoneTimerSettings.theme or "gold"
end
local toastTheme = windowTheme

function ZoneTimerRedux_ShowMilestoneAlert(zone, minutes)
    local hrs    = math.floor(minutes / 60)
    local remMin = minutes % 60
    local timeText = string.format("%dh", hrs)
    if remMin > 0 then timeText = timeText .. string.format(" %dm", remMin) end

    AlnUI:ShowToast({
        icon  = "Interface\\Icons\\inv_misc_pocketwatch_01",
        title = "Milestone Reached!",
        text  = string.format("You spent %s in %s!", timeText, zone),
        sound = 12891,
        theme = toastTheme(),
    })
end

function ZoneTimerRedux_ShowGoldMilestoneAlert(zone, gold)
    AlnUI:ShowToast({
        icon  = "Interface\\Icons\\inv_misc_coin_01",
        title = "Gold Milestone!",
        text  = string.format("%dg earned in %s!", gold, zone),
        sound = 12891,
        theme = toastTheme(),
    })
end

function ZoneTimerRedux_ShowDiscoveredAlert(zone)
    AlnUI:ShowToast({
        icon  = "Interface\\Icons\\inv_misc_map_01",
        title = "Zone Discovered!",
        text  = string.format("New zone discovered: %s", zone),
        sound = 12889,
        theme = toastTheme(),
    })
end

-- ── Main timer frame ──────────────────────────────────────────────────────────

local function CalcFrameHeight()
    local fs = ZoneTimerSettings.fontSize
    -- WoW font line height is roughly fs*1.2, so zone text (fs+4 font) renders ~fs+8 px tall.
    -- top(14) + zone(fs+8) + gap(6) + sep(1) + gap(6) + timer(fs+3) + gap(5) + gold(fs+3) + bottom(12)
    local h = 58 + 3 * fs
    if ZoneTimerSettings.trackGold == false then h = h - (fs + 8) end
    return h
end

local mainFrame = AlnUI:CreateDialog({
    name          = "ZoneTimerReduxFrame",
    theme         = windowTheme(),
    width         = ZoneTimerSettings.width,
    height        = CalcFrameHeight(),
    noCloseButton = true,
})
mainFrame:ClearAllPoints()
mainFrame:SetPoint("CENTER", 0, -40)
mainFrame:SetAlpha(ZoneTimerSettings.opacity)
if ZoneTimerSettings.windowVisible ~= false then mainFrame:Show() end

local zoneText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
zoneText:SetTextColor(1, 0.85, 0)
zoneText:SetText("---")
zoneText:SetWordWrap(false)

local separator = AlnUI:CreateSeparator(mainFrame, { x1 = 16, x2 = -16, color = { 0.55, 0.45, 0.05, 0.6 } })

local timerLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
timerLabel:SetTextColor(0.5, 0.5, 0.5)
timerLabel:SetText("Time")
timerLabel:SetJustifyH("LEFT")
timerLabel:SetWordWrap(false)

local timerText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
timerText:SetJustifyH("RIGHT")
timerText:SetWordWrap(false)
timerText:SetText("---")

local goldLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
goldLabel:SetTextColor(1, 0.82, 0)
goldLabel:SetText("Gold")
goldLabel:SetJustifyH("LEFT")
goldLabel:SetWordWrap(false)

local goldText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
goldText:SetJustifyH("RIGHT")
goldText:SetWordWrap(false)
goldText:SetText("---")

local function LayoutMainFrame()
    local fs         = ZoneTimerSettings.fontSize
    local trackGold  = ZoneTimerSettings.trackGold ~= false
    local showLabels = ZoneTimerSettings.showLabels ~= false
    local w          = ZoneTimerSettings.width

    zoneText:SetFont("Fonts\\FRIZQT__.TTF", fs + 4)
    timerLabel:SetFont("Fonts\\FRIZQT__.TTF", fs - 1)
    timerText:SetFont("Fonts\\FRIZQT__.TTF", fs)
    goldLabel:SetFont("Fonts\\FRIZQT__.TTF", fs - 1)
    goldText:SetFont("Fonts\\FRIZQT__.TTF", fs)

    -- Y offsets from frame TOP (negative = downward).
    -- WoW font line height ≈ font_size * 1.2, so zone text (fs+4 font) takes ~fs+8 px.
    local zoneH  = fs + 8
    local yZone  = -14
    local ySep   = -(14 + zoneH + 6)
    local yTimer = ySep - 1 - 6
    local yGold  = yTimer - (fs + 8)

    zoneText:ClearAllPoints()
    zoneText:SetPoint("TOP", mainFrame, "TOP", 0, yZone)
    zoneText:SetWidth(w - 24)

    separator:ClearAllPoints()
    separator:SetPoint("TOPLEFT",  mainFrame, "TOPLEFT",  16, ySep)
    separator:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -16, ySep)

    timerLabel:ClearAllPoints()
    timerText:ClearAllPoints()
    timerText:SetWidth(0)
    if showLabels then
        timerLabel:Show()
        timerText:SetJustifyH("RIGHT")
        timerLabel:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 16, yTimer)
        timerText:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -16, yTimer)
    else
        timerLabel:Hide()
        timerText:SetJustifyH("CENTER")
        timerText:SetPoint("TOP", mainFrame, "TOP", 0, yTimer)
    end

    goldLabel:ClearAllPoints()
    goldText:ClearAllPoints()
    goldText:SetWidth(0)
    if trackGold then
        goldText:Show()
        if showLabels then
            goldLabel:Show()
            goldLabel:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 16, yGold)
            goldText:SetJustifyH("RIGHT")
            goldText:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -16, yGold)
        else
            goldLabel:Hide()
            goldText:SetJustifyH("CENTER")
            goldText:SetPoint("TOP", mainFrame, "TOP", 0, yGold)
        end
    else
        goldLabel:Hide()
        goldText:Hide()
    end

    mainFrame:SetWidth(w)
    mainFrame:SetHeight(CalcFrameHeight())
end

LayoutMainFrame()

mainFrame:SetScript("OnUpdate", function()
    if not ZTR.currentZone then return end

    local total = ZTR:GetCurrentTime()
    timerText:SetText(ZTR:ColorTime(ZTR:FormatTime(total)))

    if ZoneTimerSettings.trackGold ~= false then
        local copper = ZTR:GetZoneGold(ZTR.currentZone)
        goldText:SetText(ZTR:ColorGold(ZTR:FormatGold(copper)))
        ZTR:CheckGoldMilestones(ZTR.currentZone, copper)
    end

    ZTR:CheckMilestones(ZTR.currentZone, total)
end)

-- ── Tally window ──────────────────────────────────────────────────────────────

local tallyTimeText
local tallyGoldText
local UpdateTally

local tallyFrame = AlnUI:CreateDialog({
    name       = "ZoneTimerReduxTallyFrame",
    title      = "Zone Timer Tally",
    titleWidth = 360,
    width      = 520,
    height     = 520,
    theme      = windowTheme(),
    -- wide enough for the title banner and the totals
    resizable  = true,
    minWidth   = 420,
    minHeight  = 250,
    onResize   = function(w, h)
        ZoneTimerSettings.tallyWidth  = w
        ZoneTimerSettings.tallyHeight = h
    end,
})

-- Click a column to sort: ascending, descending, then back to the default
-- order (most time first). Zone fills the width left over, so the columns
-- follow the window size.
-- right = 40: the list's 36 inset for the scroll bar + the rows' 4
local tallyHeader = AlnUI:CreateSortHeader(tallyFrame, {
    x = 24, y = -60, right = 40,
    onSort = function(key, ascending)
        ZTR.sortMode, ZTR.sortAscending = key, ascending == true
        ZoneTimerSettings.tallySort          = key or "none"
        ZoneTimerSettings.tallySortAscending = ascending == true
        UpdateTally()
    end,
}, {
    { text = "Zone", key = "zone", fill  = true, justify = "LEFT" },
    { text = "Time", key = "time", width = 116,  justify = "RIGHT" },
    { text = "Gold", key = "gold", width = 128,  justify = "RIGHT", gap = 6 },
})

AlnUI:CreateSeparator(tallyFrame, { y = -76, x1 = 18, x2 = -18 })

-- Shows the full zone or gold text when its column is cut off
local function TallyRowTooltip(row)
    local zone, gold = row.cols[1], row.cols[3]
    if zone:IsTruncated() then return zone:GetText() end
    if gold:IsTruncated() then return gold:GetText() end
end

local tallyList = AlnUI:CreateScrollList(tallyFrame, {
    x1 = 18,  y1 = -80,
    x2 = -36, y2 = 56,
    rowHeight = 22,
    x         = 6,
    right     = 4,
    columns   = {
        { fill  = true, justify = "LEFT",  wordWrap = false },
        { width = 116,  justify = "RIGHT" },
        { width = 128,  justify = "RIGHT", wordWrap = false, gap = 6 },
    },
    -- rows are recycled, so the tooltip reads whatever the row shows now
    onRowInit = function(row)
        if not row.alnTooltip then AlnUI:AddTooltip(row, TallyRowTooltip) end
    end,
})


-- anchored to the bottom so it stays just under the list while resizing
local tallyBottomLine = AlnUI:CreateSeparator(tallyFrame, { x1 = 18, x2 = -18 })
tallyBottomLine:ClearAllPoints()
tallyBottomLine:SetPoint("BOTTOMLEFT", 18, 52)
tallyBottomLine:SetPoint("BOTTOMRIGHT", -18, 52)

-- Character / Account view: native tabs standing on a gold line under the
-- title. Clients with only bottom tabs get them below the window, and
-- clients with neither keep a toggle button.
local VIEW_CHARACTER, VIEW_ACCOUNT = 1, 2

local function SetView(index)
    ZTR.charView = index == VIEW_CHARACTER
    UpdateTally()
end

local tabStyle = (AlnUI:HasTabs("top") and "top") or (AlnUI:HasTabs("bottom") and "bottom")
if tabStyle then
    local viewTabs = AlnUI:CreateTabs(tallyFrame, {
        tabs     = { "Character", "Account" },
        style    = tabStyle,
        selected = ZTR.charView and VIEW_CHARACTER or VIEW_ACCOUNT,
        onSelect = SetView,
    })
    if tabStyle == "top" then
        viewTabs:SetPoint("BOTTOMLEFT", tallyFrame, "TOPLEFT", 20, -50)
        AlnUI:CreateSeparator(tallyFrame, { y = -50, x1 = 16, x2 = -16, color = { 1, 0.82, 0 } })
    else
        viewTabs:SetPoint("TOPLEFT", tallyFrame, "BOTTOMLEFT", 12, 6)
    end
else
    local viewBtn = AlnUI:CreateButton(tallyFrame, {
        width = 110, height = 22,
        text  = ZTR.charView and "View: Char" or "View: Account",
        tooltip = "View", tooltipText = "Show this character's data or account-wide totals.",
        onClick = function(self)
            SetView(ZTR.charView and VIEW_ACCOUNT or VIEW_CHARACTER)
            self:SetText(ZTR.charView and "View: Char" or "View: Account")
        end,
    })
    -- where the tabs would be
    viewBtn:SetPoint("TOPLEFT", 20, -26)
end



function UpdateTally()
    local data      = ZTR:GetSortedZones()
    local rows      = {}
    local totalTime = 0
    local totalGold = 0

    for i, entry in ipairs(data) do
        rows[i] = {
            entry.zone,
            ZTR:ColorTime(ZTR:FormatTime(entry.time)),
            ZTR:ColorGold(ZTR:FormatGold(entry.gold)),
        }
        totalTime = totalTime + entry.time
        totalGold = totalGold + entry.gold
    end

    tallyList:SetData(rows)
    -- the totals follow the selected tab, so say which one they are
    local scope = ZTR.charView and "Character" or "Account"
    tallyTimeText:SetText(scope .. " Time: " .. ZTR:ColorTime(ZTR:FormatTime(totalTime)))
    tallyGoldText:SetText(scope .. " Gold: " .. ZTR:ColorGold(ZTR:FormatGold(totalGold)))
end

-- totals in the bottom-left corner, under the list
tallyTimeText = AlnUI:CreateLabel(tallyFrame, { text = "Character Time: 0h 0m 0s", color = { 1, 0.82, 0 } })
tallyTimeText:SetPoint("BOTTOMLEFT", 20, 30)

tallyGoldText = AlnUI:CreateLabel(tallyFrame, { text = "Character Gold: 0g 0s 0c", color = { 1, 0.82, 0 } })
tallyGoldText:SetPoint("TOPLEFT", tallyTimeText, "BOTTOMLEFT", 0, -2)

-- ── Export window ────────────────────────────────────────────────────────────

local exportFrame = AlnUI:CreateDialog({
    name       = "ZoneTimerReduxExportFrame",
    title      = "Zone Timer – CSV Export",
    titleWidth = 520,
    width      = 600,
    height     = 400,
    strata     = "DIALOG",
    theme      = windowTheme(),
})

local _, exportEdit = AlnUI:CreateScrollFrame(exportFrame, {
    x1 = 16, y1 = -62,
    x2 = -30, y2 = 16,
    childType     = "EditBox",
    contentWidth  = 520,
    contentHeight = 1,
})
exportEdit:SetMultiLine(true)
exportEdit:SetFontObject(ChatFontNormal)
exportEdit:SetAutoFocus(false)
exportEdit:EnableMouse(true)
exportEdit:SetScript("OnEscapePressed", function() exportFrame:Hide() end)

-- ── Migration help window ─────────────────────────────────────────────────────

local migrationHelpFrame = AlnUI:CreateDialog({
    name       = "ZoneTimerReduxMigrationFrame",
    title      = "Importing from ZoneTimer",
    titleWidth = 400,
    width      = 480,
    height     = 270,
    strata     = "DIALOG",
    theme      = windowTheme(),
})

local migrationText = migrationHelpFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
migrationText:SetPoint("TOPLEFT",     migrationHelpFrame, "TOPLEFT",   24, -54)
migrationText:SetPoint("BOTTOMRIGHT", migrationHelpFrame, "BOTTOMRIGHT", -24, 16)
migrationText:SetJustifyH("LEFT")
migrationText:SetJustifyV("TOP")
migrationText:SetWordWrap(true)
migrationText:SetText(
    "If you used the original ZoneTimer addon you can bring your data over:\n\n" ..
    "1.  Close World of Warcraft completely.\n\n" ..
    "2.  Go to:  WTF\\Account\\<YourAccount>\\SavedVariables\\\n\n" ..
    "3.  Copy |cffFFD700ZoneTimer.lua|r and rename the copy to\n" ..
    "     |cffFFD700ZoneTimerRedux.lua|r, replacing the existing file.\n\n" ..
    "4.  Start the game — your data will appear automatically."
)

ZoneTimerRedux.ShowMigrationHelp = function()
    migrationHelpFrame:Show()
end

-- ── Theme ─────────────────────────────────────────────────────────────────────

local function ApplyTheme()
    local theme = windowTheme()
    mainFrame:SetTheme(theme)
    tallyFrame:SetTheme(theme)
    exportFrame:SetTheme(theme)
    migrationHelpFrame:SetTheme(theme)
end

ZoneTimerRedux.ApplyWindowTheme = ApplyTheme

local tallySizeRestored = false

local function ShowTally()
    -- SavedVariables aren't loaded when this file runs, so restore here
    if not tallySizeRestored and ZoneTimerSettings.tallyWidth then
        tallyFrame:SetClampedSize(ZoneTimerSettings.tallyWidth, ZoneTimerSettings.tallyHeight)
    end
    tallySizeRestored = true

    -- the saved sort is loaded after this file runs
    tallyHeader:SetSort(ZTR.sortMode, ZTR.sortAscending)
    UpdateTally()
    tallyFrame:Show()
end

-- ── Public API for settings panels ───────────────────────────────────────────

ZoneTimerRedux.mainFrame      = mainFrame
ZoneTimerRedux.LayoutMainFrame = LayoutMainFrame

ZoneTimerRedux.SetShowLabels = function(enabled)
    ZoneTimerSettings.showLabels = enabled
    LayoutMainFrame()
end

ZoneTimerRedux.SetFontSize = function(value)
    ZoneTimerSettings.fontSize = value
    LayoutMainFrame()
end

ZoneTimerRedux.SetGoldTracking = function(enabled)
    ZoneTimerSettings.trackGold = enabled
    LayoutMainFrame()
end

ZoneTimerRedux.ResetCurrentZone = function()
    if ZTR.currentZone then
        ZoneTimerSettings.times[ZTR.currentZone] = 0
        ZTR.enteredTime = time()
        timerText:SetText("---")
    end
end

ZoneTimerRedux.SetWindowVisible = function(visible)
    ZoneTimerSettings.windowVisible = visible
    if visible then mainFrame:Show() else mainFrame:Hide() end
end

ZoneTimerRedux.SyncTallySort = function()
    tallyHeader:SetSort(ZTR.sortMode, ZTR.sortAscending)
    if tallyFrame:IsShown() then UpdateTally() end
end

ZoneTimerRedux.ShowExport = function()
    exportEdit:SetText(ZTR:GenerateCSV())
    exportEdit:HighlightText()
    exportFrame:Show()
end

-- ── Event handler ─────────────────────────────────────────────────────────────

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_FLAGS_CHANGED" then
        if UnitIsAFK("player") then
            ZTR:Pause()
        else
            ZTR:Resume()
        end
        return
    end

    if event == "PLAYER_LOGOUT" then
        ZTR:SaveCurrentZone()
        return
    end

    -- PLAYER_ENTERING_WORLD or ZONE_CHANGED_NEW_AREA
    local zone = GetRealZoneText()
    if not zone or zone == "" then return end
    ZTR:EnterZone(zone)
    zoneText:SetText(ZTR.currentZone or "(loading...)")
end)

-- ── Slash commands ────────────────────────────────────────────────────────────

SLASH_ZONETIMEREDUX1 = "/zt"
SlashCmdList["ZONETIMEREDUX"] = function(msg)
    msg = string.lower(msg or "")

    if msg == "forcemilestone" and ZTR.DEBUG then
        local zone = ZTR.currentZone or "Test Zone"
        -- toasts queue, so these play one after another
        ZoneTimerRedux_ShowDiscoveredAlert(zone)
        ZoneTimerRedux_ShowMilestoneAlert(zone, 60)
        ZoneTimerRedux_ShowGoldMilestoneAlert(zone, 1000)
    elseif msg == "pause" then
        ZTR:Pause()
        print("Zone Timer Redux: paused.")
    elseif msg == "resume" then
        ZTR:Resume()
        print("Zone Timer Redux: resumed.")
    elseif msg == "tally" then
        ShowTally()
    elseif msg == "help" then
        print("|cff33ff99ZoneTimerRedux commands:|r")

        print("|cffffff00/zt|r " .. "|cffbbbbbb- toggle main window|r")
        print("|cffffff00/zt pause|r " .. "|cffbbbbbb- pause timer|r")
        print("|cffffff00/zt resume|r " .. "|cffbbbbbb- resume timer|r")
        print("|cffffff00/zt tally|r or |cffffff00/ztt|r " .. "|cffbbbbbb- show zone tally|r")
        print("|cffffff00/zt help|r " .. "|cffbbbbbb- show this list|r")
    else
        ZoneTimerRedux.SetWindowVisible(not mainFrame:IsShown())
    end
end

SLASH_ZONETIMERTALLY1 = "/ztt"
SlashCmdList["ZONETIMERTALLY"] = function()
    if tallyFrame:IsShown() then
        tallyFrame:Hide()
    else
        ShowTally()
    end
end
