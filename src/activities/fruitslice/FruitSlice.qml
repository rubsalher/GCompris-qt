/* GCompris - FruitSlice.qml
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * "Corta la fruta" — drag over the fruit launched from the bottom of the
 * screen to slice it. Meant to encourage reaching across a large
 * (projected / touch-frame) screen with the arm, not just a small tap.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma ComponentBehavior: Bound

import QtQuick
import core 1.0
import "../../core"
import "fruitslice.js" as Activity

ActivityBase {
    id: activity
    focus: true

    onStart: focus = true
    onStop: {}

    onActivityNextLevel: Activity.nextLevel()

    pageComponent: Image {
        id: activityBackground
        source: "qrc:/gcompris/src/activities/fruitslice/resource/background.svg"
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectCrop
        focus: true

        signal start
        signal stop

        Component.onCompleted: {
            activity.start.connect(start)
            activity.stop.connect(stop)
        }

        QtObject {
            id: items
            property int currentLevel: activity.currentLevel
            onCurrentLevelChanged: activity.currentLevel = currentLevel
            property int numberOfLevel: 0
            onNumberOfLevelChanged: activity.numberOfLevel = numberOfLevel
            property alias score: score
            property alias fruitContainer: fruitContainer
            property alias crashSound: crashSound
            property alias winSound: winSound
            property real spawnInterval: 3200
            property real doubleChance: 0.1
            property real speedFactor: 1.0
        }

        onStart: Activity.start(activity, activityBackground, bar, bonus, items)
        onStop: {
            Activity.stop()
            spawnTimer.stop()
        }

        GCSoundEffect {
            id: crashSound
            source: "qrc:/gcompris/src/activities/fruitslice/resource/slice.wav"
        }

        GCSoundEffect {
            id: winSound
            source: "qrc:/gcompris/src/core/resource/sounds/win.wav"
        }

        Item {
            id: fruitContainer
            anchors.fill: parent
            clip: true
        }

        // Trail segments live in their own layer, on top of the fruit so the
        // slice mark is visible, but kept separate from fruitContainer so it
        // never interferes with the childAt() hit-testing used to detect
        // which fruit is under the finger/pointer.
        Item {
            id: trailContainer
            anchors.fill: parent
            clip: true
        }

        Component {
            id: trailSegmentComponent
            Rectangle {
                id: segment
                required property real x1
                required property real y1
                required property real x2
                required property real y2
                height: 8
                radius: height / 2
                color: GCStyle.whiteBg
                opacity: 0.9
                width: Math.hypot(x2 - x1, y2 - y1) + height
                x: x1
                y: y1 - height / 2
                transformOrigin: Item.Left
                rotation: Math.atan2(y2 - y1, x2 - x1) * 180 / Math.PI

                NumberAnimation on opacity {
                    to: 0
                    duration: 250
                    running: true
                    onStopped: segment.destroy()
                }
            }
        }

        Timer {
            id: spawnTimer
            interval: items.spawnInterval
            running: true
            repeat: true
            onTriggered: Activity.spawnTick()
        }

        MultiPointTouchArea {
            anchors.fill: fruitContainer
            onTouchUpdated: (touchPoints) => {
                for (var i in touchPoints) {
                    var touch = touchPoints[i]

                    // visual slice trail, drawn between the last and current
                    // position of this finger/pointer
                    if (touch.previousX !== touch.x || touch.previousY !== touch.y) {
                        trailSegmentComponent.createObject(trailContainer, {
                            "x1": touch.previousX,
                            "y1": touch.previousY,
                            "x2": touch.x,
                            "y2": touch.y
                        })
                    }

                    var hit = fruitContainer.childAt(touch.x, touch.y)
                    if (hit && hit.slice && hit.slice()) {
                        Activity.fruitSliced(hit)
                    }
                }
            }
        }

        DialogHelp {
            id: dialogHelp
            onClose: activity.home()
        }

        Score {
            id: score
            anchors {
                top: parent.top
                right: parent.right
                margins: GCStyle.baseMargins
            }
        }

        Bar {
            id: bar
            level: items.currentLevel + 1
            content: BarEnumContent { value: help | home | level }
            onHelpClicked: activity.displayDialog(dialogHelp)
            onPreviousLevelClicked: Activity.previousLevel()
            onNextLevelClicked: Activity.nextLevel()
            onHomeClicked: activity.home()
        }

        Bonus {
            id: bonus
            Component.onCompleted: win.connect(activity.nextLevel)
        }
    }
}
