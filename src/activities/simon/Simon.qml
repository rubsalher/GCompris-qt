/* GCompris - Simon.qml
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * "Simon dice" — a memory game inspired by the classic 1978 electronic
 * game "Simon": 4 colored pads arranged in a circle light up (with their
 * own distinct tone) in a growing sequence, and the player must repeat
 * it by tapping the pads in the same order. Replaces "melody" (a music
 * xylophone activity, removed).
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma ComponentBehavior: Bound

import QtQuick
import core 1.0
import "../../core"
import "simon.js" as Activity

ActivityBase {
    id: activity
    focus: true

    onStart: focus = true
    onStop: {}

    pageComponent: Rectangle {
        id: activityBackground
        color: "#26323d"
        focus: true

        signal start
        signal stop

        readonly property string highScoreKey: "simon-highscore"

        Component.onCompleted: {
            activity.start.connect(start)
            activity.stop.connect(stop)
            var saved = ApplicationSettings.currentLevels(highScoreKey)
            if (saved && saved.length > 0) {
                var n = parseInt(saved[0], 10)
                if (!isNaN(n))
                    items.highScore = n
            }
        }

        QtObject {
            id: items
            property var sequence: []
            property int score: 0
            property int highScore: 0
            property string gameState: "playing" // "playing" | "over"
            property bool acceptingInput: false
            property int litPad: -1
            property int playbackIndex: 0
            property string playbackPhase: "gap"
            property int playerStep: 0
            property var padSounds: [toneGreenSound, toneRedSound, toneYellowSound, toneBlueSound]
            property alias errorSound: errorSound
            property alias playbackTimer: playbackTimer
            property alias pressFlashTimer: pressFlashTimer
            property alias nextRoundTimer: nextRoundTimer

            onScoreChanged: if (score > highScore) highScore = score
            onHighScoreChanged: ApplicationSettings.setCurrentLevels(activityBackground.highScoreKey, [highScore.toString()])
        }

        onStart: Activity.start(activity, items)
        onStop: Activity.stop()


        GCSoundEffect {
            id: toneGreenSound
            source: "qrc:/gcompris/src/activities/simon/resource/tone_green.wav"
        }
        GCSoundEffect {
            id: toneRedSound
            source: "qrc:/gcompris/src/activities/simon/resource/tone_red.wav"
        }
        GCSoundEffect {
            id: toneYellowSound
            source: "qrc:/gcompris/src/activities/simon/resource/tone_yellow.wav"
        }
        GCSoundEffect {
            id: toneBlueSound
            source: "qrc:/gcompris/src/activities/simon/resource/tone_blue.wav"
        }
        GCSoundEffect {
            id: errorSound
            source: "qrc:/gcompris/src/core/resource/sounds/crash.wav"
        }

        Timer {
            id: playbackTimer
            repeat: false
            onTriggered: Activity.playbackTick()
        }
        Timer {
            id: pressFlashTimer
            interval: 280
            repeat: false
            onTriggered: Activity.onPressFlashTimeout()
        }
        Timer {
            id: nextRoundTimer
            interval: 700
            repeat: false
            onTriggered: Activity.onNextRoundTimeout()
        }

        Row {
            id: hud
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                margins: GCStyle.baseMargins
            }
            spacing: GCStyle.baseMargins

            HudBadge {
                label: qsTr("Puntos")
                value: items.score
            }
            HudBadge {
                label: qsTr("Récord")
                value: items.highScore
            }
        }

        Item {
            id: playArea
            anchors {
                top: hud.bottom
                bottom: bar.top
                left: parent.left
                right: parent.right
                margins: GCStyle.baseMargins
            }

            readonly property real circleSize: Math.min(width, height) * 0.92

            // The outer dark rim, purely decorative (matches the real toy's
            // black bezel around the 4 colored pads) — plain and static,
            // it doesn't light up itself (that turned out distracting);
            // the shine stays on the pad that's actually lit.
            Rectangle {
                id: outerRim
                anchors.centerIn: parent
                width: playArea.circleSize + GCStyle.baseMargins
                height: width
                radius: width * 0.5
                color: "#12181d"
            }

            Item {
                id: padCircle
                anchors.centerIn: parent
                width: playArea.circleSize
                height: width

                readonly property real half: width * 0.5
                readonly property var padModel: [
                    { tx: 0,               ty: 0,               index: Activity.GREEN,  base: "#1f6b24", lit: "#3ddc45" },
                    { tx: padCircle.half,  ty: 0,               index: Activity.RED,    base: "#a01f1f", lit: "#ff4b4b" },
                    { tx: 0,               ty: padCircle.half,  index: Activity.YELLOW, base: "#b3841a", lit: "#ffd83d" },
                    { tx: padCircle.half,  ty: padCircle.half,  index: Activity.BLUE,   base: "#144f96", lit: "#3d8bff" }
                ]

                Repeater {
                    model: padCircle.padModel

                    delegate: Item {
                        id: padTile
                        required property var modelData

                        x: modelData.tx
                        y: modelData.ty
                        width: padCircle.half
                        height: padCircle.half
                        clip: true

                        Rectangle {
                            // One shared circle (same absolute size/position
                            // in every tile) clipped differently by each
                            // tile — together the 4 tiles exactly reconstruct
                            // the full circle, one quarter each. No arc/path
                            // geometry needed, so nothing to get the winding
                            // direction of wrong.
                            x: -padTile.modelData.tx
                            y: -padTile.modelData.ty
                            width: padCircle.width
                            height: padCircle.width
                            radius: width * 0.5
                            color: items.litPad === padTile.modelData.index ? padTile.modelData.lit : padTile.modelData.base

                            Behavior on color { ColorAnimation { duration: 80 } }
                        }

                        // A bright white flash layered on top while this
                        // pad is lit, so it visibly shines rather than just
                        // swapping to a slightly different color.
                        Rectangle {
                            x: -padTile.modelData.tx
                            y: -padTile.modelData.ty
                            width: padCircle.width
                            height: padCircle.width
                            radius: width * 0.5
                            color: "#ffffff"
                            opacity: items.litPad === padTile.modelData.index ? 0.5 : 0
                            Behavior on opacity { NumberAnimation { duration: 80 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: Activity.padPressed(padTile.modelData.index)
                        }
                    }
                }
            }

            // Center console.
            Rectangle {
                anchors.centerIn: padCircle
                width: padCircle.width * 0.4
                height: width
                radius: width * 0.5
                color: "#12181d"
                border.width: GCStyle.thinBorder
                border.color: "#3a4550"

                GCText {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    height: parent.height * 0.8
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    fontSizeMode: Text.Fit
                    minimumPointSize: 7
                    fontSize: GCText.hugeSize * 3
                    font.bold: true
                    color: "#ffffff"
                    text: items.sequence.length
                }
            }
        }

        // Game over overlay.
        Rectangle {
            id: gameOverOverlay
            anchors.fill: parent
            color: GCStyle.grayedBg
            visible: items.gameState === "over"

            Column {
                anchors.centerIn: parent
                spacing: GCStyle.baseMargins * 1.5
                width: Math.min(parent.width * 0.8, 900)

                GCText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    fontSize: GCText.largeSize
                    font.bold: true
                    color: GCStyle.whiteText
                    text: qsTr("¡Fallaste! Llegaste hasta el color número %1").arg(items.score)
                }

                GCButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: GCStyle.bigButtonHeight
                    text: qsTr("Nueva partida")
                    onClicked: Activity.newGame()
                }
            }
        }

        DialogHelp {
            id: dialogHelp
            onClose: activity.home()
        }

        Bar {
            id: bar
            content: BarEnumContent { value: help | home }
            onHelpClicked: activity.displayDialog(dialogHelp)
            onHomeClicked: activity.home()
        }
    }
}
