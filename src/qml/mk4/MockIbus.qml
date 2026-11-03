import QtQuick

// Vehicle data for the MK4 screens. Real values come from the car's IBus
// through core (_ibus) whenever the IBus interface is plugged in; without it
// the screens show placeholder values and a DEMO DATA tag. Property names map
// 1:1 to messages documented in wilhelm-docs.
QtObject {
    id: ibus

    /// IbusFacade (_ibus); null in previews.
    property var live: null
    readonly property bool liveConnected: !!live && live.connected === true
    readonly property var obc: liveConnected && live.obc ? live.obc : ({})
    readonly property bool demo: !liveConnected

    function liveText(key) {
        const v = obc[key]
        return v !== undefined && v !== "" ? String(v) : "--"
    }
    // The cluster puts the unit inside the text ("103 KM", "6.6 KM/L").
    // The screens show the unit separately, so drop it from the value.
    function liveValue(key) {
        const t = liveText(key).trim().replace(/\s*[A-Za-z][A-Za-z\/0-9]*$/, "").trim()
        return t !== "" ? t : "--"
    }
    // Numbers the cluster has not sent yet are -999 (shown as "--").
    function liveInt(key) {
        const v = obc[key]
        return v !== undefined && v > -999 ? v : -999
    }
    function shown(value) { return value > -999 ? String(value) : "--" }

    // Live data from the phone via core (now playing, turn-by-turn, cluster
    // line). Set to _projectionInfo by main.qml; empty maps when absent.
    property var projection: null
    readonly property var nowPlaying: projection && projection.nowPlaying ? projection.nowPlaying : ({})
    readonly property var navigation: projection && projection.navigation ? projection.navigation : ({})
    readonly property var clusterText: projection && projection.clusterText ? projection.clusterText : ({})
    readonly property bool guiding: navigation.guiding === true
    readonly property bool hasTrack: nowPlaying.hasTrack === true

    // OBC Arrival / Distance follow Android Auto navigation while guiding.
    readonly property string arrivalShown: guiding && navigation.eta ? navigation.eta : arrival
    readonly property string distanceShown: guiding && navigation.destinationDistanceText
                                            ? navigation.destinationDistanceText : distance

    function maneuverSymbol(name, exitNumber) {
        switch (name) {
        case "left": case "ramp-left": case "exit-left": return "↰"
        case "right": case "ramp-right": case "exit-right": return "↱"
        case "slight-left": case "keep-left": case "fork-left": case "merge-left": return "↖"
        case "slight-right": case "keep-right": case "fork-right": case "merge-right": return "↗"
        case "sharp-left": return "↲"
        case "sharp-right": return "↳"
        case "u-turn-left": case "u-turn-right": return "↶"
        case "roundabout": case "roundabout-enter": case "roundabout-exit":
            return "↻" + (exitNumber > 0 ? exitNumber : "")
        case "destination": case "destination-left": case "destination-right": return "⚑"
        default: return "↑"
        }
    }

    // --- IKE 0x24 "OBC Text" (cluster -> displays), strings as sent by the cluster
    readonly property string time: liveConnected ? liveText("time") : demoTime            // 0x01
    readonly property string date: liveConnected ? liveText("date") : demoDate            // 0x02
    readonly property string outsideTemp: liveConnected ? liveText("outsideTemp") : demoOutsideTemp // 0x03
    readonly property string consumption1: liveConnected ? liveValue("consumption1") : demoConsumption1 // 0x04
    readonly property string consumption2: liveConnected ? liveValue("consumption2") : demoConsumption2 // 0x05
    readonly property string range: liveConnected ? liveValue("range") : demoRange         // 0x06
    readonly property string distance: liveConnected ? liveValue("distance") : demoDistance // 0x07
    readonly property string arrival: liveConnected ? liveText("arrival") : demoArrival   // 0x08
    readonly property string limit: liveConnected ? liveValue("limit") : demoLimit         // 0x09
    readonly property string avgSpeed: liveConnected ? liveValue("avgSpeed") : demoAvgSpeed // 0x0a
    readonly property string timer: liveConnected ? liveText("timer") : demoTimer         // 0x0e

    // OBC status flags (from 0x2a "OBC Status"; not read from the car yet)
    property bool limitActive: true
    property bool timerRunning: false

    // --- IKE 0x18 Speed/RPM, 0x19 Temperature, 0x17 Odometer
    readonly property int speedKmh: liveConnected ? Math.max(0, liveInt("speedKmh")) : demoSpeedKmh
    readonly property int rpm: liveConnected ? Math.max(0, liveInt("rpm")) : demoRpm
    readonly property int coolantC: liveConnected ? liveInt("coolantC") : 88
    readonly property int ambientC: liveConnected ? liveInt("ambientC") : 29
    readonly property int odometerKm: liveConnected ? -999 : 238417  // 0x17 not decoded yet

    // --- Units from IKE 0x15 Language & Region
    readonly property string distanceUnit: liveConnected && obc.distanceUnit ? obc.distanceUnit : "km"
    readonly property string consumptionUnit: liveConnected && obc.consumption1Unit ? obc.consumption1Unit : "L/100"
    readonly property string consumption2Unit: liveConnected && obc.consumption2Unit ? obc.consumption2Unit : consumptionUnit
    readonly property string speedUnit: liveConnected && obc.speedUnit ? obc.speedUnit : "km/h"
    // The cluster's temperature text has no unit; the demo text already has "°".
    readonly property string temperatureUnit: liveConnected && obc.temperatureUnit ? obc.temperatureUnit : ""

    // GT -> IKE 0x41 "OBC Control".
    // control: 0x04 activate, 0x08 deactivate, 0x10 recalculate, 0x20 set as current speed
    function obcControl(property, control) {
        if (property === 0x09 && control === 0x08) limitActive = false
        if (property === 0x09 && (control === 0x04 || control === 0x20)) limitActive = true
        if (property === 0x0e && control === 0x04) { timerRunning = true; _timerStart = Date.now() - parseFloat(demoTimer) * 1000 }
        if (property === 0x0e && control === 0x08) timerRunning = false

        if (liveConnected) {
            live.obcControl(property, control)
            return
        }
        if (property === 0x04 && control === 0x10) demoConsumption1 = "0.0"
        if (property === 0x05 && control === 0x10) demoConsumption2 = "0.0"
        if (property === 0x0a && control === 0x10) demoAvgSpeed = "0.0"
        if (property === 0x09 && control === 0x20) demoLimit = String(demoSpeedKmh)
    }

    // --- placeholder values (no IBus interface)
    property string demoTime: Qt.formatTime(new Date(), "h:mm ap")
    property string demoDate: Qt.formatDate(new Date(), "MM/dd/yyyy")
    property string demoOutsideTemp: "+29.5°"
    property string demoConsumption1: "9.8"
    property string demoConsumption2: "11.4"
    property string demoRange: "412"
    property string demoDistance: "128"
    property string demoArrival: "4:05 pm"
    property string demoLimit: "120"
    property string demoAvgSpeed: "54.3"
    property string demoTimer: "0.0"
    property int demoSpeedKmh: 62
    property int demoRpm: 1900

    property real _timerStart: 0
    property real _t: 0

    // Simulated traffic so the screens move like on a real bus.
    property Timer _sim: Timer {
        interval: 500; running: ibus.demo; repeat: true
        onTriggered: {
            ibus._t += 0.5
            ibus.demoSpeedKmh = Math.round(62 + 14 * Math.sin(ibus._t / 6))
            ibus.demoRpm = Math.round(1900 + 600 * Math.sin(ibus._t / 6) + 80 * Math.sin(ibus._t * 1.7))
            ibus.demoTime = Qt.formatTime(new Date(), "h:mm ap")
            if (ibus.timerRunning) {
                const s = (Date.now() - ibus._timerStart) / 1000
                ibus.demoTimer = s < 60 ? s.toFixed(1)
                                        : Math.floor(s / 60) + ":" + ("0" + Math.floor(s % 60)).slice(-2)
            }
        }
    }
}
