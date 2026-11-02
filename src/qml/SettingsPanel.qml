/*
 * Project: Crankshaft
 * Settings panel shell.
 *
 * This dialog only handles frame/navigation/reset. Tab content is split into
 * dedicated files under qml/settings for maintainability.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import "settings" as SettingsTabs

Dialog {
    id: settingsPanel
    property int displayRotation: 0
    readonly property bool isQuarterTurn: displayRotation === 90 || displayRotation === 270
    // Short screens (e.g. 800x480): use almost the whole display and keep the
    // chrome (title, tabs, close) to one compact band so settings have room.
    readonly property bool compact: !isQuarterTurn && parent && parent.height <= 600
    readonly property int contentMargin: (isQuarterTurn || compact) ? 12 : 18
    readonly property int sectionSpacing: (isQuarterTurn || compact) ? 8 : 12
    readonly property int headerTitleSize: (isQuarterTurn || compact) ? 16 : 18
    readonly property int tabFontSize: isQuarterTurn ? 10 : (compact ? 12 : 11)
    readonly property int panelInnerMargin: (isQuarterTurn || compact) ? 10 : 14
    title: ""
    modal: true
    parent: Overlay.overlay
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    // Keep content proportions readable after rotating the dialog content.
    width: isQuarterTurn
           ? Math.min(460, parent.width * 0.94)
           : (compact ? parent.width - 16 : Math.min(760, parent.width * 0.96))
    height: isQuarterTurn
            ? Math.min(760, parent.height * 0.96)
            : (compact ? parent.height - 16 : Math.min(460, parent.height * 0.94))
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    padding: 0
    z: 1000

    standardButtons: Dialog.NoButton

    // Dark scrim behind the panel (the default Material dim showed as a light
    // grey frame around the dark panel).
    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.6)
    }

    background: Rectangle {
        radius: settingsPanel.isQuarterTurn ? 12 : 16
        color: settingsPanel.Material.theme === Material.Dark
               ? settingsPanel.Material.background
               : settingsPanel.Material.dialogColor
        border.width: 1
        border.color: Qt.rgba(settingsPanel.Material.accent.r,
                              settingsPanel.Material.accent.g,
                              settingsPanel.Material.accent.b, 0.65)
    }

    Item {
        id: rotatedViewport
        anchors.fill: parent
        clip: true

        Item {
            id: rotatedContent
            anchors.centerIn: parent
            width: (settingsPanel.displayRotation === 90 || settingsPanel.displayRotation === 270)
                   ? rotatedViewport.height
                   : rotatedViewport.width
            height: (settingsPanel.displayRotation === 90 || settingsPanel.displayRotation === 270)
                    ? rotatedViewport.width
                    : rotatedViewport.height

            transform: Rotation {
                angle: settingsPanel.displayRotation
                origin.x: rotatedContent.width / 2
                origin.y: rotatedContent.height / 2
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: settingsPanel.contentMargin
                spacing: settingsPanel.sectionSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: settingsPanel.isQuarterTurn ? 6 : 8

                    Label {
                        text: qsTr("Settings", "SettingsPanel")
                        font.pointSize: settingsPanel.headerTitleSize
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Button {
                        visible: settingsPanel.isQuarterTurn || settingsPanel.compact
                        text: qsTr("Close", "SettingsPanel")
                        flat: true
                        font.pointSize: 12
                        Layout.preferredHeight: 44
                        onClicked: settingsPanel.close()
                    }
                }

                TabBar {
                    id: tabBar
                    Layout.fillWidth: true
                    spacing: settingsPanel.isQuarterTurn ? 1 : 2
                    Layout.preferredHeight: settingsPanel.isQuarterTurn ? 38 : implicitHeight

                    TabButton {
                        text: qsTr("Display", "SettingsPanel")
                        font.pointSize: settingsPanel.tabFontSize
                        horizontalPadding: settingsPanel.isQuarterTurn ? 8 : 12
                    }
                    TabButton {
                        text: qsTr("Audio", "SettingsPanel")
                        font.pointSize: settingsPanel.tabFontSize
                        horizontalPadding: settingsPanel.isQuarterTurn ? 8 : 12
                    }
                    TabButton {
                        text: qsTr("Connection", "SettingsPanel")
                        font.pointSize: settingsPanel.tabFontSize
                        horizontalPadding: settingsPanel.isQuarterTurn ? 8 : 12
                    }
                    TabButton {
                        text: qsTr("Bluetooth", "SettingsPanel")
                        font.pointSize: settingsPanel.tabFontSize
                        horizontalPadding: settingsPanel.isQuarterTurn ? 8 : 12
                    }
                    TabButton {
                        text: qsTr("Car", "SettingsPanel")
                        font.pointSize: settingsPanel.tabFontSize
                        horizontalPadding: settingsPanel.isQuarterTurn ? 8 : 12
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: settingsPanel.isQuarterTurn ? 10 : 12
                    color: settingsPanel.Material.theme === Material.Dark
                           ? Qt.rgba(1, 1, 1, 0.02)
                           : Qt.rgba(0, 0, 0, 0.025)
                    border.width: 1
                    border.color: settingsPanel.Material.theme === Material.Dark
                                  ? Qt.rgba(1, 1, 1, 0.08)
                                  : Qt.rgba(0, 0, 0, 0.14)

                    StackLayout {
                        anchors.fill: parent
                        anchors.margins: settingsPanel.panelInnerMargin
                        currentIndex: tabBar.currentIndex

                        SettingsTabs.DisplaySettingsTab {
                            preferencesFacade: _preferencesFacade
                        }

                        SettingsTabs.AudioSettingsTab {
                            preferencesFacade: _preferencesFacade
                        }

                        SettingsTabs.ConnectionSettingsTab {
                            preferencesFacade: _preferencesFacade
                            onRequestFactoryReset: resetConfirmationDialog.open()
                        }

                        SettingsTabs.BluetoothSettingsTab {
                            bluetoothService: _bluetoothService
                        }

                        SettingsTabs.CarSettingsTab {
                            preferencesFacade: _preferencesFacade
                        }
                    }
                }

                RowLayout {
                    visible: !settingsPanel.isQuarterTurn && !settingsPanel.compact
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }

                    Button {
                        text: qsTr("Close", "SettingsPanel")
                        onClicked: settingsPanel.close()
                    }
                }
            }
        }
    }

    Dialog {
        id: resetConfirmationDialog
        title: qsTr("Confirm Reset", "SettingsPanel")
        modal: true
        parent: settingsPanel.parent
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        z: 1001

        standardButtons: Dialog.Ok | Dialog.Cancel

        Label {
            text: qsTr("Reset all settings to factory defaults?\n\nBrightness: 50%\nAA Fullscreen Delay: Disabled\nVolume: 50%\nConnection: USB\nTheme: Dark", "SettingsPanel")
            wrapMode: Text.WordWrap
        }

        onAccepted: {
            _preferencesFacade.resetToDefaults()
            _preferencesFacade.saveSettings()
        }
    }
}
