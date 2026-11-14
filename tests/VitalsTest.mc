import Toybox.Lang;
import Toybox.Test;

// Vitals state machines, reminders and status priorities.
// Default test snapshot: 10:00, awake 07:00-23:00, resting HR 60, nothing unusual.

function snap() as VitalsSnapshot {
    var s = new VitalsSnapshot();
    s.minuteOfDay = 600;
    s.wakeMin = 420;
    s.sleepMin = 1380;
    s.restingHr = 60;
    s.heartRate = 62;
    s.bodyBattery = 70;
    s.bbPeakToday = 85;
    s.moveBar = 0;
    s.stress = 20;
    return s;
}

// Status for energy/calm only (other vitals normal).
function msgOf(energy as Number, calm as Number, deep as Boolean) as Number {
    return MonkeyStatus.message(energy, calm, deep, Vitals.BREATH_NORMAL, Vitals.WARMTH_OK, Vitals.CURIOUS_CONTENT);
}

(:test)
function energyStatesFollowMoveBarAndRecharge(logger as Logger) as Boolean {
    var s = snap();
    Test.assertEqual(Vitals.energyState(s, false), Vitals.ENERGY_RESTED);
    s.moveBar = 2;
    Test.assertEqual(Vitals.energyState(s, false), Vitals.ENERGY_RESTED);
    s.moveBar = 3; // ~90 min still
    Test.assertEqual(Vitals.energyState(s, false), Vitals.ENERGY_INACTIVE);
    Test.assert(!Vitals.isDeepInactive(s));
    s.moveBar = 5; // ~2 h
    Test.assert(Vitals.isDeepInactive(s));
    s.moveBar = 0;
    s.bbPeakToday = 40; // short recharge
    Test.assertEqual(Vitals.energyState(s, false), Vitals.ENERGY_LOW_RECHARGE);
    s.moveBar = 3;
    Test.assertEqual(Vitals.energyState(s, false), Vitals.ENERGY_EXHAUSTED);
    // A rest/nap gain or an earlier recovery clears the recharge part.
    s.bbRecentGain = 12;
    Test.assertEqual(Vitals.energyState(s, false), Vitals.ENERGY_INACTIVE);
    s.bbRecentGain = null;
    Test.assertEqual(Vitals.energyState(s, true), Vitals.ENERGY_INACTIVE);
    // Recharge is judged only 1 h after wake time.
    s.moveBar = 0;
    s.minuteOfDay = 450;
    Test.assertEqual(Vitals.energyState(s, false), Vitals.ENERGY_RESTED);
    return true;
}

(:test)
function nightAndShiftWindows(logger as Logger) as Boolean {
    var s = snap();
    s.minuteOfDay = 1400; // 23:20
    s.moveBar = 5;
    Test.assertEqual(Vitals.energyState(s, false), Vitals.ENERGY_SLEEPING);
    Test.assert(!Vitals.isInactive(s));
    // Night shift: awake 22:00-06:00.
    s.wakeMin = 1320;
    s.sleepMin = 360;
    s.minuteOfDay = 30;
    Test.assert(Vitals.isAwake(s));
    s.minuteOfDay = 600;
    Test.assert(!Vitals.isAwake(s));
    return true;
}

(:test)
function calmSeparatesStressFromExercise(logger as Logger) as Boolean {
    var s = snap();
    Test.assertEqual(Vitals.calmState(s, Vitals.CALM_CALM), Vitals.CALM_CALM);
    s.heartRate = 68; // +13 %
    Test.assertEqual(Vitals.calmState(s, Vitals.CALM_CALM), Vitals.CALM_CALM);
    s.heartRate = 70; // +16 %, not moving
    Test.assertEqual(Vitals.calmState(s, Vitals.CALM_CALM), Vitals.CALM_ALERT);
    s.hrSustainedPct = 30; // > 25 % for the last minutes
    Test.assertEqual(Vitals.calmState(s, Vitals.CALM_CALM), Vitals.CALM_STRESSED);
    // Same HR while walking briskly: exercise, never stress.
    s.stepsPerMin = 110;
    s.heartRate = 95;
    Test.assertEqual(Vitals.calmState(s, Vitals.CALM_STRESSED), Vitals.CALM_EXERCISING);
    s.heartRate = 62;
    Test.assertEqual(Vitals.calmState(s, Vitals.CALM_CALM), Vitals.CALM_CALM);
    // Garmin stress alone.
    s = snap();
    s.stress = 55;
    Test.assertEqual(Vitals.calmState(s, Vitals.CALM_CALM), Vitals.CALM_ALERT);
    s.stressSustained = true;
    Test.assertEqual(Vitals.calmState(s, Vitals.CALM_CALM), Vitals.CALM_STRESSED);
    return true;
}

(:test)
function calmHysteresis(logger as Logger) as Boolean {
    var s = snap();
    s.stress = 45;
    s.heartRate = 64; // +6 %: below alert, above calm
    Test.assertEqual(Vitals.calmState(s, Vitals.CALM_CALM), Vitals.CALM_CALM);
    Test.assertEqual(Vitals.calmState(s, Vitals.CALM_ALERT), Vitals.CALM_ALERT);
    s.stress = 35;
    s.heartRate = 63; // +5 %
    Test.assertEqual(Vitals.calmState(s, Vitals.CALM_ALERT), Vitals.CALM_CALM);
    // No data at all is calm, not alarming.
    var empty = new VitalsSnapshot();
    Test.assertEqual(Vitals.calmState(empty, Vitals.CALM_CALM), Vitals.CALM_CALM);
    Test.assert(Vitals.calmMeter(empty) == null);
    return true;
}

(:test)
function reviveIsDetectedAndCapped(logger as Logger) as Boolean {
    var vm = new VitalsModel();
    var s = snap();
    Test.assertEqual(vm.apply(s, 10), VitalsModel.EVENT_NONE);
    for (var i = 0; i < 4; i++) {
        s.moveBar = 3;
        vm.apply(s, 10);
        Test.assertEqual(vm.getEnergy(), Vitals.ENERGY_INACTIVE);
        s.moveBar = 0;
        Test.assertEqual(vm.apply(s, 10), VitalsModel.EVENT_REVIVED);
    }
    Test.assertEqual(vm.takePendingRevives(), VitalsModel.MAX_REVIVES_PER_DAY);
    Test.assertEqual(vm.takePendingRevives(), 0);
    // Yesterday's tiredness does not count as today's revive.
    s.moveBar = 3;
    vm.apply(s, 10);
    s.moveBar = 0;
    Test.assertEqual(vm.apply(s, 11), VitalsModel.EVENT_NONE);
    return true;
}

(:test)
function napClearsLowRechargeForTheDay(logger as Logger) as Boolean {
    var vm = new VitalsModel();
    var s = snap();
    s.bbPeakToday = 40;
    vm.apply(s, 20);
    Test.assertEqual(vm.getEnergy(), Vitals.ENERGY_LOW_RECHARGE);
    s.bbRecentGain = 12;
    Test.assertEqual(vm.apply(s, 20), VitalsModel.EVENT_REVIVED);
    s.bbRecentGain = 0; // the 3 h window moved on; recovery still counts today
    vm.apply(s, 20);
    Test.assertEqual(vm.getEnergy(), Vitals.ENERGY_RESTED);
    return true;
}

(:test)
function stressClearingIsAnnounced(logger as Logger) as Boolean {
    var vm = new VitalsModel();
    var s = snap();
    s.stressSustained = true;
    s.stress = 80;
    vm.apply(s, 30);
    Test.assertEqual(vm.getCalm(), Vitals.CALM_STRESSED);
    s.stressSustained = false;
    s.stress = 20;
    Test.assertEqual(vm.apply(s, 30), VitalsModel.EVENT_CALMED);
    return true;
}

(:test)
function nudgesRespectCooldownsAndQuietHours(logger as Logger) as Boolean {
    var vm = new VitalsModel();
    var s = snap();
    var t = 1000000;
    s.moveBar = 3;
    vm.apply(s, 40);
    Test.assertEqual(vm.pickNudge(s, 800, t), VitalsModel.NUDGE_INACTIVE);
    Test.assertEqual(vm.pickNudge(s, 800, t + 60), VitalsModel.NUDGE_NONE);          // min gap
    Test.assertEqual(vm.pickNudge(s, 800, t + 50 * 60), VitalsModel.NUDGE_NONE);     // same kind < 2 h
    Test.assertEqual(vm.pickNudge(s, 800, t + 2 * 3600), VitalsModel.NUDGE_INACTIVE); // after cooldown
    // Night: never.
    s.minuteOfDay = 1400;
    Test.assertEqual(vm.pickNudge(s, 800, t + 5 * 3600), VitalsModel.NUDGE_NONE);
    // Disabled: never.
    s.minuteOfDay = 600;
    vm.setEnabled(false);
    Test.assertEqual(vm.pickNudge(s, 800, t + 6 * 3600), VitalsModel.NUDGE_NONE);
    return true;
}

(:test)
function nudgePriorityAndOncePerDayKinds(logger as Logger) as Boolean {
    var vm = new VitalsModel();
    var s = snap();
    var t = 2000000;
    s.minuteOfDay = 14 * 60;
    s.bbPeakToday = 40;
    s.moveBar = 3;
    s.stressSustained = true;
    vm.apply(s, 50);
    Test.assertEqual(vm.getEnergy(), Vitals.ENERGY_EXHAUSTED);
    Test.assertEqual(vm.pickNudge(s, 300, t), VitalsModel.NUDGE_EXHAUSTED);
    Test.assertEqual(vm.pickNudge(s, 300, t + 46 * 60), VitalsModel.NUDGE_STRESSED);
    // Midday goal reminder once per day, only under 50 %.
    s.moveBar = 0;
    s.stressSustained = false;
    s.stress = 10;
    s.bbPeakToday = 90;
    vm.apply(s, 50);
    Test.assertEqual(vm.pickNudge(s, 300, t + 92 * 60), VitalsModel.NUDGE_GOAL);
    Test.assertEqual(vm.pickNudge(s, 300, t + 200 * 60), VitalsModel.NUDGE_NONE);
    Test.assertEqual(vm.pickNudge(s, 600, t + 300 * 60), VitalsModel.NUDGE_NONE);
    return true;
}

(:test)
function seenConditionsAreNotNudgedAgain(logger as Logger) as Boolean {
    var vm = new VitalsModel();
    var s = snap();
    var t = 3000000;
    s.moveBar = 3;
    vm.apply(s, 60);
    vm.markSeen(s, 800, t);
    Test.assertEqual(vm.pickNudge(s, 800, t + 30 * 60), VitalsModel.NUDGE_NONE);
    return true;
}

(:test)
function statusPriorityAndPoses(logger as Logger) as Boolean {
    var msg = msgOf(Vitals.ENERGY_EXHAUSTED, Vitals.CALM_STRESSED, false);
    Test.assertEqual(msg, MonkeyStatus.MSG_EXHAUSTED);
    Test.assert(MonkeyStatus.takesOverFace(msg));
    Test.assertEqual(msgOf(Vitals.ENERGY_INACTIVE, Vitals.CALM_STRESSED, false), MonkeyStatus.MSG_STRESSED);
    Test.assertEqual(msgOf(Vitals.ENERGY_INACTIVE, Vitals.CALM_ALERT, true), MonkeyStatus.MSG_DEEP_STILL);
    Test.assertEqual(msgOf(Vitals.ENERGY_LOW_RECHARGE, Vitals.CALM_ALERT, false), MonkeyStatus.MSG_LOW_RECHARGE);
    Test.assertEqual(msgOf(Vitals.ENERGY_RESTED, Vitals.CALM_EXERCISING, false), MonkeyStatus.MSG_EXERCISING);
    Test.assertEqual(msgOf(Vitals.ENERGY_RESTED, Vitals.CALM_CALM, false), MonkeyStatus.MSG_NONE);

    Test.assertEqual(MonkeyStatus.pose(MonkeyStatus.POSE_EAT, MonkeyStatus.MSG_NONE, 0), MonkeyStatus.POSE_EAT);
    Test.assertEqual(MonkeyStatus.pose(MonkeyStatus.POSE_EAT, MonkeyStatus.MSG_STILL, 0), MonkeyStatus.POSE_TIRED);
    Test.assertEqual(MonkeyStatus.pose(MonkeyStatus.POSE_PERK, MonkeyStatus.MSG_DEEP_STILL, 0), MonkeyStatus.POSE_ASLEEP);
    Test.assertEqual(MonkeyStatus.pose(MonkeyStatus.POSE_PERK, MonkeyStatus.MSG_EXERCISING, 1), MonkeyStatus.POSE_JOG2);
    Test.assertEqual(MonkeyStatus.tint(MonkeyStatus.MSG_STRESSED), MonkeyStatus.TINT_STRESS);
    Test.assertEqual(MonkeyStatus.tint(MonkeyStatus.MSG_NIGHT), MonkeyStatus.TINT_NIGHT);
    Test.assert(MonkeyStatus.suggestsBreathing(MonkeyStatus.MSG_ALERT));
    Test.assert(!MonkeyStatus.suggestsBreathing(MonkeyStatus.MSG_STILL));
    return true;
}

(:test)
function bonusesAreCapped(logger as Logger) as Boolean {
    var m = new MonkeyModel();
    m.update(500, 0, noHistory());
    Test.assert(m.addBreathBonus());
    Test.assert(!m.addBreathBonus());
    Test.assertEqual(m.getXp(), MonkeyModel.XP_BREATH);
    m.addReviveBonus();
    Test.assertEqual(m.getXp(), MonkeyModel.XP_BREATH + MonkeyModel.XP_REVIVE);
    var e = m.takeEvent();
    Test.assert(e != null && e[3] == MonkeyModel.EV_REVIVE);
    // Next day the breather pays again.
    m.update(501, 0, noHistory());
    Test.assert(m.addBreathBonus());
    // Demo scenario table stays consistent with the status logic.
    var row = DemoScenarios.row(7);
    Test.assertEqual(MonkeyStatus.message(row[DemoScenarios.ENERGY], row[DemoScenarios.CALM], row[DemoScenarios.DEEP] == 1,
        row[DemoScenarios.BREATH], row[DemoScenarios.WARMTH], row[DemoScenarios.CURIOUS]),
        MonkeyStatus.MSG_EXHAUSTED);
    return true;
}

(:test)
function breathIsReadOnlyAndConservative(logger as Logger) as Boolean {
    var s = snap();
    Test.assertEqual(Vitals.breathState(s), Vitals.BREATH_NORMAL); // no Pulse Ox data
    s.spo2 = 96;
    Test.assertEqual(Vitals.breathState(s), Vitals.BREATH_NORMAL);
    s.spo2 = 93;
    s.spo2LowStreak = 1;
    Test.assertEqual(Vitals.breathState(s), Vitals.BREATH_LOW);
    s.spo2LowStreak = 2; // still low on the next reading
    Test.assertEqual(Vitals.breathState(s), Vitals.BREATH_CONCERNING);
    s.spo2 = 88;
    s.spo2LowStreak = 1;
    Test.assertEqual(Vitals.breathState(s), Vitals.BREATH_CONCERNING);
    // Breath concerning outranks everything, low breath ranks below stress.
    Test.assertEqual(MonkeyStatus.message(Vitals.ENERGY_EXHAUSTED, Vitals.CALM_STRESSED, false,
        Vitals.BREATH_CONCERNING, Vitals.WARMTH_COLD, Vitals.CURIOUS_CONTENT), MonkeyStatus.MSG_BREATH_CONCERNING);
    Test.assertEqual(MonkeyStatus.message(Vitals.ENERGY_RESTED, Vitals.CALM_STRESSED, false,
        Vitals.BREATH_LOW, Vitals.WARMTH_OK, Vitals.CURIOUS_CONTENT), MonkeyStatus.MSG_STRESSED);
    Test.assert(MonkeyStatus.suggestsBreathing(MonkeyStatus.MSG_BREATH_LOW));
    return true;
}

(:test)
function warmthNeedsSustainedColdOrUnexplainedHeat(logger as Logger) as Boolean {
    var s = snap();
    s.tempC = 8;
    Test.assertEqual(Vitals.warmthState(s), Vitals.WARMTH_OK); // a single cold reading is not enough
    s.coldSustained = true;
    Test.assertEqual(Vitals.warmthState(s), Vitals.WARMTH_COLD);
    s = snap();
    s.tempC = 36;
    Test.assertEqual(Vitals.warmthState(s), Vitals.WARMTH_OK); // hot but HR normal
    s.heartRate = 72; // +20 %, not moving
    Test.assertEqual(Vitals.warmthState(s), Vitals.WARMTH_HOT);
    s.stepsPerMin = 120; // exercising explains the HR
    Test.assertEqual(Vitals.warmthState(s), Vitals.WARMTH_OK);
    return true;
}

(:test)
function curiosityRewardsNewBestsAndSpotsRoutine(logger as Logger) as Boolean {
    var routine = [[400000, 0], [410000, 1], [395000, 0], [200000, 0]] as Array<Array<Number?> >;
    Test.assertEqual(Vitals.curiosityState(100000, 0, routine), Vitals.CURIOUS_ROUTINE);
    Test.assertEqual(Vitals.curiosityState(450000, 0, routine), Vitals.CURIOUS_ADVENTUROUS); // new distance best
    Test.assertEqual(Vitals.curiosityState(100000, 6, routine), Vitals.CURIOUS_ADVENTUROUS); // new floors best
    var varied = [[400000, 0], [800000, 3], [200000, 0]] as Array<Array<Number?> >;
    Test.assertEqual(Vitals.curiosityState(100000, 0, varied), Vitals.CURIOUS_CONTENT);
    Test.assertEqual(Vitals.curiosityState(900000, 0, [[1, 1]] as Array<Array<Number?> >), Vitals.CURIOUS_CONTENT); // too little history
    // Explorer bonus is once per day.
    var m = new MonkeyModel();
    m.update(700, 0, noHistory());
    Test.assert(m.addExploreBonus());
    Test.assert(!m.addExploreBonus());
    Test.assertEqual(m.getXp(), MonkeyModel.XP_EXPLORE);
    return true;
}

(:test)
function newVitalsNudgeWithPriority(logger as Logger) as Boolean {
    var vm = new VitalsModel();
    var s = snap();
    var t = 4000000;
    s.coldSustained = true;
    s.spo2 = 88;
    vm.apply(s, 80);
    Test.assertEqual(vm.getBreath(), Vitals.BREATH_CONCERNING);
    Test.assertEqual(vm.getWarmth(), Vitals.WARMTH_COLD);
    Test.assertEqual(vm.pickNudge(s, 800, t), VitalsModel.NUDGE_BREATH);
    Test.assertEqual(vm.pickNudge(s, 800, t + 46 * 60), VitalsModel.NUDGE_COLD);
    return true;
}
