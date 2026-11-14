import Toybox.Lang;

// Goal types and their target choices. Shared by the app, the background service and the glance.
(:background, :glance)
module Goals {

    const GOAL_STEPS = 0;
    const GOAL_ACTIVE = 1;
    const GOAL_FLOORS = 2;
    const GOAL_TYPES = 3;

    // Storage keys owned by MonkeyModel but read by the background service and glance.
    const KEY_TYPE = "goalType";
    const KEY_TARGET = "goalTarget";
    const KEY_XP = "xp";

    function targetsFor(goalType as Number) as Array<Number> {
        if (goalType == GOAL_ACTIVE) {
            return [10, 20, 30, 60];
        } else if (goalType == GOAL_FLOORS) {
            return [5, 10, 15, 25];
        }
        return [1000, 3000, 5000, 10000];
    }

    function defaultTarget(goalType as Number) as Number {
        return targetsFor(goalType)[2];
    }
}
