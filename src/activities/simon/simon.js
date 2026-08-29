/* GCompris - simon.js
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * Classic "Simon" memory game: the board lights up a growing sequence of
 * the 4 colors (each with its own tone, matching the real 1978 toy),
 * the player repeats it by tapping the same colors in the same order.
 * One color is added each time a round is completed correctly; a wrong
 * tap ends the game. Unlike the original toy there is no response time
 * limit — elderly players can take as long as they need to answer.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
.pragma library

var GREEN = 0
var RED = 1
var YELLOW = 2
var BLUE = 3

var items
var activity

function start(activity_, items_) {
    activity = activity_
    items = items_
    newGame()
}

function stop() {
    items.playbackTimer.stop()
    items.pressFlashTimer.stop()
    items.nextRoundTimer.stop()
}

// Playback pacing gets a bit quicker as the sequence grows, same idea as
// the original toy (though gentler overall, and with a longer pause
// between tones for clarity).
function stepDuration() {
    var len = items.sequence.length
    if (len <= 5)
        return 500
    if (len <= 13)
        return 400
    return 300
}

function gapDuration() {
    return 220
}

function newGame() {
    items.sequence = []
    items.score = 0
    items.gameState = "playing"
    items.acceptingInput = false
    items.playerStep = 0
    items.litPad = -1
    addStepAndPlay()
}

function addStepAndPlay() {
    items.sequence = items.sequence.concat([Math.floor(Math.random() * 4)])
    items.score = items.sequence.length
    items.playerStep = 0
    items.acceptingInput = false
    items.playbackIndex = 0
    items.litPad = -1
    items.playbackPhase = "gap"
    items.playbackTimer.interval = gapDuration()
    items.playbackTimer.restart()
}

// Called on every playbackTimer tick — alternates lighting up the next
// pad in the sequence ("gap" phase ending) and turning it back off
// ("lit" phase ending), until the whole sequence has been shown.
function playbackTick() {
    if (items.playbackPhase === "gap") {
        if (items.playbackIndex >= items.sequence.length) {
            items.litPad = -1
            items.acceptingInput = true
            items.playbackTimer.stop()
            return
        }
        items.litPad = items.sequence[items.playbackIndex]
        playTone(items.litPad)
        items.playbackPhase = "lit"
        items.playbackTimer.interval = stepDuration()
        items.playbackTimer.restart()
    } else {
        items.litPad = -1
        items.playbackIndex++
        items.playbackPhase = "gap"
        items.playbackTimer.interval = gapDuration()
        items.playbackTimer.restart()
    }
}

function playTone(padIndex) {
    items.padSounds[padIndex].play()
}

function padPressed(padIndex) {
    if (!items.acceptingInput || items.gameState !== "playing")
        return

    items.litPad = padIndex
    playTone(padIndex)
    items.pressFlashTimer.restart()

    if (padIndex === items.sequence[items.playerStep]) {
        items.playerStep++
        if (items.playerStep === items.sequence.length) {
            items.acceptingInput = false
            items.nextRoundTimer.restart()
        }
    } else {
        items.acceptingInput = false
        items.gameState = "over"
        items.errorSound.play()
    }
}

// The brief highlight from a player's own tap should clear itself a
// moment later, but only if that tap didn't just end the game or
// trigger the next round's playback (those already manage litPad
// themselves).
function onPressFlashTimeout() {
    if (items.acceptingInput)
        items.litPad = -1
}

function onNextRoundTimeout() {
    addStepAndPlay()
}
