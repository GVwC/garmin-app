import Toybox.ActivityMonitor;
import Toybox.Lang;

// Today's totals from Garmin (reset at local midnight). No permission needed.
// Used by the app, the background service (midday goal nudge) and the glance.
(:background, :glance)
module ActivityService {

    // Today's value for the goal type, or null when the watch has no reading.
    function todayValue(goalType as Number) as Number? {
        var info = ActivityMonitor.getInfo();
        if (goalType == Goals.GOAL_ACTIVE) {
            var am = info.activeMinutesDay;
            return (am != null) ? am.total : null;
        } else if (goalType == Goals.GOAL_FLOORS) {
            return info.floorsClimbed;
        }
        return info.steps;
    }
}

// Finished days for XP catch-up (foreground only).
module ActivityHistory {

    // Max 7 days, newest first, as [day, value or null].
    function days(goalType as Number) as Array<Array<Number?> > {
        var out = [] as Array<Array<Number?> >;
        var hist = ActivityMonitor.getHistory();
        var today = DayClock.today();
        for (var i = 0; i < hist.size(); i++) {
            var h = hist[i];
            var start = h.startOfDay;
            var day = (start != null) ? DayClock.dayOfMoment(start) : today - 1 - i;
            var v = null as Number?;
            if (goalType == Goals.GOAL_ACTIVE) {
                var am = h.activeMinutes;
                v = (am != null) ? am.total : null;
            } else if (goalType == Goals.GOAL_FLOORS) {
                v = h.floorsClimbed;
            } else {
                v = h.steps;
            }
            out.add([day, v] as Array<Number?>);
        }
        return out;
    }
}
