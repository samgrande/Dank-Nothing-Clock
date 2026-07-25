pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins

DesktopPluginComponent {
    id: root

    // Square by default — DMS grids typically seed the widget's initial
    // size from min*, so keep these equal rather than relying on runtime
    // resize logic.
    minWidth: 260
    minHeight: 260

    property string style: pluginData.style ?? "digital"
    property bool showDate: pluginData.showDate ?? true

    // No longer a user setting — always on. It still gates the seconds
    // indicator on Analog / Analog (Classic) / Orbit.
    readonly property bool showAccent: true

    // Only wired into Digital and Split's hour digits + AM/PM box.
    // Digital (Cards) always shows 12-hour regardless of this.
    property bool is12Hour: (pluginData.timeFormat ?? "24") === "12"

    // Slider stores 0-100; only the outer card background uses this.
    // The analog clock face's own background is intentionally excluded
    // so the dial stays fully opaque regardless of this setting.
    property real backgroundOpacity: (pluginData.backgroundOpacity ?? 100) / 100

    readonly property int contentMargin: 20

    // NOTE: swap these for Theme.* tokens once you confirm the exact
    // property names in your Theme.qml (e.g. Theme.surfaceContainer,
    // Theme.onSurface). Kept as local constants for now so the widget
    // is self-contained and easy to preview.
    readonly property color colorBg: "#000000"
    readonly property color colorBorder: "#1A1A1A"
    readonly property color colorPrimary: "#FFFFFF"
    readonly property color colorSecondary: "#808080"

    // Accent color source: "primary"/"secondary" pull from the DMS
    // theme, "custom" uses the hex picked below. NOTE: Theme.primary /
    // Theme.secondary are a guess at the token names — verify these
    // against your actual Theme.qml and swap if they don't match.
    property string accentColorSource: pluginData.accentColorSource ?? "custom"
    property color customAccentColor: pluginData.accentCustomColor ?? "#FF1E4C"
    readonly property color colorAccent:
        accentColorSource === "primary" ? Theme.primary :
        accentColorSource === "secondary" ? Theme.secondary :
        customAccentColor

    FontLoader {
        id: dotoFont
        source: Qt.resolvedUrl("Doto-Bold.ttf")
    }

    readonly property string clockFont:
        dotoFont.status === FontLoader.Ready
        ? dotoFont.name
        : "monospace"

    // Always tick at second precision — the digital face only shows
    // HH:mm, but the analog second-dot needs real seconds to animate.
    SystemClock {
        id: systemClock
        precision: SystemClock.Seconds
    }

    // Blinking colon for the digital/split faces.
    property bool colonOn: true
    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: root.colonOn = !root.colonOn
    }

    readonly property string hourText: {
        if (!systemClock.date) return "--";
        var h = systemClock.date.getHours();
        if (root.is12Hour) {
            var h12 = h % 12;
            if (h12 === 0) h12 = 12;
            return (h12 < 10 ? "0" : "") + h12;
        }
        return (h < 10 ? "0" : "") + h;
    }
    readonly property string minuteText:
        systemClock.date ? systemClock.date.toLocaleTimeString(Qt.locale(), "mm") : "--"
    readonly property string dateText:
        systemClock.date
        ? systemClock.date.toLocaleDateString(Qt.locale(), "ddd, MMM d").toUpperCase()
        : ""

    readonly property string dayOfWeekText:
        systemClock.date
        ? systemClock.date.toLocaleDateString(Qt.locale(), "dddd").toUpperCase()
        : ""
    readonly property string time12Text:
        systemClock.date ? systemClock.date.toLocaleTimeString(Qt.locale(), "h:mm") : "--:--"
    readonly property string ampmText:
        systemClock.date ? systemClock.date.toLocaleTimeString(Qt.locale(), "AP") : ""
    readonly property string dayOfMonthText:
        systemClock.date ? systemClock.date.toLocaleDateString(Qt.locale(), "d") : "--"
    readonly property string monthNumText:
        systemClock.date ? systemClock.date.toLocaleDateString(Qt.locale(), "MM") : "--"

    readonly property real analogHourAngle:
        systemClock.date
        ? ((systemClock.date.getHours() % 12) + systemClock.date.getMinutes() / 60) * 30
        : 0
    readonly property real analogMinuteAngle:
        systemClock.date
        ? (systemClock.date.getMinutes() + systemClock.date.getSeconds() / 60) * 6
        : 0
    readonly property real analogSecondAngle:
        systemClock.date ? systemClock.date.getSeconds() * 6 : 0

    // Reusable "HH:mm" row with a blinking colon and a faint ghost
    // "88:88" layer behind it (classic unlit-LED look). pixelSize is
    // provided by the caller so it's derived from the actual space
    // available, never the full unclipped widget size.
    component TimeRow: Item {
        id: timeRow

        required property int pixelSize
        property color textColor: root.colorPrimary
        property bool ghost: true

        implicitWidth: fg.implicitWidth
        implicitHeight: fg.implicitHeight

        Row {
            visible: timeRow.ghost
            anchors.fill: parent
            spacing: 2
            opacity: 0.06

            Text {
                text: "88"
                font.family: root.clockFont
                font.pixelSize: timeRow.pixelSize
                color: timeRow.textColor
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: ":"
                font.family: root.clockFont
                font.pixelSize: timeRow.pixelSize
                color: timeRow.textColor
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -timeRow.pixelSize * 0.07
            }
            Text {
                text: "88"
                font.family: root.clockFont
                font.pixelSize: timeRow.pixelSize
                color: timeRow.textColor
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            id: fg
            spacing: 2

            Text {
                text: root.hourText
                font.family: root.clockFont
                font.pixelSize: timeRow.pixelSize
                color: timeRow.textColor
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: ":"
                font.family: root.clockFont
                font.pixelSize: timeRow.pixelSize
                color: timeRow.textColor
                opacity: root.colonOn ? 1.0 : 0.15
                Behavior on opacity { NumberAnimation { duration: 150 } }
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -timeRow.pixelSize * 0.07
            }
            Text {
                text: root.minuteText
                font.family: root.clockFont
                font.pixelSize: timeRow.pixelSize
                color: timeRow.textColor
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Used by Digital and Split only. Shows a small red box with
    // AM/PM inside when in 12-hour mode; nothing in 24-hour mode.
    component DateLabel: Row {
        spacing: 8

        Rectangle {
            visible: root.is12Hour
            radius: 5
            color: root.colorAccent
            width: ampmLabel.implicitWidth + 10
            height: ampmLabel.implicitHeight + 5
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: ampmLabel
                anchors.centerIn: parent
                text: root.ampmText
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1
                color: "#FFFFFF"
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.dateText
            font.pixelSize: 14
            color: root.colorSecondary
        }
    }

    component StatCard: Rectangle {
        id: statCard

        required property string value

        radius: 14
        color: "#141414"
        border.width: 1
        border.color: root.colorBorder

        Text {
            anchors.centerIn: parent
            text: statCard.value
            font.family: root.clockFont
            font.pixelSize: statCard.height * 0.36
            color: root.colorPrimary
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius * 2
        color: Qt.rgba(root.colorBg.r, root.colorBg.g, root.colorBg.b, root.backgroundOpacity)
        border.width: 1
        border.color: Qt.rgba(root.colorBorder.r, root.colorBorder.g, root.colorBorder.b, root.backgroundOpacity)
    }

    Loader {
        anchors.fill: parent
        anchors.margins: root.contentMargin

        sourceComponent:
            root.style === "split" ? splitClock :
            root.style === "analog" ? analogClock :
            root.style === "analogClassic" ? analogClassicClock :
            root.style === "digitalCard" ? digitalCardClock :
            root.style === "orbit" ? orbitClock :
            digitalClock
    }

    // "HH:MM" is 5 glyphs on the dot font, roughly 0.62x pixelSize wide
    // each plus inter-glyph spacing. Solve pixelSize from the actual
    // available width (parent, already inset by contentMargin) so text
    // never clips, and cap by height so it doesn't overrun vertically.
    function fittedPixelSize(availW, availH, heightFactor, widthDivisor) {
        var wd = widthDivisor !== undefined ? widthDivisor : 3.4;
        var byWidth = availW / wd;
        var byHeight = availH * heightFactor;
        return Math.max(24, Math.min(byWidth, byHeight));
    }

    Component {
        id: digitalClock

        Item {
            id: digitalRoot
            anchors.fill: parent

            readonly property real pixelSize:
                root.fittedPixelSize(width, height, 0.42)

            Column {
                anchors.centerIn: parent
                spacing: 10

                TimeRow {
                    anchors.horizontalCenter: parent.horizontalCenter
                    pixelSize: digitalRoot.pixelSize
                }

                DateLabel {
                    visible: root.showDate
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    Component {
        id: splitClock

        Item {
            id: splitRoot
            anchors.fill: parent

            readonly property real pixelSize:
                root.fittedPixelSize(width, height, 0.34, 1.8)

            Column {
                anchors.centerIn: parent
                spacing: -splitRoot.pixelSize * 0.1

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.hourText
                    font.family: root.clockFont
                    font.pixelSize: splitRoot.pixelSize
                    color: root.colorPrimary
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.minuteText
                    font.family: root.clockFont
                    font.pixelSize: splitRoot.pixelSize
                    color: root.colorPrimary
                    opacity: root.colonOn ? 1.0 : 0.4
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Item {
                    visible: root.showDate
                    width: 1
                    height: 16
                }

                DateLabel {
                    visible: root.showDate
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    Component {
        id: analogClock

        Item {
            id: analogRoot
            anchors.fill: parent

            readonly property real faceSize:
                Math.min(width, height - (root.showDate ? 28 : 0)) * 0.9

            Column {
                anchors.centerIn: parent
                spacing: 10

                Item {
                    id: face
                    width: analogRoot.faceSize
                    height: analogRoot.faceSize
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: root.colorBg
                        border.width: 1
                        border.color: root.colorBorder
                    }

                    // Hour hand — thick, primary color. The pivot is a
                    // zero-size Item anchored dead-center on the face via
                    // anchors.centerIn, then rotated with the plain
                    // `rotation` property (default transformOrigin is its
                    // own center, which for a zero-size item is just its
                    // anchored position). This avoids manually computing
                    // a transform origin, which is easy to get a pixel or
                    // two off. The hand rectangle is offset from that
                    // pivot so a small tail pokes out past center.
                    Item {
                        id: hourPivot
                        anchors.centerIn: face
                        width: 0
                        height: 0
                        rotation: root.analogHourAngle
                        z: 1

                        Rectangle {
                            readonly property real handLength: face.height * 0.26
                            readonly property real tailLength: face.height * 0.045

                            width: Math.max(6, face.width * 0.06)
                            height: handLength + tailLength
                            radius: width / 2
                            color: root.colorPrimary
                            x: -width / 2
                            y: -handLength
                        }
                    }

                    // Minute hand — thinner, muted grey for hierarchy.
                    // Same pivot pattern as the hour hand, with a smaller
                    // tail, and z-ordered above it so it renders on top
                    // where the two hands cross.
                    Item {
                        id: minutePivot
                        anchors.centerIn: face
                        width: 0
                        height: 0
                        rotation: root.analogMinuteAngle
                        z: 2

                        Rectangle {
                            readonly property real handLength: face.height * 0.4
                            readonly property real tailLength: face.height * 0.03

                            width: Math.max(2, face.width * 0.025)
                            height: handLength + tailLength
                            radius: width / 2
                            color: root.colorSecondary
                            x: -width / 2
                            y: -handLength
                        }
                    }



                    // Seconds — red dot orbiting the face, tip of an
                    // invisible hand, ticking once per second.
                    Item {
                        width: 2
                        height: face.height * 0.42
                        x: face.width / 2 - width / 2
                        y: face.height / 2 - height
                        transformOrigin: Item.Bottom
                        rotation: root.analogSecondAngle
                        visible: root.showAccent

                        Rectangle {
                            width: Math.max(5, face.width * 0.035)
                            height: width
                            radius: width / 2
                            color: root.colorAccent
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: -width / 2
                        }
                    }
                }

                Text {
                    visible: root.showDate
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.dateText
                    font.pixelSize: 14
                    color: root.colorSecondary
                }
            }
        }
    }

    // Style 4 — "Analog (Classic)": a traditional watch face with hour
    // markers, diamond cut-out hands, and a red seconds hand with a
    // ring-and-dot center hub.
    Component {
        id: analogClassicClock

        Item {
            id: classicRoot
            anchors.fill: parent

            readonly property real faceSize:
                Math.min(width, height - (root.showDate ? 28 : 0)) * 0.9

            Column {
                anchors.centerIn: parent
                spacing: 10

                Item {
                    id: face
                    width: classicRoot.faceSize
                    height: classicRoot.faceSize
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "#181818"
                        border.width: 1
                        border.color: root.colorBorder
                    }

                    // Hour markers — uniform thin ticks.
                    Repeater {
                        model: 12

                        Item {
                            required property int index

                            anchors.centerIn: face
                            width: 0
                            height: 0
                            rotation: index * 30

                            Rectangle {
                                width: 2
                                height: 12
                                radius: width / 2
                                color: root.colorPrimary
                                x: -width / 2
                                y: -face.height / 2 + 8
                            }
                        }
                    }

                    // Hour hand — thin rod with a small open diamond
                    // near the tip (outline only, dial-colored fill so
                    // it reads as a cut-out).
                    Item {
                        id: classicHourPivot
                        anchors.centerIn: face
                        width: 0
                        height: 0
                        rotation: root.analogHourAngle
                        z: 1

                        Rectangle {
                            id: classicHourRod
                            readonly property real handLength: face.height * 0.24
                            width: Math.max(2, face.width * 0.016)
                            height: handLength + 8
                            radius: width / 2
                            color: root.colorPrimary
                            x: -width / 2
                            y: -handLength
                        }

                        Rectangle {
                            readonly property real dSize: Math.max(7, face.width * 0.055)
                            width: dSize
                            height: dSize
                            radius: 1
                            rotation: 45
                            color: "#181818"
                            border.width: 1
                            border.color: root.colorPrimary
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: -classicHourRod.handLength * 0.55 - height / 2
                        }
                    }

                    // Minute hand — same thin treatment, longer.
                    Item {
                        id: classicMinutePivot
                        anchors.centerIn: face
                        width: 0
                        height: 0
                        rotation: root.analogMinuteAngle
                        z: 2

                        Rectangle {
                            id: classicMinuteRod
                            readonly property real handLength: face.height * 0.36
                            width: Math.max(2, face.width * 0.014)
                            height: handLength + 6
                            radius: width / 2
                            color: root.colorSecondary
                            x: -width / 2
                            y: -handLength
                        }

                        Rectangle {
                            readonly property real dSize: Math.max(6, face.width * 0.045)
                            width: dSize
                            height: dSize
                            radius: 1
                            rotation: 45
                            color: "#181818"
                            border.width: 1
                            border.color: root.colorSecondary
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: -classicMinuteRod.handLength * 0.6 - height / 2
                        }
                    }

                    // Seconds hand — thin red line with a small tail
                    // through the pivot.
                    Item {
                        anchors.centerIn: face
                        width: 0
                        height: 0
                        rotation: root.analogSecondAngle
                        visible: root.showAccent
                        z: 3

                        Rectangle {
                            readonly property real handLength: face.height * 0.4
                            readonly property real tail: face.height * 0.08
                            width: 2
                            height: handLength + tail
                            color: root.colorAccent
                            x: -width / 2
                            y: -handLength
                        }
                    }

                    // Center pivot — single small accent dot, no ring.
                    Rectangle {
                        visible: root.showAccent
                        anchors.centerIn: face
                        width: Math.max(5, face.width * 0.028)
                        height: width
                        radius: width / 2
                        color: root.colorAccent
                        z: 5
                    }
                }

                Text {
                    visible: root.showDate
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.dateText
                    font.pixelSize: 14
                    color: root.colorSecondary
                }
            }
        }
    }

    // Style 5 — "Digital (Cards)": day of week + large 12-hour time up
    // top, with two rounded-square stat cards below for day-of-month
    // and month number.
    Component {
        id: digitalCardClock

        Item {
            id: cardRoot
            anchors.fill: parent

            readonly property real dayPixelSize:
                Math.max(14, Math.min(width * 0.09, 22))
            readonly property real timePixelSize:
                root.fittedPixelSize(width, height, 0.22, 3.4)
            readonly property real ampmPixelSize: timePixelSize * 0.32

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10
                spacing: 14

                Text {
                    text: root.dayOfWeekText
                    font.family: root.clockFont
                    font.pixelSize: cardRoot.dayPixelSize
                    color: root.colorPrimary
                    font.letterSpacing: 1
                }

                Row {
                    spacing: 8

                    Text {
                        text: root.time12Text
                        font.family: root.clockFont
                        font.pixelSize: cardRoot.timePixelSize
                        color: root.colorPrimary
                    }

                    Text {
                        text: root.ampmText
                        font.family: root.clockFont
                        font.pixelSize: cardRoot.ampmPixelSize
                        color: root.colorSecondary
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: cardRoot.timePixelSize * 0.12
                    }
                }

                Row {
                    id: cardsRow
                    spacing: 10
                    width: parent.width

                    Column {
                        width: (cardsRow.width - cardsRow.spacing) / 2
                        spacing: 8

                        StatCard {
                            width: parent.width
                            height: width * 0.72
                            value: root.dayOfMonthText
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "DATE"
                            font.family: root.clockFont
                            font.pixelSize: 11
                            color: root.colorSecondary
                            font.letterSpacing: 1
                        }
                    }

                    Column {
                        width: (cardsRow.width - cardsRow.spacing) / 2
                        spacing: 8

                        StatCard {
                            width: parent.width
                            height: width * 0.72
                            value: root.monthNumText
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "MONTH"
                            font.family: root.clockFont
                            font.pixelSize: 11
                            color: root.colorSecondary
                            font.letterSpacing: 1
                        }
                    }
                }
            }
        }
    }

    // Style 6 — "Orbit": three concentric rings, each carrying a dot
    // that sweeps around it — red/outer for seconds, grey/middle for
    // minutes, white/inner for hours — with the digital time centered
    // in a filled disc in the middle.
    Component {
        id: orbitClock

        Item {
            id: orbitRoot
            anchors.fill: parent

            readonly property real faceSize:
                Math.min(width, height - (root.showDate ? 26 : 0)) * 0.92

            Column {
                anchors.centerIn: parent
                spacing: 10

                Item {
                    id: orbitFace
                    width: orbitRoot.faceSize
                    height: orbitRoot.faceSize
                    anchors.horizontalCenter: parent.horizontalCenter

                    readonly property real outerRing: width / 2 * 0.96
                    readonly property real middleRing: width / 2 * 0.74
                    readonly property real innerRing: width / 2 * 0.52
                    readonly property real coreRadius: width / 2 * 0.4

                    // Ring guides
                    Rectangle {
                        anchors.centerIn: parent
                        width: orbitFace.outerRing * 2
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: orbitFace.middleRing * 2
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: orbitFace.innerRing * 2
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                    }

                    // Center disc
                    Rectangle {
                        anchors.centerIn: parent
                        width: orbitFace.coreRadius * 2
                        height: width
                        radius: width / 2
                        color: "#141414"
                        border.width: 1
                        border.color: root.colorBorder
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.hourText + ":" + root.minuteText
                        font.family: root.clockFont
                        font.pixelSize: orbitFace.coreRadius * 0.62
                        color: root.colorPrimary
                    }

                    // Hour dot — inner ring, white
                    Item {
                        anchors.centerIn: orbitFace
                        width: 0
                        height: 0
                        rotation: root.analogHourAngle

                        Rectangle {
                            width: Math.max(6, orbitFace.width * 0.045)
                            height: width
                            radius: width / 2
                            color: root.colorPrimary
                            x: -width / 2
                            y: -orbitFace.innerRing - height / 2
                        }
                    }

                    // Minute dot — middle ring, grey
                    Item {
                        anchors.centerIn: orbitFace
                        width: 0
                        height: 0
                        rotation: root.analogMinuteAngle

                        Rectangle {
                            width: Math.max(6, orbitFace.width * 0.045)
                            height: width
                            radius: width / 2
                            color: root.colorSecondary
                            x: -width / 2
                            y: -orbitFace.middleRing - height / 2
                        }
                    }

                    // Second dot — outer ring, red accent
                    Item {
                        visible: root.showAccent
                        anchors.centerIn: orbitFace
                        width: 0
                        height: 0
                        rotation: root.analogSecondAngle

                        Rectangle {
                            width: Math.max(6, orbitFace.width * 0.045)
                            height: width
                            radius: width / 2
                            color: root.colorAccent
                            x: -width / 2
                            y: -orbitFace.outerRing - height / 2
                        }
                    }
                }

                Text {
                    visible: root.showDate
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.dateText
                    font.pixelSize: 14
                    color: root.colorSecondary
                }
            }
        }
    }
}
