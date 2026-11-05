/*
 * Project: Crankshaft
 * Car (IBus) settings tab: interface status, OBC polling and which of the
 * car's controls Crankshaft uses.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import "../components" as Components

Item {
    id: root

    required property var preferencesFacade
    // IbusFacade (_ibus); may be undefined in previews.
    property var ibus: typeof _ibus !== "undefined" ? _ibus : null
    // SystemFacade (_system): save logs to the SD card.
    property var system: typeof _system !== "undefined" ? _system : null

    component ToggleRow: RowLayout {
        id: row
        property string title
        property string note
        property bool checked
        signal toggled(bool checked)
        Layout.fillWidth: true
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Label { Layout.fillWidth: true; text: row.title; font.pointSize: 11; wrapMode: Text.WordWrap }
            Label { Layout.fillWidth: true; text: row.note; font.pointSize: 9; opacity: 0.7
                    wrapMode: Text.WordWrap; visible: text !== "" }
        }
        Switch {
            checked: row.checked
            onToggled: row.toggled(checked)
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: column
            width: parent.width
            spacing: 12

            Components.SettingsCard {
                Layout.fillWidth: true
                title: qsTr("IBus interface", "SettingsPanel")

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: !root.ibus || !root.ibus.connected
                          ? qsTr("Not connected. Plug in the Resler (or other USB) IBus interface.", "SettingsPanel")
                          : root.ibus.busAwake
                            ? qsTr("Connected, car bus active (%1)", "SettingsPanel").arg(root.ibus.status.device || "")
                            : qsTr("Connected, car bus asleep (%1)", "SettingsPanel").arg(root.ibus.status.device || "")
                }
            }

            Components.SettingsCard {
                Layout.fillWidth: true
                title: qsTr("On-board computer", "SettingsPanel")

                ToggleRow {
                    title: qsTr("Ask the cluster for OBC values every 10 s", "SettingsPanel")
                    note: qsTr("Leave off when the car's own OBC or monitor already asks: Crankshaft then only listens and adds no bus traffic.", "SettingsPanel")
                    checked: root.preferencesFacade && root.preferencesFacade.ibusPollObc
                    onToggled: (on) => { if (root.preferencesFacade) root.preferencesFacade.ibusPollObc = on }
                }
            }

            Components.SettingsCard {
                Layout.fillWidth: true
                title: qsTr("Instrument cluster", "SettingsPanel")

                ToggleRow {
                    title: qsTr("Show song and navigation on the cluster", "SettingsPanel")
                    note: qsTr("Press BC on the stalk to show OBC values instead: the text then waits for the next song or turn.", "SettingsPanel")
                    checked: root.preferencesFacade && root.preferencesFacade.ibusClusterText
                    onToggled: (on) => { if (root.preferencesFacade) root.preferencesFacade.ibusClusterText = on }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: !!root.ibus && root.ibus.status.clusterTextPaused === true
                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: qsTr("The cluster is showing OBC values until the next song or turn.", "SettingsPanel")
                    }
                    Button {
                        text: qsTr("Show again", "SettingsPanel")
                        onClicked: root.ibus.resumeClusterText()
                    }
                }
            }

            Components.SettingsCard {
                Layout.fillWidth: true
                title: qsTr("Parking sensors", "SettingsPanel")

                ToggleRow {
                    title: qsTr("Show parking sensors when reversing", "SettingsPanel")
                    note: qsTr("Opens over Android Auto in reverse (or when PDC switches on) and asks the PDC module for distances only then.", "SettingsPanel")
                    checked: root.preferencesFacade && root.preferencesFacade.ibusParkingSensors
                    onToggled: (on) => { if (root.preferencesFacade) root.preferencesFacade.ibusParkingSensors = on }
                }
            }

            Components.SettingsCard {
                Layout.fillWidth: true
                title: qsTr("Car controls", "SettingsPanel")

                ToggleRow {
                    title: qsTr("Use on-board monitor buttons and dial", "SettingsPanel")
                    note: qsTr("MENU opens the Crankshaft menu; the dial and its press control Android Auto and the menu.", "SettingsPanel")
                    checked: root.preferencesFacade && root.preferencesFacade.ibusBmbtInput
                    onToggled: (on) => { if (root.preferencesFacade) root.preferencesFacade.ibusBmbtInput = on }
                }

                ToggleRow {
                    title: qsTr("Use steering wheel buttons", "SettingsPanel")
                    note: qsTr("Next/previous track and the telephone button (voice) in Android Auto.", "SettingsPanel")
                    checked: root.preferencesFacade && root.preferencesFacade.ibusMflInput
                    onToggled: (on) => { if (root.preferencesFacade) root.preferencesFacade.ibusMflInput = on }
                }
            }

            Components.SettingsCard {
                Layout.fillWidth: true
                title: qsTr("Troubleshooting", "SettingsPanel")

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Save logs to the SD card", "SettingsPanel")
                            font.pointSize: 11
                            wrapMode: Text.WordWrap
                        }
                        Label {
                            Layout.fillWidth: true
                            font.pointSize: 9
                            opacity: 0.7
                            wrapMode: Text.WordWrap
                            text: {
                                const s = root.system ? root.system.logSaveState : ""
                                if (s === "saving") return qsTr("Saving…", "SettingsPanel")
                                if (s === "done") return qsTr("Saved to %1 on the SD card's boot partition. Put the card in a PC to read them.", "SettingsPanel").arg(root.system.logSaveMessage)
                                if (s === "error") return qsTr("Could not save: %1", "SettingsPanel").arg(root.system.logSaveMessage)
                                return qsTr("Copies the logs to a crankshaft-logs folder you can open on any PC.", "SettingsPanel")
                            }
                        }
                    }
                    Button {
                        text: qsTr("Save logs", "SettingsPanel")
                        enabled: !!root.system && root.system.logSaveState !== "saving"
                        onClicked: root.system.saveLogs()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Restart the head unit", "SettingsPanel")
                            font.pointSize: 11
                            wrapMode: Text.WordWrap
                        }
                        Label {
                            Layout.fillWidth: true
                            font.pointSize: 9
                            opacity: 0.7
                            wrapMode: Text.WordWrap
                            text: restartButton.armed
                                  ? qsTr("Press Restart again to confirm.", "SettingsPanel")
                                  : qsTr("Reboots the Pi. Android Auto reconnects by itself after about 45 seconds.", "SettingsPanel")
                        }
                    }
                    Button {
                        id: restartButton
                        property bool armed: false
                        text: armed ? qsTr("Confirm", "SettingsPanel") : qsTr("Restart", "SettingsPanel")
                        enabled: !!root.system
                        onClicked: {
                            if (armed) {
                                armed = false
                                root.system.restartSystem()
                            } else {
                                armed = true
                                restartDisarm.restart()
                            }
                        }
                        Timer { id: restartDisarm; interval: 4000; onTriggered: restartButton.armed = false }
                    }
                }
            }
        }
    }
}
