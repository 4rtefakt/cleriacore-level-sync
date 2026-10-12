def kill(cast, start, n=4):
    return ";".join("%d:near=%d;%d:atk" % (t, cast, t + 1) for t in range(start, start + 25 * n, 25))


LP = "[lua:4rtefakt.levelsync] "
CASES = {
    # Level 13 against a level 3 Selnarg, the mod off: the game's own numbers, for comparison (a 59-damage hit).
    "off": dict(room="S_10/S_1002/S_1002", settings="Enabled=0",
        drive="6:level=13;7:tier=3;20:near=17;21:atk;60:near=17;70:lua=ls;80:quit",
        expect=["near cast 17 id 17 hp 74 ", "near cast 17 id 17 hp 15 ", LP + "dealt - | taken - | exp -"]),
    # On: the same hit on the same monster, now fighting at level 13: 8 damage, not 59.
    "lifted": dict(room="S_10/S_1002/S_1002",
        drive="6:level=13;7:tier=3;20:near=17;21:atk;60:near=17;70:lua=ls;80:quit",
        expect=["near cast 17 id 17 hp 74 ", "near cast 17 id 17 hp 66 ", LP + "dealt lv 3 -> 13: 59 -> 8 "]),
    # A kill at level 13: the EXP is a level 13 monster's, not the 1 EXP an outlevelled one pays.
    "exp": dict(room="S_10/S_1002/S_1002",
        drive="6:level=13;7:tier=3;8:opt=DamageDealt=10;10:opt=DamageTaken=0;" + kill(17, 40, 6) + ";200:lua=ls;210:stats;220:quit",
        expect=[LP + "dealt lv 3 -> 13: ", " | exp lv 3 -> 13: 1.01 -> 85.85", "stats exp 22021 lv 13"]),
    # "Only tame the strong ones" leaves a weaker monster alone.
    "tame_only": dict(room="S_10/S_1002/S_1002", settings="Mode=3",
        drive="6:level=13;7:tier=3;20:near=17;21:atk;70:lua=ls;80:quit", expect=[LP + "dealt - | taken - | exp -"]),
    # Level 1 against the same level 3 monster: it is tamed to level 1 and takes 8 a hit, not 2.
    "tamed": dict(room="S_10/S_1002/S_1002",
        drive="20:near=17;21:atk;70:lua=ls;80:quit", expect=[LP + "dealt lv 3 -> 1: 2 -> 8 "]),
}
