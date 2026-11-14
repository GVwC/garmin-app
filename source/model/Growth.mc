import Toybox.Lang;

// Life stages: egg -> baby -> kid -> adult -> crowned, driven by level.
// The egg exists only until the character is created (hatching ends the setup).
// Each stage picks its sprite scale and accessory; stage art can later get its own sprites.
module Growth {

    const STAGE_EGG = 0;
    const STAGE_BABY = 1;
    const STAGE_KID = 2;
    const STAGE_ADULT = 3;
    const STAGE_CROWNED = 4;

    const KID_LEVEL = 3;
    const ADULT_LEVEL = 6;
    const CROWNED_LEVEL = 10;

    function stageFor(level as Number, hatched as Boolean) as Number {
        if (!hatched) {
            return STAGE_EGG;
        } else if (level >= CROWNED_LEVEL) {
            return STAGE_CROWNED;
        } else if (level >= ADULT_LEVEL) {
            return STAGE_ADULT;
        } else if (level >= KID_LEVEL) {
            return STAGE_KID;
        }
        return STAGE_BABY;
    }

    // Pixel scale on the 260x260 screen: babies are smaller.
    function scaleFor(stage as Number) as Number {
        return (stage == STAGE_BABY) ? 3 : 4;
    }

    // Accessory index for MonkeyArt (0 leaf, 1 headband, 2 crown) or -1.
    function accessoryFor(stage as Number) as Number {
        if (stage == STAGE_CROWNED) {
            return 2;
        } else if (stage == STAGE_ADULT) {
            return 1;
        } else if (stage == STAGE_KID) {
            return 0;
        }
        return -1;
    }
}
