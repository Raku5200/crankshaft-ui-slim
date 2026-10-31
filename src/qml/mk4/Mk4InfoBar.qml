import QtQuick
import "."

// MK4-style strip shown along the bottom of Android Auto: MENU button, then
// the next turn while navigating, the current song otherwise, or on-board
// computer values when neither is available.
Mk4Bar {
    id: bar

    property var ibus
    signal menuRequested()

    readonly property bool showNavigation: !!ibus && ibus.guiding
    readonly property bool showMedia: !!ibus && !showNavigation && ibus.hasTrack

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

    Item {
        id: middle
        anchors { left: menuBtn.right; leftMargin: 20; right: clock.left; rightMargin: 16
                  top: parent.top; bottom: parent.bottom }

        // --- next turn
        Row {
            visible: bar.showNavigation
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: 12
            readonly property var nav: bar.ibus ? bar.ibus.navigation : ({})

            Text {
                id: turnSymbol
                anchors.verticalCenter: parent.verticalCenter
                text: bar.ibus ? bar.ibus.maneuverSymbol(parent.nav.maneuver, parent.nav.roundaboutExit || 0) : ""
                color: Mk4.active
                font { family: Mk4.font; pixelSize: 28; bold: true }
            }
            Text {
                id: turnDistance
                anchors.verticalCenter: parent.verticalCenter
                text: parent.nav.status === "rerouting" ? "Rerouting" : (parent.nav.distanceText || "")
                color: Mk4.value
                font { family: Mk4.font; pixelSize: 21; bold: true }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - turnSymbol.width - turnDistance.width - eta.width - 3 * parent.spacing
                text: parent.nav.road || parent.nav.currentRoad || ""
                elide: Text.ElideRight
                color: Mk4.title
                font { family: Mk4.font; pixelSize: 19 }
            }
            Text {
                id: eta
                anchors.verticalCenter: parent.verticalCenter
                visible: !!parent.nav.eta
                text: "ETA " + (parent.nav.eta || "")
                color: Mk4.dim
                font { family: Mk4.font; pixelSize: 16 }
            }
        }

        // --- now playing
        Row {
            visible: bar.showMedia
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: 10
            readonly property var np: bar.ibus ? bar.ibus.nowPlaying : ({})

            Text {
                id: note
                anchors.verticalCenter: parent.verticalCenter
                text: parent.np.playing ? "♫" : "‖"
                color: Mk4.active
                font { family: Mk4.font; pixelSize: 22; bold: true }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - note.width - parent.spacing
                text: (parent.np.artist ? parent.np.artist + "  –  " : "") + (parent.np.song || "")
                elide: Text.ElideRight
                color: Mk4.value
                font { family: Mk4.font; pixelSize: 19; bold: true }
            }
        }

        // --- on-board computer values
        Row {
            visible: !bar.showNavigation && !bar.showMedia
            anchors.verticalCenter: parent.verticalCenter
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
    }
}
