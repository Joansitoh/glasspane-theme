#!/usr/bin/env bash
# Assemble a global-theme (Plasma/LookAndFeel) package into <outdir>.
#   scripts/package.sh <outdir> [center|left]
# Creates <outdir>/com.joansitoh.Glasspane (or ...Glasspane-Left).
# The colour scheme is embedded as contents/colors, so installing the package from the
# KDE UI already brings the colours; layouts, previews and splash are part of it too.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
out="$1"; variant="${2:-center}"
src="$root/src/share/plasma/look-and-feel/com.joansitoh.Glasspane"
id="com.joansitoh.Glasspane"; name="Glasspane"
[ "$variant" = left ] && { id="$id-Left"; name="Glasspane Left"; }
dst="$out/$id"
rm -rf "$dst"; mkdir -p "$out"
cp -a "$src" "$dst"
cp "$root/src/share/color-schemes/Glasspane.colors" "$dst/contents/colors"
if [ "$variant" = left ]; then
  cp "$root/src/variants/left/org.kde.plasma.desktop-layout.js" "$dst/contents/layouts/"
  sed -i -e "s/\"Id\": \"com.joansitoh.Glasspane\"/\"Id\": \"$id\"/" \
         -e "s/\"Name\": \"Glasspane\"/\"Name\": \"$name\"/" "$dst/metadata.json"
  sed -i -e "s/^Name=Glasspane\$/Name=$name/" \
         -e "s/^X-KDE-PluginInfo-Name=.*/X-KDE-PluginInfo-Name=$id/" "$dst/metadata.desktop"
fi
