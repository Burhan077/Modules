#!/usr/bin/env sh

# ------------ CONFIG ----------------
notify_id=929292
icon_dir="~/.config/dunst/icons/notifications"
notify_timeout=5000  # 5 seconds
state_file="/tmp/.dndstate"  # Fallback for non-dunstctl use
# ------------------------------------

# Check what notifier is available
notifier_backend() {
    if pgrep -x mako >/dev/null; then
        echo "mako"
    elif pgrep -x dunst >/dev/null; then
        echo "dunst"
    else
        echo "none"
    fi
}

send_notify() {
    local title=$1
    local body=$2
    local icon="$icon_dir/$3"
    local backend
    backend=$(notifier_backend)

    case "$backend" in
        mako)
            notify-send -r "$notify_id" -t "$notify_timeout" -i "$icon" "$title" "$body"
            ;;
        dunst)
            notify-send -r "$notify_id" -t "$notify_timeout" -u normal -i "$icon" "$title" "$body"
            ;;
        *)
            echo "❌ No supported notification daemon (Dunst or Mako) is running."
            ;;
    esac
}

set_state_file() {
    echo "$1" > "$state_file"
}

get_state_file() {
    [ -f "$state_file" ] && cat "$state_file" || echo "unknown"
}

use_dunstctl() {
    command -v dunstctl >/dev/null 2>&1
}

get_current_dnd_state() {
    if use_dunstctl; then
        dunstctl is-paused
    else
        get_state_file
    fi
}

toggle_dnd() {
    local current_state
    current_state=$(get_current_dnd_state)

    if [ "$current_state" = "true" ] || [ "$current_state" = "on" ]; then
        # Turn OFF DND
        if use_dunstctl; then
            dunstctl set-paused false
        else
            pkill -SIGUSR2 dunst 2>/dev/null
            set_state_file "off"
        fi
        sleep 0.2
        send_notify "🔔 DND Disabled" "Notifications are now active." "dnd-off.svg"
    else
        # Turn ON DND
        if use_dunstctl; then
            dunstctl set-paused true
        else
            pkill -SIGUSR1 dunst 2>/dev/null
            set_state_file "on"
        fi
        sleep 0.2
        send_notify "🔕 DND Enabled" "Notifications are silenced." "dnd-on.svg"
    fi
}

# -------------- ENTRY ----------------
if [ "$(notifier_backend)" = "none" ]; then
    echo "❌ Neither Dunst nor Mako is running. Cannot toggle DND."
    exit 1
fi

toggle_dnd

