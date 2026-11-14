import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Climbing clock: three rock walls (H, M, S), one climber each. Height = time value;
// after the summit (11 h / 59 min / 59 s) the climber falls back to the bottom.
// Timer: 1 s normally, 100 ms only while a fall animates or in demo mode.
class MainView extends WatchUi.View {

    private static const TICK_MS = 1000;
    private static const FAST_TICK_MS = 100;

    private var _model as ClimbModel;
    private var _timer as Timer.Timer?;

    // Geometry, computed once in onLayout.
    private var _laneX as Array<Number> = [0, 0, 0];
    private var _topY as Number = 0;
    private var _bottomY as Number = 0;
    private var _walls as Array<Array<[Numeric, Numeric]> > = [];
    private var _colors as Array<Number> = [Graphics.COLOR_RED, Graphics.COLOR_YELLOW, Graphics.COLOR_GREEN];
    private var _labels as Array<String> = ["H", "M", "S"];
    private var _modeLive as String = "";
    private var _modeDemo as String = "";

    function initialize(model as ClimbModel) {
        View.initialize();
        _model = model;
    }

    function onLayout(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var gap = w * 24 / 100;
        _laneX = [cx - gap, cx, cx + gap];
        _topY = h * 20 / 100;
        _bottomY = h * 76 / 100;
        _modeLive = WatchUi.loadResource(Rez.Strings.ModeLive) as String;
        _modeDemo = WatchUi.loadResource(Rez.Strings.ModeDemo) as String;

        // Jagged rock outline: [x offset, y position in per-mille from top to bottom].
        var shape = [
            [-22, 1040], [-18, 800], [-23, 550], [-16, 300], [-19, 100], [-8, -40],
            [0, -110],
            [9, -30], [18, 120], [15, 350], [22, 580], [17, 820], [22, 1040]
        ];
        var span = _bottomY - _topY;
        _walls = [];
        for (var lane = 0; lane < ClimbModel.LANES; lane++) {
            var pts = [] as Array<[Numeric, Numeric]>;
            for (var i = 0; i < shape.size(); i++) {
                pts.add([_laneX[lane] + shape[i][0], _topY + span * shape[i][1] / 1000]);
            }
            _walls.add(pts);
        }
    }

    function onShow() as Void {
        _timer = new Timer.Timer();
        onTick();
    }

    // Stop the timer whenever the view is not visible (battery).
    function onHide() as Void {
        var timer = _timer;
        if (timer != null) {
            timer.stop();
        }
        _timer = null;
    }

    function onTick() as Void {
        var t = System.getClockTime();
        _model.tick(t.hour, t.min, t.sec);
        WatchUi.requestUpdate();
        var timer = _timer;
        if (timer != null) {
            var fast = _model.isDemo() || _model.isAnyFalling();
            timer.start(method(:onTick), fast ? FAST_TICK_MS : TICK_MS, false);
        }
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setPenWidth(2);
        for (var lane = 0; lane < ClimbModel.LANES; lane++) {
            drawWall(dc, lane);
            drawLaneClimber(dc, lane);
            dc.setColor(_colors[lane], Graphics.COLOR_TRANSPARENT);
            dc.drawText(_laneX[lane], _bottomY + 16, Graphics.FONT_XTINY, _labels[lane], center);
        }
        dc.setPenWidth(1);

        var demo = _model.isDemo();
        dc.setColor(demo ? Graphics.COLOR_ORANGE : Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 91 / 100, Graphics.FONT_XTINY, demo ? _modeDemo : _modeLive, center);
    }

    private function drawWall(dc as Dc, lane as Number) as Void {
        var x = _laneX[lane];
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(_walls[lane]);

        // Holds
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var span = _bottomY - _topY;
        for (var i = 1; i < 5; i++) {
            dc.fillCircle(x + ((i % 2 == 0) ? -7 : 7), _topY + span * i / 5, 2);
        }

        // Scale on the left edge: 12 ticks (each hour / every 5 min or s),
        // long ticks at the quarters (0/3/6/9 h, 0/15/30/45 min/s).
        var max = _model.getMax(lane);
        var step = max / 12;
        for (var v = 0; v < max; v += step) {
            var y = _bottomY - span * v / (max - 1);
            if ((v / step) % 3 == 0) {
                dc.setColor(_colors[lane], Graphics.COLOR_TRANSPARENT);
                dc.drawLine(x - 31, y, x - 15, y);
            } else {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(x - 27, y, x - 19, y);
            }
        }

        // Summit flag
        var peakY = _topY - span * 110 / 1000;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x, peakY, x, peakY - 12);
        dc.fillPolygon([[x, peakY - 12], [x + 8, peakY - 9], [x, peakY - 6]]);
    }

    private function drawLaneClimber(dc as Dc, lane as Number) as Void {
        var x = _laneX[lane];
        var span = _bottomY - _topY;
        dc.setColor(_colors[lane], Graphics.COLOR_TRANSPARENT);

        var frames = _model.getFallFrames(lane);
        if (frames > 0) {
            // Accelerating fall from the summit: distance ~ d^2.
            var last = ClimbModel.FALL_FRAMES - 1;
            var d = ClimbModel.FALL_FRAMES - frames;
            drawFaller(dc, x, _topY + span * d * d / (last * last), frames == 1);
            return;
        }
        var footY = _bottomY - span * _model.getHeight(lane) / 1000;
        drawClimber(dc, x, footY, _model.getValue(lane) % 2 == 0);
    }

    // Stick figure on the wall; arms swap every step so it looks like climbing.
    private function drawClimber(dc as Dc, x as Number, footY as Number, leftUp as Boolean) as Void {
        var s = leftUp ? -1 : 1;
        dc.fillCircle(x, footY - 15, 3);
        dc.drawLine(x, footY - 12, x, footY - 5);
        dc.drawLine(x, footY - 10, x + 5 * s, footY - 16);
        dc.drawLine(x, footY - 10, x - 5 * s, footY - 7);
        dc.drawLine(x, footY - 5, x + 4 * s, footY - 1);
        dc.drawLine(x, footY - 5, x - 4 * s, footY);
    }

    // Upside-down figure with speed lines; dust when it lands.
    private function drawFaller(dc as Dc, x as Number, headY as Number, landing as Boolean) as Void {
        dc.fillCircle(x, headY - 3, 3);
        dc.drawLine(x, headY - 6, x, headY - 13);
        dc.drawLine(x - 7, headY - 10, x + 7, headY - 8);
        dc.drawLine(x, headY - 13, x - 5, headY - 19);
        dc.drawLine(x, headY - 13, x + 5, headY - 19);
        if (landing) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x - 9, headY, 2);
            dc.fillCircle(x + 9, headY, 2);
            dc.fillCircle(x - 5, headY - 3, 1);
            dc.fillCircle(x + 5, headY - 3, 1);
        } else {
            dc.drawLine(x - 4, headY - 24, x - 4, headY - 32);
            dc.drawLine(x + 4, headY - 24, x + 4, headY - 32);
        }
    }
}
