import Toybox.Lang;
import Toybox.WatchUi;

// Input for MainView. BehaviorDelegate maps device-specific input to behaviours:
// on fenix 7 Pro, START button or screen tap -> onSelect; BACK button or swipe right -> onBack.
class MainDelegate extends WatchUi.BehaviorDelegate {

    private var _model as ClimbModel;

    function initialize(model as ClimbModel) {
        BehaviorDelegate.initialize();
        _model = model;
    }

    // START toggles demo mode (fast time) so minute/hour falls can be seen quickly.
    function onSelect() as Boolean {
        _model.toggleDemo();
        Log.debug("demo=" + _model.isDemo());
        WatchUi.requestUpdate();
        return true;
    }

    // Returning false lets the system handle BACK; on the root view that exits the app.
    function onBack() as Boolean {
        Log.debug("onBack -> exit");
        return false;
    }
}
