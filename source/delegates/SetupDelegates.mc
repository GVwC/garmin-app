import Toybox.Lang;
import Toybox.WatchUi;

// Onboarding input. Each step replaces the previous screen (switchToView), so BACK on the
// first screen exits the app and the dashboard is the root once the monkey has hatched.

class WelcomeDelegate extends WatchUi.BehaviorDelegate {

    private var _model as MonkeyModel;
    private var _vitals as VitalsModel;

    function initialize(model as MonkeyModel, vitals as VitalsModel) {
        BehaviorDelegate.initialize();
        _model = model;
        _vitals = vitals;
    }

    function onSelect() as Boolean {
        WatchUi.switchToView(Menus.namesMenu(_model), new NameMenuDelegate(_model, _vitals), WatchUi.SLIDE_LEFT);
        return true;
    }
}

class NameMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _model as MonkeyModel;
    private var _vitals as VitalsModel;

    function initialize(model as MonkeyModel, vitals as VitalsModel) {
        Menu2InputDelegate.initialize();
        _model = model;
        _vitals = vitals;
    }

    function onSelect(item as MenuItem) as Void {
        _model.setName(item.getId() as Number);
        var picker = new FurPickerView(_model);
        WatchUi.switchToView(picker, new FurPickerDelegate(_model, _vitals, picker), WatchUi.SLIDE_LEFT);
    }
}

class FurPickerDelegate extends WatchUi.BehaviorDelegate {

    private var _model as MonkeyModel;
    private var _vitals as VitalsModel;
    private var _picker as FurPickerView;

    function initialize(model as MonkeyModel, vitals as VitalsModel, picker as FurPickerView) {
        BehaviorDelegate.initialize();
        _model = model;
        _vitals = vitals;
        _picker = picker;
    }

    function onNextPage() as Boolean {
        _picker.cycle(1);
        return true;
    }

    function onPreviousPage() as Boolean {
        _picker.cycle(-1);
        return true;
    }

    function onSelect() as Boolean {
        WatchUi.switchToView(Menus.goalsMenu(_model, true), new GoalsMenuDelegate(_model, _vitals, null), WatchUi.SLIDE_LEFT);
        return true;
    }
}

// Hatching: START (once hatched) creates the character and opens the dashboard.
class HatchDelegate extends WatchUi.BehaviorDelegate {

    private var _model as MonkeyModel;
    private var _vitals as VitalsModel;
    private var _view as HatchView;

    function initialize(model as MonkeyModel, vitals as VitalsModel, view as HatchView) {
        BehaviorDelegate.initialize();
        _model = model;
        _vitals = vitals;
        _view = view;
    }

    function onSelect() as Boolean {
        if (_view.isHatched()) {
            _model.setCreated();
            Log.debug("hatched name=" + _model.getName() + " fur=" + _model.getFur());
            $.openDashboard(_model, _vitals);
        }
        return true;
    }

    function onBack() as Boolean {
        return true; // no going back into the shell
    }
}

// "Start over?" confirmation as a two-item menu.
class NewGameMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _model as MonkeyModel;

    function initialize(model as MonkeyModel) {
        Menu2InputDelegate.initialize();
        _model = model;
    }

    function onSelect(item as MenuItem) as Void {
        if (item.getId() == Menus.MENU_NEW_YES) {
            _model.newGame();
            Log.debug("new game");
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            $.startOnboarding(_model, new VitalsModel());
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }
}
