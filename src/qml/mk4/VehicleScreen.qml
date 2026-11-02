import QtQuick
import "."

// Live data broadcast by the cluster: 0x18 speed/RPM, 0x19 temperatures, 0x17 odometer.
Mk4Screen {
    id: veh
    title: "VEHICLE DATA"

    component Gauge: Item {
        property string label
        property string value
        property string unit
        property real fraction: 0
        property color barColor: Mk4.route

        Text {
            id: l
            text: parent.label
            color: Mk4.dim
            font { family: Mk4.font; pixelSize: 19; letterSpacing: 1 }
        }
        Row {
            anchors { top: l.bottom; topMargin: 2 }
            spacing: 8
            Text {
                text: parent.parent.value
                color: Mk4.value
                font { family: Mk4.font; pixelSize: 58; bold: true }
            }
            Text {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 12
                text: parent.parent.unit
                color: Mk4.dim
                font { family: Mk4.font; pixelSize: 19 }
            }
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 10
            color: "#1e2442"
            border { width: 1; color: "#2c3459" }
            Rectangle {
                width: Math.max(0, Math.min(1, parent.parent.fraction)) * parent.width
                height: parent.height
                color: parent.parent.barColor
                Behavior on width { NumberAnimation { duration: 450 } }
            }
        }
    }

    Mk4Group {
        id: left
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        anchors.margins: 12; anchors.topMargin: 16; anchors.bottomMargin: 16
        width: parent.width * 0.5
        rightBracket: false

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 14
            Gauge { width: parent.width; height: (parent.height - 14) / 2
                label: "SPEED"; value: veh.ibus.speedKmh; unit: veh.ibus.speedUnit
                fraction: veh.ibus.speedKmh / 240 }
            Gauge { width: parent.width; height: (parent.height - 14) / 2
                label: "ENGINE"; value: veh.ibus.rpm; unit: "rpm"
                fraction: veh.ibus.rpm / 7000
                barColor: veh.ibus.rpm > 6000 ? Mk4.focus : Mk4.route }
        }
    }

    Mk4Group {
        anchors { left: left.right; right: parent.right; top: parent.top; bottom: parent.bottom }
        anchors.margins: 12; anchors.topMargin: 16; anchors.bottomMargin: 16
        anchors.leftMargin: 8
        leftBracket: false

        Column {
            anchors.fill: parent
            Mk4Item { screen: veh; selectable: false; width: parent.width; height: parent.height / 4
                label: "Coolant"; value: veh.ibus.shown(veh.ibus.coolantC) + "°"; unit: "C" }
            Mk4Item { screen: veh; selectable: false; width: parent.width; height: parent.height / 4
                label: "Outside"; value: veh.ibus.shown(veh.ibus.ambientC) + "°"; unit: "C" }
            Mk4Item { screen: veh; selectable: false; width: parent.width; height: parent.height / 4
                label: "Odometer"; value: veh.ibus.odometerKm > -999 ? veh.ibus.odometerKm.toLocaleString(Qt.locale("en_US"), "f", 0) : "--"
                unit: veh.ibus.distanceUnit }

            // What the instrument cluster's 20-character display will show
            // (navigation turn, or the scrolling song), as computed by core.
            Item {
                width: parent.width; height: parent.height / 4
                Text {
                    anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                    text: "Cluster"
                    color: Mk4.label
                    font { family: Mk4.font; pixelSize: Mk4.labelSize; letterSpacing: 0.5 }
                }
                Rectangle {
                    anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    width: 20 * 10 + 16; height: 34; radius: 2
                    color: "#1a0705"
                    border { width: 1; color: "#4a1a12" }
                    Text {
                        // Left-aligned like the IKE: core pads the line to 20
                        // characters so the arrow and distance never move.
                        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                        horizontalAlignment: Text.AlignLeft
                        textFormat: Text.PlainText
                        readonly property string line: veh.ibus.clusterText.line || ""
                        text: line !== "" ? line : "-- no text --"
                        color: line !== "" ? "#ff5a36" : "#6b2a1e"
                        font { family: "DejaVu Sans Mono"; pixelSize: 16; bold: true }
                    }
                }
            }
        }
    }
}
