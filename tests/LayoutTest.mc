import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Test;

// Every text line must fit the round 260x260 screen at the height it is drawn, in the real
// fonts, including worst cases (longest name, 5-digit XP, 3-digit heart rate, long banners).
// The usable width at a line is the circle's chord across the glyph band, minus a margin.

function measureDc() as Dc {
    var ref = Graphics.createBufferedBitmap({:width => 260, :height => 40});
    return (ref.get() as BufferedBitmap).getDc();
}

function res(id as ResourceId) as String {
    return Application.loadResource(id) as String;
}

// Usable width for text centred at y: chord at the glyph band edge farthest from the centre.
function widthAt(dc as Dc, y as Number, font as FontDefinition) as Number {
    var band = dc.getFontHeight(font) / 3;
    var top = (y - band - 130).abs();
    var bottom = (y + band - 130).abs();
    var d = (top > bottom) ? top : bottom;
    if (d >= 130) {
        return 0;
    }
    return (2 * Math.sqrt(130 * 130 - d * d)).toNumber() - 10;
}

class LayoutChecker {

    private var _dc as Dc;
    private var _logger as Logger;
    var failures as Number = 0;

    function initialize(dc as Dc, logger as Logger) {
        _dc = dc;
        _logger = logger;
    }

    function check(text as String, font as FontDefinition, y as Number, extra as Number) as Void {
        var w = _dc.getTextWidthInPixels(text, font) + extra;
        var max = widthAt(_dc, y, font);
        if (w > max) {
            failures++;
            _logger.error("y=" + y + " " + w + " > " + max + ": " + text);
        }
    }

    function checkAll(ids as Array<ResourceId>, font as FontDefinition, y as Number) as Void {
        for (var i = 0; i < ids.size(); i++) {
            check(res(ids[i]), font, y, 0);
        }
    }
}

(:test)
function everyScreenFitsTheRoundDisplay(logger as Logger) as Boolean {
    var dc = measureDc();
    var c = new LayoutChecker(dc, logger);
    var xt = Graphics.FONT_XTINY;
    var name = res(Rez.Strings.Name0); // all names are 4 letters

    // Dashboard header (y=30): longest normal line and the event banners.
    var lv = res(Rez.Strings.Level);
    c.check(name + " " + lv + " 12 12,345 XP", xt, 35, 0);
    c.check(res(Rez.Strings.Explored) + " +30", xt, 35, 0);
    c.check(res(Rez.Strings.Breathed) + " +10 XP", xt, 35, 0);
    c.check(res(Rez.Strings.Revived) + " +20 XP", xt, 35, 0);
    c.check(res(Rez.Strings.GoalHit) + " +350 XP", xt, 35, 0);
    c.check(res(Rez.Strings.GoalMissed) + " -150 XP", xt, 35, 0);
    c.check(res(Rez.Strings.Evolved) + " " + res(Rez.Strings.Stage3) + "!", xt, 35, 0);
    c.check(res(Rez.Strings.Calmed), xt, 35, 0);
    c.check(res(Rez.Strings.Climbed) + " +30", xt, 35, 0);
    c.check(res(Rez.Strings.Sunglasses), xt, 35, 0);
    // Goal counter (y=176, FONT_TINY).
    c.check("10,000 / 10,000 " + res(Rez.Strings.UnitSteps), Graphics.FONT_TINY, 172, 0);
    c.check("60 / 60 " + res(Rez.Strings.UnitActive), Graphics.FONT_TINY, 172, 0);
    c.check(res(Rez.Strings.GoalActiveShort) + " " + res(Rez.Strings.Unavailable), Graphics.FONT_TINY, 172, 0);
    // Status lines (y=216 / 236).
    c.checkAll([Rez.Strings.St0, Rez.Strings.St1, Rez.Strings.St2, Rez.Strings.St3, Rez.Strings.St4,
        Rez.Strings.St5, Rez.Strings.St6, Rez.Strings.St7, Rez.Strings.St8, Rez.Strings.St9,
        Rez.Strings.St10, Rez.Strings.St11, Rez.Strings.St12, Rez.Strings.St13, Rez.Strings.St14, Rez.Strings.HintLive] as Array<ResourceId>, xt, 208);
    c.checkAll([Rez.Strings.Dm0, Rez.Strings.Dm1, Rez.Strings.Dm2, Rez.Strings.Dm3, Rez.Strings.Dm4,
        Rez.Strings.Dm5, Rez.Strings.Dm6, Rez.Strings.Dm7, Rez.Strings.Dm8, Rez.Strings.Dm9,
        Rez.Strings.Dm10, Rez.Strings.Dm11, Rez.Strings.Dm12, Rez.Strings.Dm13, Rez.Strings.Dm14,
        Rez.Strings.Dm15, Rez.Strings.Dm16, Rez.Strings.Dm17, Rez.Strings.Dm18, Rez.Strings.Dm19] as Array<ResourceId>, xt, 208);
    c.checkAll([Rez.Strings.Ac0, Rez.Strings.Ac1, Rez.Strings.Ac2, Rez.Strings.Ac3, Rez.Strings.Ac4,
        Rez.Strings.Ac5, Rez.Strings.Ac6, Rez.Strings.Ac7, Rez.Strings.Ac8, Rez.Strings.Ac9,
        Rez.Strings.Ac10, Rez.Strings.Ac11, Rez.Strings.Ac12, Rez.Strings.Ac13, Rez.Strings.Ac14,
        Rez.Strings.HintMenu, Rez.Strings.HintDemo] as Array<ResourceId>, xt, 227);
    c.check(res(Rez.Strings.BodyBattery) + " 100/100", xt, 227, 0);
    c.check(res(Rez.Strings.Demo), xt, 12, 0);

    // Onboarding.
    c.check(res(Rez.Strings.AppName), Graphics.FONT_SMALL, 40, 0);
    c.check(res(Rez.Strings.WelcomeLine), xt, 172, 0);
    c.check(res(Rez.Strings.WelcomeStart), xt, 210, 0);
    c.check(res(Rez.Strings.PickFurSetup), Graphics.FONT_SMALL, 40, 0);
    c.checkAll([Rez.Strings.Fur0, Rez.Strings.Fur1, Rez.Strings.Fur2, Rez.Strings.Fur3] as Array<ResourceId>, Graphics.FONT_TINY, 172);
    c.check(res(Rez.Strings.FurHint), xt, 210, 0);
    c.check(res(Rez.Strings.Hatching), Graphics.FONT_SMALL, 40, 0);
    c.check(name + " " + res(Rez.Strings.Hatched), Graphics.FONT_SMALL, 44, 0);
    c.check(res(Rez.Strings.HatchStart), xt, 222, 0);

    // Reminder.
    c.check(name, Graphics.FONT_SMALL, 34, 0);
    c.check(res(Rez.Strings.NeedsYou), xt, 56, 0);
    c.check(res(Rez.Strings.ReminderBreathe), xt, 208, 0);
    c.check(res(Rez.Strings.ReminderGo), xt, 208, 0);
    c.check(res(Rez.Strings.ReminderLater), xt, 230, 0);

    // Day recap.
    c.check(res(Rez.Strings.RecapTitle), Graphics.FONT_SMALL, 34, 0);
    c.check("100% " + res(Rez.Strings.RecapOfGoal), xt, 152, 0);
    c.check("12,345 XP  -150", Graphics.FONT_TINY, 174, 0);
    c.check(res(Rez.Strings.RecapStreak) + " 30 > 0", xt, 196, 12);
    c.check(res(Rez.Strings.RecapTomorrow), xt, 215, 0);

    // Journey.
    c.check(res(Rez.Strings.JourneyTitle), Graphics.FONT_SMALL, 34, 0);
    c.check(res(Rez.Strings.Jr4) + " - " + res(Rez.Strings.Stage4), xt, 57, 0);
    c.check(res(Rez.Strings.Jr3) + " - " + res(Rez.Strings.Stage3), xt, 57, 0);
    c.check(lv + " 12 - " + res(Rez.Strings.Stage3), xt, 57, 0);
    c.check("12,345 " + res(Rez.Strings.StepsPerDay), xt, 194, 0);
    c.check("+111% " + res(Rez.Strings.SinceDay1), xt, 215, 0);

    // Breathing.
    c.checkAll([Rez.Strings.BreathIn, Rez.Strings.BreathHold, Rez.Strings.BreathOut] as Array<ResourceId>, Graphics.FONT_SMALL, 28);
    c.check(res(Rez.Strings.BreathDone), xt, 28, 0);
    c.check(res(Rez.Strings.Hr) + " 120 > 100  +10 " + res(Rez.Strings.Xp), xt, 196, 0);
    c.check(res(Rez.Strings.BreathAgain), xt, 218, 0);
    c.check(res(Rez.Strings.BreathSkip), xt, 52, 0);

    // Glance (171 px wide content area).
    var glance = Graphics.FONT_GLANCE;
    var gl = [res(Rez.Strings.GlanceName) + "  " + lv + " 12", "10,000 / 10,000 " + res(Rez.Strings.UnitSteps)];
    for (var i = 0; i < gl.size(); i++) {
        var w = dc.getTextWidthInPixels(gl[i], glance);
        if (w > 165) {
            c.failures++;
            logger.error("glance " + w + " > 165: " + gl[i]);
        }
    }

    logger.debug("layout failures: " + c.failures);
    Test.assertEqual(c.failures, 0);
    return true;
}
