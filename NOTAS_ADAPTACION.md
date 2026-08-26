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

---

## Fase 4 — Las otras 5 actividades, mismo patrón que `memory` (hecho)

El usuario ha dado permiso para completar todo el encargo sin pedir
confirmación en cada paso, así que he adelantado la Fase 4 (marcada como
"fuera de alcance por ahora" en el encargo original). Por actividad:

**`babymatch`** (`src/activities/babymatch/`) — **no ha hecho falta tocar
nada**: el tamaño de las piezas arrastrables usa
`view.iconSize: GCStyle.bigButtonHeight` (`ListWidget.qml` línea 78), que ya
se agrandó en la Fase 2 (70→88 * ratio). La dificultad por nivel viene de
ficheros de datos externos por nivel (`boardN_M.qml`, fuera de
`src/activities/babymatch/*.js`), no de una fórmula editable en un único
sitio como en `memory` — cambiar la dificultad ahí implicaría editar
decenas de ficheros de contenido uno a uno, lo dejo anotado como límite de
esta pasada, no hecho.

**`clickgame`** (`clickgame.js`): los peces ahora son un 36% más grandes
como objetivo de clic (multiplicador `1.1`→`1.5` sobre su tamaño base, en
`createFish()`) y se mueven más despacio y en menor número en los primeros
niveles (`levelProperty`): nivel 1 pasa de 5 peces/2000ms a 4 peces/3200ms
de duración mínima de cruce de pantalla; la progresión completa queda
4,5,7,9,12,15 peces con 3200,2800,2200,1600,1100,700ms (antes 5,7,10,12,15,18
con 2000,1500,1000,800,600,400ms).

**`erase`** (`erase.js`): la rejilla de cuadros a borrar pasa de 5x5 u 8x8
(según el nivel sea par/impar) a 3x3 o 5x5 — bloques mucho más grandes y
menos numerosos, más fáciles de "pintar" con el dedo/ratón. Fórmula
cambiada en `initLevel()`: `(currentLevel % 2 * 3) + 5` → `(currentLevel % 2
* 2) + 3`.

**`ballcatch`** (`ballcatch.js`): es un minijuego de reflejos (pulsar
izquierda+derecha del teclado dentro de una ventana de tiempo), no de
"atrapar visualmente una pelota" como sugería el nombre "renvoi" — aviso
por si esto no encaja con lo que se esperaba para el perfil de usuario. Se
ha alargado la ventana de reacción en todos los niveles, sobre todo los
primeros: nivel 1 pasa de 900ms a 1800ms (el doble), última nivel de 100ms a
200ms. Progresión completa: 1800,1500,1300,1100,900,700,500,350,200ms
(antes 900,800,700,600,500,400,300,200,100ms).

**`hangman`** (`src/core/VirtualKeyboard.qml`, componente compartido usado
por el teclado en pantalla de `hangman`): altura de cada tecla `45 * ratio`
→ `58 * ratio` (~29% más grande). Los iconos de vidas restantes (flor) y el
botón OK ya usan `GCStyle.bigButtonHeight`, agrandado en la Fase 2. No se ha
tocado el número de vidas (6, generoso de por sí) ni la lógica del juego.

### Nota sobre verificación

Como en las fases anteriores, **no se ha podido compilar ni jugar** ninguna
de estas 5 actividades en este entorno (faltan CMake/Qt6/compilador — ver
Fase 1). Son todo cambios de valores numéricos en ficheros JS/QML
concretos, de bajo riesgo de romper la compilación, pero el equilibrio de
dificultad (sobre todo en `clickgame` y `ballcatch`, que son juegos de
tiempo/reflejos) **debe jugarse y ajustarse a ojo** en cuanto se pueda
compilar — los números elegidos son una estimación razonable, no una
medición con usuarios reales.

---

---

## Fase 5 — Primera compilación real y verificación en pantalla (hecho)

Se consiguió instalar el SDK de Qt 6.11.1 + MinGW 13.1.0 + CMake + Ninja +
OpenSSL (guiado paso a paso por el chat) y **compilar y ejecutar la app de
verdad por primera vez**. Notas del proceso, por si hay que repetirlo:

- `OPENSSL_ROOT_DIR`/`OPENSSL_INCLUDE_DIR` deben apuntar a una ruta **sin
  espacios** (`C:\Program Files\OpenSSL-Win64` falla al compilar el `.rc` de
  Windows) — se copiaron `libcrypto.lib`/`libssl.lib`/`include/` a
  `C:\Users\Utente\openssl-mingw\`.
- Con MinGW hace falta además marcar los módulos Qt Multimedia, Graphs y
  Sensors por separado en el instalador (no vienen con el paquete base).
- Se compiló con `-DBUILD_SERVER=OFF -DSKIP_TRANSLATIONS=ON` (el servidor de
  profesores no hace falta; sin `gettext` instalado en Windows no se pueden
  generar las traducciones, así que la build actual solo tiene inglés).
- **Importante para futuras compilaciones**: cuando se añaden ficheros nuevos
  a la carpeta `resource/` de una actividad (o se activa una actividad
  nueva), a veces `cmake --build` no regenera el `.rcc` aunque el `.qrc`
  se haya reescrito (una re-configuración automática de CMake a mitad de
  build dejaba el `.qrc` más nuevo que el `.rcc` ya compilado, y Ninja no se
  enteraba). Si after compilar algo no aparece en la app aunque el código
  esté bien, borrar a mano el `.rcc` correspondiente en
  `build/share/GCompris/rcc/` y volver a compilar suele arreglarlo.

**Cambios de contenido visual, ya vistos en pantalla y confirmados por el
usuario que funcionan:**

- `memory`: las 12 imágenes de Openclipart sustituyeron a los animales/bebés
  (ver selección acordada más arriba). Reverso de carta (`backcard.svg`) y
  carta vacía (`emptycard.svg`) recoloreados al azul sobrio. Fondo de la
  actividad (`background.svg`, antes una escena con Tux jugando a la pelota
  entre pirámides y árboles) sustituido por un fondo liso en los tonos
  cálidos del resto de la app. Avatares del marcador (`child.svg` un niño de
  dibujos, `tux.svg` el pingüino) sustituidos por una insignia circular
  simple (azul jugador 1, verde jugador 2).
- **Menú principal**: por defecto ya no se navega por pestañas de categoría
  (favoritos/ordenador/descubrimiento/ciencias/diversión/mates/puzles/
  lectura/estrategia/buscar) — se ve una única pantalla plana con las 7
  actividades. Cambio técnico: `ApplicationSettings::m_sectionVisible`
  (`src/core/ApplicationSettings.cpp`) por defecto `false` en vez de `true`,
  `Menu.qml`'s `currentTag` fijo a `"all"` en vez de derivarlo de la primera
  sección, y `ActivityInfoTree::initialize()`
  (`src/core/ActivityInfoTree.cpp`) filtra por `"all"` al arrancar en vez de
  por `"favorite"` (que mostraba una lista vacía, no había favoritos
  guardados). La barra de secciones sigue existiendo en el código (Ctrl+B/S
  la reactivan) por si se quiere volver atrás, solo se cambió el valor por
  defecto.
- **Fondo del menú principal**: sustituido el paisaje de colinas verdes con
  sol y nubes de dibujos animados por una ilustración de paisaje original
  (montañas/colinas en capas, cielo en gradiente) en los mismos tonos
  sobrios del resto de la app — el usuario pidió algo "tipo" una imagen de
  stock con derechos de autor que compartió; no se usó esa imagen exacta
  (es de pago/con copyright), se hizo una propia con el mismo espíritu.
- **Torre de Hanoi añadida**: se descomentó `hanoi_real` en `activities.txt`
  (la versión "The Tower of Hanoi" clásica, no la "Simplified Tower of
  Hanoi" con menos discos — existe esa alternativa si se prefiere más
  fácil). Van 7 actividades activas: `memory`, `babymatch`, `clickgame`,
  `erase`, `hangman`, `ballcatch`, `hanoi_real`.

### Pendiente de esta fase

El usuario ha pedido revisar **cada actividad** una por una (fondo, HUD,
imágenes) igual que se hizo con `memory`. Segunda pasada hecha:

- **`hanoi_real`**: fondo (antes una escena de montañas con colores de
  dibujos animados muy saturados) sustituido por un degradado sobrio.
- **`hangman`**: mismo cambio de fondo.
- **`ballcatch`**: los 4 fondos de playa (`beach1-4.svg`) sustituidos por
  degradados sobrios; el Tux central (visible todo el rato durante la
  partida, no solo al ganar) sustituido por la misma insignia sobria que
  usamos en `memory`. `hand.svg` (las manos que animan el juego) no se ha
  tocado — ya usa tonos piel/gris neutros, no hacía falta.
- **`erase`, `clickgame`**: revisados y **no tocados** — ya usan fotografías
  reales (animales/peces), no dibujos infantiles, así que encajan con el
  criterio sin cambios.
- **`babymatch`**: revisado — sus ~40 iconos (`resource/images/`) son en su
  mayoría objetos cotidianos neutros (manzana, bici, casa, coche...), no
  específicamente infantiles pese al nombre de la actividad. Solo 2 iconos
  (`tuxhelico.svg`, `tuxplane.svg`, usados en un único tablero de 7) tienen a
  Tux — peso visual bajo, no se ha tocado por ahora. No tiene fondo propio
  (`resource/background.svg` no existe, usa fondos por tablero).

---

## Pendiente real (no abordado, requiere decisión o no es viable desde aquí)

- **Sustitución de imágenes infantiles por otras neutras/adultas**: sigue
  pendiente de decidir el origen de esas imágenes (banco de imágenes,
  ilustraciones propias, etc.) — no se ha hecho, tal como pedía el encargo
  original.
- **Pruebas de usuario con personas mayores reales**: no es algo que se
  pueda hacer desde aquí.
- **Compilar y verificar visualmente todos los cambios de las Fases 1-4**:
  bloqueado en este entorno concreto por falta de CMake/Qt6/compilador (ver
  Fase 1) — hace falta una máquina con el SDK de Qt instalado.

---

## Fase 6 — Ajustes de menú y arreglos de compilación tras probar en pantalla (hecho)

Con la app ya compilándose y ejecutándose de verdad, fueron saliendo varios
fallos solo visibles al jugar (no se detectan leyendo código). Quedan
anotados aquí para no repetir la investigación si hace falta recompilar
desde cero en otra máquina:

**Menú principal:**
- Barra de categorías (con iconos de animales: gato, pingüino, cerdo...)
  ocultada de forma **permanente** (no solo por defecto) — `Menu.qml`,
  el `GridView` `section` tiene `visible: false` fijo en vez de depender de
  `ApplicationSettings.sectionVisible`, así ni el atajo Ctrl+S ni una
  configuración guardada de una sesión anterior la puede volver a mostrar.
- La rejilla de actividades (`activitiesGrid`) ahora arranca siempre en
  `clockBar.bottom` en vez de depender de si la barra de secciones estaba
  visible — si no, quedaba un hueco vacío arriba.
- Añadido un **reloj y fecha** grandes arriba del todo (`clockBar` en
  `Menu.qml`), con la idea de dar orientación temporal — usa
  `Qt.formatDateTime` con el locale del sistema, se actualiza cada segundo
  con un `Timer`.
- Actividades quitadas del menú a petición del usuario tras probarlas:
  `babymatch`, `ballcatch`, `clickgame`, `erase` (se habían añadido en la
  Fase de "añadir todo el catálogo" pero al verlas jugando no encajaban).
  Se añadieron también ~27 actividades más del catálogo completo de GCompris
  (ajedrez, damas, sudoku, tangram, piano, dibujo...) sin tocar su contenido,
  identificadas cruzando capturas de pantalla del usuario con el fichero de
  traducción `poqm/es/gcompris_qt.po` para acertar el nombre interno exacto
  de cada una.

**Bugs de compilación encontrados jugando (no visibles leyendo código):**

1. **Audio silencioso / no cargaba en absoluto** (`instruments` y otras
   actividades con sonido): en Windows, `CMakeLists.txt` raíz fija
   `COMPRESSED_AUDIO` a `mp3` por defecto, pero el repositorio solo trae los
   sonidos en `.ogg` (los `.mp3` se generan/descargan aparte, paso que no
   hacemos). Arreglado pasando `-DCOMPRESSED_AUDIO=ogg` al configurar con
   `cmake` — con Qt6 en Windows el `.ogg` se reproduce bien.

2. **`instruments` y `paintings` no abrían al pulsarlas** (sin ningún error
   en el log): reutilizan internamente componentes QML de otras actividades
   — `instruments` de `colors`, `paintings` (vía `babymatch`) de
   `babymatch` — que no estaban activadas en `activities.txt`, así que esos
   componentes no llegaban a compilarse ni registrarse como recurso.
   Arreglado añadiendo esas actividades "donantes" a `activities.txt` pero
   con `enabled: false` en su propio `ActivityInfo.qml`, para que se
   compilen (satisfaciendo la dependencia) sin aparecer como icono propio en
   el menú. Se hizo un barrido completo de todas las referencias
   `activities/<nombre>/` en el código de las actividades activas para
   encontrar todos los casos de una vez:
   - `babymatch` → necesita `guesscount` (fondo) y `colors` es necesitado
     por `instruments`, no por `babymatch`
   - `balancebox` → necesita `maze` (fondo)
   - `frieze` → necesita `crane` (fondo)
   - `memory` → necesita `bargame` (fondo de las insignias de puntuación)
   Todas estas "actividades donantes" están en `activities.txt` sin comentar
   pero con `enabled: false`, mismo patrón para las cuatro.

3. **`paintings` se abría pero con el fondo en negro y las piezas
   invisibles**: el Qt 6.11.1 instalado no traía el plugin de `.webp`
   (`qwebp.dll` no estaba en `Qt/6.11.1/mingw_64/plugins/imageformats/`),
   y casi todas las imágenes de `paintings` son `.webp`. Es un módulo aparte
   del instalador de Qt ("Qt Image Formats", en Additional Libraries, mismo
   sitio que Multimedia/Graphs/Sensors) — instalarlo lo arregló sin tocar
   ninguna imagen.

**Nota para recompilar desde cero en otra máquina**: además de los pasos ya
documentados en la Fase 1 (Qt 6.11.x MinGW, CMake, Ninja, OpenSSL-Win64
copiado a una ruta sin espacios), hace falta instalar estos módulos extra
de Qt vía Qt Maintenance Tool → Additional Libraries: **Multimedia**,
**Graphs**, **Sensors**, **Image Formats**. Y al configurar con `cmake`,
añadir `-DCOMPRESSED_AUDIO=ogg` a los flags ya usados.

### Pendiente detectado pero no arreglado

Al buscar todas las referencias cruzadas entre actividades, `simplepaint` y
`sketch` referencian **muchísimas** otras actividades no activas (parece
una galería opcional de fondos para dibujar, no una dependencia dura como
las de arriba) — no se ha investigado a fondo ni tocado, de momento no han
dado ningún fallo visible al jugar. Si `simplepaint` o `sketch` fallan al
elegir cierto fondo, es la primera sospecha a revisar.

---

## Fase 7 — Traducción al español, quitar hangman, y actividad nueva "Corta la fruta" (hecho)

**Traducción a español**: funcionaba en inglés a pesar de tener `-DSKIP_TRANSLATIONS=OFF`
porque `SKIP_TRANSLATIONS` es una variable CACHE de CMake — quitar el flag `-D`
de la línea de comandos **no la resetea**, se queda en el último valor que se
le puso (`ON`) hasta que se pasa explícitamente `-DSKIP_TRANSLATIONS=OFF`.
Además hacía falta instalar `gettext` para Windows (no viene con Qt ni con
MinGW) — se usó el paquete portable de
[mlocati/gettext-iconv-windows](https://github.com/mlocati/gettext-iconv-windows),
descomprimido en `C:\Users\Utente\gettext-tools\`, con su `bin\` añadido al
PATH al compilar. El reloj/fecha del menú también tenía el mismo problema:
`Qt.formatDateTime` usa el locale del sistema operativo, no el idioma
elegido dentro de la app — se cambió a `Qt.locale(ApplicationSettings.locale).toString(...)`
en `Menu.qml` para que synchronice con el idioma de la app.

**`hangman` quitado**: dependía en duro de la actividad `lang` (todo su
diccionario de palabras) y de `reversecount` (imágenes de bonus) — se
intentó mantenerlas compiladas-pero-ocultas (mismo patrón que
`paintings`/`babymatch` etc., ver Fase 6), y aunque llegó a abrir, el
usuario decidió quitar `hangman` del todo. `lang` y `reversecount` se
volvieron a comentar en `activities.txt` porque ya no las necesita nadie.

**Actividad nueva "Corta la fruta" (`fruitslice`)**: no es una actividad de
GCompris, la hemos creado desde cero para que la gente mayor mueva más el
brazo (pensado para el marco IR + proyector grande) — va saliendo fruta en
arco (a veces también por los lados) y hay que pasar el dedo/ratón por
encima para "cortarla". Ficheros en
`src/activities/fruitslice/` (`ActivityInfo.qml`, `FruitSlice.qml`,
`Fruit.qml`, `fruitslice.js`, `CMakeLists.txt`, `resource/`).

Cosas aprendidas al construirla, útiles para la próxima actividad nueva que
se quiera añadir:

- **Imágenes de fruta**: sacadas de la colección "Frutas-collection" de la
  autora `sanja` en Openclipart (misma fuente/criterio que `memory`, CC0).
  **Cuidado al elegir una imagen solo por el nombre**: la primera "naranja"
  que se cogió (`orange-apelsinas`, id 168553) resultó ser un dibujo de una
  naranja **ya cortada en gajos**, no una naranja entera — se notó porque
  en el juego "salía ya cortada". Se detectó mirando los colores del SVG:
  un patrón con **cientos de fragmentos repetidos en solo 2-3 colores** es
  buena señal de que es una ilustración tipo gajos/sección en vez de fruta
  entera y sólida (un SVG de fruta entera normal tiene pocas decenas de
  formas, no cientos). Se sustituyó por `simple-orange` (id 26783, autor
  `laobc`) y `pear` (id 62065, autor `pawelf`), ambas mucho más simples y sí
  enteras.
- **Sonido**: `GCSoundEffect` (basado en `SoundEffect` de QtMultimedia) en
  este build **solo reproduce bien `.wav`** — se probó primero un `.mp3` de
  Freesound y luego un `.ogg` del mismo sonido, ninguno de los dos sonó
  (sin ningún error en el log). Todos los demás sonidos de GCompris que
  usan `GCSoundEffect` en el repo original son `.wav`, así que al final se
  generó un `.wav` sintético propio con un script de Python (ruido +
  barrido de tono, sin depender de descargar nada) y ahí sí sonó. **Para
  cualquier sonido nuevo de `GCSoundEffect`: usar `.wav` directamente,
  no perder tiempo con mp3/ogg.**
- **Física de la fruta**: arco parabólico calculado por tiempo transcurrido
  (no acumulando velocidad frame a frame, así no hay deriva). El "corte" se
  detecta igual que en `erase`: `MultiPointTouchArea` + `childAt(x, y)`
  sobre un `Item` contenedor separado del de la estela visual (para que la
  estela no interfiera con la detección del corte). Al cortar, la fruta se
  parte en dos mitades recortando (clip) la misma imagen dos veces en vez
  de necesitar sprites de "mitad de fruta" hechos a mano.
- **Sin traducción**: como es contenido nuevo que no existe en GCompris
  original, no hay ninguna entrada en los `.po` para sus textos — se ha
  escrito el texto directamente en español dentro de `qsTr(...)` en
  `ActivityInfo.qml` (funciona igual, simplemente no cambia si se pone la
  app en otro idioma).

### Ajustes hechos tras probarlo jugando (feedback del usuario)

- Arcos más altos, algo de fruta saliendo por los lados, tamaños variables
  por fruta (nunca demasiado pequeña), a veces salen 2 frutas a la vez
  (más probable en niveles altos), y se dobló el total de fruta necesaria
  por nivel (antes 6-16, ahora 12-32) porque el juego se hacía corto.
  Gravedad bajada para que todo vuele más despacio, dando tiempo a
  alcanzarlo.

### Para continuar en otra sesión/chat

Lo primero que debería hacer una sesión nueva es leer este fichero
(`NOTAS_ADAPTACION.md`) entero y `git log --oneline` en `gcompris-qt-src/`
para ver el estado exacto. Punto de partida rápido para volver a compilar:
ver los flags de `cmake` usados en esta fase (`-DCOMPRESSED_AUDIO=ogg
-DSKIP_TRANSLATIONS=OFF` además de los de la Fase 1), y añadir
`C:\Users\Utente\gettext-tools\bin` al PATH.
