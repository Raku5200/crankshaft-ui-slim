import QtQuick
import "."

// Info bar along the bottom of Android Auto ("Dock" design): a Menu button,
// the on-board computer values (range, consumption 1 and 2, outside temp)
// and the cluster clock, in the dark rounded look of Android Auto.
// Turn-by-turn and the song are on the instrument cluster (IKE) instead.
// Android Auto keeps its own controls out of this strip: core sends a
// matching bottom content inset (core.android_auto.video.content_inset_bottom).
Rectangle {
    id: bar

    property var ibus
    signal menuRequested()

    readonly property color ground: "#0E1013"
    readonly property color hairline: "#2A2E35"
    readonly property color chip: "#22262C"
    readonly property color chipPressed: "#30353D"
    readonly property color text: "#E8EAED"
    readonly property color dim: "#A6ADB7"
    readonly property color accent: "#8AB4F8"
    readonly property string font: "Inter"

    height: 56
    color: ground

    // Line icons in the accent colour (qml/assets/infobar-*.png, 2x).
    readonly property string gridIcon: "qrc:/qml/assets/infobar-menu.png"
    readonly property string fuelIcon: "qrc:/qml/assets/infobar-range.png"
    readonly property string gaugeIcon: "qrc:/qml/assets/infobar-consumption.png"
    readonly property string tempIcon: "qrc:/qml/assets/infobar-temp.png"

    // Touches on the bar itself must not fall through to Android Auto.
    MouseArea { anchors.fill: parent }

    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 1
        color: bar.hairline
    }

    Rectangle {
        id: menuBtn
        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
        width: menuRow.implicitWidth + 28; height: 44; radius: 22
        color: menuArea.pressed ? bar.chipPressed : bar.chip
        Row {
            id: menuRow
            anchors.centerIn: parent
            spacing: 8
            Image { source: bar.gridIcon; width: 20; height: 20; mipmap: true
                anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Menu"; color: bar.text; anchors.verticalCenter: parent.verticalCenter
                font { family: bar.font; pixelSize: 16; weight: Font.DemiBold } }
        }
        MouseArea { id: menuArea; anchors.fill: parent; anchors.margins: -6; onClicked: bar.menuRequested() }
    }

    Text {
        id: clock
        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        text: bar.ibus ? bar.ibus.time : ""
        color: bar.text
        font { family: bar.font; pixelSize: 24; weight: Font.DemiBold }
    }

    // On-board computer values from the cluster (IBus); "--" until it answers.
    Item {
        anchors { left: menuBtn.right; right: clock.left; top: parent.top; bottom: parent.bottom }
        Row {
            anchors.centerIn: parent
            spacing: 20
            component Stat: Row {
                property string iconSource
                property string badge
                property string value
                property string unit
                spacing: 6
                Image { visible: parent.iconSource !== ""; source: parent.iconSource
                    width: 18; height: 18; mipmap: true
                    anchors.verticalCenter: parent.verticalCenter }
                Rectangle { visible: parent.badge !== ""; width: 16; height: 18; radius: 4
                    color: "transparent"; border { width: 1; color: "#3A3F47" }
                    anchors.verticalCenter: parent.verticalCenter
                    Text { anchors.centerIn: parent; text: parent.parent.badge; color: bar.dim
                        font { family: bar.font; pixelSize: 11; weight: Font.DemiBold } } }
                Text { id: v; text: parent.value; color: bar.text
                    anchors.verticalCenter: parent.verticalCenter
                    font { family: bar.font; pixelSize: 19; weight: Font.DemiBold } }
                Text { text: parent.unit; visible: text !== ""; color: bar.dim
                    anchors.baseline: v.baseline
                    font { family: bar.font; pixelSize: 13 } }
            }
            Stat { iconSource: bar.fuelIcon; value: bar.ibus ? bar.ibus.range : ""
                unit: bar.ibus ? bar.ibus.distanceUnit : "" }
            Stat { iconSource: bar.gaugeIcon; value: bar.ibus ? bar.ibus.consumption1 : ""
                unit: bar.ibus ? bar.ibus.consumptionUnit : "" }
            Stat { badge: "2"; value: bar.ibus ? bar.ibus.consumption2 : ""
                unit: bar.ibus ? bar.ibus.consumption2Unit : "" }
            Stat { iconSource: bar.tempIcon; value: bar.ibus ? bar.ibus.outsideTemp : ""
                unit: bar.ibus ? bar.ibus.temperatureUnit : "" }
        }
    }

    Text {
        anchors { right: parent.right; rightMargin: 14; top: parent.top; topMargin: 2 }
        visible: !!bar.ibus && bar.ibus.demo
        text: "DEMO"; color: bar.dim
        font { family: bar.font; pixelSize: 9; weight: Font.DemiBold; letterSpacing: 1 }
    }
}
