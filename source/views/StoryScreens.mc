import Toybox.ActivityMonitor;
import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Full-screen story moments, used by story mode and by live mode:
//   ReminderView  "Momo needs you!" — buzz + shaking monkey + what to do (START) or later (BACK)
//   RecapView     end of a missed day — sad monkey, XP counting down, streak flame going out
//   JourneyView   growth egg -> king next to *your* progress (weekly steps chart)
// Each owns a short-lived timer that stops in onHide.

// Small pixel icons shared by the story screens.
module StoryDraw {

    // 10x12 flame; grey when it has gone out.
    function flame(dc as Dc, x as Number, y as Number, out as Boolean) as Void {
        dc.setColor(out ? 0x555555 : 0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + 4, y, 2, 2);
        dc.fillRectangle(x + 2, y + 2, 6, 3);
        dc.fillRectangle(x, y + 5, 10, 5);
        dc.fillRectangle(x + 2, y + 10, 6, 2);
        dc.setColor(out ? 0xAAAAAA : 0xFFFF00, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + 4, y + 6, 2, 4);
    }
}

// Reminder message: wrapped into at most 3 lines of 196 px (the box between the monkey and
// the buttons, centred at y=154). fitTextToArea needs more than the nominal font height per
// line, so the box is sized for 3 lines plus leading.
module ReminderText {

    const WIDTH = 196;
    const LINES = 3;

    function fit(text as String) as String {
        var h = Graphics.getFontHeight(Graphics.FONT_XTINY) * (LINES + 1);
        var fitted = Graphics.fitTextToArea(text, Graphics.FONT_XTINY, WIDTH, h, true);
        return (fitted != null) ? fitted : text;
    }
}

// Common bits: compile once per view, draw a pose with fur colours.
class StorySprite {

    private var _body as Array<Number>;
    private var _colors as Array<Number>;

    function initialize(fur as Number) {
        _body = PixelSprite.compile([MonkeyArt.body()]);
        _colors = PixelSprite.paletteFor(fur);
    }

    function colors() as Array<Number> {
        return _colors;
    }

    function draw(dc as Dc, poseRuns as Array<Number>, extra as Array<Number>?, x as Number, y as Number, scale as Number) as Void {
        PixelSprite.draw(dc, _body, _colors, x, y, scale);
        PixelSprite.draw(dc, poseRuns, _colors, x, y, scale);
        if (extra != null) {
            PixelSprite.draw(dc, extra, _colors, x, y, scale);
        }
    }
}

// ---------------------------------------------------------------- reminder

class ReminderView extends WatchUi.View {

    private var _model as MonkeyModel;
    private var _kind as Number;
    private var _timer as Timer.Timer?;
    private var _tick as Number = 0;
    private var _sprite as StorySprite?;
    private var _pose as Array<Number> = [];
    private var _message as String = "";

    function initialize(model as MonkeyModel, kind as Number) {
        View.initialize();
        _model = model;
        _kind = kind;
    }

    function getKind() as Number {
        return _kind;
    }

    // Stress / breath reminders offer the breathing screen on START.
    function offersBreathing() as Boolean {
        return _kind == VitalsModel.NUDGE_STRESSED || _kind == VitalsModel.NUDGE_BREATH;
    }

    function onLayout(dc as Dc) as Void {
        _sprite = new StorySprite(_model.getFur());
        var poses = [MonkeyArt.asleepPose(), MonkeyArt.stressedPose(), MonkeyArt.tiredPose(), MonkeyArt.tiredPose(),
            MonkeyArt.sadPose(), MonkeyArt.pantPose(), MonkeyArt.coldPose(), MonkeyArt.hotPose()];
        _pose = PixelSprite.compile([poses[_kind]]);
        var ids = [Rez.Strings.Nudge0, Rez.Strings.Nudge1, Rez.Strings.Nudge2, Rez.Strings.Nudge3,
            Rez.Strings.Nudge4, Rez.Strings.Nudge5, Rez.Strings.Nudge6, Rez.Strings.Nudge7];
        _message = WatchUi.loadResource(ids[_kind]) as String;
    }

    function onShow() as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([
                new Attention.VibeProfile(80, 250),
                new Attention.VibeProfile(0, 150),
                new Attention.VibeProfile(80, 250)
            ] as Array<VibeProfile>);
        }
        var t = new Timer.Timer();
        t.start(method(:onTick), 120, true);
        _timer = t;
    }

    function onHide() as Void {
        var t = _timer;
        if (t != null) {
            t.stop();
        }
        _timer = null;
    }

    function onTick() as Void {
        _tick++;
        if (_tick > 60) {
            onHide(); // stop animating after ~7 s
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.setColor(Graphics.COLOR_WHITE, 0x000000);
        dc.clear();
        // Pulsing orange ring = "attention".
        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(_tick % 6 < 3 ? 6 : 3);
        dc.drawCircle(cx, dc.getHeight() / 2, cx - 4);
        dc.setPenWidth(1);

        var name = Menus.nameLabel(_model.getName());
        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 32, Graphics.FONT_SMALL, name, center);
        dc.drawText(cx, 54, Graphics.FONT_XTINY, WatchUi.loadResource(Rez.Strings.NeedsYou) as String, center);

        var shake = (_tick < 20) ? ((_tick % 2 == 0) ? -4 : 4) : ((_tick % 10 < 5) ? 0 : -3);
        var sprite = _sprite;
        if (sprite != null) {
            // Smaller monkey (x2) leaves room for a 3-line message.
            sprite.draw(dc, _pose, null, cx - MonkeyArt.CENTER_X * 2 + shake, 70, 2);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 154, Graphics.FONT_XTINY, ReminderText.fit(_message), center);
        dc.setColor(0xFFFF55, Graphics.COLOR_TRANSPARENT);
        var hint = offersBreathing() ? Rez.Strings.ReminderBreathe : Rez.Strings.ReminderGo;
        dc.drawText(cx, 202, Graphics.FONT_XTINY, WatchUi.loadResource(hint) as String, center);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 223, Graphics.FONT_XTINY, WatchUi.loadResource(Rez.Strings.ReminderLater) as String, center);
    }
}

// ---------------------------------------------------------------- day recap (missed)

class RecapView extends WatchUi.View {

    private static const TICK_MS = 80;

    private var _model as MonkeyModel;
    private var _xpBefore as Number;
    private var _xpAfter as Number;
    private var _streakBefore as Number;
    private var _percent as Number;
    private var _timer as Timer.Timer?;
    private var _tick as Number = 0;
    private var _sprite as StorySprite?;
    private var _pose as Array<Number> = [];

    // xpDelta is negative; percent = how far the shown goal got.
    function initialize(model as MonkeyModel, xpDelta as Number, streakBefore as Number, percent as Number) {
        View.initialize();
        _model = model;
        _xpAfter = model.getXp();
        _xpBefore = _xpAfter - xpDelta;
        _streakBefore = streakBefore;
        _percent = percent;
    }

    function onLayout(dc as Dc) as Void {
        _sprite = new StorySprite(_model.getFur());
        _pose = PixelSprite.compile([MonkeyArt.sadPose()]);
    }

    function onShow() as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(40, 400)] as Array<VibeProfile>);
        }
        var t = new Timer.Timer();
        t.start(method(:onTick), TICK_MS, true);
        _timer = t;
    }

    function onHide() as Void {
        var t = _timer;
        if (t != null) {
            t.stop();
        }
        _timer = null;
    }

    function onTick() as Void {
        _tick++;
        if (_tick > 40) {
            onHide();
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.setColor(Graphics.COLOR_WHITE, 0x000055);
        dc.clear();
        dc.drawText(cx, 34, Graphics.FONT_SMALL, WatchUi.loadResource(Rez.Strings.RecapTitle) as String, center);

        // The monkey slumps a little as the XP drains.
        var slump = (_tick < 20) ? _tick / 5 : 4;
        var sprite = _sprite;
        if (sprite != null) {
            sprite.draw(dc, _pose, null, cx - MonkeyArt.CENTER_X * 3, 52 + slump, 3);
        }

        // Goal bar (missed) and how far it got.
        var x = cx - 64;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x - 2, 128, 132, 12);
        dc.setColor(0xFF5555, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, 130, 128 * _percent / 100, 8);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 152, Graphics.FONT_XTINY, _percent + "% " + (WatchUi.loadResource(Rez.Strings.RecapOfGoal) as String), center);

        // XP counting down.
        var p = (_tick > 20) ? 20 : _tick;
        var xp = _xpBefore + (_xpAfter - _xpBefore) * p / 20;
        dc.setColor(0xFF5555, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 174, Graphics.FONT_TINY, Fmt.thousands(xp) + " XP  " + Fmt.signed(_xpAfter - _xpBefore), center);

        // Streak flame going out (icon + text centred together).
        var out = _tick > 24;
        var streak = (WatchUi.loadResource(Rez.Strings.RecapStreak) as String) + " " + _streakBefore + " > " + (out ? 0 : _streakBefore);
        var w = dc.getTextWidthInPixels(streak, Graphics.FONT_XTINY);
        var fx = cx - (w + 12) / 2;
        StoryDraw.flame(dc, fx, 189, out);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(fx + 12, 196, Graphics.FONT_XTINY, streak, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0xFFFF55, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 215, Graphics.FONT_XTINY, WatchUi.loadResource(Rez.Strings.RecapTomorrow) as String, center);
    }
}

// ---------------------------------------------------------------- journey

class JourneyView extends WatchUi.View {

    private static const FRAME_MS = 1600;

    private var _model as MonkeyModel;
    private var _story as Boolean;
    private var _timer as Timer.Timer?;
    private var _frame as Number = 0;
    private var _sprite as StorySprite?;
    private var _relax as Array<Number> = [];
    private var _egg as Array<Number> = [];
    private var _acc as Array<Array<Number> > = [];
    private var _labels as Array<String> = [];
    private var _stages as Array<String> = [];

    // Story: the monkey grows egg -> king over five frames with scripted weekly steps.
    // Live: current stage and the real last 7 days.
    function initialize(model as MonkeyModel, story as Boolean) {
        View.initialize();
        _model = model;
        _story = story;
    }

    function onLayout(dc as Dc) as Void {
        _sprite = new StorySprite(_model.getFur());
        _relax = PixelSprite.compile([MonkeyArt.relaxPose()]);
        _egg = PixelSprite.compile([EggArt.egg()]);
        _acc = [PixelSprite.compile([MonkeyArt.leafAccessory()]), PixelSprite.compile([MonkeyArt.bandAccessory()]),
            PixelSprite.compile([MonkeyArt.crownAccessory()])];
        var r = [Rez.Strings.Jr0, Rez.Strings.Jr1, Rez.Strings.Jr2, Rez.Strings.Jr3, Rez.Strings.Jr4];
        for (var i = 0; i < r.size(); i++) {
            _labels.add(WatchUi.loadResource(r[i]) as String);
        }
        var st = [Rez.Strings.Stage0, Rez.Strings.Stage1, Rez.Strings.Stage2, Rez.Strings.Stage3, Rez.Strings.Stage4];
        for (var i = 0; i < st.size(); i++) {
            _stages.add(WatchUi.loadResource(st[i]) as String);
        }
    }

    function onShow() as Void {
        if (_story) {
            var t = new Timer.Timer();
            t.start(method(:onTick), FRAME_MS, true);
            _timer = t;
        }
    }

    function onHide() as Void {
        var t = _timer;
        if (t != null) {
            t.stop();
        }
        _timer = null;
    }

    function onTick() as Void {
        if (_frame < 4) {
            _frame++;
            if (Attention has :vibrate) {
                Attention.vibrate([new Attention.VibeProfile(50, 120)] as Array<VibeProfile>);
            }
        } else {
            onHide();
        }
        WatchUi.requestUpdate();
    }

    // Scripted weekly steps per frame (story) — rising as the habit builds.
    private function storyWeek(frame as Number) as Array<Number> {
        var weeks = [
            [0, 0, 0, 0, 0, 0, 0],
            [3100, 4200, 2600, 5200, 3900, 4400, 5000],
            [4800, 5600, 5200, 6100, 4900, 6300, 5800],
            [6600, 7200, 6900, 7800, 7100, 6800, 7500],
            [8100, 8600, 7900, 9300, 8200, 8800, 9100]
        ];
        return weeks[frame] as Array<Number>;
    }

    // Live: last 7 days of steps from the watch (oldest first), today last.
    private function liveWeek() as Array<Number> {
        var out = [] as Array<Number>;
        var hist = ActivityMonitor.getHistory();
        for (var i = hist.size() - 1; i >= 0 && out.size() < 6; i--) {
            var v = hist[i].steps;
            out.add(v != null ? v : 0);
        }
        var today = ActivityMonitor.getInfo().steps;
        out.add(today != null ? today : 0);
        return out;
    }

    function onUpdate(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.setColor(Graphics.COLOR_WHITE, 0x005500);
        dc.clear();
        dc.drawText(cx, 34, Graphics.FONT_SMALL, WatchUi.loadResource(Rez.Strings.JourneyTitle) as String, center);

        var stage = _story ? _frame : Growth.stageFor(_model.getLevel(), true);
        var label = _story ? _labels[_frame] : (WatchUi.loadResource(Rez.Strings.Level) as String) + " " + _model.getLevel();
        dc.setColor(0xFFFF55, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 57, Graphics.FONT_XTINY, label + " - " + _stages[stage], center);

        // The monkey stands on a fixed baseline (y=146) and grows: baby x2, then x3 with accessories.
        var baseline = 146;
        var sprite = _sprite;
        if (sprite != null) {
            if (stage == Growth.STAGE_EGG) {
                PixelSprite.draw(dc, _egg, sprite.colors(), cx - EggArt.WIDTH * 3 / 2, baseline - EggArt.HEIGHT * 3, 3);
            } else {
                var s = (stage == Growth.STAGE_BABY) ? 2 : 3;
                var acc = Growth.accessoryFor(stage);
                sprite.draw(dc, _relax, acc >= 0 ? _acc[acc] : null, cx - MonkeyArt.CENTER_X * s, baseline - 23 * s, s);
            }
        }

        // You: 7-day steps chart (yellow = 5,000+) and the average.
        var week = _story ? storyWeek(_frame) : liveWeek();
        var max = 12000;
        var sum = 0;
        for (var i = 0; i < week.size(); i++) {
            max = (week[i] > max) ? week[i] : max;
            sum += week[i];
        }
        var bw = 10;
        var gap = 5;
        var bx = cx - (week.size() * (bw + gap) - gap) / 2;
        var top = 154;
        var h = 24;
        for (var i = 0; i < week.size(); i++) {
            var bh = h * week[i] / max;
            dc.setColor(0x003300, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(bx + i * (bw + gap), top, bw, h);
            dc.setColor(week[i] >= 5000 ? 0xFFFF00 : 0x55AA00, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(bx + i * (bw + gap), top + h - bh, bw, bh);
        }
        var avg = week.size() > 0 ? sum / week.size() : 0;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 194, Graphics.FONT_XTINY, Fmt.thousands(avg) + " " + (WatchUi.loadResource(Rez.Strings.StepsPerDay) as String), center);
        if (_story && _frame >= 2) {
            var first = 4057; // average of week 1
            dc.setColor(0x55FF55, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 215, Graphics.FONT_XTINY, "+" + ((avg - first) * 100 / first) + "% " +
                (WatchUi.loadResource(Rez.Strings.SinceDay1) as String), center);
        } else if (!_story) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 215, Graphics.FONT_XTINY, (WatchUi.loadResource(Rez.Strings.RecapStreak) as String) + " " + _model.getStreak(), center);
        }
    }
}

// BACK closes any story screen; START does the reminder's action (breathe) or closes.
class StoryScreenDelegate extends WatchUi.BehaviorDelegate {

    private var _model as MonkeyModel;
    private var _main as MainView;
    private var _reminder as ReminderView?;

    function initialize(model as MonkeyModel, main as MainView, reminder as ReminderView?) {
        BehaviorDelegate.initialize();
        _model = model;
        _main = main;
        _reminder = reminder;
    }

    function onSelect() as Boolean {
        var r = _reminder;
        if (r != null && r.offersBreathing()) {
            var breath = new BreathView(_model);
            WatchUi.switchToView(breath, new BreathDelegate(breath, _main), WatchUi.SLIDE_UP);
            return true;
        }
        return onBack();
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        _main.onModelChanged();
        return true;
    }
}
