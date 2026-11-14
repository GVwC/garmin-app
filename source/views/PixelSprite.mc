import Toybox.Graphics;
import Toybox.Lang;

// Turns MonkeyArt patches into packed horizontal runs, then draws them as scaled rectangles.
// One Number per run: x | y | length | colour index. Compile is the slow part (char by char),
// so callers compile the shared body once and each pose's small patches lazily.
module PixelSprite {

    const OFFSET = 64; // lets patches use small negative x/y

    function palette() as Array<Number> {
        return [
            0x000000, // K outline
            0xAA5500, // B fur
            0x550000, // D dark fur
            0xFFAA55, // T tan
            0xFFAAAA, // P pink
            0xFFFFFF, // W white
            0x55AA00, // G green banana
            0xFFFF00, // Y yellow banana
            0xAA0000, // R mouth
            0x55AAFF  // C ice blue
        ];
    }

    // Palette with the character's fur (B) and dark fur (D): brown, golden, silver, shadow.
    function paletteFor(fur as Number) as Array<Number> {
        var p = palette();
        var furs = [[0xAA5500, 0x550000], [0xFFAA00, 0xAA5500], [0xAAAAAA, 0x555555], [0x555555, 0x000000]];
        if (fur >= 0 && fur < furs.size()) {
            p[1] = furs[fur][0];
            p[2] = furs[fur][1];
        }
        return p;
    }

    // layers: list of patch lists (body first, then pose); later patches paint over earlier ones.
    function compile(layers as Array<Array>) as Array<Number> {
        var out = [] as Array<Number>;
        var lookup = indexes();
        for (var l = 0; l < layers.size(); l++) {
            var patches = layers[l];
            for (var p = 0; p < patches.size(); p++) {
                var patch = patches[p] as Array;
                var px = patch[0] as Number;
                var py = patch[1] as Number;
                var rows = patch[2] as Array<String>;
                for (var j = 0; j < rows.size(); j++) {
                    addRuns(out, px, py + j, rows[j].toCharArray(), lookup);
                }
            }
        }
        return out;
    }

    function addRuns(out as Array<Number>, x0 as Number, y as Number, chars as Array<Char>,
            lookup as Dictionary<Char, Number>) as Void {
        var n = chars.size();
        var i = 0;
        while (i < n) {
            var c = chars[i];
            var idx = lookup[c];
            if (idx == null) {
                i++;
                continue;
            }
            var start = i;
            i++;
            while (i < n && chars[i] == c) {
                i++;
            }
            out.add(((x0 + start + OFFSET) << 24) | ((y + OFFSET) << 16) | ((i - start) << 8) | idx);
        }
    }

    // Char -> palette index; '.' (transparent) is absent.
    function indexes() as Dictionary<Char, Number> {
        return {'K' => 0, 'B' => 1, 'D' => 2, 'T' => 3, 'P' => 4, 'W' => 5, 'G' => 6, 'Y' => 7, 'R' => 8, 'C' => 9};
    }

    function draw(dc as Dc, runs as Array<Number>, colors as Array<Number>, ox as Number, oy as Number, scale as Number) as Void {
        var last = -1;
        for (var k = 0; k < runs.size(); k++) {
            var r = runs[k];
            var idx = r & 0xFF;
            if (idx != last) {
                dc.setColor(colors[idx], Graphics.COLOR_TRANSPARENT);
                last = idx;
            }
            var x = ((r >> 24) & 0xFF) - OFFSET;
            var y = ((r >> 16) & 0xFF) - OFFSET;
            var len = (r >> 8) & 0xFF;
            dc.fillRectangle(ox + x * scale, oy + y * scale, len * scale, scale);
        }
    }
}
