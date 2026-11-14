import Toybox.Lang;
import Toybox.Test;

// Unit tests. Only compiled with --unit-test. Each (:test) function receives a
// Test.Logger and returns true on success; Test.assert* raise on failure.
// Days are plain day numbers; values are [steps, activeMinutes, floors];
// history rows are [day, steps, activeMinutes, floors].

function noHistory() as Array<Array<Number?> > {
    return [] as Array<Array<Number?> >;
}

// Today's values with only steps known.
function st(steps as Number?) as Array<Number?> {
    return [steps, null, null] as Array<Number?>;
}

function stepsDay(day as Number, steps as Number?) as Array<Number?> {
    return [day, steps, null, null] as Array<Number?>;
}

(:test)
function goalBoundaryPicksPose(logger as Logger) as Boolean {
    var m = new MonkeyModel();
    Test.assertEqual(m.getTarget(), 5000);
    m.update(100, st(0), noHistory());
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_RELAX);
    m.update(100, st(2499), noHistory());
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_RELAX);
    m.update(100, st(2500), noHistory());
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_PERK);
    m.update(100, st(4999), noHistory());
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_PERK);
    Test.assert(m.takeEvent() == null);
    Test.assertEqual(m.getXp(), 0);
    m.update(100, st(5000), noHistory());
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_EAT);
    var e = m.takeEvent();
    Test.assert(e != null);
    if (e != null) {
        Test.assertEqual(e[0], MonkeyModel.XP_GOAL);
        Test.assert(e[1]);
    }
    Test.assertEqual(m.getXp(), MonkeyModel.XP_GOAL);
    return true;
}

(:test)
function rewardPlaysOncePerDay(logger as Logger) as Boolean {
    var m = new MonkeyModel();
    m.update(100, st(5000), noHistory());
    Test.assert(m.takeEvent() != null);
    // Re-opening the dashboard the same day: completed pose, no second reward.
    m.update(100, st(6200), noHistory());
    m.update(100, st(6300), noHistory());
    Test.assert(m.takeEvent() == null);
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_EAT);
    Test.assertEqual(m.getXp(), MonkeyModel.XP_GOAL);
    Test.assertEqual(m.getStreak(), 1);
    // Midnight: fresh day, yesterday already rewarded live -> not counted twice.
    m.update(101, st(0), [stepsDay(100, 6300)] as Array<Array<Number?> >);
    Test.assert(m.takeEvent() == null);
    Test.assertEqual(m.getXp(), MonkeyModel.XP_GOAL);
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_RELAX);
    Test.assertEqual(m.getStreak(), 1);
    // The new day can be rewarded again, and day 2 of the streak adds a bonus.
    m.update(101, st(5000), noHistory());
    Test.assert(m.takeEvent() != null);
    Test.assertEqual(m.getXp(), 2 * MonkeyModel.XP_GOAL + 2 * MonkeyModel.XP_STREAK);
    Test.assertEqual(m.getStreak(), 2);
    return true;
}

(:test)
function finishedDaysGainAndLoseXp(logger as Logger) as Boolean {
    var m = new MonkeyModel();
    m.update(100, st(5000), noHistory());
    m.takeEvent();
    // App not opened on 101 and 102: 101 met (+100), 102 missed (-50), 100 was already rewarded live.
    var hist = [stepsDay(102, 1200), stepsDay(101, 7000), stepsDay(100, 5000), stepsDay(99, 0)] as Array<Array<Number?> >;
    m.update(103, st(300), hist);
    Test.assertEqual(m.getXp(), 2 * MonkeyModel.XP_GOAL - MonkeyModel.XP_MISS);
    Test.assertEqual(m.getStreak(), 0); // broken on 102
    var e = m.takeEvent();
    Test.assert(e != null);
    if (e != null) {
        Test.assertEqual(e[0], MonkeyModel.XP_GOAL - MonkeyModel.XP_MISS);
        Test.assert(!e[1]);
    }
    // Settled once only.
    m.update(103, st(400), hist);
    Test.assertEqual(m.getXp(), 2 * MonkeyModel.XP_GOAL - MonkeyModel.XP_MISS);
    return true;
}

(:test)
function xpNeverNegativeAndMissingDaysIgnored(logger as Logger) as Boolean {
    var m = new MonkeyModel();
    m.update(10, st(0), noHistory());
    m.update(13, st(0), [stepsDay(12, 0), stepsDay(11, null)] as Array<Array<Number?> >);
    Test.assertEqual(m.getXp(), 0);
    Test.assert(m.takeEvent() == null);
    return true;
}

(:test)
function unavailableReading(logger as Logger) as Boolean {
    var m = new MonkeyModel();
    m.update(50, st(null), noHistory());
    Test.assert(m.getValue() == null);
    Test.assertEqual(m.getProgressPermille(), 0);
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_RELAX);
    Test.assert(m.takeEvent() == null);
    return true;
}

(:test)
function goalChangeAppliesNow(logger as Logger) as Boolean {
    var m = new MonkeyModel();
    m.update(70, st(3000), noHistory());
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_PERK);
    m.setGoal(Goals.GOAL_STEPS, 3000);
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_EAT);
    Test.assert(m.takeEvent() != null);
    // Raising the goal keeps today's XP but shows progress against the new target.
    m.setGoal(Goals.GOAL_STEPS, 10000);
    Test.assertEqual(m.getXp(), MonkeyModel.XP_GOAL);
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_RELAX);
    // A second goal: shown on the counter, pose uses both (30 % and 97 % -> 63 % overall).
    m.setGoal(Goals.GOAL_ACTIVE, 30);
    m.update(70, [3000, 29, null] as Array<Number?>, noHistory());
    Test.assertEqual(m.getGoalType(), Goals.GOAL_ACTIVE);
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_PERK);
    m.showNext(1);
    Test.assertEqual(m.getGoalType(), Goals.GOAL_STEPS);
    Test.assertEqual(Goals.targetsFor(Goals.GOAL_FLOORS)[0], 5);
    return true;
}

(:test)
function everyEnabledGoalGivesXp(logger as Logger) as Boolean {
    var m = new MonkeyModel();
    m.setGoal(Goals.GOAL_ACTIVE, 30);
    Test.assertEqual(m.enabledGoals().size(), 2);
    // Both met in one refresh: one celebration, XP for both.
    m.update(10, [5000, 30, null] as Array<Number?>, noHistory());
    var e = m.takeEvent();
    Test.assert(e != null && e[0] == 2 * MonkeyModel.XP_GOAL && e[1]);
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_EAT);
    // Next day: steps first (+100), then active completes the day (+100 + streak day 2 bonus).
    var hist = [[10, 5000, 30, null]] as Array<Array<Number?> >;
    m.update(11, [6000, 10, null] as Array<Number?>, hist);
    e = m.takeEvent();
    Test.assert(e != null && e[0] == MonkeyModel.XP_GOAL);
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_PERK);
    m.update(11, [6000, 30, null] as Array<Number?>, hist);
    e = m.takeEvent();
    Test.assert(e != null && e[0] == MonkeyModel.XP_GOAL + 2 * MonkeyModel.XP_STREAK);
    // A finished day with one goal missed: +100 / -50 and the streak breaks.
    m.update(13, [0, 0, null] as Array<Number?>, [[12, 7000, 5, null]] as Array<Array<Number?> >);
    Test.assertEqual(m.getStreak(), 0);
    Test.assertEqual(m.getXp(), 5 * MonkeyModel.XP_GOAL + 2 * MonkeyModel.XP_STREAK - MonkeyModel.XP_MISS);
    return true;
}

(:test)
function goalsCanBeSwitchedButOneStays(logger as Logger) as Boolean {
    var m = new MonkeyModel();
    m.setGoalOn(Goals.GOAL_STEPS, false);
    Test.assert(m.isGoalOn(Goals.GOAL_STEPS)); // last goal cannot be switched off
    m.setGoal(Goals.GOAL_FLOORS, 10);
    m.setGoalOn(Goals.GOAL_STEPS, false);
    Test.assert(!m.isGoalOn(Goals.GOAL_STEPS));
    Test.assertEqual(m.getGoalType(), Goals.GOAL_FLOORS);
    Test.assertEqual(m.getTarget(), 10);
    return true;
}

(:test)
function characterDefaults(logger as Logger) as Boolean {
    var m = new MonkeyModel();
    Test.assert(!m.isCreated());
    m.setFur(2);
    Test.assertEqual(m.getFur(), 2);
    m.setFur(9);
    Test.assertEqual(m.getFur(), 0);
    m.setCreated();
    Test.assert(m.isCreated());
    Test.assertEqual(MainView.accessoryIndex(2), -1);
    Test.assertEqual(MainView.accessoryIndex(3), 0);
    Test.assertEqual(MainView.accessoryIndex(7), 1);
    Test.assertEqual(MainView.accessoryIndex(12), 2);
    return true;
}

(:test)
function demoCyclesWithoutTouchingLiveXp(logger as Logger) as Boolean {
    var m = new MonkeyModel();
    m.update(200, st(5000), noHistory());
    m.takeEvent();
    m.enterDemo();
    Test.assert(m.getValue() == 1000);
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_RELAX);
    m.nextDemoStage();
    Test.assert(m.getValue() == 3250);
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_PERK);
    m.nextDemoStage();
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_EAT);
    Test.assertEqual(m.getXp(), 2 * MonkeyModel.XP_GOAL);
    var e = m.takeEvent();
    Test.assert(e != null && e[1]);
    m.nextDemoStage();
    Test.assertEqual(m.getDemoStage(), 3);
    Test.assertEqual(m.getXp(), 2 * MonkeyModel.XP_GOAL - MonkeyModel.XP_MISS);
    // Going back never replays XP effects.
    m.prevDemoStage();
    Test.assertEqual(m.getDemoStage(), 2);
    Test.assert(m.takeEvent() == null);
    Test.assertEqual(m.getXp(), 2 * MonkeyModel.XP_GOAL - MonkeyModel.XP_MISS);
    // Walk to the revive stage (+XP_REVIVE), then wrap around to stage 0.
    for (var i = 3; i < DemoScenarios.COUNT; i++) {
        m.nextDemoStage();
    }
    Test.assertEqual(m.getDemoStage(), DemoScenarios.COUNT - 1);
    var r = m.takeEvent();
    Test.assert(r != null && r[3] == MonkeyModel.EV_REVIVE);
    m.nextDemoStage();
    Test.assertEqual(m.getDemoStage(), 0);
    // Live updates while in demo are ignored for rewards.
    m.update(201, st(9000), noHistory());
    m.exitDemo();
    Test.assert(!m.isDemo());
    // Leaving demo returns to real data: live XP was untouched, today's real goal now rewarded.
    Test.assertEqual(m.getXp(), 2 * MonkeyModel.XP_GOAL);
    // Re-entering demo starts fresh.
    m.enterDemo();
    Test.assertEqual(m.getDemoStage(), 0);
    m.exitDemo();
    return true;
}

(:test)
function levelUpIsAnnounced(logger as Logger) as Boolean {
    var m = new MonkeyModel();
    m.update(300, st(5000), noHistory());
    m.takeEvent();
    m.update(303, st(0), [stepsDay(302, 5000), stepsDay(301, 5000)] as Array<Array<Number?> >);
    Test.assertEqual(m.getXp(), 3 * MonkeyModel.XP_GOAL);
    Test.assertEqual(m.getLevel(), 2);
    Test.assertEqual(m.getStreak(), 3);
    var e = m.takeEvent();
    Test.assert(e != null && e[2]);
    return true;
}

(:test)
function formatsAndDays(logger as Logger) as Boolean {
    Test.assertEqual(Fmt.thousands(0), "0");
    Test.assertEqual(Fmt.thousands(999), "999");
    Test.assertEqual(Fmt.thousands(1000), "1,000");
    Test.assertEqual(Fmt.thousands(3420), "3,420");
    Test.assertEqual(Fmt.thousands(10000), "10,000");
    Test.assertEqual(Fmt.thousands(1234567), "1,234,567");
    Test.assertEqual(Fmt.signed(100), "+100");
    Test.assertEqual(Fmt.signed(-50), "-50");
    Test.assertEqual(DayClock.dayOf(86399, 0), 0);
    Test.assertEqual(DayClock.dayOf(86400, 0), 1);
    Test.assertEqual(DayClock.dayOf(0, -3600), -1);
    // 23:30 local in UTC-6 is still the same local day.
    Test.assertEqual(DayClock.dayOf(86400 + 5 * 3600 + 1800, -6 * 3600), 0);
    return true;
}
