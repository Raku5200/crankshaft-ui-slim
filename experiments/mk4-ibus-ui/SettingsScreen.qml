import QtQuick
import "."

Mk4Screen {
    id: set
    title: "SETTINGS"

    property bool infoBar: true
    property bool startInAndroidAuto: true
    signal monitorOff()

    focusables: [bar, start, off]

    Mk4Group {
        anchors.fill: parent
        anchors.margins: 18; anchors.topMargin: 26; anchors.bottomMargin: 26

        Column {
            anchors.fill: parent
            Mk4Item { id: bar; screen: set; width: parent.width; height: parent.height / 3
                label: "Info bar in Android Auto"; value: set.infoBar ? "On" : "Off"
                highlighted: set.infoBar
                onActivated: set.infoBar = !set.infoBar }
            Mk4Item { id: start; screen: set; width: parent.width; height: parent.height / 3
                label: "Start screen"; value: set.startInAndroidAuto ? "Android Auto" : "Main menu"
                onActivated: set.startInAndroidAuto = !set.startInAndroidAuto }
            Mk4Item { id: off; screen: set; width: parent.width; height: parent.height / 3
                label: "Monitor off"; value: "›"
                onActivated: set.monitorOff() }
        }
    }
}
