# Architecture

Monkey Miles runs in three contexts on the watch, all from the same `StarterApp` class:

| Context | Entry | Memory (fēnix 7 Pro) | What runs |
|---|---|---|---|
| App | `getInitialView()` → `createDashboard()` | 768 KB | dashboard, menus, breathing |
| Background | `getServiceDelegate()` → `MonkeyService` | 64 KB | vitals check + reminder every 30 min |
| Glance | `getGlanceView()` → `MonkeyGlance` | 64 KB | one-line status in the widget list |

Code is annotated `(:background)` / `(:glance)` so each context only loads what it needs; foreground-only methods on the app class use `:typecheck(disableBackgroundCheck/disableGlanceCheck)`.

```
StarterApp (AppBase, :background)
 ├─ createDashboard()             loads MonkeyModel + VitalsModel, syncs Reminders, builds MainView
 ├─ MonkeyService (ServiceDelegate, :background)
 │     VitalsService.snapshot() → VitalsModel.apply() → pickNudge() → Background.requestApplicationWake()
 └─ MonkeyGlance (GlanceView, :glance)   reads Storage + today's goal total

model/      Goals (shared)  Vitals + VitalsSnapshot (pure rules)  VitalsModel (persisted state, nudges)
            MonkeyModel (goal, XP, bonuses, demo)  MonkeyStatus (pose/tint/recommendation)  DemoScenarios
services/   ActivityService/ActivityHistory (steps, active min, floors)  VitalsService (snapshot)  Reminders
views/      MainView  BreathView  MonkeyGlance  Menus  MonkeyArt (pixel patches)  PixelSprite (renderer)
delegates/  MainDelegate + BreathDelegate  MenuDelegates
background/ MonkeyService
utils/      DayClock  Fmt  Log
```

Data flow (app): **input → delegate → model → `MainView.onModelChanged()` → `onUpdate` reads model**. Vitals enter through `MainView.refreshVitals()`; the background writes the same `VitalsModel` storage keys, and `onBackgroundData` triggers a refresh when the app is open.

## Folders

| Path | Contents | Rule |
|---|---|---|
| `source/model` | state & rules | No `WatchUi` / `Graphics` → unit-tested |
| `source/services` | Toybox data access | Return plain values / snapshots; never enable sensors |
| `source/background` | `ServiceDelegate` | Must stay small (64 KB); no UI |
| `source/views` | views, glance, menus, pixel art | Draw only |
| `source/delegates` | input | Translate input into model calls |
| `source/utils` | `DayClock`, `Fmt`, `Log` | Stateless |
| `resources/strings` | all text; `scope="background"` / `scope="glance"` where needed | |
| `tests` | `(:test)` functions | Built only with `--unit-test` |

## Goal and XP (MonkeyModel)

| Rule | Value |
|---|---|
| Goal reached today (live) | +100 XP once per local day; celebration once |
| Finished day settled from 7-day history | met +100 (unless already rewarded), missed −50, no data → 0 |
| Revived from tiredness | +20 XP, max 3 per day |
| Finished breathing session | +10 XP, once per day |
| Level | 1 + XP / 300; XP never below 0 |
| Goal poses | < 50 % relax · 50–99 % perk · ≥ 100 % eat |

## Vitals (Vitals, VitalsModel)

All inputs are values the watch already records (no sensor is switched on for vitals):

| Input | Source |
|---|---|
| Move bar 0–5 (1 = 60 min still, +1 per 15 min) | `ActivityMonitor.Info.moveBarLevel` |
| Stress 0–100 | `ActivityMonitor.Info.stressScore`, `SensorHistory.getStressHistory` |
| Body Battery now / today's peak / 3 h gain | `SensorHistory.getBodyBatteryHistory` |
| Wrist HR (last ~6 min) | `ActivityMonitor.getHeartRateHistory` |
| Resting HR baseline, wake/sleep time | `UserProfile` (`averageRestingHeartRate`, `restingHeartRate`, `wakeTime`, `sleepTime`) |
| Cadence | steps delta between snapshots |

**Sleep is not readable by Connect IQ apps** (no API; open Garmin request). The spec's "sleep < 7 h" is therefore implemented as *low recharge*: today's Body Battery peak < 50, judged one hour after the user's wake time. A rest/nap that adds ≥ 10 Body Battery within 3 h clears it for the day.

### Energy

| State | Trigger | Monkey | Recommendation | Recovers when |
|---|---|---|---|---|
| Rested | none below | goal pose | — | — |
| Low recharge | Body Battery peak today < 50 | tired, yawning | "Ease in, bed early" | nap/rest gain ≥ 10, or tomorrow |
| Inactive | move bar ≥ 3 (~90 min still) | tired; asleep sitting at level 5 (~2 h) | "A 5-min walk helps" | Garmin clears the move bar (a few minutes of walking) |
| Exhausted | low recharge + inactive | asleep, takes over the face (black) | "Walk now, bed early" | either clears; full revive needs both |
| Night | outside wake–sleep window | asleep on night blue | "Quiet hours" | wake time |
| Revived (event) | any tired state → rested | stretch animation, "I'm back!" | +20 XP | — |

### Calm

| State | Trigger (movement cross-check: cadence ≥ 60 steps/min = moving) | Monkey | Recommendation | Recovers when |
|---|---|---|---|---|
| Calm | none below | goal pose | — | — |
| Alert | not moving and (stress ≥ 51 or HR ≥ 15 % over resting) | wide eyes, "!" | "START: 3 breaths" | stress ≤ 40 **and** HR ≤ 5 % (hysteresis) |
| Stressed | not moving and (stress ≥ 76 for ~5 min or HR > 25 % for ~5 min) | hands over ears, red tint | "START: breathe" → guided breathing | same as Alert; "Calm again" banner |
| Exercising | moving and HR ≥ 15 % over resting | jogging (2 frames) | "Good stress, go!" | activity ends |

Status priority: Exhausted > Night > Stressed > 2 h still > Inactive > Low recharge > Alert > Exercising > goal pose (`MonkeyStatus`).

### Guided breathing (BreathView)

Box breathing 4-4-4-4 × 4 rounds (~64 s). The ring and the monkey's chest follow the breath; live HR (the only place a sensor is enabled — `Sensor` permission, on in `onShow`, off in `onHide`) is shown as a number and sparkline; the summary shows HR start → end. Opened by START when Alert/Stressed, or from the menu.

## Reminders and battery

`Reminders.sync()` registers `Background.registerForTemporalEvent(30 min)`; the menu toggle removes it.

- **Why 30 min, not 15:** the move bar only changes every 15 min and the thresholds are 90/120 min, so 15-min checks would double the wake-ups (~96/day) for little gain. Each wake-up reads a few history buffers (~ms of CPU) — no GPS, no HR sensor, no radio. Change `Reminders.INTERVAL_SEC` (system minimum is 5 min).
- **When a nudge is sent** (`VitalsModel.pickNudge`): reminders on, user awake (profile wake–sleep window), ≤ 6 per day, ≥ 45 min between any two, same kind again only after 2 h, low recharge and the midday goal reminder (after 13:00, < 50 %) once per day. Priority: Exhausted > Stressed > Inactive > Low recharge > Goal.
- **Delivery:** `Background.requestApplicationWake(message)` — the watch vibrates and asks to open the app. (`Notifications.showNotification` is API 5.1+ but not listed for the fēnix 7 Pro in the SDK sample, so it is not used.)
- **No repeats:** while the dashboard is visible the app writes `fgSeen`, and `markSeen()` counts visible conditions as already nudged.
- **App timers:** 60 s goal refresh, vitals every 5 min, 100 ms only during 2–3 s animations, 400 ms only while the jogging animation is on screen; all stopped in `onHide`.

## Glance

`MonkeyGlance` shows "Monkey Miles Lv N", the current status title (from stored `vState` of today) or the goal counter, and a progress bar. It reads Storage and `ActivityMonitor` only.

## Pixel art

`MonkeyArt` holds sprites as strings (`K` outline, `B` fur, `T` tan, `Y`/`G` banana …): one shared body plus small patches per pose (relax, perk, eat, tired, asleep, alert, stressed, jog ×2, stretch, breathe). `PixelSprite.compile()` packs horizontal runs into one `Number` each. **Compile the body once and poses lazily** — compiling all poses in one `onLayout` trips the watchdog ("Code Executed Too Long").

## Expansion vitals (not built)

| Vital | fēnix 7 Pro data | Feasible? | Notes |
|---|---|---|---|
| **Breath** (Pulse Ox) | `SensorHistory.getOxygenSaturationHistory` (only when the user enabled Pulse Ox) | Read-only yes | Apps cannot trigger a measurement, so "recheck in 2 min" is not possible; use the next stored reading. Copy must stay non-diagnostic ("take a few slow breaths; if it stays low, check in with someone"). |
| **Warmth** (temperature) | `SensorHistory.getTemperatureHistory` | Partly | The sensor sits on the wrist: body heat skews ambient readings unless the watch is off-wrist. Indoor/outdoor inference needs GPS (battery-heavy) — not recommended for a background check. |
| **Curiosity** (GPS + barometer + compass) | `Position`, `SensorHistory.getElevationHistory`, `ActivityMonitor.Info.floorsClimbed` | Partly | Route novelty needs GPS tracks; the app cannot read other activities' tracks. Cheap version: new elevation/floors milestones and weekly distance as "new territory" rewards. |
| **Sleep** | none | No (on-watch) | Garmin cloud Health API only (server + partner approval). Body Battery recharge is the proxy. |

## Development safeguards

- **Null safety:** most Toybox readings are nullable (`info.steps`, `stressScore`, history samples, profile fields). Invalid stress/Body Battery values are filtered (`VitalsService.validPct`).
- **Storage:** `MonkeyModel` and `VitalsModel` only write after `load()` — unit tests never touch real storage. Background writes are allowed on CIQ ≥ 3.2.
- **Watchdog:** keep per-event work small (lazy sprite compile, bounded history windows).
- **Memory:** app ~45 KB of 768 KB, glance ~15 KB of 64 KB in the simulator.
- **Logging:** `Log.debug()` only in the app context; nothing logged in background or glance.
