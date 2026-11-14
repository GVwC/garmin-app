import Toybox.Application;
import Toybox.Lang;

// Monkey Miles game state: the character (fur, created), the goals that give XP, XP and
// levels, streaks, bonuses and the scripted demo. Days are local day numbers (DayClock).
// No WatchUi/Graphics here, so it is unit-testable.
//
// Goals: any of Steps / Active minutes / Floors can be switched on, each with its own target.
// One of them is "shown" on the dashboard (UP/DOWN cycles); the pose uses all of them.
// XP rules
//   - Each enabled goal reached today (live): +XP_GOAL once per day; celebration plays.
//   - Finished days since the last check are settled from watch history, per enabled goal:
//     met -> +XP_GOAL (unless already rewarded live), missed -> -XP_MISS, no data -> nothing.
//   - Streak: consecutive days with every enabled goal met. Completing today on a streak of
//     2+ days adds XP_STREAK x min(streak, 5).
//   - Bonuses: revived +XP_REVIVE (max 3/day, counted by VitalsModel), breathing session
//     +XP_BREATH once per day, new territory +XP_EXPLORE once per day.
//   - XP never drops below 0. Level = 1 + xp / XP_PER_LEVEL.
// Demo mode works on a copy of XP and never touches stored state.
// Nothing is written to storage until load() has been called (the app does; unit tests don't).
class MonkeyModel {

    static const POSE_RELAX = 0;
    static const POSE_PERK = 1;
    static const POSE_EAT = 2;

    static const XP_GOAL = 100;
    static const XP_MISS = 50;
    static const XP_STREAK = 10;
    static const MAX_STREAK_MULT = 5;
    static const XP_REVIVE = 20;
    static const XP_BREATH = 10;
    static const XP_EXPLORE = 30;
    static const XP_PER_LEVEL = 300;
    static const MAX_CATCH_UP_DAYS = 7;

    static const FUR_COUNT = 4;
    static const NAME_COUNT = 5;

    // Event kinds for the banner.
    static const EV_GOAL = 0;
    static const EV_MISSED = 1;
    static const EV_REVIVE = 2;
    static const EV_BREATH = 3;
    static const EV_EXPLORE = 4;

    private static const KEY_ON = "goalsOn";
    private static const KEY_TARGETS = "goalTargets";
    private static const KEY_REWARDS = "rewardDays";
    private static const KEY_EVAL_DAY = "lastEvalDay";
    private static const KEY_BREATH_DAY = "breathDay";
    private static const KEY_EXPLORE_DAY = "exploreDay";
    private static const KEY_STREAK = "streak";        // [finished-day streak, bonus day]
    private static const KEY_CHARACTER = "character";  // [created 0/1, fur, name]

    // Persisted (live only).
    private var _on as Array<Boolean> = [true, false, false];
    private var _targets as Array<Number> = [5000, 30, 15];
    private var _rewardDays as Array<Number> = [-1, -1, -1];
    private var _shown as Number = Goals.GOAL_STEPS;
    private var _xp as Number = 0;
    private var _lastEvalDay as Number? = null;
    private var _breathDay as Number = -1;
    private var _exploreDay as Number = -1;
    private var _streak as Number = 0;
    private var _streakBonusDay as Number = -1;
    private var _created as Boolean = false;
    private var _fur as Number = 0;
    private var _name as Number = 0;

    private var _persist as Boolean = false;

    // Last settled missed day, for the recap screen (not persisted).
    private var _lostStreak as Number = 0;
    private var _missPercent as Number = 0;

    // Live readings, index = goal type.
    private var _today as Number = 0;
    private var _values as Array<Number?> = [null, null, null];

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

    // ---------- character ----------

    function isCreated() as Boolean {
        return _created;
    }

    function setCreated() as Void {
        _created = true;
        save();
    }

    // Index into the name list (strings Name0..Name4).
    function getName() as Number {
        return _name;
    }

    function setName(name as Number) as Void {
        _name = (name >= 0 && name < NAME_COUNT) ? name : 0;
        save();
    }

    // Start over with a fresh egg: wipes the stored monkey (XP, goals, streak, vitals state).
    function newGame() as Void {
        if (_persist) {
            Storage.clearValues();
        }
        _on = [true, false, false];
        _targets = [5000, 30, 15];
        _rewardDays = [-1, -1, -1];
        _shown = Goals.GOAL_STEPS;
        _xp = 0;
        _lastEvalDay = null;
        _breathDay = -1;
        _exploreDay = -1;
        _streak = 0;
        _streakBonusDay = -1;
        _created = false;
        _fur = 0;
        _name = 0;
        _demo = false;
        clearEvent();
    }

    function getFur() as Number {
        return _fur;
    }

    function setFur(fur as Number) as Void {
        _fur = (fur >= 0 && fur < FUR_COUNT) ? fur : 0;
        save();
    }

    // ---------- goals ----------

    function isGoalOn(goalType as Number) as Boolean {
        return _on[goalType];
    }

    function enabledGoals() as Array<Number> {
        var out = [] as Array<Number>;
        for (var t = 0; t < Goals.GOAL_TYPES; t++) {
            if (_on[t]) {
                out.add(t);
            }
        }
        return out;
    }

    // At least one goal always stays on.
    function setGoalOn(goalType as Number, on as Boolean) as Void {
        if (!on && enabledGoals().size() <= 1 && _on[goalType]) {
            return;
        }
        _on[goalType] = on;
        if (!_on[_shown]) {
            _shown = enabledGoals()[0];
        }
        if (!_demo) {
            save();
            checkRewards();
        }
    }

    // Sets the target, switches the goal on and shows it. A newly met goal is rewarded now;
    // changing a goal mid-day never takes XP away.
    function setGoal(goalType as Number, target as Number) as Void {
        _targets[goalType] = target;
        _on[goalType] = true;
        _shown = goalType;
        if (!_demo) {
            save();
            checkRewards();
        }
    }

    // The goal on the dashboard counter.
    function getGoalType() as Number {
        return _shown;
    }

    function getTarget() as Number {
        return _targets[_shown];
    }

    function getTargetFor(goalType as Number) as Number {
        return _targets[goalType];
    }

    function showNext(step as Number) as Void {
        var goals = enabledGoals();
        var i = goals.indexOf(_shown);
        _shown = goals[(i + step + goals.size()) % goals.size()];
        if (!_demo) {
            save();
        }
    }

    // ---------- live data ----------

    // today: local day number. values: today's totals per goal type (null = unavailable).
    // history: finished days as [day, steps, activeMin, floors], any order.
    function update(today as Number, values as Array<Number?>, history as Array<Array<Number?> >) as Void {
        _today = today;
        _values = values;
        if (_demo) {
            return;
        }
        settleFinishedDays(today, history);
        checkRewards();
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
            _streak = 0; // too long away to know
        }
        var before = _xp;
        var delta = 0;
        for (var day = first; day < today; day++) {
            var allMet = true;
            var known = true;
            for (var t = 0; t < Goals.GOAL_TYPES; t++) {
                if (!_on[t]) {
                    continue;
                }
                if (_rewardDays[t] == day) {
                    continue; // rewarded live already
                }
                var v = valueForDay(history, day, t);
                if (v == null) {
                    known = false;
                    continue;
                }
                if (v >= _targets[t]) {
                    delta += XP_GOAL;
                } else {
                    delta -= XP_MISS;
                    allMet = false;
                    _missPercent = (_targets[t] > 0) ? v * 100 / _targets[t] : 0;
                }
            }
            if (!allMet) {
                if (_streak > 0) {
                    _lostStreak = _streak;
                }
                _streak = 0;
            } else if (known) {
                _streak++;
            }
        }
        _lastEvalDay = today - 1;
        if (delta != 0) {
            _xp = clampXp(_xp + delta);
            announce(_xp - before, false, levelOf(_xp) > levelOf(before), delta > 0 ? EV_GOAL : EV_MISSED);
        }
        save();
    }

    private function checkRewards() as Void {
        var before = _xp;
        var gained = 0;
        for (var t = 0; t < Goals.GOAL_TYPES; t++) {
            if (_on[t] && isMet(t) && _rewardDays[t] != _today) {
                _rewardDays[t] = _today;
                gained += XP_GOAL;
            }
        }
        if (allMetToday() && _streakBonusDay != _today) {
            _streakBonusDay = _today;
            var s = _streak + 1;
            if (s >= 2) {
                gained += XP_STREAK * (s < MAX_STREAK_MULT ? s : MAX_STREAK_MULT);
            }
        }
        if (gained > 0) {
            _xp += gained;
            save();
            announce(gained, true, levelOf(_xp) > levelOf(before), EV_GOAL);
        }
    }

    private static function valueForDay(history as Array<Array<Number?> >, day as Number, goalType as Number) as Number? {
        for (var i = 0; i < history.size(); i++) {
            var entry = history[i];
            if (entry.size() > 1 + goalType && entry[0] != null && entry[0] == day) {
                return entry[1 + goalType];
            }
        }
        return null;
    }

    // ---------- bonuses ----------

    // Revives are already capped per day by VitalsModel.
    function addReviveBonus() as Void {
        addXp(XP_REVIVE, EV_REVIVE);
    }

    // Once per day; returns true when XP was awarded.
    function addBreathBonus() as Boolean {
        if (!_demo) {
            if (_breathDay == _today) {
                return false;
            }
            _breathDay = _today;
        }
        addXp(XP_BREATH, EV_BREATH);
        return true;
    }

    // Once per day; returns true when XP was awarded.
    function addExploreBonus() as Boolean {
        if (!_demo) {
            if (_exploreDay == _today) {
                return false;
            }
            _exploreDay = _today;
        }
        addXp(XP_EXPLORE, EV_EXPLORE);
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

    // ---------- demo ----------

    function isDemo() as Boolean {
        return _demo;
    }

    // Story mode starts fresh at scene 0 with its own XP (never the real monkey's).
    function enterDemo() as Void {
        _demo = true;
        _demoStage = 0;
        _demoXp = DemoScenarios.STORY_XP;
        clearEvent();
    }

    function exitDemo() as Void {
        _demo = false;
        clearEvent();
        checkRewards();
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
        } else if (effect == DemoScenarios.EFFECT_EXPLORE) {
            addXp(XP_EXPLORE, EV_EXPLORE);
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

    function getValueFor(goalType as Number) as Number? {
        if (_demo) {
            return _targets[goalType] * demoPercent(_demoStage) / 100;
        }
        return _values[goalType];
    }

    // Shown goal's value (demo: a share of the goal).
    function getValue() as Number? {
        return getValueFor(_shown);
    }

    // 0..1000+ (can exceed 1000 when over the goal).
    function getProgressFor(goalType as Number) as Number {
        var v = getValueFor(goalType);
        var target = _targets[goalType];
        if (v == null || target <= 0) {
            return 0;
        }
        return v * 1000 / target;
    }

    function getProgressPermille() as Number {
        return getProgressFor(_shown);
    }

    function isMet(goalType as Number) as Boolean {
        return getProgressFor(goalType) >= 1000;
    }

    function allMetToday() as Boolean {
        var goals = enabledGoals();
        for (var i = 0; i < goals.size(); i++) {
            if (!isMet(goals[i])) {
                return false;
            }
        }
        return true;
    }

    // Average progress of the enabled goals, each capped at 100 %.
    function getOverallPermille() as Number {
        var goals = enabledGoals();
        var sum = 0;
        for (var i = 0; i < goals.size(); i++) {
            var p = getProgressFor(goals[i]);
            sum += (p > 1000) ? 1000 : p;
        }
        return sum / goals.size();
    }

    // Eats when every goal is met, perks up from 50 % overall.
    function getPose() as Number {
        if (allMetToday()) {
            return POSE_EAT;
        }
        return (getOverallPermille() >= 500) ? POSE_PERK : POSE_RELAX;
    }

    // Days in a row with every goal met, counting today once it is complete.
    function getStreak() as Number {
        var base = _demo ? DemoScenarios.STORY_STREAK : _streak;
        return base + (allMetToday() ? 1 : 0);
    }

    function getLostStreak() as Number {
        return _lostStreak;
    }

    function getMissPercent() as Number {
        return _missPercent;
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

    // Events of the same kind add up until the view takes them (e.g. two goals met at once).
    private function announce(xp as Number, celebrate as Boolean, levelUp as Boolean, kind as Number) as Void {
        if (_eventPending && kind == _eventKind) {
            _eventXp += xp;
            _eventCelebrate = _eventCelebrate || celebrate;
            _eventLevelUp = _eventLevelUp || levelUp;
        } else {
            _eventXp = xp;
            _eventCelebrate = celebrate;
            _eventLevelUp = levelUp;
            _eventKind = kind;
        }
        _eventPending = _eventXp != 0 || _eventCelebrate;
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
        var shown = readNumber(Goals.KEY_TYPE, Goals.GOAL_STEPS);
        _shown = (shown >= 0 && shown < Goals.GOAL_TYPES) ? shown : Goals.GOAL_STEPS;
        for (var t = 0; t < Goals.GOAL_TYPES; t++) {
            _targets[t] = Goals.defaultTarget(t);
        }
        var on = Storage.getValue(KEY_ON);
        var targets = Storage.getValue(KEY_TARGETS);
        if (on instanceof Array && on.size() == Goals.GOAL_TYPES && targets instanceof Array && targets.size() == Goals.GOAL_TYPES) {
            for (var t = 0; t < Goals.GOAL_TYPES; t++) {
                var flag = on[t];
                _on[t] = (flag instanceof Boolean) && flag;
                var target = targets[t];
                if (target instanceof Number && target > 0) {
                    _targets[t] = target;
                }
            }
        } else {
            // Older single-goal storage: the stored goal is the only one.
            _on = [false, false, false];
            _on[_shown] = true;
            _targets[_shown] = readNumber(Goals.KEY_TARGET, Goals.defaultTarget(_shown));
            var oldReward = Storage.getValue("rewardDay");
            if (oldReward instanceof Number) {
                _rewardDays[_shown] = oldReward;
            }
        }
        if (enabledGoals().size() == 0) {
            _on[Goals.GOAL_STEPS] = true;
        }
        if (!_on[_shown]) {
            _shown = enabledGoals()[0];
        }
        var rewards = Storage.getValue(KEY_REWARDS);
        if (rewards instanceof Array && rewards.size() == Goals.GOAL_TYPES) {
            for (var t = 0; t < Goals.GOAL_TYPES; t++) {
                _rewardDays[t] = num(rewards[t], -1);
            }
        }
        _xp = clampXp(readNumber(Goals.KEY_XP, 0));
        var eval = Storage.getValue(KEY_EVAL_DAY);
        _lastEvalDay = (eval instanceof Number) ? eval : null;
        _breathDay = readNumber(KEY_BREATH_DAY, -1);
        _exploreDay = readNumber(KEY_EXPLORE_DAY, -1);
        var streak = Storage.getValue(KEY_STREAK);
        if (streak instanceof Array && streak.size() == 2) {
            _streak = num(streak[0], 0);
            _streakBonusDay = num(streak[1], -1);
        }
        var ch = Storage.getValue(KEY_CHARACTER);
        if (ch instanceof Array && ch.size() >= 2) {
            _created = num(ch[0], 0) == 1;
            _fur = num(ch[1], 0);
            _name = (ch.size() >= 3) ? num(ch[2], 0) : 0;
        } else {
            // Players from before character setup keep their monkey.
            _created = Storage.getValue(Goals.KEY_XP) != null;
        }
    }

    function save() as Void {
        if (_demo || !_persist) {
            return;
        }
        Storage.setValue(Goals.KEY_TYPE, _shown);
        Storage.setValue(Goals.KEY_TARGET, _targets[_shown]);
        Storage.setValue(Goals.KEY_XP, _xp);
        Storage.setValue(KEY_ON, [_on[0], _on[1], _on[2]]);
        Storage.setValue(KEY_TARGETS, [_targets[0], _targets[1], _targets[2]]);
        Storage.setValue(KEY_REWARDS, [_rewardDays[0], _rewardDays[1], _rewardDays[2]]);
        Storage.setValue(KEY_EVAL_DAY, _lastEvalDay);
        Storage.setValue(KEY_BREATH_DAY, _breathDay);
        Storage.setValue(KEY_EXPLORE_DAY, _exploreDay);
        Storage.setValue(KEY_STREAK, [_streak, _streakBonusDay]);
        Storage.setValue(KEY_CHARACTER, [_created ? 1 : 0, _fur, _name]);
    }

    private static function readNumber(key as String, fallback as Number) as Number {
        var v = Storage.getValue(key);
        return (v instanceof Number) ? v : fallback;
    }

    private static function num(v as Object?, fallback as Number) as Number {
        return (v instanceof Number) ? v : fallback;
    }
}
