import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Application entry point (manifest: entry="StarterApp").
// Owns the Monkey Miles model (loaded from storage) and wires it into the dashboard.
// Always launches in live mode; demo mode is only entered from the menu.
class StarterApp extends Application.AppBase {

    private var _model as MonkeyModel;

    function initialize() {
        AppBase.initialize();
        _model = new MonkeyModel();
    }

    function onStart(state as Dictionary?) as Void {
        _model.load();
        Log.debug("onStart goal=" + _model.getGoalType() + "/" + _model.getTarget() + " xp=" + _model.getXp());
    }

    function onStop(state as Dictionary?) as Void {
        Log.debug("onStop");
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new MainView(_model);
        return [view, new MainDelegate(_model, view)];
    }
}
