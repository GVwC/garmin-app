import Toybox.Application;
import Toybox.Lang;

// Persisted vitals state shared by the app and the background service:
// current Energy/Calm states, revive detection, and reminder ("nudge") rules.
//
// Nudge rules (all must pass):
//   - reminders enabled, user awake (profile wake/sleep window = quiet hours otherwise)
//   - at most MAX_NUDGES_PER_DAY per day and MIN_GAP_SEC between any two nudges
//   - the same kind again only after KIND_COOLDOWN_SEC; LOW_RECHARGE and GOAL once per day
//   - priority: EXHAUSTED > STRESSED > INACTIVE > LOW_RECHARGE > GOAL (midday, < 50 %)
// When the user looks at the app, markSeen() counts as a nudge for the active conditions,
// so the background never repeats what the user just read.
(:background)
class VitalsModel {

    static const EVENT_NONE = 0;
    static const EVENT_REVIVED = 1;
    static const EVENT_CALMED = 2;

    static const NUDGE_NONE = -1;
    static const NUDGE_EXHAUSTED = 0;
    static const NUDGE_STRESSED = 1;
    static const NUDGE_INACTIVE = 2;
    static const NUDGE_LOW_RECHARGE = 3;
    static const NUDGE_GOAL = 4;
    static const NUDGE_KINDS = 5;

    static const MAX_REVIVES_PER_DAY = 3;
    static const MAX_NUDGES_PER_DAY = 6;
    static const MIN_GAP_SEC = 45 * 60;
    static const KIND_COOLDOWN_SEC = 2 * 3600;
    static const GOAL_NUDGE_MINUTE = 13 * 60;

    // Epoch seconds, refreshed by the app while the dashboard is visible, 0 when hidden.
    static const KEY_FG_SEEN = "fgSeen";

    private static const KEY_STATE = "vState";   // [day, energy, calm, recoveredDay, revivesToday, pendingRevives]
    private static const KEY_NUDGES = "vNudges"; // [lastAny, countToday, at0..at4]
    private static const KEY_ENABLED = "vEnabled";

    private var _day as Number = -1;
    private var _energy as Number = Vitals.ENERGY_RESTED;
    private var _calm as Number = Vitals.CALM_CALM;
    private var _recoveredDay as Number = -1;
    private var _revivesToday as Number = 0;
    private var _pendingRevives as Number = 0;

    private var _lastNudge as Number = 0;
    private var _nudgesToday as Number = 0;
    private var _nudgeAt as Array<Number> = [0, 0, 0, 0, 0];
    private var _enabled as Boolean = true;
    private var _persist as Boolean = false;

    function initialize() {
    }

    // Evaluates a snapshot. Returns EVENT_REVIVED when energy fully recovers from a tired
    // state, EVENT_CALMED when stress clears.
    function apply(s as VitalsSnapshot, today as Number) as Number {
        if (today != _day) {
            // New day: yesterday's tiredness never counts as today's revive.
            _day = today;
            _energy = Vitals.ENERGY_RESTED;
            _calm = Vitals.CALM_CALM;
            _revivesToday = 0;
        }
        var wasLow = _energy == Vitals.ENERGY_LOW_RECHARGE || _energy == Vitals.ENERGY_EXHAUSTED;
        if (wasLow && _recoveredDay != today && Vitals.napped(s)) {
            _recoveredDay = today;
        }
        var energy = Vitals.energyState(s, _recoveredDay == today);
        var calm = Vitals.calmState(s, _calm);

        var event = EVENT_NONE;
        var wasTired = _energy == Vitals.ENERGY_INACTIVE || _energy == Vitals.ENERGY_EXHAUSTED
            || _energy == Vitals.ENERGY_LOW_RECHARGE;
        if (wasTired && energy == Vitals.ENERGY_RESTED) {
            event = EVENT_REVIVED;
            if (_revivesToday < MAX_REVIVES_PER_DAY) {
                _revivesToday++;
                _pendingRevives++;
            }
        } else if (_calm == Vitals.CALM_STRESSED && calm == Vitals.CALM_CALM) {
            event = EVENT_CALMED;
        }
        _energy = energy;
        _calm = calm;
        save();
        return event;
    }

    function getEnergy() as Number {
        return _energy;
    }

    function getCalm() as Number {
        return _calm;
    }

    // Revives not yet turned into XP (the background can detect them while the app is closed).
    function takePendingRevives() as Number {
        var n = _pendingRevives;
        if (n > 0) {
            _pendingRevives = 0;
            save();
        }
        return n;
    }

    // ---------- nudges ----------

    function isEnabled() as Boolean {
        return _enabled;
    }

    function setEnabled(on as Boolean) as Void {
        _enabled = on;
        save();
    }

    // Conditions that would be worth a nudge right now, in priority order.
    function activeKinds(s as VitalsSnapshot, goalPermille as Number?) as Array<Number> {
        var kinds = [] as Array<Number>;
        if (_energy == Vitals.ENERGY_EXHAUSTED) {
            kinds.add(NUDGE_EXHAUSTED);
        }
        if (_calm == Vitals.CALM_STRESSED) {
            kinds.add(NUDGE_STRESSED);
        }
        if (_energy == Vitals.ENERGY_INACTIVE) {
            kinds.add(NUDGE_INACTIVE);
        }
        if (_energy == Vitals.ENERGY_LOW_RECHARGE) {
            kinds.add(NUDGE_LOW_RECHARGE);
        }
        if (s.minuteOfDay >= GOAL_NUDGE_MINUTE && goalPermille != null && goalPermille < 500) {
            kinds.add(NUDGE_GOAL);
        }
        return kinds;
    }

    // Picks the nudge to send now (and records it), or NUDGE_NONE. now = epoch seconds.
    function pickNudge(s as VitalsSnapshot, goalPermille as Number?, now as Number) as Number {
        if (!_enabled || !Vitals.isAwake(s)) {
            return NUDGE_NONE;
        }
        var startOfDay = now - s.minuteOfDay * 60;
        if (_lastNudge < startOfDay) {
            _nudgesToday = 0;
        }
        if (_nudgesToday >= MAX_NUDGES_PER_DAY || now - _lastNudge < MIN_GAP_SEC) {
            return NUDGE_NONE;
        }
        var kinds = activeKinds(s, goalPermille);
        for (var i = 0; i < kinds.size(); i++) {
            var kind = kinds[i];
            var at = _nudgeAt[kind];
            var oncePerDay = kind == NUDGE_LOW_RECHARGE || kind == NUDGE_GOAL;
            var blocked = oncePerDay ? (at >= startOfDay) : (now - at < KIND_COOLDOWN_SEC);
            if (!blocked) {
                _nudgeAt[kind] = now;
                _lastNudge = now;
                _nudgesToday++;
                save();
                return kind;
            }
        }
        return NUDGE_NONE;
    }

    // The user has seen the dashboard: treat the visible conditions as already nudged.
    function markSeen(s as VitalsSnapshot, goalPermille as Number?, now as Number) as Void {
        var kinds = activeKinds(s, goalPermille);
        if (kinds.size() == 0) {
            return;
        }
        for (var i = 0; i < kinds.size(); i++) {
            _nudgeAt[kinds[i]] = now;
        }
        _lastNudge = now;
        save();
    }

    // ---------- persistence ----------

    function load() as Void {
        _persist = true;
        var st = Storage.getValue(KEY_STATE);
        if (st instanceof Array && st.size() == 6) {
            _day = num(st[0], -1);
            _energy = num(st[1], Vitals.ENERGY_RESTED);
            _calm = num(st[2], Vitals.CALM_CALM);
            _recoveredDay = num(st[3], -1);
            _revivesToday = num(st[4], 0);
            _pendingRevives = num(st[5], 0);
        }
        var nd = Storage.getValue(KEY_NUDGES);
        if (nd instanceof Array && nd.size() == 2 + NUDGE_KINDS) {
            _lastNudge = num(nd[0], 0);
            _nudgesToday = num(nd[1], 0);
            for (var i = 0; i < NUDGE_KINDS; i++) {
                _nudgeAt[i] = num(nd[2 + i], 0);
            }
        }
        var en = Storage.getValue(KEY_ENABLED);
        _enabled = (en instanceof Boolean) ? en : true;
    }

    function save() as Void {
        if (!_persist) {
            return;
        }
        Storage.setValue(KEY_STATE, [_day, _energy, _calm, _recoveredDay, _revivesToday, _pendingRevives]);
        var nd = [_lastNudge, _nudgesToday] as Array<Storage.ValueType>;
        for (var i = 0; i < NUDGE_KINDS; i++) {
            nd.add(_nudgeAt[i]);
        }
        Storage.setValue(KEY_NUDGES, nd);
        Storage.setValue(KEY_ENABLED, _enabled);
    }

    private static function num(v as Object?, fallback as Number) as Number {
        return (v instanceof Number) ? v : fallback;
    }
}
