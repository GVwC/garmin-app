import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Application entry point (manifest: entry="StarterApp"). The same class runs in three
// contexts: the app (getInitialView), the glance (getGlanceView) and the background
// service (getServiceDelegate). Foreground-only code is marked disableBackgroundCheck.
// Always launches in live mode; demo mode is only entered from the menu.
(:background)
class StarterApp extends Application.AppBase {

    private var _view as MainView?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    (:typecheck([disableBackgroundCheck, disableGlanceCheck]))
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return $.createDashboard();
    }

    (:typecheck([disableBackgroundCheck, disableGlanceCheck]))
    function setView(view as MainView) as Void {
        _view = view;
    }

    (:typecheck(disableGlanceCheck))
    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new MonkeyService()];
    }

    (:glance, :typecheck(disableBackgroundCheck))
    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [new MonkeyGlance()];
    }

    // The background service finished a check while the app is open: show the new state.
    (:typecheck([disableBackgroundCheck, disableGlanceCheck]))
    function onBackgroundData(data as Application.PersistableType) as Void {
        var view = _view;
        if (view != null) {
            view.onBackgroundUpdate();
        }
    }
}

// Foreground-only construction, kept outside the background-capable app class.
// First launch shows character setup (egg -> name -> fur -> goals -> hatch); afterwards the dashboard.
function createDashboard() as [Views, InputDelegates] {
    var model = new MonkeyModel();
    model.load();
    var vitals = new VitalsModel();
    vitals.load();
    Reminders.sync(vitals.isEnabled());
    Log.debug("start goals=" + model.enabledGoals().size() + " xp=" + model.getXp() + " created=" + model.isCreated());
    if (!model.isCreated()) {
        return [new WelcomeView(model.getFur()), new WelcomeDelegate(model, vitals)];
    }
    var view = new MainView(model, vitals);
    $.registerView(view);
    return [view, new MainDelegate(model, vitals, view)];
}

// End of first-run setup: replace the setup menu with the dashboard.
function openDashboard(model as MonkeyModel, vitals as VitalsModel) as Void {
    var view = new MainView(model, vitals);
    $.registerView(view);
    WatchUi.switchToView(view, new MainDelegate(model, vitals, view), WatchUi.SLIDE_IMMEDIATE);
}

// "New game": back to the egg.
function startOnboarding(model as MonkeyModel, vitals as VitalsModel) as Void {
    vitals.load();
    WatchUi.switchToView(new WelcomeView(model.getFur()), new WelcomeDelegate(model, vitals), WatchUi.SLIDE_IMMEDIATE);
}

function registerView(view as MainView) as Void {
    (Application.getApp() as StarterApp).setView(view);
}
