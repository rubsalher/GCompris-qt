/* GCompris - ActivityInfo.qml
 *
 * SPDX-FileCopyrightText: 2016 Toncu Stefan <stefan.toncu29@gmail.com>
 * SPDX-FileCopyrightText: 2018 Amit Sagtani <asagtani06@gmail.com>
 * SPDX-FileCopyrightText: 2019-2024 Timothée Giet <animtim@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import core 1.0

ActivityInfo {
  name: "sketch/Sketch.qml"
  difficulty: 1
  icon: "sketch/sketch.svg"
  author: "Timothée Giet &lt;animtim@gmail.com&gt;, Amit Sagtani &lt;asagtani06@gmail.com&gt;, Stefan Toncu &lt;stefan.toncu29@gmail.com&gt;"
  //: Activity title
  title: qsTr("Sketch")
  //: Help title
  description: qsTr("Dibuja libremente con lápices de colores y una goma de borrar.")
  //: Help goal
  goal: qsTr("Ejercitar la creatividad y la coordinación de la mano.")
  prerequisite: ""
  //: Help manual
  manual: qsTr("Toca un color de arriba para elegirlo y dibuja con el dedo sobre el lienzo. Toca el icono de la goma para borrar en vez de dibujar (vuelve a tocarlo para dibujar de nuevo). El control \"Grosor\" hace el trazo más fino o más grueso, tanto para dibujar como para borrar. Las flechas deshacen y rehacen el último trazo, y el botón de recargar de la barra de abajo borra todo el dibujo para empezar de nuevo.")
  credit: qsTr("Brush smoothing concept from:") + " https://lazybrush.dulnan.net/ "
  section: "discovery arts fun"
  createdInVersion: 250000
  // WARNING: if devicePixelRatio is not integer or .5 value (like 2.75), and software renderer is used, it will lead to incremental blur on the image...
  // So better disable the activity in case software renderer is used.
  enabled: !ApplicationInfo.useSoftwareRenderer
}
