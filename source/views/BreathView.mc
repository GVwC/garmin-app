import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.Timer;
import Toybox.WatchUi;

// Guided box breathing: 4 s in, 4 s hold, 4 s out, 4 s hold — 2 rounds (~32 s), 1 in story mode.
// START / tap skips to the end at any time (XP only after at least one full round).
// The ring and the monkey's chest rise and fall with the breath; live wrist HR is plotted.
// The HR sensor is enabled only while this screen is visible (onShow/onHide).
class BreathView extends WatchUi.View {

    private static const PHASE_MS = 4000;
    private static const ROUND_MS = PHASE_MS * 4;
    private static const TICK_MS = 100;
    private static const SCALE = 3;
    private static const MAX_HR_POINTS = 64;

    private var _model as MonkeyModel;
    private var _timer as Timer.Timer?;
    private var _elapsed as Number = 0;
    private var _done as Boolean = false;
    private var _awarded as Boolean = false;
    private var _hr as Number? = null;
    private var _hrStart as Number? = null;
    private var _hrs as Array<Number> = [];

    private var _runs as Array<Number> = [];
    private var _colors as Array<Number> = [];
    private var _phases as Array<String> = [];
    private var _sDone as String = "";
    private var _sAgain as String = "";
    private var _sHr as String = "";
    private var _sXp as String = "";
    private var _sSkip as String = "";

    function initialize(model as MonkeyModel) {
        View.initialize();
        _model = model;
    }

    function onLayout(dc as Dc) as Void {
        _runs = PixelSprite.compile([MonkeyArt.body(), MonkeyArt.breathePose()]);
        _colors = PixelSprite.paletteFor(_model.getFur());
        var sIn = WatchUi.loadResource(Rez.Strings.BreathIn) as String;
        var sHold = WatchUi.loadResource(Rez.Strings.BreathHold) as String;
        var sOut = WatchUi.loadResource(Rez.Strings.BreathOut) as String;
        _phases = [sIn, sHold, sOut, sHold];
        _sDone = WatchUi.loadResource(Rez.Strings.BreathDone) as String;
        _sAgain = WatchUi.loadResource(Rez.Strings.BreathAgain) as String;
        _sHr = WatchUi.loadResource(Rez.Strings.Hr) as String;
        _sXp = WatchUi.loadResource(Rez.Strings.Xp) as String;
        _sSkip = WatchUi.loadResource(Rez.Strings.BreathSkip) as String;
    }

    function onShow() as Void {
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE] as Array<SensorType>);
        Sensor.enableSensorEvents(method(:onSensor));
        if (!_done) {
            startTimer();
        }
    }

    function onHide() as Void {
        stopTimer();
        Sensor.enableSensorEvents(null);
        Sensor.setEnabledSensors([] as Array<SensorType>);
    }

    function onSensor(info as Sensor.Info) as Void {
        var hr = info.heartRate;
        if (hr != null && hr > 0) {
            _hr = hr;
            if (_hrStart == null) {
                _hrStart = hr;
            }
        }
    }

    function isDone() as Boolean {
        return _done;
    }

    private function rounds() as Number {
        return _model.isDemo() ? 1 : 2;
    }

    // Ends the session now (also used by START / tap to skip).
    function finish() as Void {
        if (_done) {
            return;
        }
        _done = true;
        stopTimer();
        _awarded = (_elapsed >= ROUND_MS) ? _model.addBreathBonus() : false;
        WatchUi.requestUpdate();
    }

    function restart() as Void {
        _elapsed = 0;
        _done = false;
        _awarded = false;
        _hrStart = _hr;
        _hrs = [];
        startTimer();
        WatchUi.requestUpdate();
    }

    private function startTimer() as Void {
        stopTimer();
        var t = new Timer.Timer();
        t.start(method(:onTick), TICK_MS, true);
        _timer = t;
    }

    private function stopTimer() as Void {
        var t = _timer;
        if (t != null) {
            t.stop();
        }
        _timer = null;
    }

    function onTick() as Void {
        _elapsed += TICK_MS;
        var hr = _hr;
        if (_elapsed % 1000 == 0 && hr != null) {
            _hrs.add(hr);
            if (_hrs.size() > MAX_HR_POINTS) {
                _hrs = _hrs.slice(1, null);
            }
        }
        if (_elapsed >= rounds() * ROUND_MS) {
            finish();
        }
        WatchUi.requestUpdate();
    }

    // 0..1000: lungs empty .. full.
    private function fill() as Number {
        if (_done) {
            return 0;
        }
        var phase = (_elapsed / PHASE_MS) % 4;
        var t = (_elapsed % PHASE_MS) * 1000 / PHASE_MS;
        if (phase == 0) {
            return t;
        } else if (phase == 1) {
            return 1000;
        } else if (phase == 2) {
            return 1000 - t;
        }
        return 0;
    }

    function onUpdate(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.setColor(Graphics.COLOR_WHITE, 0x000055);
        dc.clear();

        var level = fill();
        var cy = 112;
        var r = 56 + 26 * level / 1000;
        dc.setColor(0x0055AA, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, r);
        dc.setColor(0x55AAFF, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawCircle(cx, cy, r);
        dc.setPenWidth(1);
        var rise = 6 * level / 1000;
        PixelSprite.draw(dc, _runs, _colors, cx - MonkeyArt.CENTER_X * SCALE, cy - 36 - rise, SCALE);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (_done) {
            dc.drawText(cx, 28, Graphics.FONT_XTINY, _sDone, center);
            var line = hrSummary();
            if (_awarded) {
                line = line + "  +" + MonkeyModel.XP_BREATH + " " + _sXp;
            }
            dc.drawText(cx, 196, Graphics.FONT_XTINY, line, center);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 222, Graphics.FONT_XTINY, _sAgain, center);
            return;
        }

        var phase = (_elapsed / PHASE_MS) % 4;
        dc.drawText(cx, 28, Graphics.FONT_SMALL, _phases[phase], center);
        var left = (PHASE_MS - _elapsed % PHASE_MS + 999) / 1000;
        dc.drawText(cx, 186, Graphics.FONT_MEDIUM, left.toString(), center);
        drawRounds(dc, cx);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 248, Graphics.FONT_XTINY, _sSkip, center);
        drawHr(dc, cx, center);
    }

    private function hrSummary() as String {
        var start = _hrStart;
        var now = _hr;
        if (start == null || now == null) {
            return _sHr + " --";
        }
        return _sHr + " " + start + " > " + now;
    }

    private function drawRounds(dc as Dc, cx as Number) as Void {
        var round = _elapsed / ROUND_MS;
        var n = rounds();
        var x0 = cx - (n * 14 - 4) / 2;
        for (var i = 0; i < n; i++) {
            dc.setColor(i <= round ? 0x55AAFF : 0x555555, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x0 + i * 14, 205, 10, 4);
        }
    }

    // "HR 72" and a sparkline of the session.
    private function drawHr(dc as Dc, cx as Number, center as Number) as Void {
        var hr = _hr;
        dc.setColor(0xFF5555, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 46, 228, Graphics.FONT_XTINY, _sHr + " " + (hr != null ? hr.toString() : "--"), center);
        var n = _hrs.size();
        if (n < 2) {
            return;
        }
        var lo = _hrs[0];
        var hi = _hrs[0];
        for (var i = 1; i < n; i++) {
            if (_hrs[i] < lo) {
                lo = _hrs[i];
            }
            if (_hrs[i] > hi) {
                hi = _hrs[i];
            }
        }
        var span = (hi - lo < 4) ? 4 : hi - lo;
        var x0 = cx - 12;
        var w = 60;
        var y0 = 238;
        var h = 16;
        for (var i = 1; i < n; i++) {
            var xa = x0 + (i - 1) * w / (MAX_HR_POINTS - 1);
            var xb = x0 + i * w / (MAX_HR_POINTS - 1);
            var ya = y0 - (_hrs[i - 1] - lo) * h / span;
            var yb = y0 - (_hrs[i] - lo) * h / span;
            dc.drawLine(xa, ya, xb, yb);
        }
    }
}
