/*
 * Project: Crankshaft
 * Reusable content card for settings sections.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Rectangle {
    id: card

    property string title: ""
    default property alias contentData: contentColumn.data
    readonly property bool isDarkTheme: card.Material.theme === Material.Dark

    radius: 10
    color: isDarkTheme ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(0, 0, 0, 0.03)
    border.width: 1
    border.color: isDarkTheme ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.16)

    implicitHeight: contentColumn.implicitHeight + 24

    // ColumnLayout (not Column) so children's Layout.fillWidth is honoured:
    // with a plain Column, sliders collapsed to ~160px and wide toggles
    // overflowed the card on small (800x480) screens.
    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8

        Label {
            Layout.fillWidth: true
            text: card.title
            visible: text !== ""
            font.pointSize: 12
            font.bold: true
            color: card.Material.foreground
            elide: Text.ElideRight
        }
    }
}
