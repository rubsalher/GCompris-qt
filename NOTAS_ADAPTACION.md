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

---

## Fase 8 — Actividad nueva "Aplastatopos" (whack-a-mole) (hecho)

Segunda actividad creada desde cero (mismo patrón que `fruitslice` en la
Fase 7): un "topo-golpe" clásico pensado para ejercitar reflejos y
atención, no tanto el movimiento de brazo por toda la pantalla (eso ya lo
cubre `fruitslice`). Ficheros en `src/activities/aplastatopos/`
(`ActivityInfo.qml`, `AplastaTopos.qml`, `HoleSlot.qml`, `HudBadge.qml`,
`aplastatopos.js`, `CMakeLists.txt`, `resource/`). Añadida a
`activities.txt` (sin comentar, orden alfabético entre
`analog_electricity` y `baby_keyboard`).

**Mecánica** (igual que se pidió, tras confirmar por búsqueda web que
coincide con el diseño clásico del género): rejilla de 3x3 agujeros: los
topos salen al azar en un agujero libre y se esconden solos si no se
tocan a tiempo; tocarlos suma un punto y los esconde al momento.
Cronómetro regresivo de 60s. La dificultad (intervalo entre apariciones,
cuánto tiempo queda arriba cada topo, probabilidad de que salgan dos a la
vez) aumenta progresivamente según avanza la partida — parámetros
interpolados linealmente entre un valor inicial suave y uno final más
exigente en `aplastatopos.js` (`lerp`/`difficultyFraction`), no hay
"niveles" manuales de Bar (no tiene botones de nivel, solo ayuda/inicio).
Panel superior con tres indicadores (puntos / récord / tiempo,
`HudBadge.qml`, mismo estilo que `Score.qml` del core) y un botón grande
"Iniciar"/"Volver a jugar" que aparece sobre un overlay semitransparente
mientras no hay partida en curso.

**Récord persistente**: usa `Qt.labs.settings` (`import Qt.labs.settings`,
componente `Settings`), NO el mecanismo propio de `ApplicationSettings`
de GCompris (ese es para ajustes globales de la app, no para datos de una
actividad concreta). El plugin QML (`qmlsettingsplugin.dll`) ya viene
incluido de serie con Qt6/qtdeclarative en `Qt/6.11.1/mingw_64/qml/Qt/labs/settings/`,
no hace falta instalar nada aparte ni tocar `CMakeLists.txt` — se resuelve
solo por ruta de import de QML en tiempo de ejecución. El récord se
guarda aparte del `.conf` de GCompris (categoría `"aplastatopos"`, en el
registro/backend nativo de `QSettings`, no en `GCompris.conf`).

**Arte e imágenes**: a diferencia de `memory`/`fruitslice` (que usan
Openclipart), aquí se preguntó al usuario y **prefirió que se dibujara
todo a mano** en vez de buscar clipart — topo, agujero/montículo de
tierra y fondo de hierba son SVG propios hechos a medida con la paleta
sobria de `GCStyle.qml` (marrón tierra `#6B4E37`/`#7A5B3A`, verde salvia
apagado `#9BAE86`/`#7E9470` para la hierba, nada de verde/marrón
saturado tipo dibujos animados). El "topo saliendo del agujero" se
consigue con un `Item` con `clip: true` (`moleClip` en `HoleSlot.qml`)
que enmarca solo la parte superior del topo (cara/orejas/hocico,
`revealFraction: 0.78` del alto del dibujo) dejando la barriga/patas
literalmente recortadas "dentro" del agujero — no hay que dibujar un
sprite aparte de "medio topo".

**Sonido**: mismo patrón que `fruitslice` — sintetizado con un script de
Python (`gen_whack_sound.py`, no incluido en el repo, era temporal en el
scratchpad) en vez de buscar un `.wav` real, para evitar de entrada el
problema ya conocido de `GCSoundEffect` con `.mp3`/`.ogg` silenciosos.
Es un "thump" grave con un poco de ruido de impacto y un pequeño barrido
de tono, ~220ms.

**Gotcha nuevo — verificación visual imposible en este entorno concreto**:
a diferencia de fases anteriores (que sí se pudieron ver jugando), en
esta sesión el entorno de automatización (herramienta de control de
escritorio) resultó estar controlando una sesión/máquina distinta de
aquella donde corre de verdad la build compilada — se pudo lanzar el
`.exe`, moverlo, comprobar con la API de Windows que su ventana existe y
tiene tamaño/posición normales, pero nunca apareció en ninguna captura de
pantalla tomada por esa herramienta (ni con `--window`, ni con
`--software-renderer`, ni forzando foco a mano vía `SetForegroundWindow`/
`AttachThreadInput`). Una captura de pantalla *real* tomada con
`System.Drawing.Graphics.CopyFromScreen` (PowerShell) confirmó que en la
pantalla física de verdad la ventana de la propia app de chat ocupa toda
la pantalla y no se puede apartar mediante llamadas de foco programáticas
(está fijada delante). **Conclusión práctica**: en este tipo de entorno,
para una actividad nueva no basta con "lanzar y hacer capturas" — hay que
verificar por otras vías (compilación limpia, `--list-activities` para
confirmar que se registra, `--launch <nombre-actividad>` +
`--window --software-renderer` redirigiendo stdout/stderr a fichero para
comprobar que no hay errores/avisos de QML al cargar la actividad
concreta) y pedirle al usuario que la juegue él mismo para el visto bueno
final de sensaciones de juego (velocidad, tamaño de agujeros, etc.) — iría
en línea con el patrón ya conocido de "no se ha podido compilar/ver en
este entorno" de las Fases 1-4, solo que ahora el bloqueo es de
visualización, no de compilación.

**Corrección importante (tras el playtest real del usuario): `--launch` NO
basta para verificar una actividad nueva.** Lo de arriba resultó ser
insuficiente en la práctica — la actividad compilaba, pasaba
`--list-activities` y arrancaba sin fallos con `--launch aplastatopos`,
pero **al entrar desde el menú de verdad (tocando el icono) no dejaba
entrar**, sin ningún error visible al principio. La causa real, encontrada
tras bastante ida y vuelta:

1. **`--launch <actividad>` usa un camino de carga distinto al menú real.**
   El menú (`Menu.qml`, función `selectCurrentItem()`) carga la actividad
   con `Loader { asynchronous: true }` + `activityLoader.setSource(url,
   {...propiedades iniciales...})`, es decir, RESOLUCIÓN DE TIPOS QML EN
   TIEMPO DE EJECUCIÓN sobre un recurso `.rcc`. `--launch` en cambio no
   pasa por ese `Loader` en absoluto, así que un fallo específico de esa
   vía (como un tipo QML que no se resuelve) **no aparece nunca** al
   probar con `--launch`, por muy limpio que salga.
2. **El fallo real**: `HammerEffect.qml` (añadido en esta misma fase,
   *después* de la configuración inicial de `cmake`) daba
   `"HammerEffect is not a type"` únicamente por el camino del `Loader`
   del menú. Motivo: al añadir un fichero `.qml` **nuevo** a una actividad,
   `cmake --build` (recompilar sin más) no es suficiente — la lista de
   tipos QML del módulo/recurso de esa actividad se fija en el paso de
   **configuración** de CMake (`cmake -G Ninja ...`), no en el de build.
   Sin volver a configurar, el `.qml` nuevo se copia igualmente al `.rcc`
   (por eso `--launch` no se quejaba de "fichero no encontrado"), pero no
   queda registrado como tipo disponible para la resolución dinámica del
   `Loader`, y solo ese camino se queja. **Es la misma familia de gotcha ya
   documentada en la Fase 6 sobre `.rcc` desactualizados, pero aplicada a
   ficheros `.qml` nuevos, no solo a `resource/*`.**
3. **Regla práctica a partir de ahora**: cualquier vez que se **añada un
   fichero `.qml` nuevo** a una actividad (no solo la primera vez que se
   crea la actividad entera), hay que volver a ejecutar el `cmake -G
   Ninja ...` completo de configuración (no solo `cmake --build .`) antes
   de dar la actividad por verificada, y la comprobación real tiene que
   incluir **entrar desde el menú de verdad** (o, si no se puede jugar a
   mano, forzar ese mismo camino de carga), no solo `--launch`.

**Truco para ver los mensajes reales de consola (`console.log`/`qWarning`,
errores de QML) en esta build**: por defecto esta compilación está en modo
`CMAKE_BUILD_TYPE=Release` (es el valor por defecto si no se especifica
`-D` al configurar) y, al ser `GCompris.exe` una app de tipo "ventana"
sin consola propia, **Qt no escribe nada a stdout/stderr aunque se
redirija la salida** — ni siquiera `console.warn()`. Hay que forzarlo con
la variable de entorno `QT_FORCE_STDERR_LOGGING=1` antes de lanzar el
`.exe`; con eso sí aparecen todos los `qWarning`/errores de QML/
`console.log` al redirigir a fichero (`GCompris.exe > log.txt 2>&1`). Sin
esta variable, un `.bat`/consola con la salida redirigida puede parecer
"no hay ningún error" cuando en realidad Qt simplemente no está
escribiendo nada.

**Cuidado con dejar flags de depuración puestos**: durante esta
investigación se usó temporalmente `--window --software-renderer` (para
sortear un problema de visualización específico del entorno de
automatización de esa sesión, no del PC real del usuario) y esto se quedó
sin querer grabado en `GCompris.conf` (`renderer=software`) y en un acceso
directo del escritorio — causó que la pantalla completa dejara de
funcionar bien en el uso normal del usuario. **Si se usa
`--software-renderer` o `--window` para depurar, revertir
`[Admin] renderer=` a `direct3d11` en
`%LOCALAPPDATA%\GCompris\GCompris.conf` y quitar esos flags de cualquier
acceso directo antes de darlo por terminado** — no son necesarios para el
uso normal, solo para diagnosticar en un entorno con problemas de pantalla.

**Truco útil descubierto para lanzar el `.exe` de desarrollo sin tocar el
PATH cada vez**: ejecutar `windeployqt.exe --qmldir <ruta a src/>
GCompris.exe` desde `build/bin` copia automáticamente todas las DLL de
Qt/MinGW y los plugins QML (incluido `Qt/labs/settings`) junto al
ejecutable, de modo que a partir de ahí `GCompris.exe` se puede lanzar con
doble clic o acceso directo sin depender de que el PATH tenga
`Qt/6.11.1/mingw_64/bin` — cómodo para que el usuario pruebe la build sin
usar la terminal. No hace falta repetirlo en cada recompilación, solo
si `build/bin` se borra o se crea de cero. Flags de `GCompris.exe` útiles
para depurar sin interfaz gráfica: `--list-activities` (lista los nombres
internos de actividades registradas), `--launch <nombre>` (arranca
directo en una actividad, saltándose el menú), `--window` (fuerza modo
ventana en vez de pantalla completa) y `--software-renderer` (evita el
renderizador Direct3D11, útil si el entorno de pantalla da problemas con
render acelerado).

### Ajustes tras el primer playtest del usuario (hecho)

- **Bug importante arreglado — no se podía golpear ningún topo**: el
  `MultiPointTouchArea` que detecta el toque estaba declarado como *hijo*
  de `holesContainer` en vez de hermano. Como se añadió el último, quedaba
  por encima en el orden de pintado, así que `holesContainer.childAt(x,y)`
  siempre se encontraba a sí mismo (el propio área de toque) en vez del
  `HoleSlot` que había debajo, y `hole.whack` nunca se llegaba a llamar.
  Arreglado moviendo el `MultiPointTouchArea` a hermano de `holesContainer`
  (mismo patrón exacto que usan `fruitslice`/`erase`: el área de toque
  vive fuera del contenedor sobre el que se hace `childAt()`, nunca
  dentro). **Apunte para futuras actividades nuevas**: si un
  `childAt()`+`MultiPointTouchArea` no detecta nada, lo primero a mirar es
  si el área de toque es hijo del mismo contenedor sobre el que se llama
  `childAt()` — si lo es, se autodetecta a sí misma y bloquea todo lo de
  debajo.
- **Más agujeros y más grandes**: rejilla de 3x3 (9) a 4x3 (12), y el
  tamaño de cada agujero dentro de su celda sube de 0.86 a 0.95 de la
  celda.
- **Agujeros más realistas**: `resource/hole.svg` rehecho — montículo
  irregular (varias elipses superpuestas en vez de una sola), manchitas de
  tierra más oscuras para textura, briznas de hierba alrededor del borde,
  y el agujero central con gradiente radial para dar profundidad real en
  vez de un óvalo plano de un solo color.
- **Fondo entero verde**: `resource/background.svg` ya no reparte
  cielo arriba / hierba abajo — ahora es todo verde (gradiente radial
  sobre el mismo tono apagado, con manchas suaves de otro verde para no
  quedar plano).
- **El topo ahora parece salir de verdad del agujero**: antes el recorte
  (`clip`) que oculta la mitad inferior del topo cubría todo el rectángulo
  del montículo, mucho más grande que el agujero oscuro dibujado — así que
  el topo "aparecía" en una zona vaga, no exactamente por el agujero.
  Ahora `HoleSlot.qml` calcula la ventana de recorte a partir de las
  coordenadas exactas de la elipse oscura de `hole.svg` (fija a propósito
  en `cx120 cy88 rx66 ry28` sobre un lienzo de `240x160`, con
  `holeImage` forzado a esa misma proporción para que no haya letterboxing
  y las fracciones cuadren siempre igual). El topo se ve asomar justo por
  el agujero, no por una zona genérica del montículo.
- **Martillo al golpear un topo**: nuevo `HammerEffect.qml` +
  `resource/hammer.svg` — al acertar sobre un topo aparece un mazo que cae
  de golpe sobre el agujero (baja, se detiene un instante, se desvanece)
  antes de que el propio componente se destruya solo. Se dispara desde el
  `MultiPointTouchArea` de `AplastaTopos.qml` justo cuando `hole.whack()`
  devuelve `true`, usando `hole.x`/`hole.y`/`hole.width` para colocarlo
  exactamente encima del agujero acertado.

### Segundo playtest — ajustes de tamaño, cabeza cortada y topo dorado (hecho)

- **Agujeros más grandes y separados**: la rejilla ya no fuerza celdas
  cuadradas (`min(width/columns, height/rows)`) — ahora cada `HoleSlot` usa
  un ancho/alto independientes (`cellW`/`cellH` por celda), con el propio
  agujero al 0.8 de la celda (antes 0.95) y una proporción ancha
  (`height: width * 0.72`) que encaja mejor con el dibujo del montículo.
  Resultado neto: agujeros bastante más grandes que antes (el aspecto ancho
  aprovecha mejor cada celda) y con un hueco real entre ellos. Además cada
  agujero tiene un pequeño desplazamiento aleatorio fijo (`jitterX`/`jitterY`,
  calculado una vez con `Math.random()` al crearse, no cambia durante la
  partida) para que la distribución no se vea como una rejilla perfecta.
- **Topos con la cabeza cortada — arreglado**: la ventana de recorte
  (`moleClip`) que antes intentaba ajustarse *exactamente* al óvalo oscuro
  dibujado en `hole.svg` (solo 35% de la altura del montículo) resultó
  demasiado baja para la altura real del topo con el tamaño que se le
  había dado — se veía solo de ojos para abajo, sin orejas ni parte de
  arriba de la cabeza. Solución: la ventana ahora va desde arriba del todo
  del montículo hasta el borde inferior del óvalo (72.5% de la altura),
  manteniendo el ancho ajustado al óvalo (sigue pareciendo que sale por el
  agujero), y el topo se ancla arriba (`y: 0`) en vez de calcular un
  desplazamiento `peekStart` — así se ve la cabeza entera y solo se esconde
  la parte de abajo (tripa/patas). **Apunte para el futuro**: al recortar
  una imagen para simular "saliendo de un agujero", más vale pecar de
  ventana alta que de ventana ajustada al milímetro al dibujo del agujero —
  es fácil que quede más pequeña de lo que la proporción real del sprite
  necesita.
- **Topo dorado (2 puntos)**: nuevo `resource/mole_gold.svg` (mismo dibujo
  que `mole.svg`, solo cambian los colores a tonos dorados) más
  `HoleSlot.isGolden` (elegido al azar en cada aparición,
  `aplastatopos.js` → `GOLDEN_CHANCE = 0.2`, un topo de cada 5
  aproximadamente) y `Activity.moleWhacked(isGolden)` que suma 2 puntos en
  vez de 1. El manual de la actividad (`ActivityInfo.qml`) ya explica la
  diferencia de puntos.
- **Bug encontrado de paso**: `GRID_SIZE` en `aplastatopos.js` se había
  quedado en `9` desde antes de subir la rejilla a 4x3 (12) en el playtest
  anterior — los agujeros 9, 10 y 11 nunca se consideraban "libres" para
  que saliera un topo ni se limpiaban al reiniciar. Corregido a `12` (debe
  coincidir siempre con `columns * rows` de `holesContainer` en
  `AplastaTopos.qml` — no hay un enlace automático entre ambos, es un
  número que hay que mantener sincronizado a mano si se vuelve a cambiar
  el tamaño de la rejilla).

---

## Fase 9 — Actividad nueva "Atrapamanzanas" (hecho, pendiente de playtest)

Tercera actividad creada desde cero, inspirada en el minijuego de "Pou" de
atrapar comida que cae. Ficheros en `src/activities/atrapamanzanas/`
(`ActivityInfo.qml`, `AtrapaManzanas.qml`, `Apple.qml`, `HudBadge.qml`,
`atrapamanzanas.js`, `CMakeLists.txt`, `resource/`). Añadida a
`activities.txt` (orden alfabético, justo después de `aplastatopos`).

**Mecánica**: un manzano fijo arriba de la pantalla; van cayendo manzanas
en línea recta desde puntos al azar de la copa del árbol. Se mueve una
cesta tocando en cualquier punto de la pantalla (la cesta se desliza hasta
la posición X tocada, con una pequeña animación de deslizamiento, no salto
instantáneo) para atraparlas antes de que lleguen al suelo. Cronómetro de
60s, puntuación + récord persistente (mismo mecanismo de
`ApplicationSettings.setCurrentLevels`/`currentLevels` que ya usa
`aplastatopos`, con clave distinta `"atrapamanzanas-highscore"`), y
dificultad que aumenta con el tiempo (menos tiempo de caída, más
frecuencia de aparición, más probabilidad de que caigan dos manzanas a la
vez) — mismo patrón de `lerp`/`difficultyFraction` que `aplastatopos.js`.
Sin fallos por manzana no atrapada (cae y desaparece sin más, diseño
relajado igual que el resto de la adaptación).

**Detección de "atrapada"**: a diferencia de `aplastatopos` (que detecta
toques sobre el objeto), aquí la manzana cae sola y el jugador solo
controla la cesta — así que la comprobación de colisión la hace la propia
manzana (`Apple.qml`) en su `Timer` de 30ms, cada tick, comparando su
borde inferior y su centro horizontal contra la caja de la cesta (recibida
como referencia de objeto `required property Item basket` al crearla).
Igual que `Fruit.qml`, la posición se calcula a partir del tiempo
transcurrido (no acumulando velocidad frame a frame) para que no haya
deriva.

**Arte propio**: manzano, manzana y cesta dibujados a mano en la paleta
sobria de la app (mismo criterio que se decidió para `aplastatopos` —
nada de Openclipart esta vez tampoco). Sonido de "atrapada" sintetizado
con Python (un "pop" agudo de dos tonos cortos), mismo motivo de siempre
para `GCSoundEffect` (`.wav` sí, `.mp3`/`.ogg` no suenan en esta build).

**Verificación hecha sin jugar a mano** (siguiendo la lección de la Fase
8): reconfigurado `cmake` completo ANTES de compilar (no solo
`cmake --build`, para que los `.qml` nuevos queden registrados como tipos
desde el principio), `--list-activities` confirma que se registra, y
`--launch atrapamanzanas --window --software-renderer` con
`QT_FORCE_STDERR_LOGGING=1` no muestra ningún error real (solo un aviso
inofensivo y repetido en toda la app, `"Unable to assign [undefined] to
int"` al usar `fontSize: GCText.largeSize/smallSize` — no es un fallo
introducido aquí, probablemente ya pasa en toda la aplicación y nunca se
había visto porque hasta la Fase 8 no se sabía lo de
`QT_FORCE_STDERR_LOGGING`; no afecta al funcionamiento, aplastatopos hace
exactamente lo mismo y funciona bien). **Aun así, sigue pendiente el
verdadero visto bueno**: entrar de verdad desde el menú (no solo
`--launch`) y jugar una partida, que es lo único que de verdad prueba el
camino de carga real del menú y las sensaciones de juego (tamaño de
cesta, velocidad de caída, si la cesta responde bien al tacto).

### Primer playtest — bug de manzanas que no caían, y ajustes visuales (hecho)

- **Bug real: nunca caía ninguna manzana.** En `atrapamanzanas.js`,
  `createApple()` tenía una comprobación de más,
  `if (appleComponent.status !== Component.Ready) return`, copiada por
  precaución sin fijarme en que `Component` (el tipo, para acceder a su
  enum `Ready`) **no está disponible sin importarlo** dentro de un fichero
  `.pragma library` — `fruitslice.js`/`aplastatopos.js` nunca lo
  necesitan porque no lo usan. Cada intento de crear una manzana lanzaba
  un `ReferenceError` silencioso dentro del `Timer` de turno y la función
  volvía sin crear nada, sin ningún efecto visible ni mensaje (los errores
  dentro de `onTriggered` de un `Timer` no siempre se ven si no se está
  mirando activamente la consola). **Arreglado quitando esa comprobación
  de más** — el patrón correcto (igual que `fruitslice`) es llamar
  directamente a `component.createObject(...)` y comprobar si el
  resultado es `null`, sin mirar `.status` antes.
- **Por qué no lo detecté antes de que lo probara el usuario**: mis
  comprobaciones con `--launch` abren la actividad en el estado "listo"
  (con el botón "Iniciar" visible) pero **nunca pulsan el botón**, así que
  todo el código de la partida en sí (que solo se dispara al llamar a
  `Activity.startGame()`) nunca se llegó a ejecutar en esas pruebas. Para
  confirmar el arreglo sin depender del usuario, esta vez se añadió
  temporalmente un `Timer` que llama a `Activity.startGame()` a los 500ms
  de cargar la actividad (con `--launch atrapamanzanas`), se comprobó que
  no salía ningún error, y se quitó ese `Timer` antes de dar el arreglo
  por bueno. **Apunte para el futuro**: para verificar de verdad una
  actividad de tipo arcade con botón de "Iniciar" sin poder jugar a mano,
  hace falta forzar el arranque de la partida con un timer temporal así —
  `--launch` por sí solo NO llega a probar nada de lo que pasa dentro de
  la partida.
- **Árbol con tronco gordo y hojas arriba**: `resource/tree.svg` rehecho
  con un tronco bastante más ancho y alto (antes era un palito fino que
  casi no se veía) y la copa de hojas claramente por encima. Las manzanas
  ahora también empiezan a caer desde la parte baja de la copa
  (`canopyBounds().bottom`, ~55% de la altura del árbol) en vez de aparecer
  de la nada por encima de toda la pantalla — así se ve mejor que salen
  del árbol.
- **Cesta a ras de suelo**: quitado el margen inferior que dejaba la
  cesta flotando un poco por encima del borde de la zona de juego —
  ahora `y: playArea.height - height` exacto.
- **Nombres del menú separados en palabras**: "Aplastatopos" →
  "Aplasta topos", "Atrapamanzanas" → "Atrapa manzanas" (solo cambia el
  `title:` que se ve en el menú — el nombre interno de carpeta/fichero
  QML de cada actividad se deja igual, no afecta a nada técnico).

### Segundo playtest — de "manzano" a "lluvia de comida" (hecho)

El usuario pidió quitar el árbol y las manzanas del manzano del todo y
convertirlo en una lluvia de comida variada que cae directamente del
cielo (más fiel al minijuego de "Pou" que inspiró la actividad). Cambios:

- Quitado `resource/tree.svg` y el `Image` del árbol de
  `AtrapaManzanas.qml` — ya no hay manzano, solo cielo.
- `Apple.qml` ahora recibe el dibujo como parámetro
  (`required property string source`, mismo patrón que `Fruit.qml` de
  `fruitslice`) en vez de tener `apple.svg` fijo a fuego — así el mismo
  componente sirve para cualquier alimento.
- Nuevos `resource/banana.svg` y `resource/grapes.svg` (mismo criterio de
  siempre: dibujado a mano, paleta sobria), y `atrapamanzanas.js` elige al
  azar entre manzana/plátano/uvas en cada aparición (`FOOD_TYPES`).
  Fácil añadir más alimentos en el futuro: solo hace falta un SVG nuevo y
  añadir su ruta a ese array.
- La comida ahora cae desde fuera de la pantalla por arriba
  (`startY: -items.appleSize`) y se reparte por casi todo el ancho de la
  zona de juego (`spawnBounds()`, 6%-94%), en vez de limitarse a la copa
  de un árbol que ya no existe.
- Título cambiado a "Lluvia de comida" (antes "Atrapa manzanas") y texto
  de ayuda actualizado para hablar de "comida" en general. El nombre
  interno de carpeta/fichero (`atrapamanzanas/AtrapaManzanas.qml`) se ha
  dejado igual a propósito — es un detalle técnico invisible para el
  usuario y renombrarlo habría sido bastante más trabajo/riesgo (mover
  carpeta, actualizar `activities.txt`, `CMakeLists.txt`, todas las rutas
  `qrc:/...` de cada fichero) sin ningún beneficio para el juego en sí.

### Tercer playtest — suelo, velocidad, icono y "reiniciar récords" global (hecho)

- **Cesta que parecía flotar sobre el suelo**: el motivo era que la franja
  verde de "suelo" estaba dibujada a fuego en `resource/background.svg` a
  una altura fija (960-1080 de un lienzo de 1080), pero la cesta se coloca
  en `playArea.height` (que depende de la altura real del HUD/barra
  inferior en cada resolución) — casi nunca coincidían exactamente, y a
  veces quedaba un hueco de cielo entre la cesta y la franja verde.
  **Arreglado quitando la franja del SVG y dibujándola en QML** (un
  `Rectangle` anclado a `playArea.bottom`, mismo sitio exacto que usa la
  cesta) — así quedan pegadas siempre, sea cual sea la resolución.
  **Apunte para el futuro**: cualquier elemento "de suelo" que tenga que
  alinearse con algo posicionado dinámicamente (como la cesta aquí) mejor
  dibujarlo en QML anclado a esa misma referencia, no como parte fija del
  fondo SVG.
- **Velocidad de caída aumentada**: `fallDuration` baja de
  `lerp(4200,2200,t)` a `lerp(3200,1600,t)` ms (cae en el aire, de
  principio a fin de la partida, entre un 24-27% más rápido).
- **Icono del menú actualizado**: mostraba solo una manzana sobre la
  cesta; ahora muestra cesta + manzana + plátano cayendo, para que se
  entienda que es "comida variada", no solo manzanas (a falta de que el
  usuario confirme si se refería a esto con "cambia el dibujito" — si se
  refería a otra cosa, decírmelo).
- **"Reiniciar récords" en Ajustes (para todas las actividades con
  puntuación)**: nuevo botón en `src/activities/menu/ConfigurationItem.qml`
  (la pantalla de Ajustes de toda la app, icono de llave inglesa del menú
  principal — **es un fichero del núcleo de GCompris, no de una actividad
  concreta**), al final de la lista, con confirmación Sí/No
  (`Core.showMessageDialog`, mismo patrón que usa el propio menú para
  otros avisos). Al confirmar, pone a cero las claves
  `aplastatopos-highscore` y `atrapamanzanas-highscore` guardadas vía
  `ApplicationSettings.setCurrentLevels`. **Si se añade una actividad
  nueva con récord persistente en el futuro, hay que añadir su clave a
  mano a la lista `highScoreKeys` de ese botón** — no hay ningún registro
  automático de "qué actividades tienen récord". Texto del botón escrito
  directamente en español (igual que en las actividades nuevas) porque es
  contenido añadido sin entrada en el catálogo de traducción real.

### Cuarto playtest — comida desde más arriba/más rápida, "Corta la fruta" a un solo nivel (hecho)

- **Atrapamanzanas**: la comida ahora empieza a caer desde
  `-appleSize * 3` en vez de `-appleSize` (bastante más arriba de la
  pantalla, así el trayecto visible es más largo) y la duración de caída
  baja otra vez, de `lerp(3200,1600,t)` a `lerp(2900,1450,t)` ms (un
  ~10% más rápido encima del aumento de la vez anterior).
- **"Corta la fruta" (`fruitslice`) reducido a un único nivel**: a
  petición del usuario, quitados los niveles 1-5 — se deja solo la
  configuración que antes era el nivel 6 (`spawnInterval: 1100, target:
  32, doubleChance: 0.35`, el más rápido/difícil de los 6 originales) como
  única dificultad, fija. Cambios: `levelProperty` en `fruitslice.js`
  reducido a un solo elemento, y quitado `level` de
  `BarEnumContent { value: help | home | level }` en `FruitSlice.qml`
  (junto con `onPreviousLevelClicked`/`onNextLevelClicked` y el binding
  `bar.level`) — ya no hay flechas de nivel en la barra inferior, solo
  ayuda y inicio. Al completar las 32 frutas sigue saliendo la animación
  de flor/bonus (eso no se ha tocado), simplemente vuelve a la misma
  única configuración en vez de subir a un "nivel 7" inexistente.

### Tableros de ajedrez y damas demasiado pequeños (hecho)

`Chess.qml`/`Checkers.qml` calculan el tamaño de casilla con
`cellSize: Math.min(fórmula_ancho, fórmula_alto)` para dos "estados" de
diseño (vertical/horizontal, según `isVertical`). En horizontal (el caso
normal en una pantalla ancha 16:9 como la del marco táctil), la fórmula de
ANCHO tiene mucho margen de sobra, así que en la práctica **la de ALTO es
siempre la que manda** — y esa dividía por `10` (8 casillas + 2 de
margen "de sobra"), cuando la columna de botones de control
(`controls`) ya limita su propia altura a la del tablero
(`height: chessboard.height`) y no necesita ese margen extra para nada.
Bajado el divisor de `10` a `8.5` en la rama `horizontalLayout` de ambos
ficheros (**no** se ha tocado la fórmula de ancho ni el estado vertical,
que si necesita ese margen extra para la fila de controles apilada encima
del tablero) — el tablero sale bastante más grande sin tocar el resto del
diseño (controles, márgenes, proporción tablero/controles), porque todo lo
demás sigue calculándose a partir del mismo `cellSize`, solo que ahora
parte de una cifra mayor. **Apunte para el futuro**: si algún otro tablero
(`checkers_2players`, `chess_2players`, `chess_partyend`, que comparten
piezas de este mismo patrón) se ve pequeño, mirar primero cuál de las dos
mitades del `Math.min` es la que de verdad manda antes de tocar nada — solo
merece la pena ajustar esa, la otra no cambia nada visualmente.

**Segunda pasada, más agresiva** (a petición del usuario, "no lo verá bien
la gente mayor" si se queda corto): bajado el divisor de alto de `8.5` a
`7`, y el de ancho de `12` a `10` (para que no se convierta en el nuevo
cuello de botella ahora que el de alto ha crecido tanto). Además,
`layoutArea.anchors.bottomMargin` baja de `bar.height * 1.2` a
`bar.height` — ese 20% de más por encima de la altura real de la barra
inferior era hueco vacío desaprovechado entre el tablero y la barra, y
recuperarlo da altura extra gratis sin ningún riesgo (la barra sigue
teniendo su sitio exacto, ni un pixel menos). Piezas, resaltados de
casillas y controles se ajustan solos porque todos se calculan a partir
del mismo `items.cellSize` — no ha hecho falta tocar nada más.

**Tercera pasada, hacia atrás** (la segunda pasada se pasó de grande,
"ahora no se ve bien"): valores dejados a medio camino entre la primera
pasada (`8.5`/`12`/`bar.height*1.2`) y la segunda (`7`/`10`/`bar.height`):
divisor de alto `7.75`, de ancho `11`, `bottomMargin: bar.height * 1.1`.
Pendiente de que el usuario confirme si este punto medio ya cuadra o hay
que afinar más en un sentido u otro.

---

## Fase 10 — Iconos de la barra más pequeños, y el menú aprovecha el hueco al ocultarla (hecho)

Sí sabía a qué se refería el usuario: los 5-6 iconos circulares de la
barra inferior (inicio/G/ayuda/llave/lista) y el icono de "tres líneas"
que la esconde/muestra (`openBar` en `src/core/Bar.qml`) comparten el
mismo tamaño, `bar.buttonSize`.

- **Iconos más pequeños**: `Bar.qml`, `buttonSize` baja de `104 * ratio`
  (puesto en la Fase 2) a `82 * ratio` — sigue siendo más grande que el
  original de GCompris (`78`), pero ya no domina la pantalla como antes.
  Este valor se usa en **toda la app** (es un componente del núcleo, no
  de una actividad), incluido el icono de tres líneas, así que un solo
  cambio arregla ambos a la vez.
  **Efecto secundario esperado**: como `bar.height` baja un poco, los
  tableros de ajedrez/damas (que restan `bar.height` en su fórmula de
  ancho y usan `bar.height * 1.1` como margen inferior, ver más arriba)
  ganarán un pelín de tamaño de rebote (cálculo estimado: unas pocas
  unidades de porcentaje, no debería notarse mucho, pero si al probarlo
  se ven demasiado grandes otra vez, es por esto).
- **El menú aprovecha el hueco al ocultar la barra**: antes, aunque los
  botones desaparecieran al tocar el icono de tres líneas, la rejilla de
  actividades (`activitiesGrid` en `Menu.qml`) seguía terminando en el
  mismo `bar.top` de siempre — `bar.height` no cambia con
  `ApplicationSettings.isBarHidden` (solo se ocultan los botones hijos,
  el icono de tres líneas se queda), así que no se ganaba ningún hueco
  visible. Cambiado el anclaje inferior de la rejilla a
  `ApplicationSettings.isBarHidden ? activityBackground.bottom : bar.top`
  — al ocultar la barra, la rejilla llega hasta abajo del todo y aparecen
  más iconos de actividades de golpe (no se hacen más grandes los
  iconos en sí — `iconWidth`/`activityCellWidth`/`Height` son valores
  fijos — sino que caben más filas a la vez sin hacer scroll).
  **Sin animación de transición** en este cambio de tamaño (salta al
  instante) — si se quiere que se vea igual de suave que el rebote de los
  botones al esconderse, sería un `Behavior`/`AnchorAnimation` aparte, no
  hecho por ahora al no haberse pedido explícitamente.

**Corrección: tableros "gigantes" tras reducir la barra — vuelta a los
valores originales, no un ajuste más encima.** Al probar con los botones
de la barra ya reducidos (Fase 10, `104→82`), los tableros de
ajedrez/damas salieron "gigantes". Antes de seguir ajustando divisores a
ciegas, caída en la cuenta real: **el motivo original de "muy pequeños" no
era que la fórmula del tablero fuera conservadora — era que la Fase 2
había agrandado mucho los botones de la barra (`78→104`), y eso encogía
`layoutArea.height`** (la fórmula resta `bar.height`/usa
`bar.height * 1.2` como margen). Ahora que los botones de la barra vuelven
a bajar cerca de su tamaño original (`75`, ver más abajo), **se ha
revertido `Chess.qml`/`Checkers.qml` a sus divisores originales de
GCompris (`12`/`10`, margen `bar.height * 1.2`)** en vez de seguir
acumulando ajustes sobre una barra que ya no existe en ese tamaño. Si
sigue viéndose pequeño con la barra ya reducida, es la primera vez que se
prueba esta combinación (divisores originales + barra pequeña), así que
tocaría agrandar desde aquí, no siguiendo la cadena de parches anteriores.

**Iconos de la barra reducidos otra vez**: `buttonSize` baja de `82` a
`75` en `Bar.qml` (ya muy cerca del original `78` de antes de la Fase 2).

**Recuadro de fecha/hora del menú reducido**: `clockBar` en `Menu.qml`
baja de `GCStyle.bigButtonHeight * 1.4` a `* 0.85` — el texto en sí no se
ha tocado, solo el alto del rectángulo que lo envuelve (menos aire
alrededor, no letras más pequeñas).

**Marco oscuro del tablero de ajedrez, reducido**: en la captura que envió
el usuario se veía que el rectángulo marrón oscuro (`boardBg`) alrededor
del tablero de 8x8 era mucho más ancho de lo necesario — dejaba un margen
de **una casilla entera** por lado (`cellSize * 10` para un tablero de
`cellSize * 8`), cuando lo único que hay ahí son las coordenadas A-H/1-8
(`font.pixelSize: cellSize * 0.5`). Bajado a `cellSize * 9.2` (margen de
~0.6 casillas por lado, suficiente para las letras/números sin cortarlas)
en `boardBg` y en `boardBorder` (el rectángulo decorativo de detrás, que
hay que mantener igualado a mano — no se recalcula solo). **Las damas NO
necesitaban este arreglo**: su tablero es de 10x10 y su `boardBg` ya usaba
`cellSize * 10 + baseMargins` — casi sin margen de sobra, porque además no
tiene coordenadas dibujadas (no hay `letters`/`numbers` en
`Checkers.qml`). No se ha tocado el tamaño de las piezas/casillas en sí en
este ajuste (`items.cellSize` no cambia) — solo el marco se ha hecho más
fino, lo que ya hace que las piezas se vean más protagonistas dentro del
mismo hueco.

**Aumento pequeño y deliberado, ya con las proporciones confirmadas
buenas**: una vez el usuario confirmó que el tamaño (divisores originales
12/10) y el marco recién recortado se veían bien, pidió agrandar "el
conjunto" (tablero + piezas) un poco más. Subido a `11.2`/`9.3` (frente a
los originales `12`/`10`) en ambos ficheros — un incremento modesto
(~7-8%) a partir de una base ya confirmada, no otra ronda de saltos
grandes. De paso, limpiado un comentario duplicado que se había quedado en
`Checkers.qml` de una edición anterior.
