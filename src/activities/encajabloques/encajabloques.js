/* GCompris - encajabloques.js
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * A block-fitting puzzle inspired by "Block Blast": place pieces on an 8x8
 * board to complete full rows/columns, which then clear and score points.
 * No time limit. Game ends when none of the current 3 pieces fit anywhere.
 *
 * Interaction: drag a tray piece onto the board — the board shows a live
 * green/red preview of where it would land while dragging, for precision.
 * Releasing over an invalid spot just cancels the drop (piece returns to
 * its tray slot); no penalty either way.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
.pragma library

var GRID_SIZE = 8
var TRAY_SIZE = 3

// Colour palette cycled through for pieces (indices 1..N in the grid model;
// 0 always means "empty cell").
var COLOR_NAMES = ["blue", "gold", "purple", "green", "red"]

// Every shape is a list of [row, col] offsets, normalised so all rows/cols
// are >= 0 (the shape's own bounding box starts at 0,0 — that box's
// top-left corner is what a tap on the board places, whether or not that
// particular corner cell is itself part of the shape).
var SHAPES = [
    // single cell
    [[0,0]],
    // dominoes
    [[0,0],[0,1]],
    [[0,0],[1,0]],
    // trominoes (line)
    [[0,0],[0,1],[0,2]],
    [[0,0],[1,0],[2,0]],
    // tetromino line
    [[0,0],[0,1],[0,2],[0,3]],
    [[0,0],[1,0],[2,0],[3,0]],
    // pentomino line
    [[0,0],[0,1],[0,2],[0,3],[0,4]],
    [[0,0],[1,0],[2,0],[3,0],[4,0]],
    // squares
    [[0,0],[0,1],[1,0],[1,1]],
    [[0,0],[0,1],[0,2],[1,0],[1,1],[1,2],[2,0],[2,1],[2,2]],
    // corner trominoes
    [[0,0],[0,1],[1,0]],
    [[0,0],[0,1],[1,1]],
    [[0,0],[1,0],[1,1]],
    [[0,1],[1,0],[1,1]],
    // L tetromino, 4 rotations
    [[0,0],[1,0],[2,0],[2,1]],
    [[0,0],[0,1],[0,2],[1,0]],
    [[0,0],[0,1],[1,1],[2,1]],
    [[1,0],[1,1],[1,2],[0,2]],
    // J tetromino, 4 rotations
    [[0,1],[1,1],[2,0],[2,1]],
    [[0,0],[1,0],[1,1],[1,2]],
    [[0,0],[0,1],[1,0],[2,0]],
    [[0,0],[0,1],[0,2],[1,2]],
    // S / Z tetromino
    [[0,1],[0,2],[1,0],[1,1]],
    [[0,0],[0,1],[1,1],[1,2]],
    [[0,0],[1,0],[1,1],[2,1]],
    [[0,1],[1,0],[1,1],[2,0]],
    // T tetromino, 4 rotations
    [[0,0],[0,1],[0,2],[1,1]],
    [[0,1],[1,0],[1,1],[1,2]],
    [[0,0],[1,0],[1,1],[2,0]],
    [[0,1],[1,0],[1,1],[2,1]]
]

var items
var activity

function start(activity_, items_) {
    activity = activity_
    items = items_
    newGame()
}

function stop() {
}

function newGame() {
    var grid = new Array(GRID_SIZE * GRID_SIZE).fill(0)
    items.gridColors = grid
    items.score = 0
    items.draggingSlot = -1
    items.previewCells = []
    items.previewValid = false
    items.gameState = "playing"
    items.pieces = generateTray()
    checkGameOver()
}

function cellIndex(row, col) {
    return row * GRID_SIZE + col
}

function generatePiece() {
    var shapeIndex = Math.floor(Math.random() * SHAPES.length)
    var colorIndex = 1 + Math.floor(Math.random() * COLOR_NAMES.length)
    return { "shapeIndex": shapeIndex, "colorIndex": colorIndex }
}

function generateTray() {
    var tray = []
    for (var i = 0; i < TRAY_SIZE; ++i)
        tray.push(generatePiece())
    return tray
}

// Whether `shape` fits with its bounding-box top-left corner at (row, col).
function canPlaceAt(shape, row, col) {
    for (var i = 0; i < shape.length; ++i) {
        var r = row + shape[i][0]
        var c = col + shape[i][1]
        if (r < 0 || r >= GRID_SIZE || c < 0 || c >= GRID_SIZE)
            return false
        if (items.gridColors[cellIndex(r, c)] !== 0)
            return false
    }
    return true
}

function canPlaceAnywhere(shape) {
    for (var r = 0; r < GRID_SIZE; ++r) {
        for (var c = 0; c < GRID_SIZE; ++c) {
            if (canPlaceAt(shape, r, c))
                return true
        }
    }
    return false
}

// --- Drag lifecycle, driven by touch events forwarded from the QML side ---

function beginDrag(slotIndex) {
    if (items.gameState !== "playing")
        return
    if (!items.pieces[slotIndex])
        return
    items.draggingSlot = slotIndex
}

// Called continuously while dragging, with the board cell (row, col) the
// piece's bounding-box top-left corner is currently over (may be out of
// bounds while hovering elsewhere, e.g. still over the tray).
function updateDragPosition(row, col) {
    if (items.draggingSlot === -1)
        return
    var piece = items.pieces[items.draggingSlot]
    if (!piece)
        return
    var shape = SHAPES[piece.shapeIndex]
    var cells = []
    for (var i = 0; i < shape.length; ++i) {
        var r = row + shape[i][0]
        var c = col + shape[i][1]
        if (r >= 0 && r < GRID_SIZE && c >= 0 && c < GRID_SIZE)
            cells.push(cellIndex(r, c))
    }
    items.previewCells = cells
    items.previewValid = canPlaceAt(shape, row, col)
}

function clearPreview() {
    items.previewCells = []
    items.previewValid = false
}

// Called on release, with the board cell (row, col) under the touch point
// (may be out of bounds, e.g. released back over the tray).
function endDrag(row, col) {
    var slot = items.draggingSlot
    items.draggingSlot = -1
    clearPreview()
    if (slot === -1)
        return

    var piece = items.pieces[slot]
    if (!piece)
        return
    var shape = SHAPES[piece.shapeIndex]
    if (row < 0 || row >= GRID_SIZE || col < 0 || col >= GRID_SIZE || !canPlaceAt(shape, row, col)) {
        items.invalidPlacementPing = !items.invalidPlacementPing
        return
    }
    commitPlacement(slot, row, col)
}

// Touch was lost mid-drag (e.g. lifted off the screen edge) — just cancel,
// same as an invalid drop but without the "nope" sound since nothing was
// really attempted.
function cancelDrag() {
    items.draggingSlot = -1
    clearPreview()
}

function commitPlacement(slot, row, col) {
    var piece = items.pieces[slot]
    var shape = SHAPES[piece.shapeIndex]

    var grid = items.gridColors.slice()
    for (var i = 0; i < shape.length; ++i)
        grid[cellIndex(row + shape[i][0], col + shape[i][1])] = piece.colorIndex

    var pieces = items.pieces.slice()
    pieces[slot] = null

    items.score += shape.length
    items.placeSound.play()

    var cleared = clearFullLines(grid)
    items.gridColors = grid

    if (cleared > 0) {
        items.score += 10 * cleared + 5 * cleared * (cleared - 1)
        items.clearSound.play()
    }

    if (pieces.every(function (p) { return p === null }))
        pieces = generateTray()
    items.pieces = pieces

    checkGameOver()
}

// Clears every full row/column found in `grid` (modified in place) and
// returns how many lines were cleared at once, for the combo bonus.
function clearFullLines(grid) {
    var fullRows = []
    var fullCols = []

    for (var r = 0; r < GRID_SIZE; ++r) {
        var full = true
        for (var c = 0; c < GRID_SIZE; ++c) {
            if (grid[cellIndex(r, c)] === 0) {
                full = false
                break
            }
        }
        if (full)
            fullRows.push(r)
    }
    for (var c2 = 0; c2 < GRID_SIZE; ++c2) {
        var fullC = true
        for (var r2 = 0; r2 < GRID_SIZE; ++r2) {
            if (grid[cellIndex(r2, c2)] === 0) {
                fullC = false
                break
            }
        }
        if (fullC)
            fullCols.push(c2)
    }

    for (var i = 0; i < fullRows.length; ++i) {
        for (var c3 = 0; c3 < GRID_SIZE; ++c3)
            grid[cellIndex(fullRows[i], c3)] = 0
    }
    for (var j = 0; j < fullCols.length; ++j) {
        for (var r3 = 0; r3 < GRID_SIZE; ++r3)
            grid[cellIndex(r3, fullCols[j])] = 0
    }

    return fullRows.length + fullCols.length
}

function checkGameOver() {
    for (var i = 0; i < items.pieces.length; ++i) {
        var piece = items.pieces[i]
        if (piece && canPlaceAnywhere(SHAPES[piece.shapeIndex]))
            return
    }
    items.gameState = "over"
}
