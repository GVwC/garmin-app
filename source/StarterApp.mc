import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Application entry point (manifest: entry="StarterApp").
// Owns the model and wires it into the initial view + delegate.
class StarterApp extends Application.AppBase {

    private var _model as StarterModel;

    function initialize() {
        AppBase.initialize();
        _model = new StarterModel();
    }

    function onStart(state as Dictionary?) as Void {
        Log.debug("onStart");
    }

    function onStop(state as Dictionary?) as Void {
        Log.debug("onStop");
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new MainView(_model), new MainDelegate(_model)];
    }
}
