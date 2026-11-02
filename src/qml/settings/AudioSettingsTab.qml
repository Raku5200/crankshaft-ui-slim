/*
 * Project: Crankshaft
 * Audio settings tab content: where Android Auto audio plays, which sound
 * output this unit uses, and the volume.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import "../components" as Components

Item {
    id: root

    required property var preferencesFacade
    // AudioOutputManager (_audioOutputs); may be undefined in tests/previews.
    property var audioOutputs: typeof _audioOutputs !== "undefined" ? _audioOutputs : null

    readonly property bool audioOnPhone: root.preferencesFacade
                                         && root.preferencesFacade.audioOutputTarget === "PHONE"

    // Re-read the outputs each time the tab is shown (a USB or Bluetooth
    // device may have been connected since).
    onVisibleChanged: if (visible && root.audioOutputs) root.audioOutputs.refresh()

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
                title: qsTr("Play Android Auto audio on", "SettingsPanel")

                ButtonGroup { id: targetGroup }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Components.SegmentedOptionButton {
                        baseText: qsTr("This unit", "SettingsPanel")
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 46
                        ButtonGroup.group: targetGroup
                        checked: !root.audioOnPhone
                        onClicked: if (root.preferencesFacade) root.preferencesFacade.audioOutputTarget = "HEAD_UNIT"
                    }

                    Components.SegmentedOptionButton {
                        baseText: qsTr("Phone", "SettingsPanel")
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 46
                        ButtonGroup.group: targetGroup
                        checked: root.audioOnPhone
                        onClicked: if (root.preferencesFacade) root.preferencesFacade.audioOutputTarget = "PHONE"
                    }
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.7
                    font.pointSize: 10
                    text: root.audioOnPhone
                          ? qsTr("The phone plays music and navigation prompts itself: its own speaker, or a Bluetooth device it is connected to. Short system sounds still play here. Android Auto reconnects to apply.", "SettingsPanel")
                          : qsTr("Music, navigation prompts and system sounds play through this unit. Android Auto reconnects to apply.", "SettingsPanel")
                }
            }

            Components.SettingsCard {
                Layout.fillWidth: true
                title: qsTr("Sound output", "SettingsPanel")
                enabled: !root.audioOnPhone
                opacity: enabled ? 1.0 : 0.5

                ButtonGroup { id: outputGroup }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8
                    visible: outputRepeater.count > 0

                    Repeater {
                        id: outputRepeater
                        model: root.audioOutputs ? root.audioOutputs.outputs : []

                        delegate: Components.SegmentedOptionButton {
                            required property var modelData
                            baseText: modelData.label
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 46
                            ButtonGroup.group: outputGroup
                            checked: root.audioOutputs && root.audioOutputs.currentOutput === modelData.name
                            onClicked: if (root.audioOutputs) root.audioOutputs.selectOutput(modelData.name)
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    visible: outputRepeater.count === 0
                    wrapMode: Text.WordWrap
                    opacity: 0.7
                    text: root.audioOutputs && root.audioOutputs.available
                          ? qsTr("No sound outputs found.", "SettingsPanel")
                          : qsTr("Waiting for the sound system...", "SettingsPanel")
                }

                Button {
                    text: qsTr("Refresh", "SettingsPanel")
                    flat: true
                    onClicked: if (root.audioOutputs) root.audioOutputs.refresh()
                }
            }

            Components.SettingsCard {
                Layout.fillWidth: true
                title: qsTr("Volume", "SettingsPanel")
                enabled: !root.audioOnPhone
                opacity: enabled ? 1.0 : 0.5

                Components.SettingsSlider {
                    Layout.fillWidth: true
                    label: ""
                    value: root.preferencesFacade ? root.preferencesFacade.audioVolume : 50
                    onUserValueChanged: (newValue) => {
                        if (root.preferencesFacade) {
                            root.preferencesFacade.audioVolume = newValue
                        }
                    }
                }
            }
        }
    }
}
