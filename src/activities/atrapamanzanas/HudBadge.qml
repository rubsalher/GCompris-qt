/* GCompris - HudBadge.qml
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * A small labelled value badge for the top HUD (score / high score / time),
 * styled like core's Score.qml so it matches the rest of the app.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma ComponentBehavior: Bound

import QtQuick
import core 1.0
import "../../core"

Rectangle {
    id: badge

    required property string label
    required property int value
    property string suffix: ""

    color: GCStyle.lightTransparentBg
    radius: GCStyle.halfMargins
    border.color: GCStyle.whiteBorder
    border.width: GCStyle.thinBorder
    width: content.implicitWidth + 2 * GCStyle.baseMargins
    height: content.implicitHeight + GCStyle.baseMargins

    Column {
        id: content
        anchors.centerIn: parent
        spacing: 2

        GCText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: badge.label
            fontSize: GCText.smallSize
            color: GCStyle.darkText
        }
        GCText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: badge.value + badge.suffix
            fontSize: GCText.largeSize
            font.bold: true
            color: GCStyle.highlightColor
        }
    }
}
