import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Reusable cell: icon + text with a hover highlight.
// vertical: icon on top, name below (pinned grid); otherwise a row (recommended / lists).
Item {
    id: tile
    property bool vertical: true
    property alias iconSource: icon.source
    property alias iconSize: icon.implicitWidth
    property string title
    property string subtitle
    signal activated()
    signal context()

    readonly property bool hovered: mouse.containsMouse || activeFocus

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 6
        color: Kirigami.Theme.highlightColor
        opacity: tile.hovered ? 0.18 : 0
        Behavior on opacity { NumberAnimation { duration: 90 } }
    }

    GridLayout {
        anchors.fill: parent
        anchors.margins: 6
        columns: tile.vertical ? 1 : 2
        columnSpacing: 10
        rowSpacing: 4

        Kirigami.Icon {
            id: icon
            implicitWidth: 32
            implicitHeight: implicitWidth
            Layout.alignment: tile.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
        }
        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true
            Layout.alignment: tile.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
            Text {
                Layout.fillWidth: true
                text: tile.title
                color: Kirigami.Theme.textColor
                font.pixelSize: tile.vertical ? 11 : 13
                elide: Text.ElideRight
                maximumLineCount: tile.vertical ? 2 : 1
                wrapMode: tile.vertical ? Text.WordWrap : Text.NoWrap
                horizontalAlignment: tile.vertical ? Text.AlignHCenter : Text.AlignLeft
            }
            Text {
                visible: !tile.vertical && tile.subtitle.length > 0
                Layout.fillWidth: true
                text: tile.subtitle
                color: Kirigami.Theme.textColor
                opacity: 0.6
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => { if (mouse.button === Qt.RightButton) tile.context(); else tile.activated(); }
    }
    Keys.onReturnPressed: tile.activated()
    Keys.onEnterPressed: tile.activated()
}
