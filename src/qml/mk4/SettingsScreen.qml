import QtQuick
import "."

Mk4Screen {
    id: set
    title: "SETTINGS"

    property bool infoBar: true
    signal openCrankshaftSettings()
    signal monitorOff()
    signal restartRequested()

    // Restart needs a second press within 4 s so a stray tap or dial press
    // can't reboot the car's head unit.
    property bool restartArmed: false
    Timer { id: disarm; interval: 4000; onTriggered: set.restartArmed = false }
    onVisibleChanged: if (!visible) restartArmed = false

    focusables: [bar, crank, off, restart]

    Mk4Group {
        anchors.fill: parent
        anchors.margins: 18; anchors.topMargin: 26; anchors.bottomMargin: 26

        Column {
            anchors.fill: parent
            Mk4Item { id: bar; screen: set; width: parent.width; height: parent.height / 4
                label: "Info bar in Android Auto"; value: set.infoBar ? "On" : "Off"
                highlighted: set.infoBar
                onActivated: set.infoBar = !set.infoBar }
            Mk4Item { id: crank; screen: set; width: parent.width; height: parent.height / 4
                label: "Crankshaft settings"; unit: "display, audio, connection"; value: ""
                onActivated: set.openCrankshaftSettings() }
            Mk4Item { id: off; screen: set; width: parent.width; height: parent.height / 4
                label: "Monitor off"; value: "›"
                onActivated: set.monitorOff() }
            Mk4Item { id: restart; screen: set; width: parent.width; height: parent.height / 4
                label: "Restart system"
                value: set.restartArmed ? "Press again" : "›"
                highlighted: set.restartArmed
                onActivated: {
                    if (set.restartArmed) {
                        set.restartArmed = false
                        set.restartRequested()
                    } else {
                        set.restartArmed = true
                        disarm.restart()
                    }
                } }
        }
    }
}
