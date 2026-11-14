#!/usr/bin/env bash
# Thin CLI wrapper around the Connect IQ SDK tools (monkeyc, monkeydo, simulator)
# for macOS and Linux. Mirrors scripts/ciq.ps1 (Windows).
#
#   ./scripts/ciq.sh build             # compile debug .prg for fenix7pro (warnings + strict type check)
#   ./scripts/ciq.sh run               # build, start simulator if needed, launch the app
#   ./scripts/ciq.sh test              # build with --unit-test and run tests in the simulator
#   ./scripts/ciq.sh sim               # start the simulator only
#   ./scripts/ciq.sh package           # release .iq package (store upload) - only when asked
#   ./scripts/ciq.sh clean             # delete bin/
#   ./scripts/ciq.sh build fenix7      # optional second argument: device id (default fenix7pro)
#
# Signing key: $CIQ_DEVELOPER_KEY, else "monkeyC.developerKeyPath" from VS Code user settings.
# SDK: the active SDK from current-sdk.cfg (set by SDK Manager).
# Java: java on PATH, else $JAVA_HOME, /usr/libexec/java_home, or Homebrew openjdk.

set -euo pipefail

task="${1:-build}"
device="${2:-fenix7pro}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$root/bin"
app_name="GarminStarter"

die() { echo "ciq.sh: $*" >&2; exit 1; }

case "$(uname -s)" in
    Darwin)
        ciq_home="$HOME/Library/Application Support/Garmin/ConnectIQ"
        vscode_settings="$HOME/Library/Application Support/Code/User/settings.json"
        ;;
    *)
        ciq_home="$HOME/.Garmin/ConnectIQ"
        vscode_settings="$HOME/.config/Code/User/settings.json"
        ;;
esac

[ -f "$ciq_home/current-sdk.cfg" ] || die "no active SDK ($ciq_home/current-sdk.cfg). Install one with the SDK Manager."
sdk="$(tr -d '\r\n' < "$ciq_home/current-sdk.cfg")"
bin="${sdk%/}/bin"
[ -x "$bin/monkeyc" ] || die "monkeyc not found in $bin"

ensure_java() {
    java -version >/dev/null 2>&1 && return
    local candidates=()
    [ -n "${JAVA_HOME:-}" ] && candidates+=("$JAVA_HOME")
    [ -x /usr/libexec/java_home ] && candidates+=("$(/usr/libexec/java_home 2>/dev/null || true)")
    candidates+=(/opt/homebrew/opt/openjdk@17 /opt/homebrew/opt/openjdk /usr/local/opt/openjdk@17 /usr/local/opt/openjdk)
    local c
    for c in "${candidates[@]}"; do
        if [ -n "$c" ] && [ -x "$c/bin/java" ] && "$c/bin/java" -version >/dev/null 2>&1; then
            export PATH="$c/bin:$PATH"
            return
        fi
    done
    die "no Java runtime found. Install one, e.g. 'brew install openjdk@17'."
}

developer_key() {
    local key="${CIQ_DEVELOPER_KEY:-}"
    if [ -z "$key" ] && [ -f "$vscode_settings" ]; then
        key="$(sed -n 's/.*"monkeyC\.developerKeyPath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$vscode_settings" | head -n 1)"
        key="${key/#\~/$HOME}"
    fi
    [ -n "$key" ] && [ -f "$key" ] || die 'developer key not found. Set $CIQ_DEVELOPER_KEY or monkeyC.developerKeyPath in VS Code.'
    printf '%s' "$key"
}

compile() {
    local out_file="$1"; shift
    ensure_java
    local key; key="$(developer_key)"
    mkdir -p "$out"
    "$bin/monkeyc" -f "$root/monkey.jungle" -y "$key" -o "$out_file" -w -l 3 "$@" \
        || die "compilation failed"
}

sim_running() { pgrep -f "bin/(ConnectIQ\.app/Contents/MacOS/)?simulator" >/dev/null 2>&1; }

start_sim() {
    sim_running && return
    if [ "$(uname -s)" = Darwin ]; then
        open "$bin/ConnectIQ.app"
    else
        nohup "$bin/simulator" >/dev/null 2>&1 &
    fi
    local i
    for i in $(seq 1 30); do sim_running && break; sleep 1; done
    sim_running || die "simulator did not start"
    sleep 6   # give the simulator time to open its connection port
}

case "$task" in
    build)
        compile "$out/$app_name.prg" -d "$device"
        ;;
    sim)
        start_sim
        ;;
    run)
        prg="$out/$app_name.prg"
        compile "$prg" -d "$device"
        start_sim
        "$bin/monkeydo" "$prg" "$device"
        ;;
    test)
        prg="$out/$app_name-test.prg"
        compile "$prg" -d "$device" --unit-test
        start_sim
        result="$("$bin/monkeydo" "$prg" "$device" -t 2>&1 || true)"
        if grep -q "Unable to connect to simulator" <<<"$result"; then
            sleep 5
            result="$("$bin/monkeydo" "$prg" "$device" -t 2>&1 || true)"
        fi
        printf '%s\n' "$result"
        # Summary line looks like: PASSED (passed=2, failed=0, errors=0)
        grep -Eq '^PASSED \(passed=[0-9]+, failed=0, errors=0\)' <<<"$result" || die "unit tests did not pass"
        ;;
    package)
        compile "$out/$app_name.iq" -e -r
        ;;
    clean)
        rm -rf "$out"
        ;;
    *)
        die "unknown task '$task' (build | run | test | sim | package | clean)"
        ;;
esac
