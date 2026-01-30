#!/bin/bash
set -euo pipefail

HYPRLOCK_DIR="$HOME/.cache/hyprlock"
HYPRLOCK_WALLSYM="$HYPRLOCK_DIR/current_wallpaper"
mkdir -p "$HYPRLOCK_DIR"

THUMB_DIR="$HOME/.cache/wofi_wallpapers"
mkdir -p "$THUMB_DIR"

WALLPAPER_DIR="$(xdg-user-dir PICTURES)/Wallpapers"

have_magick=false
if command -v magick >/dev/null 2>&1; then
  have_magick=true
fi

thumb_for() {
  local src="$1"

  # stable unique name based on full path
  local key
  key="$(printf '%s' "$src" | sha1sum | awk '{print $1}')"

  local thumb="$THUMB_DIR/$key.webp"

  # refresh thumb if missing or source is newer
  if [[ ! -f "$thumb" || "$src" -nt "$thumb" ]]; then
    if $have_magick; then
      # center-crop-ish thumbnail (keeps a nice preview shape)
      magick "$src" \
        -auto-orient \
        -thumbnail "320x180^" \
        -gravity center \
        -extent "320x180" \
        -quality 85 \
        "$thumb"
    else
      # fallback: no thumb generation available; use original
      thumb="$src"
    fi
  fi

  printf '%s' "$thumb"
}

menu() {
  find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
    -print0 \
  | sort -z \
  | while IFS= read -r -d '' f; do
      base="$(basename "$f")"
      # Only affects visual label
      display="${base//:/∶}"

      thumb="$(thumb_for "$f")"

      # IMPORTANT:
      # - show thumbnail using img:<thumb>
      # - return FULL wallpaper path via text:<path> so selection is unambiguous
      printf 'img:%s:text:%s\n' "$thumb" "$f"
    done
}

CHOICE="$(
  menu | wofi \
    --hide-search \
    --conf "$HOME/.config/wofi/config-wallpaper" \
    --style "$HOME/.config/wofi/style-wallpaper.css" \
    --cache-file=/dev/null
)"

# If wofi returns an image entry (img:...:text:...), keep only the path after "text:"
# This makes CHOICE become the full wallpaper path.
CHOICE="${CHOICE##*:text:}"

# If user cancelled, exit cleanly
if [[ -z "${CHOICE:-}" ]]; then
  exit 0
fi

WALLPAPER_PATH="$CHOICE"

# Ensure it exists
if [[ ! -f "$WALLPAPER_PATH" ]]; then
  echo "Selected wallpaper does not exist: $WALLPAPER_PATH" >&2
  exit 1
fi

CONF="$HOME/.config/hypr/hyprpaper.conf"

# Remove previous wallpaper/preload lines
sed -i '/^preload =/d' "$CONF"
sed -i '/^wallpaper =/d' "$CONF"

{
  echo "preload = $WALLPAPER_PATH"
  echo "wallpaper = , $WALLPAPER_PATH"
} >> "$CONF"

# Creates a symlink of the current wallpaper for hyprlock
# at: /home/user/.cache/hyprlock
# ln -sf "$WALLPAPER_PATH" "$HYPRLOCK_WALLSYM"

# Restart hyprpaper
pkill -x hyprpaper 2>/dev/null || true
hyprpaper &

