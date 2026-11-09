import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // Gap between the menu and the taskbar (like Windows 11).
    readonly property int gap: 12

    Plasmoid.icon: "glasspane-start"
    preferredRepresentation: compactRepresentation
    toolTipMainText: i18n("Start")

    function toggle() { dialog.visible = !dialog.visible }

    // The Meta key (activateLauncherMenu) toggles "expanded": turn that into opening or
    // closing our own dialog and keep the native popup closed.
    onExpandedChanged: {
        if (root.expanded) {
            root.expanded = false;
            root.toggle();
        }
    }

    // Only used to read the screen this panel lives on.
    Item { id: screenRef }

    compactRepresentation: MouseArea {
        id: compact
        hoverEnabled: true
        activeFocusOnTab: true
        Layout.minimumWidth: Plasmoid.formFactor === PlasmaCore.Types.Horizontal ? height : Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? width : Kirigami.Units.iconSizes.small
        onClicked: root.toggle()

        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
            active: compact.containsMouse
        }
    }

    // Required by PlasmoidItem but never shown; the real menu is the dialog below.
    fullRepresentation: Item {}

    PlasmaCore.Dialog {
        id: dialog
        type: PlasmaCore.Dialog.AppletPopup
        // Bottom edge: KWin's native "Sliding Popups" effect slides it in from the bottom and
        // back down on close, without a fade. "floating" keeps the gap and all four
        // corners rounded.
        location: PlasmaCore.Types.BottomEdge
        floating: 1
        hideOnWindowDeactivate: true
        visualParent: null

        // Centered on the screen and floating above the taskbar.
        function place() {
            var s = screenRef.Screen;
            // Real window size = content + frame margins.
            var w = dialog.width > 0 ? dialog.width : mainItem.implicitWidth + margins.left + margins.right;
            var h = dialog.height > 0 ? dialog.height : mainItem.implicitHeight + margins.top + margins.bottom;
            // Top of the taskbar = top of the start button.
            var panelTop = s.virtualY + s.height;
            var centered = true;
            var it = root.compactRepresentationItem;
            if (it) {
                var p = it.mapToGlobal(0, 0);
                panelTop = p.y;
                // Button in the middle of the taskbar -> centered menu (Windows 11);
                // button on the left -> menu aligned to the left.
                var cx = p.x + it.width / 2 - s.virtualX;
                centered = cx > s.width * 0.25 && cx < s.width * 0.75;
            }
            x = centered ? Math.round(s.virtualX + (s.width - w) / 2) : s.virtualX + root.gap;
            y = Math.round(panelTop - h - root.gap);
        }
        onVisibleChanged: if (visible) { place(); requestActivate(); }
        onHeightChanged: if (visible) place()
        onWidthChanged: if (visible) place()

        mainItem: StartMenu {
            expandedState: dialog.visible
            onCloseRequested: dialog.visible = false
        }
    }
}
