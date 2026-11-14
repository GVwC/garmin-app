import Toybox.Lang;
import Toybox.Test;

// Unit tests. Only compiled with --unit-test. Each (:test) function receives a
// Test.Logger and returns true on success; Test.assert* raise on failure.

(:test)
function climbHeightsSpanBottomToSummit(logger as Logger) as Boolean {
    var m = new ClimbModel();
    m.setTime(0, 0, 0);
    Test.assertEqual(m.getHeight(0), 0);
    Test.assertEqual(m.getHeight(2), 0);
    m.setTime(23, 59, 59);
    Test.assertEqual(m.getValue(0), 11);
    Test.assertEqual(m.getHeight(0), 1000);
    Test.assertEqual(m.getHeight(1), 1000);
    Test.assertEqual(m.getHeight(2), 1000);
    return true;
}

(:test)
function hourClimberFallsAtNoon(logger as Logger) as Boolean {
    var m = new ClimbModel();
    m.setTime(11, 59, 59);
    m.setTime(12, 0, 0);
    Test.assertEqual(m.getValue(0), 0);
    Test.assertEqual(m.getFallFrames(0), ClimbModel.FALL_FRAMES);
    return true;
}

(:test)
function climberFallsWhenValueWraps(logger as Logger) as Boolean {
    var m = new ClimbModel();
    m.setTime(10, 20, 59);
    Test.assert(!m.isAnyFalling());
    m.setTime(10, 21, 0);
    Test.assertEqual(m.getFallFrames(2), ClimbModel.FALL_FRAMES);
    Test.assertEqual(m.getFallFrames(1), 0);
    Test.assertEqual(m.getFallFrames(0), 0);
    for (var i = 0; i < ClimbModel.FALL_FRAMES; i++) {
        m.stepFall();
    }
    Test.assert(!m.isAnyFalling());
    return true;
}

(:test)
function midnightDropsAllThree(logger as Logger) as Boolean {
    var m = new ClimbModel();
    m.setTime(23, 59, 59);
    m.setTime(0, 0, 0);
    Test.assertEqual(m.getFallFrames(0), ClimbModel.FALL_FRAMES);
    Test.assertEqual(m.getFallFrames(1), ClimbModel.FALL_FRAMES);
    Test.assertEqual(m.getFallFrames(2), ClimbModel.FALL_FRAMES);
    return true;
}

(:test)
function demoAdvancesFromShownTime(logger as Logger) as Boolean {
    var m = new ClimbModel();
    m.setTime(1, 2, 3);
    m.toggleDemo();
    m.tick(9, 9, 9); // real clock ignored in demo
    Test.assertEqual(m.getValue(0), 1);
    Test.assertEqual(m.getValue(1), 3);
    Test.assertEqual(m.getValue(2), 4);
    m.toggleDemo();
    m.tick(9, 9, 9);
    Test.assertEqual(m.getValue(0), 9);
    logger.debug("demo ok");
    return true;
}
