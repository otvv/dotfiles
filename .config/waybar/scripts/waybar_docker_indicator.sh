#!/usr/bin/env bash
set -euo pipefail

n=$(docker ps -q 2>/dev/null | wc -l)

if [ "$n" -gt 0 ]; then
  printf '{"text":"%s","tooltip":"Containers running: %s","class":"active"}\n' "$n" "$n"
else
  printf '{"text":"0","tooltip":"No containers running","class":"inactive"}\n'
fi
