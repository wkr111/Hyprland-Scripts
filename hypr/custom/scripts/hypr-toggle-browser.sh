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

for cmd in "$@"; do
    if hash "$cmd" 2>/dev/null; then
        SELECTED="$cmd"; break
    fi
done
[[ -z "$SELECTED" ]] && exit 0

SPEC="${BROWSER_SPECS[$SELECTED]:-$SELECTED:$SELECTED}"
WIN_CLASS="${SPEC%%:*}"
PROC_CANDIDATES="${SPEC#*:}"

# --- CORE LOGIC: FOCUS EXISTING WINDOW ---
TARGET_WIN=$(hyprctl clients -j | jq -r --arg cls "$WIN_CLASS" '
    first(.[] | select(.class == $cls) | "\(.address) \(.workspace.id)") // empty
')

if [[ -n "$TARGET_WIN" ]]; then
    read -r ADDR WS_ID <<< "$TARGET_WIN"
    hyprctl --batch "dispatch workspace $WS_ID ; dispatch focuswindow address:$ADDR" >/dev/null 2>&1
    exit 0
fi

# --- PHASE 2: PROCESS CHECK (avoid duplicate launch) ---
PROC_PATTERN="${PROC_CANDIDATES//,/|}"
if pgrep -u "$USER" -x "$PROC_PATTERN" &>/dev/null; then
    exit 0
fi

# --- PHASE 3: LAUNCH BROWSER ---
hyprctl dispatch exec "$SELECTED" >/dev/null 2>&1
