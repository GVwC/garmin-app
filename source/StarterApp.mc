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
        var pair = $.createDashboard();
        _view = pair[0] as MainView;
        return pair;
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
function createDashboard() as [Views, InputDelegates] {
    var model = new MonkeyModel();
    model.load();
    var vitals = new VitalsModel();
    vitals.load();
    Reminders.sync(vitals.isEnabled());
    Log.debug("start goal=" + model.getGoalType() + "/" + model.getTarget() + " xp=" + model.getXp());
    var view = new MainView(model, vitals);
    return [view, new MainDelegate(model, vitals, view)];
}
