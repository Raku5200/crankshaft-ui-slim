import QtQuick

// Stand-in for a future IBus service. Every property here maps 1:1 to a
// message documented in wilhelm-docs (see README.md), so a real backend can
// expose the same names and the screens will not change.
QtObject {
    id: ibus

    // Placeholder values until the IBus backend exists; screens show a DEMO tag.
    readonly property bool demo: true

    // --- IKE 0x24 "OBC Text" (cluster -> displays), strings as sent by the cluster
    property string time: Qt.formatTime(new Date(), "h:mm ap")       // 0x01
    property string date: Qt.formatDate(new Date(), "MM/dd/yyyy")    // 0x02
    property string outsideTemp: "+29.5°"                       // 0x03
    property string consumption1: "9.8"                              // 0x04  L/100
    property string consumption2: "11.4"                             // 0x05  L/100
    property string range: "412"                                     // 0x06  km
    property string distance: "128"                                  // 0x07  km (to nav destination)
    property string arrival: "4:05 pm"                               // 0x08
    property string limit: "120"                                     // 0x09  km/h
    property string avgSpeed: "54.3"                                 // 0x0a  km/h
    property string timer: "0.0"                                     // 0x0e  s

    // OBC status flags (from 0x2a "OBC Status" / 0x41 replies)
    property bool limitActive: true
    property bool timerRunning: false

    // --- IKE 0x18 Speed/RPM, 0x19 Temperature, 0x17 Odometer
    property int speedKmh: 62
    property int rpm: 1900
    property int coolantC: 88
    property int ambientC: 29
    property int odometerKm: 238417

    // --- Units from IKE 0x15 Language & Region
    property string distanceUnit: "km"
    property string consumptionUnit: "L/100"
    property string speedUnit: "km/h"

    // GT -> IKE 0x41 "OBC Control": what the real backend will send.
    // control: 0x04 activate, 0x08 deactivate, 0x10 recalculate, 0x20 set as current speed
    function obcControl(property, control) {
        console.log("[ibus] would send 3B 05 80 41 "
                    + ("0" + property.toString(16)).slice(-2).toUpperCase() + " "
                    + ("0" + control.toString(16)).slice(-2).toUpperCase() + " <xor>")
        if (property === 0x04 && control === 0x10) consumption1 = "0.0"
        if (property === 0x05 && control === 0x10) consumption2 = "0.0"
        if (property === 0x0a && control === 0x10) avgSpeed = "0.0"
        if (property === 0x09 && control === 0x20) { limit = String(speedKmh); limitActive = true }
        if (property === 0x09 && control === 0x08) limitActive = false
        if (property === 0x09 && control === 0x04) limitActive = true
        if (property === 0x0e && control === 0x04) { timerRunning = true; _timerStart = Date.now() - parseFloat(timer) * 1000 }
        if (property === 0x0e && control === 0x08) timerRunning = false
    }

    property real _timerStart: 0
    property real _t: 0

    // Simulated traffic so the screens move like on a real bus.
    property Timer _sim: Timer {
        interval: 500; running: true; repeat: true
        onTriggered: {
            ibus._t += 0.5
            ibus.speedKmh = Math.round(62 + 14 * Math.sin(ibus._t / 6))
            ibus.rpm = Math.round(1900 + 600 * Math.sin(ibus._t / 6) + 80 * Math.sin(ibus._t * 1.7))
            ibus.time = Qt.formatTime(new Date(), "h:mm ap")
            if (ibus.timerRunning) {
                const s = (Date.now() - ibus._timerStart) / 1000
                ibus.timer = s < 60 ? s.toFixed(1)
                                    : Math.floor(s / 60) + ":" + ("0" + Math.floor(s % 60)).slice(-2)
            }
        }
    }
}
