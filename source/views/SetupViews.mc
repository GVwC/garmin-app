import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Onboarding ("create your monkey"):
//   WelcomeView (egg wobbles) -> name menu -> FurPickerView (egg spots preview the fur)
//   -> goals menu (setup mode, "Done") -> HatchView (egg cracks, baby pops out) -> dashboard.
// Timers run only while each screen is visible.

// Shared drawing for the setup screens.
module SetupDraw {

    const BG = 0x005500;

    function clear(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, BG);
        dc.clear();
    }

    function title(dc as Dc, text as String, y as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, y, Graphics.FONT_SMALL, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function hint(dc as Dc, text as String, y as Number) as Void {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, y, Graphics.FONT_XTINY, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

// Egg with a gentle wobble; START begins setup.
class WelcomeView extends WatchUi.View {

    private var _egg as Array<Number> = [];
    private var _colors as Array<Number> = [];
    private var _timer as Timer.Timer?;
    private var _frame as Number = 0;
    private var _fur as Number;

    function initialize(fur as Number) {
        View.initialize();
        _fur = fur;
    }

    function onLayout(dc as Dc) as Void {
        _egg = PixelSprite.compile([EggArt.egg()]);
        _colors = PixelSprite.paletteFor(_fur);
    }

    function onShow() as Void {
        var t = new Timer.Timer();
        t.start(method(:onTick), 300, true);
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
        _frame++;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        SetupDraw.clear(dc);
        var cx = dc.getWidth() / 2;
        SetupDraw.title(dc, WatchUi.loadResource(Rez.Strings.AppName) as String, 40);
        var wobble = [0, -3, 0, 3][_frame % 4];
        PixelSprite.draw(dc, _egg, _colors, cx - EggArt.WIDTH * 2 + wobble, 70, 4);
        dc.setColor(0xFFFF55, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 172, Graphics.FONT_XTINY, WatchUi.loadResource(Rez.Strings.WelcomeLine) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        SetupDraw.hint(dc, WatchUi.loadResource(Rez.Strings.WelcomeStart) as String, 210);
    }
}

// UP/DOWN cycles the fur colour; the egg's spots show it. START confirms.
class FurPickerView extends WatchUi.View {

    private var _model as MonkeyModel;
    private var _egg as Array<Number> = [];

    function initialize(model as MonkeyModel) {
        View.initialize();
        _model = model;
    }

    function onLayout(dc as Dc) as Void {
        _egg = PixelSprite.compile([EggArt.egg()]);
    }

    function cycle(step as Number) as Void {
        _model.setFur((_model.getFur() + step + MonkeyModel.FUR_COUNT) % MonkeyModel.FUR_COUNT);
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        SetupDraw.clear(dc);
        var cx = dc.getWidth() / 2;
        SetupDraw.title(dc, WatchUi.loadResource(Rez.Strings.PickFurSetup) as String, 40);
        PixelSprite.draw(dc, _egg, PixelSprite.paletteFor(_model.getFur()), cx - EggArt.WIDTH * 2, 66, 4);
        // Arrows hint that UP/DOWN change the colour.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[cx - 62, 106], [cx - 52, 98], [cx - 52, 114]]);
        dc.fillPolygon([[cx + 62, 106], [cx + 52, 98], [cx + 52, 114]]);
        dc.setColor(0xFFFF55, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 172, Graphics.FONT_TINY, Menus.furLabel(_model.getFur()),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        SetupDraw.hint(dc, WatchUi.loadResource(Rez.Strings.FurHint) as String, 210);
    }
}

// Wobble, crack, crack, pop: the baby monkey appears in its shell with sparkles.
class HatchView extends WatchUi.View {

    private static const TICK_MS = 150;
    private static const HATCH_TICK = 16; // ~2.4 s of wobbling and cracking

    private var _model as MonkeyModel;
    private var _timer as Timer.Timer?;
    private var _tick as Number = 0;
    private var _egg as Array<Number> = [];
    private var _crack1 as Array<Number> = [];
    private var _crack2 as Array<Number> = [];
    private var _body as Array<Number> = [];
    private var _pose as Array<Number> = [];
    private var _shell as Array<Number> = [];
    private var _sparkles as Array<Number> = [];

    function initialize(model as MonkeyModel) {
        View.initialize();
        _model = model;
    }

    function onLayout(dc as Dc) as Void {
        _egg = PixelSprite.compile([EggArt.egg()]);
        _crack1 = PixelSprite.compile([EggArt.crack1()]);
        _crack2 = PixelSprite.compile([EggArt.crack2()]);
    }

    function onShow() as Void {
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

    function isHatched() as Boolean {
        return _tick >= HATCH_TICK;
    }

    function onTick() as Void {
        _tick++;
        if (_tick == HATCH_TICK) {
            // Compile the baby only now (keeps onLayout light for the watchdog).
            _body = PixelSprite.compile([MonkeyArt.body()]);
            _pose = PixelSprite.compile([MonkeyArt.stretchPose()]);
            _shell = PixelSprite.compile([EggArt.shellBottom()]);
            _sparkles = PixelSprite.compile([EggArt.sparkles()]);
        }
        if (_tick > HATCH_TICK + 20) {
            var t = _timer;
            if (t != null) {
                t.stop(); // hold the final frame
            }
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        SetupDraw.clear(dc);
        var cx = dc.getWidth() / 2;
        var colors = PixelSprite.paletteFor(_model.getFur());
        if (!isHatched()) {
            var wobble = (_tick % 2 == 0) ? -3 : 3;
            var x = cx - EggArt.WIDTH * 2 + wobble;
            PixelSprite.draw(dc, _egg, colors, x, 66, 4);
            if (_tick >= HATCH_TICK / 2) {
                PixelSprite.draw(dc, _crack1, colors, x, 66, 4);
            }
            if (_tick >= HATCH_TICK * 3 / 4) {
                PixelSprite.draw(dc, _crack2, colors, x, 66, 4);
            }
            SetupDraw.title(dc, WatchUi.loadResource(Rez.Strings.Hatching) as String, 40);
            return;
        }
        // Baby (scale 3) sitting in the bottom half of the shell.
        var s = Growth.scaleFor(Growth.STAGE_BABY);
        var bounce = (_tick - HATCH_TICK < 8 && _tick % 2 == 0) ? -6 : 0;
        var x0 = cx - MonkeyArt.CENTER_X * s;
        var y0 = 84 + bounce;
        PixelSprite.draw(dc, _body, colors, x0, y0, s);
        PixelSprite.draw(dc, _pose, colors, x0, y0, s);
        PixelSprite.draw(dc, _shell, colors, x0 + 4 * s, y0 + 14 * s, s);
        if (_tick % 4 < 2) {
            PixelSprite.draw(dc, _sparkles, colors, x0, y0, s);
        }
        dc.setColor(0xFFFF55, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 44, Graphics.FONT_SMALL, Menus.nameLabel(_model.getName()) + " " +
            (WatchUi.loadResource(Rez.Strings.Hatched) as String),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        SetupDraw.hint(dc, WatchUi.loadResource(Rez.Strings.HatchStart) as String, 222);
    }
}
