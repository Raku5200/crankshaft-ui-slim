import QtQuick
import "."

Mk4Screen {
    id: menu
    title: "MAIN MENU"
    showMenuButton: false

    signal openAndroidAuto(string section)
    signal openPage(string page)

    focusables: [nav, audio, phone, computer, vehicle, settings]

    Row {
        anchors.fill: parent
        anchors.margins: 18
        anchors.topMargin: 26
        anchors.bottomMargin: 26
        spacing: 16

        Mk4Group {
            width: (parent.width - parent.spacing) / 2
            height: parent.height
            rightBracket: false

            Column {
                anchors.fill: parent
                Mk4Item { id: nav; screen: menu; width: parent.width; height: parent.height / 3
                    label: "Navigation"; unit: "Android Auto"
                    onActivated: menu.openAndroidAuto("navigation") }
                Mk4Item { id: audio; screen: menu; width: parent.width; height: parent.height / 3
                    label: "Audio"; unit: "Android Auto"
                    onActivated: menu.openAndroidAuto("media") }
                Mk4Item { id: phone; screen: menu; width: parent.width; height: parent.height / 3
                    label: "Telephone"; unit: "Android Auto"
                    onActivated: menu.openAndroidAuto("phone") }
            }
        }

        Mk4Group {
            width: (parent.width - parent.spacing) / 2
            height: parent.height
            leftBracket: false

            Column {
                anchors.fill: parent
                Mk4Item { id: computer; screen: menu; width: parent.width; height: parent.height / 3
                    label: "Computer"; value: "›"
                    onActivated: menu.openPage("computer") }
                Mk4Item { id: vehicle; screen: menu; width: parent.width; height: parent.height / 3
                    label: "Vehicle data"; value: "›"
                    onActivated: menu.openPage("vehicle") }
                Mk4Item { id: settings; screen: menu; width: parent.width; height: parent.height / 3
                    label: "Settings"; value: "›"
                    onActivated: menu.openPage("settings") }
            }
        }
    }
}
