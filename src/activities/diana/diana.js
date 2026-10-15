/* GCompris - diana.js
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * A giant target for a REAL small ball, thrown by hand at the screen —
 * the IR touch frame reports wherever it actually hits as a tap, and
 * the score depends on which colored ring that real impact point falls
 * in. A turn is 6 throws; after each throw there's a mandatory 3 second
 * pause (time for whoever fetches the ball to bring it back) before
 * the next one can register. This file only tracks turns/scoring and
 * the cooldown countdown; the impact mark's own quick animation lives
 * in Diana.qml.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
.pragma library

// Rings from outermost to innermost (classic archery-style coloring),
// each described by its outer radius as a fraction of the target's own
// radius, and how many points landing inside it is worth.
var RINGS = [
    { factor: 1.00, innerFactor: 0.80, color: "#f5f5f0", points: 10, textColor: "#232323" },
    { factor: 0.80, innerFactor: 0.60, color: "#232323", points: 20, textColor: "#ffffff" },
    { factor: 0.60, innerFactor: 0.40, color: "#1565c0", points: 30, textColor: "#ffffff" },
    { factor: 0.40, innerFactor: 0.20, color: "#c62828", points: 40, textColor: "#ffffff" },
    { factor: 0.20, innerFactor: 0.00, color: "#f9c74f", points: 50, textColor: "#232323" }
]

var THROWS_PER_TURN = 6
var COOLDOWN_SECONDS = 3

var items
var activity

function start(activity_, items_) {
    activity = activity_
    items = items_
    newTurn()
}

function stop() {
    items.cooldownTimer.stop()
}

function newTurn() {
    items.cooldownTimer.stop()
    items.throwsInTurn = 0
    items.turnScore = 0
    items.lastPoints = -1
    items.locked = false
    items.turnComplete = false
    items.cooldownRemaining = 0
}

// (landX, landY) is the real impact point reported by the touch frame,
// relative to the target's own center — no artificial scatter is added
// here, since the real ball throw already provides all the inaccuracy
// there is.
function scoreForLanding(landX, landY, targetRadius) {
    var dist = Math.sqrt(landX * landX + landY * landY)
    for (var i = RINGS.length - 1; i >= 0; --i) {
        if (dist <= targetRadius * RINGS[i].factor)
            return RINGS[i].points
    }
    return 0
}

// Called when the touch frame reports a real ball impact at
// (tapX, tapY) (relative to the target's center). Returns null while
// locked (mid-cooldown, or the turn's 3 throws are already done), so a
// stray extra impact doesn't score again for the same ball or sneak in
// an extra throw.
function throwAt(tapX, tapY, targetRadius) {
    if (items.locked || items.turnComplete)
        return null
    items.locked = true

    var points = scoreForLanding(tapX, tapY, targetRadius)
    items.lastPoints = points
    items.turnScore += points
    items.throwsInTurn += 1
    if (points > 0)
        items.hitSound.play()
    else
        items.missSound.play()

    if (items.throwsInTurn >= THROWS_PER_TURN)
        items.turnComplete = true

    return { "x": tapX, "y": tapY, "points": points }
}

// Called once the impact mark's own quick animation has played out. If
// the turn just ended, the "Nuevo turno" button is what unlocks the
// next throw — no need for a countdown on top of that. Otherwise starts
// the mandatory 3 second pause before another throw can register.
function throwFinished() {
    if (items.turnComplete)
        return
    items.cooldownRemaining = COOLDOWN_SECONDS
    items.cooldownTimer.restart()
}

function cooldownTick() {
    items.cooldownRemaining -= 1
    if (items.cooldownRemaining <= 0) {
        items.cooldownTimer.stop()
        items.cooldownRemaining = 0
        items.locked = false
    }
}
