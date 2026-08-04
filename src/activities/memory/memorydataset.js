/* GCompris
 *
 * SPDX-FileCopyrightText: 2014 Bruno Coudoin
 *
 *   SPDX-License-Identifier: GPL-3.0-or-later
 */

var url = "qrc:/gcompris/src/activities/memory/resource/"

// Everyday objects in a consistent vintage-illustration style (11 of 12 by the
// same artist, "j4p4n" on Openclipart, all CC0/public domain) instead of the
// upstream cartoon animals/babies, as part of the elderly-friendly build.
var images = [
                [url + 'teapot.svg', url + 'teapot.svg'],
                [url + 'rose.svg', url + 'rose.svg'],
                [url + 'sunflower.svg', url + 'sunflower.svg'],
                [url + 'glasses.svg', url + 'glasses.svg'],
                [url + 'key.svg', url + 'key.svg'],
                [url + 'phone.svg', url + 'phone.svg'],
                [url + 'clock.svg', url + 'clock.svg'],
                [url + 'watch.svg', url + 'watch.svg'],
                [url + 'scissors.svg', url + 'scissors.svg'],
                [url + 'tea.svg', url + 'tea.svg'],
                [url + 'thimble.svg', url + 'thimble.svg'],
                [url + 'umbrella.svg', url + 'umbrella.svg']
            ]

// Levels start easier and ramp up more gradually than upstream (elderly-friendly
// build): an extra very-easy first level was added (2x2), and each following
// level keeps one fewer pair than before for longer, so cards stay bigger for
// longer (card size is the grid area divided by columns/rows, so fewer
// columns/rows directly means bigger cards).
var memory_cards = [
            { // Level 1
                columns: 2,
                rows: 2,
                images: images
            },
            { // Level 2
                columns: 3,
                rows: 2,
                images: images
            },
            { // Level 3
                columns: 4,
                rows: 2,
                images: images
            },
            { // Level 4
                columns: 5,
                rows: 2,
                images: images
            },
            { // Level 5
                columns: 4,
                rows: 3,
                images: images
            },
            { // Level 6
                columns: 6,
                rows: 3,
                images: images
            },
            { // Level 7
                columns: 5,
                rows: 4,
                images: images
            }
        ]

function get() {
    return memory_cards
}
