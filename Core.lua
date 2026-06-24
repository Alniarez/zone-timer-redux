-- ZoneTimerRedux/Core.lua

ZoneTimerRedux = {}
ZoneTimerRedux.VERSION  = "1.0"
ZoneTimerRedux.sortMode = "time"
ZoneTimerRedux.DEBUG    = false

-- ── Runtime state (not persisted) ────────────────────────────────────────────
ZoneTimerRedux.currentZone = nil
ZoneTimerRedux.enteredTime = nil
ZoneTimerRedux.isPaused    = false

-- ── Debug helper ─────────────────────────────────────────────────────────────

local function DebugPrint(...)
    if not ZoneTimerRedux.DEBUG then return end
    print("|cff33ff99ZoneTimerRedux:|r", ...)
end

-- ── SavedVariable defaults (populated before addon files run) ─────────────────
ZoneTimerSettings                       = ZoneTimerSettings or {}
ZoneTimerSettings.times                 = ZoneTimerSettings.times or {}
ZoneTimerSettings.announcedMilestones   = ZoneTimerSettings.announcedMilestones or {}
ZoneTimerSettings.width                 = ZoneTimerSettings.width    or 220
ZoneTimerSettings.opacity               = ZoneTimerSettings.opacity  or 1.0
ZoneTimerSettings.fontSize              = ZoneTimerSettings.fontSize or 12
if ZoneTimerSettings.trackGold  == nil then ZoneTimerSettings.trackGold  = true end
if ZoneTimerSettings.showAlerts == nil then ZoneTimerSettings.showAlerts = true end
if ZoneTimerSettings.tallySort   == nil then ZoneTimerSettings.tallySort   = "time" end
if ZoneTimerSettings.goldenTheme == nil then ZoneTimerSettings.goldenTheme = true end
if ZoneTimerSettings.showSubzone == nil then ZoneTimerSettings.showSubzone = true end

ZoneTimerRedux.sortMode = ZoneTimerSettings.tallySort

ZoneGoldDB = ZoneGoldDB or {}

-- ── Formatting ────────────────────────────────────────────────────────────────

function ZoneTimerRedux:FormatTime(seconds)
    seconds = tonumber(seconds) or 0
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then return string.format("%dh %dm %ds", h, m, s) end
    if m > 0 then return string.format("%dm %ds", m, s) end
    return string.format("%ds", s)
end

function ZoneTimerRedux:ColorTime(text)
    local h, m, s = text:match("(%d+)h (%d+)m (%d+)s")
    if h then
        return string.format("|cffffd200%sh|r |cffc7c7cf%sm|r |cff9d9d9d%ss|r", h, m, s)
    end
    local m2, s2 = text:match("(%d+)m (%d+)s")
    if m2 then
        return string.format("|cffc7c7cf%sm|r |cff9d9d9d%ss|r", m2, s2)
    end
    return text
end

function ZoneTimerRedux:FormatGold(copper)
    copper = tonumber(copper) or 0
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    return string.format("%dg %ds %dc", g, s, c)
end

function ZoneTimerRedux:ColorGold(text)
    local g, s, c = text:match("(%d+)g (%d+)s (%d+)c")
    if not g then return text end
    return string.format("|cffFFD700%sg|r |cffffffff%ss|r |cffff7f00%sc|r", g, s, c)
end

-- ── Data accessors ────────────────────────────────────────────────────────────

function ZoneTimerRedux:GetZoneGold(zone)
    return ZoneGoldDB[zone] or 0
end

function ZoneTimerRedux:GetCurrentTime()
    if not self.currentZone then return 0 end
    local saved  = ZoneTimerSettings.times[self.currentZone] or 0
    if self.isPaused or not self.enteredTime then return saved end
    return saved + (time() - self.enteredTime)
end

function ZoneTimerRedux:GetSortedZones()
    local list = {}
    for zone, t in pairs(ZoneTimerSettings.times) do
        table.insert(list, { zone = zone, time = t, gold = self:GetZoneGold(zone) })
    end
    table.sort(list, function(a, b)
        if self.sortMode == "gold" then return a.gold > b.gold end
        return a.time > b.time
    end)
    return list
end

function ZoneTimerRedux:GenerateCSV()
    local lines = { "Zone,TimeSeconds,TimeFormatted,GoldCopper,GoldFormatted" }
    for _, entry in ipairs(self:GetSortedZones()) do
        table.insert(lines, string.format(
            "%q,%s,%q,%s,%q",
            entry.zone,
            tostring(math.floor(entry.time)),
            self:FormatTime(entry.time),
            tostring(entry.gold),
            self:FormatGold(entry.gold)
        ))
    end
    return table.concat(lines, "\n")
end

-- ── Zone lifecycle ────────────────────────────────────────────────────────────

function ZoneTimerRedux:SaveCurrentZone()
    if self.currentZone and self.enteredTime and not self.isPaused then
        local elapsed = time() - self.enteredTime
        ZoneTimerSettings.times[self.currentZone] =
            (ZoneTimerSettings.times[self.currentZone] or 0) + elapsed
        DebugPrint(string.format("Saved %q: +%ds (total %ds)", self.currentZone, elapsed, ZoneTimerSettings.times[self.currentZone]))
    end
end

function ZoneTimerRedux:EnterZone(zone)
    if not zone or zone == "" then return end
    self:SaveCurrentZone()
    self.currentZone = zone
    self.enteredTime = self.isPaused and nil or time()
    DebugPrint(string.format("Entered zone: %q (paused: %s)", tostring(zone), tostring(self.isPaused)))

    local ann = ZoneTimerSettings.announcedMilestones
    local isNew = not (ZoneTimerSettings.times[zone] and ZoneTimerSettings.times[zone] > 0)
               and not (ann[zone] and ann[zone]["discovered"])
    if isNew and ZoneTimerSettings.showAlerts then
        ann[zone] = ann[zone] or {}
        ann[zone]["discovered"] = true
        DebugPrint(string.format("New zone discovered: %q", zone))
        if ZoneTimerRedux_ShowDiscoveredAlert then
            ZoneTimerRedux_ShowDiscoveredAlert(zone)
        end
    end
end

function ZoneTimerRedux:Pause()
    self:SaveCurrentZone()
    self.isPaused    = true
    self.enteredTime = nil
    DebugPrint("Timer paused.")
end

function ZoneTimerRedux:Resume()
    self.isPaused    = false
    self.enteredTime = time()
    DebugPrint("Timer resumed.")
end

-- ── Milestones ────────────────────────────────────────────────────────────────

-- 30m, 1h, 2h, 3h, 5h, then every 10h up to 200h
do
    local m = { 30, 60, 120, 180, 300 }
    for i = 1, 20 do table.insert(m, i * 600) end
    ZoneTimerRedux.MILESTONES = m
end

function ZoneTimerRedux:CheckMilestones(zone, totalSeconds)
    if not zone then return end
    local ann = ZoneTimerSettings.announcedMilestones
    ann[zone] = ann[zone] or {}
    local minutes = math.floor(totalSeconds / 60)
    for _, m in ipairs(self.MILESTONES) do
        if minutes >= m and not ann[zone][m] then
            ann[zone][m] = true
            DebugPrint(string.format("Milestone %dm reached in %q (alerts: %s)", m, zone, tostring(ZoneTimerSettings.showAlerts)))
            if ZoneTimerSettings.showAlerts then
                ZoneTimerRedux_ShowMilestoneAlert(zone, m)
            end
        end
    end
end

function ZoneTimerRedux:CheckGoldMilestones(zone, totalCopper)
    if not zone then return end
    local ann = ZoneTimerSettings.announcedMilestones
    ann[zone] = ann[zone] or {}
    local goldK = math.floor(totalCopper / 1000000)  -- 1,000g = 1,000,000 copper
    for k = 1, goldK do
        local key = "g" .. k
        if not ann[zone][key] then
            ann[zone][key] = true
            DebugPrint(string.format("Gold milestone %dk reached in %q (alerts: %s)", k, zone, tostring(ZoneTimerSettings.showAlerts)))
            if ZoneTimerSettings.showAlerts then
                ZoneTimerRedux_ShowGoldMilestoneAlert(zone, k * 1000)
            end
        end
    end
end

-- ── Gold tracking ─────────────────────────────────────────────────────────────

local goldFrame = CreateFrame("Frame")
goldFrame:RegisterEvent("CHAT_MSG_MONEY")
goldFrame:SetScript("OnEvent", function(_, _, message)
    local zone = GetRealZoneText()
    if not zone then return end

    local locale    = GetLocale()
    local goldPat   = locale == "ptBR" and "(%d+)[^%d]*[Oo]uro"  or "(%d+)[^%d]*[Gg]old"
    local silverPat = locale == "ptBR" and "(%d+)[^%d]*[Pp]rata" or "(%d+)[^%d]*[Ss]ilver"
    local copperPat = locale == "ptBR" and "(%d+)[^%d]*[Cc]obre" or "(%d+)[^%d]*[Cc]opper"

    local g = tonumber(string.match(message, goldPat))   or 0
    local s = tonumber(string.match(message, silverPat)) or 0
    local c = tonumber(string.match(message, copperPat)) or 0

    local earned = g * 10000 + s * 100 + c
    ZoneGoldDB[zone] = (ZoneGoldDB[zone] or 0) + earned
    DebugPrint(string.format("Gold in %q: +%dc (total %dc)", zone, earned, ZoneGoldDB[zone]))
end)
