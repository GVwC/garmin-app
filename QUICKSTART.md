# Quickstart — copy & paste

## First time (teammates)

```powershell
cd C:\projects
git clone https://github.com/GVwC/garmin-app.git
```

Then once per machine: install VS Code + the **Monkey C** extension, then `Ctrl+Shift+P` → **Monkey C: Verify Installation** (installs SDK via SDK Manager, needs a Garmin account) → in SDK Manager download SDK **9.1.0** and the **fēnix 7 Pro** device → `Ctrl+Shift+P` → **Monkey C: Generate a Developer Key** (your own key, never commit it). Details: [docs/SETUP.md](docs/SETUP.md).

## Option A: VS Code only (no commands needed)

1. `File → Open Folder…` → `C:\projects\garmin-app`
2. **F5** → choose **Run App (fenix 7 Pro)** → simulator opens, app runs.
3. Change code → **F5** again to rebuild and restart.
4. Tests: Run and Debug dropdown → **Run Tests (fenix 7 Pro)** → F5.
5. Other actions: `Ctrl+Shift+P` → type `Monkey C:` (Build Current Project, Build for Device, Clean Project, Open SDK Manager, Verify Installation, Edit Products/Permissions…).

### VS Code shortcuts

| Shortcut | What it does |
|---|---|
| **F5** | Build + open simulator + run app with debugger (breakpoints work) |
| **Ctrl+F5** | Same, without debugger |
| **Ctrl+Shift+F5** | Restart the app after a code change |
| **Shift+F5** | Stop |
| **Ctrl+Shift+B** | Build only — errors/warnings appear in the Problems panel (**Ctrl+Shift+M**) |
| `Ctrl+Shift+P` → **Tasks: Run Test Task** | Unit tests |
| `Ctrl+Shift+P` → **Tasks: Run Task** | `CIQ: Start simulator`, `CIQ: Run in simulator (log in terminal)`, `CIQ: Clean` |

App logs (`Log.debug`, `System.println`) show in the **Debug Console** (F5) or the terminal (CLI run).

## Option B: PowerShell

```powershell
cd C:\projects\garmin-app
```

```powershell
.\scripts\ciq.ps1 build     # compile -> bin\GarminStarter.prg
```

```powershell
.\scripts\ciq.ps1 run       # compile + open simulator + launch app (Ctrl+C to stop log)
```

```powershell
.\scripts\ciq.ps1 test      # unit tests in the simulator
```

```powershell
.\scripts\ciq.ps1 sim       # just open the simulator
```

```powershell
.\scripts\ciq.ps1 clean     # delete bin\
```

If PowerShell says scripts are disabled, run this once in the same window (affects only that window):

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

## Option C: macOS / Linux terminal

Same tasks as Option B. Needs a Java runtime (`brew install openjdk@17` on macOS; the script finds it).

```bash
./scripts/ciq.sh build     # compile -> bin/GarminStarter.prg
```

```bash
./scripts/ciq.sh run       # compile + open simulator + launch app (Ctrl+C to stop log)
```

```bash
./scripts/ciq.sh test      # unit tests in the simulator
```

```bash
./scripts/ciq.sh sim       # just open the simulator
```

```bash
./scripts/ciq.sh clean     # delete bin/
```

In VS Code on macOS, Ctrl+Shift+B / Run Task use `ciq.sh` automatically.

## Put the app on your watch

```powershell
.\scripts\ciq.ps1 build
```
Then connect the watch by USB and copy `bin\GarminStarter.prg` into `GARMIN\APPS\` on the watch (File Explorer).

## In the simulator

START button or tap = press · BACK button = exit · status bar shows memory use.
