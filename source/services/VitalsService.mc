import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.UserProfile;

// Builds a VitalsSnapshot from data the watch records anyway (Body Battery, stress, wrist HR,
// move bar, steps). It never enables a sensor, so calling it costs only a few history reads.
// Permissions: SensorHistory (Body Battery, stress), UserProfile (resting HR, wake/sleep time).
(:background)
module VitalsService {

    const KEY_CADENCE = "vCadence"; // [steps, epoch seconds] from the previous snapshot
    const RECENT_SEC = 3 * 3600;      // window for the rest / nap gain
    const SUSTAIN_SEC = 6 * 60;       // "sustained" = every sample in the last ~5-6 minutes
    const SPO2_WINDOW_SEC = 4 * 3600; // Pulse Ox readings considered (awake part only)
    const COLD_WINDOW_SEC = 15 * 60;

    function snapshot() as VitalsSnapshot {
        var s = new VitalsSnapshot();
        var clock = System.getClockTime();
        s.minuteOfDay = clock.hour * 60 + clock.min;
        readProfile(s);

        var info = ActivityMonitor.getInfo();
        s.moveBar = info.moveBarLevel;
        if (info has :stressScore) {
            s.stress = validPct(info.stressScore);
        }
        s.stepsPerMin = cadence(info.steps);
        readHeartRate(s);
        readSensorHistory(s);
        readSpo2(s);
        readTemperature(s);
        return s;
    }

    function readProfile(s as VitalsSnapshot) as Void {
        var p = UserProfile.getProfile();
        var rest = null as Number?;
        if (p has :averageRestingHeartRate) {
            rest = p.averageRestingHeartRate;
        }
        if (rest == null || rest <= 0) {
            rest = p.restingHeartRate;
        }
        s.restingHr = (rest != null && rest > 0) ? rest : null;
        var wake = p.wakeTime;
        var sleep = p.sleepTime;
        if (wake != null && sleep != null) {
            s.wakeMin = (wake.value() / 60) % 1440;
            s.sleepMin = (sleep.value() / 60) % 1440;
        }
    }

    // Latest wrist HR and the lowest elevation over the last few minutes ("sustained").
    function readHeartRate(s as VitalsSnapshot) as Void {
        var it = ActivityMonitor.getHeartRateHistory(new Time.Duration(SUSTAIN_SEC), true);
        var latest = null as Number?;
        var lowest = null as Number?;
        var count = 0;
        var sample = it.next();
        while (sample != null) {
            var hr = sample.heartRate;
            if (hr != null && hr != ActivityMonitor.INVALID_HR_SAMPLE && hr > 0) {
                if (latest == null) {
                    latest = hr;
                }
                if (lowest == null || hr < lowest) {
                    lowest = hr;
                }
                count++;
            }
            sample = it.next();
        }
        s.heartRate = latest;
        var rest = s.restingHr;
        if (count >= 2 && lowest != null && rest != null) {
            s.hrSustainedPct = (lowest - rest) * 100 / rest;
        }
    }

    function readSensorHistory(s as VitalsSnapshot) as Void {
        if (!(Toybox has :SensorHistory)) {
            return;
        }
        var now = Time.now().value();
        if (SensorHistory has :getBodyBatteryHistory) {
            var minutes = s.minuteOfDay > 1 ? s.minuteOfDay : 1;
            var it = SensorHistory.getBodyBatteryHistory({
                :period => new Time.Duration(minutes * 60),
                :order => SensorHistory.ORDER_NEWEST_FIRST
            });
            var latest = null as Number?;
            var peak = null as Number?;
            var recentLow = null as Number?;
            var sample = it.next();
            while (sample != null) {
                var v = validPct(sample.data);
                if (v != null) {
                    if (latest == null) {
                        latest = v;
                    }
                    if (peak == null || v > peak) {
                        peak = v;
                    }
                    var when = sample.when;
                    if (when != null && now - when.value() <= RECENT_SEC && (recentLow == null || v < recentLow)) {
                        recentLow = v;
                    }
                }
                sample = it.next();
            }
            s.bodyBattery = latest;
            s.bbPeakToday = peak;
            if (latest != null && recentLow != null) {
                s.bbRecentGain = latest - recentLow;
            }
        }
        if (SensorHistory has :getStressHistory) {
            var it = SensorHistory.getStressHistory({
                :period => new Time.Duration(SUSTAIN_SEC),
                :order => SensorHistory.ORDER_NEWEST_FIRST
            });
            var count = 0;
            var allHigh = true;
            var sample = it.next();
            while (sample != null) {
                var v = validPct(sample.data);
                if (v != null) {
                    if (s.stress == null) {
                        s.stress = v;
                    }
                    count++;
                    if (v < Vitals.STRESS_HIGH) {
                        allHigh = false;
                    }
                }
                sample = it.next();
            }
            s.stressSustained = count >= 2 && allHigh;
        }
    }

    // Latest awake Pulse Ox reading and how many of the newest readings in a row are low.
    // Readings from before wake time are skipped (SpO2 is normally lower during sleep).
    function readSpo2(s as VitalsSnapshot) as Void {
        if (!(Toybox has :SensorHistory) || !(SensorHistory has :getOxygenSaturationHistory) || !Vitals.isAwake(s)) {
            return;
        }
        var awakeSec = Vitals.minutesSinceWake(s) * 60;
        var window = awakeSec < SPO2_WINDOW_SEC ? awakeSec : SPO2_WINDOW_SEC;
        if (window < 60) {
            return;
        }
        var it = SensorHistory.getOxygenSaturationHistory({
            :period => new Time.Duration(window),
            :order => SensorHistory.ORDER_NEWEST_FIRST
        });
        var streak = 0;
        var counting = true;
        var sample = it.next();
        while (sample != null) {
            var v = validPct(sample.data);
            if (v != null && v > 0) {
                if (s.spo2 == null) {
                    s.spo2 = v;
                }
                if (counting && v < Vitals.SPO2_OK) {
                    streak++;
                } else {
                    counting = false;
                }
            }
            sample = it.next();
        }
        s.spo2LowStreak = streak;
    }

    function readTemperature(s as VitalsSnapshot) as Void {
        if (!(Toybox has :SensorHistory) || !(SensorHistory has :getTemperatureHistory)) {
            return;
        }
        var it = SensorHistory.getTemperatureHistory({
            :period => new Time.Duration(COLD_WINDOW_SEC),
            :order => SensorHistory.ORDER_NEWEST_FIRST
        });
        var count = 0;
        var allCold = true;
        var sample = it.next();
        while (sample != null) {
            var d = sample.data;
            if (d != null) {
                var t = d.toNumber();
                if (s.tempC == null) {
                    s.tempC = t;
                }
                count++;
                if (t >= Vitals.COLD_C) {
                    allCold = false;
                }
            }
            sample = it.next();
        }
        s.coldSustained = count >= 2 && allCold;
    }

    // Steps per minute since the previous snapshot (1..35 min ago), else null.
    function cadence(steps as Number?) as Number? {
        if (steps == null) {
            return null;
        }
        var now = Time.now().value();
        var prev = Storage.getValue(KEY_CADENCE);
        Storage.setValue(KEY_CADENCE, [steps, now]);
        if (!(prev instanceof Array) || prev.size() != 2) {
            return null;
        }
        var prevSteps = prev[0];
        var prevTime = prev[1];
        if (!(prevSteps instanceof Number) || !(prevTime instanceof Number)) {
            return null;
        }
        var dt = now - prevTime;
        if (dt < 60 || dt > 35 * 60 || steps < prevSteps) {
            return null;
        }
        return (steps - prevSteps) * 60 / dt;
    }

    // Garmin reports invalid stress / Body Battery as negative or out-of-range values.
    function validPct(v as Numeric?) as Number? {
        if (v == null) {
            return null;
        }
        var n = v.toNumber();
        return (n >= 0 && n <= 100) ? n : null;
    }
}
