# Monkey Miles

A Garmin Connect IQ **watch-app** for the **fēnix 7 Pro** (API 5.2.0, SDK 9.1.0).
A pixel-art monkey companion that lives on your real watch data: it eats its banana when you hit your daily goal, gets tired when you sit too long or slept badly, gets stressed when your heart rate climbs without movement, and nudges you — with a recovery check, not just a notification.

> The climbing-clock example that used to live here is kept on the `demo/climbing-clock` branch.

## Features

- **Daily goal** feeding the monkey: Steps (1k / 3k / **5k** / 10k), Active minutes (10 / 20 / 30 / 60) or Floors (5 / 10 / 15 / 25). Garmin's midnight-reset totals.
- **XP and levels:** goal +100, missed day −50 (settled from the 7-day history even if the app wasn't opened), revived +20 (max 3/day), breathing session +10 (1/day). 300 XP per level.
- **Energy vital** (move bar + Body Battery): Rested · Low recharge · Inactive (~90 min still) · Exhausted · Night — with "Revived" when you recover.
- **Calm vital** (Garmin stress + wrist HR vs resting HR, cross-checked with cadence so workouts are never stress): Calm · Alert · Stressed · Exercising.
- **Breath vital** (Pulse Ox history, read-only, non-diagnostic): Normal · Low · Concerning.
- **Warmth vital** (watch temperature, conservative for wrist bias): OK · Cold · Hot.
- **Curiosity vital** (distance/floors vs your week): Content · Routine · Adventurous (+30 XP "new territory").
- **Guided breathing:** box breathing (~1 min) with an animated ring, the monkey breathing along and live heart rate.
- **Reminders:** a background check every 30 min (no sensors, history only) with quiet hours, cooldowns and a daily cap; asks you to open the app when the monkey needs you.
- **Glance:** status or goal progress in the widget list.
- **DEMO mode:** 18 scripted scenarios covering every state, never saved.

Details, thresholds and the battery rationale: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Controls (fēnix 7 Pro)

| Button | Dashboard | Demo | Breathing |
|---|---|---|---|
| **START** (or tap) | Goal picker — or **Breathe** when stressed/alert | same | Restart when finished |
| **Hold UP** (menu) | Goal · Breathe · Reminders on/off · Demo mode | same | — |
| **UP / DOWN** | — | Previous / next scenario | — |
| **BACK** | Exit app | Leave demo | Back to dashboard |

Demo scenarios: goal 20 % → 65 % → reached (+XP, bounce) → missed day (−XP) → still 90 min → still 2 h → low recharge → exhausted → alert → stressed → exercising → breath low → breath low again → cold → hot → adventurous (+XP) → routine → revived (+XP).

## Build and run

**VS Code:** open this folder → **F5** → **Run App (fenix 7 Pro)**.

```powershell
.\scripts\ciq.ps1 build   # compile -> bin\GarminStarter.prg
.\scripts\ciq.ps1 test    # unit tests in the simulator
.\scripts\ciq.ps1 run     # build + launch in the simulator
```

macOS / Linux: `./scripts/ciq.sh build | test | run`.

Simulator tips:
- The simulator opens the **glance** first for apps that have one; open the app from there (START / tap).
- Vitals use the simulator's sensor history and activity data (Simulation menu). Trigger the background check with the simulator's background-event option.
- Reset app data in the simulator for a clean XP slate.

## Install on a watch

1. `.\scripts\ciq.ps1 build` (needs your developer key, see [docs/SETUP.md](docs/SETUP.md)).
2. Connect the fēnix 7 Pro by USB; it shows up as a drive.
3. Copy `bin\GarminStarter.prg` into `GARMIN\APPS\` on the watch.
4. Disconnect and open **Monkey Miles** from the app list. Accept the permissions (background, sensor, sensor history, user profile).

## Permissions

| Permission | Why |
|---|---|
| Background | 30-min vitals check and reminders |
| SensorHistory | Body Battery, stress, Pulse Ox and temperature history |
| UserProfile | resting HR, wake/sleep time (quiet hours) |
| Sensor | live heart rate during the breathing session only |

## Docs

| File | What it covers |
|---|---|
| [QUICKSTART.md](QUICKSTART.md) | Copy-paste commands / VS Code clicks |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Contexts, state machines, XP, reminders, battery, roadmap vitals |
| [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) | Build / run / debug / logs / tests / sideloading |
| [docs/SETUP.md](docs/SETUP.md) | Tooling and how to repair it |
| [docs/API_COMPATIBILITY.md](docs/API_COMPATIBILITY.md) | fēnix 7 Pro facts and API guarding |
| [docs/NEW_APP_CHECKLIST.md](docs/NEW_APP_CHECKLIST.md) | Turning a copy of this into a new app |
| [AGENTS.md](AGENTS.md) / [CLAUDE.md](CLAUDE.md) | Rules for AI assistants |
