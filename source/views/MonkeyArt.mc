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

    // < 50 %: calm dot eyes, small smile, hands on belly, tail resting, green banana on the ground.
    function relaxPose() as Array {
        return [
            [8, 6, ["KK....KK", "KK....KK"]],
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

    // Energy: tired (move bar or low recharge). Droopy lids, yawn, arms hanging, small "z".
    function tiredPose() as Array {
        return [
            [7, 6, ["KKK....KKK", ".W......W.", ".K......K."]],
            [10, 10, [".KK.", "KRRK", ".KK."]],
            [4, 14, ["KD", "KD", "KD", ".KD"]],
            [18, 14, ["DK", "DK", "DK", "DK."]],
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
            [19, -3, ["WWW", "..W", ".W.", "WWW"]]
        ];
    }

    // Energy: exhausted / 2 h still / night. Eyes shut, tiny mouth, big "Z z".
    function asleepPose() as Array {
        return [
            [7, 6, [".........."]],
            [7, 7, ["KKK....KKK"]],
            [10, 10, [".KK."]],
            [4, 14, ["KD", "KD", "KD", ".KD"]],
            [18, 14, ["DK", "DK", "DK", "DK."]],
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
            [17, -2, ["WWW", "..W", ".W.", "WWW"]],
            [21, -7, ["WWWW", "...W", "..W.", ".W..", "WWWW"]]
        ];
    }

    // Calm: alert (HR up without movement). Wide eyes, worried brows, flat mouth, "!".
    function alertPose() as Array {
        return [
            [7, 4, ["KK......KK"]],
            [9, 5, ["K....K"]],
            [8, 6, ["KW....KW", "KK....KK"]],
            [10, 10, ["KKKK"]],
            [4, 14, ["KD", "KD", "KD", ".KD"]],
            [18, 14, ["DK", "DK", "DK", "DK."]],
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
            ]],
            [-3, 0, ["YY", "YY", "YY", "..", "YY"]]
        ];
    }

    // Calm: stressed. Hands over the ears, squeezed eyes, frown.
    function stressedPose() as Array {
        return [
            [7, 6, ["K........K"]],
            [8, 7, ["K......K"]],
            [7, 8, ["K........K"]],
            [9, 10, [".KKKK.", "K....K"]],
            [-1, 3, ["KKKKK", "KTTTK", "KTTTK", "KTTTK", "KKKKK"]],
            [20, 3, ["KKKKK", "KTTTK", "KTTTK", "KTTTK", "KKKKK"]],
            [0, 8, [".KDK", ".KDK", "..KDK", "...KDK", "....KD"]],
            [19, 8, ["KDK.", "KDK.", "KDK..", "KDK...", "DK...."]],
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
            ]]
        ];
    }

    // Calm: exercising (two frames). Determined eyes, grin, pumping arms, speed lines.
    function jogPose() as Array {
        return [
            [8, 6, ["KW....KW", "KK....KK"]],
            [9, 10, ["KKKKKK", ".KRRK."]],
            [1, 10, ["KTTK", "KTTK", ".KDK", "..KDK", "...KD"]],
            [18, 14, ["DK", "DK", "DK", "DK."]],
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
            ]],
            [-7, 9, ["WWWW"]],
            [-9, 13, ["WWWWW"]],
            [-7, 17, ["WWWW"]]
        ];
    }

    function jogPose2() as Array {
        return [
            [8, 6, ["KW....KW", "KK....KK"]],
            [9, 10, ["KKKKKK", ".KRRK."]],
            [4, 14, ["KD", "KD", "KD", ".KD"]],
            [18, 10, ["KTTK", "KTTK", "KDK.", "DK..", "K..."]],
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
            ]],
            [-6, 9, ["WWW"]],
            [-8, 13, ["WWWW"]],
            [-6, 17, ["WWW"]]
        ];
    }

    // Revived: big stretch, arms up, happy eyes, sparkles.
    function stretchPose() as Array {
        return [
            [7, 6, [".K......K.", "K.K....K.K"]],
            [9, 10, ["KKKKKK", ".KRRK."]],
            [1, -4, ["KTTK", "KTTK", ".KDK", ".KDK", ".KDK", ".KDK", ".KDK", "..KDK", "..KDK", "...KDK", "....KD"]],
            [19, -4, ["KTTK", "KTTK", "KDK.", "KDK.", "KDK.", "KDK.", "KDK.", "KDK..", "KDK..", "KDK...", "DK...."]],
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
            ]],
            [-5, 2, [".Y.", "YYY", ".Y."]],
            [26, -2, [".Y.", "YYY", ".Y."]],
            [-3, 12, ["Y"]]
        ];
    }

    // Guided breathing: eyes closed, gentle smile, hands resting on the belly.
    function breathePose() as Array {
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
            ]]
        ];
    }
}
