-- Moteve Guide - raid marks on the current step's target: a star on the NPC to talk to,
-- a skull on a mob to kill. Only when playing alone, and never on or off a mark it did not set.
local ADDON_NAME, ns = ...

local STAR, SKULL = 1, 8
local UNITS = { "target", "mouseover" }
for i = 1, 40 do UNITS[#UNITS + 1] = "nameplate" .. i end

local own = {}           -- [icon] = guid we put that icon on
local pendingClear = {}  -- [guid] = icon of ours to take off once the unit is reachable again
local lastKey

local function ReleaseOwn()
    for icon, guid in pairs(own) do pendingClear[guid] = icon; own[icon] = nil end
end

-- icon and lower-case names to mark for the current step
local function Wanted()
    local g, c = ns.guide, ns.char
    local s = g and c and g.steps[c.idx]
    if not s then return end
    local k = s.k
    if (k == "a" or k == "t" or k == "fp" or k == "note") and s.npc then
        return STAR, { [s.npc:lower()] = true }
    end
    if k == "c" and s.mob and #s.mob > 0 then
        local names = {}
        for _, n in ipairs(s.mob) do names[n:lower()] = true end
        return SKULL, names
    end
end

local function Matches(unit, icon, names)
    local name = UnitName(unit)
    if not name or not names[name:lower()] or UnitIsPlayer(unit) then return false end
    if icon == SKULL then return not UnitIsDead(unit) and UnitCanAttack("player", unit) and true or false end
    return true
end

function ns.UpdateMarks()
    local db = ns.db
    if not db then return end
    local key = ns.guide and ns.char and (ns.guide.id .. ":" .. tostring(ns.char.idx))
    local grouped = IsInGroup() or IsInRaid()
    if key ~= lastKey or not db.markTargets or grouped then ReleaseOwn() end
    lastKey = key
    local icon, names
    if db.markTargets and not grouped then icon, names = Wanted() end
    if not icon and not next(own) and not next(pendingClear) then return end

    -- what is visible now: each unit once, with the icon it carries
    local seen, units, iconAt = {}, {}, {}
    for _, unit in ipairs(UNITS) do
        local guid = UnitExists(unit) and UnitGUID(unit)
        if guid and not seen[guid] then
            local u = { unit = unit, guid = guid, icon = GetRaidTargetIndex(unit) }
            seen[guid] = u
            units[#units + 1] = u
            if u.icon then iconAt[u.icon] = guid end
        end
    end

    -- an icon of ours that is now somewhere else (or gone) is no longer ours
    for i, guid in pairs(own) do
        local u = seen[guid]
        if (iconAt[i] and iconAt[i] ~= guid) or (u and u.icon ~= i) then own[i] = nil end
    end
    for guid, i in pairs(pendingClear) do
        local u = seen[guid]
        if u then
            pendingClear[guid] = nil
            if u.icon == i then
                if i == icon and not own[i] and Matches(u.unit, icon, names) then
                    own[i] = guid   -- still the target of the current step: keep it
                else
                    SetRaidTarget(u.unit, 0)
                    u.icon, iconAt[i] = nil, nil
                end
            end
        elseif iconAt[i] and iconAt[i] ~= guid then
            pendingClear[guid] = nil
        end
    end

    if not icon then return end
    local mine = own[icon] and seen[own[icon]]
    if mine and Matches(mine.unit, icon, names) then return end
    if iconAt[icon] and iconAt[icon] ~= own[icon] then return end   -- someone else's mark
    for _, u in ipairs(units) do
        if not u.icon and Matches(u.unit, icon, names) and GetRaidTargetIndex(u.unit) == nil then
            SetRaidTarget(u.unit, icon)
            own[icon] = u.guid
            return
        end
    end
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "UPDATE_MOUSEOVER_UNIT",
                     "PLAYER_TARGET_CHANGED", "GROUP_ROSTER_UPDATE" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function() pcall(ns.UpdateMarks) end)
C_Timer.NewTicker(1, function() pcall(ns.UpdateMarks) end)
