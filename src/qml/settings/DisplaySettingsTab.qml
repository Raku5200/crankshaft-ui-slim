/*
 * Project: Crankshaft
 * Display settings tab content.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components" as Components

Item {
    id: root

    required property var preferencesFacade
    // Local alias shortens repetitive facade checks and keeps bindings readable.
    readonly property var prefs: root.preferencesFacade

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        // Vertical scrolling only: content always matches the visible width
        // (it used to grow to the widest card and run off the right edge).
        contentWidth: availableWidth
        rightPadding: 16
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ScrollBar.vertical: ScrollBar {
            // A custom scrollbar must be positioned explicitly, otherwise it
            // sits at the top-left corner of the view.
            parent: scrollView
            x: scrollView.width - width
            y: scrollView.topPadding
            height: scrollView.availableHeight
            policy: ScrollBar.AlwaysOn
            width: 10
            minimumSize: 0.2

            contentItem: Rectangle {
                implicitWidth: 8
                radius: width / 2
                color: Qt.rgba(0.25, 0.55, 0.95, 0.85)
            }

            background: Rectangle {
                implicitWidth: 12
                radius: width / 2
                color: Qt.rgba(0.5, 0.5, 0.5, 0.18)
            }
        }

        ColumnLayout {
            // Qualified: an unqualified 'availableWidth' resolved to the
            // settings Dialog's width (784px) instead of this view's (724px).
            width: scrollView.availableWidth
            spacing: 12

            Components.SettingsCard {
                Layout.fillWidth: true
                title: qsTr("Display Rotation", "SettingsPanel")

                Components.DisplayRotationToggle {
                    Layout.fillWidth: true
                    showLabel: false
                    currentRotation: root.prefs ? root.prefs.displayRotation : 0
                    onRotationChanged: (newRotation) => {
                        if (root.prefs) {
                            root.prefs.displayRotation = newRotation
                        }
                    }
                }
            }

            Components.SettingsCard {
                Layout.fillWidth: true
                title: qsTr("Brightness", "SettingsPanel")

                Components.SettingsSlider {
                    Layout.fillWidth: true
                    label: ""
                    value: root.prefs ? root.prefs.displayBrightness : 50
                    onUserValueChanged: (newValue) => {
                        if (root.prefs) {
                            root.prefs.displayBrightness = newValue
                        }
                    }
                }
            }

            Components.SettingsCard {
                Layout.fillWidth: true
                title: qsTr("AA Fullscreen Delay", "SettingsPanel")

                Components.SettingsSlider {
                    Layout.fillWidth: true
                    // 0 disables automatic fullscreen to keep current UX unchanged by default.
                    label: qsTr("Set to 0 to disable automatic fullscreen", "SettingsPanel")
                    from: 0
                    to: 30
                    valueSuffix: qsTr("s", "SettingsPanel")
                    value: root.prefs ? root.prefs.aaProjectionFullscreenDelaySeconds : 0
                    onUserValueChanged: (newValue) => {
                        if (root.prefs) {
                            root.prefs.aaProjectionFullscreenDelaySeconds = newValue
                        }
                    }
                }
            }

            Components.SettingsCard {
                Layout.fillWidth: true
                title: qsTr("Theme", "SettingsPanel")

                Components.ThemeToggle {
                    Layout.fillWidth: true
                    showLabel: false
                    currentMode: root.prefs ? root.prefs.themeMode : "DARK"
                    onModeChanged: (newMode) => {
                        if (root.prefs) {
                            root.prefs.themeMode = newMode
                        }
                    }
                }
            }
        }
    }
}
