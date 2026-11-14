import Toybox.Lang;
import Toybox.WatchUi;

// Menu2 builders. Item ids are Numbers: goal type, target value, or a MENU_* id.
module Menus {

    const MENU_GOAL = 100;
    const MENU_DEMO = 101;

    function goalLabel(goalType as Number) as String {
        var ids = [Rez.Strings.GoalSteps, Rez.Strings.GoalActive, Rez.Strings.GoalFloors];
        return WatchUi.loadResource(ids[goalType]) as String;
    }

    function unitLabel(goalType as Number) as String {
        var ids = [Rez.Strings.UnitSteps, Rez.Strings.UnitActive, Rez.Strings.UnitFloors];
        return WatchUi.loadResource(ids[goalType]) as String;
    }

    function goalSummary(model as MonkeyModel) as String {
        return Fmt.thousands(model.getTarget()) + " " + unitLabel(model.getGoalType());
    }

    function appMenu(model as MonkeyModel) as Menu2 {
        var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.MenuTitle) as String});
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.MenuGoal) as String,
            goalSummary(model), MENU_GOAL, null));
        menu.addItem(new WatchUi.ToggleMenuItem(WatchUi.loadResource(Rez.Strings.MenuDemo) as String,
            null, MENU_DEMO, model.isDemo(), null));
        return menu;
    }

    function goalTypeMenu(model as MonkeyModel) as Menu2 {
        var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.PickGoal) as String});
        for (var t = 0; t < MonkeyModel.GOAL_TYPES; t++) {
            var sub = (t == model.getGoalType()) ? goalSummary(model) : null;
            menu.addItem(new WatchUi.MenuItem(goalLabel(t), sub, t, null));
        }
        menu.setFocus(model.getGoalType());
        return menu;
    }

    function targetMenu(model as MonkeyModel, goalType as Number) as Menu2 {
        var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.PickTarget) as String});
        var targets = MonkeyModel.targetsFor(goalType);
        var focus = 2;
        for (var i = 0; i < targets.size(); i++) {
            menu.addItem(new WatchUi.MenuItem(Fmt.thousands(targets[i]) + " " + unitLabel(goalType), null, targets[i], null));
            if (goalType == model.getGoalType() && targets[i] == model.getTarget()) {
                focus = i;
            }
        }
        menu.setFocus(focus);
        return menu;
    }
}
