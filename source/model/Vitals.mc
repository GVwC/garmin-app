import Toybox.Lang;

// One reading of everything the vitals need. Built by VitalsService (or tests / demo).
// All values come from data the watch already records; nothing here turns a sensor on.
(:background, :glance)
class VitalsSnapshot {
    var minuteOfDay as Number = 720;    // local minutes since midnight
    var wakeMin as Number = 7 * 60;     // user's wake time (profile), minutes since midnight
    var sleepMin as Number = 23 * 60;   // user's sleep time (profile)
    var bodyBattery as Number? = null;  // latest Body Battery 0..100
    var bbPeakToday as Number? = null;  // highest Body Battery since midnight (recharge proxy)
    var bbRecentGain as Number? = null; // latest minus lowest Body Battery in the last 3 h (rest / nap)
    var moveBar as Number? = null;      // Garmin move bar level, 0..5 (1 = 60 min still, +1 per 15 min)
    var stress as Number? = null;       // Garmin stress 0..100 (not computed during activity)
    var stressSustained as Boolean = false; // every stress sample of the last ~5 min >= STRESS_HIGH
    var heartRate as Number? = null;    // latest wrist HR sample
    var restingHr as Number? = null;    // personal resting HR baseline
    var hrSustainedPct as Number? = null; // lowest HR elevation % over the last ~5 min
    var stepsPerMin as Number? = null;  // recent cadence; null if unknown

    function initialize() {
    }
}

// Energy and Calm state machines. Pure functions: same snapshot + previous state -> same result.
//
// Energy (movement + recharge)
//   SLEEPING       outside the user's wake window (night): monkey sleeps, no nudges
//   LOW_RECHARGE   today's Body Battery peak < RECHARGE_MIN (proxy for a short/poor night;
//                  Connect IQ cannot read sleep data). Clears after a rest/nap gain or tomorrow.
//   INACTIVE       move bar >= INACTIVE_LEVEL (~90 min without moving). Clears when Garmin clears
//                  the move bar (a few minutes of walking).
//   EXHAUSTED      LOW_RECHARGE and INACTIVE together.
//   RESTED         none of the above.
// Calm (heart rate / stress, cross-checked with movement so workouts are never read as stress)
//   EXERCISING     moving (cadence) and HR elevated: good stress
//   STRESSED       not moving and stress high for ~5 min, or HR > STRESSED_HR_PCT over resting for ~5 min
//   ALERT          not moving and stress >= ALERT_STRESS, or HR >= ALERT_HR_PCT over resting
//                  Recovers only when stress <= CALM_STRESS and HR <= CALM_HR_PCT (hysteresis).
//   CALM           otherwise (also when there is no data)
(:background, :glance)
module Vitals {

    const ENERGY_RESTED = 0;
    const ENERGY_LOW_RECHARGE = 1;
    const ENERGY_INACTIVE = 2;
    const ENERGY_EXHAUSTED = 3;
    const ENERGY_SLEEPING = 4;

    const CALM_CALM = 0;
    const CALM_ALERT = 1;
    const CALM_STRESSED = 2;
    const CALM_EXERCISING = 3;

    // Thresholds (tune here).
    const RECHARGE_MIN = 50;       // Body Battery peak below this = low recharge
    const RECHARGE_GRACE_MIN = 60; // judge recharge only 1 h after wake time
    const NAP_GAIN = 10;           // Body Battery gain that counts as a recovering rest
    const INACTIVE_LEVEL = 3;      // move bar level ~ 90 min still
    const DEEP_INACTIVE_LEVEL = 5; // ~ 2 h still: monkey falls asleep sitting up
    const MOVING_CADENCE = 60;     // steps/min that count as moving
    const STRESS_HIGH = 76;        // Garmin "high stress" band
    const ALERT_STRESS = 51;       // Garmin "medium stress" band
    const CALM_STRESS = 40;
    const ALERT_HR_PCT = 15;
    const STRESSED_HR_PCT = 25;
    const CALM_HR_PCT = 5;

    function isAwake(s as VitalsSnapshot) as Boolean {
        return inWindow(s.minuteOfDay, s.wakeMin, s.sleepMin);
    }

    // True when minute is in [from, to), handling windows that cross midnight.
    function inWindow(minute as Number, from as Number, to as Number) as Boolean {
        if (from == to) {
            return true;
        }
        if (from < to) {
            return minute >= from && minute < to;
        }
        return minute >= from || minute < to;
    }

    function minutesSinceWake(s as VitalsSnapshot) as Number {
        var d = s.minuteOfDay - s.wakeMin;
        return d < 0 ? d + 1440 : d;
    }

    // rechargeRecovered: a rest/nap already cleared low recharge earlier today (kept by VitalsModel).
    function isLowRecharge(s as VitalsSnapshot, rechargeRecovered as Boolean) as Boolean {
        if (rechargeRecovered || !isAwake(s) || minutesSinceWake(s) < RECHARGE_GRACE_MIN) {
            return false;
        }
        var peak = s.bbPeakToday;
        if (peak == null || peak >= RECHARGE_MIN) {
            return false;
        }
        return !napped(s);
    }

    function napped(s as VitalsSnapshot) as Boolean {
        var gain = s.bbRecentGain;
        return gain != null && gain >= NAP_GAIN;
    }

    function isInactive(s as VitalsSnapshot) as Boolean {
        var level = s.moveBar;
        return isAwake(s) && level != null && level >= INACTIVE_LEVEL;
    }

    function isDeepInactive(s as VitalsSnapshot) as Boolean {
        var level = s.moveBar;
        return isAwake(s) && level != null && level >= DEEP_INACTIVE_LEVEL;
    }

    function energyState(s as VitalsSnapshot, rechargeRecovered as Boolean) as Number {
        if (!isAwake(s)) {
            return ENERGY_SLEEPING;
        }
        var low = isLowRecharge(s, rechargeRecovered);
        var still = isInactive(s);
        if (low && still) {
            return ENERGY_EXHAUSTED;
        } else if (still) {
            return ENERGY_INACTIVE;
        } else if (low) {
            return ENERGY_LOW_RECHARGE;
        }
        return ENERGY_RESTED;
    }

    function isMoving(s as VitalsSnapshot) as Boolean {
        var c = s.stepsPerMin;
        return c != null && c >= MOVING_CADENCE;
    }

    // HR elevation over resting in percent, or null without data.
    function hrPct(s as VitalsSnapshot) as Number? {
        var hr = s.heartRate;
        var rest = s.restingHr;
        if (hr == null || rest == null || rest <= 0) {
            return null;
        }
        return (hr - rest) * 100 / rest;
    }

    function calmState(s as VitalsSnapshot, prev as Number) as Number {
        var pct = hrPct(s);
        var stress = s.stress;
        if (isMoving(s)) {
            return (pct != null && pct >= ALERT_HR_PCT) ? CALM_EXERCISING : CALM_CALM;
        }
        var sustainedHr = s.hrSustainedPct;
        if (s.stressSustained || (sustainedHr != null && sustainedHr > STRESSED_HR_PCT)) {
            return CALM_STRESSED;
        }
        var stressUp = stress != null && stress >= ALERT_STRESS;
        var hrUp = pct != null && pct >= ALERT_HR_PCT;
        if (stressUp || hrUp) {
            return CALM_ALERT;
        }
        // Hysteresis: once tense, only "really calm" readings bring the monkey back.
        if (prev == CALM_ALERT || prev == CALM_STRESSED) {
            var stressCalm = stress == null || stress <= CALM_STRESS;
            var hrCalm = pct == null || pct <= CALM_HR_PCT;
            if (!(stressCalm && hrCalm)) {
                return CALM_ALERT;
            }
        }
        return CALM_CALM;
    }

    // 0..100 meters for the dashboard; null = no data.
    function energyMeter(s as VitalsSnapshot) as Number? {
        var bb = s.bodyBattery;
        if (bb != null) {
            return bb;
        }
        var level = s.moveBar;
        return (level != null) ? 100 - level * 20 : null;
    }

    function calmMeter(s as VitalsSnapshot) as Number? {
        var stress = s.stress;
        if (stress != null) {
            return 100 - stress;
        }
        var pct = hrPct(s);
        if (pct == null) {
            return null;
        }
        var v = 100 - pct * 2;
        return v < 0 ? 0 : (v > 100 ? 100 : v);
    }
}
