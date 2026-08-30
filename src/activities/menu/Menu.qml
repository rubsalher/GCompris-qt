/* GCompris - Menu.qml
 *
 * SPDX-FileCopyrightText: 2014 Bruno Coudoin <bruno.coudoin@gcompris.net>
 *
 * Authors:
 *   Bruno Coudoin <bruno.coudoin@gcompris.net> (Qt Quick port)
 *
 *   SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import "../../core"
import core 1.0
import QtQuick.Effects
import "qrc:/gcompris/src/core/core.js" as Core

// For TextField
import QtQuick.Controls.Basic

/**
 * GCompris' top level menu screen.
 *
 * Displays a grid of available activities divided subdivided in activity
 * categories/sections.
 *
 * The visibility of the section row is toggled by the setting
 * ApplicationSettings.sectionVisible.
 *
 * The list of available activities depends on the following settings:
 *
 * * ApplicationSettings.filterLevelMin
 * * ApplicationSettings.filterLevelMax
 *
 * @inherit QtQuick.Item
 */
ActivityBase {
    id: activity
    focus: true
    activityInfo: ActivityInfoTree.rootMenu
    isMenu: true
    onBack: (to) => {
        if (pageView.currentItem === activity) {
            // Restore focus that has been taken by the loaded activity
            focus = true
        } else {
            pageView.pop(to)
        }

    }

    onHome: {
        if(pageView.depth === 1 && ApplicationSettings.isKioskMode) {
            return;
        }
        else if(pageView.depth === 1) {
            Core.quit(activity);
        }
        else {
            pageView.popElement();
            // Restore focus that has been taken by the loaded activity
            if(pageView.currentItem === activity) {
                focus = true;
                if(ActivityInfoTree.startingActivity != "") {
                    Core.quit(activity);
                }
            }
        }
    }

    onDisplayDialog: (dialog) => pageView.pushElement(dialog)

    onDisplayDialogs: (dialogs) => {
        for (var i = 0; i < dialogs.length; i++) {
            pageView.pushElement(dialogs[i]);
        }
    }

    //when selecting a new language in config, we need to open the newVoicesDialog,
    //but only after the config page is closed, hence the need to have a signal calling a Timer calling the function
    signal newVoicesSignal
    onNewVoicesSignal: newVoicesDialogTimer.restart();

    Timer {
        id: newVoicesDialogTimer
        interval: 250
        onTriggered: newVoicesDialog();
    }
    function newVoicesDialog() {
        Core.showMessageDialog(activity,
                qsTr("You selected a new locale, do you want to download the corresponding sound files now?"),
                qsTr("Yes"), function() {
                    // yes -> start download
                    if (DownloadManager.downloadResource(
                            GCompris.VOICES,
                           {"locale": ApplicationInfo.getVoicesLocale(ApplicationSettings.locale)}))
                    var downloadDialog = Core.showDownloadDialog(pageView.currentItem, {});
                },
                qsTr("No"), null,
                null
                );
    }

    // @cond INTERNAL_DOCS
    property string url: "qrc:/gcompris/src/activities/menu/resource/"
    readonly property var sections: [
        {
            icon: activity.url + "all.svg",
            tag: "favorite"
        },
        {
            icon: activity.url + "computer.svg",
            tag: "computer"
        },
        {
            icon: activity.url + "discovery.svg",
            tag: "discovery",
            categories: [{ "logic": qsTr("Logic") },
                         { "arts": qsTr("Fine Arts") },
                         { "music": qsTr("Music") }
            ]
        },
        {
            icon: activity.url + "sciences.svg",
            tag: "sciences",
            categories: [{ "experiment": qsTr("Experiment") },
                         { "history": qsTr("History") },
                         { "geography": qsTr("Geography") }
            ]
        },
        {
            icon: activity.url + "fun.svg",
            tag: "fun"
        },
        {
            icon: activity.url + "math.svg",
            tag: "math",
            categories: [{ "numeration": qsTr("Numeration") },
                         { "arithmetic": qsTr("Arithmetic") },
                         { "measures": qsTr("Measures") }
                        ]
        },
        {
            icon: activity.url + "puzzle.svg",
            tag: "puzzle"
        },
        {
            icon: activity.url + "reading.svg",
            tag: "reading",
            categories: [{ "letters": qsTr("Letters") },
                         { "words": qsTr("Words") },
                         { "vocabulary": qsTr("Vocabulary") }
                        ]
        },
        {
            icon: activity.url + "strategy.svg",
            tag: "strategy"
        },
        {
            icon: activity.url + "search-icon.svg",
            tag: "search"
        }
    ]
    // elderly-friendly build: single flat activity list by default (no category tabs)
    property string currentTag: "all"
    property var currentTagCategories: []
    property string currentCategory: ""
    /// @endcond

    // Elderly-friendly build: the order the activities show up in the grid
    // below, applied on top of ActivityInfoTree.menuTree — see
    // applyMenuOrder()/menuOrderStorageKey below and ReorderActivitiesPage.qml
    // for where the user actually edits this order from Settings.
    readonly property string menuOrderStorageKey: "menu-activity-order"
    property var orderedMenuTree: applyMenuOrder(ActivityInfoTree.menuTree)

    // Returns a NEW array: `items` (a list of ActivityInfo, each with a
    // .name) reordered according to the saved preference (an array of
    // activity names) — anything not found in that saved list (e.g. an
    // activity added since the last reorder) is appended at the end, in
    // its original relative order, so it still shows up.
    function applyMenuOrder(items) {
        var saved = ApplicationSettings.currentLevels(menuOrderStorageKey);
        if (!saved || saved.length === 0)
            return items;

        var byName = {};
        for (var i = 0; i < items.length; ++i)
            byName[items[i].name] = items[i];

        var ordered = [];
        var used = {};
        for (var j = 0; j < saved.length; ++j) {
            var found = byName[saved[j]];
            if (found && !used[saved[j]]) {
                ordered.push(found);
                used[saved[j]] = true;
            }
        }
        for (var k = 0; k < items.length; ++k) {
            if (!used[items[k].name])
                ordered.push(items[k]);
        }
        return ordered;
    }

    signal startActivity(string activityName, int level)

    signal startNextActivityInSequence

    pageComponent: Image {
        id: activityBackground
        source: activity.url + "background.svg"
        sourceSize.width: width
        sourceSize.height: height
        height: main.height
        width: main.width
        fillMode: Image.PreserveAspectCrop

        function loadActivity() {
            //take the focus away from textField before starting an activity
            searchTextField.focus = false

            pageView.pushElement(activityLoader.item)
            ActivityInfoTree.startingLevel = -1
        }

        Loader {
            id: activityLoader
            asynchronous: true
            onStatusChanged: {
                if (status == Loader.Loading) {
                    loading.start();
                } else if (status == Loader.Ready) {
                    loading.stop();
                    loadActivity();
                } else if (status == Loader.Error) {
                    loading.stop();
                }
            }
        }

        // Filters
        property bool horizontal: activityBackground.width >= activityBackground.height
        property int sectionIconWidth: sectionCellWidth * 0.9
        // sectionCellWidth value is defined in states
        property real sectionCellWidth: 1
        property real categoriesHeight: Math.max(45 * ApplicationInfo.ratio, sectionCellWidth * 0.5)

        // messages for server status dialog
        property string serverNotConnected: qsTr("GCompris is not connected to teacher's server.")
        property string serverBadPassword: qsTr("GCompris is connected to teacher's server, but the password entered for selected user is wrong.")
        property string serverLoggedIn: qsTr("GCompris is connected to teacher's server, and the user is authenticated as %1.").arg(currentLogin)
        property string serverConnectionLost: qsTr("GCompris has lost the connection to teacher's server.")
        property string serverDisconnected: qsTr("GCompris has been disconnected from teacher's server.")
        property string serverConnected: qsTr("GCompris is connected to teacher's server, but the user is not yet authenticated.")
        // Used to hot-reload the message if it changes while the dialog is displayed.
        property string currentLogin: ""
        property var dialogServerStatus: null
        property string serverStatusMessage: serverNotConnected
        onServerStatusMessageChanged: {
            if(dialogServerStatus) {
                dialogServerStatus.message = serverStatusMessage;
            }
        }

        property var currentActiveGrid: activitiesGrid
        property bool keyboardMode: false
        Keys.onPressed: (event) => {
            if(loading.active) {
                return;
            }
            // Ctrl-modifiers should never be handled by the search-field
            if (event.modifiers === Qt.ControlModifier) {
                if (event.key === Qt.Key_S) {
                    // Ctrl+S toggle show / hide section
                    ApplicationSettings.sectionVisible = !ApplicationSettings.sectionVisible
                }
            } else if(activity.currentTag === "search") {
                // forward to the virtual keyboard the pressed keys
                event.accepted = true;
                if(event.key === Qt.Key_Backspace)
                    keyboard.keypress(keyboard.backspace);
                else if(event.key === Qt.Key_Escape)
                    home();
                else
                    keyboard.keypress(event.text);
            } else if(event.key === Qt.Key_Space && currentActiveGrid.currentItem) {
                currentActiveGrid.currentItem.selectCurrentItem()
            }
        }
        Keys.onReleased: (event) => {
            keyboardMode = true
            event.accepted = false
        }
        Keys.onTabPressed: (event) => {
            if(!ApplicationSettings.sectionVisible) {
                currentActiveGrid = activitiesGrid;
            }
            else if(currentActiveGrid == section) {
                if(activity.currentTagCategories && activity.currentTagCategories.length != 0) {
                    currentActiveGrid = categoriesGrid;
                }
                else {
                    currentActiveGrid = activitiesGrid;
                }
            }
            else if(currentActiveGrid == categoriesGrid) {
                currentActiveGrid = activitiesGrid;
            }
            else {
                currentActiveGrid = section;
            }
        }
        Keys.onEnterPressed: if(currentActiveGrid.currentItem && !loading.active) currentActiveGrid.currentItem.selectCurrentItem();
        Keys.onReturnPressed: if(currentActiveGrid.currentItem && !loading.active) currentActiveGrid.currentItem.selectCurrentItem();
        Keys.onRightPressed: if(currentActiveGrid.currentItem && !loading.active) currentActiveGrid.moveCurrentIndexRight();
        Keys.onLeftPressed: if(currentActiveGrid.currentItem && !loading.active) currentActiveGrid.moveCurrentIndexLeft();
        Keys.onDownPressed: if(currentActiveGrid.currentItem && !loading.active) currentActiveGrid.moveCurrentIndexDown();
        Keys.onUpPressed: if(currentActiveGrid.currentItem && !loading.active) currentActiveGrid.moveCurrentIndexUp();

        // elderly-friendly build: big clock/date banner where the category bar used to be,
        // for time/day orientation instead of an empty or purely decorative strip
        Rectangle {
            id: clockBar
            anchors.top: activityBackground.top
            anchors.left: activityBackground.left
            anchors.right: activityBackground.right
            // was * 1.4 — too tall a banner just for one line of text, reduced at the user's request
            height: GCStyle.bigButtonHeight * 0.85
            color: GCStyle.lightTransparentBg

            property var now: new Date()
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clockBar.now = new Date()
            }

            function capitalize(str: string): string {
                return str.length ? str.charAt(0).toUpperCase() + str.slice(1) : str;
            }

            GCText {
                anchors.centerIn: parent
                fontSize: 22
                font.weight: Font.DemiBold
                color: GCStyle.darkText
                // use the app's own chosen language for the day/month names, not the
                // OS locale, so it stays in sync with the rest of the translated UI
                text: clockBar.capitalize(Qt.locale(ApplicationSettings.locale).toString(clockBar.now, "dddd d MMMM")) +
                      "   •   " + Qt.formatDateTime(clockBar.now, "hh:mm")
            }
        }

        GridView {
            id: section
            model: activity.sections
            x: 0
            y: 0
            // elderly-friendly build: category bar (with animal-mascot icons) permanently
            // hidden, not just default-off, so it can't reappear via a saved setting or
            // the Ctrl+S/B shortcut
            visible: false
            cellWidth: activityBackground.sectionCellWidth
            cellHeight: activityBackground.sectionCellWidth
            interactive: false
            keyNavigationWraps: true
            highlightMoveDuration: 0
            property int currentSectionSelected: 0

            Component {
                id: sectionDelegate
                Item {
                    id: backgroundSection
                    width: activityBackground.sectionCellWidth - GCStyle.halfMargins
                    height: width

                    Rectangle {
                        visible: section.currentSectionSelected === index
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#80FFFFFF" }
                            GradientStop { position: 1.0; color: "#40FFFFFF" }
                        }
                        border.width: GCStyle.thinnestBorder
                        border.color: GCStyle.whiteBorder
                    }

                    Image {
                        source: modelData.icon
                        sourceSize.width: activityBackground.sectionIconWidth
                        sourceSize.height: activityBackground.sectionIconWidth
                        anchors.centerIn: parent
                    }

                    ParticleSystemStarLoader {
                        id: particles
                        anchors.fill: backgroundSection
                        clip: false
                    }
                    MouseArea {
                        anchors.fill: backgroundSection
                        onClicked: {
                            selectCurrentItem()
                        }
                    }

                    function selectCurrentItem() {
                        if(section.currentSectionSelected === index) {
                            section.currentIndex = index // in case it was moved with keyboard
                            return
                        }
                        section.currentIndex = index
                        activity.currentTag = modelData.tag
                        activity.currentTagCategories = modelData.categories
                        if(modelData.categories !== undefined) {
                            activity.currentCategory = Object.keys(modelData.categories[0])[0];
                        }
                        else {
                            activity.currentCategory = ""
                        }
                        particles.burst(10)
                        if(modelData.tag === "search") {
                            ActivityInfoTree.filterBySearch(searchTextField.text);
                        }
                        else {
                            ActivityInfoTree.filterByTag(modelData.tag, activity.currentCategory, false)
                            ActivityInfoTree.filterEnabledActivities(true)
                        }
                        section.currentSectionSelected = index
                    }
                }
            }
            delegate: sectionDelegate
            highlight: Rectangle {
                    color: "transparent"
                    border.width: GCStyle.thinBorder
                    border.color: GCStyle.whiteBorder
            }
        }

        GridView {
            id: categoriesGrid
            model: activity.currentTagCategories
            x: activitiesGrid.x
            height: activity.currentCategory == "" ? 0 : activityBackground.categoriesHeight
            width: activitiesGrid.width
            interactive: false
            keyNavigationWraps: true
            highlightFollowsCurrentItem: false
            visible: activity.currentTag !== "search"
            cellWidth: activity.currentTagCategories ? categoriesGrid.width / activity.currentTagCategories.length : 0
            cellHeight: height
            property int currentCategorySelected: 0

            onModelChanged: currentCategorySelected = 0;

            delegate: GCButton {
                id: button
                selected: categoriesGrid.currentIndex === index
                down: activity.currentCategory === button.category
                theme: "categories"
                textSize: "regular"
                rightIconSize: rightIcon.width + rightIcon.anchors.rightMargin
                width: categoriesGrid.cellWidth - GCStyle.halfMargins
                height: categoriesGrid.cellHeight
                text: modelData[category]
                property string category: Object.keys(modelData)[0]
                onClicked: {
                    selectCurrentItem()
                }

                function selectCurrentItem() {
                    if(categoriesGrid.currentCategorySelected === index) {
                        categoriesGrid.currentIndex = index // in case it was moved with keyboard
                        return
                    }
                    categoriesGrid.currentIndex = index
                    activity.currentCategory = Object.keys(modelData)[0]
                    ActivityInfoTree.filterByTag(activity.currentTag, activity.currentCategory, false)
                    ActivityInfoTree.filterEnabledActivities(true)
                    categoriesGrid.currentCategorySelected = index
                }

                Image {
                    id: rightIcon
                    visible: activityBackground.horizontal
                    source: "qrc:/gcompris/src/activities/menu/resource/category-" + button.category + ".svg";
                    height: visible ? Math.floor(parent.height * 0.8) : 0
                    sourceSize.height: height
                    width: height
                    anchors {
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                        rightMargin: visible ? GCStyle.halfMargins : 0
                    }
                }
            }
            highlight: Item {}
        }

        // Activities
        property int iconWidth: 120 * ApplicationInfo.ratio
        property real activityCellWidth:  activitiesGrid.width / Math.max(1, Math.floor(activitiesGrid.width / iconWidth))
        property real activityCellHeight: iconWidth * 1.7

        Rectangle {
            id: activitiesMask
            visible: false
            layer.enabled: true
            anchors.fill: activitiesGrid
            // Dynamic position of the gradient used for OpacityMask
            // If the hidden bottom part of the grid is > to the maximum height of the gradient,
            // we use the maximum height.
            // Else we set the gradient start position proportionnally to the hidden bottom part,
            // until it disappears.
            // And if using software renderer, the mask is disabled, so we save the calculation and set it to 1
            property real gradientStartValue:
            !ApplicationInfo.useSoftwareRenderer ?
            (activitiesGrid.hiddenBottom > activitiesGrid.height * 0.08 ?
            0.92 : 1 - (activitiesGrid.hiddenBottom / activitiesGrid.height)) :
            1
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#FFFFFFFF" }
                GradientStop { position: activitiesMask.gradientStartValue; color: "#FFFFFFFF" }
                GradientStop { position: activitiesMask.gradientStartValue + 0.04; color: "#00FFFFFF"}
            }
        }

        GridView {
            id: activitiesGrid
            anchors {
                top: {
                    if(searchBar.visible)
                        return searchBar.bottom
                    else if (activity.currentCategory != "")
                        return categoriesGrid.bottom
                    else
                        // elderly-friendly build: category bar is permanently hidden,
                        // grid starts right below the clock/date banner
                        return clockBar.bottom
                }
                // Elderly-friendly build: when the bar is hidden (via the
                // three-line toggle), let the activity grid use that freed-up
                // space too, instead of always reserving the bar's full
                // height — reveals more activity tiles at once.
                bottom: ApplicationSettings.isBarHidden ? activityBackground.bottom : bar.top
                right: activityBackground.right
                margins: GCStyle.halfMargins
                rightMargin: 0
                topMargin: GCStyle.halfMargins
            }
            cellWidth: activityCellWidth
            cellHeight: activityCellHeight
            clip: true
            model: activity.orderedMenuTree
            keyNavigationWraps: true
            maximumFlickVelocity: activity.height
            boundsBehavior: Flickable.StopAtBounds
            // Needed to calculate the OpacityMask offset
            // If using software renderer, this value is not used, so we save the calculation and set it to 1
            property real hiddenBottom: ApplicationInfo.useSoftwareRenderer ? 1 : contentHeight - height - contentY

            delegate: Item {
                id: delegateItem
                width: activityCellWidth - GCStyle.halfMargins
                height: activityCellHeight - GCStyle.halfMargins
                property var activityInfoTreeItem: activity.orderedMenuTree[index]
                Rectangle {
                    id: activityCard
                    width: parent.width
                    height: parent.height
                    color: GCStyle.whiteBg
                    opacity: 0.5
                }
                // Elderly-friendly build: the difficulty-star badges and
                // the "new activity" sunburst badge that used to sit on
                // top of every tile's icon were dropped — clutter with no
                // real use in a fork where every activity in the menu is
                // already a fixed, hand-picked set (see also the favorite
                // star removed below).
                Image {
                    id: activityIcon
                    source: "qrc:/gcompris/src/activities/" + activityInfoTreeItem.icon
                    anchors.top: activityCard.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: iconWidth - GCStyle.halfMargins
                    height: width
                    sourceSize.width: width
                    fillMode: Image.PreserveAspectFit
                    anchors.margins: GCStyle.halfMargins
                    opacity: delegateItem.enabled ? 1 : 0.5
                }
                GCText {
                    id: title
                    anchors.top: activityIcon.bottom
                    anchors.bottom: activityCard.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: GCStyle.tinyMargins
                    horizontalAlignment: Text.AlignHCenter
                    fontSizeMode: Text.Fit
                    minimumPointSize: 7
                    fontSize: regularSize
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap
                    text: activityInfoTreeItem.title
                    textFormat: Text.PlainText
                    opacity: activityIcon.opacity
                }
                ParticleSystemStarLoader {
                    id: particles
                    anchors.fill: activityCard
                }
                MouseArea {
                    anchors.fill: activityCard
                    onClicked: selectCurrentItem()
                }

                function selectCurrentItem() {
                    if(pageView.busy || !delegateItem.enabled)
                        return

                    particles.burst(50)
                    ActivityInfoTree.currentActivity = activityInfoTreeItem
                    activityLoader.setSource("qrc:/gcompris/src/activities/" + ActivityInfoTree.currentActivity.name,
                    {
                        'menu': activity,
                        'activityInfo': ActivityInfoTree.currentActivity,
                        'levelFolder': activityInfoTreeItem.currentLevels,
                        'audioVoices': audioVoices,
                        'loading': loading
                    })
                    if (activityLoader.status == Loader.Ready) loadActivity()
                    activitiesGrid.currentIndex = index
                }
            }
            highlight: Rectangle {
                width: activityCellWidth - GCStyle.halfMargins
                height: activityCellHeight - GCStyle.halfMargins
                color:  "#AAFFFFFF"
                border.width: GCStyle.thinBorder
                border.color: GCStyle.whiteBorder
                visible: activityBackground.keyboardMode
                Behavior on x { SpringAnimation { spring: 2; damping: 0.2 } }
                Behavior on y { SpringAnimation { spring: 2; damping: 0.2 } }
            }
            layer.enabled: !ApplicationInfo.useSoftwareRenderer
            layer.effect: MultiEffect {
                id: activitiesOpacity
                maskEnabled: true
                maskSource: activitiesMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }
        }

        Loader {
            id: warningOverlay
            anchors.fill: activitiesGrid
            active: (ActivityInfoTree.menuTree.length === 0) && (activity.currentTag === "favorite")
            sourceComponent: Item {
                GCText {
                    id: instructionTxt
                    fontSize: smallSize
                    y: 2 * GCStyle.baseMargins
                    z: 2
                    width: parent.width * 0.7 - 2 * GCStyle.baseMargins
                    height: parent.height - 3 * GCStyle.baseMargins
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    font.weight: Font.DemiBold
                    color: GCStyle.whiteText
                    text: qsTr("Put your favorite activities here by clicking on the " +
                    "sun at the top right of that activity.")
                }
                Rectangle {
                    y: GCStyle.baseMargins
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: instructionTxt.contentWidth + 2 * GCStyle.baseMargins
                    height: instructionTxt.contentHeight + 2 * GCStyle.baseMargins
                    z: 1
                    radius: GCStyle.halfMargins
                    border.width: GCStyle.thinnestBorder
                    border.color: GCStyle.whiteBorder
                    color: "#527482"
                }
            }
        }

        // The scroll buttons
        GCButtonScroll {
            visible: ApplicationInfo.useSoftwareRenderer
            anchors.right: parent.right
            anchors.bottom: activitiesGrid.bottom
            anchors.margins: GCStyle.halfMargins
            onUp: activitiesGrid.flick(0, 1127)
            onDown: activitiesGrid.flick(0, -1127)
            upVisible: activitiesGrid.atYBeginning ? false : true
            downVisible: activitiesGrid.atYEnd ? false : true
        }

        Rectangle {
            id: searchBar
            visible: activity.currentTag === "search"
            height: activityBackground.categoriesHeight
            radius: GCStyle.halfMargins
            border.width: GCStyle.thinnestBorder
            border.color: GCStyle.darkBorder
            color: GCStyle.lightBg

            Connections {
                // On mobile with GCompris' virtual keyboard activated:
                // Force invisibility of Androids virtual keyboard:
                target: (ApplicationInfo.isMobile && activity.currentTag === "search"
                         && ApplicationSettings.isVirtualKeyboard) ? Qt.inputMethod : null
                function onVisibleChanged() {
                    if (ApplicationSettings.isVirtualKeyboard && visible)
                        Qt.inputMethod.hide();
                }
                function onAnimatingChanged() {
                    // note: seems to be never fired!
                    if (ApplicationSettings.isVirtualKeyboard && Qt.inputMethod.visible)
                        Qt.inputMethod.hide();
                }
            }

            Connections {
                target: activity
                function onCurrentTagChanged() {
                    if (activity.currentTag === 'search') {
                        if(ApplicationSettings.isVirtualKeyboard && !keyboard.isPopulated) {
                            keyboard.populate();
                            keyboard.isPopulated = true;
                        }
                        searchTextField.focus = true;
                    } else
                        activity.focus = true;
                }

                function onStartActivity(activityName: string, level: int) {
                    ActivityInfoTree.setCurrentActivityFromName(activityName)
                    print(activityName,  ActivityInfoTree.currentActivity.name)
                    var currentLevels = ActivityInfoTree.currentActivity.currentLevels
                    activityLoader.setSource("qrc:/gcompris/src/activities/" + ActivityInfoTree.currentActivity.name,
                    {
                        'menu': activity,
                        'audioVoices': audioVoices,
                        'loading': loading,
                        'activityInfo': ActivityInfoTree.currentActivity,
                        'levelFolder': currentLevels
                    })
                    if (activityLoader.status == Loader.Ready) loadActivity()
                }

                function onStartNextActivityInSequence() {
                    // First go back to the menu
                    while(pageView.depth > 1) {
                        home()
                    }
                    print("next activity in sequence!")
                    // always start at level 0, we should load dataset in the order of the sequence!
                    var nextActivity = ActivityInfoTree.nextActivityInSequence();
                    if(nextActivity) {
                        activity.startActivity(nextActivity, 0);
                    }
                    else {
                        print("end of sequence!")
                        ActivityInfoTree.resetAfterSequence();
                    }
                }
            }

            Connections {
                target: clientNetworkMessages
                function onLoginChanged(newLogin) {
                    activityBackground.currentLogin = clientNetworkMessages.login
                }
                function onStatusChanged() {
                    print("status changed to ", clientNetworkMessages.status);
                    switch(clientNetworkMessages.status) {
                    case NetConst.NOT_CONNECTED:
                        ApplicationInfo.setServerStatusColor("#40000000"); // transparent black
                        activityBackground.serverStatusMessage = activityBackground.serverNotConnected;
                        break;
                    case NetConst.BAD_PASSWORD_INPUT:
                        ApplicationInfo.setServerStatusColor("#d94444"); // red
                        activityBackground.serverStatusMessage = activityBackground.serverBadPassword;
                        break;
                    case NetConst.CONNECTED:
                        ApplicationInfo.setServerStatusColor("#5cc854"); // green
                        activityBackground.serverStatusMessage = activityBackground.serverLoggedIn;
                        break;
                    case NetConst.CONNECTION_LOST:
                        ApplicationInfo.setServerStatusColor("#e7bb36"); // yellow
                        activityBackground.serverStatusMessage = activityBackground.serverConnectionLost;
                        break;
                    case NetConst.DISCONNECTED:
                        ApplicationInfo.setServerStatusColor("#808080"); // gray
                        activityBackground.serverStatusMessage = activityBackground.serverDisconnected;
                        break;
                    default:
                        ApplicationInfo.setServerStatusColor("#801bd0d2"); // transparent blue
                        activityBackground.serverStatusMessage = activityBackground.serverConnected;
                    }
                }
            }

            Connections {
                target: ActivityInfoTree
                function onStartSequence() {
                    activity.startNextActivityInSequence();
                }
            }

            TextField {
                id: searchTextField
                width: parent.width
                height: parent.height
                color: GCStyle.darkText
                font.pixelSize: height * 0.5
                font.bold: true
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                font.family: GCSingletonFontLoader.fontName
                inputMethodHints: Qt.ImhNoPredictiveText
                // Note: we give focus to the textfield also in case
                // isMobile && !ApplicationSettings.isVirtualKeyboard
                // in conjunction with auto-hiding the inputMethod to always get
                // an input-cursor:
                activeFocusOnPress: true //ApplicationInfo.isMobile ? !ApplicationSettings.isVirtualKeyboard : true

                background: Rectangle {
                    opacity: 0
                }

                Keys.onReturnPressed: {
                    if (ApplicationInfo.isMobile && !ApplicationSettings.isVirtualKeyboard)
                        Qt.inputMethod.hide();
                    activity.focus = true;
                }

                onEditingFinished: {
                    if (ApplicationInfo.isMobile && !ApplicationSettings.isVirtualKeyboard)
                        Qt.inputMethod.hide();
                    activity.focus = true;
                }

                placeholderText: qsTr("Search specific activities")
                onTextChanged: searchTimer.restart();
            }
        }

        //timer to workaround some weird Type errors when typing too fast in the search field
        Timer {
            id: searchTimer
            interval: 500
            onTriggered: ActivityInfoTree.filterBySearch(searchTextField.text);
        }

        states: [
            State {
                name: "horizontalState"; when: activityBackground.horizontal
                PropertyChanges {
                    activityBackground {
                        sectionCellWidth: Math.min(110 * ApplicationInfo.ratio, section.width / activity.sections.length)
                    }
                    section {
                        width: ApplicationSettings.sectionVisible ? categoriesGrid.width : 0
                        height: ApplicationSettings.sectionVisible ? activityBackground.sectionCellWidth : 0
                    }
                    categoriesGrid {
                        anchors.topMargin: 0
                    }
                    activitiesGrid {
                        width: activityBackground.width - GCStyle.halfMargins
                    }
                    searchBar {
                        width: activityBackground.width * 0.6
                        anchors.topMargin: 0
                    }
                }
                AnchorChanges {
                    target: categoriesGrid
                    anchors.top: section.bottom
                }
                AnchorChanges {
                    target: activitiesGrid
                    anchors.left: activityBackground.left
                }
                AnchorChanges {
                    target: searchBar
                    anchors.top: section.bottom
                    anchors.horizontalCenter: activitiesGrid.horizontalCenter
                    anchors.left: undefined
                }
            },
            State {
                name: "verticalState"; when: !activityBackground.horizontal
                PropertyChanges {
                    activityBackground {
                        sectionCellWidth: Math.min(110 * ApplicationInfo.ratio, section.height / activity.sections.length)
                    }
                    section {
                        width: ApplicationSettings.sectionVisible ? activityBackground.sectionCellWidth : 0
                        height:  ApplicationSettings.sectionVisible ? activityBackground.height - bar.height : 0
                    }
                    categoriesGrid {
                        anchors.topMargin: GCStyle.halfMargins
                    }
                    activitiesGrid {
                        width: activityBackground.width - section.width - section.x
                    }
                    searchBar {
                        width: activitiesGrid.width - GCStyle.halfMargins
                        anchors.topMargin: GCStyle.halfMargins
                    }
                }
                AnchorChanges {
                    target: categoriesGrid
                    anchors.top: activityBackground.top
                }
                AnchorChanges {
                    target: activitiesGrid
                    anchors.left: section.right
                }
                AnchorChanges {
                    target: searchBar
                    anchors.top: activityBackground.top
                    anchors.horizontalCenter: undefined
                    anchors.left: activitiesGrid.left
                }
            }
        ]

        VirtualKeyboard {
            id: keyboard
            property bool isPopulated: false
            readonly property var letter: ActivityInfoTree.characters
            width: parent.width
            visible: activity.currentTag === "search" && ApplicationSettings.isVirtualKeyboard
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            onKeypress: (text) => {
                var textArray = searchTextField.text.split("");
                var cursorPosition = searchTextField.cursorPosition
                if(text == keyboard.backspace) {
                    --cursorPosition;
                    textArray.splice(cursorPosition, 1);
                }
                else if(text == keyboard.space) {
                    textArray.splice(cursorPosition, 0, " ");
                    ++cursorPosition;
                }
                else {
                    textArray.splice(cursorPosition, 0, text);
                    ++cursorPosition;
                }
                searchTextField.text = textArray.join("");
                searchTextField.cursorPosition = cursorPosition;
            }
            function populate() {
                var tmplayout = [];
                var row = 0;
                var offset = 0;
                var cols;
                var numberOfLetters = letter.length
                while(offset < numberOfLetters-1) {
                   if(numberOfLetters <= 100) {
                       cols = Math.ceil((numberOfLetters-offset) / (3 - row));
                   }
                   else {
                       cols = activityBackground.horizontal ? (Math.ceil((numberOfLetters-offset) / (15 - row)))
                                                       :(Math.ceil((numberOfLetters-offset) / (22 - row)))
                       if(row === 0) {
                           tmplayout[row] = [];
                           tmplayout[row].push({ label: keyboard.backspace });
                           tmplayout[row].push({ label: keyboard.space });
                           row ++;
                       }
                   }

                   tmplayout[row] = [];
                   for (var j = 0; j < cols; j++)
                       tmplayout[row][j] = { label: letter[j+offset] };
                   offset += j;
                   row ++;
               }
               if(numberOfLetters <= 100) {
                   tmplayout[0].push({ label: keyboard.space });
                   tmplayout[row-1].push({ label: keyboard.backspace });
               }
               keyboard.layout = tmplayout
           }
        }

        Bar {
            id: bar
            // BUG: on Windows, dynamic values in BarEnumContent are not working, so using intermediate properties as workaround to display serverStatus button
            property bool connectionAccepted: ApplicationInfo.serverConnectionAccepted
            property BarEnumContent defaultContent: BarEnumContent {
                value: help | config | about | (ApplicationInfo.isMobile ? 0 : exit)
            }
            property BarEnumContent contentWithServerStatus: BarEnumContent {
                value: help | config | about | (ApplicationInfo.isMobile ? 0 : exit) | serverStatus
            }
            onConnectionAcceptedChanged: {
                if(connectionAccepted) {
                    bar.content = bar.contentWithServerStatus;
                }
            }

            // No exit button on mobile, UI Guidelines prohibits it
            content: bar.defaultContent
            anchors.bottom: keyboard.visible ? keyboard.top : parent.bottom
            onAboutClicked: {
                searchTextField.focus = false
                displayDialog(dialogAbout)
            }

            onHelpClicked: {
                searchTextField.focus = false
                displayDialog(dialogHelp)
            }

            onServerStatusClicked: {
                searchTextField.focus = false
                activityBackground.showServerStatus()
            }

            onConfigClicked: {
                searchTextField.focus = false
                dialogActivityConfig.active = true
                dialogActivityConfig.loader.item.loadFromConfig()
                displayDialog(dialogActivityConfig)
            }
        }

        DialogAbout {
            id: dialogAbout
            onClose: home()
        }
        DialogHelp {
            id: dialogHelp
            onClose: home()
            activityInfo: ActivityInfoTree.rootMenu
        }

        function showServerStatus() {
            activityBackground.dialogServerStatus = Core.showMessageDialog(
                pageView.currentItem,
                activityBackground.serverStatusMessage,
                "", null,
                "", null);
        }

        DialogActivityConfig {
            id: dialogActivityConfig
            currentActivity: activity

            content: Component {
                ConfigurationItem {
                    id: configItem
                    parentActivity: activity
                    width: dialogActivityConfig.width - 50 * ApplicationInfo.ratio
                }
            }

            onSaveData: {
                dialogActivityConfig.configItem.save()
            }
            onClose: {
                if(activity.currentTag != "search") {
                    ActivityInfoTree.filterByTag(activity.currentTag, activity.currentCategory, false)
                    ActivityInfoTree.filterEnabledActivities(true)
                } else
                    ActivityInfoTree.filterBySearch(searchTextField.text);

                var filteredBackgroundMusic = dialogActivityConfig.configItem.filteredBackgroundMusic
                backgroundMusic.clearQueue()
                var allBackgroundMusic = dialogActivityConfig.configItem.allBackgroundMusic
                /**
                 * 1. If the current playing background music is in new filtered playlist too, continue playing it and append all the next filtered musics to backgroundMusic element.
                 * 2. Else, stop the current music, find the filtered music which comes just after it, and append all the further musics after it.
                 */
                var backgroundMusicSource = String(backgroundMusic.source)
                var backgroundMusicName = dialogActivityConfig.configItem.extractMusicNameFromPath(backgroundMusicSource) + backgroundMusicSource.slice(backgroundMusicSource.lastIndexOf('.'), backgroundMusicSource.length)
                var nextMusicIndex = filteredBackgroundMusic.indexOf(backgroundMusicName)
                if(nextMusicIndex !== -1) {
                    nextMusicIndex++
                    while(nextMusicIndex < filteredBackgroundMusic.length)
                        backgroundMusic.append(ApplicationInfo.getAudioFilePath("backgroundMusic/" + filteredBackgroundMusic[nextMusicIndex++]))
                }
                else {
                    nextMusicIndex = allBackgroundMusic.indexOf(backgroundMusicName) + 1
                    while(nextMusicIndex < allBackgroundMusic.length) {
                        if(filteredBackgroundMusic.indexOf(allBackgroundMusic[nextMusicIndex]) !== -1) {
                            nextMusicIndex = filteredBackgroundMusic.indexOf(allBackgroundMusic[nextMusicIndex])
                            break
                        }
                        nextMusicIndex++
                    }

                    while(nextMusicIndex < filteredBackgroundMusic.length)
                        backgroundMusic.append(ApplicationInfo.getAudioFilePath("backgroundMusic/" + filteredBackgroundMusic[nextMusicIndex++]))
                    backgroundMusic.nextAudio()
                }
                home()
            }

            BackgroundMusicList {
                id: backgroundMusicList
                onClose: {
                    visible = false
                    dialogActivityConfig.configItem.visible = true
                }
            }

            ServerConfigPage {
                id: serverConfigPage
                onClose: {
                    visible = false;
                    dialogActivityConfig.configItem.visible = true;
                }
            }

            // Elderly-friendly build: lets the user reorder the activities
            // shown in the main menu grid, opened from the "Ordenar los
            // juegos del menú" button added to ConfigurationItem.qml.
            ReorderActivitiesPage {
                id: reorderActivitiesPage
                onClose: {
                    visible = false;
                    dialogActivityConfig.configItem.visible = true;
                }
            }
        }
    }
}
