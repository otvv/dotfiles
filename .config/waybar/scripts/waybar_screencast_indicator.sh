#!/usr/bin/env bash
set -euo pipefail

d="$(pw-dump 2>/dev/null || true)"

if [[ "$d" == *"\"media.class\": \"Stream/Input/Video\""* && \
      ( "$d" == *"\"application.name\": \"xdg-desktop-portal-hyprland\""* || \
        "$d" == *"\"application.name\": \"xdg-desktop-portal\""* ) ]]; then
  printf '{"text":"󰄀","tooltip":"Screen share: Active","class":"active"}\n'
else
  printf '{"text":"","tooltip":"","class":"inactive"}\n'
fi
