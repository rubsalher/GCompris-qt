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
    { "spawnInterval": 1750, "target": 32, "doubleChance": 0.12, "speedFactor": 1.0 },
    { "spawnInterval": 1750, "target": 32, "doubleChance": 0.12, "speedFactor": 1.2 }
]

// Each spawn tick picks a fresh random interval in this range (ms) for
// the *next* tick, instead of a fixed one — 1.5 to 2 seconds apart.
var SPAWN_INTERVAL_MIN = 1500
var SPAWN_INTERVAL_MAX = 2000

// Reserved for the score badge in the top-right corner — no fruit's
// highest point is allowed to land inside this box, so the badge never
// hides one mid-flight. Expressed as fractions of the play area's own
// width/height (from this X onward, from the top down to this Y).
var SCORE_ZONE_X = 0.76
var SCORE_ZONE_Y = 0.26

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
// second one at the same time (chance grows with the level) — when that
// happens, the second one is forced to the opposite side of the screen
// with a crossing drift, so the two never look like the same trajectory
// twice. Also picks a fresh random interval (1.5-2s) for the next tick.
function spawnTick() {
    var firstSide = spawnFruit(0)
    if (Math.random() < items.doubleChance)
        spawnFruit(-firstSide)
    items.spawnInterval = SPAWN_INTERVAL_MIN + Math.random() * (SPAWN_INTERVAL_MAX - SPAWN_INTERVAL_MIN)
}

// sideHint: 0 lets this launch pick its own side freely; -1/+1 forces it
// to the left/right half of the screen (used to keep a simultaneous
// double-spawn visually distinct). Returns the side that was actually
// used, so the caller can force the opposite one on the next call.
function spawnFruit(sideHint) {
    if (isActivityStopped || !component || component.status !== Quick.Component.Ready)
        return sideHint

    var type = fruitTypes[Math.floor(Math.random() * fruitTypes.length)]
    var W = activityBackground.width
    var H = activityBackground.height
    if (W <= 0 || H <= 0)
        return sideHint

    // Random size per spawn: never smaller than the base size (elderly-
    // friendly build), sometimes noticeably bigger.
    var sizeScale = 1.0 + Math.random() * 0.6
    var fruitW = type.width * sizeScale
    var fruitH = type.height * sizeScale
    var margin = Math.max(fruitW, fruitH)

    // Slower overall (lower gravity means both a slower launch and a
    // longer time in the air) so there is enough time to reach and slice
    // each fruit. Lowered again on request (was H * 1.3) for noticeably
    // more hang time and a slower arc. Gravity alone (not peak height) is
    // shared by every fruit regardless of where it launches from.
    var gravity = H * 0.55 * items.speedFactor

    // Try a few random launches and keep the first one whose highest
    // point doesn't land behind the score badge (top-right corner) — see
    // rollLaunch() below. Almost always succeeds on the first try; the
    // retry limit just guards against looping forever on an unlucky run.
    var launch
    for (var attempt = 0; attempt < 6; ++attempt) {
        launch = rollLaunch(W, H, fruitW, fruitH, margin, gravity, sideHint)
        var apexX = launch.spawnX + launch.vx * (launch.flightTime / 2)
        var apexY = launch.spawnY - launch.peakHeight
        if (!(apexX > W * SCORE_ZONE_X && apexY < H * SCORE_ZONE_Y))
            break
    }

    var fruit = component.createObject(items.fruitContainer, {
        "source": url + type.imgName,
        "fruitWidth": fruitW,
        "fruitHeight": fruitH,
        "spawnX": launch.spawnX,
        "spawnY": launch.spawnY,
        "vx": launch.vx,
        "vy0": launch.vy0,
        "gravity": gravity
    })
    if (fruit) {
        createdFruits.push(fruit)
        fruit.missed.connect(fruitMissed)
    }
    return launch.side
}

// Picks one random launch (spawn point + velocity) for a fruit of the
// given size. Most launches come from the bottom, within a band around
// the horizontal centre of the screen (not the full width) — so a clear
// majority land close to dead-centre, not just "somewhere along the
// bottom" — and always drift diagonally toward the OTHER half of that
// band, so the arc reads as a sideways-sweeping curve, never a near-
// vertical bounce. A bit more often than before, a launch instead comes
// from the left/right edge and cuts diagonally across the middle of the
// screen (roughly a 60° sweep) rather than a slow horizontal creep.
//
// sideHint forces which half of the screen this particular launch
// starts from (-1 left, +1 right); 0 lets it pick freely. Used so a
// simultaneous double-spawn always sends the two fruits from opposite
// halves, crossing each other instead of running the same trajectory
// twice.
//
// Peak height is measured relative to THIS launch's own spawnY (not
// always H), so a fruit starting mid-screen (left/right edge) can never
// arc up past the top of the visible area and vanish there for part of
// its flight — every fruit's apex stays on-screen, and for a
// bottom launch (spawnY = H + fruitH) this reduces to the original
// H-relative formula, unchanged.
function rollLaunch(W, H, fruitW, fruitH, margin, gravity, sideHint) {
    var edgeRoll = Math.random()
    var spawnX, spawnY, vx
    var side = sideHint || (Math.random() < 0.5 ? -1 : 1)

    if (edgeRoll < 0.78) {
        // bottom, 78% of launches, within a central band (60% of the
        // width) split in half at the screen's centre — this launch
        // starts on whichever half `side` picked.
        var bandHalfWidth = W * 0.30
        var loFull = Math.max(margin, W / 2 - bandHalfWidth)
        var hiFull = Math.min(W - margin, W / 2 + bandHalfWidth)
        var lo = side < 0 ? loFull : W / 2
        var hi = side < 0 ? W / 2 : hiFull
        if (hi <= lo) { lo = loFull; hi = hiFull } // degenerate band: fall back to the full one
        var usableWidth = Math.max(1, hi - lo)
        var centerBias = (Math.random() + Math.random() + Math.random() + Math.random() + Math.random()) / 5
        spawnX = lo + centerBias * usableWidth
        spawnY = H + fruitH
    } else {
        // edge, 22% of launches — from whichever side `side` already
        // picked above, so a forced double-spawn's second fruit really
        // does come from the opposite side even if it lands here.
        spawnX = side < 0 ? -fruitW : W + fruitW
        spawnY = H * (0.45 + Math.random() * 0.45)
    }

    var peakHeight = Math.min(spawnY, H) * (0.72 + Math.random() * 0.25)
    var vy0 = -Math.sqrt(2 * gravity * peakHeight)
    var flightTime = 2 * Math.abs(vy0) / gravity

    if (spawnY > H) {
        // bottom: always drifts toward the OTHER half of the screen from
        // where it started (never close to zero, never random direction)
        // so the arc is a clear diagonal sweep, and two simultaneous
        // fruits sent to opposite halves visibly cross paths.
        var driftDir = side < 0 ? 1 : -1
        var driftMag = W * (0.20 + Math.random() * 0.25)
        vx = flightTime > 0 ? driftDir * driftMag / flightTime : 0
    } else {
        // left/right edge: a clear diagonal crossing through the middle
        // of the screen (roughly a 60° sweep, not a slow horizontal
        // creep) — horizontal speed is now a good fraction of the
        // vertical launch speed instead of much slower than it.
        var edgeSpeed = W * (0.28 + Math.random() * 0.14) * items.speedFactor
        vx = spawnX < 0 ? edgeSpeed : -edgeSpeed
    }

    return { "spawnX": spawnX, "spawnY": spawnY, "vx": vx, "vy0": vy0, "peakHeight": peakHeight, "flightTime": flightTime, "side": side }
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
