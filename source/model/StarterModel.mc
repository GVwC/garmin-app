import Toybox.Lang;

// Plain application state. No Toybox UI/sensor calls here, so it is unit-testable.
// Replace with your real app's state when you start a new app.
class StarterModel {

    private var _pressCount as Number = 0;

    function initialize() {
    }

    function recordPress() as Void {
        _pressCount += 1;
    }

    function getPressCount() as Number {
        return _pressCount;
    }

    function reset() as Void {
        _pressCount = 0;
    }
}
