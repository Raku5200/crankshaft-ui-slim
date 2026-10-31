import QtQuick
import "."

// Selectable row: label on the left, optional value (+unit) on the right,
// red outline when it has rotary focus. Tap = focus + confirm.
Item {
    id: item

    property var screen
    property string label: ""
    property string value: ""
    property string unit: ""
    property string marker: ""      // e.g. "□" / "■" like the OBC limit indicator
    property bool highlighted: false // e.g. a running timer or an active limit
    property bool selectable: true
    readonly property bool focused: selectable && screen && screen.isFocused(item)

    signal activated()

    implicitHeight: 54

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        color: item.focused ? Qt.rgba(0.89, 0.39, 0.30, 0.10) : "transparent"
        border { width: item.focused ? 3 : 0; color: Mk4.focus }
    }

    Text {
        id: labelText
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        text: item.label
        color: Mk4.label
        font { family: Mk4.font; pixelSize: Mk4.labelSize; letterSpacing: 0.5 }
    }

    Text {
        visible: item.marker !== ""
        anchors { left: labelText.right; leftMargin: 18; verticalCenter: parent.verticalCenter }
        text: item.marker
        color: item.highlighted ? Mk4.active : Mk4.value
        font { family: Mk4.font; pixelSize: 24; bold: true }
    }

    Text {
        id: valueText
        anchors { right: unitText.visible ? unitText.left : parent.right
                  rightMargin: unitText.visible ? 6 : 14
                  verticalCenter: parent.verticalCenter }
        text: item.value
        color: item.highlighted ? Mk4.active : Mk4.value
        font { family: Mk4.font; pixelSize: Mk4.labelSize; bold: true }
    }

    Text {
        id: unitText
        visible: item.unit !== ""
        anchors { right: parent.right; rightMargin: 14; baseline: valueText.baseline }
        text: item.unit
        color: Mk4.dim
        font { family: Mk4.font; pixelSize: 15 }
    }

    MouseArea {
        anchors.fill: parent
        enabled: item.selectable
        onClicked: {
            if (item.screen) {
                const i = item.screen.focusables.indexOf(item)
                if (i >= 0) item.screen.focusIndex = i
            }
            item.activated()
        }
    }
}
