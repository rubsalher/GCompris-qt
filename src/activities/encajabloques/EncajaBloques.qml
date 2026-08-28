/* GCompris - EncajaBloques.qml
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * "Encaja bloques" — a block-fitting puzzle inspired by "Block Blast":
 * drag pieces from a tray of 3 onto an 8x8 board, completing full
 * rows/columns to clear them and score points. No time limit; the round
 * ends when none of the 3 current pieces fit anywhere on the board.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma ComponentBehavior: Bound

import QtQuick
import core 1.0
import "../../core"
import "encajabloques.js" as Activity

ActivityBase {
    id: activity
    focus: true

    onStart: focus = true
    onStop: {}

    pageComponent: Rectangle {
        id: activityBackground
        // Dark backdrop (at the user's request) — also makes the coloured
        // blocks themselves stand out more than on a light background.
        color: "#1E2A38"
        focus: true

        signal start
        signal stop

        // High score key for GCompris's own per-activity settings store
        // (ApplicationSettings.setCurrentLevels/currentLevels) — reused here
        // as a simple persisted value, distinct from any real activity name
        // so it can never collide with actual level-progress data.
        readonly property string highScoreKey: "encajabloques-highscore"

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
            property var gridColors: []
            property var pieces: []
            property int draggingSlot: -1
            property var previewCells: []
            property bool previewValid: false
            property int score: 0
            property int highScore: 0
            property string gameState: "playing" // "playing" | "over"
            // Toggled (not a fixed value) each time a placement attempt is
            // invalid, purely so a bound handler can react to it happening.
            property bool invalidPlacementPing: false
            property alias placeSound: placeSound
            property alias clearSound: clearSound

            onScoreChanged: if (score > highScore) highScore = score
            onHighScoreChanged: ApplicationSettings.setCurrentLevels(activityBackground.highScoreKey, [highScore.toString()])
            onInvalidPlacementPingChanged: invalidSound.play()
        }

        onStart: Activity.start(activity, items)
        onStop: Activity.stop()

        GCSoundEffect {
            id: placeSound
            source: "qrc:/gcompris/src/activities/encajabloques/resource/place.wav"
        }
        GCSoundEffect {
            id: clearSound
            source: "qrc:/gcompris/src/activities/encajabloques/resource/clear.wav"
        }
        GCSoundEffect {
            id: invalidSound
            source: "qrc:/gcompris/src/core/resource/sounds/crash.wav"
        }

        // HUD: current score and high score.
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
        }

        // Board + piece tray. Fills the space between the HUD and the
        // bottom bar.
        Item {
            id: playArea
            anchors {
                top: hud.bottom
                bottom: bar.top
                left: parent.left
                right: parent.right
                margins: GCStyle.baseMargins
            }

            readonly property real trayHeight: height * 0.24
            readonly property real boardAvailableHeight: height - trayHeight - GCStyle.baseMargins
            readonly property real cellSize: Math.min(width / Activity.GRID_SIZE, boardAvailableHeight / Activity.GRID_SIZE)
            readonly property real boardPixelSize: cellSize * Activity.GRID_SIZE

            // Where a piece currently being dragged would land: the board
            // cell under the ghost's own top-left corner. Only meaningful
            // while items.draggingSlot !== -1.
            function ghostCell() {
                var bx = ghost.x - board.x
                var by = ghost.y - board.y
                return {
                    "row": Math.round(by / playArea.cellSize),
                    "col": Math.round(bx / playArea.cellSize)
                }
            }

            // Index (0/1/2) of the tray slot under local point (x,y), or -1.
            function traySlotAt(x, y) {
                for (var i = 0; i < trayRepeater.count; ++i) {
                    var tile = trayRepeater.itemAt(i)
                    if (!tile)
                        continue
                    var topLeft = tile.mapToItem(playArea, 0, 0)
                    if (x >= topLeft.x && x <= topLeft.x + tile.width &&
                        y >= topLeft.y && y <= topLeft.y + tile.height) {
                        return i
                    }
                }
                return -1
            }

            function updateGhost(x, y) {
                ghost.x = x - ghost.width / 2
                ghost.y = y - ghost.height - playArea.cellSize
                var cell = ghostCell()
                Activity.updateDragPosition(cell.row, cell.col)
            }

            Item {
                id: board
                width: playArea.boardPixelSize
                height: playArea.boardPixelSize
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                }

                Repeater {
                    id: cellsRepeater
                    model: Activity.GRID_SIZE * Activity.GRID_SIZE

                    delegate: Item {
                        id: cellDelegate
                        required property int index
                        readonly property int row: Math.floor(index / Activity.GRID_SIZE)
                        readonly property int col: index % Activity.GRID_SIZE
                        readonly property int colorIndex: items.gridColors.length > index ? items.gridColors[index] : 0
                        readonly property bool previewed: items.previewCells.indexOf(index) !== -1

                        x: col * playArea.cellSize
                        y: row * playArea.cellSize
                        width: playArea.cellSize
                        height: playArea.cellSize

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1.5
                            radius: 3
                            color: GCStyle.whiteBg
                            border.width: GCStyle.thinnestBorder
                            border.color: GCStyle.lightGrayBorder
                        }

                        Image {
                            anchors.fill: parent
                            anchors.margins: 1.5
                            visible: cellDelegate.colorIndex !== 0
                            opacity: cellDelegate.colorIndex !== 0 ? 1 : 0
                            source: cellDelegate.colorIndex !== 0
                                    ? "qrc:/gcompris/src/activities/encajabloques/resource/block_"
                                      + Activity.COLOR_NAMES[cellDelegate.colorIndex - 1] + ".svg"
                                    : ""
                            sourceSize.width: width
                            sourceSize.height: height
                            fillMode: Image.Stretch

                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        // Live drag preview: where the dragged piece would
                        // land if dropped right now, green if valid, red
                        // if not — this is what gives the precision the
                        // user asked for.
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1.5
                            radius: 3
                            visible: cellDelegate.previewed
                            color: items.previewValid ? "#992E7D32" : "#99C62828"
                        }
                    }
                }
            }

            Row {
                id: trayRow
                anchors {
                    top: board.bottom
                    topMargin: GCStyle.baseMargins
                    horizontalCenter: parent.horizontalCenter
                }
                spacing: GCStyle.baseMargins

                Repeater {
                    id: trayRepeater
                    model: 3

                    delegate: PieceTile {
                        id: pieceTile
                        required property int index
                        piece: items.pieces.length > index ? items.pieces[index] : null
                        beingDragged: items.draggingSlot === index
                        slotSize: Math.min(playArea.trayHeight * 0.95, playArea.cellSize * 4.6)
                    }
                }
            }

            // The piece currently being dragged, following the touch point
            // (lifted above it so the finger doesn't hide it).
            Item {
                id: ghost
                z: 500
                visible: items.draggingSlot !== -1
                property var piece: items.draggingSlot !== -1 && items.pieces.length > items.draggingSlot
                                     ? items.pieces[items.draggingSlot] : null
                readonly property var shapeCells: piece ? Activity.SHAPES[piece.shapeIndex] : []
                readonly property real cellPx: playArea.cellSize * 0.94
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
                width: boundW * cellPx
                height: boundH * cellPx

                Repeater {
                    model: ghost.shapeCells
                    delegate: Image {
                        id: ghostBlock
                        required property var modelData
                        x: modelData[1] * ghost.cellPx
                        y: modelData[0] * ghost.cellPx
                        width: ghost.cellPx * 0.94
                        height: width
                        source: ghost.piece
                                ? "qrc:/gcompris/src/activities/encajabloques/resource/block_"
                                  + Activity.COLOR_NAMES[ghost.piece.colorIndex - 1] + ".svg"
                                : ""
                        sourceSize.width: width
                        sourceSize.height: height
                        fillMode: Image.Stretch
                    }
                }
            }

            // One touch area for the whole play area (board + tray), not
            // one per piece — a touch area scoped to a single tray tile
            // would stop receiving updates once the finger drags outside
            // that tile's own bounds (same reason erase/fruitslice use a
            // single activity-wide touch area for their own dragging).
            MultiPointTouchArea {
                id: masterTouch
                anchors.fill: parent
                property int activePointId: -1

                onPressed: (touchPoints) => {
                    if (masterTouch.activePointId !== -1 || touchPoints.length === 0)
                        return
                    var p = touchPoints[0]
                    var slot = playArea.traySlotAt(p.x, p.y)
                    if (slot === -1)
                        return
                    masterTouch.activePointId = p.pointId
                    Activity.beginDrag(slot)
                    playArea.updateGhost(p.x, p.y)
                }
                onTouchUpdated: (touchPoints) => {
                    if (masterTouch.activePointId === -1)
                        return
                    for (var i = 0; i < touchPoints.length; ++i) {
                        if (touchPoints[i].pointId === masterTouch.activePointId) {
                            playArea.updateGhost(touchPoints[i].x, touchPoints[i].y)
                            return
                        }
                    }
                }
                onReleased: (touchPoints) => {
                    if (masterTouch.activePointId === -1)
                        return
                    for (var i = 0; i < touchPoints.length; ++i) {
                        if (touchPoints[i].pointId === masterTouch.activePointId) {
                            playArea.updateGhost(touchPoints[i].x, touchPoints[i].y)
                            break
                        }
                    }
                    var cell = playArea.ghostCell()
                    Activity.endDrag(cell.row, cell.col)
                    masterTouch.activePointId = -1
                }
                onCanceled: (touchPoints) => {
                    if (masterTouch.activePointId === -1)
                        return
                    Activity.cancelDrag()
                    masterTouch.activePointId = -1
                }
            }
        }

        // Game over overlay.
        Rectangle {
            id: gameOverOverlay
            anchors.fill: parent
            color: GCStyle.grayedBg
            visible: items.gameState === "over"

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
                    text: qsTr("¡Partida terminada! Puntuación: %1").arg(items.score)
                }

                GCButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: GCStyle.bigButtonHeight
                    text: qsTr("Nueva partida")
                    onClicked: Activity.newGame()
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
