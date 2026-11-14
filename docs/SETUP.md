# Setup

Audited 2026-11-13 on Windows 11 Pro (10.0.26200). Nothing was reinstalled; no global settings were changed.

| Component | Found | Status |
|---|---|---|
| VS Code | `%LOCALAPPDATA%\Programs\Microsoft VS Code` | OK |
| Garmin Monkey C extension | `garmin.monkey-c` 1.1.3 | OK |
| Java | Eclipse Temurin OpenJDK 11.0.28 | OK — compiler runs |
| Connect IQ SDK | 9.1.0 (`connectiq-sdk-win-9.1.0-2026-03-09-6a872a80b`) — only SDK installed | Active (`%APPDATA%\Garmin\ConnectIQ\current-sdk.cfg`) |
| SDK Manager | `%USERPROFILE%\Downloads\connectiq-sdk-manager-windows\sdkmanager.exe` | Present |
| Device `fenix7pro` | `%APPDATA%\Garmin\ConnectIQ\Devices\fenix7pro` (also `fenix7pronowifi`) | OK |
| Simulator | `<SDK>\bin\simulator.exe` | Launches, runs app |
| Compiler | `<SDK>\bin\monkeyc.bat` | `BUILD SUCCESSFUL` |
| Developer key | set in VS Code user setting `monkeyC.developerKeyPath` | Present (not displayed) |
| Git | 2.52.0 | OK |

## Recommendations (not done automatically)

- **Move the developer key out of Downloads** to a stable, backed-up location (e.g. `%USERPROFILE%\.garmin\developer_key`), then update `monkeyC.developerKeyPath` in VS Code user settings. Losing this key means you can't update store apps signed with it. Back it up privately; never commit it.
- Optionally move `sdkmanager.exe` out of Downloads too (then re-open it once so it updates `sdkmanager-location.cfg`).

## macOS

Verified 2026-11-14 on macOS 15 (Darwin 24.6), Apple silicon.

| Component | Found | Status |
|---|---|---|
| Connect IQ SDK | 9.1.0 (`connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b`) | Active (`~/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg`) |
| Device `fenix7pro` | `~/Library/Application Support/Garmin/ConnectIQ/Devices/fenix7pro` | OK |
| Java | Homebrew `openjdk@17` (keg-only, `/opt/homebrew/opt/openjdk@17`) | OK — `ciq.sh` finds it without PATH changes |
| Simulator | `<SDK>/bin/ConnectIQ.app` | Launches, runs app and tests |
| Developer key | VS Code user setting `monkeyC.developerKeyPath` | Present (not displayed) |

Set up a new Mac: install the SDK + fēnix 7 Pro device with the SDK Manager, then `brew install openjdk@17`, then `./scripts/ciq.sh test`. In VS Code also set `monkeyC.javaPath` to `/opt/homebrew/opt/openjdk@17` if the extension can't find Java.

## Repairing the environment

- **SDK / devices missing or outdated:** VS Code → "Monkey C: Open SDK Manager" → download SDK and the fēnix 7 Pro device → "Use this SDK".
- **Check everything:** VS Code → "Monkey C: Verify Installation".
- **No developer key:** VS Code → "Monkey C: Generate a Developer Key" (only if you don't already have one — a new key can't update apps signed with the old one).
- **Java:** the SDK needs a Java runtime; `monkeyC.javaPath` can point to a specific JDK if needed.

Official guide: https://developer.garmin.com/connect-iq/sdk/
