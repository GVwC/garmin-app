import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

// Local calendar day numbers (days since 1970-01-01 in device-local time).
// A new day starts at local midnight, matching Garmin's midnight step reset.
(:background, :glance)
module DayClock {

    const DAY_SEC = 86400;

    // Pure helper, unit-tested: epoch seconds + timezone offset -> local day.
    function dayOf(epochSec as Number, tzOffsetSec as Number) as Number {
        var local = epochSec + tzOffsetSec;
        var day = local / DAY_SEC;
        if (local < 0 && local % DAY_SEC != 0) {
            day -= 1;
        }
        return day;
    }

    function today() as Number {
        return dayOf(Time.now().value(), System.getClockTime().timeZoneOffset);
    }

    // History start-of-day moments: sample noon of that day, so it does not matter
    // whether the device reports local or UTC midnight.
    function dayOfMoment(m as Time.Moment) as Number {
        return dayOf(m.value() + DAY_SEC / 2, System.getClockTime().timeZoneOffset);
    }
}
