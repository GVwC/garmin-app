# garmin-connectiq-starter

A small, reusable Connect IQ **watch-app** baseline for the Garmin **fēnix 7 Pro** (API 5.2.0, SDK 9.1.0).
It shows "Garmin Starter / Ready to Build", counts START presses (or screen taps), and exits on BACK.

## Quick start

**VS Code:** open this folder → press **F5** → pick **Run App (fenix 7 Pro)**. The simulator opens and the app launches.

**Terminal (PowerShell):**

```powershell
.\scripts\ciq.ps1 build   # compile for fenix7pro
.\scripts\ciq.ps1 test    # unit tests in the simulator
.\scripts\ciq.ps1 run     # build + launch in the simulator
```

## Docs

| File | What it covers |
|---|---|
| [QUICKSTART.md](QUICKSTART.md) | Copy-paste commands / VS Code clicks |
| [docs/SETUP.md](docs/SETUP.md) | Tooling that's installed, how it was verified, how to repair it |
| [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) | Build / run / debug / logs / tests / sideloading |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Code layout and development safeguards |
| [docs/API_COMPATIBILITY.md](docs/API_COMPATIBILITY.md) | fēnix 7 Pro facts and API guarding |
| [docs/NEW_APP_CHECKLIST.md](docs/NEW_APP_CHECKLIST.md) | Turning this starter into a real app |
| [AGENTS.md](AGENTS.md) / [CLAUDE.md](CLAUDE.md) | Rules for AI assistants |
