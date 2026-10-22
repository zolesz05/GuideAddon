-- Moteve Guide - step-by-step leveling guide (RestedXP-style) for WoW Forever.
-- Shows the current step and the next ones, an arrow to the target, a map waypoint,
-- advances by itself from the quest log, and can accept / turn in the guide's quests.
local ADDON_NAME, ns = ...
local C = ns.C
local format, floor, abs, max, min, atan2, sqrt, pi = string.format, math.floor, math.abs, math.max, math.min, math.atan2, math.sqrt, math.pi
local secret = issecretvalue or function() return false end

local DEFAULTS = {
    guideSkin = "moteve", arrowSkin = "moteve",
    show = true, arrow = true, waypoint = true, autoQuest = true, xp = true, lines = 4, scale = 0.85,
    point = "RIGHT", relPoint = "RIGHT", x = -40, y = 120,
    apoint = "TOP", arelPoint = "TOP", ax = 0, ay = -170,
}
local db, char
local function Print(m) print("|cffffcf5aMoteve Guide|r: " .. m) end
ns.Print = Print

---------------------------------------------------------------------------
-- Quest log helpers (modern C_QuestLog first, old API as fallback)
---------------------------------------------------------------------------
local logCache, logDirty = {}, true
local function ScanLog()
    logCache = {}
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        local n = C_QuestLog.GetNumQuestLogEntries()
        for i = 1, n do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader and info.questID then
                local done = false
                if C_QuestLog.IsComplete then done = C_QuestLog.IsComplete(info.questID) and true or false end
                if not done and C_QuestLog.ReadyForTurnIn then done = C_QuestLog.ReadyForTurnIn(info.questID) and true or false end
                logCache[info.questID] = { complete = done or info.isComplete == 1 or info.isComplete == true }
            end
        end
    elseif GetNumQuestLogEntries then
        for i = 1, GetNumQuestLogEntries() do
            local _, _, _, isHeader, _, isComplete, _, qid = GetQuestLogTitle(i)
            if not isHeader and qid then logCache[qid] = { complete = isComplete == 1 } end
        end
    end
    logDirty = false
end
local function InLog(q) if logDirty then ScanLog() end return logCache[q] ~= nil end
local function LogComplete(q) if logDirty then ScanLog() end return logCache[q] and logCache[q].complete end
local function Completed(q)
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then return C_QuestLog.IsQuestFlaggedCompleted(q) and true or false end
    if IsQuestFlaggedCompleted then return IsQuestFlaggedCompleted(q) and true or false end
    return false
end

---------------------------------------------------------------------------
-- Guide / steps
---------------------------------------------------------------------------
local CLASSBIT = { WARRIOR = 1, PALADIN = 2, HUNTER = 4, ROGUE = 8, PRIEST = 16, SHAMAN = 64, MAGE = 128, WARLOCK = 256, DRUID = 1024 }
local RACEBIT = { HUMAN=1,ORC=2,DWARF=4,NIGHTELF=8,SCOURGE=16,UNDEAD=16,TAUREN=32,GNOME=64,TROLL=128 }
local guide
function ns.GuideAvailable(g)
    local required=g.faction
    if not required and (g.id=="orctroll" or g.id=="undead" or g.id=="tauren") then required="Horde" end
    if not required then return true end
    local faction=UnitFactionGroup and UnitFactionGroup("player")
    return not secret(faction) and (not faction or required==faction)
end
local function GuideById(id) for _, g in ipairs(ns.GUIDES or {}) do if g.id == id then return g end end end
local function GuideForRace()
    local _, race = UnitRace("player")
    race = race and race:upper() or ""
    for _, g in ipairs(ns.GUIDES or {}) do if g.races[race] then return g end end
    return ns.GUIDES and ns.GUIDES[1]
end

local function ClassOk(s)
    if s.rr and s.rr~=0 then
        local _,race=UnitRace("player")
        if secret(race) or bit.band(s.rr,RACEBIT[(race or ""):upper()] or 0)==0 then return false end
    end
    if not s.cls then return true end
    local _, cls = UnitClass("player")
    local b = CLASSBIT[cls or ""] or 0
    return bit.band(s.cls, b) ~= 0
end

-- is this step finished (or not for us)?
local function StepDone(i)
    local s = guide.steps[i]
    if not s then return true end
    if char.skip[i] then return true end
    if not ClassOk(s) then return true end
    if s.q and not InLog(s.q) and not Completed(s.q) then
        for _,q in ipairs(s.pre or {}) do if not Completed(q) then return true end end
        if s.anypre then
            local found=false
            for _,q in ipairs(s.anypre) do if Completed(q) then found=true;break end end
            if not found then return true end
        end
        for _,q in ipairs(s.ex or {}) do if InLog(q) or Completed(q) then return true end end
    end
    local k = s.k
    if k == "zone" or k == "lvl" then return true end
    if k == "a" then return InLog(s.q) or Completed(s.q) end
    if k == "c" then return Completed(s.q) or (InLog(s.q) and LogComplete(s.q)) end
    if k == "t" then return Completed(s.q) end
    if k == "grind" then return (UnitLevel("player") or 1) >= (s.lv or 1) end
    if k == "fp" then return char.fp[s.npc or s.t] and true or false end
    return false
end
ns.StepDone = StepDone

-- A manually selected historical step stays readable until navigation resumes.
-- This is session-only; saved quest/skip completion is never cleared by looking back.
local reviewIndex, reviewGuide
local function ClearReview() reviewIndex, reviewGuide = nil, nil end
local function ReviewStep(i)
    char.idx = i
    reviewIndex, reviewGuide = i, guide
end
local function Actionable(i)
    local s = guide.steps[i]
    return s and s.k ~= "zone" and s.k ~= "lvl" and ClassOk(s)
end

-- skip forward over finished steps; never jump backwards on its own
local function Advance()
    if not guide then return end
    if reviewGuide == guide and reviewIndex == char.idx then return end
    ClearReview()
    local n = #guide.steps
    local i = max(1, char.idx or 1)
    while i <= n and StepDone(i) do i = i + 1 end
    char.idx = i
end

local function NextStep()
    ClearReview()
    if guide.steps[char.idx] and not StepDone(char.idx) then char.skip[char.idx] = true end
    Advance(); ns.Refresh()
end

local function PreviousStep()
    local j = min(#guide.steps, (char.idx or 1) - 1)
    while j >= 1 and not Actionable(j) do j = j - 1 end
    if j >= 1 then ReviewStep(j) end
    ns.Refresh()
end

-- Saved progress (char.idx, char.skip) is keyed by step index. When a route loses ("-") or
-- gains ("+") steps, remap it once, in order, so started characters keep their place.
-- Checked against the old and new Guides.lua by tools/check_step_migration.py.
local STEP_REV = 1
local STEP_EDITS = {
    [1] = {   -- 0.7.2: no Razor Hill / Brill / Bloodhoof fp; 'A Task Unfinished' on the Bloodhoof road
        orctroll = { { "-", 62 } },
        undead = { { "-", 46 } },
        tauren = { { "-", 83 }, { "-", 82 }, { "-", 34 }, { "+", 34 }, { "+", 35 } },
    },
}
local function MigrateSteps()
    if char.idx then
        for r = (char.stepRev or 0) + 1, STEP_REV do
            local gone = false   -- the current step was removed: show steps inserted in its place
            for _, e in ipairs(STEP_EDITS[r] and STEP_EDITS[r][char.guide] or {}) do
                local op, at, skip = e[1], e[2], {}
                for i in pairs(char.skip) do
                    if op == "+" then skip[i >= at and i + 1 or i] = true
                    elseif i ~= at then skip[i > at and i - 1 or i] = true end
                end
                char.skip = skip
                if op == "-" and char.idx == at then gone = true
                elseif char.idx > at or (op == "+" and char.idx == at and not gone) then
                    char.idx = char.idx + (op == "+" and 1 or -1)
                end
            end
        end
    end
    char.stepRev = STEP_REV
end

-- first run: start where the character really is (level and finished quests)
local function FindStart()
    local lv = UnitLevel("player") or 1
    for i, s in ipairs(guide.steps) do
        if (s.el or 1) >= lv - 1 and not StepDone(i) then return i end
    end
    return 1
end

local function ZoneOf(i)
    for j = i, 1, -1 do local s = guide.steps[j]; if s and s.k == "zone" then return s.t end end
    return ""
end

---------------------------------------------------------------------------
-- Quest objectives (progress like "Vile Familiar slain: 6/12")
---------------------------------------------------------------------------
local function ParseObj(text, have, need, done)
    text = text or ""
    if not need then
        local n, a, b = text:match("^(.-):%s*(%d+)%s*/%s*(%d+)")
        if n then text, have, need = n, tonumber(a), tonumber(b)
        else
            a, b, n = text:match("^(%d+)%s*/%s*(%d+)%s+(.+)$")
            if a then text, have, need = n, tonumber(a), tonumber(b) end
        end
    else
        text = text:gsub("^%d+%s*/%s*%d+%s+", ""):gsub(":%s*%d+%s*/%s*%d+$", "")
    end
    have, need = tonumber(have) or (done and 1 or 0), tonumber(need) or 1
    if need < 1 then need = 1 end
    return { text = text, have = have, need = need, done = done or have >= need }
end
local function Objectives(q)
    if not q or not InLog(q) then return nil end
    local out = {}
    if C_QuestLog and C_QuestLog.GetQuestObjectives then
        local ok, t = pcall(C_QuestLog.GetQuestObjectives, q)
        if ok and type(t) == "table" then
            for _, o in ipairs(t) do
                if o.text and o.text ~= "" then out[#out + 1] = ParseObj(o.text, o.numFulfilled, o.numRequired, o.finished) end
            end
            return out
        end
    end
    if GetQuestLogIndexByID and GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
        local idx = GetQuestLogIndexByID(q)
        if idx and idx > 0 then
            for j = 1, GetNumQuestLeaderBoards(idx) or 0 do
                local text, _, fin = GetQuestLogLeaderBoard(j, idx)
                if text then out[#out + 1] = ParseObj(text, nil, nil, fin and true or false) end
            end
        end
    end
    return out
end
ns.Objectives = Objectives

---------------------------------------------------------------------------
-- Window: dark panel, bronze frame, horns + war banners, race medallion,
-- header plate, scrollable list of the upcoming steps, XP footer.
---------------------------------------------------------------------------
local W = 420
local TOPPAD, FOOT = 84, 44
local GOLDT = { 1, 0.82, 0.25 }
local GREY = { 0.68, 0.66, 0.60 }
local WHITE_T = { 0.96, 0.95, 0.92 }

local F = CreateFrame("Frame", "MoteveGuideFrame", UIParent)
F:SetSize(W, 360)
F:SetFrameStrata("MEDIUM")
F:SetMovable(true); F:EnableMouse(true); F:SetClampedToScreen(true)
F:SetClampRectInsets(-18, 18, 28, 0)
F:RegisterForDrag("LeftButton")
local function SavePos()
    F:StopMovingOrSizing()
    local p, _, rp, x, y = F:GetPoint()
    db.point, db.relPoint, db.x, db.y = p, rp, x, y
end
F:SetScript("OnDragStart", F.StartMoving)
F:SetScript("OnDragStop", SavePos)

-- war banners hanging behind the sides
local function Banner(side)
    local t = F:CreateTexture(nil, "BACKGROUND", nil, -8)
    t:SetTexture(ns.TEX("skin_banner"))
    t:SetSize(32, 126)
    if side == "L" then t:SetPoint("TOPRIGHT", F, "TOPLEFT", 14, -34)
    else t:SetPoint("TOPLEFT", F, "TOPRIGHT", -14, -34); t:SetTexCoord(1, 0, 0, 1) end
    return t
end
F.banners={Banner("L"),Banner("R")}

-- dark panel with a soft top light
F.bg = F:CreateTexture(nil, "BACKGROUND", nil, -6)
F.bg:SetPoint("TOPLEFT", 6, -6); F.bg:SetPoint("BOTTOMRIGHT", -6, 6)
ns.Grad(F.bg, "VERTICAL", { 0.045, 0.035, 0.03 }, 0.96, { 0.11, 0.09, 0.07 }, 0.96)
F.border = ns.Slice(F, "skin_frame", 0.25, "BORDER"):Fit(F, 32, 4)

-- horns on the top corners
local function Horn(side)
    local t = F:CreateTexture(nil, "ARTWORK", nil, -2)
    t:SetTexture(ns.TEX("skin_horn"))
    t:SetSize(62, 86)
    if side == "L" then t:SetPoint("BOTTOMRIGHT", F, "TOPLEFT", 27, -52)
    else t:SetPoint("BOTTOMLEFT", F, "TOPRIGHT", -27, -52); t:SetTexCoord(1, 0, 0, 1) end
    return t
end
F.horns={Horn("L"),Horn("R")}

-- header plate with the name
F.plate = F:CreateTexture(nil, "ARTWORK")
F.plate:SetTexture(ns.TEX("skin_header"))
F.plate:SetSize(222, 45)
F.plate:SetPoint("TOP", 0, 21)
F.title = ns.Font(F, "title", 19, GOLDT, "CENTER")
F.title:SetPoint("CENTER", F.plate, "CENTER", 0, -1)
F.title:SetShadowColor(0, 0, 0, 1); F.title:SetShadowOffset(1, -1)
F.title:SetText("Moteve Guide")

-- race medallion on the top left corner
local med = CreateFrame("Frame", nil, F)
med:SetSize(52, 52)
med:SetPoint("CENTER", F, "TOPLEFT", 14, -10)
med:SetFrameLevel(F:GetFrameLevel() + 6)
med.face = med:CreateTexture(nil, "ARTWORK")
med.face:SetSize(35, 35); med.face:SetPoint("CENTER")
pcall(function()
    local mask = med:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(med.face)
    med.face:AddMaskTexture(mask)
end)
med.ring = med:CreateTexture(nil, "OVERLAY")
med.ring:SetTexture(ns.TEX("skin_medal"))
med.ring:SetAllPoints()
local function SetMedal()
    local _, race = UnitRace("player")
    local sex = UnitSex and UnitSex("player") == 3 and "FEMALE" or "MALE"
    local key = race and (race:upper() .. "_" .. sex)
    local tc = RACE_ICON_TCOORDS and key and RACE_ICON_TCOORDS[key]
    if tc then
        med.face:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races")
        med.face:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
    else
        local fac = UnitFactionGroup and UnitFactionGroup("player") or "Horde"
        med.face:SetTexture("Interface\\TargetingFrame\\UI-PVP-" .. (fac == "Alliance" and "Alliance" or "Horde"))
        med.face:SetTexCoord(0.05, 0.62, 0.02, 0.6)
    end
end
ns.SetMedal = SetMedal

-- zone + route + counter
F.zone = ns.Font(F, "title", 15, GOLDT)
F.zone:SetPoint("TOPLEFT", 20, -34)
F.zone:SetPoint("RIGHT", -78, 0)
F.sub = ns.Font(F, "body", 13, GREY)
F.sub:SetPoint("TOPLEFT", F.zone, "BOTTOMLEFT", 0, -3)
F.sub:SetPoint("RIGHT", -100, 0)
F.count = ns.Font(F, "bold", 12, WHITE_T, "RIGHT")
F.count:SetPoint("TOPRIGHT", -16, -60)

-- divider under the header
F.rule = F:CreateTexture(nil, "ARTWORK")
F.rule:SetHeight(1)
F.rule:SetPoint("TOPLEFT", 14, -TOPPAD + 6); F.rule:SetPoint("TOPRIGHT", -14, -TOPPAD + 6)
ns.Grad(F.rule, "HORIZONTAL", { 0.85, 0.66, 0.3 }, 0.15, { 0.85, 0.66, 0.3 }, 0.55)

-- the top area: drag to move, right click = route / zone menu
local hdr = CreateFrame("Button", nil, F)
hdr:SetPoint("TOPLEFT", 0, 20); hdr:SetPoint("TOPRIGHT", 0, 20)
hdr:SetHeight(TOPPAD + 14)
hdr:RegisterForClicks("LeftButtonUp", "RightButtonUp")
hdr:RegisterForDrag("LeftButton")
hdr:SetScript("OnDragStart", function() F:StartMoving() end)
hdr:SetScript("OnDragStop", SavePos)
hdr:SetScript("OnEnter", function(self)
    ns.Tooltip:SetOwner(self, "ANCHOR_TOP")
    ns.Tooltip:AddLine("Moteve Guide", 1, 0.82, 0)
    ns.Tooltip:AddLine("Jobb klikk: útvonal és zóna váltása", 1, 1, 1)
    ns.Tooltip:AddLine("Görgő a listán: előre / vissza lapozás", 0.8, 0.8, 0.8)
    ns.Tooltip:AddLine("Húzd: ablak mozgatása", 0.7, 0.7, 0.7)
    ns.ShowTooltip()
end)
hdr:SetScript("OnLeave", function() ns.Tooltip:Hide() end)

local function SkinBtn(file, size, glyph, flip, fn, tip)
    local b = CreateFrame("Button", nil, F)
    b:SetSize(size, size)
    b:SetFrameLevel(F:GetFrameLevel() + 8)
    b.bg = b:CreateTexture(nil, "ARTWORK"); b.bg:SetAllPoints(); b.bg:SetTexture(ns.TEX(file))
    if glyph then
        b.g = b:CreateTexture(nil, "OVERLAY"); b.g:SetTexture(ns.TEX(glyph))
        b.g:SetSize(size * 0.6, size * 0.6); b.g:SetPoint("CENTER")
        b.g:SetVertexColor(1, 0.85, 0.4)
        if flip then b.g:SetTexCoord(1, 0, 0, 1) end
    end
    b.hl = b:CreateTexture(nil, "HIGHLIGHT"); b.hl:SetAllPoints(); b.hl:SetTexture(ns.TEX(file)); b.hl:SetBlendMode("ADD"); b.hl:SetAlpha(0.35)
    b:SetScript("OnMouseDown", function(self) if self.g then self.g:SetPoint("CENTER", 1, -1) end end)
    b:SetScript("OnMouseUp", function(self) if self.g then self.g:SetPoint("CENTER", 0, 0) end end)
    b:SetScript("OnClick", fn)
    b:SetScript("OnEnter", function(self) ns.Tooltip:SetOwner(self, "ANCHOR_TOP"); ns.Tooltip:SetText(tip); ns.ShowTooltip() end)
    b:SetScript("OnLeave", function() ns.Tooltip:Hide() end)
    return b
end

-- step icons
local ICON = {
    a     = { ns.TEX("skin_excl"), false, 30 },
    t     = { ns.TEX("skin_quest"), false, 30 },
    c     = { ns.TEX("skin_sword"), false, 30 },
    fp    = { "Interface\\TaxiFrame\\UI-Taxi-Icon-Green", false, 24 },
    grind = { "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01", true, 26 },
    go    = { "Interface\\Minimap\\Tracking\\None", false, 24 },
}
local function SetIcon(t, k, scale)
    local i = ICON[k] or ICON.go
    t:SetTexture(i[1])
    if i[2] then t:SetTexCoord(0.08, 0.92, 0.08, 0.92) else t:SetTexCoord(0, 1, 0, 1) end
    local s = floor(i[3] * (scale or 1) + 0.5)
    t:SetSize(s, s)
end

-- the scrolling list
local L = CreateFrame("Frame", nil, F)
L:SetPoint("TOPLEFT", 10, -TOPPAD)
L:SetPoint("TOPRIGHT", -10, -TOPPAD)
L:SetHeight(200)
if L.SetClipsChildren then L:SetClipsChildren(true) end
F:EnableMouseWheel(true)
L.track = L:CreateTexture(nil, "ARTWORK")
L.track:SetWidth(3); L.track:SetPoint("TOPRIGHT", 0, -2); L.track:SetPoint("BOTTOMRIGHT", 0, 2)
L.track:SetColorTexture(0, 0, 0, 0.5)
L.thumb = L:CreateTexture(nil, "OVERLAY")
L.thumb:SetWidth(3)
L.thumb:SetColorTexture(0.85, 0.66, 0.3, 0.8)

local MAXOBJ = 4
local ROW_H, CUR_H, BAR_H = 46, 46, 18
local rows = {}
local function Row(i)
    local r = rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, L)
    r.on = ns.Slice(r, "skin_rowon", 0.25, "BACKGROUND", 1):Fit(r, 10)
    r.onGrad = r:CreateTexture(nil, "BACKGROUND", nil, 2)
    r.onGrad:SetPoint("TOPLEFT", 3, -3); r.onGrad:SetPoint("BOTTOMRIGHT", -3, 3)
    ns.Grad(r.onGrad, "HORIZONTAL", { 0.35, 0.8, 0.2 }, 0.22, { 0.1, 0.25, 0.05 }, 0)
    r.sep = r:CreateTexture(nil, "BACKGROUND", nil, 1)
    r.sep:SetHeight(1); r.sep:SetPoint("BOTTOMLEFT", 4, -1); r.sep:SetPoint("BOTTOMRIGHT", -4, -1)
    ns.Grad(r.sep, "HORIZONTAL", { 0.85, 0.66, 0.3 }, 0.05, { 0.85, 0.66, 0.3 }, 0.22)
    r.hl = r:CreateTexture(nil, "HIGHLIGHT")
    r.hl:SetPoint("TOPLEFT", 2, -2); r.hl:SetPoint("BOTTOMRIGHT", -2, 2)
    ns.Grad(r.hl, "HORIZONTAL", { 1, 0.85, 0.5 }, 0.10, { 1, 0.85, 0.5 }, 0)
    r.box = r:CreateTexture(nil, "ARTWORK", nil, 1)
    r.icon = r:CreateTexture(nil, "ARTWORK", nil, 3)
    r.icon:SetPoint("CENTER", r.box, "CENTER")
    r.l1 = ns.Font(r, "title", 13.5, WHITE_T)
    r.l1:SetPoint("TOPLEFT", r.box, "TOPRIGHT", 9, -2)
    r.l1:SetPoint("RIGHT", -26, 0)
    r.l2 = ns.Font(r, "body", 12.5, GREY)
    r.l2:SetPoint("TOPLEFT", r.l1, "BOTTOMLEFT", 0, -3)
    r.l2:SetPoint("RIGHT", -26, 0)
    r.chev = r:CreateTexture(nil, "ARTWORK")
    r.chev:SetTexture(ns.TEX("skin_chev"))
    r.chev:SetSize(11, 16)
    r.chev:SetVertexColor(0.75, 0.75, 0.75)
    r.bars = {}
    for k = 1, MAXOBJ do
        local b = CreateFrame("StatusBar", nil, r)
        b:SetHeight(14)
        b:SetStatusBarTexture(ns.TEX("skin_bar"))
        b:SetMinMaxValues(0, 1)
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints(); b.bg:SetColorTexture(0, 0, 0, 0.65)
        b.frame = ns.Slice(b, "skin_barframe", 0.25, "OVERLAY"):Fit(b, 6, 2)
        b.name = ns.Font(b, "bold", 12, WHITE_T, "LEFT", "OVERLAY")
        b.name:SetPoint("LEFT", 6, 0); b.name:SetPoint("RIGHT", -46, 0)
        b.num = ns.Font(b, "bold", 12, WHITE_T, "RIGHT", "OVERLAY")
        b.num:SetPoint("RIGHT", -6, 0)
        b:Hide()
        r.bars[k] = b
    end
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r:SetScript("OnClick", function(self, btn)
        if not self.step then return end
        if btn == "RightButton" then   -- right click: mark as done / skip
            char.skip[self.step] = true
            ClearReview()
            Advance(); ns.Refresh()
        else                            -- left click: make it the current step
            if self.step < char.idx or StepDone(self.step) then ReviewStep(self.step)
            else ClearReview(); char.idx = self.step end
            ns.Refresh()
        end
    end)
    r:SetScript("OnEnter", function(self)
        local s = self.step and guide.steps[self.step]
        if not s then return end
        ns.Tooltip:SetOwner(self, "ANCHOR_LEFT")
        ns.Tooltip:AddLine(s.t, 1, 0.82, 0)
        if s.obj then ns.Tooltip:AddLine(s.obj, 1, 1, 1, true) end
        for _, o in ipairs(Objectives(s.q) or {}) do
            local c = o.done and 0.25 or 1
            ns.Tooltip:AddDoubleLine("- " .. o.text, o.have .. "/" .. o.need, 1, 1, 1, c, 1, c)
        end
        if s.npc then ns.Tooltip:AddLine(s.npc, 0.7, 0.85, 1) end
        if s.x then ns.Tooltip:AddLine(format("%.1f, %.1f", s.x, s.y), 0.6, 0.6, 0.6) end
        ns.Tooltip:AddLine(" ")
        ns.Tooltip:AddLine("Bal klikk: ez legyen az aktuális  ·  Jobb klikk: kész / kihagy", 0.55, 0.55, 0.55)
        ns.ShowTooltip()
    end)
    r:SetScript("OnLeave", function() ns.Tooltip:Hide() end)
    rows[i] = r
    return r
end

-- footer: XP/hour, time to level, XP pill with rested part
F.frule = F:CreateTexture(nil, "ARTWORK")
F.frule:SetHeight(1)
F.frule:SetPoint("BOTTOMLEFT", 14, FOOT - 8); F.frule:SetPoint("BOTTOMRIGHT", -14, FOOT - 8)
ns.Grad(F.frule, "HORIZONTAL", { 0.85, 0.66, 0.3 }, 0.55, { 0.85, 0.66, 0.3 }, 0.15)
F.xpIcon = F:CreateTexture(nil, "ARTWORK")
F.xpIcon:SetTexture(ns.TEX("skin_xp")); F.xpIcon:SetSize(24, 24)
F.xpIcon:SetPoint("BOTTOMLEFT", 16, 10)
F.rate = ns.Font(F, "bold", 10.5, WHITE_T)
F.rate:SetPoint("LEFT", F.xpIcon, "RIGHT", 5, 0)
F.rate:SetWidth(88)
F.pipe = ns.Font(F, "body", 12, GREY)
F.pipe:SetPoint("LEFT", F.rate, "RIGHT", 3, 0); F.pipe:SetText("|")
F.barsIcon = F:CreateTexture(nil, "ARTWORK")
F.barsIcon:SetTexture(ns.TEX("skin_bars")); F.barsIcon:SetSize(16, 16)
F.barsIcon:SetPoint("LEFT", F.pipe, "RIGHT", 6, 1)
F.ttl = ns.Font(F, "bold", 10.5, WHITE_T)
F.ttl:SetPoint("LEFT", F.barsIcon, "RIGHT", 4, -1)
F.ttl:SetWidth(100)

local pill = CreateFrame("Frame", nil, F)
pill:SetSize(108, 26)
pill:SetPoint("BOTTOMRIGHT", -14, 9)
pill:EnableMouse(true)
pill.rest = CreateFrame("StatusBar", nil, pill)
pill.rest:SetPoint("TOPLEFT", 5, -5); pill.rest:SetPoint("BOTTOMRIGHT", -5, 5)
pill.rest:SetStatusBarTexture(ns.TEX("skin_bar")); pill.rest:SetStatusBarColor(0.25, 0.5, 1, 0.75)
pill.bar = CreateFrame("StatusBar", nil, pill)
pill.bar:SetAllPoints(pill.rest)
pill.bar:SetStatusBarTexture(ns.TEX("skin_bar")); pill.bar:SetStatusBarColor(0.2, 0.85, 0.12)
pill.bg = pill.rest:CreateTexture(nil, "BACKGROUND"); pill.bg:SetAllPoints(); pill.bg:SetColorTexture(0, 0, 0, 0.7)
local pf = CreateFrame("Frame", nil, pill); pf:SetAllPoints(); pf:SetFrameLevel(pill.bar:GetFrameLevel() + 2)
pill.frame = ns.Slice(pf, "skin_pill", 0.25, "ARTWORK"):Fit(pill, 13)
pill.pct = ns.Font(pf, "bold", 12.5, WHITE_T, "CENTER")
pill.pct:SetPoint("CENTER", 0, 0)
pill.ptr = F:CreateTexture(nil, "ARTWORK")
pill.ptr:SetTexture(ns.TEX("skin_chev")); pill.ptr:SetTexCoord(1, 0, 0, 1)
pill.ptr:SetSize(12, 12); pill.ptr:SetVertexColor(1, 0.8, 0.35)
pill.ptr:SetPoint("RIGHT", pill, "LEFT", -2, 0)
pill:SetScript("OnEnter", function(self)
    local cur, maxv = UnitXP("player") or 0, UnitXPMax("player") or 1
    local rested = GetXPExhaustion and GetXPExhaustion() or 0
    ns.Tooltip:SetOwner(self, "ANCHOR_TOP")
    ns.Tooltip:AddLine(format("XP: %d / %d", cur, maxv), 1, 1, 1)
    if rested > 0 then ns.Tooltip:AddLine(format("Rested: %d (%d%%)", rested, floor(rested / maxv * 100)), 0.5, 0.7, 1) end
    ns.ShowTooltip()
end)
pill:SetScript("OnLeave", function() ns.Tooltip:Hide() end)
F.pill = pill

local QCOL = "|cffffd040"
local function Lines(s)
    local q = s.t and (QCOL .. s.t .. "|r") or ""
    if s.k == "a" then return "Vedd fel: " .. q, (s.npc or "") .. (s.x and format("   %.0f, %.0f", s.x, s.y) or "")
    elseif s.k == "c" then return "Csináld meg: " .. q, s.obj or ""
    elseif s.k == "t" then return "Add le: " .. q, (s.npc or "") .. (s.x and format("   %.0f, %.0f", s.x, s.y) or "")
    elseif s.k == "fp" then return "Repülési pont felvétele", (s.npc or "") .. "  (beszélj a flight masterrel)"
    elseif s.k == "grind" then return s.t, "Utána folytatódik az útvonal"
    elseif s.k == "goto" or s.k == "note" then return s.t or "", s.obj or "Következő lépés: a nyíl gombbal."
    end
    return s.t or "", ""
end

-- one-line progress summary for the other rows: "6/12 · 3/8"
local function ShortProgress(objs)
    local parts, all = {}, true
    for _, o in ipairs(objs) do
        all = all and o.done
        parts[#parts + 1] = (o.done and "|cff6fe05a" or "|cffffd040") .. o.have .. "/" .. o.need .. "|r"
    end
    if #objs > 0 and all then return "|cff6fe05aKész – vidd vissza leadni|r" end
    return table.concat(parts, "  ·  ")
end

---------------------------------------------------------------------------
-- Route / zone menu (right click on the top of the window)
---------------------------------------------------------------------------
local M = CreateFrame("Frame", "MoteveGuideMenu", UIParent)
M:SetFrameStrata("FULLSCREEN_DIALOG")
M:SetClampedToScreen(true)
M:EnableMouse(true)
M:Hide()
M.bg = M:CreateTexture(nil, "BACKGROUND")
M.bg:SetPoint("TOPLEFT", 5, -5); M.bg:SetPoint("BOTTOMRIGHT", -5, 5)
ns.Grad(M.bg, "VERTICAL", { 0.04, 0.03, 0.025 }, 0.97, { 0.1, 0.08, 0.06 }, 0.97)
M.border=ns.Slice(M, "skin_frame", 0.25, "BORDER"):Fit(M, 22, 1)
if UISpecialFrames then table.insert(UISpecialFrames, "MoteveGuideMenu") end
-- click anywhere else closes it
local catcher = CreateFrame("Button", nil, UIParent)
catcher:SetAllPoints(UIParent)
catcher:SetFrameStrata("DIALOG")
catcher:RegisterForClicks("LeftButtonUp", "RightButtonUp")
catcher:SetScript("OnClick", function() M:Hide() end)
catcher:Hide()
M:SetScript("OnHide", function() catcher:Hide() end)

local items = {}
local function Item(i)
    local b = items[i]
    if b then return b end
    b = CreateFrame("Button", nil, M)
    b:SetHeight(20)
    b.hl = b:CreateTexture(nil, "HIGHLIGHT")
    b.hl:SetAllPoints()
    ns.Grad(b.hl, "HORIZONTAL", { 1, 0.8, 0.35 }, 0.22, { 1, 0.8, 0.35 }, 0)
    b.check = b:CreateTexture(nil, "ARTWORK")
    b.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    b.check:SetSize(16, 16); b.check:SetPoint("LEFT", 2, 0)
    b.text = ns.Font(b, "body", 12, WHITE_T)
    b.text:SetPoint("LEFT", 20, 0)
    b.right = ns.Font(b, "body", 11.5, GREY, "RIGHT")
    b.right:SetPoint("RIGHT", -6, 0)
    b:SetScript("OnClick", function(self) M:Hide(); if self.fn then self.fn() end end)
    items[i] = b
    return b
end

local function ZoneList()
    local out = {}
    if not guide then return out end
    for i, s in ipairs(guide.steps) do
        if s.k == "zone" then out[#out + 1] = { i = i, name = s.t, from = s.el or 1 } end
    end
    for k, z in ipairs(out) do z.to = out[k + 1] and out[k + 1].from or 30 end
    return out
end

local function CurrentZoneStep()
    for j = min(char.idx or 1, #guide.steps), 1, -1 do if guide.steps[j].k == "zone" then return j end end
end

local function JumpTo(i, name)
    ClearReview()
    for j = i, #guide.steps do char.skip[j] = nil end
    char.idx = i
    ns.Refresh()
    Print("ugrás: " .. name)
end

local function ShowMenu(page)
    if not guide then return end
    local list = {}
    local choices={}
    for _,g in ipairs(ns.GUIDES or {}) do if ns.GuideAvailable(g) then choices[#choices+1]=g end end
    local pageSize=10
    local pages=max(1,math.ceil(#choices/pageSize))
    if type(page)~="number" then
        page=1
        for i,g in ipairs(choices) do if g.id==guide.id then page=math.ceil(i/pageSize);break end end
    end
    page=max(1,min(pages,page))
    list[#list + 1] = { head = "Útvonalak "..page.." / "..pages }
    if page>1 then list[#list+1]={text="‹ Előző útvonalak",fn=function() ShowMenu(page-1) end} end
    for i=(page-1)*pageSize+1,min(#choices,page*pageSize) do
        local g=choices[i]
        list[#list + 1] = { text = g.name, checked = g.id == guide.id,
            fn = function() SlashCmdList.MOTEVEGUIDE("guide " .. g.id) end }
    end
    if page<pages then list[#list+1]={text="Következő útvonalak ›",fn=function() ShowMenu(page+1) end} end
    list[#list + 1] = { head = "Zóna – ugrás ide" }
    local cz = CurrentZoneStep()
    for _, z in ipairs(ZoneList()) do
        list[#list + 1] = { text = z.name, right = z.from .. "–" .. z.to, checked = z.i == cz,
            fn = function() JumpTo(z.i, z.name) end }
    end
    list[#list + 1] = { head = " " }
    list[#list + 1] = { text = "Újrakezdés a szintemtől", fn = function() SlashCmdList.MOTEVEGUIDE("reset") end }
    list[#list + 1] = { text = "Beállítások", fn = function() if ns.OpenOptions then ns.OpenOptions() end end }

    for _, b in ipairs(items) do b:Hide() end
    local y, wmax = -10, 170
    for k, e in ipairs(list) do
        local b = Item(k)
        b.menuHead=e.head~=nil
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", 8, y); b:SetPoint("RIGHT", -8, 0)
        if e.head then
            ns.SetFontKind(b.text, "title", 13)
            b.text:SetTextColor(GOLDT[1], GOLDT[2], GOLDT[3])
            b.text:SetText(e.head); b.text:SetPoint("LEFT", 4, 0)
            b.right:SetText(""); b.check:Hide(); b.fn = nil
            b:EnableMouse(false)
            b:SetHeight(e.head == " " and 6 or 22)
        else
            ns.SetFontKind(b.text, "body", 12)
            b.text:SetTextColor(WHITE_T[1], WHITE_T[2], WHITE_T[3])
            b.text:SetText(e.text); b.text:SetPoint("LEFT", 22, 0)
            b.right:SetText(e.right or "")
            b.check:SetShown(e.checked and true or false)
            b.fn = e.fn
            b:EnableMouse(true)
            b:SetHeight(20)
        end
        local w = (b.text:GetStringWidth() or 100) + (b.right:GetStringWidth() or 0) + 56
        if w > wmax then wmax = w end
        b:Show()
        y = y - b:GetHeight()
    end
    M:SetSize(wmax + 16, -y + 10)
    local scale = UIParent:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    M:ClearAllPoints()
    M:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", cx / scale - 4, cy / scale + 4)
    if ns.ApplyMenuSkin then ns.ApplyMenuSkin(M,items) end
    catcher:Show()
    M:Show()
end
ns.ShowMenu = ShowMenu

hdr:SetScript("OnClick", function(_, btn) if btn == "RightButton" then if M:IsShown() then M:Hide() else ShowMenu() end end end)

---------------------------------------------------------------------------
-- Arrow
---------------------------------------------------------------------------
local A = CreateFrame("Frame", "MoteveGuideArrow", UIParent)
A:SetSize(90, 104)
A:SetMovable(true); A:EnableMouse(true); A:SetClampedToScreen(true)
A:RegisterForDrag("LeftButton")
A:SetScript("OnDragStart", A.StartMoving)
A:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    db.apoint, db.arelPoint, db.ax, db.ay = p, rp, x, y
end)
A.tex = A:CreateTexture(nil, "ARTWORK")
A.tex:SetTexture(ns.TEX("arrow"))
A.tex:SetSize(64, 64)
A.tex:SetPoint("TOP")
A.ring=A:CreateTexture(nil,"BACKGROUND");A.ring:SetSize(72,72);A.ring:SetPoint("CENTER",A.tex,"CENTER");A.ring:Hide()
A.arrival=A:CreateTexture(nil,"ARTWORK");A.arrival:SetTexture(ns.TEX("nav_arrival"))
A.arrival:SetSize(48,48);A.arrival:SetPoint("CENTER",A.tex,"CENTER");A.arrival:Hide()
A.dist = ns.Font(A, "bold", 17, { 0.97, 0.97, 0.97 }, "CENTER")
A.dist:SetPoint("TOP", A.tex, "BOTTOM", 0, 0)
A.dist:SetShadowColor(0, 0, 0, 1); A.dist:SetShadowOffset(1, -1)
A.what = ns.Font(A, "body", 12, { 0.7, 0.76, 0.86 }, "CENTER")
A.what:SetPoint("TOP", A.dist, "BOTTOM", 0, -2)
A.what:SetShadowColor(0, 0, 0, 1); A.what:SetShadowOffset(1, -1)
A:Hide()

local target   -- { m, x, y }
local function PlayerYards(tm, tx, ty)
    -- the target in yards relative to the player, on the player's current map
    if not (C_Map and C_Map.GetBestMapForUnit) then return end
    local pm = C_Map.GetBestMapForUnit("player")
    if not pm or secret(pm) then return end
    local pos = C_Map.GetPlayerMapPosition(pm, "player")
    if not pos then return end
    local px, py = pos:GetXY()
    if not px or secret(px) then return end
    local x, y = tx / 100, ty / 100
    if tm ~= pm then
        if not (C_Map.GetWorldPosFromMapPos and C_Map.GetMapPosFromWorldPos and CreateVector2D) then return end
        local cont, wpos = C_Map.GetWorldPosFromMapPos(tm, CreateVector2D(x, y))
        if not cont or not wpos then return end
        local _, mp = C_Map.GetMapPosFromWorldPos(cont, wpos, pm)
        if not mp then return end
        x, y = mp:GetXY()
    end
    local w, h = 1, 1
    if C_Map.GetMapWorldSize then w, h = C_Map.GetMapWorldSize(pm) end
    if not w or w == 0 then return end
    return (x - px) * w, (y - py) * h   -- east, south in yards
end

local acc = 0
A:SetScript("OnUpdate", function(self, el)
    acc = acc + el
    if acc < 0.05 then return end
    acc = 0
    if not target then return end
    local ok, east, south = pcall(PlayerYards, target.m, target.x, target.y)
    if not ok or not east then self.dist:SetText("?");ns.UpdateArrowState(self,false);return end
    local d = sqrt(east * east + south * south)
    local okF, facing = pcall(GetPlayerFacing)
    if okF and facing and not secret(facing) then
        local ang = atan2(-east, -south)          -- counterclockwise from north, like the player's facing
        self.tex:SetRotation(ang - facing)
    end
    if d < 8 then
        self.dist:SetText(db.arrowSkin=="original" and "|cff7fe3b0itt vagy|r" or "|cff9fc58bMegérkeztél|r")
    else
        self.dist:SetText(format("%d yd", floor(d + 0.5)))
    end
    ns.UpdateArrowState(self,d<8)
end)

local function SetWaypoint(s)
    if not (db.waypoint and s and s.m and C_Map and C_Map.SetUserWaypoint and UiMapPoint) then return end
    pcall(function()
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(s.m, s.x / 100, s.y / 100))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
    end)
end

---------------------------------------------------------------------------
-- XP / hour
---------------------------------------------------------------------------
local xpStart, xpGained, xpLast, xpLastLevel
local function XPText()
    if not xpStart then return "" end
    local secs = GetTime() - xpStart
    local cur, maxv = UnitXP("player") or 0, UnitXPMax("player") or 1
    local rested = GetXPExhaustion and GetXPExhaustion() or 0
    local parts = {}
    if secs > 120 and xpGained > 0 then
        local rate = xpGained / secs * 3600
        parts[#parts + 1] = format("XP/óra: %.1fk", rate / 1000)
        local left = (maxv - cur) / (rate / 3600)
        if left < 36000 then parts[#parts + 1] = format("szintig ~%d perc", floor(left / 60 + 0.5)) end
    else
        parts[#parts + 1] = "XP/óra: mérés…"
    end
    parts[#parts + 1] = format("%d%%", floor(cur / maxv * 100))
    if rested and rested > 0 then parts[#parts + 1] = format("|cff8fb8ffrested %d%%|r", floor(rested / maxv * 100)) end
    return table.concat(parts, "  ·  ")
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------
-- footer numbers
function ns.UpdateXP()
    local cur, maxv = UnitXP("player") or 0, UnitXPMax("player") or 1
    if maxv < 1 then maxv = 1 end
    local rested = GetXPExhaustion and GetXPExhaustion() or 0
    local secs = xpStart and (GetTime() - xpStart) or 0
    if secs > 120 and xpGained and xpGained > 0 then
        local rate = xpGained / secs * 3600
        F.rate:SetText(format("XP/óra: %.1fk", rate / 1000))
        local left = (maxv - cur) / (rate / 3600)
        F.ttl:SetText(left < 36000 and format("szintig: %d perc", floor(left / 60 + 0.5)) or "szintig: –")
    else
        F.rate:SetText("XP/óra: mérés…")
        F.ttl:SetText("szintig: –")
    end
    pill.bar:SetMinMaxValues(0, maxv); pill.bar:SetValue(cur)
    pill.rest:SetMinMaxValues(0, maxv); pill.rest:SetValue(min(maxv, cur + (rested or 0)))
    pill.pct:SetText(format("%d%%", floor(cur / maxv * 100)))
end

local scroll, lastIdx = 0, nil
local up = {}
F:SetScript("OnMouseWheel", function(_, delta)
    local limit = char and guide and char.idx > #guide.steps and #up or #up - 1
    scroll = max(0, min(limit, scroll - delta))
    ns.Refresh(true)
end)

function ns.Refresh(keepScroll)
    if not guide or not db then return end
    Advance()
    local n = #guide.steps
    local i = char.idx
    local moved = i ~= lastIdx
    lastIdx = i
    local cz = CurrentZoneStep()
    local zs = cz and guide.steps[cz]
    F.zone:SetText(zs and zs.t or guide.name)
    F.sub:SetText(guide.name)
    F.count:SetText(format("%d / %d", min(i, n), n))

    -- Include readable history before the cursor; future completed steps stay hidden.
    up = {}
    local currentOffset = 0
    for j = 1, n do
        local s = guide.steps[j]
        if Actionable(j) and (j < i or j == i or not StepDone(j)) then
            if j < i then currentOffset = currentOffset + 1 end
            up[#up + 1] = j
        end
    end
    if moved then scroll = currentOffset end
    scroll = max(0, min(scroll, i > n and #up or #up - 1))

    local following = max(0, min(8, floor(tonumber(db.lines) or 4)))
    local visible = min(#up - scroll, following + 1)
    local LH = 4
    for k = scroll + 1, scroll + visible do
        local step = guide.steps[up[k]]
        local current = up[k] == i
        local objectives = current and (step.k == "c" or step.k == "t") and Objectives(step.q) or nil
        local bars = objectives and min(#objectives, MAXOBJ) or 0
        LH = LH + (current and CUR_H or ROW_H) + bars * BAR_H + 2
    end
    LH = max(CUR_H + 4, LH)
    L:SetHeight(LH)
    F:SetHeight(TOPPAD + LH + FOOT)
    for _, r in ipairs(rows) do r:Hide() end
    local y, shown = -2, 0
    for k = scroll + 1, #up do
        local j = up[k]
        local s = guide.steps[j]
        local isCur = (j == i)
        local objs = (s.k == "c" or s.k == "t") and Objectives(s.q) or nil
        local nb = (isCur and objs) and min(#objs, MAXOBJ) or 0
        local h = (isCur and CUR_H or ROW_H) + nb * BAR_H
        if shown > 0 and -y + h > LH then break end
        shown = shown + 1
        local r = Row(shown)
        r.step = j
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", 0, y); r:SetPoint("RIGHT", -6, 0)
        r:SetHeight(h)
        local bs = isCur and 44 or 40
        r.box:SetTexture(ns.TEX(isCur and "skin_iconbox_on" or "skin_iconbox"))
        r.box:SetSize(bs, bs)
        r.box:ClearAllPoints(); r.box:SetPoint("TOPLEFT", 6, -(isCur and 5 or 3))
        SetIcon(r.icon, s.k, isCur and 1.08 or 1)
        ns.SetFontKind(r.l1, "title", isCur and 14.5 or 13.5)
        local a, b = Lines(s)
        for _, bar in ipairs(r.bars) do bar:Hide() end
        if objs and #objs > 0 then
            if isCur then
                local by = -(CUR_H - 2)
                local all = true
                for q = 1, nb do
                    local o, bar = objs[q], r.bars[q]
                    bar.skinDone=o.done
                    all = all and o.done
                    bar:ClearAllPoints()
                    bar:SetPoint("TOPLEFT", 60, by); bar:SetPoint("RIGHT", -12, 0)
                    bar:SetValue(min(1, o.have / o.need))
                    if o.done then bar:SetStatusBarColor(0.3, 0.85, 0.2) else bar:SetStatusBarColor(0.95, 0.66, 0.12) end
                    bar.name:SetText(o.text)
                    bar.num:SetText(o.have .. "/" .. o.need)
                    bar:Show()
                    by = by - BAR_H
                end
                for q = nb + 1, #objs do all = all and objs[q].done end
                if all then b = "|cffa8e890Kész – vidd vissza leadni|r" end
            else
                b = ShortProgress(objs)
            end
        end
        r.l1:SetText(a); r.l2:SetText(b)
        r.skinTitle=a
        r.chev:Show()
        r.chev:ClearAllPoints(); r.chev:SetPoint("RIGHT", -8, 0); r.chev:SetPoint("TOP", r.box, "CENTER", 0, 7)
        r.on:SetShown(isCur); r.onGrad:SetShown(isCur)
        r.sep:SetShown(not isCur)
        r.chev:SetVertexColor(isCur and 1 or 0.65, isCur and 1 or 0.65, isCur and 0.55 or 0.65)
        r:Show()
        y = y - h - 2
    end
    if shown == 0 then
        local r = Row(1); r.step = nil
        for _, bar in ipairs(r.bars) do bar:Hide() end
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -2); r:SetPoint("RIGHT", -6, 0); r:SetHeight(CUR_H)
        r.box:SetTexture(ns.TEX("skin_iconbox_on")); r.box:SetSize(44, 44)
        r.box:ClearAllPoints(); r.box:SetPoint("TOPLEFT", 6, -7)
        SetIcon(r.icon, "t", 1.1)
        r.on:Show(); r.onGrad:Show(); r.sep:Hide()
        r.l1:SetText("Az útvonal végére értél!"); r.l2:SetText("Gratula. Új szakaszok hamarosan.")
        r.skinTitle="Az útvonal végére értél!"
        r.chev:Hide()
        r:Show()
    end
    -- scrollbar
    local total = max(1, #up)
    if total > shown and shown > 0 then
        local th = max(16, LH * shown / total)
        L.thumb:SetHeight(th)
        L.thumb:ClearAllPoints()
        L.thumb:SetPoint("TOPRIGHT", 0, -2 - (LH - 4 - th) * min(1, scroll / max(1, total - shown)))
        L.track:Show(); L.thumb:Show()
    else
        L.track:Hide(); L.thumb:Hide()
    end

    for _, o in ipairs({ F.frule, F.xpIcon, F.rate, F.pipe, F.barsIcon, F.ttl, pill, pill.ptr }) do o:SetShown(db.xp) end
    if not db.xp then F:SetHeight(TOPPAD + LH + 12) end
    ns.UpdateXP()
    F:SetShown(db.show)
    -- arrow + waypoint follow the current step (not the scrolled view)
    local cs = guide.steps[i]
    if cs and cs.m and i <= n then
        if not target or target.idx ~= i then
            ns.UpdateArrowState(A,false)
            target = { m = cs.m, x = cs.x, y = cs.y, idx = i }
            SetWaypoint(cs)
        end
        A.what:SetText((Lines(cs)):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
        A:SetShown(db.arrow and db.show)
    else
        target = nil
        A:Hide()
    end
    if ns.ApplyAppearance then ns.ApplyAppearance() end
end

local closeButton=SkinBtn("skin_close", 28, nil, false, function() db.show = false; ns.Refresh() end, "Elrejtés (/mg)")
closeButton:SetPoint("TOPRIGHT",6,8);closeButton.symbol="×"
local nextButton=SkinBtn("skin_navbox", 24, "skin_chev", false, NextStep, "Következő teendő / lépés kihagyása")
nextButton:SetPoint("TOPRIGHT",-14,-30);nextButton.symbol="›"
local prevButton=SkinBtn("skin_navbox", 24, "skin_chev", true, PreviousStep, "Előző lépés megtekintése")
prevButton:SetPoint("TOPRIGHT",-42,-30);prevButton.symbol="‹"
local settingsButton=CreateFrame("Button",nil,F)
settingsButton:SetSize(26,26);settingsButton:SetPoint("TOPRIGHT",-36,-5)
settingsButton:SetFrameLevel(F:GetFrameLevel()+8)
for _,offset in ipairs({4,0,-4}) do
    local line=ns.Tex(settingsButton,"ARTWORK",{0.7,0.73,0.75})
    line:SetSize(12,1);line:SetPoint("CENTER",0,offset)
end
settingsButton:SetScript("OnClick",function() if ns.OpenOptions then ns.OpenOptions() end end)
settingsButton:SetScript("OnEnter",function(self) ns.Tooltip:SetOwner(self,"ANCHOR_TOP");ns.Tooltip:SetText("Megjelenés / beállítások");ns.ShowTooltip() end)
settingsButton:SetScript("OnLeave",function() ns.Tooltip:Hide() end)
settingsButton:Hide()
ns.SetStepIcon=SetIcon
ns.Appearance={frame=F,arrow=A,rows=rows,list=L,header=hdr,medallion=med,
    decor={F.banners[1],F.banners[2],F.horns[1],F.horns[2],F.plate},
    buttons={closeButton,nextButton,prevButton},settings=settingsButton,menu=M,menuItems=items}

---------------------------------------------------------------------------
-- Auto accept / turn-in for the guide's quests (hold Shift to stop it)
---------------------------------------------------------------------------
local guideQuests, guideNames = {}, {}
local function IndexGuide()
    guideQuests, guideNames = {}, {}
    for _, s in ipairs(guide.steps) do
        if s.q and ClassOk(s) then guideQuests[s.q] = true; if s.t then guideNames[s.t] = true end end
    end
end
local function AutoOn() return db.autoQuest and not IsShiftKeyDown() end

local Q = CreateFrame("Frame")
for _, e in ipairs({ "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "GOSSIP_SHOW", "QUEST_GREETING" }) do pcall(Q.RegisterEvent, Q, e) end
Q:SetScript("OnEvent", function(_, e)
    if not guide or not AutoOn() then return end
    local qid = GetQuestID and GetQuestID()
    if e == "QUEST_DETAIL" then
        if qid and guideQuests[qid] then AcceptQuest() end
    elseif e == "QUEST_PROGRESS" then
        if qid and guideQuests[qid] and IsQuestCompletable() then CompleteQuest() end
    elseif e == "QUEST_COMPLETE" then
        if qid and guideQuests[qid] then
            local n = GetNumQuestChoices and GetNumQuestChoices() or 0
            if n <= 1 then GetQuestReward(n) end   -- with a real choice, you pick
        end
    elseif e == "GOSSIP_SHOW" and C_GossipInfo then
        for _, q in ipairs(C_GossipInfo.GetActiveQuests() or {}) do
            if q.isComplete and guideQuests[q.questID] then C_GossipInfo.SelectActiveQuest(q.questID); return end
        end
        for _, q in ipairs(C_GossipInfo.GetAvailableQuests() or {}) do
            if guideQuests[q.questID] then C_GossipInfo.SelectAvailableQuest(q.questID); return end
        end
    elseif e == "QUEST_GREETING" then
        for i = 1, (GetNumActiveQuests and GetNumActiveQuests() or 0) do
            local title, done = GetActiveTitle(i)
            if done and guideNames[title] then SelectActiveQuest(i); return end
        end
        for i = 1, (GetNumAvailableQuests and GetNumAvailableQuests() or 0) do
            if guideNames[GetAvailableTitle(i)] then SelectAvailableQuest(i); return end
        end
    end
end)

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_TURNED_IN",
                     "QUEST_REMOVED", "PLAYER_LEVEL_UP", "PLAYER_XP_UPDATE", "TAXIMAP_OPENED", "ZONE_CHANGED_NEW_AREA" }) do
    pcall(ev.RegisterEvent, ev, e)
end
local pending = false
local function Soon()
    if pending then return end
    pending = true
    C_Timer.After(0.3, function() pending = false; logDirty = true; ns.Refresh() end)
end
ev:SetScript("OnEvent", function(_, e, a1)
    if e == "ADDON_LOADED" then
        if a1 ~= ADDON_NAME then return end
        MoteveGuideDB = MoteveGuideDB or {}
        MoteveGuideChar = MoteveGuideChar or {}
        for k, v in pairs(DEFAULTS) do if MoteveGuideDB[k] == nil then MoteveGuideDB[k] = v end end
        db, char = MoteveGuideDB, MoteveGuideChar
        char.skip = char.skip or {}
        char.fp = char.fp or {}
        ns.db, ns.char = db, char
        if ns.ValidateAppearance then ns.ValidateAppearance() end
        return
    end
    if not db then return end
    if e == "PLAYER_LOGIN" then
        ClearReview()
        guide = GuideById(char.guide) or GuideForRace()
        if not guide then Print("nincs útvonal ehhez a karakterhez."); return end
        char.guide = guide.id
        MigrateSteps()
        ns.guide = guide
        IndexGuide()
        F:SetScale(db.scale)
        F:ClearAllPoints(); F:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
        A:ClearAllPoints(); A:SetPoint(db.apoint, UIParent, db.arelPoint, db.ax, db.ay)
        logDirty = true
        if not char.idx then char.idx = FindStart() end
        xpStart, xpGained, xpLast, xpLastLevel = GetTime(), 0, UnitXP("player"), UnitLevel("player")
        ns.Refresh()
        SetMedal()
        C_Timer.NewTicker(5, function() if F:IsShown() and ns.UpdateXP then ns.UpdateXP() end end)
    elseif e == "PLAYER_XP_UPDATE" then
        local cur, lv = UnitXP("player"), UnitLevel("player")
        if xpLast then
            if lv == xpLastLevel then xpGained = xpGained + max(0, cur - xpLast)
            else xpGained = xpGained + cur end   -- level up: count what spilled over
        end
        xpLast, xpLastLevel = cur, lv
        Soon()
    elseif e == "TAXIMAP_OPENED" then
        -- the flight path of the current (or a nearby) fp step is now known
        local s = guide and guide.steps[char.idx]
        if s and s.k == "fp" then char.fp[s.npc or s.t] = true end
        Soon()
    else
        Soon()
    end
end)

---------------------------------------------------------------------------
-- Slash
---------------------------------------------------------------------------
SLASH_MOTEVEGUIDE1, SLASH_MOTEVEGUIDE2 = "/mg", "/mguide"
SlashCmdList.MOTEVEGUIDE = function(input)
    local cmd, arg = (input or ""):match("^(%S*)%s*(.-)%s*$")
    cmd = cmd:lower()
    if cmd == "" then
        db.show = not db.show; ns.Refresh()
    elseif cmd == "next" or cmd == "kovetkezo" then
        NextStep()
    elseif cmd == "prev" or cmd == "vissza" then
        PreviousStep()
    elseif cmd == "reset" then
        ClearReview()
        char.skip, char.fp = {}, {}; char.idx = FindStart(); ns.Refresh()
        Print("útvonal újrakezdve a jelenlegi szintedtől.")
    elseif cmd == "guide" or cmd == "utvonal" then
        local g = GuideById(arg)
        if g and ns.GuideAvailable(g) then
            ClearReview()
            char.guide, guide, ns.guide = g.id, g, g; char.skip = {}; IndexGuide(); char.idx = FindStart(); ns.Refresh()
            Print("útvonal: " .. g.name)
        else
            if g and not ns.GuideAvailable(g) then Print("Ez az útvonal a másik frakcióhoz tartozik."); return end
            local names = {}
            for _, x in ipairs(ns.GUIDES) do if ns.GuideAvailable(x) then names[#names + 1] = x.id .. " (" .. x.name .. ")" end end
            Print("útvonalak: " .. table.concat(names, ", ") .. "   pl. /mg guide undead")
        end
    elseif cmd == "arrow" or cmd == "nyil" then
        db.arrow = not db.arrow; ns.Refresh()
    elseif cmd == "auto" then
        db.autoQuest = not db.autoQuest; Print("automatikus felvétel/leadás: " .. (db.autoQuest and "be" or "ki"))
    elseif cmd == "scale" or cmd == "meret" then
        local percent = tonumber(arg)
        if percent and percent == percent then
            ns.SetWindowScale(percent / 100)
            Print(format("ablakméret: %d%%", floor(db.scale * 100 + 0.5)))
        else
            Print("méret: /mg scale 70   (55–130%)")
        end
    elseif cmd == "opciok" or cmd == "options" then
        if ns.OpenOptions then ns.OpenOptions() end
    else
        Print("/mg  ablak ki/be  ·  /mg next | prev  ·  /mg reset  ·  /mg guide <név>  ·  /mg nyil  ·  /mg auto  ·  /mg scale 70  ·  /mg opciok")
    end
end
