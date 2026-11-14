import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

// Background check, run by the system every Reminders.INTERVAL_SEC while reminders are on
// (also when the app is closed). Reads the same snapshot as the app, advances the vitals
// state machine and, if VitalsModel's rules allow it, asks the user to open the app.
// Budget: 64 KB memory, a few history reads, no sensors enabled.
(:background)
class MonkeyService extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        var snap = VitalsService.snapshot();
        var vitals = new VitalsModel();
        vitals.load();
        vitals.apply(snap, DayClock.today());

        var now = Time.now().value();
        if (!appIsOpen(now)) {
            var kind = vitals.pickNudge(snap, goalPermille(), now);
            if (kind != VitalsModel.NUDGE_NONE) {
                Background.requestApplicationWake(message(kind));
            }
        }
        Background.exit(null);
    }

    // The app refreshes VitalsModel.KEY_FG_SEEN while visible and clears it on hide.
    private function appIsOpen(now as Number) as Boolean {
        var seen = Storage.getValue(VitalsModel.KEY_FG_SEEN);
        return (seen instanceof Number) && seen > 0 && now - seen < 6 * 60;
    }

    private function goalPermille() as Number? {
        var type = Storage.getValue(Goals.KEY_TYPE);
        var t = (type instanceof Number && type >= 0 && type < Goals.GOAL_TYPES) ? type : Goals.GOAL_STEPS;
        var target = Storage.getValue(Goals.KEY_TARGET);
        var goal = (target instanceof Number && target > 0) ? target : Goals.defaultTarget(t);
        var v = ActivityService.todayValue(t);
        return (v == null) ? null : v * 1000 / goal;
    }

    private function message(kind as Number) as String {
        var ids = [Rez.Strings.Nudge0, Rez.Strings.Nudge1, Rez.Strings.Nudge2, Rez.Strings.Nudge3, Rez.Strings.Nudge4];
        return Application.loadResource(ids[kind]) as String;
    }
}
