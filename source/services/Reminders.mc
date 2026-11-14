import Toybox.Background;
import Toybox.Lang;
import Toybox.Time;

// Registers / removes the periodic background check (MonkeyService).
// 30 min: Garmin's move bar grows in 15-min steps and the thresholds are 90/120 min, so a
// 15-min check would double the wake-ups without changing what the user sees much.
// Each wake-up only reads history the watch already recorded (no sensors), ~48 per day.
module Reminders {

    const INTERVAL_SEC = 30 * 60;

    function sync(enabled as Boolean) as Void {
        if (!(Toybox has :Background)) {
            return;
        }
        if (enabled) {
            if (Background.getTemporalEventRegisteredTime() == null) {
                Background.registerForTemporalEvent(new Time.Duration(INTERVAL_SEC));
            }
        } else {
            Background.deleteTemporalEvent();
        }
    }
}
