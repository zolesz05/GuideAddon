-- Lua tests for Moteve Guide with WoW API stubs. Needs lua5.1 or luajit; run from the repo root:
--   lua5.1 tests/lua/run.lua [tests/lua/test_x.lua ...]
-- H.Load() loads the files of MoteveGuide.toc in their order, as the client does, then fires
-- ADDON_LOADED and PLAYER_LOGIN for a character described by the options.
local ADDON = "MoteveGuide"
local TESTS = { "tests/lua/test_guide.lua", "tests/lua/test_rxp_routes.lua" }

local H = {}

-- Frames and other UI objects: every field is a stub and every method returns one, except the
-- few the addon reads back.
local Stub
local StubMT = {}
StubMT.__index = function(_, k)
    if k == "SetScript" then return function(self, what, fn) self.scripts[what] = fn end end
    if k == "HookScript" then return function(self, what, fn) self.scripts[what] = self.scripts[what] or fn end end
    if k == "GetScript" then return function(self, what) return self.scripts[what] end end
    if k == "RegisterEvent" then return function(self, e) self.events[e] = true end end
    if k == "IsShown" or k == "IsVisible" or k == "IsMouseOver" then return function() return false end end
    if k == "GetPoint" then return function() return "CENTER", nil, "CENTER", 0, 0 end end
    if k == "GetStringWidth" or k == "GetStringHeight" or k == "GetWidth" or k == "GetHeight" or k == "GetLeft"
        or k == "GetTop" or k == "GetRight" or k == "GetBottom" or k == "GetFrameLevel" or k == "GetEffectiveScale"
        or k == "GetScale" or k == "GetNumLines" or k == "GetVerticalScroll" or k == "GetVerticalScrollRange"
        or k == "GetAlpha" then
        return function() return 1 end
    end
    if k == "GetText" then return function() return "" end end
    if k == "GetSize" then return function() return 1, 1 end end
    if k == "GetCenter" then return function() return 0, 0 end end
    return Stub()   -- callable as a method, indexable as a field
end
StubMT.__call = function() return Stub() end
local frames
function Stub()
    local s = setmetatable({ scripts = {}, events = {} }, StubMT)
    frames[#frames + 1] = s
    return s
end

local function band(a, b)
    local r, v = 0, 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then r = r + v end
        a, b, v = math.floor(a / 2), math.floor(b / 2), v * 2
    end
    return r
end

-- opts: race ("Tauren"), class ("WARRIOR"), faction, level, char (saved MoteveGuideChar),
-- quests = { [id] = { log = true, complete = false, done = false, objectives = { {finished = true}, ... } } },
-- setup = function(ns) called after the TOC files load, before the events.
function H.Load(opts)
    opts = opts or {}
    frames = {}
    local quests = opts.quests or {}
    local race = opts.race or "Tauren"
    local raceFile = race:gsub(" ", "")
    if raceFile == "Undead" then raceFile = "Scourge" end
    local stubs = {
        bit = { band = band },
        UnitRace = function() return race, raceFile end,
        UnitClass = function() local c = opts.class or "WARRIOR"; return c:sub(1, 1) .. c:sub(2):lower(), c end,
        UnitFactionGroup = function() return opts.faction or "Horde" end,
        UnitLevel = function() return opts.level or 1 end,
        UnitXP = function() return 0 end,
        UnitXPMax = function() return 400 end,
        UnitSex = function() return 2 end,
        GetXPExhaustion = function() return 0 end,
        GetTime = function() return 0 end,
        GetLocale = function() return "enUS" end,
        IsShiftKeyDown = function() return false end,
        InCombatLockdown = function() return false end,
        C_Timer = { After = function() end, NewTicker = function() return Stub() end },
        C_Map = {},
        C_QuestLog = {
            GetNumQuestLogEntries = function()
                local n = 0
                for _, q in pairs(quests) do if q.log then n = n + 1 end end
                return n
            end,
            GetInfo = function(i)
                local ids = {}
                for id, q in pairs(quests) do if q.log then ids[#ids + 1] = id end end
                table.sort(ids)
                return ids[i] and { questID = ids[i], isHeader = false, isComplete = quests[ids[i]].complete }
            end,
            IsComplete = function(id) return quests[id] and quests[id].complete or false end,
            IsQuestFlaggedCompleted = function(id) return quests[id] and quests[id].done or false end,
            GetQuestObjectives = function(id) return quests[id] and quests[id].objectives or {} end,
        },
        CreateFrame = function(_, name)
            local f = Stub()
            if name then rawset(_G, name, f) end
            return f
        end,
        SlashCmdList = {},
    }
    -- anything else the UI code touches at load is a stub
    setmetatable(_G, { __index = function(_, k)
        if type(k) == "string" and k:match("^[A-Z]") and not k:match("^MoteveGuide") then return Stub() end
    end })
    for k, v in pairs(stubs) do rawset(_G, k, v) end
    rawset(_G, "MoteveGuideDB", opts.db)
    rawset(_G, "MoteveGuideChar", opts.char)

    local ns = {}
    local toc = assert(io.open(ADDON .. "/" .. ADDON .. ".toc")):read("*a")
    for line in toc:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and not line:match("^#") then
            assert(loadfile(ADDON .. "/" .. line:gsub("\\", "/")))(ADDON, ns)
        end
    end
    if opts.setup then opts.setup(ns) end
    H.Fire("ADDON_LOADED", ADDON)
    H.Fire("PLAYER_LOGIN")
    return ns
end

function H.Fire(e, ...)
    local list = {}
    for _, f in ipairs(frames) do list[#list + 1] = f end
    for _, f in ipairs(list) do
        if f.events[e] and f.scripts.OnEvent then f.scripts.OnEvent(f, e, ...) end
    end
end

function H.GuideById(ns, id)
    for _, g in ipairs(ns.GUIDES) do if g.id == id then return g end end
end

function H.eq(a, b, msg)
    if a ~= b then error((msg or "values differ") .. ": expected " .. tostring(b) .. ", got " .. tostring(a), 2) end
end

function H.ok(v, msg)
    if not v then error(msg or "expected a true value", 2) end
end

local files = #arg > 0 and arg or TESTS
local failed, passed = 0, 0
for _, file in ipairs(files) do
    local tests = assert(loadfile(file))(H)
    local names = {}
    for name in pairs(tests) do names[#names + 1] = name end
    table.sort(names)
    for _, name in ipairs(names) do
        local ok, err = pcall(tests[name])
        if ok then passed = passed + 1
        else failed = failed + 1; print("FAIL " .. file .. ": " .. name .. "\n    " .. tostring(err)) end
    end
end
print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
