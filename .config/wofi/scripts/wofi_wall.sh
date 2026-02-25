#!/bin/bash
set -euo pipefail

HYPRLOCK_DIR="$HOME/.cache/hyprlock"
HYPRLOCK_WALLSYM="$HYPRLOCK_DIR/current_wallpaper"
mkdir -p "$HYPRLOCK_DIR"

THUMB_DIR="$HOME/.cache/wofi_wallpapers"
mkdir -p "$THUMB_DIR"

WALLPAPER_DIR="$(xdg-user-dir PICTURES)/Wallpapers"

HAVE_MAGICK=false
if command -v magick >/dev/null 2>&1; then
  echo "ImageMagick binary found."
  HAVE_MAGICK=true
fi

thumb_for() {
  local src="$1"

  # stable unique name based on full path
  local key
  key="$(printf '%s' "$src" | sha1sum | awk '{print $1}')"

  local thumb="$THUMB_DIR/$key.webp"

  # refresh thumb if missing or source is newer
  if [[ ! -f "$thumb" || "$src" -nt "$thumb" ]]; then
    if $HAVE_MAGICK; then
      # center-crop-ish thumbnail (keeps a nice preview shape)
      magick "$src" \
        -auto-orient \
        -thumbnail "250x140^" \
        -gravity center \
        -extent "250x140" \
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
      # only affects visual label
      display="${base//:/∶}"

      thumb="$(thumb_for "$f")"

      # IMPORTANT:
      # - show thumbnail using img:<thumb>
      # - return FULL wallpaper path via text:<path> so selection is unambiguous
      printf 'img:%s:text:%s\n' "$thumb" "$f"
    done
}

WOFI_CMD="$(
  menu | wofi \
    --hide-search \
    --conf "$HOME/.config/wofi/config-wallpaper" \
    --style "$HOME/.config/wofi/style-wallpaper.css" \
    --cache-file=/dev/null
)"

# this turns the current wofi selection the full wallpaper path.
# if wofi returns an image entry (img:...:text:...), keep only the path after "text:"
WOFI_CMD="${WOFI_CMD##*:text:}"

if [[ -z "${WOFI_CMD:-}" ]]; then
  exit 0
fi

WALLPAPER_PATH="$WOFI_CMD"

# make sure the wallpapers exists
# (kinda redundant since wofi wont show the wallpaper
# if it doesnt exist already, unless its deleted at script run time.)
if [[ ! -f "$WALLPAPER_PATH" ]]; then
  echo "Selected wallpaper does not exist: $WALLPAPER_PATH" >&2
  notify-send "wofi" "Selected wallpaper does not exist."
  exit 1
fi

CONF="$HOME/.config/hypr/hyprpaper.conf"

# remove previous wallpaper/preload lines
# and update it with the newly selected wallpaper
sed -i '/^preload =/d' "$CONF"
sed -i '/^wallpaper =/d' "$CONF"

{
  echo "preload = $WALLPAPER_PATH"
  echo "wallpaper = , $WALLPAPER_PATH"
} >> "$CONF"

# creates a symlink of the current wallpaper for hyprlock
# at: /home/USER/.cache/hyprlock
# ln -sf "$WALLPAPER_PATH" "$HYPRLOCK_WALLSYM"

# restart hyprpaper
pkill -x hyprpaper 2>/dev/null || true
hyprpaper &

echo "Wallpaper set."
notify-send "wofi" "Wallpaper set."
