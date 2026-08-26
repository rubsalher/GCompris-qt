/* GCompris - Fruit.qml
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * A single fruit flying in a parabolic arc; position is computed from
 * elapsed time (not accumulated per-frame) so it never drifts.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: fruit

    required property string source
    required property real fruitWidth
    required property real fruitHeight
    required property real spawnX
    required property real spawnY
    required property real vx
    required property real vy0
    required property real gravity

    property real elapsed: 0
    property bool isSliced: false

    signal missed(var fruit)

    width: fruitWidth
    height: fruitHeight
    x: spawnX + vx * elapsed - width / 2
    y: spawnY + vy0 * elapsed + 0.5 * gravity * elapsed * elapsed - height / 2

    Image {
        id: wholeImage
        anchors.fill: parent
        visible: !fruit.isSliced
        source: fruit.source
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectFit
    }

    // The two halves shown once sliced: same image, each clipped to only
    // show its half, so no separate "cut" artwork is needed per fruit.
    Item {
        id: leftHalf
        visible: fruit.isSliced
        width: fruit.width / 2
        height: fruit.height
        clip: true
        Image {
            width: fruit.width
            height: fruit.height
            source: fruit.source
            sourceSize.width: width
            sourceSize.height: height
            fillMode: Image.PreserveAspectFit
        }
    }

    Item {
        id: rightHalf
        visible: fruit.isSliced
        x: fruit.width / 2
        width: fruit.width / 2
        height: fruit.height
        clip: true
        Image {
            x: -fruit.width / 2
            width: fruit.width
            height: fruit.height
            source: fruit.source
            sourceSize.width: width
            sourceSize.height: height
            fillMode: Image.PreserveAspectFit
        }
    }

    Timer {
        interval: 30
        running: !fruit.isSliced
        repeat: true
        onTriggered: {
            fruit.elapsed += interval / 1000
            // fell off the bottom, or flew way off either side (side-launched fruit)
            if (fruit.y > fruit.parent.height ||
                fruit.x < -fruit.parent.width || fruit.x > fruit.parent.width * 2) {
                fruit.missed(fruit)
                fruit.destroy()
            }
        }
    }

    // Returns true the first time it is called (and triggers the slice),
    // false if this fruit was already sliced (avoids double-scoring while
    // the fade-out animation is still running under the finger/pointer).
    function slice(): bool {
        if (isSliced)
            return false
        isSliced = true
        splitAnimation.start()
        return true
    }

    // The two halves tumble apart and fall/fade out — the parent Item itself
    // stops moving (physics Timer is off once isSliced), so this animates
    // each half's own position relative to where the fruit was cut.
    ParallelAnimation {
        id: splitAnimation

        NumberAnimation { target: leftHalf; property: "x"; to: -fruit.width * 0.7; duration: 380; easing.type: Easing.OutQuad }
        NumberAnimation { target: leftHalf; property: "y"; to: fruit.height * 0.6; duration: 380; easing.type: Easing.InQuad }
        NumberAnimation { target: leftHalf; property: "rotation"; to: -40; duration: 380 }
        NumberAnimation { target: leftHalf; property: "opacity"; to: 0; duration: 380 }

        NumberAnimation { target: rightHalf; property: "x"; to: fruit.width * 1.2; duration: 380; easing.type: Easing.OutQuad }
        NumberAnimation { target: rightHalf; property: "y"; to: fruit.height * 0.6; duration: 380; easing.type: Easing.InQuad }
        NumberAnimation { target: rightHalf; property: "rotation"; to: 40; duration: 380 }
        NumberAnimation { target: rightHalf; property: "opacity"; to: 0; duration: 380 }

        onStopped: fruit.destroy()
    }
}
