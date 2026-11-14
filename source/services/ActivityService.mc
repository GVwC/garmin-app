import Toybox.ActivityMonitor;
import Toybox.Lang;

// Reads Garmin's own daily totals (reset at local midnight). No permission needed.
module ActivityService {

    // Today's value for the goal type, or null when the watch has no reading.
    function todayValue(goalType as Number) as Number? {
        var info = ActivityMonitor.getInfo();
        if (goalType == MonkeyModel.GOAL_ACTIVE) {
            var am = info.activeMinutesDay;
            return (am != null) ? am.total : null;
        } else if (goalType == MonkeyModel.GOAL_FLOORS) {
            return info.floorsClimbed;
        }
        return info.steps;
    }

    // Finished days (max 7, newest first) as [day, value or null].
    function history(goalType as Number) as Array<Array<Number?> > {
        var out = [] as Array<Array<Number?> >;
        var hist = ActivityMonitor.getHistory();
        var today = DayClock.today();
        for (var i = 0; i < hist.size(); i++) {
            var h = hist[i];
            var start = h.startOfDay;
            var day = (start != null) ? DayClock.dayOfMoment(start) : today - 1 - i;
            var v = null as Number?;
            if (goalType == MonkeyModel.GOAL_ACTIVE) {
                var am = h.activeMinutes;
                v = (am != null) ? am.total : null;
            } else if (goalType == MonkeyModel.GOAL_FLOORS) {
                v = h.floorsClimbed;
            } else {
                v = h.steps;
            }
            out.add([day, v] as Array<Number?>);
        }
        return out;
    }
}
