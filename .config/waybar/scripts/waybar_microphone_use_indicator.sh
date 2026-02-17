#!/usr/bin/env bash
set -euo pipefail

if pactl list source-outputs short 2>/dev/null | grep -q .; then
  printf '{"text":"","tooltip":"Microphone: Active","class":"active"}\n'
else
  printf '{"text":"","tooltip":"","class":"inactive"}\n'
fi
