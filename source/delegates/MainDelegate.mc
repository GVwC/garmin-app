import Toybox.Lang;
import Toybox.WatchUi;

// fenix 7 Pro buttons via BehaviorDelegate:
//   START (or tap)  -> onSelect   : goal picker
//   hold UP (MENU)  -> onMenu     : app menu (goal, demo mode)
//   DOWN            -> onNextPage : next demo stage (demo only)
//   BACK            -> onBack     : leave demo; in live mode exit the app
class MainDelegate extends WatchUi.BehaviorDelegate {

    private var _model as MonkeyModel;
    private var _view as MainView;

    function initialize(model as MonkeyModel, view as MainView) {
        BehaviorDelegate.initialize();
        _model = model;
        _view = view;
    }

    function onSelect() as Boolean {
        WatchUi.pushView(Menus.goalTypeMenu(_model), new GoalTypeMenuDelegate(_model, _view), WatchUi.SLIDE_UP);
        return true;
    }

    function onMenu() as Boolean {
        WatchUi.pushView(Menus.appMenu(_model), new AppMenuDelegate(_model, _view), WatchUi.SLIDE_UP);
        return true;
    }

    function onNextPage() as Boolean {
        if (!_model.isDemo()) {
            return false;
        }
        _model.nextDemoStage();
        Log.debug("demo stage " + _model.getDemoStage());
        _view.onModelChanged();
        return true;
    }

    // Returning false on the root view lets the system exit the app.
    function onBack() as Boolean {
        if (_model.isDemo()) {
            _model.exitDemo();
            Log.debug("demo off");
            _view.onModelChanged();
            return true;
        }
        return false;
    }
}
