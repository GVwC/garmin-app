import Toybox.Graphics;
import Toybox.Lang;

// Turns MonkeyArt patches into packed horizontal runs once (onLayout), then draws
// them as scaled rectangles. One Number per run: x | y | length | colour index.
module PixelSprite {

    const CHARS = "KBDTPWGYR";
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
            0xAA0000  // R mouth
        ];
    }

    // layers: list of patch lists (body first, then pose); later patches paint over earlier ones.
    function compile(layers as Array<Array>) as Array<Number> {
        var out = [] as Array<Number>;
        for (var l = 0; l < layers.size(); l++) {
            var patches = layers[l];
            for (var p = 0; p < patches.size(); p++) {
                var patch = patches[p] as Array;
                var px = patch[0] as Number;
                var py = patch[1] as Number;
                var rows = patch[2] as Array<String>;
                for (var j = 0; j < rows.size(); j++) {
                    addRuns(out, px, py + j, rows[j].toCharArray());
                }
            }
        }
        return out;
    }

    function addRuns(out as Array<Number>, x0 as Number, y as Number, chars as Array<Char>) as Void {
        var n = chars.size();
        var i = 0;
        while (i < n) {
            var c = chars[i];
            var idx = CHARS.find(c.toString());
            if (idx == null) {
                i++;
                continue;
            }
            var start = i;
            while (i < n && chars[i] == c) {
                i++;
            }
            out.add(((x0 + start + OFFSET) << 24) | ((y + OFFSET) << 16) | ((i - start) << 8) | idx);
        }
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
