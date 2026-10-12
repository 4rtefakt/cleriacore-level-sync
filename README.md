# Level Sync

For **Ys Origin** on CleriaCore. Every monster fights **as if it were near your level**, so the whole tower stays
relevant: come back to the early floors at level 40 and they still bite; walk into a late floor early and it is
hard, not hopeless.

- **Lifted or tamed.** A monster below your level hits harder, takes less and lasts longer; one above your level is
  brought down. Choose all of them, only the weak ones, or only the strong ones.
- **An offset.** Monsters at exactly your level by default; a slider puts them up to ten levels above or below.
- **EXP follows.** A synced monster pays the EXP of a monster of that level, so an old floor is worth farming again.
- **Bosses are not changed.** They keep the game's own numbers.

Example from the tests: a level 13 player with a tier 3 weapon hits a level 3 Selnarg for 59 in the retail game and
gets 1 EXP for the kill. With Level Sync the same hit does 8 and the kill pays 85.

Settings in **F1 > Mods > Level Sync**; the page also shows the last hit and EXP it changed.

## Install

1. Download `4rtefakt.levelsync-1.0.0.cleriamod` from the [releases](../../releases).
2. Double-click it (or use F1 > Mods > *Install a mod file...*).
3. Turn **Level Sync** on in F1 > Mods and restart CleriaCore.

Needs a CleriaCore with mod API 6.

## How it works

One Lua file, [main.lua](main.lua), about 90 lines. A mod can not change a monster's stats, but it sees every hit
just before it is applied, with everything that went into it. The game builds a monster's stats from its level on
straight lines, so "the same monster at another level" is a ratio:

```lua
local function line(lo, hi, level) return lo + (hi - lo) * (level - 1) / 59 end
local function raw(atk, def, power) return atk ^ 0.66 * (atk - 0.98 * def + 10 + power) / 22.92 end   -- the game's formula

cleria.combat.add_filter("damage", function(q)          -- q.atk, q.def, q.power, q.level, q.value ...
    local t = target(q.level)                           -- your level + the offset
    local stat = line(40, 295, t) / line(40, 295, q.level)
    if q.dir == "dealt" then
        local hp = line(60, 475, t) / line(60, 475, q.level)        -- more HP = each hit counts for less
        return q.value * raw(q.atk, q.def * stat, q.power) / raw(q.atk, q.def, q.power) / hp
    end
    return q.value * raw(q.atk * stat, q.def, q.power) / raw(q.atk, q.def, q.power)
end)
```

(The real code also keeps the game's minimums.)

| Part | API |
|---|---|
| Hits both ways | the `"damage"` combat filter and its fields `atk`, `def`, `power`, `level` |
| EXP | the `"exp"` filter and its fields `base`, `enemy_level`, `rate`, `factor`, `chain` |
| Your level | `cleria.player.level()` |

## Tests

`python .dev/run.py` runs five cases through CleriaCore's headless harness on a real monster: the mod off (a hit of
59, the monster at 15 of 74 HP); on (the same hit does 8); a kill (85.85 EXP instead of 1.01); "only tame the
strong ones" leaving a weaker monster alone; and a level 1 player against the level 3 monster (8 a hit instead
of 2).

Not covered: hits **taken** from a synced monster are computed the same way but no test lands one, and nobody has
played a whole run with it. The feel across forty floors is unknown.

## More CleriaCore mods

Each one is a small Lua mod that shows a different part of the mod API:

- [Mutators](https://github.com/4rtefakt/cleriacore-mutators): challenge rules: Glass Cannon, Berserker, One Hit, Vampire, Midas, Famine, Permadeath, a level cap
- [Solo Randomizer](https://github.com/4rtefakt/cleriacore-solo-randomizer): the tower's chests shuffled from a seed, always beatable, no server
- [Daily Challenge](https://github.com/4rtefakt/cleriacore-daily-challenge): the date shuffles the chests and picks two rules, the same for everyone
- [Roguelite Perks](https://github.com/4rtefakt/cleriacore-roguelite-perks): every boss beaten lets you choose one of three random perks
- [New Game+](https://github.com/4rtefakt/cleriacore-new-game-plus): start again with part of your level, SP and weapon against a harder tower
- [Adaptive Difficulty](https://github.com/4rtefakt/cleriacore-adaptive-difficulty): enemies hit softer after each death, and return to normal as you progress
- [Achievements](https://github.com/4rtefakt/cleriacore-achievements): thirty achievements kept across all your saves
- [Run HUD](https://github.com/4rtefakt/cleriacore-run-hud): room and run time, kills, deaths, damage per second
- [Bestiary+](https://github.com/4rtefakt/cleriacore-bestiary): a per-save hunting log of every monster killed
- [Autosave+](https://github.com/4rtefakt/cleriacore-autosave): rolling autosaves on a timer, after bosses and in new zones
- [Debug Menu](https://github.com/4rtefakt/cleriacore-debug-menu): change level, SP, items, gear, skills, blessings, warps and flags
- [Crowd Control](https://github.com/4rtefakt/cleriacore-crowd-control): Twitch chat votes on what happens to you
- [LiveSplit Autosplitter](https://github.com/4rtefakt/cleriacore-livesplit): starts and splits LiveSplit over its WebSocket server
- [Archipelago](https://github.com/4rtefakt/ys-origin-cleriacore-ap): the multiworld randomizer client, the biggest one

## About

Written with AI assistance (Claude Code) as a showcase of the CleriaCore mod API, and tested as described above.
MIT license.
