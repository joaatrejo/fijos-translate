# Fijos Translate 🌐🎙️

Aplicación móvil desarrollada como proyecto de la materia **Desarrollo de Apps** (profesor Fabian Bessonne), escuela **PRoA de Corral de Bustos**.

A diferencia de un traductor convencional, esta app tiene un **modo conversación en vivo**: dos personas que hablan idiomas distintos pueden mantener una charla y la app traduce automáticamente lo que dice cada una, en tiempo real y en voz alta.

## ✨ Funcionalidades

- 🎤 Reconocimiento de voz en tiempo real (voz → texto)
- 🌍 Traducción automática entre idiomas
- 🔊 Lectura en voz alta de la traducción (texto → voz)
- 🔁 Modo conversación: cada persona tiene su propio botón, la app alterna entre los dos idiomas configurados

## 🛠️ Tecnologías usadas

| Tecnología | Uso |
|---|---|
| [Flutter](https://flutter.dev) (Dart) | Framework para la app (Android/iOS con un solo código) |
| [speech_to_text](https://pub.dev/packages/speech_to_text) | Reconocimiento de voz |
| [flutter_tts](https://pub.dev/packages/flutter_tts) | Texto a voz |
| [Google Cloud Translation API](https://cloud.google.com/translate) | Traducción automática |
| [http](https://pub.dev/packages/http) | Conexión con la API de traducción |

## 📋 Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado (`flutter doctor` sin errores)
- Android Studio (para el SDK de Android y/o emulador)
- Un editor de código (recomendado: VS Code con las extensiones **Flutter** y **Dart**)
- Una API Key de Google Cloud Translation ([cómo generarla](https://cloud.google.com/translate/docs/setup))

> 💡 Para la instalación paso a paso, detallada, ver [`instructivo.md`](./instructivo.md).

## 🚀 Instalación rápida

1. Cloná el repositorio:
   ```bash
   git clone https://github.com/joaatrejo/fijos-translate.git
   cd fijos-translate
   ```

2. Instalá las dependencias:
   ```bash
   flutter pub get
   ```

3. Agregá tu API Key de traducción. Creá un archivo `lib/config.dart` (no se sube al repo) con:
   ```dart
   const String googleApiKey = 'TU_API_KEY_ACA';
   ```

4. Conectá un celular por USB con la depuración USB activada, o abrí un emulador.

5. Corré la app:
   ```bash
   flutter run
   ```

## 📱 Uso

1. Abrí la app y elegí el idioma de la Persona A y de la Persona B (por defecto: español e inglés).
2. Cuando hable la Persona A, tocá el botón "Hablar (Persona A)" — la app escucha, traduce y lee en voz alta en el idioma de la Persona B.
3. Cuando responda la Persona B, se toca su propio botón, y la traducción va en sentido inverso.

## 📂 Estructura del proyecto

```
lib/
 └── main.dart        # Pantalla principal y lógica de la conversación
pubspec.yaml           # Dependencias del proyecto
```

## 🗺️ Roadmap

- [ ] Historial de conversación tipo chat (burbujas)
- [ ] Detección automática de idioma (sin tener que fijarlo antes)
- [ ] Manejo de errores (sin conexión, sin permisos, falla de la API)
- [ ] Selector de idiomas desde la interfaz

## 👥 Equipo

- Joaquín Trejo
- Ian Acosta
- Octavio Bambini
- Facundo Rodríguez
- Ciro Cafaratti

## 📄 Licencia

Este proyecto es de uso educativo.
