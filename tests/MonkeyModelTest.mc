import Toybox.Lang;
import Toybox.Test;

// Unit tests. Only compiled with --unit-test. Each (:test) function receives a
// Test.Logger and returns true on success; Test.assert* raise on failure.
// Days are plain day numbers; history entries are [day, value].

function noHistory() as Array<Array<Number?> > {
    return [] as Array<Array<Number?> >;
}

(:test)
function goalBoundaryPicksPose(logger as Logger) as Boolean {
    var m = new MonkeyModel();
    Test.assertEqual(m.getTarget(), 5000);
    m.update(100, 0, noHistory());
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_RELAX);
    m.update(100, 2499, noHistory());
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_RELAX);
    m.update(100, 2500, noHistory());
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_PERK);
    m.update(100, 4999, noHistory());
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_PERK);
    Test.assert(m.takeEvent() == null);
    Test.assertEqual(m.getXp(), 0);
    m.update(100, 5000, noHistory());
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
    m.update(100, 5000, noHistory());
    Test.assert(m.takeEvent() != null);
    // Re-opening the dashboard the same day: completed pose, no second reward.
    m.update(100, 6200, noHistory());
    m.update(100, 6300, noHistory());
    Test.assert(m.takeEvent() == null);
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_EAT);
    Test.assertEqual(m.getXp(), MonkeyModel.XP_GOAL);
    // Midnight: fresh day, yesterday already rewarded live -> not counted twice.
    m.update(101, 0, [[100, 6300]] as Array<Array<Number?> >);
    Test.assert(m.takeEvent() == null);
    Test.assertEqual(m.getXp(), MonkeyModel.XP_GOAL);
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_RELAX);
    // The new day can be rewarded again.
    m.update(101, 5000, noHistory());
    Test.assert(m.takeEvent() != null);
    Test.assertEqual(m.getXp(), 2 * MonkeyModel.XP_GOAL);
    return true;
}

(:test)
function finishedDaysGainAndLoseXp(logger as Logger) as Boolean {
    var m = new MonkeyModel();
    m.update(100, 5000, noHistory());
    m.takeEvent();
    // App not opened on 101 and 102: 101 met (+100), 102 missed (-50), 100 was already rewarded live.
    var hist = [[102, 1200], [101, 7000], [100, 5000], [99, 0]] as Array<Array<Number?> >;
    m.update(103, 300, hist);
    Test.assertEqual(m.getXp(), 2 * MonkeyModel.XP_GOAL - MonkeyModel.XP_MISS);
    var e = m.takeEvent();
    Test.assert(e != null);
    if (e != null) {
        Test.assertEqual(e[0], MonkeyModel.XP_GOAL - MonkeyModel.XP_MISS);
        Test.assert(!e[1]);
    }
    // Settled once only.
    m.update(103, 400, hist);
    Test.assertEqual(m.getXp(), 2 * MonkeyModel.XP_GOAL - MonkeyModel.XP_MISS);
    return true;
}

(:test)
function xpNeverNegativeAndMissingDaysIgnored(logger as Logger) as Boolean {
    var m = new MonkeyModel();
    m.update(10, 0, noHistory());
    m.update(13, 0, [[12, 0], [11, null]] as Array<Array<Number?> >);
    Test.assertEqual(m.getXp(), 0);
    Test.assert(m.takeEvent() == null);
    return true;
}

(:test)
function unavailableReading(logger as Logger) as Boolean {
    var m = new MonkeyModel();
    m.update(50, null, noHistory());
    Test.assert(m.getValue() == null);
    Test.assertEqual(m.getProgressPermille(), 0);
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_RELAX);
    Test.assert(m.takeEvent() == null);
    return true;
}

(:test)
function goalChangeAppliesNow(logger as Logger) as Boolean {
    var m = new MonkeyModel();
    m.update(70, 3000, noHistory());
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_PERK);
    m.setGoal(MonkeyModel.GOAL_STEPS, 3000);
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_EAT);
    Test.assert(m.takeEvent() != null);
    // Raising the goal keeps today's XP but shows progress against the new target.
    m.setGoal(MonkeyModel.GOAL_STEPS, 10000);
    Test.assertEqual(m.getXp(), MonkeyModel.XP_GOAL);
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_RELAX);
    // Other goal types use their own targets.
    m.setGoal(MonkeyModel.GOAL_ACTIVE, 30);
    m.update(70, 29, noHistory());
    Test.assertEqual(m.getPose(), MonkeyModel.POSE_PERK);
    Test.assertEqual(MonkeyModel.targetsFor(MonkeyModel.GOAL_FLOORS)[0], 5);
    return true;
}

(:test)
function demoCyclesWithoutTouchingLiveXp(logger as Logger) as Boolean {
    var m = new MonkeyModel();
    m.update(200, 5000, noHistory());
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
    Test.assertEqual(m.getDemoStage(), MonkeyModel.DEMO_MISSED);
    Test.assertEqual(m.getXp(), 2 * MonkeyModel.XP_GOAL - MonkeyModel.XP_MISS);
    m.nextDemoStage();
    Test.assertEqual(m.getDemoStage(), 0);
    // Live updates while in demo are ignored for rewards.
    m.update(201, 9000, noHistory());
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
    m.update(300, 5000, noHistory());
    m.takeEvent();
    m.update(303, 0, [[302, 5000], [301, 5000]] as Array<Array<Number?> >);
    Test.assertEqual(m.getXp(), 3 * MonkeyModel.XP_GOAL);
    Test.assertEqual(m.getLevel(), 2);
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
