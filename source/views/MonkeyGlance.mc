import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Glance in the watch's widget list: "Monkey Miles  Lv 3", the monkey's status or goal
// progress, and a thin progress bar. Reads only Storage (written by the app and the
// background service) and Garmin's daily total — cheap enough for the glance's 64 KB.
(:glance)
class MonkeyGlance extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var left = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

        var xp = readNumber(Goals.KEY_XP, 0);
        var type = readNumber(Goals.KEY_TYPE, Goals.GOAL_STEPS);
        if (type < 0 || type >= Goals.GOAL_TYPES) {
            type = Goals.GOAL_STEPS;
        }
        var target = readNumber(Goals.KEY_TARGET, Goals.defaultTarget(type));
        var value = ActivityService.todayValue(type);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var title = load(Rez.Strings.GlanceName) + "  " + load(Rez.Strings.Level) + " " + (1 + xp / 300);
        dc.drawText(0, h / 5, Graphics.FONT_GLANCE, title, left);

        var line;
        var msg = currentMsg();
        if (msg != MonkeyStatus.MSG_NONE) {
            var ids = [Rez.Strings.St0, Rez.Strings.St1, Rez.Strings.St2, Rez.Strings.St3,
                Rez.Strings.St4, Rez.Strings.St5, Rez.Strings.St6, Rez.Strings.St7, Rez.Strings.St8,
                Rez.Strings.St9, Rez.Strings.St10, Rez.Strings.St11, Rez.Strings.St12, Rez.Strings.St13];
            line = load(ids[msg]);
            var good = msg == MonkeyStatus.MSG_EXERCISING || msg == MonkeyStatus.MSG_ADVENTUROUS;
            dc.setColor(good ? 0x55FF55 : 0xFFAA00, Graphics.COLOR_TRANSPARENT);
        } else if (value == null) {
            line = load(Rez.Strings.Unavailable);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        } else {
            var units = [Rez.Strings.UnitSteps, Rez.Strings.UnitActive, Rez.Strings.UnitFloors];
            line = Fmt.thousands(value) + " / " + Fmt.thousands(target) + " " + load(units[type]);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(0, h / 2, Graphics.FONT_GLANCE, line, left);

        var p = (value == null || target <= 0) ? 0 : value * 1000 / target;
        if (p > 1000) {
            p = 1000;
        }
        var barY = h * 4 / 5;
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, barY, w, 4);
        dc.setColor(p >= 1000 ? 0xFFFF55 : (p >= 500 ? 0xFFFF00 : 0x55AA00), Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, barY, w * p / 1000, 4);
    }

    // Status from the last stored vitals of today (stale days count as nothing to report).
    private function currentMsg() as Number {
        var st = Storage.getValue("vState");
        if (!(st instanceof Array) || st.size() < 3) {
            return MonkeyStatus.MSG_NONE;
        }
        var day = st[0];
        var energy = st[1];
        var calm = st[2];
        if (!(day instanceof Number) || day != DayClock.today()
                || !(energy instanceof Number) || !(calm instanceof Number)) {
            return MonkeyStatus.MSG_NONE;
        }
        var breath = (st.size() >= 8 && st[6] instanceof Number) ? st[6] as Number : Vitals.BREATH_NORMAL;
        var warmth = (st.size() >= 8 && st[7] instanceof Number) ? st[7] as Number : Vitals.WARMTH_OK;
        return MonkeyStatus.message(energy, calm, false, breath, warmth, Vitals.CURIOUS_CONTENT);
    }

    private static function load(id as ResourceId) as String {
        return Application.loadResource(id) as String;
    }

    private static function readNumber(key as String, fallback as Number) as Number {
        var v = Storage.getValue(key);
        return (v instanceof Number) ? v : fallback;
    }
}
