import Toybox.Lang;

// Decides what the monkey shows: pose, background tint and the recommendation to display.
// Vitals override goal progress, in this priority:
//   EXHAUSTED > night > STRESSED > 2 h still > INACTIVE > LOW_RECHARGE > ALERT > EXERCISING > goal pose
// Pure functions, unit-tested. Also used by the glance.
(:glance)
module MonkeyStatus {

    // Poses (index into MainView's compiled sprites). 0..2 match MonkeyModel.getPose().
    const POSE_RELAX = 0;
    const POSE_PERK = 1;
    const POSE_EAT = 2;
    const POSE_TIRED = 3;
    const POSE_ASLEEP = 4;
    const POSE_ALERT = 5;
    const POSE_STRESSED = 6;
    const POSE_JOG = 7;
    const POSE_JOG2 = 8;
    const POSE_STRETCH = 9;
    const POSE_BREATHE = 10;
    const POSE_COUNT = 11;

    const TINT_DAY = 0;
    const TINT_NIGHT = 1;
    const TINT_STRESS = 2;
    const TINT_EMPTY = 3;

    // Recommendations (index into status title/action strings).
    const MSG_NONE = -1;
    const MSG_EXHAUSTED = 0;
    const MSG_NIGHT = 1;
    const MSG_STRESSED = 2;
    const MSG_DEEP_STILL = 3;
    const MSG_STILL = 4;
    const MSG_LOW_RECHARGE = 5;
    const MSG_ALERT = 6;
    const MSG_EXERCISING = 7;
    const MSG_COUNT = 8;

    function message(energy as Number, calm as Number, deepStill as Boolean) as Number {
        if (energy == Vitals.ENERGY_EXHAUSTED) {
            return MSG_EXHAUSTED;
        } else if (energy == Vitals.ENERGY_SLEEPING) {
            return MSG_NIGHT;
        } else if (calm == Vitals.CALM_STRESSED) {
            return MSG_STRESSED;
        } else if (energy == Vitals.ENERGY_INACTIVE) {
            return deepStill ? MSG_DEEP_STILL : MSG_STILL;
        } else if (energy == Vitals.ENERGY_LOW_RECHARGE) {
            return MSG_LOW_RECHARGE;
        } else if (calm == Vitals.CALM_ALERT) {
            return MSG_ALERT;
        } else if (calm == Vitals.CALM_EXERCISING) {
            return MSG_EXERCISING;
        }
        return MSG_NONE;
    }

    // goalPose: MonkeyModel.getPose(). frame toggles the jog animation.
    function pose(goalPose as Number, msg as Number, frame as Number) as Number {
        if (msg == MSG_EXHAUSTED || msg == MSG_NIGHT || msg == MSG_DEEP_STILL) {
            return POSE_ASLEEP;
        } else if (msg == MSG_STRESSED) {
            return POSE_STRESSED;
        } else if (msg == MSG_STILL || msg == MSG_LOW_RECHARGE) {
            return POSE_TIRED;
        } else if (msg == MSG_ALERT) {
            return POSE_ALERT;
        } else if (msg == MSG_EXERCISING) {
            return (frame % 2 == 0) ? POSE_JOG : POSE_JOG2;
        }
        return goalPose;
    }

    function tint(msg as Number) as Number {
        if (msg == MSG_EXHAUSTED) {
            return TINT_EMPTY;
        } else if (msg == MSG_NIGHT) {
            return TINT_NIGHT;
        } else if (msg == MSG_STRESSED) {
            return TINT_STRESS;
        }
        return TINT_DAY;
    }

    // START opens the breathing screen instead of the goal picker when it is the recommendation.
    function suggestsBreathing(msg as Number) as Boolean {
        return msg == MSG_STRESSED || msg == MSG_ALERT;
    }

    // Exhausted: the sleeping monkey takes over the whole face (counter and bars hidden).
    function takesOverFace(msg as Number) as Boolean {
        return msg == MSG_EXHAUSTED;
    }
}
