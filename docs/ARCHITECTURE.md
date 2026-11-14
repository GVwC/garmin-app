# Architecture

```
StarterApp (AppBase)          owns state, returns the initial view + delegate
 ├─ ClimbModel                plain state/logic — no UI calls, unit-tested
 ├─ MainView (View)           reads the model, draws with Dc
 └─ MainDelegate (BehaviorDelegate)
                              input → updates model → WatchUi.requestUpdate()
Log (module)                  Log.debug(), compiled out of release builds
```

Data flows one way: **input → delegate → model → requestUpdate → view.onUpdate reads model**. The model is passed into the view and delegate through their constructors, so there are no globals.

## Folders

| Path | Contents | Rule |
|---|---|---|
| `source/views` | `WatchUi.View` subclasses | Draw only; no business logic |
| `source/delegates` | input delegates | Translate input into model calls |
| `source/model` | state & logic classes | No `WatchUi` / `Graphics` imports → testable |
| `source/utils` | small helpers (`Log`) | Stateless |
| `resources/strings` | all user-visible text | Load with `WatchUi.loadResource` |
| `resources/drawables` | launcher icon (40×40 on fenix7pro) | |
| `tests` | `(:test)` functions | Built only with `--unit-test` |

The starter draws directly with the `Dc` instead of a layout XML — it's smaller and easier to replace. Add `resources/layouts/` and `setLayout(Rez.Layouts.X(dc))` if you prefer layouts. Add `source/services/` when you have sensor/network/storage access code to isolate.

## Development safeguards

- **Null safety:** many Toybox calls return nullable values (e.g. `Activity.getActivityInfo()`, `info.currentHeartRate`, `Application.Storage.getValue`). Declare `as Type?` and check `!= null` before use. Strict type-checking (`-l 3`) flags most misses.
- **Device/API compatibility:** guard optional APIs with `has` — see API_COMPATIBILITY.md. Keep `manifest.xml` products limited to devices you've actually tested.
- **Error handling:** Monkey C has `try/catch` for `Lang.Exception` subclasses; use it around operations documented to throw (e.g. storage/parsing). Many fatal errors (out of memory, watchdog "code executed too long", null dereference) **cannot be caught** — prevent them instead.
- **Memory:** load resources once in `onLayout`/`onShow`, free large ones (bitmaps) in `onHide` by setting them to `null`; avoid big arrays/dictionaries and per-frame allocations; watch the simulator memory bar.
- **Redraws:** call `WatchUi.requestUpdate()` only when state changes. If you need a timer, use the slowest acceptable rate and stop it in `onHide`.
- **Battery:** enable sensors/GPS (`Sensor.setEnabledSensors`, `Position.enableLocationEvents`) only while needed and disable in `onHide`/`onStop`. Each needs the matching manifest permission.
- **UI/logic separation:** see folder rules above.
- **Logging:** `Log.debug("component: message")`; never log in `onUpdate` or loops; never log personal data.
