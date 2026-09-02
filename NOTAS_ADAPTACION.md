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

---

## Fase 11 — "Lluvia de comida": 3 niveles de velocidad, y fondo de bosque (hecho)

- **3 niveles seleccionables** (antes solo había un ajuste automático
  dentro de la partida, sin niveles de verdad): añadido
  `levelProperty` en `atrapamanzanas.js` con 3 configuraciones de
  velocidad cada vez más rápidas (duración de caída y hueco entre
  apariciones), y cableado el patrón estándar de niveles de GCompris
  (`items.currentLevel`/`numberOfLevel` sincronizados con `activity.*`,
  `Core.getInitialLevel/getNextLevel/getPreviousLevel`, flechas de nivel
  en la `Bar` con `BarEnumContent { value: help | home | level }`) —
  mismo patrón que ya se había quitado de "Corta la fruta" en la Fase 9,
  aquí en cambio se ha añadido de cero. Cambiar de nivel reinicia la
  partida a "listo" (no cambia la dificultad a media partida). El
  aumento automático de velocidad *dentro* de cada nivel (según pasan
  los 60s) se mantiene igual que antes, ahora aplicado sobre los valores
  base de cada nivel en vez de unos fijos.
  **Verificado** con el mismo truco de siempre (`Timer` temporal que
  llama a `Activity.startGame()`, más `--start-level 3` para probar el
  nivel más rápido) — sin errores en ninguno de los 3 niveles.
- **Fondo de bosque**: `resource/background.svg` rehecho — nubes suaves
  arriba, dos capas de montañas/colinas en tonos azul-grisáceo y verde
  apagado, y una hilera de árboles (copa redonda + tronco) a los lados
  de abajo, dejando el centro despejado para que no estorbe a la comida
  que cae ni a la cesta. **Ojo**: no se ha vuelto a añadir ninguna franja
  de "suelo" de color fijo al SVG — esa banda se quitó a propósito en la
  Fase 9 porque no coincidía con la posición real de la cesta en
  pantalla (que depende del tamaño de HUD/barra); el "suelo" verde que
  se ve en el juego lo sigue dibujando `AtrapaManzanas.qml` en QML,
  anclado de verdad a la cesta.

**Fondo rehecho al estilo bosque denso que pidió el usuario (con foto de
referencia)**: la composición (troncos grandes en primer plano, copa de
hojas pegada arriba del todo, matojos/rocas abajo, troncos finos y
difuminados al fondo para dar profundidad) sigue la foto que compartió,
pero **redibujada desde cero en los tonos sobrios habituales de la app**
en vez de copiar los colores vivos/estilo dibujos animados de la foto
original (mismo criterio que en la Fase 5 con el fondo del menú: se
recoge el espíritu de una imagen de referencia, no se reproduce tal cual,
también por si tuviera derechos de autor). `resource/background.svg`.

**Hierba de verdad en el suelo por el que se mueve la cesta**: nuevo
`resource/grass.svg` (franja con puntas de hierba dentadas arriba,
pensada para repetirse en horizontal) sustituye al `Rectangle` de color
liso que había antes. En QML, `ground` pasa de `Rectangle` a `Image` con
`fillMode: Image.TileHorizontally` — importante: `sourceSize` se fija a
la altura real de la franja *manteniendo la proporción original del SVG*
(no al ancho completo), si no el mosaico no repite y sale una sola
"hierba" gigante y deformada en vez de repetida. Sigue anclado al fondo
real de `playArea` igual que antes, así que se mantiene pegado a la
cesta.

**Corrección tras ver la primera versión del bosque en pantalla (captura
del usuario) — tres fallos reales, no solo de gusto:**

1. **"Los árboles flotan"**: los troncos grandes y los finos de fondo
   paraban en `y≈950-970` de un lienzo de `1080`, dejando un hueco antes
   del borde inferior — arreglado alargándolos todos hasta `y=1080`
   exacto, sin excepción.
2. **"Cosas verdes mal" donde se mueve la cesta**: eran los óvalos de
   "matojos" que se habían puesto en `background.svg` a una altura fija
   (`y≈870-950`), sin tener en cuenta que la franja de hierba de verdad
   la dibuja `AtrapaManzanas.qml` en QML sobre `playArea` (que no ocupa
   toda la pantalla, tiene el HUD arriba y la barra abajo restando
   espacio) — los dos "verdes" no coincidían y se veían como manchas
   sueltas encima de la hierba real. **Quitados del todo los matojos y
   piedras del SVG de fondo** — la única hierba/vegetación del suelo
   ahora es la franja de `grass.svg` en QML, ya anclada de verdad a la
   cesta.
3. **"El fondo blanco"**: el degradado `#DCD8B8→#C7CBAA` salía
   demasiado pálido en pantalla — cambiado a un verde-tierra más oscuro y
   cálido (`#B7AE86→#8E9678`), que ya no lee como "vacío/blanco" entre
   los troncos. Aumentada también la densidad de troncos finos de fondo
   (de 8 a 10, mejor repartidos) para que se note más el "bosque" y no
   solo unos pocos troncos sueltos.

**Bug real en `grass.svg` (no solo estética): el zigzag de las puntas de
hierba no encajaba consigo mismo al repetirse** (dibujado a mano con
`l` relativos, la suma de subidas/bajadas no volvía exactamente al mismo
punto de partida cada `400px`), así que `Image.TileHorizontally` en QML
sacaba parches con costuras/huecos visibles en vez de una franja
continua — es justo lo que se veía en la captura. **Arreglado usando un
`<pattern>` de SVG** (`resource/grass.svg` ahora tiene su propio lienzo
ancho de `1920x140` con un patrón de triángulos que SVG repite
matemáticamente exacto, sin cálculo a mano) en vez de dibujar el zigzag
entero a pulso — ya no hace falta ni `TileHorizontally` en QML, con
`Image.Stretch` normal es suficiente porque el SVG ya trae el repetido
metido dentro. **Apunte para el futuro**: si hay que crear otro patrón
repetitivo (hierba, agua, ladrillos...), usar siempre `<pattern>` de SVG
en vez de calcular un zigzag/repetición a mano — es fácil que la suma no
cuadre exacta y salgan costuras como esta.

**Hierba demasiado fina y bosque "flotando" debajo de ella**: en la
captura se veía que la franja de hierba era una cinta finita a media
pantalla, con bosque normal (sin hierba) tanto encima como debajo de
ella hasta el borde real de la pantalla — el motivo es que `playArea` (el
área de juego en sí) no ocupa toda la pantalla, deja hueco para el HUD
arriba y la barra de abajo, así que lo que se ve *por debajo* de
`playArea` (justo donde está la barra) es directamente el
`background.svg`, sin ninguna hierba de QML encima. Dos cambios:

1. `ground.height` sube de `playArea.height * 0.1` a `* 0.35` en
   `AtrapaManzanas.qml` — la cesta queda bien dentro de la hierba, no solo
   rozando el borde de arriba.
2. `background.svg` ahora tiene su propio degradado de "suelo" en la
   franja de abajo (`y=760` a `1080`, transición de aire a verde), *antes*
   de los troncos, para que la zona que queda fuera de `playArea` (detrás
   de la barra inferior) también lea como suelo/césped y no como bosque
   cortado en seco justo donde empieza la cinta de hierba de QML.

**Límite honesto de esta sesión**: el usuario pidió "ve revisando tú
mismo hasta que esté bien", pero en este entorno de trabajo no hay forma
de ver la app en pantalla de verdad (ver gotcha de la Fase 8 sobre la
herramienta de automatización) — los cambios de esta ronda están
verificados matemáticamente (proporciones, que no haya huecos) y sin
errores de QML, pero el visto bueno final de cómo queda *de verdad* en
pantalla sigue necesitando que lo mire el usuario.

**El arreglo anterior no bastó — causa real encontrada esta vez.** La
captura siguiente seguía mostrando bosque sin hierba entre la cinta verde
y el borde real de la pantalla. El problema de fondo: `ground` estaba
anclado a `parent.bottom`, es decir, al fondo de **`playArea`** — y
`playArea` deja hueco debajo para la barra inferior (`bottom: bar.top`),
así que su "fondo" no es el fondo real de la pantalla. Todo lo que queda
entre el fondo de `playArea` y el borde de verdad de la pantalla se ve
directamente el `background.svg`, sin ninguna hierba de QML encima —
el degradado de suelo añadido en el fondo (intento anterior) tampoco
llegaba a notarse lo suficiente ahí.

**Arreglo de verdad**: `ground.anchors.bottom` cambia de `parent.bottom`
a **`activityBackground.bottom`** — el borde real de la pantalla, no el
de `playArea` — y la altura pasa a calcularse sobre
`activityBackground.height` (`* 0.4`) en vez de `playArea.height`. Así la
hierba llega sí o sí hasta el borde de verdad, sin depender de cuánto
hueco deje `playArea` para la barra ni de suposiciones sobre cómo encaja
`background.svg` en pantalla. La cesta sigue estando cómodamente dentro
de la franja (empieza bastante por encima de donde está la cesta).

**El usuario compartió una segunda foto de referencia** (bosque con
troncos curvados/gruesos, piedras con musgo, copa densa, hierba en
primer plano — pinta de recurso gráfico de pago) y pidió literalmente
"borra este fondo y pon este nuevo". **No se ha insertado esa imagen tal
cual** — mismo motivo de siempre (parece stock de pago, y es justo el
mismo criterio ya aplicado en la Fase 5 con la imagen de referencia del
menú) — en su lugar, `resource/background.svg` se ha rehecho de cero
copiando la *composición* (un par de troncos ahora dibujados con curvas
Bézier en vez de trapecios rectos, piedras con musgo cerca del suelo,
copa mucho más densa y superpuesta en capas arriba, matojos de hierba
extra junto a las bases de los troncos) pero en la paleta sobria propia
de la app, no los colores vivos de la foto. El arreglo de "la hierba
llega hasta abajo de verdad" de la ronda anterior (anclado a
`activityBackground.bottom`) no se ha tocado, sigue igual.

**Franja de hierba de QML quitada, a petición del usuario** — se deja
solo el `background.svg` (bosque + degradado de suelo integrado en el
propio SVG). Quitado el `Image { id: ground }` de `AtrapaManzanas.qml` y
borrado `resource/grass.svg` (ya no lo usa nadie). **Recordatorio**: al
borrar un fichero de recurso hace falta reconfigurar `cmake` (no solo
`cmake --build`), si no Ninja falla con "missing and no known rule to
make it" porque la lista de recursos generada en la configuración
anterior todavía lo espera — mismo tipo de gotcha que al *añadir*
ficheros nuevos, pero al revés.

---

## Fase 12 — Quitados los juegos de memoria de sonido, y sonido/música al final del menú (hecho)

- **Borrados**: `memory-sound` y `memory-sound-tux` (juego de memoria por
  sonidos) — comentados en `activities.txt`, ya no compilan ni aparecen.
  Comprobado antes de quitarlos que ninguna otra actividad activa los usa
  como "donante" (no aparecen referenciados en el código de otras
  actividades).
- **Movidos al final de la lista del menú**: `instruments`, `melody`,
  `piano_composition`, `play_piano` (los 4 juegos de sonido/música que
  quedaban activos). **Importante para el futuro**: el orden en que
  aparecen los iconos en el menú **es el mismo orden en que están escritas
  las líneas activas (sin `#`) en `activities.txt`**, de arriba a abajo —
  no es alfabético por título ni por sección. Así que para reordenar el
  menú, lo que hay que mover es la posición de la línea en este fichero,
  no nada en el código QML. Las 4 líneas se han sacado de su sitio
  alfabético y puesto justo después de `traffic` (la última actividad
  activa antes de esta fase), rompiendo a propósito el orden alfabético
  del fichero para esas 4 líneas — el comentario "Keep it sorted" de la
  cabecera del fichero es solo una convención de mantenimiento, no algo
  que rompa la compilación si no se sigue.

**"Instrumentos musicales" (`instruments`) también borrado**, comentado
en `activities.txt`. Antes de quitarlo comprobé que nada dependa de él
como "donante" obligatorio: `simplepaint` y `sketch` sí lo mencionan
(`resource/background.svg` de `instruments` aparece en su galería
opcional de fondos para dibujar), pero es la misma referencia "blanda" ya
documentada en la Fase 6 — si alguien elige justo ese fondo concreto en
`simplepaint`/`sketch` puede salir en blanco, el resto de la actividad no
se rompe (ya pasa lo mismo con otras decenas de fondos de esa galería que
apuntan a actividades ya inactivas, no es nada nuevo). `colors` (la
actividad de la que `instruments` sí dependía) se queda tal cual, sigue
activa por sí misma sin cambios.

---

## Fase 13 — Actividad nueva "Encaja bloques" (inspirada en Block Blast) (hecho)

Cuarta actividad creada desde cero. El usuario pidió reproducir el juego
móvil "Block Blast" y compartió una captura; antes de construirlo se
buscaron las reglas exactas en internet para no adivinarlas (ver fuentes
en la conversación): tablero 8x8, 3 piezas a la vez, sin rotación, sin
límite de tiempo, se borran filas/columnas completas, puntuación por
tamaño de pieza + bonus por línea + bonus de combo si se borra más de una
línea a la vez, partida terminada cuando ninguna de las 3 piezas caben ya
en el tablero. Ficheros en `src/activities/encajabloques/`
(`ActivityInfo.qml`, `EncajaBloques.qml`, `PieceTile.qml`, `HudBadge.qml`,
`encajabloques.js`, `CMakeLists.txt`, `resource/`). Añadida a
`activities.txt` en orden alfabético.

**Cambio deliberado respecto al original: toca-y-toca en vez de arrastrar.**
El juego real se juega arrastrando cada pieza con el dedo hasta el
tablero. Aquí se cambió a "toca una pieza de la bandeja para
seleccionarla, luego toca la casilla del tablero donde tiene que ir la
esquina superior izquierda de su caja" — un arrastre preciso y sostenido
es más difícil para gente mayor en un marco táctil IR que dos toques
simples, y además es bastante más sencillo de implementar de forma
robusta sin poder probarlo a mano en este entorno. Un toque en una
casilla que no encaja no hace nada (solo un sonido de aviso, `crash.wav`
reutilizado del núcleo — es el sonido de "respuesta incorrecta" que ya
usa toda la app) y la pieza se queda seleccionada para volver a intentarlo
sin penalización. **Pendiente para el futuro si se pide**: una vista
previa en vivo de dónde caería la pieza mientras se mantiene el dedo, algo
más cercano al juego original — no se ha hecho en esta primera versión
por simplicidad y para minimizar riesgo de bugs de arrastre no
verificables visualmente.

**Piezas**: 31 formas (ficha suelta, dominó, tromino/tetromino/pentominó
en línea, cuadrado 2x2 y 3x3, trominós de esquina, y las 4 rotaciones de
L, J, S/Z y T) en `SHAPES` de `encajabloques.js`, cada una una lista de
`[fila, columna]` relativos, siempre normalizada para que la caja
delimitadora empiece en `(0,0)` — el toque en el tablero coloca esa
esquina de la caja ahí, sea o no una casilla rellena de la pieza en sí
(por ejemplo la T "hacia arriba" tiene la esquina `(0,0)` vacía).

**Colores**: en vez de un único bloque en escala de grises re-teñido con
un efecto (`MultiEffect.colorization`, cuyo comportamiento exacto no se
podía verificar sin ver la pantalla), se hicieron **5 SVG ya coloreados**
(`resource/block_blue.svg`, `_gold`, `_purple`, `_green`, `_red`, mismo
bisel/sombreado en los 5, solo cambia el tono) — más ficheros pero cero
incertidumbre de cómo se va a ver, dado que no hay forma de comprobarlo
en pantalla en este entorno.

**Verificación exhaustiva sin poder jugar a mano**: como esta actividad
NO tiene botón de "Iniciar" (la partida empieza sola al entrar, como el
juego real, sin límite de tiempo) `--launch encajabloques` sí ejercita de
verdad `newGame()`/generación de piezas/comprobación de partida-terminada
al arrancar — a diferencia de las actividades tipo arcade de fases
anteriores. Además, para probar la interacción de tocar-y-colocar
(que si depende de un toque real), se añadió temporalmente un `Timer` que
llamaba a `Activity.selectPiece()`/`Activity.attemptPlace()` con
coordenadas conocidas — incluida una prueba a propósito de solape
(colocar una pieza encima de otra ya puesta, debe fallar) y una prueba
determinista de borrado de línea (rellenar una fila a mano dejando un
hueco, colocar una ficha suelta ahí, comprobar que la puntuación sube lo
esperado Y que la fila queda vacía otra vez) — **las tres pruebas dieron
el resultado exacto esperado** antes de quitar el `Timer` de prueba.
Aparte de eso, ningún error de QML en ninguna comprobación.

## Fase 14 — "Encaja bloques": arrastrar en vez de tocar, y fondo oscuro (hecho)

Petición: "Añade un fondo obscuro, y haz que los bloques se puedan
deslizar para ver como los coloca y tener mas precision" — la primera
versión de Fase 13 era tocar-para-elegir-y-tocar-para-colocar; se pidió
cambiarlo a arrastrar de verdad, con vista previa en vivo (justo lo que
la Fase 13 había dejado apuntado como "pendiente si se pide").

**Fondo**: `activityBackground.color` pasó de `GCStyle.lightBg` a un
azul marino oscuro (`"#1E2A38"`) — además de ser lo pedido, hace que los
5 colores de bloque resalten más que sobre fondo claro (como en el Block
Blast real).

**Arrastre**: se rehizo la interacción entera siguiendo el patrón ya
usado en `erase.js`/`fruitslice.js` de esta adaptación — un único
`MultiPointTouchArea` que cubre toda `playArea` (tablero + bandeja),
NO uno por ficha, porque un área de toque limitada a una sola ficha deja
de recibir actualizaciones en cuanto el dedo se sale de los límites de
esa ficha durante el arrastre. `PieceTile.qml` quedó como componente
puramente visual (sin lógica de toque propia, solo dibuja la pieza o la
oculta mientras se arrastra vía `beingDragged`). Toda la lógica de
arrastre vive en `encajabloques.js`: `beginDrag(slot)` al empezar,
`updateDragPosition(fila, columna)` en cada movimiento (recalcula qué
casillas se ocuparían y si el hueco es válido), `endDrag(fila, columna)`
al soltar (coloca la pieza si es válido, si no la devuelve a su hueco sin
penalización), y `cancelDrag()` si el toque se pierde a media partida.

**Vista previa en vivo**: mientras se arrastra, las casillas del tablero
por donde pasaría la pieza se resaltan en verde translúcido (encaja) o
rojo translúcido (no encaja) — esto es justo la "más precisión" pedida,
ya que antes solo se sabía si encajaba al soltar. Además se añadió una
pieza "fantasma" (`ghost`) que sigue al dedo por encima (desplazada hacia
arriba para no quedar tapada) mostrando la pieza que se está moviendo,
ya que la ficha original de la bandeja se oculta mientras tanto.

**Verificado** con el mismo método sin pantalla de siempre: `--launch
encajabloques` (esta actividad no tiene botón de Iniciar, así que
`--launch` sí ejercita `newGame()` de verdad) más un `Timer` de
diagnóstico temporal que llamó a `beginDrag`/`updateDragPosition`/
`endDrag` con coordenadas conocidas — colocación válida (la puntuación
subió lo esperado) y colocación solapada (la puntuación no cambió y
`draggingSlot` volvió a `-1` sin fallo) dieron el resultado exacto
esperado; el `Timer` se quitó después. Ningún error de QML en ninguna
comprobación.

**Aprovechado también para cerrar dos cabos sueltos que quedaron
pendientes de la Fase 13**: el texto de ayuda de la actividad
(`ActivityInfo.qml`) se reescribió para explicar arrastrar en vez de
tocar-y-tocar, y se añadió `"encajabloques-highscore"` a la lista de
claves que borra el botón "Reiniciar récords de las actividades" en
Ajustes (`ConfigurationItem.qml`) — antes solo incluía Aplastatopos y
Atrapamanzanas.

## Fase 15 — "Boceto" (Sketch) simplificado a lápiz + goma (hecho)

Petición: "La actividad de boceto la puedes hacer mas sencilla pon que
hayan colores normales una goma para borrar a la vista que se pueda
agrandar el grosor para dibujar y borrar, simplificalo que no hayan
tantas cosas inecesarias". "Boceto" venía de fábrica siendo un mini
editor de imagen completo: 6 estilos de pincel distintos (redondo,
relleno, aerógrafo, "sketch", spray, círculos), herramientas de formas
geométricas, degradados, sellos, texto, un selector de color con
paletas editables y rueda de color, selector de imagen de fondo, y
guardar/abrir archivo — todo repartido en 3 paneles plegables. Muchísimo
para alguien mayor que solo quiere dibujar con el dedo.

**Simplificado a lo esencial**, todo siempre visible en una sola barra
arriba del lienzo (nada plegado ni escondido en menús):
- 9 colores normales en círculos grandes (negro, rojo, naranja,
  amarillo, verde, azul, morado, marrón, rosa) — tocar uno lo selecciona
  y sale del modo goma automáticamente.
- Un botón de goma de borrar bien visible (con su icono), que se queda
  resaltado en azul mientras está activo. Tocarlo otra vez vuelve a
  dibujar.
- Un único control "Grosor" (`GCSlider`) que engorda o afina el trazo
  — recuerda un grosor distinto para el lápiz y para la goma (p. ej. se
  puede querer un lápiz fino pero una goma gorda), y muestra/edita el
  que corresponda según si la goma está activada o no.
- Deshacer/rehacer (flechas) y un botón de recargar en la barra de abajo
  que borra todo el lienzo (con confirmación de "¿Quieres borrar el
  dibujo?").

**Quitado por completo** (no solo escondido): los otros 5 estilos de
pincel, las herramientas de formas/degradados/sellos/texto, el selector
de imagen o color de fondo, y guardar/abrir archivo — junto con sus 21
ficheros `.qml` ya inservibles (`ToolsPanel.qml`, `ColorsPanel.qml`,
`ColorSelector.qml`, `FilesPanel.qml`, `FoldablePanel.qml`,
`GeometryTool(Panel).qml`, `GradientTool(Panel).qml`,
`StampTool(Panel).qml`, `TextTool(Panel).qml`, `BrushToolPanel.qml`,
`BackgroundSelector.qml`, `PatternSelector.qml`, `SliderColor.qml`,
`SliderSettings.qml`, `DarkCheckBox.qml`, `ActionButton.qml`,
`SelectionButton.qml`, `ActivityConfig.qml` — este último era solo un
ajuste de "número de deshacer" en el diálogo de configuración de la
actividad, que también se quitó de la barra por ser una opción de más).
`BrushTool.qml` se recortó para dejar solo el pincel redondo (el mismo
que ya servía tanto para dibujar como, en modo goma, para borrar — no
hacía falta escribir nada nuevo ahí). **Importante**: antes de borrar
nada se comprobó con `grep` que ningún otro fichero del repositorio
dependía de ellos — la actividad `compass` (desactivada en el menú de
esta adaptación, ver `activities.txt`) resulta que SÍ importa
`PaletteSelector.qml` y `BackgroundColorSelector.qml` de la carpeta de
sketch, así que esos dos ficheros (y sus iconos en `resource/`, también
reutilizados por `compass`) se dejaron intactos.

**Verificado** sin poder ver la pantalla, como siempre: tras borrar
ficheros `.qml` hizo falta `cmake` de reconfiguración completa (no solo
recompilar) antes del primer build. Con `--launch sketch` (esta
actividad tampoco tiene botón de Iniciar) más un `Timer` de diagnóstico
temporal se simuló un trazo completo, el cambio de color, activar/
desactivar la goma con el deslizador de grosor recordando cada valor
por separado, deshacer/rehacer, y el flujo de "borrar todo" — los 9
`console.warn` de comprobación dieron exactamente el resultado esperado
(p. ej. al activar la goma el deslizador mostró su propio grosor
guardado sin tocar el del lápiz, y viceversa). También se relanzó
`--launch compass` para confirmar que seguía arrancando sin errores tras
tocar ficheros de su misma carpeta compartida. Ningún error de QML en
ninguna comprobación (aparte del falso positivo ya conocido y
documentado de `fontSize: GCText.smallSize`).

**Corrección tras la primera prueba real en el marco IR**: el usuario
reportó que ni los colores, ni la goma, ni el grosor respondían al
tocarlos. Causa encontrada: en `Sketch.qml`, el control de "Grosor"
(`Column` con el texto y el `GCSlider`) estaba puesto directamente
dentro de la `Row` de la barra de herramientas con `anchors.verticalCenter`
puesto en él mismo — y en Qt Quick, un hijo directo de `Row`/`Column`/
`Grid` no puede tener `anchors` propios, porque `Row` coloca a sus hijos
moviéndoles `x`/`y` ella misma; en cuanto detecta un hijo con `anchors`
deja de funcionar para **todos** sus hijos, no solo para el que los
tenía puestos, así que probablemente todos los botones de la barra
(colores, goma, deshacer, rehacer) quedaron amontonados en una posición
que no coincidía con lo que se veía en pantalla, dejando el conjunto
prácticamente inutilizable. Solución: meter el `Column` un nivel más
adentro, dentro de un `Item` normal sin anchors propios (que sí puede
ser hijo directo de la `Row` sin problema), y anclar el `Column` dentro
de ESE `Item`. Verificado que compila y arranca sin errores QML;
pendiente de que el usuario lo vuelva a probar en el marco IR para
confirmar que ahora sí responde al tacto (esto no se puede comprobar de
ningún otro modo desde este entorno de desarrollo, que no tiene pantalla
táctil ni acceso visual real al resultado).

**Segunda corrección, con foto real de la pantalla** (el usuario mandó
una captura): la primera corrección no fue suficiente. La foto reveló
DOS fallos distintos y más importantes que el de `anchors` dentro de
`Row`:

1. **La barra era más ancha que la pantalla.** En la foto faltaba el
   círculo negro por completo (empujado fuera del borde izquierdo) y
   deshacer/rehacer no aparecían por ningún lado (empujados fuera del
   borde derecho) — los 9 colores + goma + control de grosor (260px de
   ancho él solo) + deshacer/rehacer, todo en una sola fila, sencillamente
   no cabían en el ancho de la pantalla a este tamaño de botón grande.
   Arreglado repartiendo la barra en **dos filas**: colores arriba,
   goma + grosor + deshacer/rehacer abajo — comprobado con un `Timer` de
   diagnóstico que las dos filas (1274px y 1010px) caben de sobra dentro
   del ancho real de la barra (1888px en una pantalla de 1920).
2. **El color/goma/grosor no se aplicaban de verdad al dibujar**, aunque
   el botón correspondiente sí cambiaba de aspecto (por eso en la foto se
   ve amarillo "seleccionado" con su marco azul, pero los trazos
   dibujados salen todos en gris oscuro). Causa: el pincel (`roundBrush`
   en `BrushTool.qml`) solo lee `items.foregroundColor` y el grosor
   dentro de `modeInit()`, y `modeInit()` solo se llamaba UNA VEZ al
   empezar la actividad (vía `canvasArea.init()`). En la versión
   original de Sketch con paneles plegables, esto se disparaba de nuevo
   cada vez que se CERRABA un panel (`ColorsPanel.onClose: {
   items.selectedTool.toolInit(); }`) — pero la barra nueva, al no tener
   paneles que abrir/cerrar, nunca volvía a llamarlo, así que el pincel
   se quedaba pintando para siempre con el color/grosor que hubiera al
   arrancar. Arreglado añadiendo una función `toolbar.refreshBrush()`
   (llama a `brushTool.toolInit()` si el contexto del canvas ya existe)
   invocada explícitamente al tocar un color, al tocar la goma, y en
   cada cambio del deslizador de grosor.

Verificado con un `Timer` de diagnóstico temporal que llamó a las
mismas rutas que tocaría el dedo del usuario (cambiar color, mover el
grosor, activar la goma) y leyó directamente `tempCanvas.ctx.strokeStyle`
/`ctx.lineWidth` antes y después de cada cambio — los tres casos dieron
el valor esperado exacto (p. ej. tras elegir azul, `ctx.strokeStyle`
pasó de `#1a1a1a` a `#2e6fd9`; tras activar la goma, pasó a `#ffffff` con
el grosor de goma en vez del de lápiz). `Timer` retirado después.
Ningún error de QML en ninguna comprobación.

**Tercera ronda tras la foto de la barra ya funcionando**: el usuario
confirmó que colores y goma ya respondían bien, pero pidió tres cosas
más: (1) la barra en dos filas ocupaba demasiado alto en la hoja de
dibujo, volver a una sola fila; (2) como 9 colores grandes no caben en
una sola fila, meterlos en una franja que se pueda deslizar con el dedo
(con su propia barrita de desplazamiento visible) en vez de partir la
barra en dos; (3) lo que se pinta no salía con opacidad 100%.

- **Una sola fila con colores deslizables**: la barra volvió a su altura
  de una sola fila. Los controles de tamaño fijo (goma, grosor,
  deshacer, rehacer) se anclaron a la derecha (`toolsRow`, con
  `anchors.right: parent.right`), y los colores pasaron a un `Flickable`
  horizontal (`colorsFlick`) que ocupa todo el ancho que quede libre a
  la izquierda de esos controles (`anchors.right: toolsRow.left`) —
  contiene el `Row` de los 9 círculos de color, y se puede arrastrar con
  el dedo para ver los que no caben en el ancho visible. Debajo del
  `Flickable` se añadió un `ScrollBar` (de `QtQuick.Controls.Basic`,
  igual que ya se hace para `GCSlider`) enlazado a mano a
  `colorsFlick.visibleArea.widthRatio`/`xPosition` — se ve como una
  barrita que también se puede arrastrar directamente para desplazar los
  colores, y solo aparece si de verdad sobran colores que no caben
  (`policy: colorsRow.width > colorsFlick.width ? AlwaysOn : AlwaysOff`).
- **Opacidad 100%**: la causa era que `AbstractBrush.qml` (heredado del
  Sketch original) trae por defecto `toolOpacity: 0.5` — en la versión
  original esto se podía subir a 1 con un deslizador de opacidad dentro
  del selector de color avanzado, que se quitó al simplificar la
  actividad, dejando el pincel encallado permanentemente al 50% sin
  ninguna forma de cambiarlo. Arreglado poniendo `toolOpacity: 1` y
  `defaultToolOpacity: 1` directamente en `roundBrush` (dentro de
  `BrushTool.qml`) — la goma ya estaba al 100% de fábrica
  (`eraserOpacity: 1`), no hacía falta tocarla.

Verificado con `--launch sketch` más un `Timer` de diagnóstico temporal:
la barra bajó de dos filas a una sola (176px de alto, la mitad que
antes), el ancho visible de la franja de colores (825px) es menor que
el ancho total de los 9 colores (1274px) así que la barrita de
desplazamiento sale activada como se esperaba, arrastrar
`colorsFlick.contentX` a mano mueve correctamente la posición de la
barrita, y `roundBrush.toolOpacity` se confirma en `1`. `Timer` retirado
después. Ningún error de QML en ninguna comprobación.

**Nota**: el usuario pidió explícitamente no generar ni mandar ningún
zip nuevo hasta que lo pida — build compilado y verificado sin errores,
pero pendiente de empaquetar hasta recibir esa señal.

## Fase 16 — Quitado el botón "Configuración de actividad" del menú, y nuevo botón en Ajustes para ordenar los juegos (hecho)

Petición, con foto del botón en cuestión (círculo morado con icono de
lista): "Borra este boton y en ajustes créame un boto en el que yo
pueda ordenar el orden de los juegos en el menu".

**Identificado** (con ayuda de un agente de exploración): el botón era
`bar_activity_config.svg` en la barra del menú principal
(`Bar.qml`/`Menu.qml`), que alternaba un modo `clickMode: "play"` /
`"activityConfig"` — en ese segundo modo, tocar una actividad ya no la
abría, sino que enseñaba un diálogo para elegir su "dataset"/nivel
concreto (una función de GCompris de fábrica, poco relevante para esta
adaptación ya que casi todas las actividades complejas con datasets ya
se habían quitado del menú en fases anteriores).

**Quitado por completo** de `Menu.qml` (no solo escondido): la
propiedad `clickMode`, el `Loader` `chooseLevelLoader` y su
`DialogChooseLevel`, el banner morado "Activity Settings"
(`activityConfigTextBar`), la rama `else` de `selectCurrentItem()` que
abría ese diálogo, y el bit `activityConfig` en las dos `BarEnumContent`
de la barra del menú (`defaultContent`/`contentWithServerStatus`) junto
con su `onActivityConfigClicked`. **No se ha tocado `Bar.qml`** — el
botón "activityConfig" sigue existiendo como componente genérico y
sigue funcionando con normalidad en otras actividades que lo usan para
su propio panel de configuración (p. ej. número de deshacer); solo se
ha quitado su aparición concreta en la barra del menú principal.

**Nuevo: ordenar los juegos del menú**. Investigado primero (con otro
agente) cómo `ActivityInfoTree` expone la lista de actividades:
`menuTree` (la lista ya filtrada que ve el menú, sin setter propio,
recalculada desde cero por cada filtro) y `menuTreeFull` (la lista
COMPLETA sin filtrar, en el orden de `activities.txt`, constante). No
existe ninguna función en C++ para reordenar — se decidió NO tocar C++
(sería el primer cambio en C++ de toda esta adaptación, con más riesgo
y sin manera de probarlo tan a fondo como el QML) y en su lugar resolver
el reordenado enteramente por el lado QML:

- `Menu.qml` añade `applyMenuOrder(items)`: coge la lista que sea
  (`ActivityInfoTree.menuTree`) y la reordena según una lista guardada
  de nombres de actividad (cualquier actividad no guardada en esa lista
  —p. ej. una nueva— se añade al final, en su orden original, para que
  nunca desaparezca). El grid del menú (`activitiesGrid`) pasa de
  `model: ActivityInfoTree.menuTree` a `model: activity.orderedMenuTree`
  (una property que aplica `applyMenuOrder` en vivo), y el delegado
  ajusta su `activityInfoTreeItem: ActivityInfoTree.menuTree[index]` a
  `activity.orderedMenuTree[index]` para que el índice siga
  correspondiendo a lo que se ve en pantalla.
- El orden guardado se persiste con el mismo mecanismo ya usado para los
  récords (`ApplicationSettings.setCurrentLevels("menu-activity-order",
  [...])`/`currentLevels(...)`) — sin tocar C++ tampoco aquí.
- **`ReorderActivitiesPage.qml`** (nueva): pantalla completa a modo de
  lista con flechas ↑/↓ por fila (nada de arrastrar — más fiable de
  acertar con el dedo en la pantalla táctil que un "drag", seguimos el
  mismo criterio ya aplicado en Encaja bloques y las demás actividades
  nuevas). Cada flecha mueve la fila Y guarda el nuevo orden al momento
  (no hay un botón "Guardar" aparte, para no complicar la interacción).
  Copiada la estructura general de `ServerConfigPage.qml` (barra de
  título con aspa de cerrar, `Flickable` con `GCButtonScroll`), que ya
  existía en el menú para el mismo propósito (una pantalla completa
  encima de Ajustes).
- Botón nuevo en `ConfigurationItem.qml`: "Ordenar los juegos del menú",
  que hace `dialogConfig.visible = false; reorderActivitiesPage.visible
  = true;` — el mismo patrón exacto que ya usaba el botón existente de
  "Teacher's server config" para abrir `ServerConfigPage`. Esto funciona
  porque `ReorderActivitiesPage` se declaró como hijo directo de
  `DialogActivityConfig { id: dialogActivityConfig }` en `Menu.qml`
  (junto a `ServerConfigPage`), y `ConfigurationItem.qml` se instancia
  desde un `Component {}` escrito literalmente dentro de `Menu.qml` — la
  cadena de contexto de QML deja ver los ids de `Menu.qml` desde dentro
  del `ConfigurationItem` cargado dinámicamente, aunque sea otro
  fichero (comprobado que YA se usaba exactamente este mecanismo para
  `serverConfigPage`, así que no es un truco nuevo, es el patrón que
  ya existía).

**Verificado** con `--window` sin `--launch` (arranca directo en el
menú real, a diferencia de lanzar una actividad concreta) más un
`Timer` de diagnóstico temporal: 29 actividades activas de 36 totales
en `menuTreeFull`, `orderedMenuTree` coincide en longitud con
`menuTree` sin orden guardado, mover la 3ª actividad a la 1ª posición
desde `ReorderActivitiesPage` (`moveActivity`) se refleja correctamente
en el `ListModel`, se guarda bien en `ApplicationSettings`
(`currentLevels("menu-activity-order")[0]` pasó a ser esa actividad), y
volver a aplicar `applyMenuOrder` con ese ajuste guardado reproduce
exactamente el mismo orden — el `Timer` limpió el ajuste de prueba al
terminar (confirmado vacío después) y se quitó del código. Ningún error
de QML en ninguna comprobación.

**Corrección tras la primera prueba real**: el usuario reordenó los
juegos de verdad y mandó una foto — a todos les había desaparecido el
icono/foto grande (solo quedaban el título y las estrellitas de
dificultad, con el fondo de montañas asomando donde debería ir la
imagen). Causa: `ActivityInfoTree.menuTree` es un modelo especial de
QML (`QQmlListProperty&lt;ActivityInfo&gt;`, una lista de objetos C++) que
expone automáticamente cada propiedad del objeto activo del delegado
como si fuera una variable normal dentro del delegado — así, el código
original podía escribir simplemente `icon` o `favorite` a secas (sin
`activityInfoTreeItem.`) y funcionaba solo. Pero `activity.orderedMenuTree`
(la property nueva que aplica el orden guardado) es un **array de
JavaScript normal**, y los arrays de JavaScript usados como `model:` en
QML NO tienen esa magia de "cada propiedad se vuelve una variable
suelta" — solo dan acceso a `index` y `modelData`. Como resultado,
`icon` a secas ya no encontraba nada (imagen vacía = icono
desaparecido) y lo mismo le pasaba a `favorite`. **Se encontró además un
tercer caso más grave** del mismo problema, no visible en la foto
porque solo se dispara al tocar un icono: dentro de la función que
lanza la actividad (`selectCurrentItem()`) se pasaba `'levelFolder':
currentLevels` a secas — esto habría lanzado un `ReferenceError` real
(no solo un icono en blanco) en cuanto el usuario tocase cualquier juego
que hubiera sido reordenado, aunque solo se detectó leyendo el código
con cuidado, ya que mis comprobaciones automáticas de antes nunca
"tocaban" un icono de verdad. Arreglados los tres cualificando
explícitamente con `activityInfoTreeItem.` (`activityInfoTreeItem.icon`,
`activityInfoTreeItem.favorite` en los dos sitios donde se leía y donde
se escribía al marcar/desmarcar favorito, y
`activityInfoTreeItem.currentLevels`) — se repasó el resto del delegado
entero a mano para confirmar que ninguna otra propiedad se quedó sin
cualificar.

Verificado con `--window` (arranca en el menú real) más un `Timer` de
diagnóstico temporal que leyó `icon`/`favorite`/`currentLevels` de las 3
primeras actividades del **orden ya guardado de verdad por el usuario**
(sin necesidad de simular nada) — los tres salieron con valores válidos
y sin ningún error, p. ej. `icon=aplastatopos/aplastatopos.svg`. `Timer`
retirado después. Ningún error de QML en ninguna comprobación. El orden
guardado por el usuario en su prueba real se dejó intacto (no se tocó).

## Fase 17 — Quitado "Melodía", actividad nueva "Simon dice" (hecho)

Petición, con foto del juguete electrónico real: "Sabes el juego de
melodia pues quitalo y haz un simon dice busca en internet lo que
necessites saber de este juego".

**Quitada "melodía"** (xilófono musical) por completo: comprobado antes
con `grep` que ningún otro fichero dependía de su carpeta, borrada
entera (`src/activities/melody/`, 15 ficheros) y su línea comentada en
`activities.txt` con nota de por qué. (Nota técnica: al intentar borrar
la carpeta con PowerShell daba "en uso" — la sesión de Bash de este
mismo agente tenía esa carpeta como directorio de trabajo actual, que en
Windows basta para bloquear su borrado; un `cd` fuera de ella lo
resolvió.)

**Investigado primero** (con un agente de búsqueda) el juego real
"Simon" de Milton Bradley (1978) antes de programar nada, tal y como
pidió el usuario: secuencia que empieza en 1 color y crece de uno en
uno, repitiéndose ENTERA desde el principio en cada ronda (no solo el
color nuevo); un fallo termina la partida al momento, sin reintento; las
4 casillas tienen cada una su propio tono/nota distintos (verde
arriba-izquierda ~415 Hz, rojo arriba-derecha ~311 Hz, amarillo
abajo-izquierda ~252 Hz, azul abajo-derecha ~209 Hz); la velocidad de
reproducción se acelera un poco a partir de cierta longitud de
secuencia; existen versiones "junior" simplificadas (botones más
grandes, más tiempo de respuesta, sin subir de velocidad) pensadas para
niños pequeños, con la misma filosofía que esta adaptación para gente
mayor.

**Construida `simon/` desde cero**:
- 4 tonos sintetizados con Python (`tone_{green,red,yellow,blue}.wav`,
  ondas seno a esas mismas 4 frecuencias del juguete real, con ataque y
  caída suaves para que no suenen como un pitido brusco).
- El sonido de fallo reutiliza `crash.wav` del núcleo, igual que ya se
  hace en otras actividades de esta adaptación.
- **Sin límite de tiempo para responder** (a diferencia del juguete
  real, que da solo ~3 segundos) — decisión deliberada siguiendo la
  filosofía de toda esta adaptación de no meter prisa a gente mayor;
  documentado aquí como una libertad tomada, no un descuido.
- Los 4 cuadrantes de color en círculo se dibujan con un truco sin
  ambigüedad geométrica: en vez de arcos SVG/`Shape` (donde acertar el
  sentido de giro no se puede verificar sin ver la pantalla), cada
  cuadrante es un `Item` con `clip: true` que recorta una copia de UN
  MISMO círculo completo (mismo tamaño y posición absoluta en las 4
  copias) — por construcción, cada recorte muestra exactamente una
  cuarta parte sin solapes ni huecos, sin depender de banderas de arco
  que no se puedan comprobar aquí. El icono del menú (`simon.svg`) usa
  la misma idea con `<clipPath>` de SVG.
- **Verificación visual real, por primera vez en esta adaptación**: al
  guardar el SVG del icono, un hook de este entorno lo abrió solo en el
  panel del navegador y se pudo hacer una captura de pantalla real,
  confirmando que los 4 colores salen en el cuadrante correcto — la
  primera vez que se ha podido comprobar algo visualmente en todo este
  proyecto (normalmente solo se puede verificar leyendo logs). Un
  intento de maqueta HTML del tablero completo para comprobar también el
  diseño no funcionó (el visor de capturas no soporta bien ficheros
  fuera de la carpeta del proyecto), así que esa parte se quedó sin
  comprobar visualmente, solo por lógica.
- Lógica del juego (`simon.js`): secuencia completa se reproduce desde
  el principio cada ronda, con `Timer`s encadenados (`playbackTimer`
  para ir encendiendo/apagando cada color con su tono,
  `pressFlashTimer` para el destello breve al tocar,
  `nextRoundTimer` para la pausa antes de la ronda siguiente).
  Puntuación = longitud de secuencia alcanzada; récord persistido con
  `ApplicationSettings.setCurrentLevels("simon-highscore", ...)`, mismo
  mecanismo que las demás actividades nuevas. Añadida también esa clave
  al botón "Reiniciar récords de las actividades" en Ajustes (para no
  repetir el olvido de la Fase 13 con Encaja bloques).

**Verificado** con `--launch simon` (arranca solo, sin botón de
Iniciar) más un `Timer` de diagnóstico temporal que forzó una secuencia
conocida y simuló: un acierto (avanza de ronda, la secuencia crece de 1
a 2), un fallo deliberado (termina la partida con la puntuación y el
récord correctos), y `newGame()` (reinicia bien). Los cinco resultados
coincidieron exactamente con lo esperado. También se relanzó el menú
principal entero (`--window` sin `--launch`) para confirmar que
"melodía" desaparecida y "Simon dice" nueva conviven sin errores con el
resto de actividades y con el orden personalizado ya guardado por el
usuario. Ningún error de QML en ninguna comprobación.

**Corrección de volumen**: el usuario probó los tonos y salían muy
bajitos. Los 4 `.wav` se regeneraron con el mismo script de Python
subiendo la amplitud de la onda de 0.55 a 0.95 (de un máximo de 1.0,
sin llegar a saturar) — un aumento de sonoridad de cerca de +4.4 dB.
No se ha tocado el volumen general de efectos de sonido de la app
(`ApplicationSettings.audioEffectsVolume`, del que `GCSoundEffect`
depende siempre) porque eso afectaría a TODAS las actividades, no solo
a esta — la queja era específica de Simon, así que se subió solo el
propio sonido grabado. Verificado que compila y arranca sin errores;
no se puede comprobar el volumen real de otro modo desde este entorno
sin altavoces reales.

## Fase 18 — Actividad nueva "Diana" (hecho)

Petición: "crear un juego con una diana gigante con diferentes franjas
de colores y puntos, para que los abuelos tiren una pelota pequeña
intenten tirarla al centro, a la derecha donde no esté la diana pon la
puntuación, sin límite de tiempo".

**Interacción**: tocar el sitio de la diana donde se quiera tirar
lanza la pelota ahí — no hace falta arrastrar ni "apuntar y soltar"
(complicaría la precisión táctil sin aportar nada, siguiendo el mismo
criterio de simplicidad que el resto de esta adaptación). Para que
siga pareciendo un tiro de verdad y no "toca donde quieras y aciertas
siempre", cada tiro tiene una pequeña dispersión aleatoria alrededor
del punto tocado (`SCATTER_FACTOR = 0.06`, un 6% del radio de la diana)
— se puede apuntar al centro y casi siempre acertar cerca, pero no con
precisión perfecta, como un tiro real.

**5 franjas de color y puntos** (esquema clásico de diana de tiro con
arco): blanco=10, negro=20, azul=30, rojo=40, dorado (centro)=50 — con
el número de puntos impreso dentro de cada franja, en el radio de
abajo, para que siempre se vea claro cuánto vale cada color sin tener
que memorizarlo. Los anillos se dibujan con el mismo truco sin
ambigüedad ya usado para "Simon dice": un `Repeater` va pintando
círculos completos de mayor a menor tamaño, cada uno encima del
anterior — sin arcos ni recortes, cero riesgo de que salga mal sin
poder verlo.

**Sin límite de tiempo real**: la puntuación ("Puntos") es un total que
se va sumando tiro tras tiro sin ningún reloj ni ronda — se puede
tirar tantas veces como se quiera, sin ninguna prisa. El botón de
recargar de la barra de abajo pone el total a cero para empezar una
tanda nueva, guardando el récord (la tanda con más puntos conseguida
nunca) igual que en las demás actividades de esta adaptación.

**Puntuación a la derecha, diana a la izquierda**: la diana ocupa toda
la zona izquierda/central disponible (lo más grande posible dado el
hueco reservado a la derecha para "Puntos"/"Récord"), tal y como pidió
el usuario explícitamente en vez del HUD arriba que usan las demás
actividades.

**Verificado**, con el mismo método de siempre más una comprobación
extra posible esta vez: al guardar el icono del menú (`diana.svg`, la
misma diana clásica en miniatura) y la pelota (`resource/ball.svg`, con
sombreado 3D y sombra), el hook de este entorno los abrió solos en el
panel del navegador y se pudieron ver ambos correctamente con una
captura de pantalla real — segunda vez en esta adaptación (tras el
icono de Simon) que se ha podido verificar algo visualmente. La lógica
del juego (`diana.js`) se comprobó con `--launch diana` más un `Timer`
de diagnóstico temporal: las 7 fronteras exactas entre franjas dieron
la puntuación correcta (0/10/20/30/40/50 exactamente donde debían), la
dispersión aleatoria se mantuvo dentro del límite esperado en 200
pruebas, el bloqueo para no poder tirar dos pelotas a la vez mientras
la anterior sigue "en el aire" funcionó, y reiniciar sesión puso el
marcador a cero correctamente. `Timer` retirado después. Se añadió
también `"diana-highscore"` al botón de "Reiniciar récords" en Ajustes.
Ningún error de QML en ninguna comprobación.

**Corrección importante tras aclarar el usuario cómo se usa de verdad**:
"la pelota es real que les doy yo y ellos la tiran y el marco IR la
detecta" — es decir, no es un juego de "toca la pantalla para simular
un lanzamiento": es una pelota física de verdad, el cuidador se la da
al abuelo, la tira contra la pantalla táctil, y el marco IR detecta el
impacto real exactamente como si fuera un toque normal. Esto cambiaba
dos cosas de fondo respecto a la primera versión:

1. **Quitada la dispersión aleatoria** (`SCATTER_FACTOR`) que se había
   añadido en la primera versión para que "no se acertara siempre
   tocando el centro" — con una pelota de verdad esa imprecisión ya la
   pone el propio lanzamiento físico; añadir encima una dispersión
   inventada por software habría hecho que un acierto real en el centro
   pudiera puntuar como si hubiera fallado, lo cual habría sido
   confuso e injusto de cara al abuelo que sí acertó de verdad. Ahora
   el punto de impacto que reporta el marco IR se usa tal cual, sin
   modificarlo.
2. **Zona de detección ampliada a toda la pantalla de juego** (antes
   solo un margen alrededor de la diana): si la pelota real falla del
   todo y golpea la pantalla lejos de la diana, debe registrarse igual
   como fallo (0 puntos) en vez de no hacer nada, porque es un
   lanzamiento real que de verdad ha pasado.

También pidió "la diana en medio del todo": se cambió de estar anclada
a la izquierda a quedar centrada en toda la pantalla de juego
(`anchors.centerIn: playArea`), calculando su tamaño a partir de la
altura disponible (la dimensión que manda en una pantalla apaisada) en
vez de restarle el ancho del panel de puntuación — con una diana tan
grande sigue sobrando margen de sobra a la derecha para "Puntos"/
"Récord" sin necesidad de competir por el centrado.

La marca visual que aparece al impactar dejó de simular "una pelota que
llega volando" (crecía desde pequeña con un rebote `OutBack`) y pasó a
ser un sello/marca instantánea justo en el punto de impacto real (un
`Easing.OutQuad` rápido, sin crecer desde cero) — más honesto con lo
que realmente pasa: la pelota YA ha llegado de verdad cuando el
software se entera.

**Verificado** con `--launch diana` más un `Timer` de diagnóstico
temporal: el centro de la diana coincide con el centro de la pantalla
de juego (930.68,407.68) frente a (931,408) — diferencia de redondeo
insignificante —, sobra margen de sobra a la derecha (540px libres
frente a 372px que necesita el panel de puntuación), un impacto
simulado justo en el centro puntuó 50 como se esperaba, y un impacto
simulado lejos de la diana (cerca de una esquina de la pantalla) se
registró correctamente como fallo (0 puntos) en vez de ignorarse.
`Timer` retirado después. Ningún error de QML en ninguna comprobación.

## Fase 19 — Ajustes visuales de "Simon dice" (hecho)

Petición, con foto del centro de la diana: "Quita estas letras donde
pone simon dice y cuando se ilumine 1 haz que brille mas".

- **Quitado el texto "SIMON DICE"** del centro del tablero — solo queda
  el número de ronda actual, ahora más grande (`hugeSize * 1.4`) ya que
  tiene todo el círculo central para él solo.
- **Los colores brillan más al encenderse**, con dos efectos que se
  suman al simple cambio de color que ya había:
  1. Un destello blanco semitransparente (opacidad 0.5) superpuesto
     encima del color de cada casilla mientras está encendida — se
     nota mucho más que un color ligeramente distinto.
  2. El borde del aro negro exterior (el bisel decorativo alrededor de
     las 4 casillas) se ilumina con el MISMO color que la casilla
     encendida en ese momento — da sensación de que la luz "se
     desborda" un poco más allá de la propia casilla, en vez de quedar
     encerrada dentro de su cuarto de círculo.

**Verificado** con `--launch simon` más un `Timer` de diagnóstico
temporal que forzó `items.litPad` a un valor conocido (rojo) y
comprobó, DESPUÉS de esperar a que terminara la animación de 80ms (los
cambios de borde/opacidad usan `Behavior`, así que leerlos en el mismo
instante habría dado el valor antiguo, no el nuevo) — el borde exterior
pasó correctamente de ancho 0 a ancho 17.4 con el color rojo exacto de
esa casilla, y volvió a 0 al apagarse. Ningún error de QML en ninguna
comprobación.

## Fase 20 — Diana: turnos de 3 tiros, espera de 5 segundos, quitado el récord (hecho)

Petición, con foto del badge "Récord": "haz que despues de un tiro
tarde 5 seg en poder hacer otro pon que 1 turno sean 3 lanzamientos y
quita el record de ese juego que no sirve".

- **Espera obligatoria de 5 segundos entre tiros**: no contradice el
  "sin límite de tiempo" pedido en la Fase 18 — aquella petición era
  sobre no meter prisa para DECIDIR cuándo tirar (pensar todo el tiempo
  que haga falta antes del lanzamiento); esta espera es DESPUÉS de
  tirar, mientras alguien va a buscar la pelota real y la trae de
  vuelta — encaja con el propio uso físico del juego, no lo contradice.
- **Un turno son 3 tiros**: al completar el tercero aparece una
  pantalla de "¡Turno terminado!" con los puntos conseguidos y un botón
  "Nuevo turno" — no hay ninguna cuenta atrás forzando a empezar el
  turno siguiente, se empieza cuando se quiera tocando el botón.
- **Quitado el récord** por completo: ya no tiene sentido con turnos de
  3 tiros en vez de una sesión libre — se quitó la property
  `highScore`, la carga/guardado en `ApplicationSettings`
  (`"diana-highscore"`), el badge correspondiente, y esa misma clave
  del botón de "Reiniciar récords" en Ajustes. El panel de la derecha
  ahora muestra los puntos del turno actual y "Tiro X de 3"; mientras
  dura la espera de 5 segundos aparece además un aviso "Espera Xs…"
  bajo esos datos.

**Error real encontrado y corregido durante la propia verificación**:
al reescribir el fichero para quitar la carga del récord, se borró por
error el `Component.onCompleted` ENTERO — que además de cargar el
récord (ya no necesario) también conectaba las señales `activity.start`/
`activity.stop` a las señales locales `start`/`stop` de las que dependen
TODOS los `onStart:`/`onStop:` de la actividad. Sin esa conexión, el
juego nunca llegaba a arrancar de verdad (`Activity.start()` nunca se
llamaba), y cualquier intento de tirar daba un `TypeError` real
(`Cannot read property 'locked' of undefined`) porque la variable
interna `items` del `.js` nunca se llegaba a inicializar. Se detectó
exactamente porque el primer intento de comprobación con el `Timer` de
diagnóstico falló con ese error en el log — recordatorio de que, al
quitar código de un bloque, hay que revisar si ese bloque hacía ALGO
MÁS aparte de lo que se quería quitar. Se corrigió dejando el
`Component.onCompleted` solo con la conexión de señales.

**Verificado** con `--launch diana` más un `Timer` de diagnóstico
temporal (tras corregir el error de arriba): tiro 1 en el centro dio 50
puntos y bloqueó nuevos tiros; un segundo tiro mientras seguía
bloqueado se rechazó correctamente; `throwFinished()` inició la cuenta
atrás en 5; forzando 5 "ticks" de la cuenta atrás (sin esperar 5
segundos reales) el bloqueo se liberó exactamente como se esperaba;
tiro 2 en el anillo de 20 puntos sumó bien (70 en total); tiro 3
(fallo deliberado, 0 puntos) completó el turno (`turnComplete=true`,
70 puntos finales); un cuarto intento de tiro tras terminar el turno se
rechazó; y `Activity.newTurn()` reinició todo correctamente. También se
relanzó el menú principal entero para confirmar que no se rompió nada
más. Ningún error de QML en ninguna comprobación final.

## Fase 21 — Quitado el brillo del aro exterior de Simon, número más grande, y menú sin estrellitas (hecho)

Petición, con foto del centro de Simon (número "3") y foto de una tira
de casillas del menú con estrellitas y una insignia en forma de sol:
"Quita que se ilumine el aro de fuera porque despista y haz los
numeros mas grandes. Y quita las estrelitas de los juegos del menu".

- **Quitado el brillo del aro exterior** de Simon dice — el borde que
  se iluminaba del color de la casilla encendida (añadido en la Fase
  19) se ha revertido a un aro negro fijo, sin animación. Se mantiene
  el destello blanco sobre la propia casilla encendida, que no se
  quejó de ese.
- **Número central más grande**: en vez de un tamaño fijo
  (`hugeSize * 1.4`), ahora usa `fontSizeMode: Text.Fit` dentro de una
  caja del 80% del círculo central (ancho y alto) con un tamaño de
  partida enorme (`hugeSize * 3`) — así ocupa siempre el máximo posible
  dentro del círculo, sea el número de 1 o de 2 cifras, sin necesidad
  de ajustar el multiplicador a mano.
- **Quitadas las estrellitas y demás insignias de las casillas del
  menú**: las dos fotos del segundo mensaje mostraban, en cada casilla,
  una estrellita de dificultad (arriba a la izquierda del icono) y una
  insignia en forma de sol/estrella de favorito (arriba a la derecha,
  visible porque `sectionVisible=true` en los ajustes). Ninguna de las
  dos tenía ya sentido en esta adaptación: la dificultad no aporta nada
  cuando el menú es una lista ya fija y elegida a mano, y marcar
  favoritos tampoco sirve de nada desde que la barra de categorías
  (donde estaría la pestaña de favoritos) está permanentemente oculta.
  Se quitaron del todo: los 3 iconos de dificultad mínima/máxima con su
  separador, la insignia de "actividad nueva", y el icono+`MouseArea`
  de marcar/desmarcar favorito — cada casilla del menú ahora muestra
  solo el icono del juego y su título, sin nada más encima.

**Verificado** con `--launch simon` y con el menú principal completo
(`--window` sin `--launch`), ambos sin errores de QML. El
`fontSizeMode: Text.Fit` del número es un patrón ya usado con
confianza en el resto del proyecto (título de las casillas del menú,
textos de aviso, etc.), así que no hizo falta un diagnóstico aparte
para confirmar que funciona.

## Fase 22: Aplastatopos, rebajar la rampa de dificultad

Petición: "Haz que en el juego de los topos no suba tanto la velocidad
porque los abuelos no podran darle." La dificultad progresiva de
`aplastatopos.js` (a lo largo de los 60s de la ronda) subía demasiado:

- El hueco entre topos bajaba de 1300ms a 500ms (más del doble de
  rápido al final).
- El tiempo que cada topo quedaba arriba bajaba de 1700ms a solo
  800ms, insuficiente para localizarlo y golpearlo con reflejos de
  persona mayor.
- La probabilidad de que salieran dos topos a la vez subía hasta el
  35% cerca del final, lo que obliga a repartir la atención entre dos
  agujeros.

Se ha suavizado la rampa en las tres variables (`scheduleNextMole()` y
`spawnMole()` en `src/activities/aplastatopos/aplastatopos.js`), de
forma que el juego se sigue poniendo un poco más difícil según avanza
la ronda, pero sin llegar a un ritmo excesivo:

- Hueco entre topos: de 1300ms a 1000ms (antes 500ms).
- Topo arriba: de 1700ms a 1300ms (antes 800ms).
- Probabilidad de doble topo: de 0% a 15% (antes 35%).

**Nota de compilación**: en este equipo, tras reiniciar la sesión,
`cmake` y las herramientas de `gettext` (`msgattrib`, usadas solo para
regenerar las traducciones `.qm`) habían dejado de estar en el `PATH`
del shell. `cmake` se soluciona añadiendo `C:\Qt\Tools\CMake_64\bin` al
`PATH` de la sesión de turno. Para `msgattrib` (target por defecto
`all`) no hizo falta arreglarlo: alcanza con compilar el target
`binaries` (`cmake --build . --target binaries -j 8`) en vez de `all`,
que reconstruye el ejecutable y los `.rcc` de las actividades sin tocar
las traducciones.

**Verificado** con `--launch aplastatopos --window --software-renderer`,
sin errores de QML/JS (solo el ruido de arranque ya conocido).

## Fase 23: eliminar "Caja de equilibrio" (balancebox)

Petición: "Elimina el juego caja de equilibrio y crea un zip que
funcione." Se ha quitado por completo la actividad `balancebox`:

- Borrada la carpeta `src/activities/balancebox/` entera (incluido su
  editor de niveles).
- Comentada la línea `balancebox` en `src/activities/activities.txt`.
- No usaba ninguna clave de puntuación propia (`ApplicationSettings`),
  así que `ConfigurationItem.qml` no necesitaba cambios.
- La actividad `maze` (ya oculta del menú, `enabled: false`) se
  mantenía compilada solo porque `balancebox/Balancebox.qml` reutilizaba
  su imagen de fondo (`maze/resource/maze_bg.svg`). Al desaparecer ese
  único motivo, se ha actualizado el comentario de
  `src/activities/maze/ActivityInfo.qml` para no dejar una explicación
  obsoleta (`maze` se deja compilado igualmente, sin más cambios: no es
  parte de lo pedido y no hace daño mantenerlo).

**Reconfiguración necesaria**: al quitar una carpeta con su propio
`CMakeLists.txt` (`add_subdirectory` en
`src/activities/CMakeLists.txt` viene generado automáticamente a
partir de `activities.txt`), hace falta un `cmake .` completo antes de
compilar, no basta con `cmake --build`. Después, compilar solo el
target `binaries` (ver Fase 22) regenera `activities.rcc` y `maze.rcc`
sin tocar las traducciones.

Como en cambios anteriores de actividades, ninja deja un `.rcc`
obsoleto (`balancebox.rcc`) en `build/share/GCompris/rcc/` porque ya
no hay ninguna regla que lo borre — se ha eliminado a mano antes de
sincronizar la carpeta portable.

**Zip portable**: se ha regenerado sincronizando
`build/share/GCompris/rcc` → `gcompris-portable/share/GCompris/rcc`
con `robocopy /MIR` (que además purga los `.rcc` obsoletos del lado
portable) y comprimiendo de nuevo con `Compress-Archive`. El
`GCompris.exe` no cambia de contenido (mismo hash SHA-256 que antes),
ya que esta actividad no tenía código C++ propio.

**Verificado** con `--window --software-renderer` (menú completo, sin
`--launch` porque la actividad ya no existe), sin errores de QML/JS.
Nota: la configuración del usuario (`GCompris.conf`) todavía menciona
`balancebox` en `menu-activity-order`, en `[Favorite]` y tiene una
sección `[balancebox]` con su progreso guardado — son datos propios
del usuario, no se han tocado; el propio `Menu.qml` (función
`applyMenuOrder`) ya ignora sin problema las entradas de actividades
que ya no existen, comprobado en este mismo arranque.

## Fase 24: el zip portable no arrancaba (estructura de carpetas incorrecta)

Aviso: "no me deja abrir gcompris con los ultimos dos zips no aparecen
los dos apartados ni BIN ni el otro, descomprimo el zip abro el juego
y no se abre nada."

**Causa encontrada**: la carpeta `gcompris-portable/` (usada para
armar los dos últimos zips) tenía `GCompris.exe` suelto en la raíz,
con `share/` como subcarpeta directa suya. Pero el propio código de
GCompris (`ApplicationInfo::getFilePath()` en
`src/core/ApplicationInfo.cpp`, con `GCOMPRIS_DATA_FOLDER` fijado en
tiempo de compilación a `../share/GCompris` para Windows en
`src/core/config.h.in`) busca sus recursos (`rcc`) en
`<carpeta_del_exe>/../share/GCompris/rcc/`, es decir, **exige que el
.exe esté un nivel por debajo de `share`**, normalmente dentro de una
carpeta `bin`. Con la estructura plana, ese "un nivel arriba" caía
fuera de la carpeta portable entera, así que en la práctica el .exe
NUNCA leía los recursos de `gcompris-portable/share/` — cuando por
casualidad SÍ arrancaba sin error en este PC era porque, al probarlo
sin salir de esa carpeta, esa ruta ".." coincidía con la instalación
oficial vieja de GCompris que hay en la raíz de `GCompris-Qt/share`
(anterior a toda esta adaptación). En cualquier otro sitio (como al
descomprimir el zip en el PC del usuario) esa carpeta no existe y
falla con "Failed to load the resource file ... core.rcc / menu.rcc /
activities.rcc" — sin ninguna ventana visible, tal como describía el
aviso.

**Solución**: se ha reorganizado `gcompris-portable/` metiendo el
.exe, todas las DLLs y las carpetas de plugins de Qt (`platforms`,
`imageformats`, `qml`, etc.) dentro de una subcarpeta `bin/`, dejando
`share/` como hermana de `bin/` (igual que la propia carpeta de
compilación `build/bin` + `build/share` que se usa para probar en este
PC, y que coincide con la estructura de la instalación oficial vieja:
por eso el usuario esperaba ver "bin" al abrir el zip). El zip se ha
vuelto a generar comprimiendo `bin/` y `share/` directamente (sin
carpeta contenedora), así que al descomprimirlo aparecen esas dos
carpetas sueltas.

**Verificado de extremo a extremo**, no solo en la carpeta de
siempre: se ha descomprimido el zip nuevo en una ubicación totalmente
distinta (`Desktop\zip_test_extract2`, fuera del proyecto) y se ha
arrancado `bin\GCompris.exe` desde ahí, sin ningún error de carga de
recursos (solo el ruido de arranque ya conocido). Antes de este fallo,
ninguno de los zips de esta sesión se había probado así — se
verificaban solo con `--launch`/`--window` desde `build/bin`, que
nunca podía revelar este problema porque usa su propia carpeta
`build/share` correctamente emparejada. A partir de ahora, cualquier
zip nuevo debe probarse descomprimiéndolo en una carpeta ajena al
proyecto antes de darlo por bueno.

## Fase 25: la aplicación volvió a estar en inglés, topos y frutas

Tres peticiones: "La aplicacion vuelve a estar en ingles arreglalo.
Aumenta un poco lo que duran los topos en pantalla. En el juego caida
de frutas aumenta el tamaño de las frutas."

**Por qué se puso en inglés** (efecto secundario de la Fase 24): al
probar el zip roto (antes de arreglar la carpeta `bin`/`share`),
`core.rcc` no cargó — y `LanguageList.qml` vive dentro de `core.rcc`.
`ApplicationInfo::loadTranslation()`
(`src/core/ApplicationInfo.cpp:355`) construye la lista de idiomas
soportados instanciando ese mismo QML; al no poder cargarlo, la lista
salió vacía, así que CUALQUIER idioma (incluido `es_ES.UTF-8`) se
consideró "no soportado" y el código cayó al idioma "system", **y lo
guardó permanentemente** en la configuración
(`ApplicationSettings::getInstance()->setLocale(locale)` en esa misma
función) — la configuración es un único archivo compartido por
cualquier copia del juego que se ejecute, así que esa prueba rota dejó
"grabado" `locale=system` para siempre, no solo para esa sesión. Con
la carpeta portable ya arreglada esto no debería repetirse, pero se ha
corregido el valor a mano en
`%LOCALAPPDATA%\GCompris\GCompris.conf` (`locale=es_ES.UTF-8`) y se ha
comprobado en el log de arranque que ahora sí reconoce
`"locale", "es"` sin ningún aviso de "no soportado".

**Topos más lentos (otra vez)**: en `aplastatopos.js`, el tiempo que
cada topo aguanta arriba (`upDuration` en `spawnMole()`) se ha subido
de 1700ms→1300ms (Fase 22) a **2000ms→1600ms**.

**Frutas más grandes en "Lluvia de comida"** (`atrapamanzanas`, el
juego de la cesta atrapando comida que cae — no `fruitslice`/"Corta la
fruta", que es otro juego distinto): en
`AtrapaManzanas.qml`, `appleSize` ha pasado de
`Math.max(64, playArea.width * 0.05)` a
`Math.max(96, playArea.width * 0.075)` — unas 1.5 veces más grande.

**Zip regenerado** con `bin`/`share` en la raíz (Fase 24) y, esta vez,
sincronizando también `share/GCompris/translations` (antes solo se
sincronizaba `rcc`) — la carpeta portable nunca había llevado las
traducciones, así que aunque `es_ES.UTF-8` se reconociera bien, sin
`gcompris_qt_es.qm` los textos de la interfaz general (los que no son
de nuestras actividades propias) habrían salido en inglés igualmente.
Verificado extrayendo el zip en una carpeta nueva y arrancando desde
ahí: sin errores, `locale=es_ES.UTF-8` se mantiene después de cerrar
el juego.

## Fase 26: nivel nuevo y más lento en Aplastatopos y Lluvia de comida

Petición: "En los juegos de aplasta topos y el cesto de la comida crea
un nivel mas en el nivel 1 baja bastante la velocidad del juego en la
que se va el topo y lo rapido que cae la fruta."

**Lluvia de comida** (`atrapamanzanas`) ya tenía un sistema de 3
niveles (`levelProperty` en `atrapamanzanas.js`) y arranca siempre en
el nivel 1 (`Core.getInitialLevel` empieza en 0 salvo argumento de
línea de comandos, que aquí no se usa) — es decir, el usuario ya
estaba jugando siempre con el nivel más lento de los 3 que había, y
aun así le parecía rápido. Se ha añadido un nivel 1 nuevo, bastante
más lento, delante de los 3 que había (que pasan a ser niveles 2-4):
caída de la fruta `fallStart`/`fallEnd` de 2900-1450ms a 3600-2200ms,
y separación entre frutas `gapStart`/`gapEnd` de 1600-700ms a
2000-1200ms.

**Aplastatopos** no tenía ningún sistema de niveles (la barra inferior
solo tenía ayuda y inicio). Se le ha añadido uno completo, copiando el
patrón ya usado en `atrapamanzanas` (mismo `Core.getInitialLevel` /
`getNextLevel` / `getPreviousLevel` de `core.js`, mismas propiedades
`currentLevel`/`numberOfLevel` sincronizadas con `activity.*`, mismo
`level` + flechas en `BarEnumContent`). Dos niveles: el nivel 2 es
exactamente la velocidad que ya había (para no perder el ajuste de las
Fases 22 y 25); el nivel 1, nuevo y bastante más lento, sube el tiempo
que el topo aguanta arriba (`upStart`/`upEnd`) de 2000-1600ms a
2600-2200ms, y el hueco entre topos (`gapStart`/`gapEnd`) de
1300-1000ms a 1800-1500ms. Arranca en el nivel 1 por defecto, igual
que `atrapamanzanas`.

**Verificado** con un `console.warn` temporal en el `start()` de cada
actividad confirmando `numberOfLevel`/`currentLevel` exactos
(aplastatopos: 2 niveles, empieza en el 0 → "Nivel 1"; atrapamanzanas:
4 niveles, empieza en el 0 → "Nivel 1"), quitado antes de la
compilación final. Lanzados ambos con `--launch`/`--window` y el menú
completo, sin errores. Zip regenerado, sincronizado y comprobado de
nuevo extrayéndolo en una carpeta ajena al proyecto.

## Fase 27: frutas más lentas y grandes en Corta la fruta, y más grandes en Lluvia de comida

Petición: "En el juego de corta fruta haz que vayan bastante mas lento
y aumenta el tamaño de las frutas en el corta frutas y en el juego del
cesto, ni hagas zips todavia." (sin zip esta vez, según lo pedido).

**Corta la fruta** (`fruitslice.js`):
- Velocidad: la gravedad que rige el arco de la fruta baja de `H * 1.3`
  a `H * 0.55` (H = alto de la zona de juego). Al ser menor la
  gravedad, con la misma altura de pico (`peakHeight`, sin tocar) la
  fruta necesita menos velocidad de lanzamiento Y tarda más en caer —
  ambas cosas a la vez, con una sola constante. El movimiento
  horizontal ya se calculaba a partir del tiempo de vuelo, así que
  también se ralentiza solo, sin tocarlo aparte.
- Tamaño: las medidas base de `fruitTypes` suben todas ~30% (ej.
  manzana de 120x120 a 155x155, plátano de 145x90 a 190x115). El
  escalado aleatorio adicional por cada fruta que ya existía
  (`sizeScale`, hasta +60%) se mantiene igual encima de estas medidas
  mayores.

**Lluvia de comida** (`atrapamanzanas`): `appleSize` en
`AtrapaManzanas.qml` sube otra vez, de `Math.max(96, ancho*0.075)`
(Fase 25) a `Math.max(130, ancho*0.1)`.

**Verificado** con `--launch fruitslice` y `--launch atrapamanzanas`,
sin errores de QML/JS. **No se ha regenerado el zip** (pedido
explícito de esperar).

## Fase 28: en Corta la fruta, algunas frutas seguían yendo muy rápido

Aviso: "En el corta frutas todavia hay algunas frutas que van muy
rapido."

**Causa**: las frutas que salen por los laterales (izquierda/derecha,
un 40% del total — ver `edgeRoll` en `spawnFruit()` de
`fruitslice.js`) calculaban su velocidad horizontal como (distancia
hasta un punto casi al otro lado de la pantalla) ÷ (tiempo de vuelo).
Al bajar la gravedad en la Fase 27 para que todas las frutas cayeran
más despacio, el tiempo de vuelo subió, pero la distancia a cruzar
seguía siendo casi toda la pantalla — así que su velocidad horizontal
apenas cambió, mientras que las frutas que salen por abajo (60%, con
una deriva lateral pequeña y fija) sí se notaban más lentas. Resultado:
las laterales se quedaron destacando como "las rápidas".

**Solución**: en vez de calcular la velocidad como distancia ÷ tiempo
de vuelo (lo que la hace depender de cuánto tarde esa fruta en concreto
en caer), las frutas de los laterales ahora reciben directamente una
velocidad horizontal limitada (`vx = W * (0.07 + Math.random() * 0.06)`,
con signo según el lado), igual que ya hacían las de abajo. Así ninguna
fruta puede salir "disparada" solo por tener que recorrer más pantalla
en el mismo tiempo.

**Verificado** con `--launch fruitslice`, sin errores de QML/JS. Sigue
sin regenerarse el zip.

## Fase 29: nuevo nivel en Corta la fruta, un poco más rápido

Petición: "Añade un nivel mas sumando un poco mas la velocidad de las
frutas, en el juego de cortar la fruta."

**`fruitslice.js`**: `levelProperty` pasa de tener 1 nivel a 2. Se
añade un campo nuevo, `speedFactor` (1.0 en el nivel 1, 1.2 en el
nivel 2), que multiplica la gravedad (`gravity`, controla tanto la
velocidad de lanzamiento como la de caída del arco) y la velocidad
horizontal de las frutas que salen por los laterales (`vx` en la rama
izquierda/derecha de `spawnFruit()`). `spawnInterval`, `target` y
`doubleChance` quedan iguales en ambos niveles — solo cambia la
velocidad de la fruta, tal y como se pidió.

`initLevel()` ahora también lee `speedFactor` del nivel actual y lo
guarda en `items.speedFactor` (nueva `property real speedFactor: 1.0`
en `FruitSlice.qml`).

**Navegación entre niveles**: la barra sigue sin botones de nivel (se
quitaron a propósito cuando solo había 1 nivel, ver Fases previas). No
hacía falta añadirlos: `Bonus.win` ya está conectado a
`activity.nextLevel()`, así que al completar el objetivo de frutas de
un nivel se pasa automáticamente al otro, y con `numberOfLevel = 2`
(`Core.getNextLevel`) el juego simplemente cicla entre nivel 1 y nivel
2 cada vez que se completa uno. Comentario de `FruitSlice.qml`
actualizado para reflejar esto.

**Verificado** con `--launch fruitslice --window --software-renderer`
tras una recompilación completa (`cmake --build .`, sin necesidad de
reconfigurar porque no se añadió ningún `.qml` nuevo): sin errores de
QML/JS, solo los warnings preexistentes de `banana.svg` (ajenos a este
cambio). No se ha regenerado el zip.

**Corrección a la Fase 29**: tras confirmar por código que el cambio de
nivel funcionaba (nivel 0→1 y `speedFactor` 1.0→1.2 verificados con un
`Timer` de depuración temporal, luego retirado), el usuario pidió
explícitamente mostrar las flechas de nivel en la barra — igual que ya
tienen "Lluvia de comida" y "Aplastatopos" — para poder ver/confirmar
en qué nivel está, en vez de que el cambio sea silencioso. Se añadió a
`FruitSlice.qml`, mismo patrón que esas dos actividades:
```
Bar {
    id: bar
    level: items.currentLevel + 1
    content: BarEnumContent { value: help | home | level }
    onPreviousLevelClicked: Activity.previousLevel()
    onNextLevelClicked: Activity.nextLevel()
    ...
}
```
Con esto la barra ya muestra `< 1 >` / `< 2 >` y permite cambiar de
nivel a mano en cualquier momento (no solo automáticamente al terminar
el objetivo), igual que en el resto de actividades multi-nivel del
proyecto. Verificado con `--launch fruitslice`, sin errores.
