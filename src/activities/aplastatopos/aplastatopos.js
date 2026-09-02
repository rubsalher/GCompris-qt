/* GCompris - aplastatopos.js
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * Classic "whack-a-mole": moles pop up at random holes in a grid and hide
 * again after a while; tap them before they hide to score. Most moles are
 * worth 1 point, a rarer golden one is worth 2. The game runs for a fixed
 * countdown and gets a bit faster as it goes on. Two selectable levels
 * make the whole round progressively faster (level itself doesn't change
 * during a round — only the automatic ramp within a round does).
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
.pragma library
.import "qrc:/gcompris/src/core/core.js" as Core

// Must match holesContainer.columns * holesContainer.rows in AplastaTopos.qml.
var GRID_SIZE = 12
var TOTAL_SECONDS = 60
// Chance that a spawned mole is the golden, 2-point variant.
var GOLDEN_CHANCE = 0.2

// Two difficulty levels (how long a mole stays up, and the gap before the
// next one), each faster overall than the last. Level 2 is the original
// single-speed tuning; level 1 is a new, noticeably slower tier added on
// request, and is also the level the activity opens on by default.
var levelProperty = [
    { upStart: 2600, upEnd: 2200, gapStart: 1800, gapEnd: 1500, gapJitter: 300 },
    { upStart: 2000, upEnd: 1600, gapStart: 1300, gapEnd: 1000, gapJitter: 300 }
]

var items
var activity
var isPlaying = false

function start(activity_, items_) {
    activity = activity_
    items = items_
    items.numberOfLevel = levelProperty.length
    items.currentLevel = Core.getInitialLevel(items.numberOfLevel)
    resetBoard()
}

function nextLevel() {
    items.currentLevel = Core.getNextLevel(items.currentLevel, items.numberOfLevel)
    resetBoard()
}

function previousLevel() {
    items.currentLevel = Core.getPreviousLevel(items.currentLevel, items.numberOfLevel)
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
    var level = levelProperty[items.currentLevel]
    var t = difficultyFraction()
    var gap = lerp(level.gapStart, level.gapEnd, t) + Math.random() * level.gapJitter
    items.spawnTimer.interval = gap
    items.spawnTimer.restart()
}

function spawnMole() {
    if (!isPlaying)
        return

    var level = levelProperty[items.currentLevel]
    var t = difficultyFraction()
    var upDuration = lerp(level.upStart, level.upEnd, t)

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
