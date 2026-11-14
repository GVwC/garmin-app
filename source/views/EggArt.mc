import Toybox.Lang;

// Pixel egg for onboarding: spots use the fur colour (B), so the egg previews the monkey.
// Same patch format and palette as MonkeyArt.
module EggArt {

    const WIDTH = 16;
    const HEIGHT = 20;

    function egg() as Array {
        return [
            [0, 0, [
                "......KKKK......",
                "....KKWWWWKK....",
                "...KWWWWWWWWK...",
                "..KWWBBWWWWWWK..",
                "..KWBBBWWWWWWK..",
                ".KWWWBWWWWBBWWK.",
                ".KWWWWWWWBBBBWK.",
                ".KWWWWWWWWBBWWK.",
                "KWWWWWWWWWWWWWWK",
                "KWWBBWWWWWWWWWWK",
                "KWBBBBWWWWWWWWWK",
                "KWWBBWWWWWBBWWWK",
                "KWWWWWWWWBBBBWWK",
                "KWWWWWWWWWBBWWWK",
                ".KWWWWWWWWWWWWK.",
                ".KWWBBWWWWWWWWK.",
                "..KWBBWWWWWWWK..",
                "...KWWWWWWWWK...",
                "....KKWWWWKK....",
                "......KKKK......"
            ]]
        ];
    }

    // First crack: a small zigzag.
    function crack1() as Array {
        return [[6, 6, ["K..", ".K.", "K.K", "...K"]]];
    }

    // Second crack: across the whole egg.
    function crack2() as Array {
        return [[1, 8, ["K.K...K..K...K", ".K.K.K.KK.K.K.", "..K...K..K.K.."]]];
    }

    // Bottom half of the shell after hatching (zigzag rim).
    function shellBottom() as Array {
        return [
            [0, 0, [
                ".K.K..K.K..K.K..",
                "KWKWKKWKWKKWKWKK",
                "KWWBBWWWWWBBWWWK",
                "KWWWWWWWWBBBBWWK",
                ".KWWWWWWWWBBWWK.",
                ".KWWBBWWWWWWWWK.",
                "..KWBBWWWWWWWK..",
                "...KWWWWWWWWK...",
                "....KKWWWWKK....",
                "......KKKK......"
            ]]
        ];
    }

    // Sparkles around the newborn.
    function sparkles() as Array {
        return [
            [-6, -2, [".Y.", "YYY", ".Y."]],
            [20, -4, [".Y.", "YYY", ".Y."]],
            [-4, 12, ["Y"]],
            [22, 10, ["Y"]]
        ];
    }
}
