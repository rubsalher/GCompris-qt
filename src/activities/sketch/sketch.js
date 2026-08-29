/* GCompris - sketch.js
 *
 * SPDX-FileCopyrightText: 2024 Timothée Giet <animtim@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

.pragma library
.import QtQuick as Quick
.import core 1.0 as GCompris

var items;

var canvasWidth = 1;
var canvasHeight = 1;

function start(items_) {
    items = items_;
    initLevel();
}

function stop() {
    items.canvasArea.width = 0;
    items.canvasArea.height = 0;
}

function initLevel() {
    items.canvasArea.clearUndo();
    items.canvasArea.clearRedo();
    initCanvas();
    items.canvasArea.init();
    items.canvasLocked = false;
}

function resetLevel() {
    items.resetRequested = false;
    initLevel();
}

// set fixed canvas size at init to avoid various bugs...
function initCanvas() {
    // size to be rounded to smallest even number to avoid bugs with software renderer...
    canvasWidth = 2 * parseInt(items.layoutArea.width / 2);
    canvasHeight = 2 * parseInt(items.layoutArea.height / 2);
    items.canvasArea.width = canvasWidth;
    items.canvasArea.height = canvasHeight;
    items.canvasColor.color = items.backgroundColor;
    items.canvasImage.source = "";
    items.tempCanvas.initContext();
    //add first empty undo to restore empty canvas
    items.tempCanvas.paintActionFinished();
}

function undoAction() {
    // 1st element of the list is always last possible state, never undo it
    if(items.canvasArea.undoSize > 1) {
        items.scrollSound.play();
        items.canvasLocked = true;
        items.canvasArea.doUndo();
        items.canvasArea.sendToImageSource();
        items.canvasLocked = false;
    }
}

function redoAction() {
    if(items.canvasArea.redoSize > 0) {
        items.scrollSound.play();
        items.canvasLocked = true;
        items.canvasArea.doRedo();
        items.canvasArea.sendToImageSource();
        items.canvasLocked = false;
    }
}

function requestNewImage() {
    items.resetRequested = true;
    items.newImageDialog.active = true;
}
