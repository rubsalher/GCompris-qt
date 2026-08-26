/* GCompris - atrapamanzanas.js
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * A rain of food falls from the sky at random points across the screen;
 * move the basket by touching anywhere to catch it before it hits the
 * ground (uncaught food just disappears, no penalty). Runs for a fixed
 * countdown and gets a bit faster as it goes on.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
.pragma library

var TOTAL_SECONDS = 60

var FOOD_TYPES = [
    "qrc:/gcompris/src/activities/atrapamanzanas/resource/apple.svg",
    "qrc:/gcompris/src/activities/atrapamanzanas/resource/banana.svg",
    "qrc:/gcompris/src/activities/atrapamanzanas/resource/grapes.svg"
]

var items
var activity
var isPlaying = false
var activeApples = []

var appleComponent = Qt.createComponent("qrc:/gcompris/src/activities/atrapamanzanas/Apple.qml")

function start(activity_, items_) {
    activity = activity_
    items = items_
    resetGame()
}

function stop() {
    isPlaying = false
    items.spawnTimer.stop()
    items.countdownTimer.stop()
    destroyApples()
}

function resetGame() {
    isPlaying = false
    items.score = 0
    items.remainingSeconds = TOTAL_SECONDS
    items.gameState = "ready"
    destroyApples()
}

function destroyApples() {
    for (var i = 0; i < activeApples.length; ++i) {
        if (activeApples[i])
            activeApples[i].destroy()
    }
    activeApples = []
}

function startGame() {
    resetGame()
    isPlaying = true
    items.gameState = "playing"
    items.countdownTimer.start()
    scheduleNextApple()
}

function endGame() {
    isPlaying = false
    items.spawnTimer.stop()
    items.countdownTimer.stop()
    destroyApples()
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

function scheduleNextApple() {
    if (!isPlaying)
        return
    var t = difficultyFraction()
    var gap = lerp(1600, 700, t) + Math.random() * 300
    items.spawnTimer.interval = gap
    items.spawnTimer.restart()
}

function spawnApple() {
    if (!isPlaying)
        return

    createApple()

    // Occasionally a second apple falls at the same time, more often as
    // the round advances (elderly-friendly: starts at 0%, never above 30%).
    var doubleChance = lerp(0.0, 0.3, difficultyFraction())
    if (Math.random() < doubleChance)
        createApple()

    scheduleNextApple()
}

function createApple() {
    var t = difficultyFraction()
    var fallDuration = lerp(2900, 1450, t)
    var bounds = items.spawnBounds()
    var spawnX = bounds.left + Math.random() * (bounds.right - bounds.left)
    var source = FOOD_TYPES[Math.floor(Math.random() * FOOD_TYPES.length)]

    var apple = appleComponent.createObject(items.playArea, {
        "source": source,
        "appleSize": items.appleSize,
        "spawnX": spawnX,
        "startY": -items.appleSize * 3,
        "fallDurationMs": fallDuration,
        "groundY": items.playArea.height,
        "basket": items.basket
    })
    if (apple === null) {
        console.log("Error creating apple object")
        return
    }
    apple.caught.connect(appleCaught)
    apple.missed.connect(appleMissed)
    activeApples.push(apple)
}

function removeApple(apple) {
    var idx = activeApples.indexOf(apple)
    if (idx !== -1)
        activeApples.splice(idx, 1)
}

function appleCaught(apple) {
    removeApple(apple)
    if (!isPlaying)
        return
    items.score += 1
    items.catchSound.play()
}

function appleMissed(apple) {
    removeApple(apple)
}
