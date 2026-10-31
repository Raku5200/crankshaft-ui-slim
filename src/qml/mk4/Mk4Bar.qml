import QtQuick
import "."

// Title / status bar with the horizontal blue gradient and a light top edge.
Rectangle {
    id: bar
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: Mk4.barLeft }
        GradientStop { position: 0.55; color: Qt.darker(Mk4.barLeft, 1.35) }
        GradientStop { position: 1.0; color: Mk4.barRight }
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Mk4.barHighlight }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
}
