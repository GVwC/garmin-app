# AGENTS.md — rules for AI coding assistants

This is a Garmin Connect IQ project in Monkey C. Target: **fēnix 7 Pro** (product id `fenix7pro`), Connect IQ API **5.2.0**, SDK **9.1.0**, Windows or macOS.
Read [docs/API_COMPATIBILITY.md](docs/API_COMPATIBILITY.md) for device facts and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for code layout.

## Rules

1. **Target the fēnix 7 Pro.** Only use APIs available at Connect IQ 5.2.0 on `fenix7pro`. Check `minApiLevel`/"Since" in the API docs.
2. **Prefer official Garmin documentation**: https://developer.garmin.com/connect-iq/api-docs/ and the SDK's local docs (`<SDK>/doc`). Sample code in `<SDK>/samples` is authoritative for usage patterns.
3. **Never invent Monkey C or Toybox classes, methods, constants, manifest keys, jungle keys or compiler flags.** If unsure, look it up or say so. The compiler (strict type-check) is the final arbiter.
4. **Don't assume an API exists because newer watches have it** (e.g. fēnix 8 / API 5.x+ features). When an API is optional per device, guard with `has` (`if (Toybox has :SensorHistory)`, `if (obj has :method)`).
5. **Keep memory low.** Watch-app limit on this device is ~768 KB; glances/background are 64 KB. Load resources once (`onLayout`/`onShow`), release them in `onHide`, avoid large arrays/dictionaries and string building in `onUpdate`.
6. **Minimize battery use.** No timers faster than needed, stop timers/sensors in `onHide`/`onStop`, request sensors only while the screen needs them, no polling loops.
7. **Avoid unnecessary dependencies** (barrels, web requests, permissions). Add a permission only when the feature needs it.
8. **Keep logic modular.** UI in `source/views`, input in `source/delegates`, state/logic in `source/model` (no `WatchUi`/`Graphics` there), Toybox data access in `source/services`, the background service in `source/background`, helpers in `source/utils`.
9. **Compile after every change:** `.\scripts\ciq.ps1 build` (warnings on, strict type-check). Treat new warnings as errors to fix.
10. **Run simulator checks whenever possible:** `.\scripts\ciq.ps1 test` (unit tests) and `.\scripts\ciq.ps1 run` (smoke test). Report each check as Passed / Failed / Not attempted / Requires physical hardware — never claim a check passed if it didn't run.
11. **Flag unverified hardware behaviour** (sensors, GPS, battery, button feel, touch, backlight, real memory) explicitly — the simulator does not prove it.
12. **Preserve a working baseline.** Don't leave the project in a non-compiling state; make one coherent change at a time and commit working states (only when asked).
13. **Never touch signing keys or publish.** Don't read, print, move, regenerate or commit `developer_key*`/`*.der`. Don't run `package`, upload to the Connect IQ Store, change the app UUID, or push to remotes without explicit permission.
14. **Prefer small, testable changes.** Put testable logic in plain classes and add a `(:test)` function in `tests/` for it.
15. **Update docs when architecture changes** (ARCHITECTURE.md, this file's paths, CLAUDE.md commands).

## Commands (from repo root)

Windows uses PowerShell `.\scripts\ciq.ps1 <task>`; macOS/Linux use bash `./scripts/ciq.sh <task>`. Same tasks, same flags. Rules above that say `ciq.ps1` mean whichever script fits your OS.

| Task | Windows | macOS / Linux |
|---|---|---|
| Compile (debug, fenix7pro) | `.\scripts\ciq.ps1 build` | `./scripts/ciq.sh build` |
| Unit tests in simulator | `.\scripts\ciq.ps1 test` | `./scripts/ciq.sh test` |
| Build + launch in simulator | `.\scripts\ciq.ps1 run` | `./scripts/ciq.sh run` |
| Start simulator only | `.\scripts\ciq.ps1 sim` | `./scripts/ciq.sh sim` |
| Clean | `.\scripts\ciq.ps1 clean` | `./scripts/ciq.sh clean` |

VS Code equivalents: F5 (Run App / Run Tests in `.vscode/launch.json`), command palette "Monkey C: Build Current Project".

## Code conventions

- Explicit types on members, parameters and returns (`as Number`, `as String?`); strict type-check must pass.
- Nullable values: declare `as Type?`, check `!= null` before use, never cast away null without a check.
- Logging: `Log.debug("...")` (stripped from release builds). No `System.println` elsewhere.
- Redraw only via `WatchUi.requestUpdate()` after a state change; never on a tight timer.
- User-facing text lives in `resources/strings/strings.xml`.

## Git

- Commit messages: **one line, [Conventional Commits](https://www.conventionalcommits.org/)** — `type(scope): summary`, e.g. `feat(view): show heart rate on main screen`.
- No body, no trailers: no `Co-Authored-By`, no "Generated with …", no AI attribution in commits or PR descriptions.
- Small commits on short-lived branches (`feat/<thing>`), merge to `main` often; `main` must always build.
