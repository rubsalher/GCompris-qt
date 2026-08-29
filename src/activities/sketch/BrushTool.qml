/* GCompris - BrushTool.qml
 *
 * SPDX-FileCopyrightText: 2024 Timothée Giet <animtim@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import core 1.0

// Elderly-friendly build: simplified down to the one brush mode ("Boceto"
// only ever uses roundBrush, in draw or eraser mode) — the other brush
// styles (fill/air/sketch/spray/circles) were removed along with the tool
// panel that used to switch between them, to keep the activity to just
// "draw" + "erase" + "thickness", per the request to simplify it.
Item {
    id: brushTool
    property Item selectedMode: roundBrush
    readonly property bool usePositionChanged: false
    readonly property real fullCircle: 2 * Math.PI

    property alias roundBrush: roundBrush

    onSelectedModeChanged: {
        if(tempCanvas.ctx)
            selectedMode.modeInit();
    }

    function toolInit() {
        selectedMode.modeInit();
    }

    function toolStart() {
        selectedMode.start();
    }

    function toolProcess() {
        selectedMode.process();
    }

    function toolStop() {
        selectedMode.stop();
    }

    // functions used in modes
    function midPointBtw(p1, p2) {
        return {
            x: (p1.x + p2.x) * 0.5,
            y: (p1.y + p2.y) * 0.5
        };
    }

    // functions for brush smoothing (adapted from https://lazybrush.dulnan.net/)
    function ease(x) {
        return 1 - Math.sqrt(1 - x * x);
    }

    function equalsTo(pointA, pointB) {
        return pointA.x === pointB.x && pointA.y === pointB.y;
    }

    function getDifferenceTo(pointA, pointB) {
        return { x: pointA.x - pointB.x, y: pointA.y - pointB.y };
    }

    function getDistanceTo(pointA, pointB) {
        var diff = getDifferenceTo(pointA, pointB);
        return Math.sqrt(diff.x * diff.x + diff.y * diff.y);
    }

    function getAngleTo(pointA, pointB) {
        var diff = getDifferenceTo(pointA, pointB);
        return Math.atan2(diff.y, diff.x);
    }

    function moveByAngle(origin, angle, distance, friction) {
        // Rotate the angle based on the coordinate system ([0,0] in the top left)
        const angleRotated = angle + Math.PI * 0.5;
        var x = origin.x + Math.sin(angleRotated) * distance * ease(1 - friction);
        var y = origin.y - Math.cos(angleRotated) * distance * ease(1 - friction);
        return { x: x, y: y };
    }

    // Using quadraticCurveTo using midPoint instead of simple lineTo avoids broken/angular curves on fast lines, especially on mobile.
    function smoothedProcess() {
        var newPoint = canvasInput.savePoint();
        // if there's smoothing, check if it's outside smoothingRadius
        if(selectedMode.smoothingRadius > 0) {
            var distance = getDistanceTo(newPoint, canvasInput.midPoint);
            var isOutside =  Math.round((distance - selectedMode.smoothingRadius) * 10) / 10 > 0;
            if(isOutside){
                var angle = getAngleTo(newPoint, canvasInput.midPoint);
                canvasInput.lastPoint = canvasInput.currentPoint;
                canvasInput.currentPoint = brushTool.moveByAngle(
                    canvasInput.midPoint,
                    angle,
                    distance - selectedMode.smoothingRadius,
                    selectedMode.smoothingFriction
                )
            } else {
                return;
            }
        } else {
            if(equalsTo(newPoint, canvasInput.currentPoint)) {
                return;
            }
            canvasInput.lastPoint = canvasInput.currentPoint;
            canvasInput.currentPoint = newPoint;
        }
        canvasInput.midPoint = midPointBtw(canvasInput.lastPoint, canvasInput.currentPoint);
        tempCanvas.ctx.clearRect(0, 0, tempCanvas.width, tempCanvas.height);
        tempCanvas.ctx.quadraticCurveTo(canvasInput.lastPoint.x, canvasInput.lastPoint.y, canvasInput.midPoint.x, canvasInput.midPoint.y);
        tempCanvas.ctx.stroke();
        tempCanvas.requestPaint();
    }
    //

    function defaultModeInit() {
        processTimer.interval = selectedMode.timerInterval;
        tempCanvas.opacity = selectedMode.actualToolOpacity;
        tempCanvas.ctx.lineCap = tempCanvas.ctx.lineJoin = "round";
        tempCanvas.ctx.strokeStyle = tempCanvas.ctx.fillStyle = items.foregroundColor;
        tempCanvas.ctx.globalAlpha = 1;
    }

    // default functions used in most modes
    function defaultModeStart() {
        canvasInput.currentPoint = canvasInput.lastPoint = canvasInput.midPoint = canvasInput.savePoint();
        tempCanvas.ctx.beginPath();
        tempCanvas.ctx.arc(canvasInput.currentPoint.x, canvasInput.currentPoint.y, selectedMode.radiusSize, 0, brushTool.fullCircle);
        tempCanvas.ctx.fill();
        tempCanvas.requestPaint();
        tempCanvas.ctx.moveTo(canvasInput.currentPoint.x, canvasInput.currentPoint.y);
        tempCanvas.ctx.beginPath();
    }

    function defaultModeStop() {
        processTimer.stop();
        canvasInput.resetPoints();
        tempCanvas.paintActionFinished();
    }

    // The one and only brush: a simple round pen, usable both to draw and
    // (in eraser mode) to erase — toolSize/eraserSize (1 to 100) are its
    // separate remembered thicknesses for each of those two modes.
    AbstractBrush {
        id: roundBrush
        toolSize: 5
        defaultToolSize: 5
        minToolSize: 1
        maxToolSize: 100
        sizeSliderStepSize: 1
        timerInterval: 15
        // AbstractBrush defaults toolOpacity to 0.5 (meant to be adjustable
        // via a settings slider that no longer exists in this simplified
        // build) — force fully opaque strokes instead.
        toolOpacity: 1
        defaultToolOpacity: 1
        // on mobile, the smoothing can actually make it worse, so better set it to 0 by default there...
        property int toolSmoothing: ApplicationInfo.isMobile ? 0 : 1
        readonly property int defaultToolSmoothing: ApplicationInfo.isMobile ? 0 : 1

        // eraserMode
        eraserSize: 10
        defaultEraserSize: 10
        property int eraserSmoothing: ApplicationInfo.isMobile ? 0 : 1
        readonly property int defaultEraserSmoothing: ApplicationInfo.isMobile ? 0 : 1

        readonly property int smoothingRadius: (items.eraserMode ? eraserSmoothing : toolSmoothing) * 5
        readonly property real smoothingFriction: 0.05

        function modeInit() {
            items.outlineCursorRadius = Math.max(smoothingRadius, radiusSize);
            tempCanvas.ctx.lineWidth = actualToolSize;
            brushTool.defaultModeInit();
        }

        function start() {
            brushTool.defaultModeStart();
            processTimer.restart();
        }

        function process() {
            brushTool.smoothedProcess();
        }

        function stop() {
            brushTool.defaultModeStop();
        }
    }
}
