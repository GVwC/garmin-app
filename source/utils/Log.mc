import Toybox.Lang;
import Toybox.System;

// Debug logging. (:debug) code is excluded from release builds and (:release)
// code from debug builds, so Log.debug() is a no-op in packaged apps.
// Note: string arguments are still built at the call site, so avoid logging in
// tight loops or onUpdate().
module Log {

    (:debug)
    function debug(msg as String) as Void {
        System.println("[Starter] " + msg);
    }

    (:release)
    function debug(msg as String) as Void {
    }
}
