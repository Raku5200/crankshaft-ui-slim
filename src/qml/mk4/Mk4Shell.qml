import QtQuick
import "."

// MK4-navigation-style native menu shown on top of Android Auto / the
// waiting screen. Navigation, Audio and Telephone return to Android Auto.
//
// Keyboard stands in for the BMBT until IBus input exists:
//   Left/Up, Right/Down = dial · Enter/Space = dial press · Esc/M = MENU
FocusScope {
    id: shell

    property var ibus
    property string page: "menu"
    property bool infoBar: settingsPage.infoBar
    property bool monitorOff: false

    signal closeRequested()
    signal openCrankshaftSettings()

    readonly property var current: page === "computer" ? computerPage
                                   : page === "vehicle" ? vehiclePage
                                   : page === "settings" ? settingsPage
                                   : menuPage

    function open() {
        page = "menu"
        monitorOff = false
        visible = true
        forceActiveFocus()
    }

    function menuButton() {
        if (page === "menu")
            closeRequested()
        else
            page = "menu"
    }

    visible: false

    Keys.onPressed: (event) => {
        if (shell.monitorOff) { shell.monitorOff = false; event.accepted = true; return }
        switch (event.key) {
        case Qt.Key_Left: case Qt.Key_Up: shell.current.dial(-1); break
        case Qt.Key_Right: case Qt.Key_Down: shell.current.dial(1); break
        case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space: shell.current.confirm(); break
        case Qt.Key_Escape: case Qt.Key_M: shell.menuButton(); break
        default: return
        }
        event.accepted = true
    }

    // Swallow touches so nothing reaches Android Auto underneath.
    MouseArea { anchors.fill: parent }

    MenuScreen {
        id: menuPage
        anchors.fill: parent
        visible: shell.page === "menu"
        ibus: shell.ibus
        showMenuButton: true
        onMenuRequested: shell.menuButton()
        onOpenAndroidAuto: (section) => shell.closeRequested()
        onOpenPage: (p) => shell.page = p
    }

    ComputerScreen {
        id: computerPage
        anchors.fill: parent
        visible: shell.page === "computer"
        ibus: shell.ibus
        onMenuRequested: shell.menuButton()
    }

    VehicleScreen {
        id: vehiclePage
        anchors.fill: parent
        visible: shell.page === "vehicle"
        ibus: shell.ibus
        onMenuRequested: shell.menuButton()
    }

    SettingsScreen {
        id: settingsPage
        anchors.fill: parent
        visible: shell.page === "settings"
        ibus: shell.ibus
        onMenuRequested: shell.menuButton()
        onOpenCrankshaftSettings: shell.openCrankshaftSettings()
        onMonitorOff: shell.monitorOff = true
    }

    Rectangle {
        anchors.fill: parent
        visible: shell.monitorOff
        color: "black"
        MouseArea { anchors.fill: parent; onClicked: shell.monitorOff = false }
    }
}
