import Toybox.Lang;
import Toybox.WatchUi;

// App menu: Goals, Breathe, Character, Reminders toggle, Demo mode toggle.
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
        if (id == Menus.MENU_GOALS) {
            WatchUi.switchToView(Menus.goalsMenu(_model, false), new GoalsMenuDelegate(_model, _vitals, _view), WatchUi.SLIDE_LEFT);
        } else if (id == Menus.MENU_CHARACTER) {
            WatchUi.switchToView(Menus.furMenu(_model, false), new FurMenuDelegate(_model, _vitals, _view), WatchUi.SLIDE_LEFT);
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

// Fur colour. During first-run setup (view == null) it continues to the goals step.
class FurMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _model as MonkeyModel;
    private var _vitals as VitalsModel;
    private var _view as MainView?;

    function initialize(model as MonkeyModel, vitals as VitalsModel, view as MainView?) {
        Menu2InputDelegate.initialize();
        _model = model;
        _vitals = vitals;
        _view = view;
    }

    function onSelect(item as MenuItem) as Void {
        _model.setFur(item.getId() as Number);
        var view = _view;
        if (view == null) {
            WatchUi.switchToView(Menus.goalsMenu(_model, true), new GoalsMenuDelegate(_model, _vitals, null), WatchUi.SLIDE_LEFT);
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            view.onModelChanged();
        }
    }
}

// Which goals give XP. Selecting a goal opens its target menu; "Done" ends first-run setup.
class GoalsMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _model as MonkeyModel;
    private var _vitals as VitalsModel;
    private var _view as MainView?;

    function initialize(model as MonkeyModel, vitals as VitalsModel, view as MainView?) {
        Menu2InputDelegate.initialize();
        _model = model;
        _vitals = vitals;
        _view = view;
    }

    function onSelect(item as MenuItem) as Void {
        var id = item.getId() as Number;
        if (id == Menus.MENU_DONE) {
            _model.setCreated();
            Log.debug("character created");
            $.openDashboard(_model, _vitals);
            return;
        }
        WatchUi.pushView(Menus.targetMenu(_model, id), new TargetMenuDelegate(_model, id, item), WatchUi.SLIDE_LEFT);
    }

    function onBack() as Void {
        var view = _view;
        if (view == null) {
            // Setup: BACK finishes with what was picked so far.
            _model.setCreated();
            $.openDashboard(_model, _vitals);
            return;
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        view.onModelChanged();
    }
}

// Daily target (or Off) for one goal; updates the goals list it came from.
class TargetMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _model as MonkeyModel;
    private var _type as Number;
    private var _item as MenuItem;

    function initialize(model as MonkeyModel, goalType as Number, item as MenuItem) {
        Menu2InputDelegate.initialize();
        _model = model;
        _type = goalType;
        _item = item;
    }

    function onSelect(item as MenuItem) as Void {
        var target = item.getId() as Number;
        if (target == Menus.TARGET_OFF) {
            _model.setGoalOn(_type, false);
        } else {
            _model.setGoal(_type, target);
        }
        Log.debug("goal " + _type + " on=" + _model.isGoalOn(_type) + " " + _model.getTargetFor(_type));
        _item.setSubLabel(Menus.goalSub(_model, _type));
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
