# Instructivo: cómo armar la app Fijos Translate

Esta app se hace con **Flutter (Dart)**. Usa el micrófono para escuchar, una API para traducir, y lee la traducción en voz alta. La idea general es un ciclo:

**Persona A habla → se convierte a texto → se traduce → se escucha en el idioma de Persona B → y al revés.**

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

Abrí `pubspec.yaml` y agregá esto dentro de `dependencies:`

```yaml
dependencies:
  flutter:
    sdk: flutter
  speech_to_text: ^7.0.0
  flutter_tts: ^4.0.2
  http: ^1.2.0
  permission_handler: ^11.3.1
```

Guardá y corré:
```bash
flutter pub get
```

Qué hace cada una:
- `speech_to_text`: escucha el micrófono y devuelve lo que se dijo, como texto.
- `flutter_tts`: lee un texto en voz alta.
- `http`: nos deja pedirle la traducción a la API por internet.
- `permission_handler`: pide permiso de micrófono (obligatorio en Android/iOS).

---

## Paso 3 — Conseguir la API Key de traducción

1. Entrá a Google Cloud Console → creá un proyecto → activá la **Cloud Translation API**.
2. Generá una **API Key** en "Credenciales".
3. Google tiene una capa gratuita mensual, suficiente para el proyecto. **No subas esta key a GitHub** — la vamos a guardar en un archivo aparte que no se sube al repo (ver README).

La traducción no la hace el celular: la app le manda el texto a un servidor de Google por internet y este devuelve la traducción. Por eso hace falta conexión y la API Key (te identifica como quien hace el pedido).

---

## Paso 4 — Pantalla base

Reemplazá el contenido de `lib/main.dart` por esto:

```dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  bool _isListening = false;
  String _textoReconocido = '';
  String _textoTraducido = '';

  String _idiomaA = 'es-AR'; // Español (Argentina)
  String _idiomaB = 'en-US'; // Inglés

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fijos Translate')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Dijiste: $_textoReconocido'),
            const SizedBox(height: 20),
            Text('Traducción: $_textoTraducido'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {}, // se completa en el Paso 5
              child: Text(_isListening ? 'Escuchando...' : 'Hablar (Persona A)'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Ideas clave de este código:**
- `MyApp` solo arranca la app y no cambia nunca — por eso es `StatelessWidget`.
- `ConversationScreen` sí cambia (el texto se va actualizando), por eso es `StatefulWidget` y tiene variables (`_textoReconocido`, `_isListening`, etc.) que al modificarse redibujan la pantalla.
- `_idiomaA` y `_idiomaB` son las dos variables clave: definen entre qué idiomas se traduce.

---

## Paso 5 — Escuchar el micrófono (voz → texto)

Agregá este método dentro de la clase, antes del `build`:

```dart
void _escuchar(String idiomaOrigen, String idiomaDestino) async {
  bool disponible = await _speech.initialize();
  if (disponible) {
    setState(() => _isListening = true);
    _speech.listen(
      localeId: idiomaOrigen,
      onResult: (resultado) async {
        setState(() => _textoReconocido = resultado.recognizedWords);
        if (resultado.finalResult) {
          _speech.stop();
          setState(() => _isListening = false);
          await _traducirYHablar(resultado.recognizedWords, idiomaOrigen, idiomaDestino);
        }
      },
    );
  }
}
```

Cómo funciona:
1. `_speech.initialize()` prepara el micrófono (y pide permiso si hace falta).
2. `_speech.listen()` empieza a grabar y va actualizando `_textoReconocido` mientras la persona habla.
3. Cuando `finalResult` es `true` (la persona hizo una pausa, terminó de hablar), frenamos el micrófono y mandamos el texto a traducir.

Y en el botón del Paso 4, cambiá `onPressed: () {}` por:
```dart
onPressed: () => _escuchar(_idiomaA, _idiomaB),
```

---

## Paso 6 — Traducir y leer en voz alta

Agregá este método (reemplazá `TU_API_KEY` por la tuya del Paso 3):

```dart
Future<void> _traducirYHablar(String texto, String idiomaOrigen, String idiomaDestino) async {
  if (texto.isEmpty) return;

  const apiKey = 'TU_API_KEY';
  final codigoDestino = idiomaDestino.split('-')[0]; // ej: 'en-US' -> 'en'

  final url = Uri.parse('https://translation.googleapis.com/language/translate/v2?key=$apiKey');
  final respuesta = await http.post(url, body: {
    'q': texto,
    'target': codigoDestino,
  });

  final datos = jsonDecode(respuesta.body);
  final traduccion = datos['data']['translations'][0]['translatedText'];

  setState(() => _textoTraducido = traduccion);

  await _tts.setLanguage(idiomaDestino);
  await _tts.speak(traduccion);
}
```

Cómo funciona:
1. Armamos la URL de la API de Google con nuestra key.
2. Le mandamos el texto (`q`) y a qué idioma traducir (`target`).
3. La respuesta viene en JSON; `jsonDecode` la convierte en algo que Dart puede leer, y de ahí sacamos la traducción.
4. `_tts.speak()` lee la traducción en voz alta, en el idioma de la Persona B.

---

## Paso 7 — Que sea de ida y vuelta

Para que la Persona B también pueda hablar, agregá un segundo botón en el `build()`, junto al anterior:

```dart
ElevatedButton(
  onPressed: () => _escuchar(_idiomaB, _idiomaA),
  child: const Text('Hablar (Persona B)'),
),
```

Es el mismo método `_escuchar` de antes, pero con el origen y el destino invertidos. Así cada persona tiene su botón, y la traducción siempre va hacia el idioma del otro.

---

## Paso 8 — Probar en un celular real

1. Activá "Opciones de desarrollador" en el Android: Ajustes → Acerca del teléfono → tocar 7 veces "Número de compilación".
2. Dentro de Opciones de desarrollador, activá "Depuración USB".
3. Conectá el celular por cable y aceptá el permiso que aparece en la pantalla.
4. En VS Code, abajo a la derecha debería aparecer el nombre del celular (si no, corré `flutter devices`).
5. Apretá F5 o el botón ▶️ — la app se instala y abre sola.

La primera vez que la app pida el micrófono, Android va a mostrar un permiso: hay que aceptarlo o el reconocimiento de voz no funciona.

---

## Qué sigue

- Historial de mensajes tipo chat (guardar cada traducción en una lista y mostrarla como burbujas).
- Detección automática de idioma, en vez de fijar A y B de antemano.
- Manejo de errores: sin internet, sin permiso de micrófono, o la API no responde.

Se puede encarar cada uno de a uno, con el mismo nivel de detalle que los pasos de arriba.
