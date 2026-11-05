import QtQuick
import "."

// Info bar along the bottom of Android Auto ("Dock" design): the on-board
// computer values (range, consumption 1 and 2, average speed, outside temp)
// in the dark rounded look of Android Auto. Touching anywhere on the bar
// opens the Crankshaft menu. Turn-by-turn and the song are on the instrument
// cluster (IKE) instead. Android Auto keeps its own controls out of this
// strip: core sends a matching bottom content inset
// (core.android_auto.video.content_inset_bottom).
Rectangle {
    id: bar

    property var ibus
    signal menuRequested()

    readonly property color ground: "#0E1013"
    readonly property color groundPressed: "#1C2026"
    readonly property color hairline: "#2A2E35"
    readonly property color text: "#E8EAED"
    readonly property color dim: "#A6ADB7"
    readonly property string font: "Inter"

    height: 56
    color: touch.pressed ? groundPressed : ground

    // The whole bar is the menu button; touches never fall through to
    // Android Auto.
    MouseArea { id: touch; anchors.fill: parent; onClicked: bar.menuRequested() }

    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 1
        color: bar.hairline
    }

    // On-board computer values from the cluster (IBus); "--" until it answers.
    Row {
        anchors.centerIn: parent
        spacing: 22
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
                font { family: bar.font; pixelSize: 20; weight: Font.DemiBold } }
            Text { text: parent.unit; visible: text !== ""; color: bar.dim
                anchors.baseline: v.baseline
                font { family: bar.font; pixelSize: 13 } }
        }
        Stat { iconSource: "qrc:/qml/assets/infobar-range.png"
            value: bar.ibus ? bar.ibus.range : ""; unit: bar.ibus ? bar.ibus.distanceUnit : "" }
        Stat { iconSource: "qrc:/qml/assets/infobar-consumption.png"
            value: bar.ibus ? bar.ibus.consumption1 : ""; unit: bar.ibus ? bar.ibus.consumptionUnit : "" }
        Stat { badge: "2"
            value: bar.ibus ? bar.ibus.consumption2 : ""; unit: bar.ibus ? bar.ibus.consumption2Unit : "" }
        Stat { iconSource: "qrc:/qml/assets/infobar-speed.png"
            value: bar.ibus ? bar.ibus.avgSpeed : ""; unit: bar.ibus ? bar.ibus.speedUnit : "" }
        Stat { iconSource: "qrc:/qml/assets/infobar-temp.png"
            value: bar.ibus ? bar.ibus.outsideTemp : ""; unit: bar.ibus ? bar.ibus.temperatureUnit : "" }
    }

    Text {
        anchors { right: parent.right; rightMargin: 10; top: parent.top; topMargin: 3 }
        visible: !!bar.ibus && bar.ibus.demo
        text: "DEMO"; color: bar.dim
        font { family: bar.font; pixelSize: 9; weight: Font.DemiBold; letterSpacing: 1 }
    }
}
