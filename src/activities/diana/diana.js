/* GCompris - diana.js
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * A giant target for a REAL small ball, thrown by hand at the screen —
 * the IR touch frame reports wherever it actually hits as a tap, and
 * the score depends on which colored ring that real impact point falls
 * in. No time limit at all — this file only scores where a throw
 * landed; all animation/pacing lives in Diana.qml.
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

var items
var activity

function start(activity_, items_) {
    activity = activity_
    items = items_
    newSession()
}

function stop() {
}

function newSession() {
    items.score = 0
    items.lastPoints = -1
    items.throwing = false
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
// (tapX, tapY) (relative to the target's center). Returns null if a
// throw is still being shown, so two near-simultaneous impacts don't
// score twice for the same ball.
function throwAt(tapX, tapY, targetRadius) {
    if (items.throwing)
        return null
    items.throwing = true

    var points = scoreForLanding(tapX, tapY, targetRadius)
    items.lastPoints = points
    items.score += points
    if (points > 0)
        items.hitSound.play()
    else
        items.missSound.play()

    return { "x": tapX, "y": tapY, "points": points }
}

// Called once the impact mark's animation has fully played out, to
// allow the next throw to register.
function throwFinished() {
    items.throwing = false
}
