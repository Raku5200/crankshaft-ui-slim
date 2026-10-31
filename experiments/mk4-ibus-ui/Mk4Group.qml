import QtQuick
import "."

// Darker panel framed by the grey "[ ]" brackets used around selectable groups.
Item {
    id: group
    property bool leftBracket: true
    property bool rightBracket: true
    default property alias content: inner.data

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        color: Mk4.panel
    }

    component Bracket: Item {
        property bool mirrored: false
        width: 10
        Rectangle { x: mirrored ? parent.width - 3 : 0; width: 3; height: parent.height; color: Mk4.bracket }
        Rectangle { x: mirrored ? 0 : 0; y: 0; width: parent.width; height: 3; color: Mk4.bracket }
        Rectangle { y: parent.height - 3; width: parent.width; height: 3; color: Mk4.bracket }
    }

    Bracket { visible: group.leftBracket; anchors { left: parent.left; top: parent.top; bottom: parent.bottom } }
    Bracket { visible: group.rightBracket; mirrored: true; anchors { right: parent.right; top: parent.top; bottom: parent.bottom } }

    Item {
        id: inner
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 6
        anchors.bottomMargin: 6
    }
}
