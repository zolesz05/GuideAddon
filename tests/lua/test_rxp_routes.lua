-- RXPRoutes.lua: the RestedXP routes, their defaults and the continuation with the old routes.
local H = ...
local T = {}

local RXP = { "tauren_rxp", "orctroll_rxp", "undead_rxp", "human_rxp", "dwarfgnome_rxp", "nightelf_rxp",
              "mage_h_rxp", "mage_a_rxp", "mage_aoe_a_rxp" }
local HORDE = { Tauren = true, Orc = true, Troll = true, Undead = true }

local function Default(race, class)
    return H.Load({ race = race, class = class or "WARRIOR", faction = HORDE[race] and "Horde" or "Alliance" }).guide.id
end

function T.new_characters_get_their_race_route()
    local want = { Tauren = "tauren_rxp", Orc = "orctroll_rxp", Troll = "orctroll_rxp", Undead = "undead_rxp",
                   Human = "human_rxp", Dwarf = "dwarfgnome_rxp", Gnome = "dwarfgnome_rxp", ["Night Elf"] = "nightelf_rxp" }
    for race, id in pairs(want) do
        for _, class in ipairs({ "WARRIOR", "HUNTER", "PRIEST" }) do H.eq(Default(race, class), id, race .. " " .. class) end
    end
end

function T.mages_get_their_faction_mage_route()
    for _, race in ipairs({ "Troll", "Undead", "Orc", "Tauren" }) do H.eq(Default(race, "MAGE"), "mage_h_rxp", race) end
    for _, race in ipairs({ "Human", "Gnome" }) do H.eq(Default(race, "MAGE"), "mage_a_rxp", race) end
end

function T.saved_route_and_index_stay()
    local ns = H.Load({ race = "Tauren", char = { guide = "tauren", idx = 57, skip = { [3] = true } } })
    H.eq(ns.char.guide, "tauren")
    H.eq(ns.char.idx, 57)
    H.eq(ns.guide.id, "tauren")
    H.ok(ns.char.skip[3])
end

function T.new_routes_have_a_faction_and_hide_from_the_other()
    local ns = H.Load({ race = "Human", faction = "Alliance" })
    for _, id in ipairs(RXP) do
        local g = H.GuideById(ns, id)
        H.ok(g, id .. " is registered")
        H.ok(g.faction == "Horde" or g.faction == "Alliance", id .. " has a faction")
        H.eq(ns.GuideAvailable(g), g.faction == "Alliance", id)
    end
    ns = H.Load({ race = "Tauren", faction = "Horde" })
    for _, id in ipairs(RXP) do
        local g = H.GuideById(ns, id)
        H.eq(ns.GuideAvailable(g), g.faction == "Horde", id)
    end
end

function T.new_routes_come_first()
    local ns = H.Load()
    for i, id in ipairs(RXP) do H.eq(ns.GUIDES[i].id, id) end
end

-- the continuation shares the step tables of the old route, which tells the two parts apart
local function Parts(ns, g)
    local old = {}
    for _, s in ipairs(H.GuideById(ns, g.base).steps) do old[s] = true end
    local rxp, tail = {}, {}
    for _, s in ipairs(g.steps) do
        if old[s] then tail[#tail + 1] = s else H.eq(#tail, 0, g.id .. ": RXP step after the seam"); rxp[#rxp + 1] = s end
    end
    return rxp, tail
end

function T.routes_continue_with_the_old_route_without_repeating_turn_ins()
    local ns = H.Load()
    for _, id in ipairs(RXP) do
        local g = H.GuideById(ns, id)
        local rxp, tail = Parts(ns, g)
        H.ok(#rxp > 100, id .. " has RXP steps")
        H.ok(#tail > 50, id .. " continues with " .. g.base)
        H.eq(tail[1].k, "zone", id .. " continues at a zone")
        local turnedIn = {}
        for _, s in ipairs(rxp) do if s.k == "t" then turnedIn[s.q] = true end end
        for _, s in ipairs(tail) do
            H.ok(not (s.k == "t" and turnedIn[s.q]), id .. ": quest " .. tostring(s.q) .. " turned in twice")
            H.ok(not (s.q and turnedIn[s.q]), id .. ": quest " .. tostring(s.q) .. " repeated after the seam")
        end
    end
end

function T.horde_routes_continue_at_level_22()
    local ns = H.Load()
    for _, id in ipairs({ "tauren_rxp", "orctroll_rxp", "undead_rxp" }) do
        local _, tail = Parts(ns, H.GuideById(ns, id))
        H.eq(tail[1].el, 22, id)
    end
end

function T.tauren_route_has_no_mulgore_flight_path()
    local ns = H.Load()
    for _, s in ipairs(H.GuideById(ns, "tauren_rxp").steps) do
        H.ok(not (s.k == "fp" and s.m == 1412), "fp step in Mulgore: " .. tostring(s.t))
    end
end

function T.mage_routes_are_for_mages()
    local ns = H.Load()
    for _, id in ipairs({ "mage_h_rxp", "mage_a_rxp", "mage_aoe_a_rxp" }) do
        local g = H.GuideById(ns, id)
        H.ok(g.classes and g.classes.MAGE, id)
        local rxp = Parts(ns, g)
        for _, s in ipairs(rxp) do H.ok(not s.cls or s.cls % 256 >= 128, id .. ": step for another class") end
    end
end

function T.a_new_tauren_starts_on_the_first_step()
    local ns = H.Load({ race = "Tauren" })
    local s = ns.guide.steps[ns.char.idx]
    H.eq(s.k, "a"); H.eq(s.q, 747)
end

return T
