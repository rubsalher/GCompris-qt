/* GCompris - ActivityInfo.qml
 *
 * Elderly-friendly build: new activity, not part of upstream GCompris.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import core 1.0

ActivityInfo {
  name: "fruitslice/FruitSlice.qml"
  difficulty: 1
  icon: "fruitslice/fruitslice.svg"
  author: "Adaptación gente gran"
  //: Activity title
  title: qsTr("Corta la fruta")
  //: Help title
  description: qsTr("Arrastra el dedo o el ratón sobre la fruta que va saliendo para cortarla.")
  //: Help goal
  goal: qsTr("Ejercitar el movimiento del brazo y la coordinación viso-manual, siguiendo la fruta por toda la pantalla.")
  //: Help prerequisite
  prerequisite: qsTr("Ninguno.")
  //: Help manual
  manual: qsTr("Va saliendo fruta desde abajo. Pasa el dedo o el ratón por encima para cortarla antes de que caiga. No pasa nada si se te escapa alguna, sigue intentándolo.")
  credit: qsTr("Imágenes de fruta de Openclipart (dominio público), autora \"sanja\".")
  section: "fun"
  createdInVersion: 0
}
