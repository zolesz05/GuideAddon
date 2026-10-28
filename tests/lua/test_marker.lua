-- Marker.lua: raid marks on the current step's NPC (star) and mobs (skull), only when alone.
local H = ...
local T = {}

local MARK = { id = "test_mark", name = "t", races = {}, steps = {
    { k = "a", q = 1, t = "A", npc = "Grull Hawkwind" },               -- 1
    { k = "c", q = 1, oi = 1, t = "A", mob = { "Plainstrider", "Adult Plainstrider" } }, -- 2
    { k = "t", q = 1, t = "A", npc = "Grull Hawkwind" },               -- 3
    { k = "a", q = 2, t = "B", npc = "Grull Hawkwind" },               -- 4
    { k = "fp", t = "Repülési pont: Camp Taurajo", npc = "Omusa Thunderhorn" }, -- 5
    { k = "note", t = "Beszélj vele", npc = "Zarlman Two-Moons" },     -- 6
    { k = "note", t = "Menj", m = 1412, x = 1, y = 1 },                -- 7
    { k = "c", q = 2, t = "B", obj = "o" },                            -- 8
    { k = "grind", t = "g", lv = 60 },                                 -- 9
    { k = "t", q = 2, t = "B", npc = "Grull Hawkwind" },               -- 10
} }
local OTHER = { id = "test_mark2", name = "t", races = {}, steps = { { k = "a", q = 3, t = "C", npc = "Baine" } } }

local function Load(idx, opts)
    opts = opts or {}
    opts.char = { guide = "test_mark", idx = idx }
    opts.quests = opts.quests or {}
    opts.setup = function(ns) table.insert(ns.GUIDES, 1, MARK); table.insert(ns.GUIDES, 1, OTHER) end
    local ns = H.Load(opts)
    H.eq(ns.char.idx, idx, "current step")
    return ns, opts.units, opts
end

local function Marks()
    local out = {}
    for _, m in ipairs(H.marks) do out[#out + 1] = m[1] .. "=" .. m[2] end
    return table.concat(out, " ")
end

local function Grull(guid) return { guid = guid or "npc1", name = "Grull Hawkwind", friend = true } end
local function Boar(guid, extra)
    local u = { guid = guid, name = "Plainstrider" }
    for k, v in pairs(extra or {}) do u[k] = v end
    return u
end

function T.accept_npc_on_a_nameplate_gets_a_star()
    local _, units = Load(1, { units = { nameplate3 = Grull() } })
    H.eq(Marks(), "nameplate3=1")
    H.eq(units.nameplate3.icon, 1)
end

function T.npc_name_matches_without_case()
    Load(1, { units = { nameplate1 = { guid = "npc1", name = "grull HAWKWIND", friend = true } } })
    H.eq(Marks(), "nameplate1=1")
end

function T.turnin_fp_and_note_npcs_get_a_star()
    Load(3, { units = { nameplate1 = Grull() } })
    H.eq(Marks(), "nameplate1=1")
    Load(5, { units = { nameplate1 = { guid = "npc2", name = "Omusa Thunderhorn", friend = true } } })
    H.eq(Marks(), "nameplate1=1")
    Load(6, { units = { nameplate1 = { guid = "npc3", name = "Zarlman Two-Moons", friend = true } } })
    H.eq(Marks(), "nameplate1=1")
end

function T.other_units_get_no_star()
    Load(1, { units = { nameplate1 = { guid = "npc9", name = "Someone Else", friend = true },
                        nameplate2 = { guid = "p1", name = "Grull Hawkwind", player = true } } })
    H.eq(Marks(), "")
end

function T.mouseover_and_target_are_marked_without_nameplates()
    local _, units = Load(1)
    H.eq(Marks(), "")
    units.mouseover = Grull()
    H.Fire("UPDATE_MOUSEOVER_UNIT")
    H.eq(Marks(), "mouseover=1")

    _, units = Load(1)
    units.target = Grull()
    H.Fire("PLAYER_TARGET_CHANGED")
    H.eq(Marks(), "target=1")
end

function T.nameplate_event_marks_a_new_nameplate()
    local _, units = Load(2)
    units.nameplate7 = Boar("m1")
    H.Fire("NAME_PLATE_UNIT_ADDED", "nameplate7")
    H.eq(Marks(), "nameplate7=8")
end

function T.complete_step_skulls_a_living_attackable_mob()
    local _, units = Load(2, { units = {
        nameplate1 = Boar("m1", { dead = true }),
        nameplate2 = Boar("m2", { friend = true }),
        nameplate3 = { guid = "m3", name = "Adult Plainstrider" },
    } })
    H.eq(Marks(), "nameplate3=8")
    H.eq(units.nameplate1.icon, nil); H.eq(units.nameplate2.icon, nil)
end

function T.dead_or_friendly_mobs_get_no_skull()
    Load(2, { units = { nameplate1 = Boar("m1", { dead = true }), nameplate2 = Boar("m2", { friend = true }) } })
    H.eq(Marks(), "")
end

function T.skull_moves_to_another_living_mob_when_its_mob_dies()
    local ns, units = Load(2, { units = { nameplate1 = Boar("m1") } })
    H.eq(Marks(), "nameplate1=8")
    units.nameplate1.dead = true
    ns.UpdateMarks()
    H.eq(Marks(), "nameplate1=8", "no other living mob: no call")
    units.nameplate2 = Boar("m2")
    ns.UpdateMarks()
    H.eq(Marks(), "nameplate1=8 nameplate2=8")
    H.eq(units.nameplate2.icon, 8); H.eq(units.nameplate1.icon, nil)
end

function T.living_skulled_mob_keeps_the_skull()
    local ns, units = Load(2, { units = { nameplate1 = Boar("m1") } })
    units.nameplate2 = Boar("m2")
    ns.UpdateMarks(); ns.UpdateMarks()
    H.eq(Marks(), "nameplate1=8")
end

function T.no_marks_in_a_group_or_raid()
    Load(1, { group = true, units = { nameplate1 = Grull() } })
    H.eq(Marks(), "")
    Load(2, { raid = true, units = { nameplate1 = Boar("m1") } })
    H.eq(Marks(), "")
end

function T.joining_a_group_takes_our_marks_off()
    local ns, units, opts = Load(1, { units = { nameplate1 = Grull() } })
    opts.group = true
    H.Fire("GROUP_ROSTER_UPDATE")
    H.eq(Marks(), "nameplate1=1 nameplate1=0")
    H.eq(units.nameplate1.icon, nil)
    units.nameplate2 = Grull("npc2")
    ns.UpdateMarks(); ns.Refresh()
    H.eq(Marks(), "nameplate1=1 nameplate1=0", "nothing more in the group")
end

function T.a_marked_unit_is_left_alone()
    local _, units = Load(1, { units = { target = { guid = "npc1", name = "Grull Hawkwind", friend = true, icon = 3 } } })
    H.eq(Marks(), "")
    H.eq(units.target.icon, 3)
end

function T.the_icon_on_another_visible_unit_is_not_taken()
    local ns, units = Load(1, { units = { nameplate1 = { guid = "x1", name = "Kodo", icon = 1 }, nameplate2 = Grull() } })
    H.eq(Marks(), "")
    ns.UpdateMarks()
    H.eq(Marks(), "")
    H.eq(units.nameplate1.icon, 1)
end

function T.foreign_marks_are_never_taken_off()
    local ns, units = Load(1, { units = { nameplate1 = Grull(), nameplate2 = Boar("m1", { icon = 8 }) } })
    H.eq(Marks(), "nameplate1=1")
    -- the player moves the star to another unit: it is no longer ours
    units.nameplate3 = { guid = "x1", name = "Kodo" }
    units.nameplate1.icon, units.nameplate3.icon = nil, 1
    ns.char.idx = 2; ns.Refresh()
    ns.db.markTargets = false; ns.Refresh()
    H.Fire("GROUP_ROSTER_UPDATE")
    H.eq(Marks(), "nameplate1=1")
    H.eq(units.nameplate2.icon, 8); H.eq(units.nameplate3.icon, 1)
end

function T.next_step_takes_the_star_off_and_skulls_the_mob()
    local ns, units = Load(1, { units = { nameplate1 = Grull(), nameplate2 = Boar("m1") } })
    H.eq(Marks(), "nameplate1=1", "the next step's mob is not marked ahead")
    SlashCmdList.MOTEVEGUIDE("next")
    H.eq(ns.char.idx, 2)
    H.eq(Marks(), "nameplate1=1 nameplate1=0 nameplate2=8")
    H.eq(units.nameplate1.icon, nil)
end

function T.prev_step_takes_the_skull_off_and_stars_the_npc()
    local ns, units = Load(2, { units = { nameplate1 = Grull(), nameplate2 = Boar("m1") } })
    H.eq(Marks(), "nameplate2=8")
    SlashCmdList.MOTEVEGUIDE("prev")
    H.eq(ns.char.idx, 1)
    H.eq(Marks(), "nameplate2=8 nameplate2=0 nameplate1=1")
    H.eq(units.nameplate2.icon, nil)
end

function T.route_switch_takes_our_mark_off()
    local ns, units = Load(1, { units = { nameplate1 = Grull(), nameplate2 = { guid = "npc5", name = "Baine", friend = true } } })
    SlashCmdList.MOTEVEGUIDE("guide test_mark2")
    H.eq(ns.guide.id, "test_mark2")
    H.eq(Marks(), "nameplate1=1 nameplate1=0 nameplate2=1")
    H.eq(units.nameplate1.icon, nil)
end

function T.auto_advance_takes_the_mark_off()
    local quests = {}
    local ns, units = Load(2, { quests = quests, units = { nameplate1 = Boar("m1"), nameplate2 = Grull() } })
    H.eq(Marks(), "nameplate1=8")
    quests[1] = { done = true }   -- turned in: 2 (complete) and 3 (turn in) are done, 4 accepts quest 2
    ns.Refresh()
    H.eq(ns.char.idx, 4)
    H.eq(Marks(), "nameplate1=8 nameplate1=0 nameplate2=1")
end

function T.same_npc_on_the_next_step_keeps_its_star()
    local ns, units = Load(3, { units = { nameplate1 = Grull() } })
    SlashCmdList.MOTEVEGUIDE("next")
    H.eq(ns.char.idx, 4)
    H.eq(Marks(), "nameplate1=1")
    H.eq(units.nameplate1.icon, 1)
end

function T.out_of_reach_mark_comes_off_when_the_unit_is_back()
    local ns, units = Load(1, { units = { nameplate1 = Grull() } })
    units.far, units.nameplate1 = units.nameplate1, nil
    H.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate1")
    SlashCmdList.MOTEVEGUIDE("next")
    H.eq(Marks(), "nameplate1=1", "nothing to call while it is out of reach")
    H.eq(units.far.icon, 1)
    units.nameplate4 = units.far
    H.Fire("NAME_PLATE_UNIT_ADDED", "nameplate4")
    H.eq(Marks(), "nameplate1=1 nameplate4=0")
    H.eq(units.far.icon, nil)
end

function T.turning_the_option_off_takes_our_marks_off()
    local ns, units = Load(1, { units = { nameplate1 = Grull() } })
    ns.db.markTargets = false
    ns.Refresh()
    H.eq(Marks(), "nameplate1=1 nameplate1=0")
    units.nameplate2 = Grull("npc2")
    H.Fire("PLAYER_TARGET_CHANGED"); ns.UpdateMarks()
    H.eq(Marks(), "nameplate1=1 nameplate1=0")
end

function T.option_is_on_by_default()
    local ns = Load(1)
    H.eq(ns.db.markTargets, true)
    ns = Load(1, { db = { markTargets = false }, units = { nameplate1 = Grull() } })
    H.eq(ns.db.markTargets, false)
    H.eq(Marks(), "")
end

function T.options_checkbox_writes_mark_targets()
    local ns = Load(1)
    local cb
    for _, f in ipairs(H.frames) do if rawget(f, "opt") and f.opt.key == "markTargets" then cb = f end end
    H.ok(cb, "no markTargets checkbox")
    H.eq(cb.opt.text, "Célpont jelölése")
    H.ok(cb.opt.tip:find("Egyedül játszva", 1, true), "tooltip")
    cb.GetChecked = function() return false end
    cb.scripts.OnClick(cb)
    H.eq(ns.db.markTargets, false)
    H.eq(MoteveGuideDB.markTargets, false)
end

function T.steps_without_a_target_mark_nothing()
    for _, idx in ipairs({ 7, 8, 9 }) do
        local ns = Load(idx, { units = { nameplate1 = Grull(), nameplate2 = Boar("m1") } })
        ns.Refresh(); ns.UpdateMarks()
        H.eq(Marks(), "", "step " .. idx)
    end
end

return T
