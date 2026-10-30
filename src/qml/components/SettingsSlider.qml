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
import QtQuick.Controls.Material
import QtQuick.Layouts

/**
 * @brief Reusable slider component for settings with label and value display.
 *
 * Properties:
 * - label: Display text for the setting
 * - value: Current slider value (0-100)
 * - onUserValueChanged: Signal emitted when user adjusts slider
 */
ColumnLayout {
    id: settingsSlider
    spacing: 8
    
    property alias label: labelText.text
    property int value: 50
    property int from: 0
    property int to: 100
    // Units suffix for value label. Keep '%' default for existing sliders.
    property string valueSuffix: "%"
    
    signal userValueChanged(int newValue)
    
    Label {
        id: labelText
        Layout.fillWidth: true
        visible: text !== ""
        color: settingsSlider.Material.foreground
        opacity: 0.75
        font.pointSize: 10
        wrapMode: Text.WordWrap
    }
    
    RowLayout {
        Layout.fillWidth: true
        spacing: 16
        
        Slider {
            Layout.fillWidth: true
            from: settingsSlider.from
            to: settingsSlider.to
            stepSize: 1
            value: settingsSlider.value
            
            onMoved: {
                const newValue = Math.round(value)
                settingsSlider.value = newValue
                settingsSlider.userValueChanged(newValue)
            }
        }
        
        Label {
            text: settingsSlider.value + settingsSlider.valueSuffix
            // Explicit theme colour: the inherited default rendered black on
            // the dark settings panel.
            color: settingsSlider.Material.foreground
            font.pointSize: 13
            font.bold: true
            Layout.minimumWidth: 52
            horizontalAlignment: Text.AlignRight
        }
    }
}
