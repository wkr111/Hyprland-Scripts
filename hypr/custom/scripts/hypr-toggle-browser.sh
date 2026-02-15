#!/usr/bin/env bash
# --------------------------------------------------------------------------
# Script:  hypr-toggle-browser.sh
# Purpose: Focus or Launch a single browser instance in Hyprland
# --------------------------------------------------------------------------

# --- CONFIGURATION ---
declare -A BROWSER_SPECS=(
    ["zen-browser"]="zen:zen-bin,zen"
    ["floorp"]="floorp:floorp"
    ["waterfox"]="waterfox:waterfox-bin,waterfox"
    ["brave-browser"]="brave-browser:brave-browser,brave"
    ["google-chrome-stable"]="google-chrome:chrome"
    ["firefox"]="firefox:firefox,firefox-esr"
    ["microsoft-edge-stable"]="msedge:microsoft-edge,msedge"
    ["vivaldi-stable"]="vivaldi-stable:vivaldi-bin,vivaldi"
    ["librewolf"]="librewolf:librewolf"
    ["chromium"]="chromium:chromium,chromium-browser"
    ["opera"]="opera:opera"
    ["helium"]="helium:helium"
)

# --- PRE-FLIGHT ---
[[ -z "$1" ]] && exit 0
if ! command -v jq &>/dev/null; then exit 1; fi

SELECTED=""
for cmd in "$@"; do
    if command -v "$cmd" &>/dev/null; then
        SELECTED="$cmd"; break
    fi
done
[[ -z "$SELECTED" ]] && exit 0

# Extract specifications
SPEC="${BROWSER_SPECS[$SELECTED]:-$SELECTED:$SELECTED}"
IFS=':' read -r WIN_CLASS PROC_CANDIDATES <<< "$SPEC"
IFS=',' read -ra PROC_LIST <<< "$PROC_CANDIDATES"

# --- CORE LOGIC: SINGLE WINDOW FOCUS ---
# Fetch the first matching window's address and workspace ID
TARGET_WIN=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$WIN_CLASS\") | \"\(.address) \(.workspace.id)\"" | head -n 1)

if [[ -n "$TARGET_WIN" ]]; then
    read -r ADDR WS_ID <<< "$TARGET_WIN"
    # Use batch mode to switch workspace and focus in one IPC call
    hyprctl --batch "dispatch workspace $WS_ID ; dispatch focuswindow address:$ADDR" >/dev/null 2>&1
    exit 0
fi

# --- PHASE 2: PROCESS CHECK ---
# Avoid re-launching if the process exists but no window is mapped yet
for p in "${PROC_LIST[@]}"; do
    pgrep -u "$USER" -x "$p" &>/dev/null && exit 0
done

# --- PHASE 3: EXECUTION ---
hyprctl dispatch exec "$SELECTED" >/dev/null 2>&1
