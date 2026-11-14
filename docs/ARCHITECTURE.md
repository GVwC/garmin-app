# Architecture

```
StarterApp (AppBase)             loads MonkeyModel from storage, returns MainView + MainDelegate
 ├─ MonkeyModel                  goal, XP, daily reward, demo — no UI calls, unit-tested
 ├─ MainView (View)              reads activity data into the model, draws the dashboard
 │   ├─ MonkeyArt (module)       pixel-art patches: shared body + per-pose eyes/mouth/arms/tail/banana
 │   └─ PixelSprite (module)     compiles patches to packed runs once, draws them scaled
 ├─ MainDelegate (BehaviorDelegate)   START goal picker, hold UP menu, DOWN demo stage, BACK
 └─ Menus + MenuDelegates        Menu2: app menu, goal type, target
ActivityService (module)         ActivityMonitor.getInfo()/getHistory() → numbers for the model
DayClock, Fmt, Log (modules)     local day numbers, "3,420" formatting, debug logging
```

Data flows one way: **input → delegate → model → view.onModelChanged / requestUpdate → onUpdate reads model**. Activity data enters through `MainView.refresh()` → `ActivityService` → `MonkeyModel.update(today, value, history)`. The model is passed through constructors, so there are no globals.

## Folders

| Path | Contents | Rule |
|---|---|---|
| `source/views` | View, menus, pixel art | Draw only; no business logic |
| `source/delegates` | input delegates | Translate input into model calls |
| `source/model` | `MonkeyModel` | No `WatchUi` / `Graphics` imports → testable |
| `source/services` | `ActivityService` | Toybox sensor/data access, returns plain values |
| `source/utils` | `Log`, `DayClock`, `Fmt` | Stateless helpers |
| `resources/strings` | all user-visible text | Load with `WatchUi.loadResource` |
| `resources/drawables` | launcher icon (40×40 on fenix7pro) | |
| `tests` | `(:test)` functions | Built only with `--unit-test` |

## Game rules (MonkeyModel)

| Rule | Value |
|---|---|
| Goal reached today (live) | +100 XP, once per local day; celebration plays once |
| Finished day settled from history | met +100 (unless already rewarded live), missed −50, no data → nothing |
| Catch-up window | last 7 days (what `ActivityMonitor.getHistory()` keeps) |
| First run | starts counting from today; no retroactive XP |
| Level | 1 + XP / 300; XP never below 0 |
| Poses | < 50 % relax · 50–99 % perk · ≥ 100 % eat |
| Demo | separate XP copy, stages 20/65/100 %/missed; never saves |

Stored keys (`Application.Storage`): `goalType`, `goalTarget`, `xp`, `rewardDay`, `lastEvalDay`. Days are local day numbers (`DayClock`), so "today" flips at local midnight like Garmin's step total. Storage is only written after `load()` — unit tests never touch it.

## Pixel art

`MonkeyArt` holds sprites as strings (`K` outline, `B` fur, `T` tan, `Y`/`G` banana …). The body is one shared patch; each pose adds small patches on top. `PixelSprite.compile()` turns them into one packed `Number` per horizontal run in `onLayout`, so `onUpdate` only does `fillRectangle` calls (scale 4 → ~96 px monkey). New poses/evolutions = new patch functions, no asset tooling.

## Data sources (checked against SDK 9.1.0 for fenix7pro)

| Available to the app | Not available |
|---|---|
| `ActivityMonitor.Info`: steps, stepGoal, activeMinutesDay/Week (+ week goal), floorsClimbed (+ goal), calories, distance, stressScore, timeToRecovery, moveBarLevel, respirationRate, isSleepMode | Sleep score, sleep stages, sleep duration |
| `ActivityMonitor.getHistory()`: last 7 days of steps, active minutes, floors, calories, distance | Training Readiness, HRV status |
| `SensorHistory`: Body Battery, stress, heart rate, SpO2, elevation, temperature | |
| `Complications` (read): Body Battery, stress, recovery time, training status, VO2 max | |

## Roadmap (designed, not built yet)

- **Multiple goals / character setup.** First-run flow: pick the monkey's look, then switch on the goals that give XP (steps, active minutes, floors, move bar, calm-stress day, morning Body Battery). The model's single goal becomes a list; each goal settles its own XP with the same rules.
- **Sleep goal.** Connect IQ apps cannot read sleep data (open Garmin feature request since 2022). Planned options, in order:
  1. *Morning Body Battery* ≥ threshold as a recovery proxy (`SensorHistory.getBodyBatteryHistory`).
  2. *Bedtime goal*: `Background.registerForSleepEvent` + `isSleepMode` to reward going to bed on time.
  3. *Self check-in*: one-tap "how did you sleep?" in the morning.
  4. Real sleep data only via Garmin's cloud Health API (needs a server and partner approval).
- **Forced midday reminder.** Background service (`Background.registerForTemporalEvent`, `System.ServiceDelegate`, `Background` permission, 64 KB memory) checks progress around 13:00; if under 50 %, `Background.requestApplicationWake("Your monkey is hungry!")` (or `Notifications.showNotification`, API 5.1+) prompts the user. Must be verified on a real watch; it cannot override Do Not Disturb.
- **Tamagotchi layer.** Needs (hunger = inactivity, energy = Body Battery, mood = stress), evolution stages per level, unlockable pixel items, streak multipliers, a glance view.

## Development safeguards

- **Null safety:** many Toybox calls return nullable values (e.g. `info.steps`, `info.activeMinutesDay`, `Application.Storage.getValue`). Declare `as Type?` and check `!= null` before use. Strict type-checking (`-l 3`) flags most misses.
- **Device/API compatibility:** guard optional APIs with `has` — see API_COMPATIBILITY.md. Keep `manifest.xml` products limited to devices you've actually tested.
- **Error handling:** Monkey C has `try/catch` for `Lang.Exception` subclasses; use it around operations documented to throw. Many fatal errors (out of memory, watchdog, null dereference) **cannot be caught** — prevent them instead.
- **Memory:** sprites are compiled once in `onLayout`; the app uses ~25 KB of the 768 KB limit in the simulator.
- **Redraws / battery:** the view timer runs every 60 s, and at 100 ms only during the 3 s celebration/banner; it stops in `onHide`. No sensors are enabled — the app only reads Garmin's own daily totals.
- **Logging:** `Log.debug("component: message")`; never log in `onUpdate` or loops; never log personal data.
