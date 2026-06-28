-- ZoneTimerRedux/UI.lua

local ZTR = ZoneTimerRedux

-- ── Milestone alert ───────────────────────────────────────────────────────────
-- Global so Core.lua can call it from CheckMilestones.

function ZoneTimerRedux_ShowMilestoneAlert(zone, minutes)
    local hrs    = math.floor(minutes / 60)
    local remMin = minutes % 60
    local timeText = string.format("%dh", hrs)
    if remMin > 0 then timeText = timeText .. string.format(" %dm", remMin) end

    AlnUI:ShowToast({
        icon  = "Interface\\Icons\\achievement_zone_burningsteppes",
        title = "Milestone Reached!",
        text  = string.format("You spent %s in %s!", timeText, zone),
        sound = 12891,
    })
end

function ZoneTimerRedux_ShowGoldMilestoneAlert(zone, gold)
    AlnUI:ShowToast({
        icon  = "Interface\\Icons\\inv_misc_coin_01",
        title = "Gold Milestone!",
        text  = string.format("%dg earned in %s!", gold, zone),
        sound = 12891,
    })
end

function ZoneTimerRedux_ShowDiscoveredAlert(zone)
    AlnUI:ShowToast({
        icon  = "Interface\\Icons\\inv_misc_map_01",
        title = "Zone Discovered!",
        text  = string.format("New zone discovered: %s", zone),
        sound = 12889,
    })
end

-- ── Main timer frame ──────────────────────────────────────────────────────────

local function CalcFrameHeight()
    local h = 39 + 3 * ZoneTimerSettings.fontSize
    if ZoneTimerSettings.trackGold == false then
        h = h - (ZoneTimerSettings.fontSize + 8)
    end
    if ZTR.DEBUG and ZoneTimerSettings.showSubzone ~= false then
        h = h + 16
    end
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
mainFrame:Show()

local zoneText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
zoneText:SetPoint("TOP", mainFrame, "TOP", 0, -12)
zoneText:SetFont("Fonts\\FRIZQT__.TTF", ZoneTimerSettings.fontSize + 4)
zoneText:SetText("---")

local subzoneText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
subzoneText:SetFont("Fonts\\FRIZQT__.TTF", ZoneTimerSettings.fontSize - 1)
subzoneText:SetTextColor(0.8, 0.8, 0.8)
subzoneText:SetText("")

local timerText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
timerText:SetFont("Fonts\\FRIZQT__.TTF", ZoneTimerSettings.fontSize)
timerText:SetText("Time: 0s")

if ZTR.DEBUG and ZoneTimerSettings.showSubzone ~= false then
    subzoneText:SetPoint("TOP", zoneText, "BOTTOM", 0, -2)
    timerText:SetPoint("TOP", subzoneText, "BOTTOM", 0, -4)
else
    subzoneText:Hide()
    timerText:SetPoint("TOP", zoneText, "BOTTOM", 0, -4)
end

local goldText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
goldText:SetPoint("TOP", timerText, "BOTTOM", 0, -4)
goldText:SetText("Gold: 0g 0s 0c")

if ZoneTimerSettings.trackGold == false then
    goldText:Hide()
end

mainFrame:SetScript("OnUpdate", function()
    if not ZTR.currentZone then return end

    if ZTR.DEBUG and ZoneTimerSettings.showSubzone ~= false then
        subzoneText:SetText(GetSubZoneText() or "")
    end

    local total = ZTR:GetCurrentTime()
    timerText:SetText("Time: " .. ZTR:ColorTime(ZTR:FormatTime(total)))

    if ZoneTimerSettings.trackGold ~= false then
        local copper = ZTR:GetZoneGold(ZTR.currentZone)
        goldText:SetText("Gold: " .. ZTR:ColorGold(ZTR:FormatGold(copper)))
        ZTR:CheckGoldMilestones(ZTR.currentZone, copper)
    end

    ZTR:CheckMilestones(ZTR.currentZone, total)
end)

-- ── Tally window ──────────────────────────────────────────────────────────────

local tallyRows     = {}
local tallyTimeText
local tallyGoldText
local UpdateTally   -- forward declaration

local tallyFrame = AlnUI:CreateDialog({
    name       = "ZoneTimerReduxTallyFrame",
    title      = "Zone Timer Tally",
    titleWidth = 300,
    width      = 520,
    height     = 520,
    theme      = ZoneTimerSettings.goldenTheme ~= false and "gold" or "standard",
})

AlnUI:CreateColumnRow(tallyFrame, { font = "GameFontNormal", x = 24, y = -44 }, {
    { text = "Zone", width = 210, justify = "LEFT" },
    { text = "Time", width = 120, justify = "RIGHT" },
    { text = "Gold", width = 130, justify = "RIGHT", gap = 6 },
})

local _, tallyContent = AlnUI:CreateScrollFrame(tallyFrame, {
    x1 = 18,  y1 = -62,
    x2 = -36, y2 = 50,
    contentWidth = 360, contentHeight = 400,
})

local tallyExportBtn = AlnUI:CreateButton(tallyFrame, { width = 100, height = 22, text = "Export" })
tallyExportBtn:SetPoint("BOTTOMRIGHT", -16, 16)

local tallySortBtn = AlnUI:CreateButton(tallyFrame, { width = 120, height = 22, text = "Sort: Time" })
tallySortBtn:SetPoint("BOTTOMRIGHT", tallyExportBtn, "BOTTOMLEFT", -6, 0)

tallySortBtn:SetScript("OnClick", function()
    ZTR.sortMode = ZTR.sortMode == "time" and "gold" or "time"
    ZoneTimerSettings.tallySort = ZTR.sortMode
    tallySortBtn:SetText(ZTR.sortMode == "gold" and "Sort: Gold" or "Sort: Time")
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

-- Export window

local exportFrame = AlnUI:CreateDialog({
    name       = "ZoneTimerReduxExportFrame",
    title      = "Zone Timer – CSV Export",
    titleWidth = 520,
    width      = 600,
    height     = 400,
    strata     = "DIALOG",
    level      = tallyFrame:GetFrameLevel() + 10,
    theme      = ZoneTimerSettings.goldenTheme ~= false and "gold" or "standard",
})
exportFrame:ClearAllPoints()
exportFrame:SetPoint("CENTER", tallyFrame, "CENTER")

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

tallyExportBtn:SetScript("OnClick", function()
    exportEdit:SetText(ZTR:GenerateCSV())
    exportEdit:HighlightText()
    exportFrame:Show()
end)

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
    if tallyFrame.titleBanner  then tallyFrame.titleBanner:SetTexture(t.header)  end
    if exportFrame.titleBanner then exportFrame.titleBanner:SetTexture(t.header) end
end

ZoneTimerRedux.ApplyWindowTheme = ApplyTheme

mainFrame:HookScript("OnShow", ApplyTheme)
tallyFrame:HookScript("OnShow", ApplyTheme)
exportFrame:HookScript("OnShow", ApplyTheme)

local function ShowTally()
    tallySortBtn:SetText(ZTR.sortMode == "gold" and "Sort: Gold" or "Sort: Time")
    UpdateTally()
    tallyFrame:Show()
end

-- ── Public API for settings panels ───────────────────────────────────────────

ZoneTimerRedux.mainFrame = mainFrame

ZoneTimerRedux.SetShowSubzone = function(enabled)
    ZoneTimerSettings.showSubzone = enabled
    if enabled then
        subzoneText:Show()
        timerText:ClearAllPoints()
        timerText:SetPoint("TOP", subzoneText, "BOTTOM", 0, -4)
    else
        subzoneText:Hide()
        timerText:ClearAllPoints()
        timerText:SetPoint("TOP", zoneText, "BOTTOM", 0, -4)
    end
    mainFrame:SetHeight(CalcFrameHeight())
end

ZoneTimerRedux.SetFontSize = function(value)
    ZoneTimerSettings.fontSize = value
    zoneText:SetFont("Fonts\\FRIZQT__.TTF", value + 4)
    subzoneText:SetFont("Fonts\\FRIZQT__.TTF", value - 1)
    timerText:SetFont("Fonts\\FRIZQT__.TTF", value)
    mainFrame:SetHeight(CalcFrameHeight())
end

ZoneTimerRedux.SetGoldTracking = function(enabled)
    ZoneTimerSettings.trackGold = enabled
    if enabled then
        goldText:Show()
    else
        goldText:Hide()
    end
    mainFrame:SetHeight(CalcFrameHeight())
end

ZoneTimerRedux.ResetCurrentZone = function()
    if ZTR.currentZone then
        ZoneTimerSettings.times[ZTR.currentZone] = 0
        ZTR.enteredTime = time()
        timerText:SetText("Time: 0s")
    end
end

ZoneTimerRedux.SyncTallySort = function()
    tallySortBtn:SetText(ZTR.sortMode == "gold" and "Sort: Gold" or "Sort: Time")
    if tallyFrame:IsShown() then UpdateTally() end
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
        if ZTR.currentZone then
            ZoneTimerRedux_ShowMilestoneAlert(ZTR.currentZone, 999)
        end
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
        if mainFrame:IsShown() then
            mainFrame:Hide()
        else
            mainFrame:Show()
        end
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
