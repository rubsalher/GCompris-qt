/* GCompris - ActivityInfo.qml
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 * Replaces "melody" (a music xylophone activity, removed) — a memory
 * game inspired by the classic 1978 electronic game "Simon".
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import core 1.0

ActivityInfo {
  name: "simon/Simon.qml"
  difficulty: 2
  icon: "simon/simon.svg"
  author: "Adaptación gente gran"
  //: Activity title
  title: qsTr("Simon dice")
  //: Help title
  description: qsTr("Repite la secuencia de colores cada vez más larga.")
  //: Help goal
  goal: qsTr("Ejercitar la memoria y la atención.")
  //: Help prerequisite
  prerequisite: qsTr("Ninguno.")
  //: Help manual
  manual: qsTr("Espera a que se enciendan los colores en un orden: fíjate bien en cuáles se encienden y en qué orden. Cuando termine, toca los mismos colores en el mismo orden tocando los círculos. Si aciertas toda la secuencia, se añade un color más y se repite todo desde el principio, cada vez un poco más larga. Si te equivocas, termina la partida — toca \"Nueva partida\" para volver a intentarlo. No hay límite de tiempo para responder: tómate el tiempo que necesites.")
  credit: qsTr("Actividad nueva, creada para esta adaptación, inspirada en el juego electrónico \"Simon\" de 1978.")
  section: "fun"
  createdInVersion: 0
}
