#!/usr/bin/env bash
# Remove the Glasspane components installed by install.sh.
# Left in place on purpose: the Win10OS cursors and the Win11 icon theme (you may use
# them elsewhere) and your Kvantum selection. Switch to another global theme first.
set -euo pipefail
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
rm -rfv "$DATA/plasma/look-and-feel/com.joansitoh.Glasspane" \
        "$DATA/plasma/look-and-feel/com.joansitoh.Glasspane-Left" \
        "$DATA/plasma/desktoptheme/Glasspane" \
        "$DATA/plasma/plasmoids/com.joansitoh.glasspane.start" \
        "$DATA/color-schemes/Glasspane.colors" \
        "$DATA/aurorae/themes/Glasspane" \
        "$DATA/icons/hicolor/scalable/apps/glasspane-start.svg" \
        "$CONF/Kvantum/Glasspane"
echo "Removed. Pick another global theme in System Settings and restart plasmashell if panels show errors."
