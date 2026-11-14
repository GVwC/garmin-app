<#
.SYNOPSIS
  Thin CLI wrapper around the Connect IQ SDK tools (monkeyc, monkeydo, simulator).
  VS Code users can use the Monkey C extension instead; this exists so terminal
  users and AI agents can run the same checks.

.EXAMPLE
  .\scripts\ciq.ps1 build             # compile debug .prg for fenix7pro (warnings + strict type check)
  .\scripts\ciq.ps1 run               # build, start simulator if needed, launch the app
  .\scripts\ciq.ps1 test              # build with --unit-test and run tests in the simulator
  .\scripts\ciq.ps1 sim               # start the simulator only
  .\scripts\ciq.ps1 package           # release .iq package (store upload) - only when asked
  .\scripts\ciq.ps1 clean             # delete bin/

  Signing key: $env:CIQ_DEVELOPER_KEY, else "monkeyC.developerKeyPath" from VS Code user settings.
  SDK: the active SDK from %APPDATA%\Garmin\ConnectIQ\current-sdk.cfg (set by SDK Manager).
#>
param(
    [ValidateSet('build', 'run', 'test', 'sim', 'package', 'clean')]
    [string]$Task = 'build',
    [string]$Device = 'fenix7pro'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'bin'
$appName = 'GarminStarter'

$sdk = (Get-Content (Join-Path $env:APPDATA 'Garmin\ConnectIQ\current-sdk.cfg') -Raw).Trim()
$bin = Join-Path $sdk 'bin'

function Get-DeveloperKey {
    $key = $env:CIQ_DEVELOPER_KEY
    if (-not $key) {
        $settings = Join-Path $env:APPDATA 'Code\User\settings.json'
        if (Test-Path $settings) {
            $m = Select-String -Path $settings -Pattern '"monkeyC\.developerKeyPath"\s*:\s*"([^"]+)"'
            if ($m) { $key = $m.Matches[0].Groups[1].Value -replace '\\\\', '\' }
        }
    }
    if (-not $key -or -not (Test-Path $key)) {
        throw 'Developer key not found. Set $env:CIQ_DEVELOPER_KEY or monkeyC.developerKeyPath in VS Code.'
    }
    return $key
}

function Invoke-Compile([string]$outFile, [string[]]$extra) {
    New-Item -ItemType Directory -Force $out | Out-Null
    $compileArgs = @('-f', (Join-Path $root 'monkey.jungle'), '-y', (Get-DeveloperKey), '-o', $outFile, '-w', '-l', '3') + $extra
    & (Join-Path $bin 'monkeyc.bat') @compileArgs
    if ($LASTEXITCODE -ne 0) { throw "Compilation failed (exit $LASTEXITCODE)" }
}

function Start-Sim {
    if (-not (Get-Process -Name simulator -ErrorAction SilentlyContinue)) {
        Start-Process (Join-Path $bin 'simulator.exe')
        Start-Sleep -Seconds 6   # give the simulator time to open its connection port
    }
}

switch ($Task) {
    'build' {
        Invoke-Compile (Join-Path $out "$appName.prg") @('-d', $Device)
    }
    'sim' { Start-Sim }
    'run' {
        $prg = Join-Path $out "$appName.prg"
        Invoke-Compile $prg @('-d', $Device)
        Start-Sim
        & (Join-Path $bin 'monkeydo.bat') $prg $Device
    }
    'test' {
        $prg = Join-Path $out "$appName-test.prg"
        Invoke-Compile $prg @('-d', $Device, '--unit-test')
        Start-Sim
        $result = & (Join-Path $bin 'monkeydo.bat') $prg $Device /t 2>&1 | Out-String
        Write-Output $result
        # Summary line looks like: PASSED (passed=2, failed=0, errors=0)
        if ($result -notmatch '(?m)^PASSED \(passed=\d+, failed=0, errors=0\)') { throw 'Unit tests did not pass.' }
    }
    'package' {
        Invoke-Compile (Join-Path $out "$appName.iq") @('-e', '-r')
    }
    'clean' {
        if (Test-Path $out) { Remove-Item -Recurse -Force $out }
    }
}
