pragma Singleton
import QtQuick

// Visual language of the MK4 navigation / Board Monitor screens:
// deep navy body, blue gradient title and status bars, light text,
// grey bracket frames and a salmon-red focus outline.
QtObject {
    readonly property color body: "#0d1124"
    readonly property color bodyBottom: "#151a33"
    readonly property color panel: "#090c1a"
    readonly property color barLeft: "#4b5f96"
    readonly property color barRight: "#16204a"
    readonly property color barHighlight: "#7d8fc2"
    readonly property color title: "#d5ddf2"
    readonly property color label: "#e9edf6"
    readonly property color value: "#ffffff"
    readonly property color dim: "#8d96b3"
    readonly property color bracket: "#8b909e"
    readonly property color focus: "#e2634d"
    readonly property color active: "#f2b34a"
    readonly property color route: "#4f8df5"

    readonly property string font: "DejaVu Sans"
    readonly property int titleSize: 25
    readonly property int labelSize: 25
    readonly property int smallSize: 18

    readonly property int headerHeight: 50
    readonly property int footerHeight: 44
}
