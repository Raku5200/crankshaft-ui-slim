import QtQuick
import "."

// On-board computer, laid out like the MK4 "COMPUTER" page.
// Values come from IKE 0x24; selecting an item sends GT 0x41 OBC Control.
Mk4Screen {
    id: obc
    title: "COMPUTER"

    focusables: [cons1, cons2, avg, limitItem, dist, timerItem]

    // Read-only header rows (not selectable on the original either).
    Grid {
        id: info
        anchors { left: parent.left; right: parent.right; top: parent.top }
        anchors.leftMargin: 26; anchors.rightMargin: 26; anchors.topMargin: 8
        columns: 2
        columnSpacing: 40
        Mk4Item { screen: obc; selectable: false; width: (info.width - 40) / 2; height: 46
            label: "Range"; value: obc.ibus.range; unit: obc.ibus.distanceUnit }
        Mk4Item { screen: obc; selectable: false; width: (info.width - 40) / 2; height: 46
            label: "Arrival"; value: obc.ibus.arrivalShown }
        Mk4Item { screen: obc; selectable: false; width: (info.width - 40) / 2; height: 46
            label: "Out. temp."; value: obc.ibus.outsideTemp }
    }

    Row {
        anchors { left: parent.left; right: parent.right; top: info.bottom; bottom: parent.bottom }
        anchors.leftMargin: 10; anchors.rightMargin: 10; anchors.topMargin: 8; anchors.bottomMargin: 12
        spacing: 8

        Mk4Group {
            width: (parent.width - parent.spacing) / 2; height: parent.height
            rightBracket: false
            Column {
                anchors.fill: parent
                Mk4Item { id: cons1; screen: obc; width: parent.width; height: parent.height / 3
                    label: "Consump. 1"; value: obc.ibus.consumption1; unit: obc.ibus.consumptionUnit
                    onActivated: obc.ibus.obcControl(0x04, 0x10) }   // recalculate (reset)
                Mk4Item { id: cons2; screen: obc; width: parent.width; height: parent.height / 3
                    label: "Consump. 2"; value: obc.ibus.consumption2; unit: obc.ibus.consumptionUnit
                    onActivated: obc.ibus.obcControl(0x05, 0x10) }
                Mk4Item { id: avg; screen: obc; width: parent.width; height: parent.height / 3
                    label: "Avg. speed"; value: obc.ibus.avgSpeed; unit: obc.ibus.speedUnit
                    onActivated: obc.ibus.obcControl(0x0a, 0x10) }
            }
        }

        Mk4Group {
            width: (parent.width - parent.spacing) / 2; height: parent.height
            leftBracket: false
            Column {
                anchors.fill: parent
                Mk4Item { id: limitItem; screen: obc; width: parent.width; height: parent.height / 3
                    label: "Limit"; marker: obc.ibus.limitActive ? "■" : "□"
                    highlighted: obc.ibus.limitActive
                    value: obc.ibus.limit; unit: obc.ibus.speedUnit
                    onActivated: obc.ibus.obcControl(0x09, obc.ibus.limitActive ? 0x08 : 0x04) }
                Mk4Item { id: dist; screen: obc; width: parent.width; height: parent.height / 3
                    label: "Distance"; value: obc.ibus.distanceShown
                    unit: obc.ibus.guiding ? "" : obc.ibus.distanceUnit }
                Mk4Item { id: timerItem; screen: obc; width: parent.width; height: parent.height / 3
                    label: "Timer"; marker: obc.ibus.timerRunning ? "▶" : ""
                    highlighted: obc.ibus.timerRunning
                    value: obc.ibus.timer
                    onActivated: obc.ibus.obcControl(0x0e, obc.ibus.timerRunning ? 0x08 : 0x04) }
            }
        }
    }
}
