/* GCompris - ActivityInfo.qml
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * A giant target for a REAL small ball (handed to the player, thrown by
 * hand at the touch screen) — try to land it in the center, no time
 * limit. The IR touch frame reports wherever the real ball hits as a
 * normal tap, which is what actually gets scored.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import core 1.0

ActivityInfo {
  name: "diana/Diana.qml"
  difficulty: 1
  icon: "diana/diana.svg"
  author: "Adaptación gente gran"
  //: Activity title
  title: qsTr("Diana")
  //: Help title
  description: qsTr("Tira una pelota de verdad a la diana e intenta acertar en el centro.")
  //: Help goal
  goal: qsTr("Ejercitar la puntería y la coordinación.")
  //: Help prerequisite
  prerequisite: qsTr("Una pelota pequeña y blanda para tirar a la pantalla.")
  //: Help manual
  manual: qsTr("Tira la pelota de verdad contra la pantalla, apuntando a la diana. Cuanto más cerca del centro caiga, más puntos consigues — mira los números y los colores de cada franja. A la derecha se ven los puntos que llevas y tu récord. No hay límite de tiempo: tírala cuando quieras, tantas veces como quieras. El botón de recargar de la barra de abajo pone los puntos a cero para empezar una tanda nueva.")
  credit: qsTr("Actividad nueva, creada para esta adaptación.")
  section: "fun"
  createdInVersion: 0
}
