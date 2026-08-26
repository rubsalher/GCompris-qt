/* GCompris - AplastaTopos.qml
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * "Aplastatopos" — classic whack-a-mole: tap the moles as they pop up at
 * random holes before they hide, within a 60 second countdown. Difficulty
 * (spawn rate, how long each mole stays up, chance of two at once) ramps up
 * gently as the round advances. High score is kept between plays.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma ComponentBehavior: Bound

import QtQuick
import core 1.0
import "../../core"
import "aplastatopos.js" as Activity

ActivityBase {
    id: activity
    focus: true

    onStart: focus = true
    onStop: {}

    pageComponent: Image {
        id: activityBackground
        source: "qrc:/gcompris/src/activities/aplastatopos/resource/background.svg"
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectCrop
        focus: true

        signal start
        signal stop

        // High score key for GCompris's own per-activity settings store
        // (ApplicationSettings.setCurrentLevels/currentLevels) — reused here
        // as a simple persisted value, distinct from any real activity name
        // so it can never collide with actual level-progress data.
        readonly property string highScoreKey: "aplastatopos-highscore"

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
            property int score: 0
            property int highScore: 0
            property int remainingSeconds: Activity.TOTAL_SECONDS
            property string gameState: "ready" // "ready" | "playing" | "over"
            property alias holesRepeater: holesRepeater
            property alias spawnTimer: spawnTimer
            property alias countdownTimer: countdownTimer
            property alias whackSound: whackSound
            onScoreChanged: if (score > highScore) highScore = score
            onHighScoreChanged: ApplicationSettings.setCurrentLevels(activityBackground.highScoreKey, [highScore.toString()])
        }

        onStart: Activity.start(activity, items)
        onStop: Activity.stop()

        GCSoundEffect {
            id: whackSound
            source: "qrc:/gcompris/src/activities/aplastatopos/resource/whack.wav"
        }

        // Playing field: a 3x3 grid of holes, filling the space between the
        // HUD and the bottom bar.
        Item {
            id: board
            anchors {
                top: hud.bottom
                bottom: bar.top
                left: parent.left
                right: parent.right
                margins: GCStyle.baseMargins
            }

            Item {
                id: holesContainer
                anchors.centerIn: parent
                readonly property int columns: 4
                readonly property int rows: 3
                width: parent.width
                height: parent.height

                Repeater {
                    id: holesRepeater
                    model: holesContainer.columns * holesContainer.rows

                    delegate: HoleSlot {
                        id: holeDelegate
                        required property int index
                        holeIndex: index

                        // Cells are sized independently in width/height (not
                        // forced square) since the hole artwork itself is
                        // wider than it is tall — this alone lets each hole
                        // be noticeably bigger without needing a taller grid.
                        readonly property real cellW: holesContainer.width / holesContainer.columns
                        readonly property real cellH: holesContainer.height / holesContainer.rows
                        // Small fixed-per-hole random offset, computed once,
                        // so the layout reads as a hand-placed patch of
                        // ground rather than a rigid checkerboard.
                        readonly property real jitterX: (Math.random() - 0.5) * cellW * 0.18
                        readonly property real jitterY: (Math.random() - 0.5) * cellH * 0.18

                        // 0.8 fill (was 0.95) leaves a real gap between holes
                        // so reaching the next one takes a bit more arm
                        // movement, as asked.
                        width: cellW * 0.8
                        height: width * 0.72

                        x: (index % holesContainer.columns) * cellW + (cellW - width) / 2 + jitterX
                        y: Math.floor(index / holesContainer.columns) * cellH + (cellH - height) / 2 + jitterY
                    }
                }
            }

            // Sibling of holesContainer (not a child!) so childAt() below only
            // ever finds the HoleSlot items themselves, never this touch area.
            MultiPointTouchArea {
                anchors.fill: holesContainer
                onTouchUpdated: (touchPoints) => {
                    for (var i in touchPoints) {
                        var touch = touchPoints[i]
                        var hole = holesContainer.childAt(touch.x, touch.y)
                        if (hole && hole.whack && hole.whack()) {
                            Activity.moleWhacked(hole.isGolden)
                            hammerComponent.createObject(holesContainer, {
                                "targetWidth": hole.width,
                                "targetHeight": hole.height,
                                "x": hole.x,
                                "y": hole.y
                            })
                        }
                    }
                }
            }
        }

        Component {
            id: hammerComponent
            HammerEffect {}
        }

        // HUD: current score, high score and remaining time.
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
            HudBadge {
                label: qsTr("Tiempo")
                value: items.remainingSeconds
                suffix: qsTr("s")
            }
        }

        Timer {
            id: countdownTimer
            interval: 1000
            repeat: true
            onTriggered: Activity.onCountdownTick()
        }

        Timer {
            id: spawnTimer
            repeat: false
            onTriggered: Activity.spawnMole()
        }

        // Start / restart overlay, shown whenever a round isn't in progress.
        Rectangle {
            id: startOverlay
            anchors.fill: parent
            color: GCStyle.grayedBg
            visible: items.gameState !== "playing"

            Column {
                anchors.centerIn: parent
                spacing: GCStyle.baseMargins * 1.5
                width: Math.min(parent.width * 0.8, 900)

                GCText {
                    visible: items.gameState === "over"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    fontSize: GCText.largeSize
                    font.bold: true
                    color: GCStyle.whiteText
                    text: qsTr("¡Partida terminada! Puntuación: %1").arg(items.score)
                }

                GCButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: GCStyle.bigButtonHeight
                    text: items.gameState === "over" ? qsTr("Volver a jugar") : qsTr("Iniciar")
                    onClicked: Activity.startGame()
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
