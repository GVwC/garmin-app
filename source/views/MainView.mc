import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

// Dashboard (260x260 round):
//   level + XP bar · Energy meter | pixel monkey | Calm meter · "3,420 / 5,000 steps" ·
//   goal bar · status title + recommendation (or button hints).
// Refresh: goal value on show and every REFRESH_MS, vitals on show and every VITALS_MS.
// The timer runs fast only while an animation plays (celebration, revive, banner) or while the
// monkey jogs; it is stopped in onHide. No sensors are enabled here.
class MainView extends WatchUi.View {

    private static const REFRESH_MS = 60000;
    private static const VITALS_MS = 300000;
    private static const ANIM_MS = 100;
    private static const JOG_MS = 400;
    private static const BANNER_TICKS = 30;  // 3 s at ANIM_MS
    private static const STRETCH_TICKS = 20; // 2 s
    private static const SCALE = 4;
    private static const BIG_SCALE = 5;
    private static const MONKEY_Y = 70;

    private var _model as MonkeyModel;
    private var _vitals as VitalsModel;
    private var _timer as Timer.Timer?;
    private var _sinceRefreshMs as Number = 0;
    private var _sinceVitalsMs as Number = 0;

    // Vitals as last shown.
    private var _snap as VitalsSnapshot = new VitalsSnapshot();
    private var _hasSnap as Boolean = false;
    private var _msg as Number = MonkeyStatus.MSG_NONE;
    private var _curious as Number = Vitals.CURIOUS_CONTENT;

    // Animation state.
    private var _bounceTick as Number = -1;
    private var _stretchTicks as Number = 0;
    private var _bannerTicks as Number = 0;
    private var _bannerText as String = "";
    private var _bannerColor as Number = Graphics.COLOR_YELLOW;
    private var _frame as Number = 0;

    // Cached in onLayout.
    private var _body as Array<Number> = [];
    private var _poses as Array<Array<Number>?> = [];
    private var _colors as Array<Number> = [];
    private var _bounce as Array<Number> = [0, -3, -6, -8, -9, -8, -6, -3, 0, -2, -3, -2, 0];
    private var _labels as Array<String> = [];
    private var _units as Array<String> = [];
    private var _titles as Array<String> = [];
    private var _actions as Array<String> = [];
    private var _demoLabels as Array<String> = [];
    private var _s as Dictionary<Symbol, String> = {};

    function initialize(model as MonkeyModel, vitals as VitalsModel) {
        View.initialize();
        _model = model;
        _vitals = vitals;
    }

    function onLayout(dc as Dc) as Void {
        // The body is shared by every pose; pose patches are compiled on first use
        // (compiling everything at once trips the watchdog).
        _body = PixelSprite.compile([MonkeyArt.body()]);
        _poses = new Array<Array<Number>?>[MonkeyStatus.POSE_COUNT];
        _colors = PixelSprite.palette();
        _labels = strs([Rez.Strings.GoalSteps, Rez.Strings.GoalActive, Rez.Strings.GoalFloors]);
        _units = strs([Rez.Strings.UnitSteps, Rez.Strings.UnitActive, Rez.Strings.UnitFloors]);
        _titles = strs([Rez.Strings.St0, Rez.Strings.St1, Rez.Strings.St2, Rez.Strings.St3,
            Rez.Strings.St4, Rez.Strings.St5, Rez.Strings.St6, Rez.Strings.St7, Rez.Strings.St8,
            Rez.Strings.St9, Rez.Strings.St10, Rez.Strings.St11, Rez.Strings.St12, Rez.Strings.St13]);
        _actions = strs([Rez.Strings.Ac0, Rez.Strings.Ac1, Rez.Strings.Ac2, Rez.Strings.Ac3,
            Rez.Strings.Ac4, Rez.Strings.Ac5, Rez.Strings.Ac6, Rez.Strings.Ac7, Rez.Strings.Ac8,
            Rez.Strings.Ac9, Rez.Strings.Ac10, Rez.Strings.Ac11, Rez.Strings.Ac12, Rez.Strings.Ac13]);
        _demoLabels = strs([Rez.Strings.Dm0, Rez.Strings.Dm1, Rez.Strings.Dm2, Rez.Strings.Dm3,
            Rez.Strings.Dm4, Rez.Strings.Dm5, Rez.Strings.Dm6, Rez.Strings.Dm7, Rez.Strings.Dm8,
            Rez.Strings.Dm9, Rez.Strings.Dm10, Rez.Strings.Dm11, Rez.Strings.Dm12, Rez.Strings.Dm13,
            Rez.Strings.Dm14, Rez.Strings.Dm15, Rez.Strings.Dm16, Rez.Strings.Dm17]);
        _s = {
            :unavailable => str(Rez.Strings.Unavailable),
            :level => str(Rez.Strings.Level),
            :xp => str(Rez.Strings.Xp),
            :levelUp => str(Rez.Strings.LevelUp),
            :goalHit => str(Rez.Strings.GoalHit),
            :goalMissed => str(Rez.Strings.GoalMissed),
            :revived => str(Rez.Strings.Revived),
            :calmed => str(Rez.Strings.Calmed),
            :breathed => str(Rez.Strings.Breathed),
            :explored => str(Rez.Strings.Explored),
            :hintLive => str(Rez.Strings.HintLive),
            :hintMenu => str(Rez.Strings.HintMenu),
            :hintDemo => str(Rez.Strings.HintDemo),
            :demo => str(Rez.Strings.Demo)
        };
    }

    private function poseRuns(pose as Number) as Array<Number> {
        var runs = _poses[pose];
        if (runs == null) {
            runs = PixelSprite.compile([posePatches(pose)]);
            _poses[pose] = runs;
        }
        return runs;
    }

    private static function posePatches(pose as Number) as Array {
        if (pose == MonkeyStatus.POSE_PERK) {
            return MonkeyArt.perkPose();
        } else if (pose == MonkeyStatus.POSE_EAT) {
            return MonkeyArt.eatPose();
        } else if (pose == MonkeyStatus.POSE_TIRED) {
            return MonkeyArt.tiredPose();
        } else if (pose == MonkeyStatus.POSE_ASLEEP) {
            return MonkeyArt.asleepPose();
        } else if (pose == MonkeyStatus.POSE_ALERT) {
            return MonkeyArt.alertPose();
        } else if (pose == MonkeyStatus.POSE_STRESSED) {
            return MonkeyArt.stressedPose();
        } else if (pose == MonkeyStatus.POSE_JOG) {
            return MonkeyArt.jogPose();
        } else if (pose == MonkeyStatus.POSE_JOG2) {
            return MonkeyArt.jogPose2();
        } else if (pose == MonkeyStatus.POSE_STRETCH) {
            return MonkeyArt.stretchPose();
        } else if (pose == MonkeyStatus.POSE_BREATHE) {
            return MonkeyArt.breathePose();
        } else if (pose == MonkeyStatus.POSE_PANT) {
            return MonkeyArt.pantPose();
        } else if (pose == MonkeyStatus.POSE_COLD) {
            return MonkeyArt.coldPose();
        } else if (pose == MonkeyStatus.POSE_HOT) {
            return MonkeyArt.hotPose();
        } else if (pose == MonkeyStatus.POSE_CLIMB) {
            return MonkeyArt.climbPose();
        } else if (pose == MonkeyStatus.POSE_BORED) {
            return MonkeyArt.boredPose();
        }
        return MonkeyArt.relaxPose();
    }

    private function drawSprite(dc as Dc, pose as Number, x as Number, y as Number, scale as Number) as Void {
        PixelSprite.draw(dc, _body, _colors, x, y, scale);
        PixelSprite.draw(dc, poseRuns(pose), _colors, x, y, scale);
    }

    private static function str(id as ResourceId) as String {
        return WatchUi.loadResource(id) as String;
    }

    private static function strs(ids as Array<ResourceId>) as Array<String> {
        var out = [] as Array<String>;
        for (var i = 0; i < ids.size(); i++) {
            out.add(str(ids[i]));
        }
        return out;
    }

    private function text(key as Symbol) as String {
        var v = _s[key];
        return (v != null) ? v : "";
    }

    // ---------- lifecycle ----------

    function onShow() as Void {
        _timer = new Timer.Timer();
        refresh(true);
        schedule();
    }

    function onHide() as Void {
        var timer = _timer;
        if (timer != null) {
            timer.stop();
        }
        _timer = null;
        _bounceTick = -1;
        _stretchTicks = 0;
        _bannerTicks = 0;
        Storage.setValue(VitalsModel.KEY_FG_SEEN, 0);
    }

    // Goal value every call; vitals when forced or VITALS_MS has passed.
    function refresh(withVitals as Boolean) as Void {
        var type = _model.getGoalType();
        _model.update(DayClock.today(), ActivityService.todayValue(type), ActivityHistory.days(type));
        _sinceRefreshMs = 0;
        if (withVitals || _sinceVitalsMs >= VITALS_MS) {
            refreshVitals();
        }
        pollEvent();
        updateStatus();
        WatchUi.requestUpdate();
    }

    private function refreshVitals() as Void {
        _sinceVitalsMs = 0;
        if (_model.isDemo()) {
            return;
        }
        _vitals.load(); // pick up what the background wrote
        var snap = VitalsService.snapshot();
        var event = _vitals.apply(snap, DayClock.today());
        var revives = _vitals.takePendingRevives();
        for (var i = 0; i < revives; i++) {
            _model.addReviveBonus();
        }
        if (event == VitalsModel.EVENT_REVIVED) {
            _stretchTicks = STRETCH_TICKS;
            if (revives == 0) {
                showBanner(text(:revived), 0x55FFFF);
            }
        } else if (event == VitalsModel.EVENT_CALMED) {
            showBanner(text(:calmed), 0x55FFFF);
        }
        _curious = ActivityHistory.curiosity();
        if (_curious == Vitals.CURIOUS_ADVENTUROUS) {
            _model.addExploreBonus(); // once per day; the event shows the banner
        }
        var now = Time.now().value();
        _vitals.markSeen(snap, _model.getProgressPermille(), now);
        Storage.setValue(VitalsModel.KEY_FG_SEEN, now);
        _snap = snap;
        _hasSnap = true;
    }

    // Background service delivered new data while the app is open.
    function onBackgroundUpdate() as Void {
        refresh(true);
        schedule();
    }

    // Called by delegates after demo/goal/breathing changes.
    function onModelChanged() as Void {
        if (_model.isDemo()) {
            pollEvent();
            updateStatus();
            WatchUi.requestUpdate();
        } else {
            refresh(true);
        }
        schedule();
    }

    function getMsg() as Number {
        return _msg;
    }

    // ---------- status ----------

    private function demoRow() as Array<Number> {
        return DemoScenarios.row(_model.getDemoStage());
    }

    private function updateStatus() as Void {
        if (_model.isDemo()) {
            var row = demoRow();
            _msg = MonkeyStatus.message(row[DemoScenarios.ENERGY], row[DemoScenarios.CALM], row[DemoScenarios.DEEP] == 1,
                row[DemoScenarios.BREATH], row[DemoScenarios.WARMTH], row[DemoScenarios.CURIOUS]);
        } else {
            _msg = MonkeyStatus.message(_vitals.getEnergy(), _vitals.getCalm(), Vitals.isDeepInactive(_snap),
                _vitals.getBreath(), _vitals.getWarmth(), _curious);
        }
    }

    private function energyMeter() as Number? {
        if (_model.isDemo()) {
            return demoRow()[DemoScenarios.E_METER];
        }
        return _hasSnap ? Vitals.energyMeter(_snap) : null;
    }

    // Garmin's live stress score is a 30 s average; the state uses the sustained history.
    // Cap the meter so it never looks calmer than the state the monkey shows.
    private function calmMeter() as Number? {
        if (_model.isDemo()) {
            return demoRow()[DemoScenarios.C_METER];
        }
        var v = _hasSnap ? Vitals.calmMeter(_snap) : null;
        var calm = _vitals.getCalm();
        var cap = (calm == Vitals.CALM_STRESSED) ? 20 : ((calm == Vitals.CALM_ALERT) ? 45 : 100);
        if (v == null) {
            return (cap < 100) ? cap : null;
        }
        return (v > cap) ? cap : v;
    }

    private function pollEvent() as Void {
        var e = _model.takeEvent();
        if (e == null) {
            return;
        }
        var xp = e[0];
        var kind = e[3];
        var label = text(:goalHit);
        var color = Graphics.COLOR_YELLOW;
        if (kind == MonkeyModel.EV_MISSED) {
            label = text(:goalMissed);
            color = 0xFF5555;
        } else if (kind == MonkeyModel.EV_REVIVE) {
            label = text(:revived);
            color = 0x55FFFF;
            _stretchTicks = STRETCH_TICKS;
        } else if (kind == MonkeyModel.EV_BREATH) {
            label = text(:breathed);
            color = 0x55FFFF;
        } else if (kind == MonkeyModel.EV_EXPLORE) {
            label = text(:explored);
            color = 0x55FF55;
        }
        if (e[2]) {
            showBanner(text(:levelUp), 0x55FFFF);
        } else {
            showBanner(label + " " + Fmt.signed(xp) + " " + text(:xp), color);
        }
        if (e[1]) {
            _bounceTick = 0;
        }
    }

    private function showBanner(t as String, color as Number) as Void {
        _bannerText = t;
        _bannerColor = color;
        _bannerTicks = BANNER_TICKS;
    }

    // ---------- timer ----------

    private function isAnimating() as Boolean {
        return _bounceTick >= 0 || _stretchTicks > 0 || _bannerTicks > 0;
    }

    private function interval() as Number {
        if (isAnimating()) {
            return ANIM_MS;
        }
        return MonkeyStatus.isLooping(_msg) ? JOG_MS : REFRESH_MS;
    }

    private function schedule() as Void {
        var timer = _timer;
        if (timer == null) {
            return;
        }
        timer.stop();
        timer.start(method(:onTick), interval(), false);
    }

    function onTick() as Void {
        var step = interval();
        _sinceRefreshMs += step;
        _sinceVitalsMs += step;
        _frame++;
        if (_bounceTick >= 0) {
            _bounceTick++;
            if (_bounceTick >= _bounce.size()) {
                _bounceTick = -1;
            }
        }
        if (_stretchTicks > 0) {
            _stretchTicks--;
        }
        if (_bannerTicks > 0) {
            _bannerTicks--;
        }
        if (_sinceRefreshMs >= REFRESH_MS) {
            refresh(false);
        } else {
            WatchUi.requestUpdate();
        }
        schedule();
    }

    // ---------- drawing ----------

    function onUpdate(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var bg = MonkeyStatus.tintColor(MonkeyStatus.tint(_msg));
        dc.setColor(Graphics.COLOR_WHITE, bg);
        dc.clear();

        var takeover = MonkeyStatus.takesOverFace(_msg) && _bounceTick < 0 && _stretchTicks == 0;
        if (takeover) {
            drawSprite(dc, MonkeyStatus.POSE_ASLEEP, cx - MonkeyArt.CENTER_X * BIG_SCALE, 76, BIG_SCALE);
        } else {
            drawHeader(dc, cx, center);
            drawMeters(dc, cx);
            drawMonkey(dc, cx);
            drawGoal(dc, cx, center);
        }
        drawStatus(dc, cx, center);
    }

    private function drawMonkey(dc as Dc, cx as Number) as Void {
        var pose;
        var dy = 0;
        var dx = 0;
        if (_bounceTick >= 0) {
            pose = MonkeyStatus.POSE_EAT;
            dy = _bounce[_bounceTick] * SCALE / 2;
        } else if (_stretchTicks > 0) {
            pose = MonkeyStatus.POSE_STRETCH;
            dy = (_stretchTicks % 4 < 2) ? -4 : 0;
        } else {
            pose = MonkeyStatus.pose(_model.getPose(), _msg, _frame);
            if (pose == MonkeyStatus.POSE_JOG2) {
                dy = -4;
            }
            if (pose == MonkeyStatus.POSE_COLD) {
                dx = (_frame % 2 == 0) ? -2 : 2; // shiver
            }
        }
        drawSprite(dc, pose, cx - MonkeyArt.CENTER_X * SCALE + dx, MONKEY_Y + dy, SCALE);
    }

    // "Lv 3   240 XP" with a chunky XP bar, or the event banner for a few seconds.
    private function drawHeader(dc as Dc, cx as Number, center as Number) as Void {
        if (_bannerTicks > 0) {
            dc.setColor(_bannerColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 30, Graphics.FONT_XTINY, _bannerText, center);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var t = text(:level) + " " + _model.getLevel() + "   " + Fmt.thousands(_model.getXp()) + " " + text(:xp);
            dc.drawText(cx, 30, Graphics.FONT_XTINY, t, center);
        }
        drawSegments(dc, cx - 40, 44, 80, 5, 10, _model.getLevelPermille(), 0x55AAFF);
    }

    // Energy (bolt, left) and Calm (heart, right): vertical 8-block meters.
    private function drawMeters(dc as Dc, cx as Number) as Void {
        var e = energyMeter();
        var c = calmMeter();
        drawBolt(dc, cx - 101, 72);
        drawHeart(dc, cx + 95, 72);
        drawVertical(dc, cx - 102, 86, e, levelColor(e, 0xFFFF00));
        drawVertical(dc, cx + 94, 86, c, levelColor(c, 0x55FFFF));
    }

    private static function levelColor(v as Number?, good as Number) as Number {
        if (v == null) {
            return 0x555555;
        }
        return (v >= 50) ? good : ((v >= 25) ? 0xFFAA00 : 0xFF5555);
    }

    private function drawVertical(dc as Dc, x as Number, y as Number, value as Number?, color as Number) as Void {
        var count = 8;
        var seg = 8;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x - 2, y - 2, 12, count * seg + 2);
        var filled = (value == null) ? 0 : (value * count + 50) / 100;
        for (var i = 0; i < count; i++) {
            var lit = (count - 1 - i) < filled;
            dc.setColor(lit ? color : 0x555555, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x, y + i * seg, 8, seg - 2);
        }
    }

    private function drawBolt(dc as Dc, x as Number, y as Number) as Void {
        dc.setColor(0xFFFF00, Graphics.COLOR_TRANSPARENT);
        var px = [[4, 0], [6, 0], [2, 2], [4, 2], [0, 4], [2, 4], [4, 4], [6, 4], [4, 6], [6, 6], [2, 8], [4, 8], [2, 10]];
        for (var i = 0; i < px.size(); i++) {
            dc.fillRectangle(x + px[i][0], y + px[i][1], 2, 2);
        }
    }

    private function drawHeart(dc as Dc, x as Number, y as Number) as Void {
        dc.setColor(0xFF5555, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y + 2, 4, 4);
        dc.fillRectangle(x + 6, y + 2, 4, 4);
        dc.fillRectangle(x + 1, y + 4, 8, 4);
        dc.fillRectangle(x + 3, y + 8, 4, 2);
        dc.fillRectangle(x + 4, y + 10, 2, 2);
    }

    private function drawGoal(dc as Dc, cx as Number, center as Number) as Void {
        var type = _model.getGoalType();
        var v = _model.getValue();
        var t;
        if (v == null) {
            t = _labels[type] + " " + text(:unavailable);
        } else {
            t = Fmt.thousands(v) + " / " + Fmt.thousands(_model.getTarget()) + " " + _units[type];
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 176, Graphics.FONT_TINY, t, center);
        var p = _model.getProgressPermille();
        var color = (p >= 1000) ? 0xFFFF55 : ((p >= 500) ? Graphics.COLOR_YELLOW : 0x55AA00);
        drawSegments(dc, cx - 80, 191, 160, 9, 20, p > 1000 ? 1000 : p, color);
    }

    // Pixel-style bar: `count` blocks with 2 px gaps on a black track.
    private function drawSegments(dc as Dc, x as Number, y as Number, width as Number, height as Number,
            count as Number, permille as Number, color as Number) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x - 2, y - 2, width + 2, height + 4);
        var seg = width / count;
        var filled = permille * count / 1000;
        for (var i = 0; i < count; i++) {
            dc.setColor(i < filled ? color : 0x555555, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x + i * seg, y, seg - 2, height);
        }
    }

    // Two lines at the bottom: demo label / status title, then recommendation / hints.
    private function drawStatus(dc as Dc, cx as Number, center as Number) as Void {
        var line1 = "";
        var color1 = Graphics.COLOR_LT_GRAY;
        var line2 = "";
        if (_msg != MonkeyStatus.MSG_NONE) {
            line1 = _titles[_msg];
            var good = _msg == MonkeyStatus.MSG_EXERCISING || _msg == MonkeyStatus.MSG_ADVENTUROUS;
            color1 = good ? 0x55FF55 : 0xFFAA00;
            line2 = _actions[_msg];
        } else {
            line1 = text(:hintLive);
            line2 = text(:hintMenu);
        }
        if (_model.isDemo()) {
            line1 = text(:demo) + " " + _demoLabels[_model.getDemoStage()];
            color1 = 0xFFAA00;
            if (_msg == MonkeyStatus.MSG_NONE) {
                line2 = text(:hintDemo);
            }
        }
        dc.setColor(color1, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 216, Graphics.FONT_XTINY, line1, center);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 236, Graphics.FONT_XTINY, line2, center);
    }
}
