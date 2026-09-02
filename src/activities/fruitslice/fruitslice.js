/* GCompris - fruitslice.js
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * Fruits launch in an arc from the bottom of the screen; drag the finger/
 * mouse over them to slice them before they fall — encourages reaching
 * across the whole (projected) screen with the arm.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
.pragma library
.import QtQuick as Quick
.import core 1.0 as GCompris
.import "qrc:/gcompris/src/core/core.js" as Core

var url = "qrc:/gcompris/src/activities/fruitslice/resource/"

// Bigger base sizes (elderly-friendly build) — easier to see and to hit.
var fruitTypes = [
    { "imgName": "apple.svg", "width": 155, "height": 155 },
    { "imgName": "orange.svg", "width": 155, "height": 155 },
    { "imgName": "pear.svg", "width": 135, "height": 170 },
    { "imgName": "strawberry.svg", "width": 135, "height": 135 },
    { "imgName": "pineapple.svg", "width": 145, "height": 195 },
    { "imgName": "banana.svg", "width": 190, "height": 115 },
    { "imgName": "grapes.svg", "width": 145, "height": 170 },
    { "imgName": "watermelon.svg", "width": 170, "height": 155 }
]

// Elderly-friendly build: levels removed at the user's request, only the
// old level 6 (the fastest/hardest of the original 6) was kept as a single
// difficulty for a long time. A second, slightly faster level was added
// later (fruits fly a bit quicker, same spawn rate/target) — finishing a
// level auto-advances to the next one via Bonus.win, and with only 2
// levels and no level-selector buttons shown, it just cycles between them.
// doubleChance: probability that a spawn tick launches a second fruit
// alongside the first one (0 = never, 1 = always).
// speedFactor: multiplies fruit gravity/velocity (both the arc launch and
// the left/right edge drift) — 1 = baseline, >1 = faster fruits.
var levelProperty = [
    { "spawnInterval": 1100, "target": 32, "doubleChance": 0.35, "speedFactor": 1.0 },
    { "spawnInterval": 1100, "target": 32, "doubleChance": 0.35, "speedFactor": 1.2 }
]

var items
var activity
var activityBackground
var bar
var bonus
var component
var createdFruits
var isActivityStopped = false

function start(activity_, activityBackground_, bar_, bonus_, items_) {
    activity = activity_
    activityBackground = activityBackground_
    bar = bar_
    bonus = bonus_
    items = items_
    component = Qt.createComponent("qrc:/gcompris/src/activities/fruitslice/Fruit.qml")
    items.numberOfLevel = levelProperty.length
    items.currentLevel = Core.getInitialLevel(items.numberOfLevel)
    isActivityStopped = false
    createdFruits = []
    initLevel()
}

function stop() {
    isActivityStopped = true
    destroyFruits()
}

function initLevel() {
    destroyFruits()
    items.spawnInterval = levelProperty[items.currentLevel].spawnInterval
    items.doubleChance = levelProperty[items.currentLevel].doubleChance
    items.speedFactor = levelProperty[items.currentLevel].speedFactor
    items.score.numberOfSubLevels = levelProperty[items.currentLevel].target
    items.score.currentSubLevel = 0
}

function nextLevel() {
    items.currentLevel = Core.getNextLevel(items.currentLevel, items.numberOfLevel);
    initLevel();
}

function previousLevel() {
    items.currentLevel = Core.getPreviousLevel(items.currentLevel, items.numberOfLevel);
    initLevel();
}

// Called by the spawn Timer: always launches one fruit, and sometimes a
// second one at the same time (chance grows with the level).
function spawnTick() {
    spawnFruit()
    if (Math.random() < items.doubleChance)
        spawnFruit()
}

function spawnFruit() {
    if (isActivityStopped || !component || component.status !== Quick.Component.Ready)
        return

    var type = fruitTypes[Math.floor(Math.random() * fruitTypes.length)]
    var W = activityBackground.width
    var H = activityBackground.height
    if (W <= 0 || H <= 0)
        return

    // Random size per spawn: never smaller than the base size (elderly-
    // friendly build), sometimes noticeably bigger.
    var sizeScale = 1.0 + Math.random() * 0.6
    var fruitW = type.width * sizeScale
    var fruitH = type.height * sizeScale

    // Higher, more varied arcs, and slower overall (lower gravity means
    // both a slower launch and a longer time in the air) so there is
    // enough time to reach and slice each fruit. Lowered again on request
    // (was H * 1.3) for noticeably more hang time and a slower arc.
    var gravity = H * 0.55 * items.speedFactor
    var peakHeight = H * (0.55 + Math.random() * 0.4)
    var vy0 = -Math.sqrt(2 * gravity * peakHeight)
    var flightTime = 2 * Math.abs(vy0) / gravity

    // Most fruit launches from the bottom; some from the left/right edges
    // too, so reaching sideways is also needed, not just up.
    var edgeRoll = Math.random()
    var margin = Math.max(fruitW, fruitH)
    var spawnX, spawnY, vx

    if (edgeRoll < 0.6) {
        // bottom
        spawnX = margin + Math.random() * Math.max(1, W - 2 * margin)
        spawnY = H + fruitH
        var maxDrift = W * 0.15
        vx = flightTime > 0 ? (Math.random() * 2 - 1) * maxDrift / flightTime : 0
    } else if (edgeRoll < 0.8) {
        // left edge — capped as a direct speed (not a fixed on-screen
        // target divided by flight time) so it never ends up much faster
        // than a bottom-launched fruit just because it has more screen
        // to cross before the (now longer) flight time is up.
        spawnX = -fruitW
        spawnY = H * (0.45 + Math.random() * 0.45)
        vx = W * (0.07 + Math.random() * 0.06) * items.speedFactor
    } else {
        // right edge, same capped speed, mirrored.
        spawnX = W + fruitW
        spawnY = H * (0.45 + Math.random() * 0.45)
        vx = -W * (0.07 + Math.random() * 0.06) * items.speedFactor
    }

    var fruit = component.createObject(items.fruitContainer, {
        "source": url + type.imgName,
        "fruitWidth": fruitW,
        "fruitHeight": fruitH,
        "spawnX": spawnX,
        "spawnY": spawnY,
        "vx": vx,
        "vy0": vy0,
        "gravity": gravity
    })
    if (fruit) {
        createdFruits.push(fruit)
        fruit.missed.connect(fruitMissed)
    }
}

function fruitMissed(fruit) {
    var idx = createdFruits.indexOf(fruit)
    if (idx !== -1)
        createdFruits.splice(idx, 1)
}

function fruitSliced(fruit) {
    var idx = createdFruits.indexOf(fruit)
    if (idx !== -1)
        createdFruits.splice(idx, 1)

    items.crashSound.play()
    items.score.currentSubLevel += 1
    if (items.score.currentSubLevel >= items.score.numberOfSubLevels) {
        items.winSound.play()
        bonus.good("flower")
    }
}

function destroyFruits() {
    if (!createdFruits)
        return
    for (var i = 0; i < createdFruits.length; ++i) {
        if (createdFruits[i])
            createdFruits[i].destroy()
    }
    createdFruits = []
}
