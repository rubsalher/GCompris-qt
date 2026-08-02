/* GCompris - GCStyle.qml
 *
 * SPDX-FileCopyrightText: 2025 Timothée Giet <animtim@gmail.com>
 *
 * Authors:
 *   Timothée Giet <animtim@gmail.com>
 *
 *   SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma Singleton
import QtQuick
import core 1.0

/**
 * A QML singleton to store all shared style-related values (common colors, borders and margins)
 */

QtObject {
    // margins (used also for rectangle corner's radius)
    // enlarged for better touch-target separation on large screens (elderly-friendly build)
    readonly property int baseMargins: 14 * ApplicationInfo.ratio
    readonly property int halfMargins: 8 * ApplicationInfo.ratio
    readonly property int tinyMargins: Math.max(1, 2 * ApplicationInfo.ratio)

    // border sizes
    readonly property int fatBorder: Math.max(5, 8 * ApplicationInfo.ratio)
    readonly property int thickerBorder: Math.max(3, 5 * ApplicationInfo.ratio)
    readonly property int thickBorder: Math.max(2, 4 * ApplicationInfo.ratio)
    readonly property int midBorder: Math.max(2, 3 * ApplicationInfo.ratio)
    readonly property int thinBorder: Math.max(1, 2 * ApplicationInfo.ratio)
    readonly property int thinnestBorder: Math.max(1, ApplicationInfo.ratio)

    // small button's height in menu config page
    readonly property int smallButtonHeight: 44 * ApplicationInfo.ratio
    // big button's size, like for OK button
    readonly property int bigButtonHeight: 88 * ApplicationInfo.ratio

    // border colors
    readonly property color whiteBorder: "#ffffff"
    readonly property color lightBorder: "#f2f2f2"
    readonly property color darkBorder: "#373737"
    readonly property color darkerBorder: "#191919"
    readonly property color noBorder: "#00ffffff"
    readonly property color blueBorder: "#87A6DD"
    readonly property color grayBorder: "#808080"
    readonly property color lightGrayBorder: "#c0c0c0"

    readonly property color answerBorder: "#1F5C86" // blue
    // NOTE: correct/incorrect feedback still relies on a green/red pair, which
    // classic color-theory advice for elderly/color-vision-deficient users
    // recommends avoiding; darkened+saturated here for max contrast, but a
    // real fix needs a non-color cue too (icon/shape) — not done in this pass
    readonly property color goodAnswerBorder: "#2E7D32" // green
    readonly property color badAnswerBorder: "#C62828" // red

    // colors for text and its background
    readonly property color whiteText: "#ffffff"
    readonly property color lightText: "#f2f2f2"
    readonly property color darkText: "#373737"
    readonly property color darkerText: "#191919"

    // less light color used in Sketch and Drawing_wheels components
    readonly property color contentColor: "#d2d2d2"

    readonly property color paperWhite: "#E8E8E8"
    // sober, non-glaring neutral backgrounds (elderly-friendly build: avoid pure white)
    readonly property color lightBg: "#EDEAE3"
    readonly property color lighterBg: "#F2EFE9"
    readonly property color lightTransparentBg: "#AAEDEAE3"
    readonly property color whiteBg: "#ffffff"
    readonly property color whiteBlueBg: "#f6fbfc"
    readonly property color whiteBlueTransparentBg: "#80f6fbfc"
    readonly property color darkBg: "#373737"
    readonly property color darkTransparentBg: "#13373737"
    readonly property color midGrayBg: "#808080"

    // sober, solid, high-contrast accent (was a pastel cyan) — keep the same
    // hue family for focusColor/selectedDarkBlue to avoid clashing accents
    readonly property color highlightColor: "#1F5C86"
    readonly property color focusColor: "#5B9BC4"
    readonly property color selectedDarkBlue: "#154A6E"

    // color from gcompris logo used in some activities
    readonly property color gcOrange: "#e77936"

    // special button Bg colors
    readonly property color buttonColor: "#ffffff"
    readonly property color goodAnswer: "#0072B2"
    readonly property color badAnswer: "#C62828"
    // special sliders colors
    readonly property color sliderHandle: "#ffffff"
    readonly property color sliderPressed: "#1F5C86"
    readonly property color sliderFill: "#1F5C86"
    readonly property color sliderEmpty: "#585858"
    readonly property color sliderBorder: "#808080"

    // color for config panels
    readonly property color configBg: "#696da3"
    // color for GCCreationHandler Bg and some activities (was a pastel light blue)
    readonly property color lightBlueBg: "#B8CDE0"

    // grayed background behind pop-up dialogs
    readonly property color grayedBg: "#C080a0c0"
}
