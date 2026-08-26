/* GCompris - Apple.qml
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * A single food item (apple, banana, grapes, ...) falling straight down at
 * a constant speed; position is computed from elapsed time (not
 * accumulated per-frame) so it never drifts. Checks each tick whether it
 * has landed inside the basket.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: apple

    required property string source
    required property real appleSize
    required property real spawnX
    required property real startY
    required property real fallDurationMs
    required property real groundY
    required property Item basket

    property real elapsed: 0
    property bool isCaught: false

    signal caught(var apple)
    signal missed(var apple)

    readonly property real fallDurationSec: fallDurationMs / 1000

    width: appleSize
    height: appleSize
    x: spawnX - width / 2
    y: startY + (groundY - startY) * Math.min(elapsed / fallDurationSec, 1)
    opacity: isCaught ? 0 : 1
    scale: isCaught ? 0.5 : 1.0

    Image {
        anchors.fill: parent
        source: apple.source
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectFit
    }

    Behavior on opacity { NumberAnimation { duration: 150 } }
    Behavior on scale { NumberAnimation { duration: 150 } }

    Timer {
        interval: 30
        running: !apple.isCaught
        repeat: true
        onTriggered: {
            apple.elapsed += interval / 1000

            var appleCenterX = apple.x + apple.width / 2
            var appleBottom = apple.y + apple.height

            if (appleBottom >= apple.basket.y && appleBottom <= apple.basket.y + apple.basket.height &&
                appleCenterX >= apple.basket.x && appleCenterX <= apple.basket.x + apple.basket.width) {
                apple.isCaught = true
                apple.caught(apple)
                catchTimer.start()
            } else if (apple.elapsed >= apple.fallDurationSec) {
                apple.missed(apple)
                apple.destroy()
            }
        }
    }

    Timer {
        id: catchTimer
        interval: 160
        repeat: false
        onTriggered: apple.destroy()
    }
}
