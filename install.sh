#!/usr/bin/env bash
# Install Glasspane for the current user.
#   ./install.sh                  install everything and apply (centred taskbar)
#   ./install.sh --layout=left    same, with the taskbar on the left
#   ./install.sh --no-apply       install only; pick the theme in System Settings later
#   ./install.sh --titlebar-opacity=90   window title bar opacity in percent (default 85)
set -euo pipefail
cd "$(dirname "$0")"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
LAYOUT="Glasspane"; APPLY=1; TB_OPACITY=""
for a in "$@"; do case "$a" in
  --layout=left)   LAYOUT="Glasspane-Left" ;;
  --layout=center) LAYOUT="Glasspane" ;;
  --no-apply)      APPLY=0 ;;
  --titlebar-opacity=*) TB_OPACITY="${a#*=}" ;;
  -h|--help)       sed -n '2,6p' "$0"; exit 0 ;;
  *) echo "unknown option: $a" >&2; exit 1 ;;
esac; done

put() { # put <source dir/file> <destination dir>
  mkdir -p "$2"; rm -rf "$2/$(basename "$1")"; cp -a "$1" "$2/"
}

echo "• Installing components…"
put src/share/plasma/desktoptheme/Glasspane                      "$DATA/plasma/desktoptheme"
put src/share/plasma/plasmoids/com.joansitoh.glasspane.start     "$DATA/plasma/plasmoids"
python3 scripts/build-mo.py po "$DATA/plasma/plasmoids/com.joansitoh.glasspane.start"
put src/share/color-schemes/Glasspane.colors                     "$DATA/color-schemes"
put src/share/aurorae/themes/Glasspane                           "$DATA/aurorae/themes"
[ -n "$TB_OPACITY" ] && scripts/titlebar-opacity.sh "$TB_OPACITY"
put src/share/icons/Win10OS-cursors                              "$DATA/icons"
mkdir -p "$DATA/icons/hicolor/scalable/apps"
cp src/share/icons/hicolor/scalable/apps/glasspane-start.svg     "$DATA/icons/hicolor/scalable/apps/"
put src/config/Kvantum/Glasspane                                 "$CONF/Kvantum"

echo "• Installing global themes (Glasspane, Glasspane Left)…"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
scripts/package.sh "$tmp" center
scripts/package.sh "$tmp" left
mkdir -p "$DATA/plasma/look-and-feel"
for id in com.joansitoh.Glasspane com.joansitoh.Glasspane-Left; do put "$tmp/$id" "$DATA/plasma/look-and-feel"; done

# leftovers from earlier development names
rm -rf "$DATA/plasma/desktoptheme/Win11OS-dark-modern" "$DATA/plasma/look-and-feel/com.joansitoh.Win11OS" \
       "$DATA/kwin/scripts/glasspane-startmenu"

if [ ! -d "$DATA/icons/Win11" ] && [ ! -d /usr/share/icons/Win11 ]; then
  echo "• Win11 icon theme missing: fetching it from its upstream repo…"
  t2="$(mktemp -d)"
  git clone --depth 1 https://github.com/yeyushengfan258/Win11-icon-theme "$t2/icons"
  (cd "$t2/icons" && ./install.sh)
  rm -rf "$t2"
fi
if [ -z "$(find /usr/lib /usr/lib64 -name 'libkvantum.so' -print -quit 2>/dev/null)" ] && ! command -v kvantummanager >/dev/null; then
  echo "! Kvantum does not seem to be installed (needed for the widget style)."
  echo "  Fedora: sudo dnf install kvantum    Debian/Ubuntu: sudo apt install qt6-style-kvantum"
fi

[ "$APPLY" = 0 ] && { echo "Done. Select it in System Settings → Appearance → Global Theme."; exit 0; }

echo "• Applying…"
mkdir -p "$CONF/Kvantum"
printf '[General]\ntheme=Glasspane\n' > "$CONF/Kvantum/kvantum.kvconfig"
plasma-apply-lookandfeel -a "com.joansitoh.$LAYOUT" --resetLayout
plasma-apply-desktoptheme Glasspane || true
echo "Done. If anything looks off, log out and back in."
