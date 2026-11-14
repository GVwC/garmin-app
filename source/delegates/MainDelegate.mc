import Toybox.Lang;
import Toybox.WatchUi;

// fenix 7 Pro buttons via BehaviorDelegate:
//   START (or tap)  -> onSelect       : goals, or the breathing screen when stressed/alert/breath low
//   hold UP (MENU)  -> onMenu         : app menu (goals, breathe, character, reminders, demo)
//   UP / DOWN       -> previous/next  : demo stages; in live mode cycle the shown goal
//   BACK            -> onBack         : leave demo; in live mode exit the app
class MainDelegate extends WatchUi.BehaviorDelegate {

    private var _model as MonkeyModel;
    private var _vitals as VitalsModel;
    private var _view as MainView;

    function initialize(model as MonkeyModel, vitals as VitalsModel, view as MainView) {
        BehaviorDelegate.initialize();
        _model = model;
        _vitals = vitals;
        _view = view;
    }

    function onSelect() as Boolean {
        if (MonkeyStatus.suggestsBreathing(_view.getMsg())) {
            var breath = new BreathView(_model);
            WatchUi.pushView(breath, new BreathDelegate(breath, _view), WatchUi.SLIDE_UP);
        } else {
            WatchUi.pushView(Menus.goalsMenu(_model, false), new GoalsMenuDelegate(_model, _vitals, _view), WatchUi.SLIDE_UP);
        }
        return true;
    }

    function onMenu() as Boolean {
        WatchUi.pushView(Menus.appMenu(_model, _vitals), new AppMenuDelegate(_model, _vitals, _view), WatchUi.SLIDE_UP);
        return true;
    }

    function onNextPage() as Boolean {
        if (!_model.isDemo()) {
            return showGoal(1);
        }
        _model.nextDemoStage();
        Log.debug("demo stage " + _model.getDemoStage());
        _view.onModelChanged();
        return true;
    }

    function onPreviousPage() as Boolean {
        if (!_model.isDemo()) {
            return showGoal(-1);
        }
        _model.prevDemoStage();
        Log.debug("demo stage " + _model.getDemoStage());
        _view.onModelChanged();
        return true;
    }

    private function showGoal(step as Number) as Boolean {
        if (_model.enabledGoals().size() < 2) {
            return false;
        }
        _model.showNext(step);
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

// Breathing screen: START restarts a finished session, BACK returns to the dashboard.
class BreathDelegate extends WatchUi.BehaviorDelegate {

    private var _breath as BreathView;
    private var _main as MainView;

    function initialize(breath as BreathView, main as MainView) {
        BehaviorDelegate.initialize();
        _breath = breath;
        _main = main;
    }

    function onSelect() as Boolean {
        if (_breath.isDone()) {
            _breath.restart();
        }
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        _main.onModelChanged();
        return true;
    }
}
