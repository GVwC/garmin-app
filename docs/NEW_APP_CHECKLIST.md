# New app checklist

Work through this in order. Commit a compiling state after each step.

## 0. Copy the starter

1. Copy the folder (or `git clone` it) to a new name; delete the copy's `.git` if you want fresh history, then `git init`.
2. VS Code → **Monkey C: Regenerate UUID** (every app needs its own id).
3. Update `AppName` in `resources/strings/strings.xml`, replace `resources/drawables/launcher_icon.svg` (40×40).

## 1. Choose an app type

| Type | Use it for | Runs |
|---|---|---|
| Watch app (`watch-app`) — *current* | Full-screen interactive app | When the user opens it |
| Watch face (`watchface`) | Time display + data | Always; very limited input & power |
| Data field (`datafield`) | One field inside a Garmin activity | Only during activities |
| Glance (part of a watch app) | Summary line in the glance loop | Glance loop; 64 KB budget |
| Background service (part of an app) | Periodic work (e.g. fetch data) | Temporal events; 64 KB budget |

## 2. Define the purpose
Write 1–3 sentences: who uses it, when, what it shows, what input it takes. Put them at the top of README.md.

## 3. Identify required Toybox APIs
List each module/class you need (e.g. `Toybox.Sensor`, `Toybox.Position`, `Toybox.Communications`, `Toybox.Application.Storage`) with its doc link and "Since" version. Note required manifest permissions (*Monkey C: Edit Permissions*).

## 4. Check device compatibility
Confirm every API is ≤ 5.2.0 and available on fenix7pro (compile to prove it). Plan `has` guards for optional features. See [API_COMPATIBILITY.md](API_COMPATIBILITY.md).

## 5. Plan screens and navigation
Sketch each screen at 260×260 round (content inside the circle). Map inputs: START/tap = select, BACK = back/exit, UP/DOWN = page, hold UP = menu. Use `WatchUi.pushView`/`popView` for navigation; `Menu2` for menus.

## 6. Implement the smallest functional version
Replace `MonkeyModel` with your state, `MainView` with your first screen, `MainDelegate` with your input. Keep one screen working before adding more.

## 7. Test in the simulator
`ciq.ps1 build` (no warnings) → `ciq.ps1 test` → `ciq.ps1 run`. Use *Simulation* menu to fake sensors/activity data/GPS; check memory in the status bar; try *Settings → Low battery*, etc.

## 8. Test on the real watch
Sideload (DEVELOPMENT.md). Check buttons, touch, readability outdoors, sensor behaviour, and `GARMIN\APPS\LOGS\CIQ_LOG.YML` for crashes.

## 9. Optimise memory and battery
Peak memory well below the limit (leave ≥ 20% headroom), no timers faster than needed, sensors off when hidden, no work in `onUpdate` beyond drawing. Try a release build (`-r`) to compare size.

## 10. Prepare a release (optional)
Final name/icon/UUID, store description and screenshots, `ciq.ps1 package` → upload `.iq` at https://apps.garmin.com/developer. Keep your developer key backed up — updates must be signed with the same key.

---

## Converting to another app type

App types are **not** interchangeable by changing one attribute: each type has a different base class, lifecycle and limits. Expect to rewrite the view and delegate.

| Target | `manifest.xml` | `source/StarterApp.mc` | View / delegate | Notes |
|---|---|---|---|---|
| **Watch face** | `type="watchface"` | `getInitialView()` returns `[new MyWatchFace()]` (optionally `+ WatchFaceDelegate`) | View extends `WatchUi.WatchFace`; remove `MainDelegate` (watch faces get no button input) | `onUpdate` runs ~once per minute (more in high-power mode after a gesture); per-second updates need `onPartialUpdate` with a strict power budget. 128 KB. |
| **Data field** | `type="datafield"` | `getInitialView()` returns `[new MyField()]` | Extend `WatchUi.SimpleDataField` (return a value from `compute`) or `WatchUi.DataField` (custom drawing); no delegate | `compute(info as Activity.Info)` ~1×/s during activities; layout must handle multiple field sizes. 256 KB. |
| **Glance** | stays `watch-app` | add `(:glance) function getGlanceView()` returning `[new MyGlanceView()]` | `(:glance)` class extending `WatchUi.GlanceView` | Only `(:glance)`-annotated code is loaded in the glance; 64 KB. On fenix7pro the device file lists no separate `widget` memory budget, i.e. widget-style use = watch app + glance; verify in the simulator's glance view. |
| **Background service** | add `Background` permission | `(:background)` `getServiceDelegate()` | `(:background)` class extending `System.ServiceDelegate`; register with `Background.registerForTemporalEvent` | 64 KB; minimum 5-minute temporal interval. |
| **Standalone app** (current) | `type="watch-app"` | as is | `View` + `BehaviorDelegate` | 768 KB. |

Tip: the SDK has a template per type in `<SDK>\bin\templates\` and full examples in `<SDK>\samples\`. Starting from *Monkey C: New Project* for a different type and moving over `docs/`, `AGENTS.md`, `CLAUDE.md`, `scripts/`, `.vscode/` and `.gitignore` is often cleaner than converting.
