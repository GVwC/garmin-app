import Toybox.Lang;
import Toybox.WatchUi;

// App menu: Goal -> goal picker, Breathe, Reminders toggle, Demo mode toggle.
class AppMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _model as MonkeyModel;
    private var _vitals as VitalsModel;
    private var _view as MainView;

    function initialize(model as MonkeyModel, vitals as VitalsModel, view as MainView) {
        Menu2InputDelegate.initialize();
        _model = model;
        _vitals = vitals;
        _view = view;
    }

    function onSelect(item as MenuItem) as Void {
        var id = item.getId();
        if (id == Menus.MENU_GOAL) {
            WatchUi.switchToView(Menus.goalTypeMenu(_model), new GoalTypeMenuDelegate(_model, _view), WatchUi.SLIDE_LEFT);
        } else if (id == Menus.MENU_BREATHE) {
            var breath = new BreathView(_model);
            WatchUi.switchToView(breath, new BreathDelegate(breath, _view), WatchUi.SLIDE_LEFT);
        } else if (id == Menus.MENU_REMINDERS) {
            var on = (item as ToggleMenuItem).isEnabled();
            _vitals.setEnabled(on);
            Reminders.sync(on);
            Log.debug("reminders=" + on);
        } else if (id == Menus.MENU_DEMO) {
            if (_model.isDemo()) {
                _model.exitDemo();
            } else {
                _model.enterDemo();
            }
            Log.debug("demo=" + _model.isDemo());
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            _view.onModelChanged();
        }
    }
}

// Step 1: which activity feeds the monkey. Replaced by the target menu on select.
class GoalTypeMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _model as MonkeyModel;
    private var _view as MainView;

    function initialize(model as MonkeyModel, view as MainView) {
        Menu2InputDelegate.initialize();
        _model = model;
        _view = view;
    }

    function onSelect(item as MenuItem) as Void {
        var type = item.getId() as Number;
        WatchUi.switchToView(Menus.targetMenu(_model, type), new TargetMenuDelegate(_model, _view, type), WatchUi.SLIDE_LEFT);
    }
}

// Step 2: daily target. Saves the goal and returns to the dashboard.
class TargetMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _model as MonkeyModel;
    private var _view as MainView;
    private var _type as Number;

    function initialize(model as MonkeyModel, view as MainView, goalType as Number) {
        Menu2InputDelegate.initialize();
        _model = model;
        _view = view;
        _type = goalType;
    }

    function onSelect(item as MenuItem) as Void {
        _model.setGoal(_type, item.getId() as Number);
        Log.debug("goal " + _type + " " + _model.getTarget());
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        _view.onModelChanged();
    }
}
