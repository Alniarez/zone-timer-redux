-- ZoneTimerRedux/UI.lua

local ZTR = ZoneTimerRedux

-- ── Milestone alert ───────────────────────────────────────────────────────────

local function toastTheme()
    return ZoneTimerSettings.goldenTheme ~= false and "gold" or "standard"
end

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
    theme         = ZoneTimerSettings.goldenTheme ~= false and "gold" or "standard",
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

local separator = mainFrame:CreateTexture(nil, "ARTWORK")
separator:SetHeight(1)
separator:SetColorTexture(0.55, 0.45, 0.05, 0.6)

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

local tallyRows     = {}
local tallyTimeText
local tallyGoldText
local UpdateTally

local tallyFrame = AlnUI:CreateDialog({
    name       = "ZoneTimerReduxTallyFrame",
    title      = "Zone Timer Tally",
    titleWidth = 360,
    width      = 520,
    height     = 520,
    theme      = ZoneTimerSettings.goldenTheme ~= false and "gold" or "standard",
})

AlnUI:CreateColumnRow(tallyFrame, { font = "GameFontNormal", x = 24, y = -44 },
{
    { text = "Zone", width = 210, justify = "LEFT" },
    { text = "Time", width = 120, justify = "RIGHT" },
    { text = "Gold", width = 130, justify = "RIGHT", gap = 6 },
})

local _, tallyContent = AlnUI:CreateScrollFrame(tallyFrame, {
    x1 = 18,  y1 = -62,
    x2 = -36, y2 = 50,
    contentWidth = 360, contentHeight = 400,
})

local tallySortBtn = AlnUI:CreateButton(tallyFrame, { width = 120, height = 22, text = "Sort: Time" })
tallySortBtn:SetPoint("BOTTOMRIGHT", -16, 16)

local tallyViewBtn = AlnUI:CreateButton(tallyFrame, { width = 110, height = 22, text = "View: Char" })
tallyViewBtn:SetPoint("BOTTOMRIGHT", tallySortBtn, "BOTTOMLEFT", -6, 0)

tallySortBtn:SetScript("OnClick", function()
    ZTR.sortMode = ZTR.sortMode == "time" and "gold" or "time"
    ZoneTimerSettings.tallySort = ZTR.sortMode
    tallySortBtn:SetText(ZTR.sortMode == "gold" and "Sort: Gold" or "Sort: Time")
    UpdateTally()
end)

tallyViewBtn:SetScript("OnClick", function()
    ZTR.charView = not ZTR.charView
    tallyViewBtn:SetText(ZTR.charView and "View: Char" or "View: Account")
    UpdateTally()
end)

local function ClearTallyRows()
    for _, fs in ipairs(tallyRows) do
        fs:Hide()
        fs:SetParent(nil)
    end
    wipe(tallyRows)
end

function UpdateTally()
    ClearTallyRows()

    local data      = ZTR:GetSortedZones()
    local rowHeight = 22
    local totalTime = 0
    local totalGold = 0

    for i, entry in ipairs(data) do
        local y       = -8 - (i - 1) * rowHeight
        local goldStr = ZTR:ColorGold(ZTR:FormatGold(entry.gold))

        local cols = AlnUI:CreateColumnRow(tallyContent, { y = y }, {
            { text = entry.zone,                                 width = 210, justify = "LEFT",  wordWrap = false },
            { text = ZTR:ColorTime(ZTR:FormatTime(entry.time)), width = 120, justify = "RIGHT" },
            { text = goldStr,                                    width = 130, justify = "RIGHT", wordWrap = false, gap = 6 },
        })

        cols[1]:SetScript("OnEnter", function(self)
            if self:IsTruncated() then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(entry.zone, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        cols[1]:SetScript("OnLeave", GameTooltip_Hide)

        cols[3]:SetScript("OnEnter", function(self)
            if self:IsTruncated() then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(goldStr, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        cols[3]:SetScript("OnLeave", GameTooltip_Hide)

        for _, fs in ipairs(cols) do table.insert(tallyRows, fs) end

        totalTime = totalTime + entry.time
        totalGold = totalGold + entry.gold
    end

    tallyContent:SetHeight(math.max(400, (#data + 1) * rowHeight))
    tallyTimeText:SetText("Total Time: " .. ZTR:ColorTime(ZTR:FormatTime(totalTime)))
    tallyGoldText:SetText("Total Gold: " .. ZTR:ColorGold(ZTR:FormatGold(totalGold)))
end

tallyTimeText = tallyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
tallyTimeText:SetPoint("BOTTOMLEFT", 20, 30)
tallyTimeText:SetJustifyH("LEFT")
tallyTimeText:SetText("Total Time: 0h 0m 0s")
tallyTimeText:SetTextColor(1, 0.82, 0)

tallyGoldText = tallyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
tallyGoldText:SetPoint("TOPLEFT", tallyTimeText, "BOTTOMLEFT", 0, -2)
tallyGoldText:SetJustifyH("LEFT")
tallyGoldText:SetText("Total Gold: 0g 0s 0c")
tallyGoldText:SetTextColor(1, 0.82, 0)

-- ── Export window ────────────────────────────────────────────────────────────

local exportFrame = AlnUI:CreateDialog({
    name       = "ZoneTimerReduxExportFrame",
    title      = "Zone Timer – CSV Export",
    titleWidth = 520,
    width      = 600,
    height     = 400,
    strata     = "DIALOG",
    theme      = ZoneTimerSettings.goldenTheme ~= false and "gold" or "standard",
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
    theme      = ZoneTimerSettings.goldenTheme ~= false and "gold" or "standard",
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

local THEME_TEXTURES = {
    gold     = { edge = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",   header = "Interface\\DialogFrame\\UI-DialogBox-Gold-Header" },
    standard = { edge = "Interface\\DialogFrame\\UI-DialogBox-Border",        header = "Interface\\DialogFrame\\UI-DialogBox-Header" },
}

local function ApplyTheme()
    local t = ZoneTimerSettings.goldenTheme ~= false and THEME_TEXTURES.gold or THEME_TEXTURES.standard
    local backdrop = {
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = t.edge,
        edgeSize = 32,
        insets   = { left = 8, right = 8, top = 8, bottom = 8 },
    }
    mainFrame:SetBackdrop(backdrop)
    tallyFrame:SetBackdrop(backdrop)
    exportFrame:SetBackdrop(backdrop)
    migrationHelpFrame:SetBackdrop(backdrop)
    if tallyFrame.titleBanner        then tallyFrame.titleBanner:SetTexture(t.header)        end
    if exportFrame.titleBanner       then exportFrame.titleBanner:SetTexture(t.header)       end
    if migrationHelpFrame.titleBanner then migrationHelpFrame.titleBanner:SetTexture(t.header) end
end

ZoneTimerRedux.ApplyWindowTheme = ApplyTheme

local function ShowTally()
    tallySortBtn:SetText(ZTR.sortMode == "gold" and "Sort: Gold" or "Sort: Time")
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
    tallySortBtn:SetText(ZTR.sortMode == "gold" and "Sort: Gold" or "Sort: Time")
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
        ZoneTimerRedux_ShowDiscoveredAlert(zone)
        C_Timer.After(7,  function() ZoneTimerRedux_ShowMilestoneAlert(zone, 60)        end)
        C_Timer.After(14, function() ZoneTimerRedux_ShowGoldMilestoneAlert(zone, 1000)  end)
    elseif msg == "pause" then
        ZTR:Pause()
        print("Zone Timer Redux: paused.")
    elseif msg == "resume" then
        ZTR:Resume()
        print("Zone Timer Redux: resumed.")
    elseif msg == "tally" then
        ShowTally()
    elseif msg == "help" then
        print("/zt             – toggle main window")
        print("/zt pause       – pause timer")
        print("/zt resume      – resume timer")
        print("/zt tally       – show zone tally")
        print("/zt help        – show this list")
        print("/ztt            – toggle zone tally directly")
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
