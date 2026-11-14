import Toybox.Lang;
import Toybox.WatchUi;

// Menu2 builders. Item ids are Numbers: goal type, target value, or a MENU_* id.
module Menus {

    const MENU_GOAL = 100;
    const MENU_DEMO = 101;
    const MENU_BREATHE = 102;
    const MENU_REMINDERS = 103;

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

    function s(id as ResourceId) as String {
        return WatchUi.loadResource(id) as String;
    }

    function appMenu(model as MonkeyModel, vitals as VitalsModel) as Menu2 {
        var menu = new WatchUi.Menu2({:title => s(Rez.Strings.MenuTitle)});
        menu.addItem(new WatchUi.MenuItem(s(Rez.Strings.MenuGoal), goalSummary(model), MENU_GOAL, null));
        menu.addItem(new WatchUi.MenuItem(s(Rez.Strings.MenuBreathe), s(Rez.Strings.MenuBreatheSub), MENU_BREATHE, null));
        menu.addItem(new WatchUi.ToggleMenuItem(s(Rez.Strings.MenuReminders), s(Rez.Strings.MenuRemindersSub),
            MENU_REMINDERS, vitals.isEnabled(), null));
        menu.addItem(new WatchUi.ToggleMenuItem(s(Rez.Strings.MenuDemo), null, MENU_DEMO, model.isDemo(), null));
        return menu;
    }

    function goalTypeMenu(model as MonkeyModel) as Menu2 {
        var menu = new WatchUi.Menu2({:title => s(Rez.Strings.PickGoal)});
        for (var t = 0; t < Goals.GOAL_TYPES; t++) {
            var sub = (t == model.getGoalType()) ? goalSummary(model) : null;
            menu.addItem(new WatchUi.MenuItem(goalLabel(t), sub, t, null));
        }
        menu.setFocus(model.getGoalType());
        return menu;
    }

    function targetMenu(model as MonkeyModel, goalType as Number) as Menu2 {
        var menu = new WatchUi.Menu2({:title => s(Rez.Strings.PickTarget)});
        var targets = Goals.targetsFor(goalType);
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
