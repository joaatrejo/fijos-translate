# Guía paso a paso: App traductor con modo conversación en vivo

Stack elegido: **Flutter (Dart)** + paquete `speech_to_text` (voz→texto) + paquete `flutter_tts` (texto→voz) + **Google Cloud Translation API** (traducción).

La lógica general de la app va a ser un ciclo:
**Persona A habla → se convierte a texto → se traduce → se lee en voz alta en el idioma de Persona B → y viceversa.**

---

## Paso 0 — Instalar lo necesario

1. **Flutter SDK**: bajalo de flutter.dev e instalalo siguiendo la guía para tu sistema operativo (Windows/Mac/Linux). Al final corré `flutter doctor` en una terminal — te va a decir qué falta (por ejemplo, Android Studio para el emulador/SDK de Android).
2. **Android Studio** (aunque programemos en VS Code): lo necesitás igual porque trae el Android SDK y las herramientas para conectar un celular real.
3. **VS Code**: instalá las extensiones **Flutter** y **Dart** desde el marketplace (buscá "Flutter" — la extensión de Dart se instala sola como dependencia).

**Por qué esto:** Flutter es el "motor" que convierte tu código Dart en una app nativa. VS Code con la extensión Flutter te da autocompletado, botón de "run", y hot reload (ver los cambios al instante sin reiniciar la app).

---

## Paso 1 — Crear el proyecto

En la terminal de VS Code:

```bash
flutter create traductor_app
cd traductor_app
code .
```

Esto genera una estructura de carpetas. Las que nos importan:
- `lib/main.dart` → acá va todo nuestro código Dart (la lógica y las pantallas).
- `pubspec.yaml` → acá se declaran las librerías externas (paquetes) que usamos.

**Lógica:** Flutter organiza todo en "widgets" (bloques de UI que se combinan). Todo lo que ves en pantalla — un botón, un texto, una pantalla entera — es un widget.

---

## Paso 2 — Agregar las librerías (paquetes)

Abrí `pubspec.yaml` y agregá estas líneas dentro de `dependencies:`

```yaml
dependencies:
  flutter:
    sdk: flutter
  speech_to_text: ^7.0.0
  flutter_tts: ^4.0.2
  http: ^1.2.0
  permission_handler: ^11.3.1
```

Guardá y corré en la terminal:
```bash
flutter pub get
```

**Qué hace cada uno:**
- `speech_to_text`: escucha el micrófono y devuelve lo que la persona dijo, como texto.
- `flutter_tts`: toma un texto y lo "lee" en voz alta (text-to-speech).
- `http`: nos deja hacer pedidos a la API de traducción por internet.
- `permission_handler`: pide permiso de micrófono al usuario (obligatorio en Android/iOS).

---

## Paso 3 — Conseguir la API Key de traducción

1. Andá a Google Cloud Console → creá un proyecto → activá la **Cloud Translation API**.
2. Generá una **API Key** en "Credenciales".
3. Google da una capa gratuita mensual (suficiente para un proyecto escolar), pero **ojo**: no subas esta key a un repositorio público de GitHub. La vamos a guardar en una variable separada.

**Lógica:** la traducción no la hace tu celular — tu app le manda el texto a un servidor de Google por internet, y el servidor te devuelve la traducción. Por eso hace falta conexión a internet y una key que te identifica como el que hace el pedido.

---

## Paso 4 — Estructura base de `main.dart`

Reemplazá todo el contenido de `lib/main.dart` por esto (lo vamos a ir completando):

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
      title: 'Traductor en Vivo',
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

  // Idioma de cada persona. A y B hablan distinto.
  String _idiomaA = 'es-AR'; // Español (Argentina)
  String _idiomaB = 'en-US'; // Inglés

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Traductor en Vivo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Dijiste: $_textoReconocido'),
            const SizedBox(height: 20),
            Text('Traducción: $_textoTraducido'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {}, // acá va la lógica del Paso 5
              child: Text(_isListening ? 'Escuchando...' : 'Hablar (Persona A)'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Explicación de la lógica:**
- `StatelessWidget` (`MyApp`) es un widget que no cambia — solo arranca la app.
- `StatefulWidget` (`ConversationScreen`) sí cambia con el tiempo (el texto que se va actualizando cuando alguien habla), por eso tiene un `State` asociado con variables (`_textoReconocido`, `_isListening`, etc.) que al modificarse redibujan la pantalla.
- El `_idiomaA` y `_idiomaB` son las dos variables clave: van a definir a quién le toca hablar y a qué idioma traducir.

---

## Paso 5 — Escuchar el micrófono (voz → texto)

Agregá este método dentro de `_ConversationScreenState` (debajo de las variables, antes de `build`):

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

**Lógica paso a paso:**
1. `_speech.initialize()` prepara el micrófono y pide permiso si hace falta.
2. `_speech.listen()` empieza a grabar y va llamando a `onResult` cada vez que reconoce algo nuevo (por eso `_textoReconocido` se actualiza en vivo, palabra por palabra).
3. Cuando `resultado.finalResult` es `true`, significa que la persona terminó de hablar (hizo una pausa) → ahí frenamos el micrófono y mandamos el texto a traducir.

Y cambiá el botón del Paso 4 para que llame a esto:
```dart
onPressed: () => _escuchar(_idiomaA, _idiomaB),
```

---

## Paso 6 — Traducir el texto (llamada a la API)

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

**Lógica paso a paso:**
1. Armamos la URL del servicio de Google, con nuestra API key.
2. `http.post` manda el texto (`q`) y el idioma al que queremos traducir (`target`).
3. La respuesta llega en formato JSON (texto estructurado); `jsonDecode` lo convierte en un mapa de Dart para poder "entrar" a `datos['data']['translations'][0]['translatedText']` y sacar la traducción.
4. `_tts.speak()` lee en voz alta la traducción, en el idioma de la Persona B.

---

## Paso 7 — Que la conversación sea de ida y vuelta

Para que no sea solo A→B sino una conversación real, agregá un segundo botón para que hable la Persona B, y una variable que indique de quién es el turno:

```dart
// Agregar junto a los otros botones en el build():
ElevatedButton(
  onPressed: () => _escuchar(_idiomaB, _idiomaA),
  child: const Text('Hablar (Persona B)'),
),
```

**Lógica:** es el mismo método `_escuchar`, pero invertimos qué idioma es el "origen" y cuál el "destino". Así cada persona tiene su propio botón, y la traducción siempre va hacia el idioma de la otra.

---

## Paso 8 — Probar en un celular real

1. Activá "Opciones de desarrollador" en tu Android (Ajustes → Acerca del teléfono → tocar 7 veces en "Número de compilación").
2. Dentro de Opciones de desarrollador, activá "Depuración USB".
3. Conectá el celular a la compu por cable, aceptá el permiso que aparece en la pantalla del celular.
4. En VS Code, abajo a la derecha vas a ver el nombre de tu dispositivo (si no aparece, corré `flutter devices` en la terminal).
5. Apretá F5 (o el botón ▶️ de Flutter) — la app se instala y abre sola en tu celular.

**Nota sobre permisos:** la primera vez que la app pida el micrófono, Android va a mostrar un cartel de permiso — hay que aceptarlo o el reconocimiento de voz no va a funcionar.

---

## Qué sigue (para ir sumando de a poco)

- Agregar el diseño de "doble burbuja de chat" (guardar un historial de mensajes en una lista y mostrarlos como en WhatsApp).
- Detección automática de idioma (en vez de fijar A y B, que la API detecte qué idioma se habló).
- Manejo de errores (sin internet, sin permiso de micrófono, API sin respuesta).

Cualquiera de estos lo podemos encarar paso a paso como hicimos con lo de arriba — avisame por cuál seguimos.
