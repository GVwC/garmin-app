import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Test;

// Every status / caption string must fit the round 260x260 screen in the real fonts.
// Usable widths: status line 1 at y=216 ~195 px, line 2 at y=236 ~150 px, glance 171 px
// (minus a small margin).

function measureDc() as Dc {
    var ref = Graphics.createBufferedBitmap({:width => 260, :height => 40});
    return (ref.get() as BufferedBitmap).getDc();
}

function assertFits(dc as Dc, ids as Array<ResourceId>, font as FontDefinition, max as Number, logger as Logger) as Void {
    for (var i = 0; i < ids.size(); i++) {
        var t = Application.loadResource(ids[i]) as String;
        var w = dc.getTextWidthInPixels(t, font);
        if (w > max) {
            logger.error("too wide (" + w + " > " + max + "): " + t);
        }
        Test.assert(w <= max);
    }
}

(:test)
function statusAndStoryTextFitTheScreen(logger as Logger) as Boolean {
    var dc = measureDc();
    var titles = [Rez.Strings.St0, Rez.Strings.St1, Rez.Strings.St2, Rez.Strings.St3, Rez.Strings.St4,
        Rez.Strings.St5, Rez.Strings.St6, Rez.Strings.St7, Rez.Strings.St8, Rez.Strings.St9,
        Rez.Strings.St10, Rez.Strings.St11, Rez.Strings.St12, Rez.Strings.St13] as Array<ResourceId>;
    var actions = [Rez.Strings.Ac0, Rez.Strings.Ac1, Rez.Strings.Ac2, Rez.Strings.Ac3, Rez.Strings.Ac4,
        Rez.Strings.Ac5, Rez.Strings.Ac6, Rez.Strings.Ac7, Rez.Strings.Ac8, Rez.Strings.Ac9,
        Rez.Strings.Ac10, Rez.Strings.Ac11, Rez.Strings.Ac12, Rez.Strings.Ac13] as Array<ResourceId>;
    var captions = [Rez.Strings.Dm0, Rez.Strings.Dm1, Rez.Strings.Dm2, Rez.Strings.Dm3, Rez.Strings.Dm4,
        Rez.Strings.Dm5, Rez.Strings.Dm6, Rez.Strings.Dm7, Rez.Strings.Dm8, Rez.Strings.Dm9,
        Rez.Strings.Dm10, Rez.Strings.Dm11, Rez.Strings.Dm12, Rez.Strings.Dm13, Rez.Strings.Dm14,
        Rez.Strings.Dm15, Rez.Strings.Dm16, Rez.Strings.Dm17, Rez.Strings.Dm18, Rez.Strings.Dm19] as Array<ResourceId>;
    assertFits(dc, titles, Graphics.FONT_XTINY, 187, logger);
    assertFits(dc, captions, Graphics.FONT_XTINY, 187, logger);
    assertFits(dc, actions, Graphics.FONT_XTINY, 142, logger);
    assertFits(dc, titles, Graphics.FONT_GLANCE, 165, logger);
    // Story line 2 for the recharge scene.
    var bb = (Application.loadResource(Rez.Strings.BodyBattery) as String) + " 100/100";
    Test.assert(dc.getTextWidthInPixels(bb, Graphics.FONT_XTINY) <= 142);
    // STORY badge (y=12) must not run into the header line (y=30).
    var h = dc.getFontHeight(Graphics.FONT_XTINY);
    logger.debug("xtiny height " + h);
    Test.assert(12 + h / 2 <= 30 - h / 2 + 4);
    return true;
}
