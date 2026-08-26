/* GCompris - HammerEffect.qml
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * One-shot hit-feedback animation: a hammer slams down onto a whacked mole
 * and fades out. Purely decorative, destroys itself when done.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: hammerEffect

    required property real targetWidth
    required property real targetHeight
    width: targetWidth
    height: targetHeight
    z: 100

    Image {
        id: hammerImage
        anchors.centerIn: parent
        width: parent.width * 0.9
        height: width * (200 / 140)
        source: "qrc:/gcompris/src/activities/aplastatopos/resource/hammer.svg"
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectFit
        rotation: -28
        y: -hammerEffect.height * 0.55
    }

    SequentialAnimation {
        running: true
        ParallelAnimation {
            NumberAnimation { target: hammerImage; property: "y"; to: 0; duration: 90; easing.type: Easing.InQuad }
            NumberAnimation { target: hammerImage; property: "rotation"; to: 8; duration: 90; easing.type: Easing.InQuad }
        }
        PauseAnimation { duration: 70 }
        NumberAnimation { target: hammerEffect; property: "opacity"; to: 0; duration: 150 }
        onStopped: hammerEffect.destroy()
    }
}
