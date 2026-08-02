# Notas de adaptación GCompris para gente mayor

Rama de trabajo: `adaptacion-gent-gran` (creada sobre `master`, commit base `4fe093b`).
Repo fuente clonado en: `gcompris-qt-src/` (clon superficial `--depth 1` de
`https://invent.kde.org/education/gcompris/gcompris-qt.git`, vía mirror
`https://github.com/KDE/gcompris-qt.git` porque el clon directo a invent.kde.org
pedía autenticación en este entorno). La carpeta padre (`GCompris-Qt/`) contenía
solo la instalación binaria de Windows (`bin/`, `lib/`, `share/`, `Uninstall.exe`),
no el código fuente — por eso se clonó en una subcarpeta nueva.

## Aclaración: "renvoi" → `ballcatch`

La actividad **`renvoi`** que pedía el encargo original no existe en este
repo (206 carpetas revisadas, ninguna se llama así ni parecido). Confirmado
con el usuario: se refería a **`ballcatch`** (atrapar una pelota). La lista
de 6 actividades a mantener queda cerrada:
`memory`, `babymatch`, `clickgame`, `erase`, `ballcatch`, `hangman`.

## 1. Mecanismo de activar/desactivar actividades en el menú

Encontrado en `src/activities/CMakeLists.txt` + `src/activities/activities.txt` +
`src/core/ActivityInfoTree.cpp`:

1. **`src/activities/activities.txt`** es la lista maestra: una actividad por
   línea (nombre de carpeta), las líneas que empiezan por `#` son comentarios.
2. **`src/activities/CMakeLists.txt`** lee ese fichero al configurar el
   proyecto (`file(READ activities.txt ...)`), y por cada línea no comentada:
   - crea una opción de CMake `option(USE_<actividad> ... ON)` (activada por
     defecto),
   - si está `ON`, hace `add_subdirectory(<actividad>)` (compila esa
     actividad) y añade su nombre a un fichero generado
     **`activities_out.txt`**.
3. `activities_out.txt` se empaqueta como recurso Qt (`activities.rcc`) y es
   el fichero que **realmente lee la app en tiempo de ejecución**
   (`ActivityInfoTree::getActivityList()` en `src/core/ActivityInfoTree.cpp`,
   ruta interna `:/gcompris/src/activities/activities_out.txt`). Para cada
   línea, carga el `ActivityInfo.qml` correspondiente y lo añade al menú.

**Conclusión — forma más limpia y reversible de limitar el menú a 6
actividades:** editar `src/activities/activities.txt` y comentar con `#`
todas las líneas salvo las 6 que queremos mantener. No hace falta tocar
`CMakeLists.txt` ni las carpetas de las actividades, y es un único fichero de
una sola responsabilidad — `git diff` de una línea por actividad descartada,
fácil de revertir.

Existe además una propiedad `enabled` (bool, por defecto `true`) en cada
`ActivityInfo` (`src/core/ActivityInfo.h/.cpp`), filtrada en tiempo de
ejecución por `ActivityInfoTree::filterEnabledActivities()`. Esta vía es la
que usa GCompris para controles parentales / modo profesor (activar-desactivar
actividades individuales desde dentro de la app ya compilada), **no** es el
mecanismo que controla qué se compila ni la lista base — no la necesitamos
para la Fase 1.

## 2. Las 206 carpetas de `src/activities/`, agrupadas

**Mantener (6, lista cerrada):**

- `memory` — mantener
- `babymatch` — mantener
- `clickgame` — mantener
- `erase` — mantener (existen también `erase_2clic` y `erase_clic`, variantes
  de la misma actividad; se descartan salvo que se diga lo contrario)
- `ballcatch` — mantener (sustituye a "renvoi", ver aclaración arriba)
- `hangman` — mantener

**Descartar (todas las demás, ~200 carpetas).** No se listan una a una aquí
para no inflar este documento — la lista completa y literal es el contenido
de `src/activities/activities.txt`. En la Fase 1, ese mismo fichero quedará
como el registro exacto de qué se mantuvo y qué se comentó.

## 3. Control global de tamaño de fuente y color

- **Tamaño de fuente:** `src/core/ApplicationSettings.h` / `.cpp`, propiedad
  `baseFontSize` (rango `m_baseFontSizeMin = -7` a `m_baseFontSizeMax = 7`,
  por defecto `0`, persistida en config con la clave `BASE_FONT_SIZE_KEY`).
  El tamaño real de cualquier texto se calcula en `src/core/GCText.qml`:
  ```
  font.pointSize: ((fixFontSize ? 0 : ApplicationSettings.baseFontSize) + fontSize) * ApplicationInfo.fontRatio
  ```
  Es decir: `(baseFontSize global + fontSize propio del texto) * fontRatio`.
  Ya existe un ajuste de usuario para `baseFontSize` (pantalla de ajustes),
  pero su rango máximo (+7) puede no ser suficiente — a revisar en Fase 2.

- **Colores / tema:** `src/core/GCStyle.qml` — singleton QML
  (`pragma Singleton`) con todos los colores compartidos de la app: fondos
  (`whiteBg`, `lightBg`, `darkBg`...), texto (`whiteText`, `darkText`...),
  bordes, colores de respuesta correcta/incorrecta
  (`goodAnswerBorder` verde, `badAnswerBorder` rojo), etc. Es el punto único
  para cambiar la paleta global.

- **Barra de navegación:** `src/core/Bar.qml`. Tamaño de botón:
  `buttonSize: Math.floor(Math.min(78 * ApplicationInfo.ratio, parent.width / (numberOfButtons + 1) - buttonMargins))`,
  separación entre botones: `buttonMargins: GCStyle.halfMargins` (=
  `5 * ApplicationInfo.ratio`, definido en `GCStyle.qml`). Para agrandar
  botones y separación: subir la constante `78` y/o `GCStyle.baseMargins` /
  `halfMargins`.

## 4. Actividad `memory` (piloto Fase 3)

- `src/activities/memory/ActivityInfo.qml` — metadatos (título, ayuda,
  sección `"fun memory"`, dificultad `1`).
- `src/activities/memory/Memory.qml` — **no contiene la lógica**, solo
  conecta `MemoryCommon.qml` con el dataset de imágenes
  (`memorydataset.js`) y el fondo. La lógica real (tamaño de cartas, nº de
  pares por nivel, animación de volteo) está en
  `src/activities/memory/MemoryCommon.qml` — pendiente de revisar en detalle
  en la Fase 3, todavía no examinado a fondo en esta Fase 0.
- Imágenes: pendiente de contar/documentar formato en Fase 3 (no se ha
  entrado aún en `src/activities/memory/resource/`).

## 5. Feedback de audio (para revisar más adelante, no tocar aún)

Pendiente de comprobar en Fase 2 si el sonido de confirmación al pulsar/
completar es suficientemente claro/alto. No investigado todavía en esta
Fase 0.

---

## Fase 1 — Filtrado del menú a 6 actividades (hecho)

- Editado `src/activities/activities.txt`: comentadas con `#` todas las
  líneas salvo `memory`, `babymatch`, `clickgame`, `erase`, `ballcatch`,
  `hangman`. No se ha tocado `CMakeLists.txt` ni ninguna carpeta de
  actividad — el cambio es de una sola línea por actividad descartada y
  100% reversible (`git diff`/`git revert` de un único fichero).
- **No se ha podido compilar ni verificar visualmente el menú en este
  entorno.** Esta máquina no tiene instalado ninguna de las herramientas
  necesarias para compilar GCompris (comprobado explícitamente, no hay
  rastro de ellas en el sistema):
  - `cmake` — no encontrado
  - Qt 6.x SDK (`qmake`/`/c/Qt/...`) — no encontrado (solo hay DLLs sueltas
    de Qt5 redistribuidas con otras apps, irrelevantes)
  - Compilador (MSVC `cl` o MinGW `g++`) — no encontrado
  - Ninja — no comprobado, pero no hay Qt SDK del que colgaría

  Instalar el SDK de Qt 6.5.3 + MinGW + Ninja requiere el instalador gráfico
  de Qt (con cuenta Qt) y varios GB de descarga — no es algo que se pueda
  hacer de forma desatendida desde aquí, así que no lo he intentado.

### Cómo verificarlo tú (Windows, según `HACKING`)

```
cd gcompris-qt-src
mkdir build
cd build
cmake -G "Ninja" -DCMAKE_PREFIX_PATH=/c/Qt/6.5.3/mingw_64/ -DOPENSSL_ROOT_DIR=/c/Qt/Tools/OpenSSLv3/Win_x64/ ..
cmake --build . -j 4 --config Release --target BuildTranslations
cmake --build . -j 4 --config Release
```

(Necesitas antes: Qt Maintenance Tool → instalar Qt 6.5.3 con MinGW, y las
Developer Tools "Ninja" y "OpenSSL"; añadir `mingw1120_64/bin` y `Ninja` al
PATH, ver `HACKING` líneas 103-111.)

Después de compilar, el ejecutable estará en `build/bin/` — al abrirlo, el
menú principal debería mostrar únicamente las 6 actividades.

Si prefieres no instalar el SDK completo, la forma más rápida de verificar
el cambio sin compilar es leer `src/activities/activities.txt` directamente:
solo 6 líneas quedan sin comentar.

---

## Fase 2 — Accesibilidad global (hecho, sin compilar — mismo motivo que Fase 1)

**1. Tamaño de fuente** (`src/core/ApplicationSettings.cpp`):
- `m_baseFontSizeMax`: `7` → `12` (más margen para escalar el texto desde
  los ajustes de la app).
- Valor por defecto de `baseFontSize` (primer arranque, sin config previa):
  `0` → `6` (a mitad del nuevo rango máximo). Como
  `font.pointSize = (baseFontSize + fontSize_del_texto) * fontRatio`
  (`src/core/GCText.qml`), esto agranda **todo** el texto de la app de forma
  proporcional desde el primer arranque, sin tocar cada actividad una por
  una. El usuario sigue pudiendo subir más desde los ajustes (hasta el nuevo
  máximo 12) o bajarlo si se pasa.
- No he podido medir en pantalta real a cuántos "pt reales" equivale, porque
  `fontRatio` depende de la resolución/DPI de la pantalla en tiempo de
  ejecución (`ApplicationInfo.cpp`) y no he podido compilar ni ejecutar la
  app en este entorno (ver Fase 1). Recomiendo, al probarlo en una máquina
  con Qt instalado, comprobar visualmente si `baseFontSize: 6` es suficiente
  o si conviene subirlo más (hay margen hasta 12).

**2. Botones y separación** (`src/core/GCStyle.qml`, `src/core/Bar.qml`):
- `GCStyle.baseMargins`: `10` → `14`, `halfMargins`: `5` → `8` (más aire
  entre elementos en toda la app, ya que `Bar.buttonMargins` y muchos
  paneles usan estos valores).
- `GCStyle.smallButtonHeight`: `35` → `44`, `bigButtonHeight`: `70` → `88`
  (botones tipo "OK" y de configuración, más grandes).
- `Bar.buttonSize`: máximo de `78` → `104` px base (antes de aplicar el
  ratio de pantalla) — los botones de inicio/ayuda/ajustes de la barra
  inferior son ahora ~33% más grandes, con más separación entre ellos.

**3. Paleta de colores** (`src/core/GCStyle.qml`, singleton compartido por
toda la app):
- Fondos: `lightBg` (`#f2f2f2`→`#EDEAE3`) y `lighterBg`
  (`#f8f8f8`→`#F2EFE9`) pasan de gris frío casi blanco a un neutro cálido,
  para evitar el deslumbramiento del blanco puro. `whiteBg` (`#ffffff`) se
  ha dejado igual porque muchos botones/iconos dependen de un blanco
  literal como base.
- Acento principal: `highlightColor` (`#3ac5f7`, cian pastel tipo
  Tux/infantil) → `#1F5C86` (azul sobrio y sólido). `focusColor` y
  `selectedDarkBlue` recolocados en la misma familia de azules
  (`#5B9BC4` / `#154A6E`) para no introducir un segundo acento que choque.
  `sliderFill`/`sliderPressed` alineados al mismo azul.
- `lightBlueBg` (`#abcdef`, pastel) → `#B8CDE0` (azul grisáceo, menos
  saturado).
- Contraste texto/fondo: `darkText` (`#373737`) sobre los nuevos fondos
  claros da ~8:1, por encima del mínimo 4.5:1 pedido — no ha hecho falta
  tocarlo.
- Respuesta correcta/incorrecta: `goodAnswer` (antes `#0099ff` azul) se deja
  en azul sólido `#0072B2`; `badAnswer` (antes `#ff6666` rojo pastel) →
  `#C62828` (rojo sólido, **no** naranja — evité a propósito emparejarlo con
  el nuevo azul de acento para no crear una combinación azul-naranja).
  `goodAnswerBorder`/`badAnswerBorder` (verde/rojo, usados para marcar
  acierto/error en el borde de las tarjetas) se han oscurecido y saturado
  (`#2E7D32` / `#C62828`) para mejorar el contraste, **pero siguen siendo un
  par verde/rojo** — el encargo pedía evitar justo esa combinación. No lo he
  eliminado del todo porque verde=correcto/rojo=incorrecto es una
  convención usada en todas las actividades y quitarla de verdad requiere
  añadir una señal no cromática (icono/forma), no solo cambiar el color; lo
  dejo anotado aquí como pendiente para una fase futura si se quiere resolver
  a fondo.

**4. Feedback de audio** — comprobado, no tocado (según lo pedido):
- Existe un control de volumen global para efectos de sonido:
  `ApplicationSettings.audioEffectsVolume`, por defecto `0.7` (70%),
  ajustable ya desde los ajustes de la app. No hay un único "sonido de
  clic" centralizado en `Bar.qml` — cada actividad reproduce sus propios
  efectos (vía `GCSoundEffect.qml`) a ese volumen. Para saber si 70% es
  suficientemente claro/alto hace falta probarlo de oído en la app
  compilada — no evaluable solo leyendo código. Pendiente para cuando se
  pueda ejecutar la app.

### Nota sobre verificación

Igual que en la Fase 1, estos cambios **no se han podido compilar ni ver en
pantalla** en este entorno (faltan CMake/Qt6/compilador, ver Fase 1). Son
cambios de valores/colores en 3 ficheros concretos
(`ApplicationSettings.cpp`, `GCStyle.qml`, `Bar.qml`), de bajo riesgo de
romper la compilación, pero **deben verificarse visualmente** en cuanto se
pueda compilar en una máquina con el SDK de Qt instalado.

---

## Fase 3 — Actividad `memory` (piloto, hecho — sin compilar, mismo motivo)

**Dónde está cada cosa** (`src/activities/memory/`):
- **Tamaño de las cartas**: no es un valor fijo en píxeles — se calcula en
  `MemoryCommon.qml` (`cardImageWidth`/`cardImageHeight`) a partir del
  tamaño de celda de un `GridView` (`cellWidth = width/columns`,
  `cellHeight = height/rows`). Es decir: **el tamaño de carta depende
  directamente del número de columnas/filas del nivel**, no hay un número
  mágico que agrandar aparte.
- **Número de pares por nivel**: en `memorydataset.js`, array
  `memory_cards`, cada nivel define `columns`/`rows` (nº de pares =
  `columns * rows / 2`). Los valores originales eran 3, 4, 5, 6, 9 y 10
  pares (6 niveles).
- **Velocidad de animación de volteo**: en `CardItem.qml` — rotación de
  volteo `NumberAnimation { duration: 750 }` (línea 134) y aparición de
  carta `Behavior on opacity { NumberAnimation { duration: 1000 } }` (línea
  164). Localizado pero **no modificado** en esta fase (el encargo pedía
  solo localizarlo, no cambiarlo).
- **Imágenes** (`src/activities/memory/resource/`): 26 ficheros `.svg` en
  total + 1 `.wav` (sonido de volteo). De los 26 SVG, 21 son las imágenes
  numeradas de animales (`01_cat.svg` a `21_frog.svg`) que forman las
  parejas — cada una se referencia dos veces en el array `images` de
  `memorydataset.js` para crear su propia pareja (no hay dos dibujos
  distintos por pareja, es el mismo fichero repetido). Los otros 5 SVG son
  piezas de interfaz: `backcard.svg` (dorso), `emptycard.svg`,
  `background.svg`, `child.svg`/`tux.svg` (marcadores de puntuación). No se
  han tocado ni sustituido en esta fase.

**Cambio aplicado** (`memorydataset.js`, array `memory_cards`): como el
tamaño de carta depende del grid, la única forma real de "agrandar las
cartas" sin tocar la fórmula de layout es reducir columnas/filas en los
primeros niveles. He:
- Añadido un nivel 1 nuevo, muy fácil, de `2x2` (2 pares) — antes el
  primer nivel ya empezaba en 3 pares.
- Desplazado el resto de niveles un paso hacia abajo en dificultad: los
  niveles que antes eran 3, 4, 5, 6, 9, 10 pares pasan a ser el nivel 2 a 7
  de la nueva lista (7 niveles en total en vez de 6), manteniendo el último
  nivel (10 pares) igual que antes para quien quiera más reto.
- No he tocado `CardItem.qml` (animaciones) ni la fórmula de
  `cardImageWidth`/`cardImageHeight` en `MemoryCommon.qml` — con menos
  columnas/filas, esa fórmula ya calcula cartas más grandes automáticamente.

### Nota sobre verificación

No se ha podido compilar ni jugar la actividad en este entorno (mismo motivo
que en Fases 1 y 2 — faltan CMake/Qt6/compilador). El cambio es de datos
(nº de columnas/filas por nivel) en un único array de un fichero JS, de
bajo riesgo, pero **debe jugarse una partida real** en cuanto se pueda
compilar para confirmar que las cartas se ven cómodas y que los 7 niveles
cargan bien (comprobado en el código: ningún nivel pide más parejas de las
21 imágenes disponibles en `images` — el nivel más exigente pide 10 pares).
