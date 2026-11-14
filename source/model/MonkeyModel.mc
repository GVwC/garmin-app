import Toybox.Application;
import Toybox.Lang;

// Monkey Miles game state: one daily goal, XP and levels, bonuses, and the scripted demo.
// Days are local day numbers (see DayClock). No WatchUi/Graphics here, so it is unit-testable.
//
// XP rules
//   - Reaching today's goal (live): +XP_GOAL once per day, celebration plays once.
//   - Each finished day since the last check is settled from watch history:
//     goal met -> +XP_GOAL (unless already rewarded live), missed -> -XP_MISS, no data -> nothing.
//   - Bonuses: revived from tiredness +XP_REVIVE (max 3/day, counted by VitalsModel),
//     a finished breathing session +XP_BREATH once per day.
//   - XP never drops below 0. Level = 1 + xp / XP_PER_LEVEL.
// Demo mode works on a copy of XP and never touches stored state.
// Nothing is written to storage until load() has been called (the app does; unit tests don't).
class MonkeyModel {

    static const POSE_RELAX = 0;
    static const POSE_PERK = 1;
    static const POSE_EAT = 2;

    static const XP_GOAL = 100;
    static const XP_MISS = 50;
    static const XP_REVIVE = 20;
    static const XP_BREATH = 10;
    static const XP_PER_LEVEL = 300;
    static const MAX_CATCH_UP_DAYS = 7;

    // Event kinds for the banner.
    static const EV_GOAL = 0;
    static const EV_MISSED = 1;
    static const EV_REVIVE = 2;
    static const EV_BREATH = 3;

    private static const KEY_REWARD_DAY = "rewardDay";
    private static const KEY_EVAL_DAY = "lastEvalDay";
    private static const KEY_BREATH_DAY = "breathDay";

    // Persisted (live only).
    private var _goalType as Number = Goals.GOAL_STEPS;
    private var _target as Number = 5000;
    private var _xp as Number = 0;
    private var _rewardDay as Number? = null;
    private var _lastEvalDay as Number? = null;
    private var _breathDay as Number? = null;

    private var _persist as Boolean = false;

    // Live reading.
    private var _today as Number = 0;
    private var _value as Number? = null;

    // Demo.
    private var _demo as Boolean = false;
    private var _demoStage as Number = 0;
    private var _demoXp as Number = 0;

    // One-shot event for the view: XP change to announce, celebration, level up, kind.
    private var _eventXp as Number = 0;
    private var _eventCelebrate as Boolean = false;
    private var _eventLevelUp as Boolean = false;
    private var _eventKind as Number = EV_GOAL;
    private var _eventPending as Boolean = false;

    function initialize() {
    }

    // ---------- goals ----------

    function getGoalType() as Number {
        return _goalType;
    }

    function getTarget() as Number {
        return _target;
    }

    // Changing the goal mid-day never takes XP away; a newly met goal is rewarded now.
    function setGoal(goalType as Number, target as Number) as Void {
        _goalType = goalType;
        _target = target;
        if (!_demo) {
            save();
            checkReward();
        }
    }

    // ---------- live data ----------

    // today: local day number. value: today's total (null = unavailable).
    // history: finished days as [day, value or null], any order.
    function update(today as Number, value as Number?, history as Array<Array<Number?> >) as Void {
        _today = today;
        _value = value;
        if (_demo) {
            return;
        }
        settleFinishedDays(today, history);
        checkReward();
    }

    function settleFinishedDays(today as Number, history as Array<Array<Number?> >) as Void {
        var last = _lastEvalDay;
        if (last == null) {
            // First run: start counting from today, no retroactive XP.
            _lastEvalDay = today - 1;
            save();
            return;
        }
        if (last >= today - 1) {
            return;
        }
        var first = last + 1;
        if (first < today - MAX_CATCH_UP_DAYS) {
            first = today - MAX_CATCH_UP_DAYS;
        }
        var before = _xp;
        var delta = 0;
        for (var day = first; day < today; day++) {
            if (_rewardDay != null && day == _rewardDay) {
                continue;
            }
            var v = valueForDay(history, day);
            if (v == null) {
                continue;
            }
            delta += (v >= _target) ? XP_GOAL : -XP_MISS;
        }
        _lastEvalDay = today - 1;
        if (delta != 0) {
            _xp = clampXp(_xp + delta);
            announce(_xp - before, false, levelOf(_xp) > levelOf(before), delta > 0 ? EV_GOAL : EV_MISSED);
        }
        save();
    }

    private function checkReward() as Void {
        var v = _value;
        if (v == null || v < _target) {
            return;
        }
        if (_rewardDay != null && _rewardDay == _today) {
            return;
        }
        var before = _xp;
        _xp += XP_GOAL;
        _rewardDay = _today;
        save();
        announce(XP_GOAL, true, levelOf(_xp) > levelOf(before), EV_GOAL);
    }

    // ---------- bonuses ----------

    // Revives are already capped per day by VitalsModel.
    function addReviveBonus() as Void {
        addXp(XP_REVIVE, EV_REVIVE);
    }

    // Once per day; returns true when XP was awarded.
    function addBreathBonus() as Boolean {
        if (_demo) {
            addXp(XP_BREATH, EV_BREATH);
            return true;
        }
        if (_breathDay != null && _breathDay == _today) {
            return false;
        }
        _breathDay = _today;
        addXp(XP_BREATH, EV_BREATH);
        return true;
    }

    private function addXp(xp as Number, kind as Number) as Void {
        var before = getXp();
        if (_demo) {
            _demoXp += xp;
        } else {
            _xp += xp;
            save();
        }
        announce(xp, false, levelOf(getXp()) > levelOf(before), kind);
    }

    private static function valueForDay(history as Array<Array<Number?> >, day as Number) as Number? {
        for (var i = 0; i < history.size(); i++) {
            var entry = history[i];
            if (entry.size() >= 2 && entry[0] != null && entry[0] == day) {
                return entry[1];
            }
        }
        return null;
    }

    // ---------- demo ----------

    function isDemo() as Boolean {
        return _demo;
    }

    // Demo starts fresh at stage 0 with a copy of the live XP.
    function enterDemo() as Void {
        _demo = true;
        _demoStage = 0;
        _demoXp = _xp;
        clearEvent();
    }

    function exitDemo() as Void {
        _demo = false;
        clearEvent();
        checkReward();
    }

    // Walks the DemoScenarios table. Effects (+XP, -XP, celebration) only play going forward.
    function nextDemoStage() as Void {
        if (!_demo) {
            return;
        }
        _demoStage = (_demoStage + 1) % DemoScenarios.COUNT;
        clearEvent();
        var effect = DemoScenarios.row(_demoStage)[DemoScenarios.EFFECT];
        var before = _demoXp;
        if (effect == DemoScenarios.EFFECT_GOAL) {
            _demoXp += XP_GOAL;
            announce(XP_GOAL, true, levelOf(_demoXp) > levelOf(before), EV_GOAL);
        } else if (effect == DemoScenarios.EFFECT_MISSED) {
            _demoXp = clampXp(_demoXp - XP_MISS);
            announce(_demoXp - before, false, false, EV_MISSED);
        } else if (effect == DemoScenarios.EFFECT_REVIVE) {
            addXp(XP_REVIVE, EV_REVIVE);
        }
    }

    function prevDemoStage() as Void {
        if (!_demo) {
            return;
        }
        _demoStage = (_demoStage + DemoScenarios.COUNT - 1) % DemoScenarios.COUNT;
        clearEvent();
    }

    function getDemoStage() as Number {
        return _demoStage;
    }

    static function demoPercent(stage as Number) as Number {
        return DemoScenarios.row(stage)[DemoScenarios.PERCENT];
    }

    // ---------- derived state for the view ----------

    // Current value shown on screen (demo: a share of the goal).
    function getValue() as Number? {
        if (_demo) {
            return _target * demoPercent(_demoStage) / 100;
        }
        return _value;
    }

    // 0..1000+ (can exceed 1000 when over the goal).
    function getProgressPermille() as Number {
        var v = getValue();
        if (v == null || _target <= 0) {
            return 0;
        }
        return v * 1000 / _target;
    }

    function getPose() as Number {
        var p = getProgressPermille();
        if (p >= 1000) {
            return POSE_EAT;
        } else if (p >= 500) {
            return POSE_PERK;
        }
        return POSE_RELAX;
    }

    function getXp() as Number {
        return _demo ? _demoXp : _xp;
    }

    function getLevel() as Number {
        return levelOf(getXp());
    }

    // Progress inside the current level, 0..999.
    function getLevelPermille() as Number {
        return (getXp() % XP_PER_LEVEL) * 1000 / XP_PER_LEVEL;
    }

    static function levelOf(xp as Number) as Number {
        return 1 + xp / XP_PER_LEVEL;
    }

    private static function clampXp(xp as Number) as Number {
        return xp < 0 ? 0 : xp;
    }

    // ---------- one-shot events ----------

    private function announce(xp as Number, celebrate as Boolean, levelUp as Boolean, kind as Number) as Void {
        _eventXp = xp;
        _eventCelebrate = celebrate;
        _eventLevelUp = levelUp;
        _eventKind = kind;
        _eventPending = xp != 0 || celebrate;
    }

    private function clearEvent() as Void {
        _eventPending = false;
        _eventXp = 0;
        _eventCelebrate = false;
        _eventLevelUp = false;
    }

    // The view takes the event once; returns [xpDelta, celebrate, levelUp, kind] or null.
    function takeEvent() as [Number, Boolean, Boolean, Number]? {
        if (!_eventPending) {
            return null;
        }
        var e = [_eventXp, _eventCelebrate, _eventLevelUp, _eventKind] as [Number, Boolean, Boolean, Number];
        clearEvent();
        return e;
    }

    // ---------- persistence (live only) ----------

    function load() as Void {
        _persist = true;
        _goalType = readNumber(Goals.KEY_TYPE, Goals.GOAL_STEPS);
        if (_goalType < 0 || _goalType >= Goals.GOAL_TYPES) {
            _goalType = Goals.GOAL_STEPS;
        }
        _target = readNumber(Goals.KEY_TARGET, Goals.defaultTarget(_goalType));
        _xp = clampXp(readNumber(Goals.KEY_XP, 0));
        _rewardDay = readOptional(KEY_REWARD_DAY);
        _lastEvalDay = readOptional(KEY_EVAL_DAY);
        _breathDay = readOptional(KEY_BREATH_DAY);
    }

    function save() as Void {
        if (_demo || !_persist) {
            return;
        }
        Storage.setValue(Goals.KEY_TYPE, _goalType);
        Storage.setValue(Goals.KEY_TARGET, _target);
        Storage.setValue(Goals.KEY_XP, _xp);
        Storage.setValue(KEY_REWARD_DAY, _rewardDay);
        Storage.setValue(KEY_EVAL_DAY, _lastEvalDay);
        Storage.setValue(KEY_BREATH_DAY, _breathDay);
    }

    private static function readNumber(key as String, fallback as Number) as Number {
        var v = Storage.getValue(key);
        return (v instanceof Number) ? v : fallback;
    }

    private static function readOptional(key as String) as Number? {
        var v = Storage.getValue(key);
        return (v instanceof Number) ? v : null;
    }
}
