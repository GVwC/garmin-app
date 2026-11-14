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
    var bbAgeMin as Number? = null;     // minutes since the newest Body Battery sample (null = unknown)
    var moveBar as Number? = null;      // Garmin move bar level, 0..5 (1 = 60 min still, +1 per 15 min)
    var stress as Number? = null;       // Garmin stress 0..100 (not computed during activity)
    var stressSustained as Boolean = false; // every stress sample of the last ~5 min >= STRESS_HIGH
    var heartRate as Number? = null;    // latest wrist HR sample
    var restingHr as Number? = null;    // personal resting HR baseline
    var hrSustainedPct as Number? = null; // lowest HR elevation % over the last ~5 min
    var stepsPerMin as Number? = null;  // recent cadence; null if unknown
    var spo2 as Number? = null;         // latest Pulse Ox reading while awake (only if the user enabled Pulse Ox)
    var spo2LowStreak as Number = 0;    // newest consecutive readings below SPO2_OK
    var tempC as Number? = null;        // latest watch temperature (wrist-biased: reads warmer than the air)
    var coldSustained as Boolean = false; // every temperature sample of the last ~15 min < COLD_C

    function initialize() {
    }
}

// Energy and Calm state machines. Pure functions: same snapshot + previous state -> same result.
//
// Energy (movement + recharge)
//   SLEEPING       outside the user's wake window (night): monkey sleeps, no nudges
//   LOW_RECHARGE   "low morning recharge": today's Body Battery peak < RECHARGE_MIN. Not a sleep
//                  measurement (this watch exposes no sleep data to apps). Needs fresh history
//                  (newest sample <= BB_FRESH_MIN old). Clears after a rest/nap gain or tomorrow.
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
// Breath (Pulse Ox, read-only: apps cannot trigger a measurement; never diagnostic)
//   NORMAL >= 95 % · LOW 90-94 % (single reading) · CONCERNING < 90 % or low on 2+ readings in a row
// Warmth (watch temperature sensor; on the wrist it reads several degrees above the air)
//   COLD           every reading of the last ~15 min below COLD_C (only real cold gets the wrist that low)
//   HOT            reading >= HOT_C and HR raised without movement
// Curiosity (daily distance / floors vs the last 7 days; no GPS)
//   CLIMB          climb milestone from Garmin's floors count (barometric, firmware-filtered):
//                  >= CLIMB_MILESTONE_FLOORS today, or a new 7-day floors best of >= 5
//   ADVENTUROUS    distance record: today beats the 7-day best distance (>= 3 km)
//   ROUTINE        last 3 days nearly identical distance (+-15 %) and almost no floors
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

    const BREATH_NORMAL = 0;
    const BREATH_LOW = 1;
    const BREATH_CONCERNING = 2;

    const WARMTH_OK = 0;
    const WARMTH_COLD = 1;
    const WARMTH_HOT = 2;

    const CURIOUS_CONTENT = 0;
    const CURIOUS_ROUTINE = 1;
    const CURIOUS_ADVENTUROUS = 2; // distance record
    const CURIOUS_CLIMB = 3;       // climb milestone (floors)

    // Thresholds (tune here).
    const RECHARGE_MIN = 50;       // Body Battery peak below this = low recharge
    const RECHARGE_GRACE_MIN = 60; // judge recharge only 1 h after wake time
    const NAP_GAIN = 10;           // Body Battery gain that counts as a recovering rest
    const BB_FRESH_MIN = 120;      // older Body Battery history is not trusted for recharge
    const INACTIVE_LEVEL = 3;      // move bar level ~ 90 min still
    const DEEP_INACTIVE_LEVEL = 5; // ~ 2 h still: monkey falls asleep sitting up
    const MOVING_CADENCE = 60;     // steps/min that count as moving
    const STRESS_HIGH = 76;        // Garmin "high stress" band
    const ALERT_STRESS = 51;       // Garmin "medium stress" band
    const CALM_STRESS = 40;
    const ALERT_HR_PCT = 15;
    const STRESSED_HR_PCT = 25;
    const CALM_HR_PCT = 5;
    const SPO2_OK = 95;
    const SPO2_LOW = 90;
    const COLD_C = 10;
    const HOT_C = 35;
    const EXPLORE_MIN_CM = 300000; // 3 km (ActivityMonitor distance is in cm)
    const EXPLORE_MIN_FLOORS = 5;
    const CLIMB_MILESTONE_FLOORS = 10; // ~30 m of climbing in a day
    const ROUTINE_SPREAD_PCT = 15;
    const ROUTINE_MAX_FLOORS = 2;

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
        // Missing or stale history never triggers low recharge by itself.
        var age = s.bbAgeMin;
        if (age == null || age > BB_FRESH_MIN) {
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

    // ---------- Breath ----------

    function breathState(s as VitalsSnapshot) as Number {
        var v = s.spo2;
        if (v == null || v >= SPO2_OK) {
            return BREATH_NORMAL;
        }
        if (v < SPO2_LOW || s.spo2LowStreak >= 2) {
            return BREATH_CONCERNING;
        }
        return BREATH_LOW;
    }

    // ---------- Warmth ----------

    function warmthState(s as VitalsSnapshot) as Number {
        if (s.coldSustained) {
            return WARMTH_COLD;
        }
        var t = s.tempC;
        var pct = hrPct(s);
        if (t != null && t >= HOT_C && !isMoving(s) && pct != null && pct >= ALERT_HR_PCT) {
            return WARMTH_HOT;
        }
        return WARMTH_OK;
    }

    // ---------- Curiosity ----------

    // past: finished days, newest first, as [distanceCm, floors] (null values allowed).
    function curiosityState(todayCm as Number?, todayFloors as Number?, past as Array<Array<Number?> >) as Number {
        if (todayFloors != null && todayFloors >= CLIMB_MILESTONE_FLOORS) {
            return CURIOUS_CLIMB;
        }
        if (past.size() < 3) {
            return CURIOUS_CONTENT;
        }
        var bestCm = 0;
        var bestFloors = 0;
        for (var i = 0; i < past.size(); i++) {
            var d = past[i][0];
            var f = past[i][1];
            if (d != null && d > bestCm) {
                bestCm = d;
            }
            if (f != null && f > bestFloors) {
                bestFloors = f;
            }
        }
        if (todayFloors != null && todayFloors > bestFloors && todayFloors >= EXPLORE_MIN_FLOORS) {
            return CURIOUS_CLIMB;
        }
        if (todayCm != null && todayCm > bestCm && todayCm >= EXPLORE_MIN_CM) {
            return CURIOUS_ADVENTUROUS;
        }
        // Routine: the last three days look the same.
        var lo = null as Number?;
        var hi = null as Number?;
        for (var i = 0; i < 3; i++) {
            var d = past[i][0];
            var f = past[i][1];
            if (d == null || d <= 0 || (f != null && f > ROUTINE_MAX_FLOORS)) {
                return CURIOUS_CONTENT;
            }
            if (lo == null || d < lo) {
                lo = d;
            }
            if (hi == null || d > hi) {
                hi = d;
            }
        }
        if (lo != null && hi != null && (hi - lo) * 100 <= hi * ROUTINE_SPREAD_PCT) {
            return CURIOUS_ROUTINE;
        }
        return CURIOUS_CONTENT;
    }
}
