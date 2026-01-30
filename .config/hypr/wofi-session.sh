#!/bin/bash
set -euo pipefail

CHOICE="$(
  printf '%b' " [Lock]\n󰗼 [Logout]\n [Reboot]\n [Suspend]\n [Shutdown]\n" \
  | wofi --hide-search --conf "$HOME/.config/wofi/config-session" --cache-file=/dev/null
)"

[[ -z "${CHOICE:-}" ]] && exit 0

case "$CHOICE" in
  " [Lock]") hyprlock ;;
  "󰗼 [Logout]") hyprctl dispatch exit ;;
  " [Reboot]") systemctl reboot ;;
  " [Suspend]") systemctl suspend ;;
  " [Shutdown]") systemctl poweroff ;;
  *) exit 0 ;;
esac

