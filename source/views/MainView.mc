import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Startup screen. Draws directly with the Dc (no layout XML) to keep it small.
// Redraws only when the system asks or the delegate calls WatchUi.requestUpdate().
class MainView extends WatchUi.View {

    private var _model as StarterModel;
    private var _title as String = "";
    private var _status as String = "";
    private var _pressesLabel as String = "";
    private var _hint as String = "";

    function initialize(model as StarterModel) {
        View.initialize();
        _model = model;
    }

    // Load resources once, not on every onUpdate().
    function onLayout(dc as Dc) as Void {
        _title = WatchUi.loadResource(Rez.Strings.Title) as String;
        _status = WatchUi.loadResource(Rez.Strings.Status) as String;
        _pressesLabel = WatchUi.loadResource(Rez.Strings.PressesLabel) as String;
        _hint = WatchUi.loadResource(Rez.Strings.Hint) as String;
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 32 / 100, Graphics.FONT_MEDIUM, _title, center);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 50 / 100, Graphics.FONT_SMALL, _status, center);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 65 / 100, Graphics.FONT_TINY,
            Lang.format("$1$: $2$", [_pressesLabel, _model.getPressCount()]), center);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 80 / 100, Graphics.FONT_XTINY, _hint, center);
    }
}
