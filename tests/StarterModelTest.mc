import Toybox.Lang;
import Toybox.Test;

// Unit tests. Only compiled with --unit-test. Each (:test) function receives a
// Test.Logger and returns true on success; Test.assert* raise on failure.

(:test)
function starterModelStartsAtZero(logger as Logger) as Boolean {
    var model = new StarterModel();
    Test.assertEqual(model.getPressCount(), 0);
    return true;
}

(:test)
function starterModelCountsPresses(logger as Logger) as Boolean {
    var model = new StarterModel();
    model.recordPress();
    model.recordPress();
    Test.assertEqual(model.getPressCount(), 2);
    model.reset();
    Test.assertEqual(model.getPressCount(), 0);
    logger.debug("press counting ok");
    return true;
}
