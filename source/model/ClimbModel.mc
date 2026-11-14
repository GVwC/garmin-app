import Toybox.Lang;

// State for the climbing clock. Three lanes: 0 = hours, 1 = minutes, 2 = seconds.
// Hours use a 12-hour dial. A climber's height is value / (max - 1): bottom at 0,
// summit at 11 or 59. When a value goes down (59 -> 0, 11 -> 0 at 12:00 and midnight)
// that climber falls for FALL_FRAMES ticks.
// No Toybox UI calls here, so it is unit-testable.
class ClimbModel {

    static const LANES = 3;
    static const FALL_FRAMES = 8;
    // Demo mode advances 61 s per tick so seconds and minutes both move every tick.
    static const DEMO_STEP_SEC = 61;
    private static const DAY_SEC = 86400;

    private var _max as Array<Number> = [12, 60, 60];
    private var _values as Array<Number> = [0, 0, 0];
    private var _fall as Array<Number> = [0, 0, 0];
    private var _hasTime as Boolean = false;
    private var _demo as Boolean = false;
    private var _demoSec as Number = 0;

    function initialize() {
    }

    // Called once per timer tick with the real clock. Advances falls, then time.
    function tick(hour as Number, min as Number, sec as Number) as Void {
        stepFall();
        if (_demo) {
            _demoSec = (_demoSec + DEMO_STEP_SEC) % DAY_SEC;
            setTime(_demoSec / 3600, (_demoSec / 60) % 60, _demoSec % 60);
        } else {
            setTime(hour, min, sec);
        }
    }

    function setTime(hour as Number, min as Number, sec as Number) as Void {
        var v = [hour % 12, min, sec];
        for (var i = 0; i < LANES; i++) {
            if (_hasTime && v[i] < _values[i]) {
                _fall[i] = FALL_FRAMES;
            }
            _values[i] = v[i];
        }
        _hasTime = true;
    }

    function stepFall() as Void {
        for (var i = 0; i < LANES; i++) {
            if (_fall[i] > 0) {
                _fall[i] -= 1;
            }
        }
    }

    // Demo starts from the currently shown time so the switch is seamless.
    function toggleDemo() as Void {
        _demo = !_demo;
        if (_demo) {
            _demoSec = _values[0] * 3600 + _values[1] * 60 + _values[2];
        }
    }

    function isDemo() as Boolean {
        return _demo;
    }

    function getValue(lane as Number) as Number {
        return _values[lane];
    }

    // Number of positions on the lane: 12 for hours, 60 for minutes/seconds.
    function getMax(lane as Number) as Number {
        return _max[lane];
    }

    // Height on the wall in per-mille: 0 = bottom, 1000 = summit.
    function getHeight(lane as Number) as Number {
        return _values[lane] * 1000 / (_max[lane] - 1);
    }

    // Remaining fall frames; FALL_FRAMES = just left the summit, 0 = not falling.
    function getFallFrames(lane as Number) as Number {
        return _fall[lane];
    }

    function isAnyFalling() as Boolean {
        for (var i = 0; i < LANES; i++) {
            if (_fall[i] > 0) {
                return true;
            }
        }
        return false;
    }
}
