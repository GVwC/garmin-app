# Monkey Miles

A Garmin Connect IQ **watch-app** for the **fēnix 7 Pro** (API 5.2.0, SDK 9.1.0).
A short walk feeds your pixel-art monkey: it grows its banana as you move, eats it and bounces when you hit your daily goal, and you earn XP and levels. Miss a day and you lose a little XP.

> Hackathon demo. The climbing-clock example that used to live here is kept on the `demo/climbing-clock` branch.

## What it does

- **One daily goal** that feeds the monkey: **Steps** (1,000 / 3,000 / **5,000** / 10,000), **Active minutes** (10 / 20 / 30 / 60) or **Floors** (5 / 10 / 15 / 25). Saved on the watch.
- **Real data** from Garmin's daily totals (`ActivityMonitor`, resets at local midnight). Refreshed when the app opens/returns and every 60 s while visible. No reading → "Steps unavailable".
- **Monkey poses**
  - below 50 %: relaxed, green banana on the ground
  - 50 % to just below the goal: perks up, holds a yellow banana
  - goal reached: eats the banana with a short victory bounce — once per day in live mode; the completed pose stays.
- **XP**: goal reached **+100 XP** (once per day). Days you didn't open the app are settled from the watch's 7-day history: met **+100**, missed **−50**. XP never goes below 0. Every 300 XP is a level.
- **DEMO mode** (from the menu): DOWN cycles 20 % → 65 % → 100 % (+XP, celebration) → missed day (−XP). Starts fresh each time, uses a copy of your XP and never saves anything. BACK returns to real data. The app always launches in live mode.

## Controls (fēnix 7 Pro)

| Button | Live | Demo |
|---|---|---|
| **START** (or tap) | Choose goal → target | Choose goal |
| **Hold UP** (menu) | Menu: Goal, Demo mode | Menu: Goal, Demo mode (off) |
| **DOWN** | — | Next demo stage |
| **BACK** | Exit app | Leave demo |

## Build and run

**VS Code:** open this folder → **F5** → **Run App (fenix 7 Pro)**.

**Windows (PowerShell):**

```powershell
.\scripts\ciq.ps1 build   # compile -> bin\GarminStarter.prg
.\scripts\ciq.ps1 test    # unit tests in the simulator
.\scripts\ciq.ps1 run     # build + launch in the simulator
```

**macOS / Linux:**

```bash
./scripts/ciq.sh build
./scripts/ciq.sh test
./scripts/ciq.sh run
```

In the simulator, click the buttons on the watch image. Step/floor/active-minute values come from the simulator's activity data (Simulation menu); to start from a clean slate use the simulator's option to reset app data.

## Install on a watch

1. `.\scripts\ciq.ps1 build` (needs your developer key, see [docs/SETUP.md](docs/SETUP.md)).
2. Connect the fēnix 7 Pro by USB; it shows up as a drive.
3. Copy `bin\GarminStarter.prg` into `GARMIN\APPS\` on the watch.
4. Disconnect and open **Monkey Miles** from the app list.

## Docs

| File | What it covers |
|---|---|
| [QUICKSTART.md](QUICKSTART.md) | Copy-paste commands / VS Code clicks |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Code layout, XP rules, data sources, roadmap (sleep, reminders) |
| [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) | Build / run / debug / logs / tests / sideloading |
| [docs/SETUP.md](docs/SETUP.md) | Tooling and how to repair it |
| [docs/API_COMPATIBILITY.md](docs/API_COMPATIBILITY.md) | fēnix 7 Pro facts and API guarding |
| [docs/NEW_APP_CHECKLIST.md](docs/NEW_APP_CHECKLIST.md) | Turning a copy of this into a new app |
| [AGENTS.md](AGENTS.md) / [CLAUDE.md](CLAUDE.md) | Rules for AI assistants |
