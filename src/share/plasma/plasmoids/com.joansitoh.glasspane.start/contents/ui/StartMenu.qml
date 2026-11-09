import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import org.kde.plasma.private.kicker as Kicker
import org.kde.plasma.plasmoid
import org.kde.plasma.private.sessions as Sessions

Item {
    id: menu

    property bool expandedState: false
    signal closeRequested()

    implicitWidth: 640
    implicitHeight: 720
    Layout.minimumWidth: 640
    Layout.preferredWidth: 640
    Layout.minimumHeight: 720
    Layout.preferredHeight: 720

    // 0 = home, 1 = all apps, 2 = search
    property int page: search.text.length > 0 ? 2 : (showAll ? 1 : 0)
    property bool showAll: false

    onExpandedStateChanged: {
        if (expandedState) {
            search.forceActiveFocus();
        } else {
            search.text = "";
            showAll = false;
        }
    }

    // ---- Modelos ----------------------------------------------------------
    Kicker.KAStatsFavoritesModel { id: pinned; enabled: true; maxFavorites: 18 }
    readonly property var defaultPinned: [
        "applications:org.mozilla.firefox.desktop", "applications:org.kde.dolphin.desktop",
        "applications:com.mitchellh.ghostty.desktop", "applications:org.kde.kwrite.desktop",
        "applications:kdesystemsettings.desktop", "applications:org.kde.discover.desktop",
        "applications:org.kde.konsole.desktop", "applications:org.kde.kontact.desktop"
    ]
    Component.onCompleted: {
        // Own favourites store, shared by every instance of the widget.
        pinned.initForClient("com.joansitoh.glasspane.start.favorites");
        rootModel.refresh();
        allApps = rootModel.modelForRow(0);
        seedTimer.start();
    }
    // First run only: pin a few default apps (afterwards your own choices rule).
    Timer {
        id: seedTimer
        interval: 400
        onTriggered: {
            if (!Plasmoid.configuration.seeded && pinned.count === 0) {
                pinned.favorites = menu.defaultPinned;
            }
            Plasmoid.configuration.seeded = true;
        }
    }
    Kicker.RecentUsageModel { id: recents; shownItems: Kicker.RecentUsageModel.AppsAndDocs; ordering: Kicker.RecentUsageModel.Recent }
    // Row 0 of RootModel is "All applications" (flat, sorted list).
    Kicker.RootModel {
        id: rootModel
        autoPopulate: false
        appletInterface: root
        flat: true
        sorted: true
        showSeparators: false
        showTopLevelItems: true
        showAllApps: true
        showAllAppsCategorized: false
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
    }
    property var allApps: null
    Kicker.RunnerModel {
        id: results
        appletInterface: root
        mergeResults: true
        query: search.text
        runners: ["krunner_services", "krunner_systemsettings", "krunner_recentdocuments", "calculator", "baloosearch"]
    }

    KCoreAddons.KUser { id: user }
    Sessions.SessionManagement { id: session }

    property string ctxId: ""
    QQC2.Menu {
        id: ctxMenu
        QQC2.MenuItem {
            text: pinned.isFavorite(menu.ctxId) ? i18n("Unpin") : i18n("Pin to Start")
            icon.name: pinned.isFavorite(menu.ctxId) ? "window-unpin" : "pin"
            onTriggered: {
                if (pinned.isFavorite(menu.ctxId)) pinned.removeFavorite(menu.ctxId);
                else pinned.addFavorite(menu.ctxId);
            }
        }
    }
    function showContext(favId) {
        if (!favId) return;
        ctxId = favId;
        ctxMenu.popup();
    }

    function launch(model, index) {
        model.trigger(index, "", null);
        menu.closeRequested();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // ---- Buscador ------------------------------------------------------
        PlasmaExtras.SearchField {
            id: search
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            placeholderText: i18n("Search apps, settings and documents")
            onAccepted: if (menu.page === 2 && resultList.count > 0) menu.launch(resultList.model, 0)
            Keys.onEscapePressed: event => {
                if (text.length > 0) text = "";
                else if (menu.showAll) menu.showAll = false;
                else menu.closeRequested();
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: menu.page

            // ======== Page 0: home (pinned + recommended) =================
            ColumnLayout {
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Text {
                        text: i18n("Pinned")
                        font.pixelSize: 14; font.bold: true
                        color: Kirigami.Theme.textColor
                        Layout.fillWidth: true
                    }
                    PlasmaComponents3.Button {
                        text: i18n("All apps")
                        icon.name: "go-next"
                        LayoutMirroring.enabled: true
                        flat: true
                        onClicked: menu.showAll = true
                    }
                }

                GridView {
                    id: pinnedGrid
                    Layout.fillWidth: true
                    Layout.preferredHeight: 3 * cellHeight + 4
                    cellWidth: Math.floor(width / 6)
                    cellHeight: 88
                    clip: true
                    interactive: false
                    model: pinned
                    delegate: Tile {
                        width: pinnedGrid.cellWidth
                        height: pinnedGrid.cellHeight
                        iconSource: model.decoration
                        iconSize: 36
                        title: model.display
                        onActivated: menu.launch(pinned, index)
                        onContext: menu.showContext(model.favoriteId)
                    }
                }

                Text {
                    text: i18n("Recommended")
                    font.pixelSize: 14; font.bold: true
                    color: Kirigami.Theme.textColor
                    Layout.topMargin: 6
                }

                GridView {
                    id: recentGrid
                    Layout.fillWidth: true
                    Layout.preferredHeight: 3 * cellHeight
                    cellWidth: Math.floor(width / 2)
                    cellHeight: 52
                    clip: true
                    interactive: false
                    model: recents
                    delegate: Tile {
                        width: recentGrid.cellWidth
                        height: recentGrid.cellHeight
                        vertical: false
                        iconSource: model.decoration
                        iconSize: 28
                        title: model.display
                        subtitle: model.description || ""
                        // only 6 fit (3 rows x 2)
                        visible: index < 6
                        onActivated: menu.launch(recents, index)
                    }
                }
            }

            // ======== Page 1: all apps ====================================
            ColumnLayout {
                spacing: 8
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Text {
                        text: i18n("All apps")
                        font.pixelSize: 14; font.bold: true
                        color: Kirigami.Theme.textColor
                        Layout.fillWidth: true
                    }
                    PlasmaComponents3.Button {
                        text: i18n("Back")
                        icon.name: "go-previous"
                        flat: true
                        onClicked: menu.showAll = false
                    }
                }
                ListView {
                    id: appList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: allApps
                    boundsBehavior: Flickable.StopAtBounds
                    QQC2.ScrollBar.vertical: QQC2.ScrollBar {}
                    delegate: Tile {
                        width: appList.width
                        height: 40
                        vertical: false
                        iconSource: model.decoration
                        iconSize: 24
                        title: model.display
                        onActivated: menu.launch(appList.model, index)
                        onContext: menu.showContext(model.favoriteId)
                    }
                }
            }

            // ======== Page 2: search results ==============================
            ListView {
                id: resultList
                clip: true
                // with mergeResults, row 0 is the group holding all results
                model: results.count > 0 ? results.modelForRow(0) : null
                boundsBehavior: Flickable.StopAtBounds
                QQC2.ScrollBar.vertical: QQC2.ScrollBar {}
                delegate: Tile {
                    width: resultList.width
                    height: 48
                    vertical: false
                    iconSource: model.decoration
                    iconSize: 28
                    title: model.display
                    subtitle: model.description || ""
                    onActivated: menu.launch(resultList.model, index)
                    onContext: menu.showContext(model.favoriteId)
                }
                Text {
                    anchors.centerIn: parent
                    visible: resultList.count === 0 && !results.querying
                    text: i18n("No results")
                    color: Kirigami.Theme.textColor
                    opacity: 0.6
                }
            }
        }

        // ---- Footer: user + power -------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Kirigami.Theme.textColor
            opacity: 0.12
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            spacing: 10

            Kirigami.Icon {
                source: user.faceIconUrl.toString().length > 0 ? user.faceIconUrl : "user-identity"
                implicitWidth: 32; implicitHeight: 32
            }
            Text {
                text: user.fullName.length > 0 ? user.fullName : user.loginName
                color: Kirigami.Theme.textColor
                font.pixelSize: 13
                Layout.fillWidth: true
            }
            PlasmaComponents3.ToolButton {
                icon.name: "system-shutdown"
                display: QQC2.AbstractButton.IconOnly
                onClicked: powerMenu.popup()
                QQC2.ToolTip.text: i18n("Power")
                QQC2.ToolTip.visible: hovered
                QQC2.Menu {
                    id: powerMenu
                    QQC2.MenuItem { text: i18n("Lock"); icon.name: "system-lock-screen"; enabled: session.canLock; onTriggered: { menu.closeRequested(); session.lock(); } }
                    QQC2.MenuItem { text: i18n("Log out"); icon.name: "system-log-out"; enabled: session.canLogout; onTriggered: { menu.closeRequested(); session.requestLogout(); } }
                    QQC2.MenuItem { text: i18n("Sleep"); icon.name: "system-suspend"; enabled: session.canSuspend; onTriggered: { menu.closeRequested(); session.suspend(); } }
                    QQC2.MenuItem { text: i18n("Restart"); icon.name: "system-reboot"; enabled: session.canReboot; onTriggered: { menu.closeRequested(); session.requestReboot(); } }
                    QQC2.MenuItem { text: i18n("Shut down"); icon.name: "system-shutdown"; enabled: session.canShutdown; onTriggered: { menu.closeRequested(); session.requestShutdown(); } }
                }
            }
        }
    }
}
