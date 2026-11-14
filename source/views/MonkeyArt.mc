import Toybox.Lang;

// Pixel-art monkey. Every function returns patches: [x, y, rows] in sprite pixels.
// The body silhouette is shared; each pose only adds eyes, mouth, arms, tail and banana.
// Characters: . transparent  K outline  B fur  D dark fur  T tan  P pink
//             W white  G green banana  Y yellow banana  R mouth
module MonkeyArt {

    const WIDTH = 32;   // sprite bounding box incl. tail
    const HEIGHT = 24;
    const CENTER_X = 12; // body centre column (tail sticks out to the right)

    function body() as Array {
        return [
            [0, 0, [
                "........KKKKKKKK........",
                "......KKBBBBBBBBKK......",
                ".....KBBBBBBBBBBBBK.....",
                ".KKK.KBBBBBBBBBBBBK.KKK.",
                "KBBBKBBTTTTBBTTTTBBKBBBK",
                "KBPPKBTTTTTTTTTTTTBKPPBK",
                "KBPPBTTTTTTTTTTTTTTBPPBK",
                "KBBBBTTTTTTTTTTTTTTBBBBK",
                ".KKKBTTTTTTTTTTTTTTBKKK.",
                "....KBTTTTKTTKTTTTBK....",
                "....KBTTTTTTTTTTTTBK....",
                ".....KBTTTTTTTTTTBK.....",
                "......KKBBBBBBBBKK......",
                "......KBBBBBBBBBBK......",
                ".....KBBBTTTTTTBBBK.....",
                "....KBBBTTTTTTTTBBBK....",
                "....KBBBTTTTTTTTBBBK....",
                "....KBBBTTTTTTTTBBBK....",
                "....KBBBBTTTTTTBBBBK....",
                "...KBBBBBBBBBBBBBBBBK...",
                "..KBBBBBKKKKKKKKBBBBBK..",
                "..KTTTTTK......KTTTTTK..",
                "...KKKKK........KKKKK..."
            ]]
        ];
    }

    // < 50 %: sleepy eyes, small smile, hands on belly, tail resting, green banana on the ground.
    function relaxPose() as Array {
        return [
            [7, 6, [".........."]],
            [7, 7, ["KKK....KKK"]],
            [9, 10, ["K....K", ".KKKK."]],
            [5, 15, ["KD", "KD", ".KD"]],
            [17, 15, ["DK", "DK", "DK."]],
            [7, 17, ["KBBK", ".KK."]],
            [13, 17, ["KBBK", ".KK."]],
            [20, 12, [
                "....KKKK",
                "...KBBBBK",
                "..KBKKKBK",
                "..KBK.KBK",
                "..KBKKBK.",
                "..KBK.K..",
                "..KBK....",
                ".KBK.....",
                "KBK......",
                "BK......."
            ]],
            [-8, 18, [
                ".K.......",
                "KGK....KK",
                "KGGKKKKGK",
                ".KGGGGGK.",
                "..KKKKK.."
            ]]
        ];
    }

    // 50-99 %: wide eyes, grin, banana (yellow) raised high, tail curled up.
    function perkPose() as Array {
        return [
            [8, 6, ["KW....KW", "KK....KK"]],
            [9, 10, ["KKKKKK", ".KRRK."]],
            [1, 5, [
                ".K...",
                ".KK..",
                "KYYK.",
                "KYYK.",
                "KYYK.",
                "KYYK.",
                ".KYYK",
                ".KTTK",
                ".KTTK",
                ".KBBK",
                ".KBBK",
                "..KBBK"
            ]],
            [17, 15, ["DK", "DK", "DK."]],
            [20, 4, [
                "...KKKKK.",
                "..KBBBBBK",
                ".KBKKKKBK",
                ".KBK..KBK",
                ".KBK.KBK.",
                ".KBK..K..",
                "..KBK....",
                "...KBK...",
                "...KBK...",
                "..KBK....",
                ".KBK.....",
                "KBK......",
                "BK......."
            ]]
        ];
    }

    // Goal reached: happy ^ ^ eyes, both hands hold the banana to the open mouth.
    function eatPose() as Array {
        return [
            [7, 6, [".K......K.", "K.K....K.K"]],
            [6, 9, ["PP........PP"]],
            [9, 10, ["KRWWRK", ".KWWK."]],
            [8, 12, [
                ".KYWWYK.",
                "KYYKKYYK",
                "KYK..KYK",
                ".K....K."
            ]],
            [5, 12, ["KTTK", "KTTK", ".KK."]],
            [15, 12, ["KTTK", "KTTK", ".KK."]],
            [20, 4, [
                "...KKKKK.",
                "..KBBBBBK",
                ".KBKKKKBK",
                ".KBK..KBK",
                ".KBK.KBK.",
                ".KBK..K..",
                "..KBK....",
                "...KBK...",
                "...KBK...",
                "..KBK....",
                ".KBK.....",
                "KBK......",
                "BK......."
            ]]
        ];
    }
}
