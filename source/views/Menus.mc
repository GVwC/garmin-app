import Toybox.Lang;
import Toybox.WatchUi;

// Menu2 builders. Item ids are Numbers: goal type, target value, fur index or a MENU_* id.
module Menus {

    const MENU_GOALS = 100;
    const MENU_DEMO = 101;
    const MENU_BREATHE = 102;
    const MENU_REMINDERS = 103;
    const MENU_CHARACTER = 104;
    const MENU_DONE = 105;
    const MENU_NEW_GAME = 106;
    const MENU_JOURNEY = 109;
    const MENU_NEW_YES = 107;
    const MENU_NEW_NO = 108;
    const TARGET_OFF = -1;

    function s(id as ResourceId) as String {
        return WatchUi.loadResource(id) as String;
    }

    function goalLabel(goalType as Number) as String {
        return s([Rez.Strings.GoalSteps, Rez.Strings.GoalActive, Rez.Strings.GoalFloors][goalType]);
    }

    function unitLabel(goalType as Number) as String {
        return s([Rez.Strings.UnitSteps, Rez.Strings.UnitActive, Rez.Strings.UnitFloors][goalType]);
    }

    function targetLabel(goalType as Number, target as Number) as String {
        return Fmt.thousands(target) + " " + unitLabel(goalType);
    }

    // "5,000 steps" when on, "Off" otherwise.
    function goalSub(model as MonkeyModel, goalType as Number) as String {
        return model.isGoalOn(goalType) ? targetLabel(goalType, model.getTargetFor(goalType)) : s(Rez.Strings.Off);
    }

    function goalsSummary(model as MonkeyModel) as String {
        var goals = model.enabledGoals();
        var out = "";
        for (var i = 0; i < goals.size(); i++) {
            out += (i > 0 ? ", " : "") + goalLabel(goals[i]);
        }
        return out;
    }

    function furLabel(fur as Number) as String {
        return s([Rez.Strings.Fur0, Rez.Strings.Fur1, Rez.Strings.Fur2, Rez.Strings.Fur3][fur]);
    }

    function nameLabel(name as Number) as String {
        return s([Rez.Strings.Name0, Rez.Strings.Name1, Rez.Strings.Name2, Rez.Strings.Name3, Rez.Strings.Name4][name]);
    }

    // Onboarding step 1: pick a name.
    function namesMenu(model as MonkeyModel) as Menu2 {
        var menu = new WatchUi.Menu2({:title => s(Rez.Strings.PickName)});
        for (var n = 0; n < MonkeyModel.NAME_COUNT; n++) {
            menu.addItem(new WatchUi.MenuItem(nameLabel(n), null, n, null));
        }
        menu.setFocus(model.getName());
        return menu;
    }

    // "Start over with a new egg?" Yes / No.
    function newGameMenu() as Menu2 {
        var menu = new WatchUi.Menu2({:title => s(Rez.Strings.NewGameAsk)});
        menu.addItem(new WatchUi.MenuItem(s(Rez.Strings.NewGameNo), null, MENU_NEW_NO, null));
        menu.addItem(new WatchUi.MenuItem(s(Rez.Strings.NewGameYes), s(Rez.Strings.NewGameYesSub), MENU_NEW_YES, null));
        return menu;
    }

    function appMenu(model as MonkeyModel, vitals as VitalsModel) as Menu2 {
        var menu = new WatchUi.Menu2({:title => s(Rez.Strings.MenuTitle)});
        menu.addItem(new WatchUi.MenuItem(s(Rez.Strings.MenuGoals), goalsSummary(model), MENU_GOALS, null));
        menu.addItem(new WatchUi.MenuItem(s(Rez.Strings.MenuJourney), s(Rez.Strings.MenuJourneySub), MENU_JOURNEY, null));
        menu.addItem(new WatchUi.MenuItem(s(Rez.Strings.MenuBreathe), s(Rez.Strings.MenuBreatheSub), MENU_BREATHE, null));
        menu.addItem(new WatchUi.MenuItem(s(Rez.Strings.MenuCharacter), furLabel(model.getFur()), MENU_CHARACTER, null));
        menu.addItem(new WatchUi.ToggleMenuItem(s(Rez.Strings.MenuReminders), s(Rez.Strings.MenuRemindersSub),
            MENU_REMINDERS, vitals.isEnabled(), null));
        menu.addItem(new WatchUi.ToggleMenuItem(s(Rez.Strings.MenuDemo), null, MENU_DEMO, model.isDemo(), null));
        menu.addItem(new WatchUi.MenuItem(s(Rez.Strings.MenuNewGame), s(Rez.Strings.MenuNewGameSub), MENU_NEW_GAME, null));
        return menu;
    }

    // Character step 1: fur colour.
    function furMenu(model as MonkeyModel, setup as Boolean) as Menu2 {
        var menu = new WatchUi.Menu2({:title => s(setup ? Rez.Strings.PickFurSetup : Rez.Strings.PickFur)});
        for (var f = 0; f < MonkeyModel.FUR_COUNT; f++) {
            menu.addItem(new WatchUi.MenuItem(furLabel(f), null, f, null));
        }
        menu.setFocus(model.getFur());
        return menu;
    }

    // Character step 2 / START: which goals feed the monkey. In setup a "Done" item closes it.
    function goalsMenu(model as MonkeyModel, setup as Boolean) as Menu2 {
        var menu = new WatchUi.Menu2({:title => s(setup ? Rez.Strings.PickGoalsSetup : Rez.Strings.PickGoals)});
        for (var t = 0; t < Goals.GOAL_TYPES; t++) {
            menu.addItem(new WatchUi.MenuItem(goalLabel(t), goalSub(model, t), t, null));
        }
        if (setup) {
            menu.addItem(new WatchUi.MenuItem(s(Rez.Strings.Done), null, MENU_DONE, null));
        }
        menu.setFocus(model.getGoalType());
        return menu;
    }

    // Daily target for one goal; "Off" is offered while another goal stays on.
    function targetMenu(model as MonkeyModel, goalType as Number) as Menu2 {
        var menu = new WatchUi.Menu2({:title => goalLabel(goalType)});
        var offered = model.isGoalOn(goalType) && model.enabledGoals().size() > 1;
        if (offered) {
            menu.addItem(new WatchUi.MenuItem(s(Rez.Strings.Off), null, TARGET_OFF, null));
        }
        var targets = Goals.targetsFor(goalType);
        var focus = 2;
        for (var i = 0; i < targets.size(); i++) {
            menu.addItem(new WatchUi.MenuItem(targetLabel(goalType, targets[i]), null, targets[i], null));
            if (model.isGoalOn(goalType) && targets[i] == model.getTargetFor(goalType)) {
                focus = i;
            }
        }
        menu.setFocus(offered ? focus + 1 : focus);
        return menu;
    }
}
