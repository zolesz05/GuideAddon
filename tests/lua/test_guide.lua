-- Guide.lua: default route choice and step completion.
local H = ...
local T = {}

local function AddGuide(g) return function(ns) table.insert(ns.GUIDES, 1, g) end end

function T.tauren_route_without_classes_still_matches_by_race()
    local ns = H.Load({ race = "Tauren", setup = function(ns)
        for i = #ns.GUIDES, 1, -1 do if ns.GUIDES[i].id:match("_rxp$") then table.remove(ns.GUIDES, i) end end
    end })
    H.eq(ns.guide.id, "tauren")
end

function T.class_route_is_chosen_before_a_race_only_route()
    local mage = { id = "test_mage", name = "t", races = { TAUREN = true }, classes = { MAGE = true }, steps = { { k = "zone", t = "x" } } }
    local plain = { id = "test_plain", name = "t", races = { TAUREN = true }, steps = { { k = "zone", t = "x" } } }
    local setup = function(ns) table.insert(ns.GUIDES, 1, mage); table.insert(ns.GUIDES, 1, plain) end
    H.eq(H.Load({ race = "Tauren", class = "MAGE", setup = setup }).guide.id, "test_mage")
    H.eq(H.Load({ race = "Tauren", class = "WARRIOR", setup = setup }).guide.id, "test_plain")
end

function T.class_route_for_another_race_is_not_chosen()
    local mage = { id = "test_mage", name = "t", races = { HUMAN = true }, classes = { MAGE = true }, steps = { { k = "zone", t = "x" } } }
    local ns = H.Load({ race = "Tauren", class = "MAGE", setup = AddGuide(mage) })
    H.ok(ns.guide.id ~= "test_mage", "a Human Mage route for a Tauren Mage")
end

local OI = { id = "test_oi", name = "t", races = {}, steps = {
    { k = "c", q = 100, oi = 1, t = "Q" },
    { k = "c", q = 100, oi = 2, t = "Q" },
    { k = "c", q = 100, t = "Q" },
    { k = "t", q = 100, t = "Q" },
} }

function T.objective_step_is_done_when_its_objective_is_finished()
    local ns = H.Load({ char = { guide = "test_oi" }, setup = AddGuide(OI), quests = {
        [100] = { log = true, complete = false, objectives = { { text = "a", finished = true }, { text = "b", finished = false } } },
    } })
    H.ok(ns.StepDone(1), "objective 1 is finished")
    H.ok(not ns.StepDone(2), "objective 2 is not finished")
    H.ok(not ns.StepDone(3), "a step without oi waits for the whole quest")
    H.eq(ns.char.idx, 2, "the route starts at the first unfinished objective")
end

function T.objective_step_is_done_when_the_whole_quest_is()
    local ns = H.Load({ char = { guide = "test_oi" }, setup = AddGuide(OI), quests = {
        [100] = { log = true, complete = true, objectives = { { text = "a", finished = false }, { text = "b", finished = false } } },
    } })
    H.ok(ns.StepDone(1)); H.ok(ns.StepDone(2)); H.ok(ns.StepDone(3))
end

function T.objective_step_is_not_done_without_the_quest()
    local ns = H.Load({ char = { guide = "test_oi" }, setup = AddGuide(OI), quests = {} })
    H.ok(not ns.StepDone(1))
end

local XP = { id = "test_xp", name = "t", races = {}, steps = {
    { k = "grind", t = "g", lv = 3, xp = 1150 },
    { k = "grind", t = "g", lv = 3, xp = -40 },
    { k = "grind", t = "g", lv = 3, xp = 0.75 },
    { k = "grind", t = "g", lv = 3 },
} }

local function GrindDone(level, xp)
    local ns = H.Load({ char = { guide = "test_xp" }, setup = AddGuide(XP), level = level, xp = xp, xpMax = 1400 })
    return { ns.StepDone(1), ns.StepDone(2), ns.StepDone(3), ns.StepDone(4) }
end

function T.grind_step_waits_for_the_xp_into_its_level()
    local d = GrindDone(3, 1000)
    H.ok(not d[1], "1000 < 1150 xp"); H.ok(not d[2], "1000 < 1400-40 xp"); H.ok(not d[3], "1000 < 75% of 1400")
    H.ok(d[4], "a plain grind is done at the level")
    d = GrindDone(3, 1360)
    H.ok(d[1]); H.ok(d[2]); H.ok(d[3])
    d = GrindDone(2, 1399)
    H.ok(not d[1] and not d[2] and not d[3] and not d[4], "below the level")
    d = GrindDone(4, 0)
    H.ok(d[1] and d[2] and d[3] and d[4], "past the level")
end

return T
