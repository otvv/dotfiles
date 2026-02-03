#!/bin/bash
set -euo pipefail

WOFI_CMD="$(
  printf '%b' " [Lock]\n󰗼 [Logout]\n [Reboot]\n [Suspend]\n [Shutdown]\n" \
  | wofi --hide-search --conf "$HOME/.config/wofi/config-session" --cache-file=/dev/null
)"

[[ -z "${WOFI_CMD:-}" ]] && exit 0

case "$WOFI_CMD" in
  " [Lock]") hyprlock ;;
  "󰗼 [Logout]") hyprctl dispatch exit ;;
  " [Reboot]") systemctl reboot ;;
  " [Suspend]") systemctl suspend ;;
  " [Shutdown]") systemctl poweroff ;;
  *) exit 0 ;;
esac

