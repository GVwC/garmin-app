import Toybox.Lang;

// Story mode, "A day with Momo": scripted scenes so a demo shows every feature in order,
// independent of real sensor data. DOWN = next scene, UP = previous.
//   0-9   day 1: short night, still -> reminder, walk, revive, midday reminder, stress -> breathe,
//         calm, new route, goals met (evolves baby -> kid), night
//   10    day 2: lazy day -> recap (goal missed, XP lost, streak out)
//   11    journey: egg -> king next to your weekly progress
//   12+   extra states
// Story XP starts at STORY_XP so the goal scene evolves baby -> kid.
module DemoScenarios {

    // Columns of a row.
    const PERCENT = 0;   // goal progress in %
    const ENERGY = 1;    // Vitals.ENERGY_*
    const CALM = 2;      // Vitals.CALM_*
    const DEEP = 3;      // 1 = move bar maxed (monkey falls asleep sitting up)
    const EFFECT = 4;    // EFFECT_* applied when the scene is entered going forward
    const E_METER = 5;   // energy meter 0..100
    const C_METER = 6;   // calm meter 0..100
    const BREATH = 7;    // Vitals.BREATH_*
    const WARMTH = 8;    // Vitals.WARMTH_*
    const CURIOUS = 9;   // Vitals.CURIOUS_*
    const NUDGE = 10;    // VitalsModel.NUDGE_* -> reminder screen on entry, or -1
    const SCREEN = 11;   // SCREEN_* full-screen moment on entry

    const EFFECT_NONE = 0;
    const EFFECT_GOAL = 1;
    const EFFECT_MISSED = 2;
    const EFFECT_REVIVE = 3;
    const EFFECT_EXPLORE = 4;
    const EFFECT_CALMED = 5;

    const SCREEN_NONE = 0;
    const SCREEN_RECAP = 1;
    const SCREEN_JOURNEY = 2;

    const COUNT = 20;
    const DAY_SCENES = 12;
    const STORY_XP = 520;  // level 2 baby; revive + explore + goal crosses level 3 (kid)
    const STORY_STREAK = 2;

    function row(stage as Number) as Array<Number> {
        var R = Vitals.ENERGY_RESTED;
        var C = Vitals.CALM_CALM;
        var N = Vitals.BREATH_NORMAL;
        var W = Vitals.WARMTH_OK;
        var Q = Vitals.CURIOUS_CONTENT;
        var X = -1;
        var rows = [
            // --- day 1 ---
            [5, Vitals.ENERGY_LOW_RECHARGE, C, 0, EFFECT_NONE, 38, 70, N, W, Q, X, 0],           // 07:30 short night
            [20, Vitals.ENERGY_INACTIVE, C, 0, EFFECT_NONE, 45, 72, N, W, Q, VitalsModel.NUDGE_INACTIVE, 0],
            [45, R, Vitals.CALM_EXERCISING, 0, EFFECT_NONE, 55, 60, N, W, Q, X, 0],             // 10:40 walk
            [45, R, C, 0, EFFECT_REVIVE, 62, 74, N, W, Q, X, 0],                                // 10:45 back
            [45, R, C, 0, EFFECT_NONE, 60, 72, N, W, Q, VitalsModel.NUDGE_GOAL, 0],             // 13:00 under half
            [60, R, Vitals.CALM_STRESSED, 0, EFFECT_NONE, 55, 15, N, W, Q, VitalsModel.NUDGE_STRESSED, 0],
            [60, R, C, 0, EFFECT_CALMED, 58, 76, N, W, Q, X, 0],                                // 15:12 calm
            [85, R, C, 0, EFFECT_EXPLORE, 66, 78, N, W, Vitals.CURIOUS_ADVENTUROUS, X, 0],      // 16:30 new route
            [100, R, C, 0, EFFECT_GOAL, 70, 80, N, W, Q, X, 0],                                 // 18:00 goals
            [100, Vitals.ENERGY_SLEEPING, C, 0, EFFECT_NONE, 72, 86, N, W, Q, X, 0],            // 22:30 night
            // --- day 2 and the journey ---
            [35, R, C, 0, EFFECT_MISSED, 50, 70, N, W, Q, X, SCREEN_RECAP],                     // lazy day
            [60, R, C, 0, EFFECT_NONE, 80, 80, N, W, Q, X, SCREEN_JOURNEY],                     // journey
            // --- extra states ---
            [40, Vitals.ENERGY_INACTIVE, C, 1, EFFECT_NONE, 48, 72, N, W, Q, X, 0],
            [30, Vitals.ENERGY_EXHAUSTED, C, 0, EFFECT_NONE, 14, 60, N, W, Q, VitalsModel.NUDGE_EXHAUSTED, 0],
            [50, R, Vitals.CALM_ALERT, 0, EFFECT_NONE, 60, 42, N, W, Q, X, 0],
            [55, R, C, 0, EFFECT_NONE, 60, 55, Vitals.BREATH_LOW, W, Q, X, 0],
            [55, R, C, 0, EFFECT_NONE, 55, 50, Vitals.BREATH_CONCERNING, W, Q, VitalsModel.NUDGE_BREATH, 0],
            [45, R, C, 0, EFFECT_NONE, 58, 70, N, Vitals.WARMTH_COLD, Q, VitalsModel.NUDGE_COLD, 0],
            [45, R, C, 0, EFFECT_NONE, 52, 48, N, Vitals.WARMTH_HOT, Q, X, 0],
            [60, R, C, 0, EFFECT_NONE, 70, 75, N, W, Vitals.CURIOUS_ROUTINE, X, 0]
        ];
        return rows[stage] as Array<Number>;
    }
}
