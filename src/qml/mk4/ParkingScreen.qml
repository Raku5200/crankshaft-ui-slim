import QtQuick
import "."

// Parking sensors (PDC) shown while reversing: the car from above with the
// front to the left, four sectors in front and four behind. Each sector
// fills from the outside in up to the obstacle, so the closer something is,
// the further the colour (green, yellow, red) reaches towards the car.
// Values come from core (IBus PDC module, cm; 255 = nothing in range).
Rectangle {
    id: root

    /// _ibus.parking: visible, reverse, frontLeft..rearRight (cm).
    property var parking: ({})
    /// "km" or "mi" from the cluster; miles show inches.
    property string distanceUnit: "km"
    readonly property bool inches: distanceUnit === "mi"
    /// Furthest distance drawn (the PDC module reports about this far).
    property int rangeCm: 150

    signal closeRequested()

    color: "#000000"

    function cm(key) {
        const v = parking ? parking[key] : undefined
        return v === undefined || v === null ? -1 : Number(v)
    }
    function inRange(v) { return v >= 0 && v < 255 }
    function closest(keys) {
        let best = -1
        for (const k of keys) {
            const v = cm(k)
            if (inRange(v) && (best < 0 || v < best)) best = v
        }
        return best
    }
    function shown(v) {
        if (!inRange(v)) return "--"
        return inches ? Math.round(v / 2.54) + " in" : v + " cm"
    }
    function distanceColor(v) {
        if (!inRange(v)) return "#8d96b3"
        if (v < 30) return "#ff4a3d"
        if (v < 70) return "#ffd23a"
        return "#ffffff"
    }

    readonly property int frontClosest: closest(["frontLeft", "frontCenterLeft", "frontCenterRight", "frontRight"])
    readonly property int rearClosest: closest(["rearLeft", "rearCenterLeft", "rearCenterRight", "rearRight"])

    onParkingChanged: sensors.requestPaint()
    onRangeCmChanged: sensors.requestPaint()

    // Nothing behind this screen may be touched while it is up.
    MouseArea { anchors.fill: parent }

    // --- header: closest distance in front / behind
    Item {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 64

        Column {
            anchors { left: parent.left; leftMargin: 28; verticalCenter: parent.verticalCenter }
            Text { text: "FRONT"; color: Mk4.dim; font { family: Mk4.font; pixelSize: 13; bold: true; letterSpacing: 1 } }
            Text { text: root.shown(root.frontClosest); color: root.distanceColor(root.frontClosest)
                font { family: Mk4.font; pixelSize: 30; bold: true } }
        }
        Text {
            anchors.centerIn: parent
            text: "PDC"
            color: Mk4.title
            font { family: Mk4.font; pixelSize: 22; bold: true; letterSpacing: 2 }
        }
        Column {
            anchors { right: closeBtn.left; rightMargin: 22; verticalCenter: parent.verticalCenter }
            Text { anchors.right: parent.right; text: "REAR"; color: Mk4.dim
                font { family: Mk4.font; pixelSize: 13; bold: true; letterSpacing: 1 } }
            Text { anchors.right: parent.right; text: root.shown(root.rearClosest); color: root.distanceColor(root.rearClosest)
                font { family: Mk4.font; pixelSize: 30; bold: true } }
        }
        Rectangle {
            id: closeBtn
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            width: 44; height: 44; radius: 4
            color: closeArea.pressed ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08)
            border { width: 1; color: Mk4.bracket }
            Text { anchors.centerIn: parent; text: "✕"; color: Mk4.title; font { pixelSize: 22; bold: true } }
            MouseArea { id: closeArea; anchors.fill: parent; anchors.margins: -6; onClicked: root.closeRequested() }
        }
    }

    // --- car and sensor sectors
    Item {
        id: stage
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom }

        readonly property real cx: width / 2
        readonly property real cy: height / 2
        // Car body, front to the left.
        readonly property real carLength: Math.min(width * 0.52, height * 2.2)
        readonly property real carWidth: carLength * 0.43
        // Sectors: from just past the bumper out to rangeCm.
        readonly property real innerR: carLength / 2 + 14
        readonly property real outerR: Math.min(width / 2 - 8, innerR + (height / 2) * 0.95)
        readonly property real halfSpanDeg: Math.min(32, Math.asin(Math.min(1, (height / 2 - 6) / outerR)) * 180 / Math.PI)

        Canvas {
            id: sensors
            anchors.fill: parent
            antialiasing: true
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            function sector(ctx, a0, a1, r0, r1) {
                const cx = stage.cx, cy = stage.cy
                ctx.beginPath()
                ctx.arc(cx, cy, r1, a0, a1, false)
                ctx.arc(cx, cy, r0, a1, a0, true)
                ctx.closePath()
            }

            // Sectors top to bottom. With the front to the left the car's
            // right side is at the top, so the front reads FR..FL and the
            // rear RR..RL.
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const r0 = stage.innerR, r1 = stage.outerR
                const span = stage.halfSpanDeg * Math.PI / 180
                const step = 2 * span / 4
                const ends = [
                    { centre: Math.PI, keys: ["frontRight", "frontCenterRight", "frontCenterLeft", "frontLeft"], flip: true },
                    { centre: 0, keys: ["rearRight", "rearCenterRight", "rearCenterLeft", "rearLeft"], flip: false }
                ]
                const gradient = ctx.createRadialGradient(stage.cx, stage.cy, r0, stage.cx, stage.cy, r1)
                gradient.addColorStop(0.0, "#e3241b")
                gradient.addColorStop(0.18, "#ef5a17")
                gradient.addColorStop(0.36, "#f6e600")
                gradient.addColorStop(0.58, "#f6e600")
                gradient.addColorStop(0.78, "#11c81a")
                gradient.addColorStop(1.0, "#11c81a")

                for (const end of ends) {
                    for (let i = 0; i < 4; ++i) {
                        // Canvas angles grow clockwise. Sector i counts from
                        // the top: on the left end the top is at PI + span.
                        const a0 = end.flip ? end.centre + span - (i + 1) * step : end.centre - span + i * step
                        const a1 = a0 + step
                        const key = end.keys[i]
                        const v = root.cm(key)

                        ctx.fillStyle = "#1f2126"
                        sector(ctx, a0, a1, r0, r1)
                        ctx.fill()

                        if (root.inRange(v) && v <= root.rangeCm) {
                            const r = r0 + (r1 - r0) * Math.max(0, v) / root.rangeCm
                            ctx.fillStyle = gradient
                            sector(ctx, a0, a1, r, r1)
                            ctx.fill()
                        }

                        ctx.lineWidth = 3
                        ctx.strokeStyle = "#000000"
                        sector(ctx, a0, a1, r0, r1)
                        ctx.stroke()
                    }
                }
            }
        }

        // Car seen from above, front to the left (drawn, not an image).
        Canvas {
            id: car
            width: stage.carLength
            height: stage.carWidth
            anchors.centerIn: parent
            antialiasing: true
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const w = width, h = height
                ctx.lineWidth = 2
                ctx.strokeStyle = "#cfd4de"
                ctx.lineJoin = "round"

                // body
                ctx.beginPath()
                ctx.moveTo(w * 0.06, h * 0.16)
                ctx.quadraticCurveTo(w * 0.07, h * 0.04, w * 0.20, h * 0.03)
                ctx.lineTo(w * 0.86, h * 0.04)
                ctx.quadraticCurveTo(w * 0.985, h * 0.06, w * 0.99, h * 0.22)
                ctx.lineTo(w * 0.99, h * 0.78)
                ctx.quadraticCurveTo(w * 0.985, h * 0.94, w * 0.86, h * 0.96)
                ctx.lineTo(w * 0.20, h * 0.97)
                ctx.quadraticCurveTo(w * 0.07, h * 0.96, w * 0.06, h * 0.84)
                ctx.quadraticCurveTo(w * 0.0, h * 0.5, w * 0.06, h * 0.16)
                ctx.closePath()
                ctx.fillStyle = "#101318"
                ctx.fill()
                ctx.stroke()

                // windscreen, roof and rear window
                ctx.lineWidth = 1.6
                ctx.beginPath()
                ctx.moveTo(w * 0.33, h * 0.14)
                ctx.quadraticCurveTo(w * 0.27, h * 0.5, w * 0.33, h * 0.86)
                ctx.lineTo(w * 0.43, h * 0.80)
                ctx.quadraticCurveTo(w * 0.40, h * 0.5, w * 0.43, h * 0.20)
                ctx.closePath()
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(w * 0.43, h * 0.20)
                ctx.lineTo(w * 0.71, h * 0.21)
                ctx.moveTo(w * 0.43, h * 0.80)
                ctx.lineTo(w * 0.71, h * 0.79)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(w * 0.71, h * 0.21)
                ctx.quadraticCurveTo(w * 0.75, h * 0.5, w * 0.71, h * 0.79)
                ctx.lineTo(w * 0.79, h * 0.84)
                ctx.quadraticCurveTo(w * 0.83, h * 0.5, w * 0.79, h * 0.16)
                ctx.closePath()
                ctx.stroke()

                // bonnet lines and mirrors
                ctx.beginPath()
                ctx.moveTo(w * 0.10, h * 0.28)
                ctx.quadraticCurveTo(w * 0.22, h * 0.24, w * 0.33, h * 0.26)
                ctx.moveTo(w * 0.10, h * 0.72)
                ctx.quadraticCurveTo(w * 0.22, h * 0.76, w * 0.33, h * 0.74)
                ctx.stroke()

                ctx.fillStyle = "#cfd4de"
                ctx.fillRect(w * 0.345, -h * 0.03, w * 0.03, h * 0.07)
                ctx.fillRect(w * 0.345, h * 0.96, w * 0.03, h * 0.07)
            }
        }

        Text {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 6 }
            visible: !root.parking || root.parking.heard !== true
            text: "Waiting for the parking sensors…"
            color: Mk4.dim
            font { family: Mk4.font; pixelSize: 15 }
        }
    }
}
