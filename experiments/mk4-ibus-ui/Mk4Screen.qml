import QtQuick
import "."

// One MK4 page: title bar, content area, status bar (time · temp · date).
// Rotary navigation: `focusables` lists the selectable items in dial order.
Item {
    id: screen

    property string title: ""
    property var ibus
    property var focusables: []
    property int focusIndex: 0
    property bool showMenuButton: true
    default property alias content: body.data

    signal menuRequested()

    function dial(steps) {
        if (focusables.length === 0)
            return
        focusIndex = ((focusIndex + steps) % focusables.length + focusables.length) % focusables.length
    }

    function confirm() {
        if (focusables.length > 0)
            focusables[focusIndex].activated()
    }

    function isFocused(item) {
        return focusables.length > 0 && focusables[focusIndex] === item
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Mk4.body }
            GradientStop { position: 1.0; color: Mk4.bodyBottom }
        }
    }

    Mk4Bar {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: Mk4.headerHeight

        Text {
            anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
            text: screen.title
            color: Mk4.title
            font { family: Mk4.font; pixelSize: Mk4.titleSize; bold: true; letterSpacing: 1.5 }
        }

        // Touch shortcut for the BMBT MENU button.
        Rectangle {
            visible: screen.showMenuButton
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            width: 96; height: 34; radius: 3
            color: menuTouch.pressed ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08)
            border { width: 1; color: Mk4.bracket }

            Text {
                anchors.centerIn: parent
                text: "MENU"
                color: Mk4.title
                font { family: Mk4.font; pixelSize: 17; bold: true; letterSpacing: 1 }
            }

            MouseArea {
                id: menuTouch
                anchors.fill: parent
                anchors.margins: -6
                onClicked: screen.menuRequested()
            }
        }
    }

    Item {
        id: body
        anchors {
            left: parent.left; right: parent.right
            top: header.bottom; bottom: footer.top
        }
    }

    Mk4Bar {
        id: footer
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: Mk4.footerHeight

        Text {
            anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
            text: screen.ibus ? screen.ibus.time : ""
            color: Mk4.value
            font { family: Mk4.font; pixelSize: 22; bold: true }
        }
        Text {
            anchors.centerIn: parent
            text: screen.ibus ? screen.ibus.outsideTemp : ""
            color: Mk4.title
            font { family: Mk4.font; pixelSize: 20 }
        }
        Text {
            anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
            text: screen.ibus ? screen.ibus.date : ""
            color: Mk4.value
            font { family: Mk4.font; pixelSize: 22; bold: true }
        }
    }
}
