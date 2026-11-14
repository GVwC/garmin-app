import Toybox.Lang;

// Scripted demo: each stage sets goal progress and vitals so judges can see every state
// without waiting for real data. Stages are walked with DOWN (next) / UP (previous).
module DemoScenarios {

    // Columns of a row.
    const PERCENT = 0;   // goal progress in %
    const ENERGY = 1;    // Vitals.ENERGY_*
    const CALM = 2;      // Vitals.CALM_*
    const DEEP = 3;      // 1 = move bar maxed (monkey falls asleep sitting up)
    const EFFECT = 4;    // EFFECT_* applied when the stage is entered going forward
    const E_METER = 5;   // energy meter 0..100
    const C_METER = 6;   // calm meter 0..100
    const BREATH = 7;    // Vitals.BREATH_*
    const WARMTH = 8;    // Vitals.WARMTH_*
    const CURIOUS = 9;   // Vitals.CURIOUS_*

    const EFFECT_NONE = 0;
    const EFFECT_GOAL = 1;
    const EFFECT_MISSED = 2;
    const EFFECT_REVIVE = 3;
    const EFFECT_EXPLORE = 4;

    const COUNT = 18;

    function row(stage as Number) as Array<Number> {
        var R = Vitals.ENERGY_RESTED;
        var C = Vitals.CALM_CALM;
        var N = Vitals.BREATH_NORMAL;
        var W = Vitals.WARMTH_OK;
        var Q = Vitals.CURIOUS_CONTENT;
        var rows = [
            [20, R, C, 0, EFFECT_NONE, 80, 78, N, W, Q],
            [65, R, C, 0, EFFECT_NONE, 72, 74, N, W, Q],
            [100, R, C, 0, EFFECT_GOAL, 70, 80, N, W, Q],
            [35, R, C, 0, EFFECT_MISSED, 62, 70, N, W, Q],
            [40, Vitals.ENERGY_INACTIVE, C, 0, EFFECT_NONE, 55, 72, N, W, Q],
            [40, Vitals.ENERGY_INACTIVE, C, 1, EFFECT_NONE, 48, 72, N, W, Q],
            [30, Vitals.ENERGY_LOW_RECHARGE, C, 0, EFFECT_NONE, 32, 66, N, W, Q],
            [30, Vitals.ENERGY_EXHAUSTED, C, 0, EFFECT_NONE, 14, 60, N, W, Q],
            [50, R, Vitals.CALM_ALERT, 0, EFFECT_NONE, 60, 42, N, W, Q],
            [50, R, Vitals.CALM_STRESSED, 0, EFFECT_NONE, 55, 15, N, W, Q],
            [75, R, Vitals.CALM_EXERCISING, 0, EFFECT_NONE, 66, 58, N, W, Q],
            [55, R, C, 0, EFFECT_NONE, 60, 55, Vitals.BREATH_LOW, W, Q],
            [55, R, C, 0, EFFECT_NONE, 55, 50, Vitals.BREATH_CONCERNING, W, Q],
            [45, R, C, 0, EFFECT_NONE, 58, 70, N, Vitals.WARMTH_COLD, Q],
            [45, R, C, 0, EFFECT_NONE, 52, 48, N, Vitals.WARMTH_HOT, Q],
            [90, R, C, 0, EFFECT_EXPLORE, 74, 80, N, W, Vitals.CURIOUS_ADVENTUROUS],
            [60, R, C, 0, EFFECT_NONE, 70, 75, N, W, Vitals.CURIOUS_ROUTINE],
            [75, R, C, 0, EFFECT_REVIVE, 86, 82, N, W, Q]
        ];
        return rows[stage] as Array<Number>;
    }
}
