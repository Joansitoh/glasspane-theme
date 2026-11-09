#!/usr/bin/env bash
# Set the opacity of the Glasspane window decoration (title bar and borders).
#   scripts/titlebar-opacity.sh 85     percent, 0–100 (default theme value: 85)
#   scripts/titlebar-opacity.sh        print the current value
# Edits the installed theme in ~/.local/share/aurorae/themes/Glasspane and reloads KWin.
set -euo pipefail
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
SVG="${GLASSPANE_DECORATION_SVG:-$DATA/aurorae/themes/Glasspane/decoration.svg}"
[ -f "$SVG" ] || { echo "Glasspane decoration not installed ($SVG). Run ./install.sh first." >&2; exit 1; }

current="$(grep -o 'opacity:[0-9.]*;fill:#282828' "$SVG" | head -n1 | sed 's/opacity:\([0-9.]*\);.*/\1/')"
if [ $# -eq 0 ]; then
  awk -v o="$current" 'BEGIN { printf "%d\n", o * 100 + 0.5 }'; exit 0
fi
pct="$1"
[[ "$pct" =~ ^[0-9]+$ ]] && [ "$pct" -le 100 ] || { echo "opacity must be an integer between 0 and 100" >&2; exit 1; }
val="$(awk -v p="$pct" 'BEGIN { printf "%.2f", p / 100 }')"

sed -i "s/opacity:[0-9.]*;fill:#282828/opacity:$val;fill:#282828/g" "$SVG"
echo "Title bar opacity: $pct%"

# Aurorae caches the rendered theme; reconfigure KWin so the change shows up.
dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1 || true
