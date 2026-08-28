/* GCompris - ActivityInfo.qml
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import core 1.0

ActivityInfo {
  name: "atrapamanzanas/AtrapaManzanas.qml"
  difficulty: 1
  icon: "atrapamanzanas/atrapamanzanas.svg"
  author: "Adaptación gente gran"
  //: Activity title
  title: qsTr("Lluvia de comida")
  //: Help title
  description: qsTr("Mueve la cesta para atrapar la comida que cae del cielo.")
  //: Help goal
  goal: qsTr("Ejercitar los reflejos, la atención y el movimiento del brazo por toda la pantalla.")
  //: Help prerequisite
  prerequisite: qsTr("Ninguno.")
  //: Help manual
  manual: qsTr("Pulsa \"Iniciar\" para empezar. Del cielo va cayendo comida: toca la pantalla donde quieras y la cesta se moverá hasta ahí para atraparla antes de que llegue al suelo (si se te escapa, desaparece sin más, no pasa nada). Tienes 60 segundos, y la partida se va poniendo un poco más rápida según avanza. Hay 3 niveles de velocidad, cada vez más rápido: cámbialos con las flechas de la barra de abajo. Intenta superar tu récord.")
  credit: qsTr("Actividad nueva, creada para esta adaptación.")
  section: "fun"
  createdInVersion: 0
}
