import QtQuick
import "."

// MK4-style strip shown along the bottom of Android Auto: MENU button plus
// live on-board computer values.
Mk4Bar {
    id: bar

    property var ibus
    signal menuRequested()

    height: 48

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

    // Touches on the bar itself must not fall through to Android Auto.
    MouseArea { anchors.fill: parent; z: -1 }

    Row {
        anchors { left: menuBtn.right; leftMargin: 22; verticalCenter: parent.verticalCenter }
        spacing: 26
        component Stat: Row {
            property string label; property string value
            spacing: 7
            Text { text: parent.label; color: Mk4.dim; font { family: Mk4.font; pixelSize: 16 }
                anchors.baseline: v.baseline }
            Text { id: v; text: parent.value; color: Mk4.value; font { family: Mk4.font; pixelSize: 21; bold: true } }
        }
        Stat { label: "Range"; value: bar.ibus ? bar.ibus.range + " " + bar.ibus.distanceUnit : "" }
        Stat { label: "Cons."; value: bar.ibus ? bar.ibus.consumption1 : "" }
        Stat { label: "Speed"; value: bar.ibus ? bar.ibus.speedKmh + "" : "" }
        Stat { label: "Out"; value: bar.ibus ? bar.ibus.outsideTemp : "" }
    }

    Text {
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        text: bar.ibus ? bar.ibus.time : ""
        color: Mk4.value
        font { family: Mk4.font; pixelSize: 21; bold: true }
    }
}
