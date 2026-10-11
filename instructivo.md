# Instructivo: cómo armar la app Fijos Translate

Esta app se hace con **Flutter (Dart)**. Usa el micrófono para escuchar, **Google ML Kit** para traducir (la traducción se hace dentro del celular, sin API key ni tarjeta) y lee la traducción en voz alta. La idea general es un ciclo:

**Persona A habla → se convierte a texto → se traduce → se escucha en el idioma de Persona B → y al revés.**

> ℹ️ No hace falta usar Google Cloud Console ni crear ninguna API Key.

---

## Paso 0 — Instalar lo necesario

1. **Flutter SDK**: bajalo de flutter.dev e instalalo. Al final corré `flutter doctor` en la terminal — te dice qué falta.
2. **Android Studio**: aunque programemos en VS Code, lo necesitamos porque trae el Android SDK (para poder instalar la app en un celular).
3. **VS Code**: instalá las extensiones **Flutter** y **Dart** (buscalas en el marketplace de VS Code; la de Dart se instala sola).

---

## Paso 1 — Crear el proyecto

En la terminal:

```bash
flutter create fijos_translate
cd fijos_translate
code .
```

Carpetas importantes:
- `lib/main.dart` → acá va todo nuestro código.
- `pubspec.yaml` → acá se declaran las librerías (paquetes) que usa la app.

---

## Paso 2 — Agregar las librerías

En la terminal, dentro de la carpeta del proyecto:

```bash
flutter pub add speech_to_text flutter_tts google_mlkit_translation
```

Este comando agrega los tres paquetes al `pubspec.yaml` (con la versión más nueva) y los descarga. Si ya habían agregado `http` o `permission_handler` en una versión anterior de esta guía, borren esas líneas del `pubspec.yaml`: ya no se usan.

Qué hace cada una:
- `speech_to_text`: escucha el micrófono y devuelve lo que se dijo, como texto.
- `flutter_tts`: lee un texto en voz alta.
- `google_mlkit_translation`: traduce texto directamente en el celular.

---

## Paso 3 — Permisos de Android

Android no deja usar el micrófono si la app no lo declara. Abrí `android/app/src/main/AndroidManifest.xml` y agregá estas líneas **dentro de `<manifest>`**, antes de `<application ...>`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>

<queries>
    <intent>
        <action android:name="android.speech.RecognitionService"/>
    </intent>
</queries>
```

- `RECORD_AUDIO`: permiso para usar el micrófono.
- `INTERNET`: para bajar los idiomas la primera vez.
- `<queries>`: le permite a la app encontrar el servicio de reconocimiento de voz del celular.

Si al correr la app aparece un error que menciona `minSdkVersion`, abrí `android/app/build.gradle` (o `build.gradle.kts`) y subí el valor de `minSdk` al número que pida el error.

---

## Paso 4 — Pantalla base

Reemplazá el contenido de `lib/main.dart` por esto:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fijos Translate',
      home: const ConversationScreen(),
    );
  }
}

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  // Idiomas de cada persona (A y B hablan distinto).
  final String _idiomaA = 'es-AR'; // Español (Argentina)
  final String _idiomaB = 'en-US'; // Inglés

  // Tabla que conecta el código corto ('es', 'en') con el idioma de ML Kit.
  final Map<String, TranslateLanguage> _idiomasMlKit = {
    'es': TranslateLanguage.spanish,
    'en': TranslateLanguage.english,
  };

  bool _preparando = true; // true mientras se descargan los idiomas
  bool _isListening = false;
  String _estado = 'Descargando idiomas...';
  String _textoReconocido = '';
  String _textoTraducido = '';

  @override
  Widget build(BuildContext context) {
    final bloqueado = _preparando || _isListening;

    return Scaffold(
      appBar: AppBar(title: const Text('Fijos Translate')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_estado, style: const TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 24),
              Text('Dijiste: $_textoReconocido'),
              const SizedBox(height: 20),
              Text('Traducción: $_textoTraducido'),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: bloqueado ? null : () {}, // se conecta en el Paso 8
                child: const Text('Hablar (Persona A)'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: bloqueado ? null : () {}, // se conecta en el Paso 8
                child: const Text('Hablar (Persona B)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Ideas clave de este código:**
- `MyApp` solo arranca la app y no cambia nunca — por eso es `StatelessWidget`.
- `ConversationScreen` sí cambia (los textos se van actualizando), por eso es `StatefulWidget`. Sus variables (`_textoReconocido`, `_estado`, etc.) redibujan la pantalla cuando las modificamos con `setState`.
- `_idiomaA` y `_idiomaB` definen entre qué idiomas se traduce. `_idiomasMlKit` es una tabla que le dice a ML Kit qué idioma es cada código.
- `bloqueado`: mientras se descargan los idiomas o se está escuchando, los botones quedan desactivados (`onPressed: null` desactiva un botón en Flutter).

---

## Paso 5 — Descargar los idiomas (ML Kit)

ML Kit traduce dentro del celular, pero antes necesita tener cada idioma descargado (unos 30 MB por idioma). Se hace una sola vez, con internet. Agregá esto dentro de la clase `_ConversationScreenState`, antes del `build`:

```dart
@override
void initState() {
  super.initState();
  _prepararIdiomas();
}

Future<void> _prepararIdiomas() async {
  try {
    for (final idioma in _idiomasMlKit.values) {
      final yaDescargado = await _modelManager.isModelDownloaded(idioma.bcpCode);
      if (!yaDescargado) {
        await _modelManager.downloadModel(idioma.bcpCode);
      }
    }
    if (!mounted) return;
    setState(() {
      _preparando = false;
      _estado = 'Listo para traducir';
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _estado = 'No se pudieron descargar los idiomas. Revisá internet.';
    });
  }
}
```

Cómo funciona:
1. `initState` se ejecuta una sola vez, cuando se abre la pantalla, y llama a `_prepararIdiomas`.
2. Por cada idioma de la tabla, `isModelDownloaded` pregunta si ya está en el celular; si no, `downloadModel` lo baja.
3. Cuando termina, `_preparando` pasa a `false` y los botones se activan. Si falla (por ejemplo, sin internet), se avisa en pantalla.
4. `if (!mounted) return;` evita errores si el usuario cierra la pantalla mientras se descarga.

---

## Paso 6 — Escuchar el micrófono (voz → texto)

Agregá este método en la misma clase:

```dart
void _escuchar(String idiomaOrigen, String idiomaDestino) async {
  final disponible = await _speech.initialize();
  if (!disponible) {
    setState(() => _estado = 'No se pudo usar el micrófono. Revisá permisos.');
    return;
  }

  setState(() {
    _isListening = true;
    _estado = 'Escuchando...';
  });

  _speech.listen(
    localeId: idiomaOrigen,
    onResult: (resultado) async {
      setState(() => _textoReconocido = resultado.recognizedWords);
      if (resultado.finalResult) {
        await _speech.stop();
        setState(() => _isListening = false);
        await _traducirYHablar(resultado.recognizedWords, idiomaOrigen, idiomaDestino);
      }
    },
  );
}
```

Cómo funciona:
1. `_speech.initialize()` prepara el micrófono (y pide permiso la primera vez).
2. `_speech.listen()` empieza a grabar y llama a `onResult` cada vez que reconoce algo nuevo, por eso el texto aparece mientras la persona habla.
3. Cuando `finalResult` es `true` (la persona hizo una pausa), frenamos el micrófono y mandamos el texto a traducir.

---

## Paso 7 — Traducir y leer en voz alta

Agregá estos dos métodos:

```dart
Future<String> _traducir(String texto, String idiomaOrigen, String idiomaDestino) async {
  final traductor = OnDeviceTranslator(
    sourceLanguage: _idiomasMlKit[idiomaOrigen.split('-')[0]]!,
    targetLanguage: _idiomasMlKit[idiomaDestino.split('-')[0]]!,
  );
  final traduccion = await traductor.translateText(texto);
  await traductor.close();
  return traduccion;
}

Future<void> _traducirYHablar(String texto, String idiomaOrigen, String idiomaDestino) async {
  if (texto.isEmpty) {
    setState(() => _estado = 'No se escuchó nada, probá de nuevo.');
    return;
  }

  final traduccion = await _traducir(texto, idiomaOrigen, idiomaDestino);
  setState(() {
    _textoTraducido = traduccion;
    _estado = 'Listo para traducir';
  });

  await _tts.setLanguage(idiomaDestino);
  await _tts.speak(traduccion);
}
```

Cómo funciona:
1. `idiomaOrigen.split('-')[0]` convierte `'es-AR'` en `'es'`, que es la clave de nuestra tabla `_idiomasMlKit`.
2. `OnDeviceTranslator` es el traductor de ML Kit: se crea con un idioma de origen y uno de destino, y `translateText` devuelve el texto traducido. No hay pedidos a internet ni API Key.
3. `traductor.close()` libera la memoria cuando terminamos.
4. `_tts.speak()` lee la traducción en voz alta, en el idioma de la otra persona.

---

## Paso 8 — Conectar los botones (ida y vuelta)

En el `build()`, cambiá los dos `onPressed` del Paso 4 por estos:

```dart
// Botón de la Persona A
onPressed: bloqueado ? null : () => _escuchar(_idiomaA, _idiomaB),

// Botón de la Persona B
onPressed: bloqueado ? null : () => _escuchar(_idiomaB, _idiomaA),
```

Es el mismo método `_escuchar`, pero con el origen y el destino invertidos. Así cada persona tiene su botón, y la traducción siempre va hacia el idioma del otro.

> El código completo de todo el archivo está en [`lib/main.dart`](./lib/main.dart) del repositorio, por si quieren compararlo con el suyo.

---

## Paso 9 — Probar en un celular real

1. Activá "Opciones de desarrollador" en el Android: Ajustes → Acerca del teléfono → tocar 7 veces "Número de compilación".
2. Dentro de Opciones de desarrollador, activá "Depuración USB".
3. Conectá el celular por cable y aceptá el permiso que aparece en la pantalla.
4. En VS Code, abajo a la derecha debería aparecer el nombre del celular (si no, corré `flutter devices`).
5. Apretá F5 o el botón ▶️ — la app se instala y abre sola.

Qué esperar:
- La **primera vez**, la app dice "Descargando idiomas..." y los botones están desactivados. Necesita internet y puede tardar un poco. Cuando dice "Listo para traducir", ya se puede usar.
- Android va a pedir permiso de micrófono: hay que aceptarlo o el reconocimiento de voz no funciona.
- La traducción en sí funciona sin internet una vez descargados los idiomas. El **reconocimiento de voz** de Android, en cambio, normalmente sí usa internet, salvo que el celular tenga descargado el idioma para uso sin conexión.

---

## Qué sigue

- Historial de mensajes tipo chat (guardar cada traducción en una lista y mostrarla como burbujas).
- Más idiomas: se agregan en la tabla `_idiomasMlKit` y en las variables `_idiomaA` / `_idiomaB`.
- Selector de idiomas en la pantalla, en vez de fijarlos en el código.

Se puede encarar cada uno de a uno, con el mismo nivel de detalle que los pasos de arriba.