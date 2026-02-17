#!/usr/bin/env bash
set -euo pipefail

# credits to: https://github.com/Sebastiaan76/waybar_wireplumber_audio_changer/blob/main/audio_changer.py
# I just asked an LLM to port this to bash and I've made some changes.

WOFI_CMD=(
  wofi
  --dmenu
  --hide-scroll
  --allow-markup
  --hide-search
  --location=top_right
  --width=350
  --height=200
  --yoffset=5
  --xoffset=-30
)

# parse "wpctl status" and print lines as: "<id>\t<name>"
# where <name> already has " - Default" appended for the active sink.
parse_wpctl_status() {
  wpctl status \
  | sed 's/[├─│└]//g' \
  | awk '
      BEGIN { in_sinks=0 }
      /Sinks:/ { in_sinks=1; next }
      in_sinks {
        # Stop at the first blank line after Sinks block
        if ($0 ~ /^[[:space:]]*$/) exit

        line=$0
        gsub(/^[[:space:]]+/, "", line)

        # Remove trailing volume info
        sub(/[[:space:]]*\[vol:.*$/, "", line)

        # Mark default sink: starts with "*"
        is_default = 0
        if (line ~ /^\*/) {
          is_default = 1
          sub(/^\*[[:space:]]*/, "", line)
        }

        # Expect "NN. Name..."
        # Extract id and name reliably
        if (match(line, /^([0-9]+)\.[[:space:]]*(.*)$/, m)) {
          id=m[1]
          name=m[2]
          if (is_default) name = name "] - Active"
          printf "%s\t%s\n", id, name
        }
      }
    '
}

# setup sink list to be displayed in wofi 
# (names only with markup)
build_wofi_list() {
  parse_wpctl_status | awk -F"\t" '
    {
      id=$1
      name=$2
      if (name ~ /] - Active$/) {
        printf "<b> [%s</b>\n", name
      } else {
        printf "%s\n", name
      }
    }
  '
}
list="$(build_wofi_list)"

# if no sinks found
if [[ -z "${list}" ]]; then
  echo "No sinks found in wpctl status."
  notify-send "wofi" "No sinks found in wpctl status."
  exit 1
fi

# show wofi if theres at least one available sink
selected="$(
  printf '%s\n' "$list" | "${WOFI_CMD[@]}" || true
)"

[[ -z "${selected}" ]] && exit 0

# wofi returns the selected label

# this is only needed if the string returned by wofi
# is returned with markup
# TODO: look this up 
selected="${selected#<b>}"
selected="${selected%</b>}"
selected="${selected# }"

# find matching sink ID from the string name
# provided by parse_wpctl_status
sink_id="$(
  parse_wpctl_status | awk -F"\t" -v sel="$selected" '$2 == sel {print $1; exit}'
)"

# if something goes wrong while attempting to set the sink ID.
# this will also be triggered if you try to set the same sink
# FIXME: dont do anything in case the user tries to set the same sink
# and send a notification telling him that.
if [[ -z "${sink_id}" ]]; then
  echo "Could not match selection to a sink."
  notify-send "wofi" "Could not match selection to a sink."
  exit 1
fi

echo "Changed default sink."
notify-send "wofi" "Changed default sink."
wpctl set-default "$sink_id"

