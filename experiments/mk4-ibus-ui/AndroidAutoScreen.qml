import QtQuick
import "."

// Where the real AAProjectionView will sit. The content here is only a
// stand-in so the layout and switching can be judged.
Item {
    id: aa

    property var ibus
    property string section: "navigation"
    property bool infoBar: true
    signal menuRequested()

    // In the real build these go to Android Auto as rotary-controller events.
    function dial(steps) { console.log("[aa] rotary", steps) }
    function confirm() { console.log("[aa] rotary press") }

    Rectangle { anchors.fill: parent; color: "#1b2029" }

    Item {
        id: projection
        anchors { left: parent.left; right: parent.right; top: parent.top }
        anchors.bottom: aa.infoBar ? bar.top : parent.bottom

        // --- navigation placeholder: abstract street grid + route
        Canvas {
            id: map
            anchors.fill: parent
            visible: aa.section === "navigation"
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const c = getContext("2d"), w = width, h = height
                c.fillStyle = "#222833"; c.fillRect(0, 0, w, h)
                c.fillStyle = "#1c3a2c"; c.fillRect(w * 0.62, h * 0.08, w * 0.22, h * 0.3)   // park
                c.fillStyle = "#1d3550"; c.beginPath()                                      // water
                c.moveTo(0, h * 0.78); c.quadraticCurveTo(w * 0.3, h * 0.66, w * 0.45, h); c.lineTo(0, h); c.fill()
                c.strokeStyle = "#3a4250"; c.lineWidth = 6
                for (let x = -40; x < w; x += 120) { c.beginPath(); c.moveTo(x, 0); c.lineTo(x + 70, h); c.stroke() }
                for (let y = 30; y < h; y += 95) { c.beginPath(); c.moveTo(0, y); c.lineTo(w, y - 40); c.stroke() }
                c.strokeStyle = "#5a6474"; c.lineWidth = 12
                c.beginPath(); c.moveTo(0, h * 0.55); c.lineTo(w, h * 0.38); c.stroke()
                c.strokeStyle = Mk4.route; c.lineWidth = 10; c.lineCap = "round"; c.lineJoin = "round"
                c.beginPath(); c.moveTo(w * 0.5, h); c.lineTo(w * 0.52, h * 0.47); c.lineTo(w * 0.86, h * 0.41); c.stroke()
                c.fillStyle = "#ffffff"; c.beginPath()                                      // own position
                c.moveTo(w * 0.5, h - 64); c.lineTo(w * 0.5 + 15, h - 26); c.lineTo(w * 0.5, h - 34); c.lineTo(w * 0.5 - 15, h - 26); c.fill()
            }
        }

        Rectangle {
            visible: aa.section === "navigation"
            x: 14; y: 14; width: 250; height: 86; radius: 8
            color: "#0f5c3e"
            Text { x: 16; y: 10; text: "↱"; color: "white"; font { family: Mk4.font; pixelSize: 46; bold: true } }
            Text { x: 78; y: 14; text: "300 m"; color: "white"; font { family: Mk4.font; pixelSize: 24; bold: true } }
            Text { x: 78; y: 48; text: "Galle Road"; color: "#d6efe3"; font { family: Mk4.font; pixelSize: 18 } }
        }

        // --- media placeholder
        Row {
            visible: aa.section === "media"
            anchors.centerIn: parent
            spacing: 28
            Rectangle { width: 170; height: 170; radius: 10
                gradient: Gradient { GradientStop { position: 0; color: "#7a4bd1" } GradientStop { position: 1; color: "#d1503a" } } }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Text { text: "Track title"; color: "white"; font { family: Mk4.font; pixelSize: 30; bold: true } }
                Text { text: "Artist · Album"; color: "#aab3c5"; font { family: Mk4.font; pixelSize: 20 } }
                Text { text: "⏮     ⏸     ⏭"; color: "white"; font { family: Mk4.font; pixelSize: 34 } }
            }
        }

        // --- phone placeholder
        Column {
            visible: aa.section === "phone"
            anchors.centerIn: parent
            spacing: 14
            Repeater {
                model: ["Recent call 1", "Recent call 2", "Recent call 3"]
                Rectangle { width: 380; height: 58; radius: 8; color: "#2a3140"
                    Text { anchors.verticalCenter: parent.verticalCenter; x: 18; text: modelData
                        color: "white"; font { family: Mk4.font; pixelSize: 22 } } }
            }
        }

        Text {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 10 }
            text: "Android Auto projection (placeholder)"
            color: Qt.rgba(1, 1, 1, 0.35)
            font { family: Mk4.font; pixelSize: 14 }
        }

        // Floating MENU tab when the info bar is hidden.
        Rectangle {
            visible: !aa.infoBar
            anchors { right: parent.right; top: parent.top; margins: 10 }
            width: 88; height: 40; radius: 4
            color: Qt.rgba(0.05, 0.07, 0.14, 0.75)
            border { width: 1; color: Mk4.bracket }
            Text { anchors.centerIn: parent; text: "MENU"; color: Mk4.title
                font { family: Mk4.font; pixelSize: 17; bold: true; letterSpacing: 1 } }
            MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: aa.menuRequested() }
        }
    }

    // MK4-style strip with live OBC data underneath Android Auto.
    Mk4Bar {
        id: bar
        visible: aa.infoBar
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 48

        Rectangle {
            id: menuBtn
            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
            width: 92; height: 36; radius: 3
            color: menuArea.pressed ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08)
            border { width: 1; color: Mk4.bracket }
            Text { anchors.centerIn: parent; text: "MENU"; color: Mk4.title
                font { family: Mk4.font; pixelSize: 17; bold: true; letterSpacing: 1 } }
            MouseArea { id: menuArea; anchors.fill: parent; anchors.margins: -6; onClicked: aa.menuRequested() }
        }

        Row {
            anchors { left: menuBtn.right; leftMargin: 22; right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
            spacing: 26
            component Stat: Row {
                property string label; property string value
                spacing: 7
                Text { text: parent.label; color: Mk4.dim; font { family: Mk4.font; pixelSize: 16 }
                    anchors.baseline: v.baseline }
                Text { id: v; text: parent.value; color: Mk4.value; font { family: Mk4.font; pixelSize: 21; bold: true } }
            }
            Stat { label: "Range"; value: aa.ibus.range + " " + aa.ibus.distanceUnit }
            Stat { label: "Cons."; value: aa.ibus.consumption1 }
            Stat { label: "Speed"; value: aa.ibus.speedKmh + "" }
            Stat { label: "Out"; value: aa.ibus.outsideTemp }
        }

        Text {
            anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
            text: aa.ibus.time
            color: Mk4.value
            font { family: Mk4.font; pixelSize: 21; bold: true }
        }
    }
}
