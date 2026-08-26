/* GCompris - HoleSlot.qml
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * One hole in the "Aplastatopos" grid: a static mound/hole image plus a mole
 * that pops up for a limited time. The whole slot is the touch target
 * (not just the mole's visible shape), for generous hit areas on a large
 * projected screen.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: holeSlot

    required property int holeIndex
    readonly property bool isMoleUp: moleUp && !isHit

    property bool moleUp: false
    property bool isHit: false
    // Golden mole = worth more points. Set by popUp(), read by the activity
    // right after a successful whack() to know how many points to award.
    property bool isGolden: false

    // hole.svg is 240x160 with its dark opening ellipse fixed at
    // cx120 cy88 rx66 ry28 — keep this box the exact same aspect ratio
    // (no letterboxing) so the fractions below line up pixel-for-pixel
    // with that opening, and the mole looks like it truly comes out of it.
    readonly property real holeAspect: 160 / 240

    Image {
        id: holeImage
        width: parent.width
        height: parent.width * holeSlot.holeAspect
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: parent.height * 0.04
        }
        source: "qrc:/gcompris/src/activities/aplastatopos/resource/hole.svg"
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectFit
    }

    // Peek window: full height of the mound down to the *bottom* of the
    // drawn opening (fraction 0.725 of holeImage's height — the ellipse
    // cx120 cy88 rx66 ry28 in the 240x160 viewBox), but only as wide as the
    // opening itself (fraction [0.225, 0.775]) so the mole still looks like
    // it's coming out of that hole specifically, not the whole mound.
    // Tall enough that the mole's whole head clears it (previous, tighter
    // window was cropping the ears/top of the head off).
    Item {
        id: moleClip
        x: holeImage.x + holeImage.width * 0.225
        y: holeImage.y
        width: holeImage.width * 0.55
        height: holeImage.height * 0.725
        clip: true

        Image {
            id: moleImage
            width: moleClip.width * 1.1
            height: width * (220 / 200) // mole.svg aspect ratio
            anchors.horizontalCenter: parent.horizontalCenter
            // Popped up: top-aligned to the window, showing the mole from
            // the ears down to just above the belly/paws. Parked: pushed
            // fully below the window, out of sight.
            y: (holeSlot.moleUp && !holeSlot.isHit) ? 0 : moleClip.height
            source: holeSlot.isGolden
                    ? "qrc:/gcompris/src/activities/aplastatopos/resource/mole_gold.svg"
                    : "qrc:/gcompris/src/activities/aplastatopos/resource/mole.svg"
            sourceSize.width: width
            sourceSize.height: height
            fillMode: Image.PreserveAspectFit
            scale: holeSlot.isHit ? 0.6 : 1.0
            opacity: holeSlot.isHit ? 0 : 1

            Behavior on y {
                NumberAnimation { duration: 170; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
            }
            Behavior on scale {
                NumberAnimation { duration: 150; easing.type: Easing.InQuad }
            }
            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
        }
    }

    Timer {
        id: upTimer
        repeat: false
        onTriggered: holeSlot.moleUp = false
    }

    Timer {
        id: hitClearTimer
        interval: 160
        repeat: false
        onTriggered: holeSlot.moleUp = false
    }

    // Called by the activity's spawn logic to make a mole appear here for
    // durationMs milliseconds if not whacked before that. golden marks the
    // rarer, higher-value variant.
    function popUp(durationMs, golden) {
        isHit = false
        isGolden = !!golden
        hitClearTimer.stop()
        moleUp = true
        upTimer.interval = durationMs
        upTimer.restart()
    }

    // Called on tap/click. Returns true the first time it hits an up mole
    // (and triggers the squish), false otherwise (empty hole, or already hit).
    // Check isGolden right after this returns true to know the point value.
    function whack(): bool {
        if (!isMoleUp)
            return false
        isHit = true
        upTimer.stop()
        hitClearTimer.restart()
        return true
    }

    // Force an immediate, unanimated reset (used when stopping/restarting the game).
    function reset() {
        upTimer.stop()
        hitClearTimer.stop()
        isHit = false
        moleUp = false
    }
}
