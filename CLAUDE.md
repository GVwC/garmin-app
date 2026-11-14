# CLAUDE.md

**Follow [AGENTS.md](AGENTS.md) — it holds the binding rules, commands and conventions.** This file adds Claude-specific context only.

## Snapshot

- Garmin Connect IQ **watch-app** in Monkey C, starter/baseline for future apps.
- Target device: `fenix7pro` (fēnix 7 Pro, 260×260 round MIP, 8 bpp, touch + 5 buttons), API 5.2.0, SDK 9.1.0 (active SDK read from `%APPDATA%\Garmin\ConnectIQ\current-sdk.cfg`).
- OS: Windows 11. Use the PowerShell tool for `scripts\ciq.ps1`.

## Layout

```
manifest.xml          app id, type, products, permissions (edit via "Monkey C: Edit ..." commands)
monkey.jungle         build config; sourcePath = source;tests
source/StarterApp.mc  AppBase entry; owns StarterModel
source/views/         WatchUi.View subclasses (drawing only)
source/delegates/     input handling (BehaviorDelegate)
source/model/         plain state/logic, unit-testable
source/utils/Log.mc   Log.debug() — (:debug) only
resources/            strings, drawables (launcher icon 40×40)
tests/                (:test) functions, built only with --unit-test
scripts/ciq.ps1       build | test | run | sim | package | clean
docs/                 SETUP, ARCHITECTURE, DEVELOPMENT, API_COMPATIBILITY, NEW_APP_CHECKLIST
```

## Workflow for every change

1. Look up any Toybox API you use in the official docs (or `<SDK>/bin/api.debug.xml`) and confirm it exists at API ≤ 5.2.0.
2. Edit the smallest set of files.
3. `.\scripts\ciq.ps1 build` → must print `BUILD SUCCESSFUL` with no new warnings.
4. `.\scripts\ciq.ps1 test` → must end with `PASSED (passed=N, failed=0, errors=0)`.
5. For UI changes, `.\scripts\ciq.ps1 run` and inspect the simulator; console output from `Log.debug` appears in the terminal.
6. Report results as Passed / Failed / Not attempted / Requires physical hardware.

## Known limitations

- `ciq.ps1 run` keeps streaming simulator output until the app exits; run it in the background if you need to keep working.
- The simulator can't verify real battery drain, sensor accuracy, GPS, or exact on-device memory/performance — say so.
- Simulator UI (button clicks) can't be scripted reliably; button logic is covered by testing model methods plus manual simulator checks.
- Never read or print the developer key; `ciq.ps1` resolves it from `$env:CIQ_DEVELOPER_KEY` or VS Code user settings.
