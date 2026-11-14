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

## Character, goals and XP (MonkeyModel)

First launch (`createDashboard`): onboarding instead of the dashboard — `WelcomeView` (egg) → name menu → `FurPickerView` (egg spots preview the fur) → goals (`goalsMenu` with "Done") → `HatchView` → `openDashboard()`. *New game* clears storage and returns to the egg (`startOnboarding`). Growth stages (`Growth`): egg → baby (×3 scale) → kid (leaf, Lv 3) → adult (headband, Lv 6) → king (crown, Lv 10); crossing a stage plays the evolution animation.

Full-screen moments (`StoryScreens.mc`): `ReminderView` (buzz + shaking monkey; also opened when the app is launched from a background reminder via the `pendingNudge` key), `RecapView` (missed day: XP drain, streak out), `JourneyView` (story: egg → king with scripted weekly steps; live: current stage + last 7 days). Story mode (`DemoScenarios`) pushes them on scene entry. The same menus are reachable later (Hold UP → Character / Goals, START → Goals). Players from the single-goal version are migrated (their goal becomes the only enabled one, the character counts as created).

Goals: Steps / Active minutes / Floors, each on/off with its own target (at least one stays on). One goal is *shown* on the counter (UP/DOWN cycles); chips under the XP bar show every enabled goal (yellow = met, outlined = shown). The pose uses all goals: eat when every goal is met, perk up at ≥ 50 % average progress.

| Rule | Value |
|---|---|
| Each enabled goal reached today (live) | +100 XP once per local day; celebration once (several goals add up in one banner) |
| Finished day settled from 7-day history | per enabled goal: met +100 (unless already rewarded), missed −50, no data → 0 |
| Streak | consecutive days with every enabled goal met; completing today on day 2+ adds +10 × days (max ×5) |
| Revived from tiredness | +20 XP, max 3 per day |
| Finished breathing session | +10 XP, once per day |
| New territory (Curiosity) | +30 XP, once per day |
| Level | 1 + XP / 300; XP never below 0 |
| Evolution | leaf from level 3, headband from 6, crown from 10 (accessory patches drawn over any pose) |
| Fur | Brown / Golden / Silver / Shadow: swaps the `B` and `D` palette entries |

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
| Pulse Ox (awake, last 4 h) | `SensorHistory.getOxygenSaturationHistory` |
| Temperature (last 15 min) | `SensorHistory.getTemperatureHistory` |
| Distance / floors, 7 days | `ActivityMonitor.getInfo()`, `getHistory()` (app only) |

**Sleep data on this target.** The fēnix 7 Pro runs Connect IQ API 5.2.0 and the installed SDK 9.1.0 exposes no sleep data to apps: no sleep duration, stages or score, and no `COMPLICATION_TYPE_SLEEP_SCORE` in its API (checked in `api.debug.xml`). A sleep-score complication is reported for API 6.0.2 on newer devices; that was not verifiable here and does not apply to this watch either way. The app therefore never claims anything about sleep length or quality: it shows **low morning recharge**, today's Body Battery peak < 50, judged one hour after the user's wake time, and only when the newest Body Battery sample is at most 2 h old (missing or stale history never triggers it). A rest/nap that adds ≥ 10 Body Battery within 3 h clears it for the day.

### Energy

| State | Trigger | Monkey | Recommendation | Recovers when |
|---|---|---|---|---|
| Rested | none below | goal pose | — | — |
| Low morning recharge | Body Battery peak today < 50 (fresh history only) | tired, yawning | "Ease in, bed early" | nap/rest gain ≥ 10, or tomorrow |
| Inactive | move bar ≥ 3 (~90 min still) | tired; asleep sitting at level 5 (~2 h) | "A 5-min walk helps" | Garmin clears the move bar (a few minutes of walking) |
| Exhausted | low morning recharge + inactive | asleep, takes over the face (black) | "Walk now, bed early" | either clears; full revive needs both |
| Night | outside wake–sleep window | asleep on night blue | "Quiet hours" | wake time |
| Revived (event) | any tired state → rested | stretch animation, "I'm back!" | +20 XP | — |

### Calm

| State | Trigger (movement cross-check: cadence ≥ 60 steps/min = moving) | Monkey | Recommendation | Recovers when |
|---|---|---|---|---|
| Calm | none below | goal pose | — | — |
| Alert | not moving and (stress ≥ 51 or HR ≥ 15 % over resting) | wide eyes, "!" | "START: 3 breaths" | stress ≤ 40 **and** HR ≤ 5 % (hysteresis) |
| Stressed | not moving and (stress ≥ 76 for ~5 min or HR > 25 % for ~5 min) | hands over ears, red tint | "START: breathe" → guided breathing | same as Alert; "Calm again" banner |
| Exercising | moving and HR ≥ 15 % over resting | jogging (2 frames) | "Good stress, go!" | activity ends |

Status priority (`MonkeyStatus`): Breath concerning > Exhausted > Night > Stressed > Cold > Hot > Breath low > 2 h still > Inactive > Low recharge > Alert > Exercising > Adventurous > Routine > goal pose.

### Guided breathing (BreathView)

Box breathing 4-4-4-4 × 2 rounds (~32 s; 1 round in story mode); START or a tap skips to the end (XP only after a full round). The ring and the monkey's chest follow the breath; live HR (the only place a sensor is enabled — `Sensor` permission, on in `onShow`, off in `onHide`) is shown as a number and sparkline; the summary shows HR start → end. Opened by START when Alert/Stressed, or from the menu.

## Reminders and battery

`Reminders.sync()` registers `Background.registerForTemporalEvent(30 min)`; the menu toggle removes it.

- **Why 30 min, not 15:** the move bar only changes every 15 min and the thresholds are 90/120 min, so 15-min checks would double the wake-ups (~96/day) for little gain. Each wake-up reads a few history buffers (~ms of CPU) — no GPS, no HR sensor, no radio. Change `Reminders.INTERVAL_SEC` (system minimum is 5 min).
- **When a nudge is sent** (`VitalsModel.pickNudge`): reminders on, user awake (profile wake–sleep window), ≤ 6 per day, ≥ 45 min between any two, same kind again only after 2 h, low recharge and the midday goal reminder (after 13:00, < 50 %) once per day. Priority: Breath concerning > Exhausted > Stressed > Cold > Hot > Inactive > Low recharge > Goal.
- **Delivery:** `Background.requestApplicationWake(message)` — the watch vibrates and asks to open the app. (`Notifications.showNotification` is API 5.1+ but not listed for the fēnix 7 Pro in the SDK sample, so it is not used.)
- **No repeats:** while the dashboard is visible the app writes `fgSeen`, and `markSeen()` counts visible conditions as already nudged.
- **App timers:** 60 s goal refresh, vitals every 5 min, 100 ms only during 2–3 s animations, 400 ms only while the jogging animation is on screen; all stopped in `onHide`.

## Glance

`MonkeyGlance` shows "Monkey Miles Lv N", the current status title (from stored `vState` of today) or the goal counter, and a progress bar. It reads Storage and `ActivityMonitor` only.

## Pixel art

`MonkeyArt` holds sprites as strings (`K` outline, `B` fur, `T` tan, `Y`/`G` banana, `C` ice …): one shared body plus small patches per pose (relax, perk, eat, tired, asleep, alert, stressed, jog ×2, stretch, breathe, pant, cold, hot, climb, bored). `PixelSprite.compile()` packs horizontal runs into one `Number` each. **Compile the body once and poses lazily** — compiling all poses in one `onLayout` trips the watchdog ("Code Executed Too Long").

### Breath (Pulse Ox, read-only)

| State | Trigger | Monkey | Recommendation | Recovers when |
|---|---|---|---|---|
| Normal | latest awake reading ≥ 95 % or no data | goal pose | — | — |
| Low | one reading 90–94 % | panting, sweat drop | "START: slow breaths" | next reading ≥ 95 % |
| Concerning | < 90 %, or low on 2+ readings in a row | panting, teal tint | "Lasts? Ask someone" + background reminder | a later reading ≥ 95 % |

Readings come from `SensorHistory.getOxygenSaturationHistory` (only exists if the user enabled Pulse Ox), awake hours only (SpO2 is normally lower asleep). Apps cannot start a measurement, so the spec's "recheck in 2 min" is the next stored reading. Copy never diagnoses: "Sit down and take slow breaths; if it continues, check in with someone."

### Warmth (watch temperature)

| State | Trigger | Monkey | Recommendation |
|---|---|---|---|
| OK | default | goal pose | — |
| Cold | every reading of the last 15 min < 10 °C | shivering, snowflakes, ice-blue tint | "Head somewhere warm" |
| Hot | reading ≥ 35 °C and HR ≥ 15 % over resting without movement | fanning with a leaf, sun | "Water and shade" |

The sensor is on the wrist and reads several degrees above the air, so thresholds are deliberately conservative (only real cold pulls the wrist sensor under 10 °C). No GPS indoor/outdoor inference (battery).

### Curiosity (daily distance / floors, no GPS)

| State | Trigger | Monkey | Reward / text |
|---|---|---|---|
| Content | default | goal pose | — |
| Routine | last 3 days within ±15 % distance and ≤ 2 floors each | bored, chin on hand | "New direction today?" |
| Adventurous | today beats the 7-day best distance (≥ 3 km) or floors (≥ 5) | plants a flag | +30 XP once per day, "New territory!" |

Route novelty and compass bearings would need GPS tracks of other activities, which apps cannot read; the distance/floors version keeps the "discovery" idea at zero battery cost.

### Sleep

Not readable on this watch (API 5.2.0, SDK 9.1.0: no sleep duration, stages, score or sleep-score complication). A sleep-score complication is reported for API 6.0.2 on newer devices (not verified here). Real sleep data otherwise only via Garmin's cloud Health API (server + partner approval). The app uses *low morning recharge* from Body Battery instead and never labels it as sleep.

## Development safeguards

- **Null safety:** most Toybox readings are nullable (`info.steps`, `stressScore`, history samples, profile fields). Invalid stress/Body Battery values are filtered (`VitalsService.validPct`).
- **Storage:** `MonkeyModel` and `VitalsModel` only write after `load()` — unit tests never touch real storage. Background writes are allowed on CIQ ≥ 3.2.
- **Watchdog:** keep per-event work small (lazy sprite compile, bounded history windows).
- **Memory:** app ~45 KB of 768 KB, glance ~15 KB of 64 KB in the simulator.
- **Logging:** `Log.debug()` only in the app context; nothing logged in background or glance.
