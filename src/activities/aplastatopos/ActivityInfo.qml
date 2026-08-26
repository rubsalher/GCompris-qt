/* GCompris - ActivityInfo.qml
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import core 1.0

ActivityInfo {
  name: "aplastatopos/AplastaTopos.qml"
  difficulty: 1
  icon: "aplastatopos/aplastatopos.svg"
  author: "Adaptación gente gran"
  //: Activity title
  title: qsTr("Aplasta topos")
  //: Help title
  description: qsTr("Toca los topos que van saliendo de los agujeros antes de que se escondan.")
  //: Help goal
  goal: qsTr("Ejercitar los reflejos, la atención y el movimiento del brazo por toda la pantalla.")
  //: Help prerequisite
  prerequisite: qsTr("Ninguno.")
  //: Help manual
  manual: qsTr("Pulsa \"Iniciar\" para empezar. Van saliendo topos al azar en los agujeros: tócalos antes de que se escondan para sumar puntos. El topo normal vale 1 punto y el topo dorado vale 2. Tienes 60 segundos, y la partida se va poniendo un poco más rápida según avanza. Intenta superar tu récord.")
  credit: qsTr("Actividad nueva, creada para esta adaptación.")
  section: "fun"
  createdInVersion: 0
}
