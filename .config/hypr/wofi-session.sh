#!/bin/bash
set -euo pipefail

CHOICE="$(
  printf '%b' " Lock\n󰗼 Logout\n Reboot\n Suspend\n Shutdown\n" \
  | wofi --hide-search --conf "$HOME/.config/wofi/config-session" --cache-file=/dev/null
)"

[[ -z "${CHOICE:-}" ]] && exit 0

case "$CHOICE" in
  " Lock")
    if command -v hyprlock >/dev/null 2>&1; then
      hyprlock
    elif command -v swaylock >/dev/null 2>&1; then
      swaylock
    else
      loginctl lock-session
    fi
    ;;
  "󰗼 Logout") hyprctl dispatch exit ;;
  " Reboot") systemctl reboot ;;
  " Suspend") systemctl suspend ;;
  " Shutdown") systemctl poweroff ;;
  *) exit 0 ;;
esac

