import QtQuick
import "."

// MK4-style strip shown along the bottom of Android Auto: MENU button, the
// on-board computer values (range, consumption, average speed, outside
// temperature) and the cluster clock. Turn-by-turn and the song are on the
// instrument cluster (IKE) instead.
Mk4Bar {
    id: bar

    property var ibus
    signal menuRequested()

    height: 48

    // Touches on the bar itself must not fall through to Android Auto.
    MouseArea { anchors.fill: parent }

    Rectangle {
        id: menuBtn
        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
        width: 92; height: 36; radius: 3
        color: menuArea.pressed ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08)
        border { width: 1; color: Mk4.bracket }
        Text { anchors.centerIn: parent; text: "MENU"; color: Mk4.title
            font { family: Mk4.font; pixelSize: 17; bold: true; letterSpacing: 1 } }
        MouseArea { id: menuArea; anchors.fill: parent; anchors.margins: -6; onClicked: bar.menuRequested() }
    }

    Text {
        id: clock
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        text: bar.ibus ? bar.ibus.time : ""
        color: Mk4.value
        font { family: Mk4.font; pixelSize: 21; bold: true }
    }

    // On-board computer values from the cluster (IBus); "--" until it answers.
    Row {
        id: middle
        anchors { left: menuBtn.right; leftMargin: 18; verticalCenter: parent.verticalCenter }
        spacing: 18
        component Stat: Row {
            property string label; property string value; property string unit
            spacing: 5
            Text { text: parent.label; color: Mk4.dim; font { family: Mk4.font; pixelSize: 15 }
                anchors.baseline: v.baseline }
            Text { id: v; text: parent.value; color: Mk4.value; font { family: Mk4.font; pixelSize: 21; bold: true } }
            Text { text: parent.unit; visible: text !== ""; color: Mk4.dim; font { family: Mk4.font; pixelSize: 12 }
                anchors.baseline: v.baseline }
        }
        Stat { label: "Range"; value: bar.ibus ? bar.ibus.range : ""; unit: bar.ibus ? bar.ibus.distanceUnit : "" }
        Stat { label: "Cons."; value: bar.ibus ? bar.ibus.consumption1 : ""; unit: bar.ibus ? bar.ibus.consumptionUnit : "" }
        Stat { label: "Avg"; value: bar.ibus ? bar.ibus.avgSpeed : ""; unit: bar.ibus ? bar.ibus.speedUnit : "" }
        Stat { label: "Out"; value: bar.ibus ? bar.ibus.outsideTemp : ""; unit: bar.ibus ? bar.ibus.temperatureUnit : "" }
    }

    Text {
        anchors { right: parent.right; rightMargin: 16; top: parent.top; topMargin: 1 }
        visible: !!bar.ibus && bar.ibus.demo
        text: "DEMO"; color: Mk4.dim
        font { family: Mk4.font; pixelSize: 10; bold: true; letterSpacing: 1 }
    }
}
