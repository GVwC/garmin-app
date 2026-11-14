# Quickstart — copy & paste

## Option A: VS Code only (no commands needed)

1. `File → Open Folder…` → `C:\projects\garmin-connectiq-starter`
2. **F5** → choose **Run App (fenix 7 Pro)** → simulator opens, app runs.
3. Change code → **F5** again to rebuild and restart.
4. Tests: Run and Debug dropdown → **Run Tests (fenix 7 Pro)** → F5.
5. Other actions: `Ctrl+Shift+P` → type `Monkey C:` (Build Current Project, Build for Device, Clean Project, Open SDK Manager, Verify Installation, Edit Products/Permissions…).

## Option B: PowerShell

```powershell
cd C:\projects\garmin-connectiq-starter
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

## Put the app on your watch

```powershell
.\scripts\ciq.ps1 build
```
Then connect the watch by USB and copy `bin\GarminStarter.prg` into `GARMIN\APPS\` on the watch (File Explorer).

## In the simulator

START button or tap = press · BACK button = exit · status bar shows memory use.
