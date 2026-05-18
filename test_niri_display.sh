#!/bin/bash

# Niri Display Settings CLI Test Script
# This script simulates the logic used in the DMS plugin service.

# Requirements: niri, jq (optional, will fallback to python3)

HAS_JQ=$(command -v jq)

get_outputs_json() {
    niri msg --json outputs
}

get_internal_display() {
    local json=$1
    if [ -n "$HAS_JQ" ]; then
        echo "$json" | jq -r 'to_entries[] | select(.key | test("eDP|LVDS"; "i")) | .key' | head -n 1
    else
        echo "$json" | python3 -c 'import json, sys; d=json.load(sys.stdin); print("\n".join([k for k,v in d.items() if any(x in k.lower() for x in ["edp", "lvds"])]))' | head -n 1
    fi
}

get_external_displays() {
    local json=$1
    if [ -n "$HAS_JQ" ]; then
        echo "$json" | jq -r 'to_entries[] | select(.key | test("eDP|LVDS"; "i") | not) | .key'
    else
        echo "$json" | python3 -c 'import json, sys; d=json.load(sys.stdin); print("\n".join([k for k,v in d.items() if not any(x in k.lower() for x in ["edp", "lvds"])]))'
    fi
}

apply_profile() {
    local profile=$1
    echo "Applying profile: $profile"
    
    local json=$(get_outputs_json)
    local internal=$(get_internal_display "$json")
    local externals=$(get_external_displays "$json")
    
    case $profile in
        internal_only)
            echo "Action: Internal ON, Externals OFF"
            [ -n "$internal" ] && niri msg output "$internal" on
            for ext in $externals; do
                niri msg output "$ext" off
            done
            ;;
        external_only)
            echo "Action: Internal OFF, Externals ON"
            [ -n "$internal" ] && niri msg output "$internal" off
            for ext in $externals; do
                niri msg output "$ext" on
            done
            ;;
        extend)
            echo "Action: All ON"
            [ -n "$internal" ] && niri msg output "$internal" on
            for ext in $externals; do
                niri msg output "$ext" on
            done
            ;;
        *)
            echo "Unknown profile: $profile"
            return 1
            ;;
    esac
}

check_fallback() {
    echo "Checking fallback..."
    local json=$(get_outputs_json)
    local internal=$(get_internal_display "$json")
    
    # Count active external displays
    local active_externals
    if [ -n "$HAS_JQ" ]; then
        active_externals=$(echo "$json" | jq -r 'to_entries[] | select(.key | test("eDP|LVDS"; "i") | not) | select(.value.logical != null) | .key')
    else
        active_externals=$(echo "$json" | python3 -c 'import json, sys; d=json.load(sys.stdin); print("\n".join([k for k,v in d.items() if not any(x in k.lower() for x in ["edp", "lvds"]) and v.get("logical") is not None]))')
    fi
    
    local count=$(echo "$active_externals" | grep -c . || echo 0)
    echo "Active external displays: $count"
    
    # Check if internal is logical
    local internal_logical
    if [ -n "$HAS_JQ" ]; then
        internal_logical=$(echo "$json" | jq -r ".[\"$internal\"].logical")
    else
        internal_logical=$(echo "$json" | python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get(\"$internal\", {}).get(\"logical\"))")
    fi

    if [ "$count" -eq 0 ] && [ "$internal_logical" == "None" ] || [ "$internal_logical" == "null" ]; then
        echo "FALLBACK TRIGGERED: No active external displays found and internal display is disabled."
        echo "Action: Enabling internal display $internal"
        niri msg output "$internal" on
    else
        echo "Fallback not needed: count=$count, internal_logical=$internal_logical"
    fi
}

case $1 in
    internal) apply_profile "internal_only" ;;
    external) apply_profile "external_only" ;;
    extend) apply_profile "extend" ;;
    fallback) check_fallback ;;
    *)
        echo "Usage: $0 {internal|external|extend|fallback}"
        exit 1
        ;;
esac
