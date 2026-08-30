/* GCompris - aplastatopos.js
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * Classic "whack-a-mole": moles pop up at random holes in a grid and hide
 * again after a while; tap them before they hide to score. Most moles are
 * worth 1 point, a rarer golden one is worth 2. The game runs for a fixed
 * countdown and gets a bit faster as it goes on.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
.pragma library

// Must match holesContainer.columns * holesContainer.rows in AplastaTopos.qml.
var GRID_SIZE = 12
var TOTAL_SECONDS = 60
// Chance that a spawned mole is the golden, 2-point variant.
var GOLDEN_CHANCE = 0.2

var items
var activity
var isPlaying = false

function start(activity_, items_) {
    activity = activity_
    items = items_
    resetBoard()
}

function stop() {
    isPlaying = false
    items.spawnTimer.stop()
    items.countdownTimer.stop()
    clearHoles()
}

function resetBoard() {
    isPlaying = false
    items.score = 0
    items.remainingSeconds = TOTAL_SECONDS
    items.gameState = "ready"
    clearHoles()
}

function clearHoles() {
    for (var i = 0; i < GRID_SIZE; ++i) {
        var hole = items.holesRepeater.itemAt(i)
        if (hole)
            hole.reset()
    }
}

function startGame() {
    resetBoard()
    isPlaying = true
    items.gameState = "playing"
    items.countdownTimer.start()
    scheduleNextMole()
}

function endGame() {
    isPlaying = false
    items.spawnTimer.stop()
    items.countdownTimer.stop()
    clearHoles()
    items.gameState = "over"
}

function onCountdownTick() {
    if (!isPlaying)
        return
    items.remainingSeconds -= 1
    if (items.remainingSeconds <= 0) {
        items.remainingSeconds = 0
        endGame()
    }
}

// 0 at the start of the round, 1 near the end: used to ramp up difficulty.
function difficultyFraction() {
    return 1 - (items.remainingSeconds / TOTAL_SECONDS)
}

function lerp(a, b, t) {
    return a + (b - a) * t
}

function freeHoleIndices() {
    var result = []
    for (var i = 0; i < GRID_SIZE; ++i) {
        var hole = items.holesRepeater.itemAt(i)
        if (hole && !hole.isMoleUp)
            result.push(i)
    }
    return result
}

function scheduleNextMole() {
    if (!isPlaying)
        return
    var t = difficultyFraction()
    // Elderly-friendly: the gap between moles barely tightens over the
    // round (was 1300ms->500ms, more than doubling the pace by the end —
    // too fast to react to). Now it only eases from 1300ms to 1000ms.
    var gap = lerp(1300, 1000, t) + Math.random() * 300
    items.spawnTimer.interval = gap
    items.spawnTimer.restart()
}

function spawnMole() {
    if (!isPlaying)
        return

    var t = difficultyFraction()
    // Elderly-friendly: moles used to stay up for as little as 800ms near
    // the end, not enough time to spot and reach them. Now the floor is
    // 1300ms, close to the starting 1700ms.
    var upDuration = lerp(1700, 1300, t)

    var free = freeHoleIndices()
    if (free.length > 0) {
        var idx = free[Math.floor(Math.random() * free.length)]
        items.holesRepeater.itemAt(idx).popUp(upDuration, Math.random() < GOLDEN_CHANCE)
    }

    // Occasionally a second mole pops up at the same time, more often as
    // the round advances (elderly-friendly: starts at 0%, capped at 15%
    // instead of 35% — two moles at once is much harder to handle).
    var doubleChance = lerp(0.0, 0.15, t)
    if (Math.random() < doubleChance) {
        var free2 = freeHoleIndices()
        if (free2.length > 0) {
            var idx2 = free2[Math.floor(Math.random() * free2.length)]
            items.holesRepeater.itemAt(idx2).popUp(upDuration, Math.random() < GOLDEN_CHANCE)
        }
    }

    scheduleNextMole()
}

function moleWhacked(isGolden) {
    if (!isPlaying)
        return
    items.score += isGolden ? 2 : 1
    items.whackSound.play()
}
