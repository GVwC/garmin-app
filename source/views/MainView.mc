import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Dashboard: level + XP bar, the pixel monkey, "3,420 / 5,000 steps", progress bar, hints.
// Live data is refreshed on show and every REFRESH_MS while visible; the timer only runs
// fast (ANIM_MS) while a celebration or XP banner is on screen.
class MainView extends WatchUi.View {

    private static const REFRESH_MS = 60000;
    private static const ANIM_MS = 100;
    private static const BANNER_TICKS = 30; // 3 s
    private static const SCALE = 4;
    private static const BG = 0x005500;

    private var _model as MonkeyModel;
    private var _timer as Timer.Timer?;
    private var _sinceRefreshMs as Number = 0;

    // Animation state.
    private var _bounceTick as Number = -1;
    private var _bannerTicks as Number = 0;
    private var _bannerText as String = "";
    private var _bannerColor as Number = Graphics.COLOR_YELLOW;

    // Cached in onLayout.
    private var _poses as Array<Array<Number> > = [];
    private var _colors as Array<Number> = [];
    private var _bounce as Array<Number> = [0, -3, -6, -8, -9, -8, -6, -3, 0, -2, -3, -2, 0];
    private var _labels as Array<String> = [];
    private var _units as Array<String> = [];
    private var _sUnavailable as String = "";
    private var _sLevel as String = "";
    private var _sXp as String = "";
    private var _sLevelUp as String = "";
    private var _sGoalHit as String = "";
    private var _sGoalMissed as String = "";
    private var _sHintLive as String = "";
    private var _sHintMenu as String = "";
    private var _sHintDemo as String = "";
    private var _sDemo as String = "";
    private var _sDemoMissed as String = "";

    function initialize(model as MonkeyModel) {
        View.initialize();
        _model = model;
    }

    function onLayout(dc as Dc) as Void {
        var body = MonkeyArt.body();
        _poses = [
            PixelSprite.compile([body, MonkeyArt.relaxPose()]),
            PixelSprite.compile([body, MonkeyArt.perkPose()]),
            PixelSprite.compile([body, MonkeyArt.eatPose()])
        ];
        _colors = PixelSprite.palette();
        _labels = [str(Rez.Strings.GoalSteps), str(Rez.Strings.GoalActive), str(Rez.Strings.GoalFloors)];
        _units = [str(Rez.Strings.UnitSteps), str(Rez.Strings.UnitActive), str(Rez.Strings.UnitFloors)];
        _sUnavailable = str(Rez.Strings.Unavailable);
        _sLevel = str(Rez.Strings.Level);
        _sXp = str(Rez.Strings.Xp);
        _sLevelUp = str(Rez.Strings.LevelUp);
        _sGoalHit = str(Rez.Strings.GoalHit);
        _sGoalMissed = str(Rez.Strings.GoalMissed);
        _sHintLive = str(Rez.Strings.HintLive);
        _sHintMenu = str(Rez.Strings.HintMenu);
        _sHintDemo = str(Rez.Strings.HintDemo);
        _sDemo = str(Rez.Strings.Demo);
        _sDemoMissed = str(Rez.Strings.DemoMissed);
    }

    private static function str(id as ResourceId) as String {
        return WatchUi.loadResource(id) as String;
    }

    function onShow() as Void {
        _timer = new Timer.Timer();
        refresh();
        schedule();
    }

    // Stop the timer whenever the view is hidden (battery) and drop running animations.
    function onHide() as Void {
        var timer = _timer;
        if (timer != null) {
            timer.stop();
        }
        _timer = null;
        _bounceTick = -1;
        _bannerTicks = 0;
    }

    // Reads today's total + finished days and lets the model settle XP.
    function refresh() as Void {
        var type = _model.getGoalType();
        _model.update(DayClock.today(), ActivityService.todayValue(type), ActivityService.history(type));
        _sinceRefreshMs = 0;
        pollEvent();
        WatchUi.requestUpdate();
    }

    // Called by delegates after demo/goal changes.
    function onModelChanged() as Void {
        if (_model.isDemo()) {
            pollEvent();
            WatchUi.requestUpdate();
        } else {
            refresh();
        }
        schedule();
    }

    private function pollEvent() as Void {
        var e = _model.takeEvent();
        if (e == null) {
            return;
        }
        var xp = e[0];
        if (e[2]) {
            _bannerText = _sLevelUp;
            _bannerColor = 0x55FFFF;
        } else if (xp > 0) {
            _bannerText = _sGoalHit + " " + Fmt.signed(xp) + " " + _sXp;
            _bannerColor = Graphics.COLOR_YELLOW;
        } else {
            _bannerText = _sGoalMissed + " " + Fmt.signed(xp) + " " + _sXp;
            _bannerColor = 0xFF5555;
        }
        _bannerTicks = BANNER_TICKS;
        if (e[1]) {
            _bounceTick = 0;
        }
    }

    private function isAnimating() as Boolean {
        return _bounceTick >= 0 || _bannerTicks > 0;
    }

    private function schedule() as Void {
        var timer = _timer;
        if (timer == null) {
            return;
        }
        timer.stop();
        timer.start(method(:onTick), isAnimating() ? ANIM_MS : REFRESH_MS, false);
    }

    function onTick() as Void {
        _sinceRefreshMs += isAnimating() ? ANIM_MS : REFRESH_MS;
        if (_bounceTick >= 0) {
            _bounceTick++;
            if (_bounceTick >= _bounce.size()) {
                _bounceTick = -1;
            }
        }
        if (_bannerTicks > 0) {
            _bannerTicks--;
        }
        if (_sinceRefreshMs >= REFRESH_MS) {
            refresh();
        } else {
            WatchUi.requestUpdate();
        }
        schedule();
    }

    function onUpdate(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(Graphics.COLOR_WHITE, BG);
        dc.clear();

        drawHeader(dc, cx, center);

        // Monkey: body centre column on the screen centre; bounce only while celebrating.
        var dy = (_bounceTick >= 0) ? _bounce[_bounceTick] * SCALE / 2 : 0;
        PixelSprite.draw(dc, _poses[_model.getPose()], _colors, cx - MonkeyArt.CENTER_X * SCALE, 64 + dy, SCALE);

        var type = _model.getGoalType();
        var v = _model.getValue();
        var text;
        if (v == null) {
            text = _labels[type] + " " + _sUnavailable;
        } else {
            text = Fmt.thousands(v) + " / " + Fmt.thousands(_model.getTarget()) + " " + _units[type];
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 172, Graphics.FONT_TINY, text, center);

        var p = _model.getProgressPermille();
        var color = (p >= 1000) ? 0xFFFF55 : ((p >= 500) ? Graphics.COLOR_YELLOW : 0x55AA00);
        drawSegments(dc, cx - 80, 190, 160, 12, 20, p > 1000 ? 1000 : p, color);

        drawHints(dc, cx, center);
    }

    // "Lv 3   240 XP" with a chunky XP bar, or the event banner for a few seconds.
    private function drawHeader(dc as Dc, cx as Number, center as Number) as Void {
        if (_bannerTicks > 0) {
            dc.setColor(_bannerColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 34, Graphics.FONT_XTINY, _bannerText, center);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var t = _sLevel + " " + _model.getLevel() + "   " + Fmt.thousands(_model.getXp()) + " " + _sXp;
            dc.drawText(cx, 34, Graphics.FONT_XTINY, t, center);
        }
        drawSegments(dc, cx - 50, 50, 100, 6, 10, _model.getLevelPermille(), 0x55AAFF);
    }

    // Pixel-style bar: `count` blocks with 2 px gaps on a black track.
    private function drawSegments(dc as Dc, x as Number, y as Number, width as Number, height as Number,
            count as Number, permille as Number, color as Number) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x - 2, y - 2, width + 2, height + 4);
        var seg = width / count;
        var filled = permille * count / 1000;
        for (var i = 0; i < count; i++) {
            dc.setColor(i < filled ? color : 0x003300, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x + i * seg, y, seg - 2, height);
        }
    }

    private function drawHints(dc as Dc, cx as Number, center as Number) as Void {
        if (_model.isDemo()) {
            var stage = _model.getDemoStage();
            var label = (stage == MonkeyModel.DEMO_MISSED)
                ? _sDemo + " " + _sDemoMissed
                : _sDemo + " " + MonkeyModel.demoPercent(stage) + "%";
            dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 214, Graphics.FONT_XTINY, label, center);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 234, Graphics.FONT_XTINY, _sHintDemo, center);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 214, Graphics.FONT_XTINY, _sHintLive, center);
            dc.drawText(cx, 234, Graphics.FONT_XTINY, _sHintMenu, center);
        }
    }
}
