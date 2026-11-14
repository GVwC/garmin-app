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

    const EFFECT_NONE = 0;
    const EFFECT_GOAL = 1;
    const EFFECT_MISSED = 2;
    const EFFECT_REVIVE = 3;
    const EFFECT_BREATH = 4;

    // Stage indexes referenced by the view for labels.
    const COUNT = 12;

    function row(stage as Number) as Array<Number> {
        var rows = [
            [20, Vitals.ENERGY_RESTED, Vitals.CALM_CALM, 0, EFFECT_NONE, 80, 78],
            [65, Vitals.ENERGY_RESTED, Vitals.CALM_CALM, 0, EFFECT_NONE, 72, 74],
            [100, Vitals.ENERGY_RESTED, Vitals.CALM_CALM, 0, EFFECT_GOAL, 70, 80],
            [35, Vitals.ENERGY_RESTED, Vitals.CALM_CALM, 0, EFFECT_MISSED, 62, 70],
            [40, Vitals.ENERGY_INACTIVE, Vitals.CALM_CALM, 0, EFFECT_NONE, 55, 72],
            [40, Vitals.ENERGY_INACTIVE, Vitals.CALM_CALM, 1, EFFECT_NONE, 48, 72],
            [30, Vitals.ENERGY_LOW_RECHARGE, Vitals.CALM_CALM, 0, EFFECT_NONE, 32, 66],
            [30, Vitals.ENERGY_EXHAUSTED, Vitals.CALM_CALM, 0, EFFECT_NONE, 14, 60],
            [50, Vitals.ENERGY_RESTED, Vitals.CALM_ALERT, 0, EFFECT_NONE, 60, 42],
            [50, Vitals.ENERGY_RESTED, Vitals.CALM_STRESSED, 0, EFFECT_NONE, 55, 15],
            [75, Vitals.ENERGY_RESTED, Vitals.CALM_EXERCISING, 0, EFFECT_NONE, 66, 58],
            [75, Vitals.ENERGY_RESTED, Vitals.CALM_CALM, 0, EFFECT_REVIVE, 86, 82]
        ];
        return rows[stage] as Array<Number>;
    }
}
