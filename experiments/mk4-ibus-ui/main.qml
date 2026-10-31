import QtQuick
import QtQuick.Window
import "."

// MK4-navigation-style shell for Crankshaft (experiment, not wired into the app).
//
// BMBT emulation on a keyboard:
//   Left / Up      dial left   (IBus F0 04 3B 49 01 ..)
//   Right / Down   dial right  (IBus F0 04 3B 49 81 ..)
//   Enter / Space  dial press  (IBus 0x48 BUTTON_CONFIRM)
//   Esc / M        MENU button (IBus 0x48 BUTTON_MENU) - toggles Android Auto <-> main menu
// Touch works everywhere as well.
Window {
    id: win
    width: 800
    height: 480
    visible: true
    color: "black"
    title: "Crankshaft MK4 UI experiment"

    property string page: "aa"
    property string lastAaSection: "navigation"
    property bool monitorOff: false

    MockIbus { id: ibus }

    Component.onCompleted: page = settingsPage.startInAndroidAuto ? "aa" : "menu"

    readonly property var current: page === "aa" ? aaPage
                                   : page === "computer" ? computerPage
                                   : page === "vehicle" ? vehiclePage
                                   : page === "settings" ? settingsPage
                                   : menuPage

    function menuButton() {
        // MENU from Android Auto opens the main menu; from the main menu it
        // returns to Android Auto; from any sub-page it goes to the main menu.
        page = page === "aa" ? "menu" : (page === "menu" ? "aa" : "menu")
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            if (win.monitorOff) { win.monitorOff = false; event.accepted = true; return }
            switch (event.key) {
            case Qt.Key_Left: case Qt.Key_Up: win.current.dial(-1); break
            case Qt.Key_Right: case Qt.Key_Down: win.current.dial(1); break
            case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space: win.current.confirm(); break
            case Qt.Key_Escape: case Qt.Key_M: win.menuButton(); break
            default: return
            }
            event.accepted = true
        }

        AndroidAutoScreen {
            id: aaPage
            objectName: "aaPage"
            anchors.fill: parent
            visible: win.page === "aa"
            ibus: ibus
            section: win.lastAaSection
            infoBar: settingsPage.infoBar
            onMenuRequested: win.menuButton()
        }

        MenuScreen {
            id: menuPage
            objectName: "menuPage"
            anchors.fill: parent
            visible: win.page === "menu"
            ibus: ibus
            onOpenAndroidAuto: (section) => { win.lastAaSection = section; win.page = "aa" }
            onOpenPage: (p) => win.page = p
        }

        ComputerScreen {
            id: computerPage
            objectName: "computerPage"
            anchors.fill: parent
            visible: win.page === "computer"
            ibus: ibus
            onMenuRequested: win.menuButton()
        }

        VehicleScreen {
            id: vehiclePage
            objectName: "vehiclePage"
            anchors.fill: parent
            visible: win.page === "vehicle"
            ibus: ibus
            onMenuRequested: win.menuButton()
        }

        SettingsScreen {
            id: settingsPage
            objectName: "settingsPage"
            anchors.fill: parent
            visible: win.page === "settings"
            ibus: ibus
            onMenuRequested: win.menuButton()
            onMonitorOff: win.monitorOff = true
        }

        Rectangle {
            anchors.fill: parent
            visible: win.monitorOff
            color: "black"
            MouseArea { anchors.fill: parent; onClicked: win.monitorOff = false }
        }
    }
}
