/*
 * Project: Crankshaft
 * Connection status view used when projection is not active.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: statusView

    property var androidAutoFacade: null
    property var themeManager: null
    readonly property var t: themeManager ? themeManager : fallbackTheme

    ThemeManager {
        id: fallbackTheme
    }

    QtObject {
        id: palette
        readonly property color backgroundColor: t.colors.background
        readonly property color surfaceColor: t.colors.surface
        readonly property color borderColor: t.colors.border
        readonly property color errorColor: t.colors.error
        readonly property color successColor: t.colors.success
        readonly property color textPrimaryColor: t.colors.textPrimary
        readonly property color textSecondaryColor: t.colors.textSecondary
        readonly property color accentColor: t.colors.primary
        readonly property color accentColorHover: Qt.lighter(t.colors.primary, 1.12)
        readonly property color accentColorPressed: Qt.darker(t.colors.primary, 1.18)
        readonly property int spacing: t.spacing.medium
        readonly property int spacingMedium: t.spacing.medium
        readonly property int spacingLarge: t.spacing.large
        readonly property int radiusSmall: t.dimensions.borderRadiusSmall
        readonly property int radiusLarge: t.dimensions.borderRadiusLarge
        readonly property int touchTargetMinimum: t.dimensions.minTouchTarget
        readonly property int fontSizeHeading: t.typography.h3
        readonly property int fontSizeBody: t.typography.body1
    }

    readonly property int stateDisconnected: 0
    readonly property int stateSearching: 1
    readonly property int stateConnecting: 2
    readonly property int stateConnected: 3
    readonly property int stateError: 4

    property int connectionState: androidAutoFacade ? androidAutoFacade.connectionState : stateDisconnected
    // USB or Wireless, from Settings > Connection; changes the instructions shown.
    readonly property bool wirelessMode: typeof _preferencesFacade !== "undefined" && _preferencesFacade
                                         ? _preferencesFacade.connectionPreference === "WIRELESS"
                                         : false
    readonly property bool compact: height <= 600

    Rectangle {
        anchors.fill: parent
        color: palette.backgroundColor
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(560, parent.width * 0.86)
        // Fit the content instead of a fixed height (left a large empty area).
        height: Math.min(statusColumn.implicitHeight + 2 * palette.spacingLarge, parent.height * 0.9)
        radius: palette.radiusLarge
        color: Qt.rgba(palette.surfaceColor.r, palette.surfaceColor.g, palette.surfaceColor.b, 0.96)
        border.width: 1
        border.color: palette.borderColor

        ColumnLayout {
            id: statusColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: palette.spacingLarge
            spacing: statusView.compact ? palette.spacingMedium : palette.spacingLarge

            Item {
                Layout.preferredWidth: statusView.compact ? 88 : 120
                Layout.preferredHeight: statusView.compact ? 88 : 120
                Layout.alignment: Qt.AlignHCenter

                BusyIndicator {
                    anchors.centerIn: parent
                    width: 80
                    height: 80
                    running: statusView.connectionState === stateSearching ||
                             statusView.connectionState === stateConnecting
                }

                Text {
                    anchors.centerIn: parent
                    visible: !statusView.isLoadingState()
                    text: statusView.connectionState === stateConnected ? "✓" :
                          statusView.connectionState === stateError ? "✗" : "○"
                    font.pixelSize: 64
                    color: statusView.connectionState === stateConnected ? palette.successColor :
                           statusView.connectionState === stateError ? palette.errorColor :
                           palette.textSecondaryColor
                }
            }

            Label {
                text: getStatusText()
                font.pixelSize: palette.fontSizeHeading
                font.bold: true
                color: palette.textPrimaryColor
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Label {
                text: getStatusDetails()
                font.pixelSize: palette.fontSizeBody
                color: palette.textSecondaryColor
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            // Which way the head unit is looking for the phone, and where to change it.
            Rectangle {
                visible: !statusView.isActiveState()
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: modeLabel.implicitWidth + 28
                implicitHeight: 32
                radius: 16
                color: Qt.rgba(palette.accentColor.r, palette.accentColor.g, palette.accentColor.b, 0.16)
                border.width: 1
                border.color: Qt.rgba(palette.accentColor.r, palette.accentColor.g, palette.accentColor.b, 0.5)

                Label {
                    id: modeLabel
                    anchors.centerIn: parent
                    text: statusView.wirelessMode
                          ? qsTr("Wireless mode \u00b7 change with \u2699 Settings \u203a Connection")
                          : qsTr("USB mode \u00b7 change with \u2699 Settings \u203a Connection")
                    font.pixelSize: palette.fontSizeBody - 2
                    color: palette.textPrimaryColor
                }
            }

            Label {
                visible: statusView.connectionState === stateError
                text: androidAutoFacade ? androidAutoFacade.lastError : ""
                font.pixelSize: palette.fontSizeBody
                color: palette.errorColor
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: palette.spacingMedium
                Layout.alignment: Qt.AlignHCenter

                Button {
                    visible: statusView.connectionState === stateError
                    text: qsTr("Retry")
                    Layout.preferredHeight: palette.touchTargetMinimum
                    Layout.preferredWidth: 150

                    background: Rectangle {
                        color: parent.pressed ? palette.accentColorPressed :
                               parent.hovered ? palette.accentColorHover :
                               palette.accentColor
                        radius: palette.radiusSmall
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: palette.fontSizeBody
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        if (androidAutoFacade) {
                            androidAutoFacade.retryConnection()
                        }
                    }
                }

                Button {
                    visible: statusView.connectionState === stateConnected
                    text: qsTr("Disconnect")
                    Layout.preferredHeight: palette.touchTargetMinimum
                    Layout.preferredWidth: 150

                    background: Rectangle {
                        color: parent.pressed ? Qt.darker(palette.errorColor, 1.3) :
                               parent.hovered ? Qt.lighter(palette.errorColor, 1.1) :
                               palette.errorColor
                        radius: palette.radiusSmall
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: palette.fontSizeBody
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        if (androidAutoFacade) {
                            androidAutoFacade.disconnectDevice()
                        }
                    }
                }
            }
        }
    }

    function isActiveState() {
        return connectionState === stateConnecting || connectionState === stateConnected
    }

    function isLoadingState() {
        return connectionState === stateSearching || connectionState === stateConnecting
    }

    function getStatusText() {
        switch (connectionState) {
        case stateDisconnected:
        case stateSearching:
            return qsTr("Waiting for your phone")
        case stateConnecting:
            return qsTr("Connecting...")
        case stateConnected:
            return qsTr("Connected to %1").arg(androidAutoFacade ? androidAutoFacade.connectedDeviceName : "")
        case stateError:
            return qsTr("Connection Error")
        default:
            return qsTr("Unknown State")
        }
    }

    function getStatusDetails() {
        switch (connectionState) {
        case stateDisconnected:
        case stateSearching:
            return wirelessMode
                ? qsTr("First time: on your phone, pair Bluetooth with \u201cCrankshaft\u201d within 2 minutes of start-up. Paired phones start Android Auto automatically.")
                : qsTr("Connect your phone with a USB cable. Android Auto starts automatically.")
        case stateConnecting:
            return qsTr("Please wait while we establish the connection")
        case stateConnected:
            return qsTr("Android Auto projection is active")
        case stateError:
            return qsTr("Failed to connect to device")
        default:
            return ""
        }
    }
}
