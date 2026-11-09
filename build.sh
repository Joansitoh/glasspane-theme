#!/usr/bin/env bash
# Build distributable archives into ./dist
#   glasspane.tar.gz          global theme, centred taskbar   (KDE UI: "Install from file…")
#   glasspane-left.tar.gz     global theme, left taskbar      (KDE UI: "Install from file…")
#   glasspane-full.tar.gz     everything + install.sh         (no git needed)
set -euo pipefail
cd "$(dirname "$0")"
rm -rf dist; mkdir -p dist; tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
scripts/package.sh "$tmp" center
scripts/package.sh "$tmp" left
tar -czf dist/glasspane.tar.gz      -C "$tmp" com.joansitoh.Glasspane
tar -czf dist/glasspane-left.tar.gz -C "$tmp" com.joansitoh.Glasspane-Left
tar -czf dist/glasspane-full.tar.gz --transform 's,^,glasspane-theme/,' \
    README.md LICENSE install.sh uninstall.sh build.sh scripts src assets po
ls -lh dist
