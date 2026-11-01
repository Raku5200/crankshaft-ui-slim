/*
 * Project: Crankshaft
 * This file is part of Crankshaft project.
 * Copyright (C) 2025 OpenCarDev Team
 *
 *  Crankshaft is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Crankshaft is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Crankshaft. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * @brief Reusable toggle component for connection preference (USB/Wireless).
 *
 * Properties:
 * - currentPreference: Current connection preference ("AUTO", "USB" or "WIRELESS")
 * - onPreferenceChanged: Signal emitted when user selects a connection type
 */
ColumnLayout {
    id: connectionToggle
    spacing: 8
    width: parent ? parent.width : implicitWidth
    
    property string currentPreference: "AUTO"
    // Keep optional so parent cards can provide the section title without duplicates.
    property bool showLabel: true
    property string titleText: qsTr("Connection Preference", "ConnectionPreferenceToggle")
    
    signal preferenceChanged(string newPreference)

    ButtonGroup {
        id: connectionPreferenceGroup
        exclusive: true
    }
    
    Label {
        visible: connectionToggle.showLabel
        text: connectionToggle.titleText
        font.pointSize: 12
        font.bold: true
    }
    
    RowLayout {
        Layout.fillWidth: true
        spacing: 16
        
        SegmentedOptionButton {
            // Looks for a USB phone and a wireless phone at the same time.
            baseText: qsTr("Auto", "ConnectionPreferenceToggle")
            Layout.fillWidth: true
            Layout.preferredWidth: 1  // equal split regardless of label length
            Layout.preferredHeight: 46
            ButtonGroup.group: connectionPreferenceGroup
            checked: connectionToggle.currentPreference === "AUTO"

            onClicked: {
                if (checked) {
                    connectionToggle.currentPreference = "AUTO"
                    connectionToggle.preferenceChanged("AUTO")
                }
            }
        }

        SegmentedOptionButton {
            baseText: qsTr("USB", "ConnectionPreferenceToggle")
            Layout.fillWidth: true
            Layout.preferredWidth: 1  // equal split regardless of label length
            Layout.preferredHeight: 46
            ButtonGroup.group: connectionPreferenceGroup
            checked: connectionToggle.currentPreference === "USB"
            
            onClicked: {
                if (checked) {
                    connectionToggle.currentPreference = "USB"
                    connectionToggle.preferenceChanged("USB")
                }
            }
        }
        
        SegmentedOptionButton {
            baseText: qsTr("Wireless", "ConnectionPreferenceToggle")
            Layout.fillWidth: true
            Layout.preferredWidth: 1  // equal split regardless of label length
            Layout.preferredHeight: 46
            ButtonGroup.group: connectionPreferenceGroup
            checked: connectionToggle.currentPreference === "WIRELESS"
            
            onClicked: {
                if (checked) {
                    connectionToggle.currentPreference = "WIRELESS"
                    connectionToggle.preferenceChanged("WIRELESS")
                }
            }
        }
    }
}
