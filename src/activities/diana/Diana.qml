/* GCompris - Diana.qml
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * A giant target, centered on screen, for a REAL small ball thrown by
 * hand at the screen — the IR touch frame reports wherever it actually
 * hits as a tap, same as any other touch, and that's scored by which
 * colored ring it landed in. Score sits to the right, clear of the
 * target itself. A turn is 3 throws, with a mandatory 5 second pause
 * after each one (time to go fetch the real ball and bring it back).
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma ComponentBehavior: Bound

import QtQuick
import core 1.0
import "../../core"
import "diana.js" as Activity

ActivityBase {
    id: activity
    focus: true

    onStart: focus = true
    onStop: {}

    pageComponent: Rectangle {
        id: activityBackground
        color: "#3f6b4a"
        focus: true

        signal start
        signal stop

        Component.onCompleted: {
            activity.start.connect(start)
            activity.stop.connect(stop)
        }

        QtObject {
            id: items
            property int throwsInTurn: 0
            property int turnScore: 0
            property int lastPoints: -1
            property bool locked: false
            property bool turnComplete: false
            property int cooldownRemaining: 0
            property alias hitSound: hitSound
            property alias missSound: missSound
            property alias cooldownTimer: cooldownTimer
        }

        onStart: Activity.start(activity, items)
        onStop: Activity.stop()

        GCSoundEffect {
            id: hitSound
            source: "qrc:/gcompris/src/core/resource/sounds/bonus.wav"
        }
        GCSoundEffect {
            id: missSound
            source: "qrc:/gcompris/src/core/resource/sounds/audioclick.wav"
        }

        Timer {
            id: cooldownTimer
            interval: 1000
            repeat: true
            onTriggered: Activity.cooldownTick()
        }

        Item {
            id: playArea
            anchors {
                top: parent.top
                bottom: bar.top
                left: parent.left
                right: parent.right
                margins: GCStyle.baseMargins
            }

            readonly property real scorePanelWidth: Math.min(width * 0.2, 260 * ApplicationInfo.ratio)
            // Sized off the height (the limiting dimension on a landscape
            // screen) and centered in the FULL width — with a giant target
            // this still comfortably leaves room in the margin on the
            // right for the score panel, without needing to fight the
            // target for centering.
            readonly property real targetDiameter: height * 0.96

            Item {
                id: targetArea
                width: playArea.targetDiameter
                height: width
                anchors.centerIn: playArea

                // Rings, largest first — each later (smaller) one is simply
                // drawn on top of the previous, so together they tile into
                // a perfect bullseye with no arc/path geometry needed.
                Repeater {
                    model: Activity.RINGS

                    delegate: Rectangle {
                        id: ringDelegate
                        required property var modelData
                        anchors.centerIn: parent
                        width: targetArea.width * ringDelegate.modelData.factor
                        height: width
                        radius: width * 0.5
                        color: ringDelegate.modelData.color
                        border.width: GCStyle.thinnestBorder
                        border.color: "#33000000"
                    }
                }

                // Point values printed along the lower spoke of the
                // target, one per ring band, so it's always clear how
                // much each color is worth.
                Repeater {
                    model: Activity.RINGS

                    delegate: GCText {
                        id: pointLabel
                        required property var modelData
                        readonly property real midFactor: (modelData.factor + modelData.innerFactor) * 0.5
                        x: targetArea.width * 0.5 - width * 0.5
                        y: targetArea.height * 0.5 + targetArea.height * 0.5 * midFactor - height * 0.5
                        text: modelData.points
                        font.bold: true
                        fontSize: GCText.mediumSize
                        color: modelData.textColor
                    }
                }
            }

            // The whole play area is the detection zone — the real ball
            // can hit anywhere on screen, not just close to the target,
            // and a real physical throw missing the target entirely should
            // still register (as a 0-point miss) rather than being
            // silently ignored.
            MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => {
                    var tapX = mouse.x - targetArea.x - targetArea.width * 0.5;
                    var tapY = mouse.y - targetArea.y - targetArea.height * 0.5;
                    var result = Activity.throwAt(tapX, tapY, targetArea.width * 0.5);
                    if (result === null)
                        return;

                    impactMark.x = mouse.x - impactMark.width * 0.5;
                    impactMark.y = mouse.y - impactMark.height * 0.5;
                    scoreText.text = result.points > 0 ? ("+" + result.points) : qsTr("¡Fuera!");
                    scoreText.x = mouse.x - scoreText.implicitWidth * 0.5;
                    scoreText.y = mouse.y - impactMark.height * 0.5 - scoreText.implicitHeight;
                    impactAnim.restart();
                }
            }

            // Marks exactly where the real ball actually hit the screen —
            // not a simulated thrown ball, just a quick stamp-like flash
            // with the points earned, since the real throw already
            // happened by the time this appears.
            Image {
                id: impactMark
                source: "qrc:/gcompris/src/activities/diana/resource/ball.svg"
                width: targetArea.width * 0.09
                height: width
                sourceSize.width: width
                sourceSize.height: width
                opacity: 0
                scale: 0.85
                z: 10
            }

            GCText {
                id: scoreText
                opacity: 0
                font.bold: true
                fontSize: GCText.largeSize
                color: "#ffffff"
                style: Text.Outline
                styleColor: "#00000090"
                z: 11
            }

            SequentialAnimation {
                id: impactAnim
                ParallelAnimation {
                    NumberAnimation { target: impactMark; property: "opacity"; to: 1; duration: 80 }
                    NumberAnimation { target: impactMark; property: "scale"; to: 1.0; duration: 120; easing.type: Easing.OutQuad }
                    NumberAnimation { target: scoreText; property: "opacity"; to: 1; duration: 80 }
                }
                PauseAnimation { duration: 550 }
                ParallelAnimation {
                    NumberAnimation { target: impactMark; property: "opacity"; to: 0; duration: 250 }
                    NumberAnimation { target: scoreText; property: "opacity"; to: 0; duration: 250 }
                }
                ScriptAction { script: Activity.throwFinished() }
            }

            Column {
                id: scorePanel
                anchors {
                    right: playArea.right
                    verticalCenter: playArea.verticalCenter
                }
                width: playArea.scorePanelWidth
                spacing: GCStyle.baseMargins

                HudBadge {
                    anchors.horizontalCenter: parent.horizontalCenter
                    label: qsTr("Puntos")
                    value: items.turnScore
                }

                GCText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    fontSize: GCText.mediumSize
                    font.bold: true
                    color: GCStyle.whiteText
                    text: qsTr("Tiro %1 de %2").arg(Math.min(items.throwsInTurn + 1, Activity.THROWS_PER_TURN)).arg(Activity.THROWS_PER_TURN)
                }

                GCText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    fontSize: GCText.mediumSize
                    color: GCStyle.whiteText
                    visible: items.cooldownRemaining > 0
                    text: qsTr("Espera %1 s…").arg(items.cooldownRemaining)
                }
            }
        }

        // Turn complete: no more time pressure than the throws
        // themselves — the next turn only starts once this button is
        // tapped, whenever that is.
        Rectangle {
            id: turnCompleteOverlay
            anchors.fill: parent
            color: GCStyle.grayedBg
            visible: items.turnComplete

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
                    text: qsTr("¡Turno terminado! Puntos conseguidos: %1").arg(items.turnScore)
                }

                GCButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: GCStyle.bigButtonHeight
                    text: qsTr("Nuevo turno")
                    onClicked: Activity.newTurn()
                }
            }
        }

        DialogHelp {
            id: dialogHelp
            onClose: activity.home()
        }

        Bar {
            id: bar
            content: BarEnumContent { value: help | home | reload }
            onHelpClicked: activity.displayDialog(dialogHelp)
            onHomeClicked: activity.home()
            onReloadClicked: Activity.newTurn()
        }
    }
}
