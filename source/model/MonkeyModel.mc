import Toybox.Application;
import Toybox.Lang;

// Monkey Miles state: one daily goal, XP, the once-per-day reward and demo mode.
// Days are local day numbers (see DayClock). No WatchUi/Graphics here, so it is unit-testable.
//
// XP rules
//   - Reaching today's goal (live): +XP_GOAL once per day, celebration plays once.
//   - Each finished day since the last check is settled from watch history:
//     goal met -> +XP_GOAL (unless already rewarded live), missed -> -XP_MISS, no data -> nothing.
//   - XP never drops below 0. Level = 1 + xp / XP_PER_LEVEL.
// Demo mode works on a copy of XP and never touches stored state.
// Nothing is written to storage until load() has been called (the app does; unit tests don't).
class MonkeyModel {

    static const GOAL_STEPS = 0;
    static const GOAL_ACTIVE = 1;
    static const GOAL_FLOORS = 2;
    static const GOAL_TYPES = 3;

    static const POSE_RELAX = 0;
    static const POSE_PERK = 1;
    static const POSE_EAT = 2;

    static const XP_GOAL = 100;
    static const XP_MISS = 50;
    static const XP_PER_LEVEL = 300;
    static const MAX_CATCH_UP_DAYS = 7;

    static const DEMO_STAGES = 4;
    static const DEMO_MISSED = 3;

    private static const KEY_TYPE = "goalType";
    private static const KEY_TARGET = "goalTarget";
    private static const KEY_XP = "xp";
    private static const KEY_REWARD_DAY = "rewardDay";
    private static const KEY_EVAL_DAY = "lastEvalDay";

    // Persisted (live only).
    private var _goalType as Number = GOAL_STEPS;
    private var _target as Number = 5000;
    private var _xp as Number = 0;
    private var _rewardDay as Number? = null;
    private var _lastEvalDay as Number? = null;

    private var _persist as Boolean = false;

    // Live reading.
    private var _today as Number = 0;
    private var _value as Number? = null;

    // Demo.
    private var _demo as Boolean = false;
    private var _demoStage as Number = 0;
    private var _demoXp as Number = 0;

    // One-shot event for the view: XP change to announce, celebration, level up.
    private var _eventXp as Number = 0;
    private var _eventCelebrate as Boolean = false;
    private var _eventLevelUp as Boolean = false;

    function initialize() {
    }

    // ---------- goals ----------

    static function targetsFor(goalType as Number) as Array<Number> {
        if (goalType == GOAL_ACTIVE) {
            return [10, 20, 30, 60];
        } else if (goalType == GOAL_FLOORS) {
            return [5, 10, 15, 25];
        }
        return [1000, 3000, 5000, 10000];
    }

    static function defaultTarget(goalType as Number) as Number {
        return targetsFor(goalType)[2];
    }

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
            announce(_xp - before, false, levelOf(_xp) > levelOf(before));
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
        announce(XP_GOAL, true, levelOf(_xp) > levelOf(before));
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

    // Demo starts fresh at 20 % with a copy of the live XP.
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

    // 20 % -> 65 % -> 100 % (+XP, celebration) -> missed day (-XP) -> 20 % ...
    function nextDemoStage() as Void {
        if (!_demo) {
            return;
        }
        _demoStage = (_demoStage + 1) % DEMO_STAGES;
        var before = _demoXp;
        if (_demoStage == 2) {
            _demoXp += XP_GOAL;
            announce(XP_GOAL, true, levelOf(_demoXp) > levelOf(before));
        } else if (_demoStage == DEMO_MISSED) {
            _demoXp = clampXp(_demoXp - XP_MISS);
            announce(_demoXp - before, false, false);
        } else {
            clearEvent();
        }
    }

    function getDemoStage() as Number {
        return _demoStage;
    }

    static function demoPercent(stage as Number) as Number {
        return [20, 65, 100, 35][stage];
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

    private function announce(xp as Number, celebrate as Boolean, levelUp as Boolean) as Void {
        _eventXp = xp;
        _eventCelebrate = celebrate;
        _eventLevelUp = levelUp;
    }

    private function clearEvent() as Void {
        announce(0, false, false);
    }

    // The view takes the event once; returns [xpDelta, celebrate, levelUp] or null.
    function takeEvent() as [Number, Boolean, Boolean]? {
        if (_eventXp == 0 && !_eventCelebrate) {
            return null;
        }
        var e = [_eventXp, _eventCelebrate, _eventLevelUp] as [Number, Boolean, Boolean];
        clearEvent();
        return e;
    }

    // ---------- persistence (live only) ----------

    function load() as Void {
        _persist = true;
        _goalType = readNumber(KEY_TYPE, GOAL_STEPS);
        if (_goalType < 0 || _goalType >= GOAL_TYPES) {
            _goalType = GOAL_STEPS;
        }
        _target = readNumber(KEY_TARGET, defaultTarget(_goalType));
        _xp = clampXp(readNumber(KEY_XP, 0));
        _rewardDay = readOptional(KEY_REWARD_DAY);
        _lastEvalDay = readOptional(KEY_EVAL_DAY);
    }

    function save() as Void {
        if (_demo || !_persist) {
            return;
        }
        Storage.setValue(KEY_TYPE, _goalType);
        Storage.setValue(KEY_TARGET, _target);
        Storage.setValue(KEY_XP, _xp);
        Storage.setValue(KEY_REWARD_DAY, _rewardDay);
        Storage.setValue(KEY_EVAL_DAY, _lastEvalDay);
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
