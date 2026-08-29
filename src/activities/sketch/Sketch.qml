/* GCompris - Sketch.qml
 *
 * SPDX-FileCopyrightText: 2016 Toncu Stefan <stefan.toncu29@gmail.com>
 * SPDX-FileCopyrightText: 2018 Amit Sagtani <asagtani06@gmail.com>
 * SPDX-FileCopyrightText: 2019-2024 Timothée Giet <animtim@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Elderly-friendly build: this activity used to be a full mini image
 * editor (several brush styles, geometric shapes, gradients, stamps,
 * text, palette editing, save/load to file, background pictures...).
 * At the user's request it was stripped down to just what a simple free
 * drawing pad needs: a row of plain colors, a visible eraser, one
 * thickness slider that resizes whichever of the two (pen or eraser) is
 * currently active, undo/redo, and a clear (reload) button — all always
 * visible in one toolbar, nothing hidden behind folding panels or menus.
 */

import QtQuick
import QtQuick.Controls.Basic
import core 1.0

import "../../core"
import "sketch.js" as Activity

ActivityBase {
    id: activity

    onStart: focus = true
    onStop: {}

    // Storing undo with QQuickItemGrabResult uses quite some RAM,
    // so limit more by default on mobile which typically has less RAM than computers
    property int undoSetting: ApplicationInfo.isMobile ? 5 : 10

    pageComponent: Rectangle {
        id: activityBackground
        anchors.fill: parent
        color: "#cacaca"
        signal start
        signal stop

        Component.onCompleted: {
            activity.start.connect(start);
            activity.stop.connect(stop);
        }

        readonly property var basicColors: [
            "#1a1a1a", // negro
            "#e02020", // rojo
            "#f2871f", // naranja
            "#f2d31f", // amarillo
            "#3fa63f", // verde
            "#2e6fd9", // azul
            "#8e44ad", // morado
            "#8a5a3c", // marrón
            "#e0629b"  // rosa
        ]

        // Add here the QML items you need to access in javascript
        QtObject {
            id: items
            readonly property Item selectedTool: brushTool

            property bool canvasLocked: true
            property bool toolStarted: false
            property bool resetRequested: false
            property color selectedForegroundColor: activityBackground.basicColors[0]
            readonly property color foregroundColor: eraserMode ? backgroundColor : selectedForegroundColor
            readonly property color backgroundColor: Qt.rgba(1,1,1,1)
            property bool eraserMode: false
            property alias layoutArea: layoutArea
            property alias canvasArea: canvasArea
            property alias canvasColor: canvasColor
            property alias canvasImage: canvasImage
            property alias tempCanvas: tempCanvas
            property alias outlineCursorRadius: outlineCursor.radius
            property alias scrollSound: scrollSound
            property alias newImageDialog: newImageDialog
            readonly property real devicePixelRatio: Screen.devicePixelRatio
        }

        onStart: {
            Activity.start(items);
        }
        onStop: {
            processTimer.stop();
            Activity.stop();
        }

        Keys.onEscapePressed: activity.home();

        Keys.onPressed: (event) => {
            if((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_Z)) {
                Activity.undoAction();
                event.accepted = true;
            } else if((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_Y)) {
                Activity.redoAction();
                event.accepted = true;
            } else if(event.key === Qt.Key_Delete ||
                    event.key === Qt.Key_Backspace ||
                    ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_N))) {
                Activity.requestNewImage();
                event.accepted = true;
            } else if((event.modifiers === Qt.ControlModifier && event.key === Qt.Key_W)) {
                activity.home();
                event.accepted = true;
            }
        }

        Keys.onReleased: (event) => {
            if(event.key === Qt.Key_Back) {
                activity.home();
                event.accepted = true;
            }
        }

        GCSoundEffect {
            id: scrollSound
            source: "qrc:/gcompris/src/core/resource/sounds/scroll.wav"
        }

        // Toolbar: colors, eraser, thickness, undo/redo — everything always
        // visible in one compact row, nothing folded away. The colors don't
        // all have to fit on screen at once: they sit in a horizontally
        // scrollable strip (drag the strip itself, or drag the little bar
        // underneath it) so the toolbar stays a single row no matter how
        // many colors there are.
        Rectangle {
            id: toolbar
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: GCStyle.halfMargins
            }
            height: swatchSize + scrollBarHeight + GCStyle.baseMargins * 1.3
            radius: GCStyle.halfMargins
            color: GCStyle.darkBg
            border.width: GCStyle.thinnestBorder
            border.color: GCStyle.contentColor

            readonly property real swatchSize: GCStyle.bigButtonHeight * 0.7
            readonly property real scrollBarHeight: GCStyle.halfMargins * 0.7

            // The brush only reads the current color/thickness/eraser mode
            // once, when modeInit() runs — so without calling this again
            // every time one of those changes, the toolbar's own look would
            // update but drawing would silently keep using the old values.
            function refreshBrush() {
                if(tempCanvas.ctx) {
                    brushTool.toolInit();
                }
            }

            // Eraser, thickness, undo, redo: fixed-size controls, kept
            // right-aligned so the colors strip on the left gets whatever
            // width remains.
            Row {
                id: toolsRow
                anchors {
                    right: parent.right
                    rightMargin: GCStyle.baseMargins * 0.6
                    verticalCenter: parent.verticalCenter
                }
                spacing: GCStyle.halfMargins

                Rectangle {
                    id: eraserButton
                    width: toolbar.swatchSize
                    height: toolbar.swatchSize
                    radius: GCStyle.halfMargins
                    color: items.eraserMode ? GCStyle.highlightColor : "transparent"
                    border.width: GCStyle.thinnestBorder
                    border.color: GCStyle.contentColor
                    scale: eraserPressArea.pressed ? 0.92 : 1
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    Image {
                        anchors.fill: parent
                        anchors.margins: GCStyle.halfMargins * 0.5
                        source: "qrc:/gcompris/src/activities/sketch/resource/eraserTools.svg"
                        sourceSize.width: width
                        sourceSize.height: height
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        id: eraserPressArea
                        anchors.fill: parent
                        onClicked: {
                            items.eraserMode = !items.eraserMode;
                            toolbar.refreshBrush();
                        }
                    }
                }

                Rectangle {
                    width: GCStyle.thinnestBorder * 2
                    height: toolbar.swatchSize
                    color: GCStyle.contentColor
                    opacity: 0.5
                }

                Item {
                    // NOTE: this outer plain Item (with no anchors of its own) is
                    // required because Row positions its direct children by
                    // setting their x/y itself — a direct child with its own
                    // anchors conflicts with that and silently breaks the
                    // Row's layout for every sibling, not just this one.
                    // Anchoring the actual Column one level down, inside this
                    // plain Item, sidesteps that entirely.
                    width: 260 * ApplicationInfo.ratio
                    height: toolbar.swatchSize

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        spacing: GCStyle.halfMargins * 0.3

                        GCText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            color: GCStyle.whiteText
                            fontSize: GCText.smallSize
                            text: qsTr("Grosor")
                        }

                        GCSlider {
                            id: thicknessSlider
                            width: parent.width
                            from: brushTool.roundBrush.minToolSize
                            to: brushTool.roundBrush.maxToolSize
                            stepSize: brushTool.roundBrush.sizeSliderStepSize
                            value: brushTool.roundBrush.toolSize
                            onValueChanged: {
                                if(items.eraserMode) {
                                    brushTool.roundBrush.eraserSize = value;
                                } else {
                                    brushTool.roundBrush.toolSize = value;
                                }
                                toolbar.refreshBrush();
                            }

                            Connections {
                                target: items
                                function onEraserModeChanged() {
                                    thicknessSlider.value = items.eraserMode ? brushTool.roundBrush.eraserSize : brushTool.roundBrush.toolSize;
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: GCStyle.thinnestBorder * 2
                    height: toolbar.swatchSize
                    color: GCStyle.contentColor
                    opacity: 0.5
                }

                Image {
                    id: undoButton
                    source: "qrc:/gcompris/src/activities/sketch/resource/undo.svg"
                    width: toolbar.swatchSize
                    height: toolbar.swatchSize
                    sourceSize.width: width
                    sourceSize.height: height
                    enabled: canvasArea.undoSize > 1
                    opacity: enabled ? 1 : 0.5
                    scale: undoPressArea.pressed ? 0.9 : 1
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    MouseArea {
                        id: undoPressArea
                        anchors.fill: parent
                        enabled: !items.canvasLocked
                        onClicked: Activity.undoAction();
                    }
                }

                Image {
                    id: redoButton
                    source: "qrc:/gcompris/src/activities/sketch/resource/undo.svg"
                    mirror: true // mirrored undo image for redo
                    width: toolbar.swatchSize
                    height: toolbar.swatchSize
                    sourceSize.width: width
                    sourceSize.height: height
                    enabled: canvasArea.redoSize > 0
                    opacity: enabled ? 1 : 0.5
                    scale: redoPressArea.pressed ? 0.9 : 1
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    MouseArea {
                        id: redoPressArea
                        anchors.fill: parent
                        enabled: !items.canvasLocked
                        onClicked: Activity.redoAction();
                    }
                }
            }

            // Colors: a horizontally scrollable strip filling whatever
            // width is left to the left of the fixed controls above.
            Item {
                id: colorsArea
                anchors {
                    left: parent.left
                    leftMargin: GCStyle.baseMargins * 0.6
                    right: toolsRow.left
                    rightMargin: GCStyle.baseMargins * 0.6
                    verticalCenter: parent.verticalCenter
                }
                height: toolbar.swatchSize + toolbar.scrollBarHeight + GCStyle.halfMargins * 0.3

                Flickable {
                    id: colorsFlick
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    height: toolbar.swatchSize
                    contentWidth: colorsRow.width
                    contentHeight: height
                    flickableDirection: Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    Row {
                        id: colorsRow
                        spacing: GCStyle.halfMargins

                        Repeater {
                            model: activityBackground.basicColors

                            delegate: Rectangle {
                                id: colorSwatch
                                required property string modelData
                                readonly property bool isSelected: !items.eraserMode && items.selectedForegroundColor.toString() === modelData
                                width: toolbar.swatchSize
                                height: toolbar.swatchSize
                                radius: width * 0.5
                                color: modelData
                                border.width: isSelected ? GCStyle.thinBorder * 1.4 : GCStyle.thinnestBorder
                                border.color: isSelected ? GCStyle.highlightColor : GCStyle.contentColor
                                scale: pressArea.pressed ? 0.92 : 1
                                Behavior on scale { NumberAnimation { duration: 80 } }

                                MouseArea {
                                    id: pressArea
                                    anchors.fill: parent
                                    onClicked: {
                                        items.selectedForegroundColor = colorSwatch.modelData;
                                        items.eraserMode = false;
                                        toolbar.refreshBrush();
                                    }
                                }
                            }
                        }
                    }
                }

                // Draggable scroll handle under the strip — shown only when
                // there are more colors than fit at once.
                ScrollBar {
                    id: colorsScrollBar
                    anchors {
                        top: colorsFlick.bottom
                        topMargin: GCStyle.halfMargins * 0.3
                        left: colorsFlick.left
                        right: colorsFlick.right
                    }
                    height: toolbar.scrollBarHeight
                    orientation: Qt.Horizontal
                    policy: colorsRow.width > colorsFlick.width ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                    size: colorsFlick.visibleArea.widthRatio
                    position: colorsFlick.visibleArea.xPosition
                    onPositionChanged: {
                        if(pressed) {
                            colorsFlick.contentX = position * colorsFlick.contentWidth;
                        }
                    }

                    contentItem: Rectangle {
                        implicitHeight: colorsScrollBar.height
                        radius: height * 0.5
                        color: GCStyle.highlightColor
                    }
                    background: Rectangle {
                        implicitHeight: colorsScrollBar.height
                        radius: height * 0.5
                        color: GCStyle.contentColor
                        opacity: 0.35
                    }
                }
            }
        }

        Item {
            id: layoutArea
            anchors {
                top: toolbar.bottom
                bottom: bar.top
                left: parent.left
                right: parent.right
                margins: GCStyle.halfMargins
            }
        }

        GImageGrabber {
            id: canvasArea
            anchors.centerIn: layoutArea
            maxUndo: activity.undoSetting

            function init() {
                canvasInput.resetPoints();
                items.selectedTool.toolInit();
            }

            function sendToImageSource() {
                canvasImage.source = canvasArea.getImageUrl();
            }

            onGrabReady: {
                canvasArea.sendToImageSource();
                tempCanvas.clearTempCanvas();
            }

            Rectangle {
                id: canvasColor
                anchors.fill: parent
            }

            // The QML Canvas has lots of issues when deviceRatio != 1, especially it can't load images at real pixel size, only device pixel size.
            // This makes it impossible to have good undo/redo or load images with proper resolution (not looking pixelated).
            // Using an Image instead to store the painting is the only solution I found which doesn't require coding the painting tools in C++.
            Image {
                id: canvasImage
                anchors.fill: parent
                // DO NOT use Image.PreserveAspectFit, as it progressively adds some blur at each paint iteration when deviceRatio != 1...
                fillMode: Image.Stretch
                cache: false
                smooth: true
            }

            Canvas {
                id: tempCanvas
                anchors.fill: parent
                scale: 1
                x: 0
                y: 0
                renderStrategy: Canvas.Immediate
                renderTarget: Canvas.Image
                clip: true // useful to avoid Rectangle, Shapes, etc... overflows

                property var ctx

                function initContext() {
                    ctx = getContext("2d");
                }

                // After loading canvas result to image, clear Canvas
                function clearTempCanvas() {
                    tempCanvas.ctx.clearRect(0, 0, tempCanvas.width, tempCanvas.height);
                    tempCanvas.requestPaint();
                    items.canvasLocked = false;
                }

                function paintActionFinished() {
                    canvasArea.safeGrab(Qt.size(canvasArea.width, canvasArea.height));
                    // next steps are in canvasArea onGrabReady...
                }

                MouseArea {
                    id: canvasInput
                    anchors.fill: parent
                    enabled: !items.canvasLocked
                    hoverEnabled: true

                    property var lastPoint
                    property var midPoint
                    property var currentPoint

                    function savePoint() {
                        return { x: mouseX, y: mouseY };
                    }

                    function resetPoints() {
                        lastPoint = midPoint = currentPoint = { x: -1, y: -1 };
                    }

                    onPressed: {
                        items.selectedTool.toolStart();
                        items.toolStarted = true;
                    }

                    onReleased: {
                        items.canvasLocked = true;
                        items.selectedTool.toolStop();
                        items.toolStarted = false;
                    }

                    onPositionChanged: {
                        if(items.selectedTool.usePositionChanged && items.toolStarted) {
                            items.selectedTool.toolProcess();
                        }
                    }
                }

                Timer {
                    id: processTimer
                    interval: 30
                    repeat: true
                    onTriggered: {
                        items.selectedTool.toolProcess();
                    }
                }
            }
        }

        Rectangle {
            id: outlineCursor
            color: "#00000000"
            border.color: "#80000000"
            border.width: 1
            radius: 0
            width: 2 * radius
            height: width
            visible: canvasInput.containsMouse && radius > 0
            x: canvasInput.mouseX - radius + canvasArea.x
            y: canvasInput.mouseY - radius + canvasArea.y

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                color: parent.color
                border.color: "#80FFFFFF"
                border.width: 1
                radius: width
            }
        }

        BrushTool {
            id: brushTool
        }

        Loader {
            id: newImageDialog
            sourceComponent: GCDialog {
                parent: activity
                isDestructible: false
                message: qsTr("¿Quieres borrar el dibujo?")
                button1Text: qsTr("Sí")
                button2Text: qsTr("No")
                onClose: {
                    newImageDialog.active = false;
                    items.resetRequested = false;
                }
                onButton1Hit: {
                    if(items.resetRequested) {
                        Activity.resetLevel();
                    }
                }
            }
            anchors.fill: parent
            focus: true
            active: false
            onStatusChanged: if(status == Loader.Ready) item.start();
        }

        DialogHelp {
            id: dialogHelp
            onClose: activity.home();
        }

        Bar {
            id: bar
            content: BarEnumContent { value: help | home | reload }
            onHelpClicked: {
                displayDialog(dialogHelp);
            }
            onHomeClicked: {
                activity.home();
            }
            onReloadClicked: {
                Activity.requestNewImage();
            }
        }
    }
}
