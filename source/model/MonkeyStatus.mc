import Toybox.Lang;

// Decides what the monkey shows: pose, background tint and the recommendation to display.
// One status at a time, highest priority first:
//   breath concerning > exhausted > night > stressed > cold > hot > breath low >
//   2 h still > still > low recharge > alert > exercising > adventurous > routine > goal pose
// Pure functions, unit-tested. Also used by the glance.
(:glance)
module MonkeyStatus {

    // Poses (index into MainView's sprites). 0..2 match MonkeyModel.getPose().
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
    const POSE_PANT = 11;
    const POSE_COLD = 12;
    const POSE_HOT = 13;
    const POSE_CLIMB = 14;
    const POSE_BORED = 15;
    const POSE_COUNT = 16;

    const TINT_DAY = 0;
    const TINT_NIGHT = 1;
    const TINT_STRESS = 2;
    const TINT_EMPTY = 3;
    const TINT_COLD = 4;
    const TINT_HOT = 5;
    const TINT_BREATH = 6;

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
    const MSG_BREATH_CONCERNING = 8;
    const MSG_BREATH_LOW = 9;
    const MSG_COLD = 10;
    const MSG_HOT = 11;
    const MSG_ADVENTUROUS = 12;
    const MSG_ROUTINE = 13;
    const MSG_COUNT = 14;

    function message(energy as Number, calm as Number, deepStill as Boolean,
            breath as Number, warmth as Number, curious as Number) as Number {
        if (breath == Vitals.BREATH_CONCERNING) {
            return MSG_BREATH_CONCERNING;
        } else if (energy == Vitals.ENERGY_EXHAUSTED) {
            return MSG_EXHAUSTED;
        } else if (energy == Vitals.ENERGY_SLEEPING) {
            return MSG_NIGHT;
        } else if (calm == Vitals.CALM_STRESSED) {
            return MSG_STRESSED;
        } else if (warmth == Vitals.WARMTH_COLD) {
            return MSG_COLD;
        } else if (warmth == Vitals.WARMTH_HOT) {
            return MSG_HOT;
        } else if (breath == Vitals.BREATH_LOW) {
            return MSG_BREATH_LOW;
        } else if (energy == Vitals.ENERGY_INACTIVE) {
            return deepStill ? MSG_DEEP_STILL : MSG_STILL;
        } else if (energy == Vitals.ENERGY_LOW_RECHARGE) {
            return MSG_LOW_RECHARGE;
        } else if (calm == Vitals.CALM_ALERT) {
            return MSG_ALERT;
        } else if (calm == Vitals.CALM_EXERCISING) {
            return MSG_EXERCISING;
        } else if (curious == Vitals.CURIOUS_ADVENTUROUS) {
            return MSG_ADVENTUROUS;
        } else if (curious == Vitals.CURIOUS_ROUTINE) {
            return MSG_ROUTINE;
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
        } else if (msg == MSG_BREATH_CONCERNING || msg == MSG_BREATH_LOW) {
            return POSE_PANT;
        } else if (msg == MSG_COLD) {
            return POSE_COLD;
        } else if (msg == MSG_HOT) {
            return POSE_HOT;
        } else if (msg == MSG_ADVENTUROUS) {
            return POSE_CLIMB;
        } else if (msg == MSG_ROUTINE) {
            return POSE_BORED;
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
        } else if (msg == MSG_COLD) {
            return TINT_COLD;
        } else if (msg == MSG_HOT) {
            return TINT_HOT;
        } else if (msg == MSG_BREATH_CONCERNING) {
            return TINT_BREATH;
        }
        return TINT_DAY;
    }

    // Background colour per tint (64-colour MIP palette).
    function tintColor(tint as Number) as Number {
        return [0x005500, 0x000055, 0x550000, 0x000000, 0x0055AA, 0x555500, 0x005555][tint];
    }

    // START opens the breathing screen instead of the goal picker when it is the recommendation.
    function suggestsBreathing(msg as Number) as Boolean {
        return msg == MSG_STRESSED || msg == MSG_ALERT || msg == MSG_BREATH_LOW || msg == MSG_BREATH_CONCERNING;
    }

    // Exhausted: the sleeping monkey takes over the whole face (counter and bars hidden).
    function takesOverFace(msg as Number) as Boolean {
        return msg == MSG_EXHAUSTED;
    }

    // Animated with a slow 2-frame loop while visible (jog bob, shiver).
    function isLooping(msg as Number) as Boolean {
        return msg == MSG_EXERCISING || msg == MSG_COLD;
    }
}
