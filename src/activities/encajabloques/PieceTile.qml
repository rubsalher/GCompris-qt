/* GCompris - PieceTile.qml
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * One tray slot: shows a piece (a handful of little coloured blocks laid
 * out in its shape) or nothing if that slot has already been placed this
 * round, or has been picked up and is currently being dragged.
 *
 * Purely visual — no touch handling of its own. A single touch area
 * spanning the whole play area (in EncajaBloques.qml) handles the actual
 * dragging, because a touch area scoped to just this tile would stop
 * receiving updates the moment the finger drags outside its bounds (same
 * reason erase/fruitslice use one activity-wide touch area instead of one
 * per draggable item).
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma ComponentBehavior: Bound

import QtQuick
import core 1.0
import "../../core"
import "encajabloques.js" as Activity

Item {
    id: tile

    required property var piece // {shapeIndex, colorIndex} or null
    required property bool beingDragged
    required property real slotSize

    readonly property var shapeCells: piece ? Activity.SHAPES[piece.shapeIndex] : []
    readonly property int boundW: {
        var m = 1
        for (var i = 0; i < shapeCells.length; ++i)
            m = Math.max(m, shapeCells[i][1] + 1)
        return m
    }
    readonly property int boundH: {
        var m = 1
        for (var i = 0; i < shapeCells.length; ++i)
            m = Math.max(m, shapeCells[i][0] + 1)
        return m
    }
    // 5.2 so the longest possible piece (5 in a row) always fits with a
    // little breathing room on each side.
    readonly property real miniCell: slotSize / 5.2

    width: slotSize
    height: slotSize

    Rectangle {
        anchors.fill: parent
        radius: GCStyle.halfMargins
        color: GCStyle.lightTransparentBg
        border.width: GCStyle.thinBorder
        border.color: GCStyle.whiteBorder
    }

    Item {
        id: shapeArea
        anchors.centerIn: parent
        width: tile.boundW * tile.miniCell
        height: tile.boundH * tile.miniCell
        // Hidden (not just faded) while its piece is off being dragged, so
        // there is never a moment where it looks like there are two of it.
        visible: tile.piece !== null && !tile.beingDragged

        Repeater {
            model: tile.shapeCells
            delegate: Image {
                id: miniBlock
                required property var modelData
                x: modelData[1] * tile.miniCell
                y: modelData[0] * tile.miniCell
                width: tile.miniCell * 0.9
                height: width
                source: tile.piece
                        ? "qrc:/gcompris/src/activities/encajabloques/resource/block_"
                          + Activity.COLOR_NAMES[tile.piece.colorIndex - 1] + ".svg"
                        : ""
                sourceSize.width: width
                sourceSize.height: height
                fillMode: Image.Stretch
            }
        }
    }
}
