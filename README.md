# Fijos Translate 🌐🎙️

Aplicación móvil desarrollada como proyecto de la materia **Desarrollo de Apps** (profesor Fabian Bessonne), escuela **PRoA de Corral de Bustos**.

A diferencia de un traductor convencional, esta app tiene un **modo conversación en vivo**: dos personas que hablan idiomas distintos pueden mantener una charla y la app traduce automáticamente lo que dice cada una, en tiempo real y en voz alta.

## ✨ Funcionalidades

- 🎤 Reconocimiento de voz en tiempo real (voz → texto)
- 🌍 Traducción automática dentro del celular, con **Google ML Kit** (sin API key ni tarjeta)
- 🔊 Lectura en voz alta de la traducción (texto → voz)
- 🔁 Modo conversación: cada persona tiene su propio botón, la app alterna entre los dos idiomas configurados

## 🛠️ Tecnologías usadas

| Tecnología | Uso |
|---|---|
| [Flutter](https://flutter.dev) (Dart) | Framework para la app |
| [speech_to_text](https://pub.dev/packages/speech_to_text) | Reconocimiento de voz |
| [flutter_tts](https://pub.dev/packages/flutter_tts) | Texto a voz |
| [google_mlkit_translation](https://pub.dev/packages/google_mlkit_translation) | Traducción en el propio celular (Google ML Kit) |

## 📋 Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado (`flutter doctor` sin errores)
- Android Studio (para el SDK de Android y/o emulador)
- Un editor de código (recomendado: VS Code con las extensiones **Flutter** y **Dart**)
- Un celular Android con depuración USB, o un emulador

> 💡 Para el paso a paso detallado de cómo se armó la app, ver [`instructivo.md`](./instructivo.md).

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

3. Conectá un celular por USB con la depuración USB activada, o abrí un emulador.

4. Corré la app:
   ```bash
   flutter run
   ```

No hace falta configurar ninguna API Key.

## 📱 Uso

1. La **primera vez**, la app descarga los idiomas al celular (necesita internet; unos 30 MB por idioma). Cuando dice "Listo para traducir", se puede usar.
2. Cuando hable la Persona A, tocá "Hablar (Persona A)": la app escucha, traduce y lee la traducción en voz alta en el idioma de la Persona B.
3. Cuando responda la Persona B, se toca su propio botón, y la traducción va en sentido inverso.

Por defecto, los idiomas son español (Argentina) e inglés (Estados Unidos).

> La traducción funciona sin internet una vez descargados los idiomas. El reconocimiento de voz de Android normalmente sí usa internet, salvo que el celular tenga descargado el idioma para uso sin conexión.

## 📂 Estructura del proyecto

```
lib/
 └── main.dart                              # Pantalla principal y lógica de la conversación
android/app/src/main/AndroidManifest.xml    # Permisos (micrófono, internet)
pubspec.yaml                                # Dependencias del proyecto
instructivo.md                              # Paso a paso para armar la app
```

## 🗺️ Roadmap

- [ ] Historial de conversación tipo chat (burbujas)
- [ ] Selector de idiomas desde la interfaz
- [ ] Más idiomas (se suman en la tabla de idiomas de `main.dart`)
- [ ] Manejo de errores más completo (sin conexión al bajar idiomas, sin permiso de micrófono)

## 👥 Equipo

- Joaquín Trejo
- Ian Acosta
- Facundo Rodríguez
- Octavio Bambini

## 📄 Licencia

Este proyecto es de uso educativo.