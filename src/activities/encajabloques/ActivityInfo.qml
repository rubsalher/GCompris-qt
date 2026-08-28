/* GCompris - ActivityInfo.qml
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import core 1.0

ActivityInfo {
  name: "encajabloques/EncajaBloques.qml"
  difficulty: 2
  icon: "encajabloques/encajabloques.svg"
  author: "Adaptación gente gran"
  //: Activity title
  title: qsTr("Encaja bloques")
  //: Help title
  description: qsTr("Coloca las piezas en el tablero para completar filas y columnas enteras.")
  //: Help goal
  goal: qsTr("Ejercitar la atención, la planificación y la visión espacial.")
  //: Help prerequisite
  prerequisite: qsTr("Ninguno.")
  //: Help manual
  manual: qsTr("Tienes 3 piezas abajo. Arrastra una con el dedo hasta el tablero: mientras la mueves verás en verde dónde encajaría y en rojo dónde no cabe. Suelta el dedo para colocarla ahí. Si sueltas en un sitio donde no cabe, la pieza vuelve a su hueco y puedes probar otra vez. Cuando completes una fila o una columna entera, se borra y suman puntos. La partida termina cuando ninguna de las 3 piezas cabe ya en el tablero. No hay límite de tiempo: tómate el tiempo que necesites para pensar cada jugada.")
  credit: qsTr("Actividad nueva, creada para esta adaptación, inspirada en el juego \"Block Blast\".")
  section: "fun"
  createdInVersion: 0
}
