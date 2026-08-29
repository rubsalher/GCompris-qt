/* GCompris - ReorderActivitiesPage.qml
 *
 * Elderly-friendly build: new screen, not part of upstream GCompris.
 * Lets the user reorder the activities shown in the main menu grid, with
 * simple up/down buttons per row (no drag-and-drop — easier and more
 * reliable to hit precisely on a touch frame). Opened from the "Ordenar
 * los juegos del menú" button in ConfigurationItem.qml, following the
 * exact same show/hide pattern as ServerConfigPage.qml (a sibling full
 * screen overlay inside Menu.qml's DialogActivityConfig).
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import core 1.0

import "../../core"

Rectangle {
    id: reorderPage
    color: GCStyle.configBg
    z: 10000
    anchors.fill: parent
    visible: false
    focus: visible

    signal close

    onClose: parent.forceActiveFocus()

    Keys.onEscapePressed: close()
    Keys.onReleased: (event) => {
        if(event.key === Qt.Key_Back) {
            close();
            event.accepted = true;
        }
    }

    // Same storage key and ordering rule as Menu.qml's own
    // applyMenuOrder() — kept in sync manually since these live in two
    // different files with no shared module for it.
    readonly property string orderStorageKey: "menu-activity-order"

    ListModel {
        id: activitiesModel
    }

    // Rebuilds the list from the currently enabled activities, in the
    // order the main menu currently shows them (saved order if any, the
    // default activities.txt order otherwise) — so what's shown here
    // always matches reality when the page is opened.
    function loadActivities() {
        var full = ActivityInfoTree.menuTreeFull;
        var enabledItems = [];
        for (var i = 0; i < full.length; ++i) {
            if (full[i].enabled)
                enabledItems.push(full[i]);
        }

        var saved = ApplicationSettings.currentLevels(orderStorageKey);
        var ordered = enabledItems;
        if (saved && saved.length > 0) {
            var byName = {};
            for (var j = 0; j < enabledItems.length; ++j)
                byName[enabledItems[j].name] = enabledItems[j];
            var result = [];
            var used = {};
            for (var k = 0; k < saved.length; ++k) {
                var found = byName[saved[k]];
                if (found && !used[saved[k]]) {
                    result.push(found);
                    used[saved[k]] = true;
                }
            }
            for (var m = 0; m < enabledItems.length; ++m) {
                if (!used[enabledItems[m].name])
                    result.push(enabledItems[m]);
            }
            ordered = result;
        }

        activitiesModel.clear();
        for (var n = 0; n < ordered.length; ++n) {
            activitiesModel.append({
                "activityName": ordered[n].name,
                "activityTitle": ordered[n].title,
                "activityIcon": ordered[n].icon
            });
        }
    }

    // Persists the current on-screen order immediately — no separate
    // "save" step, every tap of an arrow both moves the row and saves.
    function saveOrder() {
        var names = [];
        for (var i = 0; i < activitiesModel.count; ++i)
            names.push(activitiesModel.get(i).activityName);
        ApplicationSettings.setCurrentLevels(orderStorageKey, names);
    }

    function moveActivity(from, to) {
        if (to < 0 || to >= activitiesModel.count)
            return;
        activitiesModel.move(from, to, 1);
        saveOrder();
    }

    onVisibleChanged: {
        if (visible)
            loadActivities();
    }

    Column {
        id: topColumn
        spacing: GCStyle.halfMargins
        anchors.top: parent.top
        anchors.topMargin: GCStyle.baseMargins
        anchors.horizontalCenter: parent.horizontalCenter
        width: reorderPage.width - 2 * GCStyle.baseMargins

        Rectangle {
            id: titleRectangle
            color: GCStyle.lightBg
            radius: GCStyle.baseMargins
            width: parent.width
            height: Math.max(title.height, cancel.height) + GCStyle.baseMargins

            GCText {
                id: title
                text: qsTr("Ordenar los juegos del menú")
                width: titleRectangle.width - (cancel.width + cancel.anchors.margins) * 2
                height: 50 * ApplicationInfo.ratio
                anchors.horizontalCenter: titleRectangle.horizontalCenter
                anchors.verticalCenter: titleRectangle.verticalCenter
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                minimumPointSize: 7
                fontSize: largeSize
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
            }
            // The cancel/close button
            GCButtonCancel {
                id: cancel
                anchors.top: undefined
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: GCStyle.tinyMargins
                apply: true
                onClose: reorderPage.close()
            }
        }
    }

    Rectangle {
        id: listBg
        anchors {
            top: topColumn.bottom
            topMargin: GCStyle.halfMargins
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: GCStyle.baseMargins
        }
        width: topColumn.width
        radius: GCStyle.baseMargins
        color: GCStyle.lightTransparentBg
        border.color: GCStyle.whiteBorder
        border.width: GCStyle.midBorder

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: GCStyle.baseMargins
            anchors.rightMargin: scrollItem.width + GCStyle.halfMargins
            clip: true
            model: activitiesModel
            spacing: GCStyle.halfMargins
            maximumFlickVelocity: reorderPage.height
            boundsBehavior: Flickable.StopAtBounds

            header: GCText {
                width: list.width
                height: contentHeight + GCStyle.baseMargins
                text: qsTr("Usa las flechas para subir o bajar cada juego. Los cambios se guardan al momento.")
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignBottom
                fontSize: smallSize
                color: GCStyle.darkText
            }

            move: Transition {
                NumberAnimation { properties: "y"; duration: 200 }
            }
            displaced: Transition {
                NumberAnimation { properties: "y"; duration: 200 }
            }

            delegate: Rectangle {
                id: rowDelegate
                required property int index
                required property string activityName
                required property string activityTitle
                required property string activityIcon

                width: list.width
                height: GCStyle.bigButtonHeight * 0.85
                radius: GCStyle.halfMargins
                color: GCStyle.whiteBg
                border.width: GCStyle.thinnestBorder
                border.color: GCStyle.grayBorder

                readonly property real arrowSize: height - GCStyle.halfMargins

                Image {
                    id: rowIcon
                    source: "qrc:/gcompris/src/activities/" + rowDelegate.activityIcon
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        margins: GCStyle.halfMargins * 0.5
                    }
                    width: rowDelegate.arrowSize
                    height: width
                    sourceSize.width: width
                    sourceSize.height: width
                    fillMode: Image.PreserveAspectFit
                }

                GCText {
                    anchors {
                        left: rowIcon.right
                        leftMargin: GCStyle.halfMargins
                        right: upButton.left
                        rightMargin: GCStyle.halfMargins
                        verticalCenter: parent.verticalCenter
                    }
                    text: rowDelegate.activityTitle
                    textFormat: Text.PlainText
                    fontSizeMode: Text.Fit
                    minimumPointSize: 7
                    fontSize: regularSize
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    color: GCStyle.darkText
                }

                Rectangle {
                    id: upButton
                    anchors {
                        right: downButton.left
                        rightMargin: GCStyle.halfMargins * 0.5
                        verticalCenter: parent.verticalCenter
                    }
                    width: rowDelegate.arrowSize
                    height: width
                    radius: GCStyle.halfMargins * 0.5
                    color: upMouse.pressed ? GCStyle.highlightColor : GCStyle.lightBg
                    border.width: GCStyle.thinnestBorder
                    border.color: GCStyle.grayBorder
                    opacity: rowDelegate.index === 0 ? 0.35 : 1

                    Image {
                        anchors.fill: parent
                        anchors.margins: parent.width * 0.22
                        source: "qrc:/gcompris/src/core/resource/arrow_up.svg"
                        sourceSize.width: width
                        sourceSize.height: height
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        id: upMouse
                        anchors.fill: parent
                        enabled: rowDelegate.index > 0
                        onClicked: reorderPage.moveActivity(rowDelegate.index, rowDelegate.index - 1)
                    }
                }

                Rectangle {
                    id: downButton
                    anchors {
                        right: parent.right
                        rightMargin: GCStyle.halfMargins * 0.5
                        verticalCenter: parent.verticalCenter
                    }
                    width: rowDelegate.arrowSize
                    height: width
                    radius: GCStyle.halfMargins * 0.5
                    color: downMouse.pressed ? GCStyle.highlightColor : GCStyle.lightBg
                    border.width: GCStyle.thinnestBorder
                    border.color: GCStyle.grayBorder
                    opacity: rowDelegate.index === activitiesModel.count - 1 ? 0.35 : 1

                    Image {
                        anchors.fill: parent
                        anchors.margins: parent.width * 0.22
                        source: "qrc:/gcompris/src/core/resource/arrow_down.svg"
                        sourceSize.width: width
                        sourceSize.height: height
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        id: downMouse
                        anchors.fill: parent
                        enabled: rowDelegate.index < activitiesModel.count - 1
                        onClicked: reorderPage.moveActivity(rowDelegate.index, rowDelegate.index + 1)
                    }
                }
            }
        }

        // The scroll buttons
        GCButtonScroll {
            id: scrollItem
            anchors.right: parent.right
            anchors.rightMargin: GCStyle.halfMargins
            anchors.bottom: list.bottom
            anchors.bottomMargin: GCStyle.halfMargins
            onUp: list.flick(0, 1000)
            onDown: list.flick(0, -1000)
            upVisible: list.atYBeginning ? false : true
            downVisible: list.atYEnd ? false : true
        }
    }
}
