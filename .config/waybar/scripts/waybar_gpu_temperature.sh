#!/usr/bin/env bash
set -euo pipefail

get_gpu_temp_milli() {
  local hw name label input

  # common gpu names
  local -a candidates=("amdgpu" "nvidia" "nouveau" "i915")

  # label patterns (varies by brand)
  local -a prefer_labels=("edge" "GPU" "junction" "hotspot" "Core")

  for hw in /sys/class/hwmon/hwmon*; do
    [[ -r "$hw/name" ]] || continue
    name="$(cat "$hw/name")"

    local ok=0
    for c in "${candidates[@]}"; do
      if [[ "$name" == "$c" ]]; then ok=1; break; fi
    done
    (( ok == 1 )) || continue

    # search for "labeled" temperatures
    for pat in "${prefer_labels[@]}"; do
      for label in "$hw"/temp*_label; do
        [[ -r "$label" ]] || continue
        if grep -qi -- "$pat" "$label"; then
          input="${label/_label/_input}"
          [[ -r "$input" ]] && cat "$input" && return 0
        fi
      done
    done

    # use the first readable temp in case
    # the above method fails
    for input in "$hw"/temp*_input; do
      [[ -r "$input" ]] || continue
      cat "$input" && return 0
    done
  done

  return 1
}

temp_milli="$(get_gpu_temp_milli || true)"
if [[ -z "${temp_milli:-}" ]]; then
  printf '{"text":" --°C","tooltip":"GPU temp sensor not found","class":"inactive"}\n'
  exit 0
fi

temp_c="$(( temp_milli / 1000 ))"

# classes for CSS styling
cls="normal"
if (( temp_c >= 85 )); then
  cls="critical"
fi

printf '{"text":" %s°C","tooltip":"GPU temperature: %s°C","class":"%s"}\n' \
  "$temp_c" "$temp_c" "$cls"
