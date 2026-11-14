# Development workflow

Commands below use the Windows script; on macOS/Linux replace `.\scripts\ciq.ps1` with `./scripts/ciq.sh` (same tasks).

## Build

- VS Code: command palette → **Monkey C: Build Current Project** (output in `bin/`). Errors and warnings appear in the Problems panel.
- Terminal: `.\scripts\ciq.ps1 build` → `bin\GarminStarter.prg`. Uses `-w` (warnings) and `-l 3` (strict type-check), same strictness as `.vscode/settings.json`.

## Run in the simulator

- VS Code: **F5** → *Run App (fenix 7 Pro)*. The extension starts the simulator if needed.
- Terminal: `.\scripts\ciq.ps1 run` (starts `simulator.exe` if not running, then `monkeydo`).
- Simulator only: `.\scripts\ciq.ps1 sim`, or run `<SDK>\bin\simulator.exe`.

**Restart quickly:** press F5 again (or Ctrl+Shift+F5 while debugging); the simulator stays open and the app is reloaded. From a terminal, re-run `ciq.ps1 run`.

## Interacting

On the simulated watch, click the physical buttons on the image or the screen:

| Watch input | Behaviour (BehaviorDelegate) | Monkey Miles action |
|---|---|---|
| START (top right) / tap screen | `onSelect` | goal picker |
| BACK (bottom right) / swipe right | `onBack` | leave demo, else exit app |
| UP / DOWN (left) / swipe | `onPreviousPage` / `onNextPage` | DOWN: next demo stage |
| Hold UP | `onMenu` | menu: goal, demo mode |

## Debugging

- Set breakpoints in `.mc` files and press F5 — the extension's `monkeyc` debugger supports breakpoints, stepping and variable inspection. Set `"stopAtLaunch": true` in `launch.json` to break at start.
- **Logs:** `Log.debug(...)` → `System.println`, shown in the VS Code Debug Console (or the terminal for `ciq.ps1 run`). Stripped from release builds.
- **Memory:** the simulator status bar shows current/limit memory (`7.1/763.6kB` for the starter). *File → View Memory* gives a breakdown.
- **Crashes:** the simulator shows the crash screen and the console prints the error with a stack trace.
- On a real watch: create `GARMIN\APPS\LOGS\<PRG-NAME>.TXT` (e.g. `GARMINSTARTER.TXT`) on the device to capture `println` output; crashes are written to `GARMIN\APPS\LOGS\CIQ_LOG.YML`.

## Unit tests

- `tests/*.mc` contain `(:test)` functions; they're compiled only with `--unit-test`.
- VS Code: F5 → *Run Tests (fenix 7 Pro)*, or the Test Explorer.
- Terminal: `.\scripts\ciq.ps1 test` — fails unless the summary is `PASSED (... failed=0, errors=0)`.
- Assertions: `Test.assert`, `Test.assertEqual`, `Test.assertMessage`, `Test.assertEqualMessage`, `Test.assertNotEqual`.

## Sideloading to the real watch

1. `.\scripts\ciq.ps1 build` (or VS Code "Monkey C: Build for Device" → fenix7pro).
2. Connect the watch by USB; it appears as a drive (MTP on Windows).
3. Copy `bin\GarminStarter.prg` to `GARMIN\APPS\` on the watch.
4. Disconnect; open the app from the watch's app list.

## Release (only when you decide to publish)

`.\scripts\ciq.ps1 package` (or "Monkey C: Export Project") creates a signed `.iq` for the Connect IQ Store. Change the app UUID, name and icon first (see NEW_APP_CHECKLIST.md).
