/* GCompris - AtrapaManzanas.qml
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * "Atrapamanzanas" — apples fall one by one (sometimes two at once) from a
 * tree at the top of the screen; touch anywhere to slide the basket there
 * and catch them before they hit the ground, within a 60 second countdown.
 * Difficulty (fall speed, spawn rate, chance of two at once) ramps up
 * gently as the round advances. High score is kept between plays.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma ComponentBehavior: Bound

import QtQuick
import core 1.0
import "../../core"
import "atrapamanzanas.js" as Activity

ActivityBase {
    id: activity
    focus: true

    onStart: focus = true
    onStop: {}

    pageComponent: Image {
        id: activityBackground
        source: "qrc:/gcompris/src/activities/atrapamanzanas/resource/background.svg"
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
        readonly property string highScoreKey: "atrapamanzanas-highscore"

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
            property alias spawnTimer: spawnTimer
            property alias countdownTimer: countdownTimer
            property alias catchSound: catchSound
            property alias playArea: playArea
            property alias basket: basket
            readonly property real appleSize: Math.max(64, playArea.width * 0.05)
            onScoreChanged: if (score > highScore) highScore = score
            onHighScoreChanged: ApplicationSettings.setCurrentLevels(activityBackground.highScoreKey, [highScore.toString()])

            function spawnBounds() {
                return {
                    "left": playArea.width * 0.06,
                    "right": playArea.width * 0.94
                }
            }
        }

        onStart: Activity.start(activity, items)
        onStop: Activity.stop()

        GCSoundEffect {
            id: catchSound
            source: "qrc:/gcompris/src/activities/atrapamanzanas/resource/catch.wav"
        }

        // Playing field: food rains down from the top, the basket waits on
        // the ground. Fills the space between the HUD and the bottom bar.
        Item {
            id: playArea
            anchors {
                top: hud.bottom
                bottom: bar.top
                left: parent.left
                right: parent.right
                margins: GCStyle.baseMargins
            }

            // Ground strip, anchored to the real bottom of the play area so
            // it always lines up exactly with the basket, whatever the
            // screen size — drawing it in the static background.svg instead
            // made it drift out of alignment with the basket.
            Rectangle {
                id: ground
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: playArea.height * 0.1
                color: "#9BAE86"
                opacity: 0.55
            }

            Item {
                id: basket
                property real targetX: playArea.width / 2
                width: playArea.width * 0.17
                height: width * (160 / 260)
                x: Math.max(0, Math.min(playArea.width - width, targetX - width / 2))
                y: playArea.height - height

                Behavior on x {
                    NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                }

                Image {
                    anchors.fill: parent
                    source: "qrc:/gcompris/src/activities/atrapamanzanas/resource/basket.svg"
                    sourceSize.width: width
                    sourceSize.height: height
                    fillMode: Image.PreserveAspectFit
                }
            }

            MultiPointTouchArea {
                anchors.fill: parent
                onTouchUpdated: (touchPoints) => {
                    if (touchPoints.length > 0)
                        basket.targetX = touchPoints[0].x
                }
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
            onTriggered: Activity.spawnApple()
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
