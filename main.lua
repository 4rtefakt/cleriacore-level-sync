-- Level Sync: every monster fights as if it were at (your level + offset).
--
-- The game builds a monster's stats from its level on shared curves, each times the monster's own multiplier:
--   HP ~ 60..475, ATK and DEF ~ 40..295, EXP ~ 15..610   (level 1..60, straight lines)
-- so "the same monster at another level" is its stats times curve(new) / curve(old). A mod can not change a
-- monster's stats, but it sees every hit and every EXP award just before they are applied: the hit is recomputed
-- with the synced ATK or DEF, and the monster's synced HP is folded into the damage it takes.

local S, P = cleria.settings, cleria.player

local enabled = S.get("Enabled", true)
local offset = S.get("Offset", 0)              -- monsters at your level + offset
local mode = S.get("Mode", 1)                  -- 1 both ways, 2 only lift weak monsters, 3 only tame strong ones
local sync_exp = S.get("SyncExp", true)

local function line(lo, hi, level) return lo + (hi - lo) * (level - 1) / 59 end
local function target(level)                   -- the level this monster fights at, or nil when it is left alone
    if not enabled or not level then return nil end
    local t = math.max(1, math.min(60, P.level() + offset))
    if t == level or (mode == 2 and level > t) or (mode == 3 and level < t) then return nil end
    return t
end

-- the game's damage formula before resistances and rounding (the same on both sides)
local function raw(atk, def, power) return atk ^ 0.66 * (atk - 0.98 * def + 10 + power) / 22.92 end

local seen = {}                                -- what the last query of each kind became, for the page and the tests

cleria.combat.add_filter("damage", function(q)
    if q.value <= 0 then return nil end
    local t = target(q.level)
    if not t then return nil end
    local stat = line(40, 295, t) / line(40, 295, q.level)
    local new
    if q.dir == "dealt" then
        local old_base = math.max(raw(q.atk, q.def, q.power), 1)
        local new_base = math.max(raw(q.atk, q.def * stat, q.power), 1)
        local hp = line(60, 475, t) / line(60, 475, q.level)          -- more HP = each hit counts for less
        new = q.value * new_base / old_base / hp
    else
        local floor_old, floor_new = q.atk * 0.03, q.atk * stat * 0.03   -- the game's soft floor on hits taken
        local old_base = math.max(raw(q.atk, q.def, q.power), floor_old)
        local new_base = math.max(raw(q.atk * stat, q.def, q.power), floor_new)
        new = q.value * new_base / old_base
    end
    new = math.max(1, math.floor(new + 0.5))
    seen[q.dir] = string.format("%s lv %d -> %d: %d -> %d", q.dir, q.level, t, math.floor(q.value), new)
    return new
end)

cleria.combat.add_filter("exp", function(q)
    if not sync_exp or q.source ~= "kill" then return nil end
    local t = target(q.enemy_level)
    if not t then return nil end
    local base = q.base * line(15, 610, t) / line(15, 610, q.enemy_level)
    local d = t - q.level                                               -- the synced monster against you
    local gap = d >= 0 and 1.5 ^ math.min(d, 3) or 1.5 ^ d
    local new = math.max(1, math.floor(base * gap * 0.6666 * q.rate * q.factor * q.diff_mult)) * q.chain
    seen.exp = string.format("exp lv %d -> %d: %.2f -> %.2f", q.enemy_level, t, q.value, new)
    return new
end)

cleria.ui.page("Level Sync", function(p)
    p:section("Level Sync")
    local v, ch = p:toggle("Enabled", enabled, "Monsters fight as if they were near your level. Bosses are not changed. Not a retail option.")
    if ch then enabled = v S.set("Enabled", v) end
    v, ch = p:slider("Monsters are at your level", offset, -10, 10, 1, "%+.0f", "0 = exactly your level. Above: a harder game; below: an easier one.")
    if ch then offset = math.floor(v + 0.5) S.set("Offset", offset) end
    v, ch = p:choice("Which monsters", mode, {"All of them", "Only lift the weak ones", "Only tame the strong ones"},
                     "Lifting keeps the early floors a fight when you come back; taming lets you go up early.")
    if ch then mode = v S.set("Mode", v) end
    v, ch = p:toggle("EXP follows", sync_exp, "A synced monster pays the EXP of a monster of that level.")
    if ch then sync_exp = v S.set("SyncExp", v) end
    p:section("Last changes")
    p:info("Hit dealt", seen.dealt or "-")
    p:info("Hit taken", seen.taken or "-")
    p:info("EXP", seen.exp or "-")
end)

cleria.command("ls", function() cleria.log((seen.dealt or "dealt -") .. " | " .. (seen.taken or "taken -") .. " | " .. (seen.exp or "exp -")) end)
cleria.log("Level Sync loaded")
