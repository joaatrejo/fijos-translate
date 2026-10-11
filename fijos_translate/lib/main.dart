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
  // Para sumar un idioma nuevo, se agrega una línea acá.
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
  void initState() {
    super.initState();
    _prepararIdiomas();
  }

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }

  // Baja los idiomas al celular (solo la primera vez, necesita internet).
  Future<void> _prepararIdiomas() async {
    try {
      for (final idioma in _idiomasMlKit.values) {
        final yaDescargado =
            await _modelManager.isModelDownloaded(idioma.bcpCode);
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

  // Voz -> texto. Cuando la persona termina de hablar, traduce.
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
          await _traducirYHablar(
              resultado.recognizedWords, idiomaOrigen, idiomaDestino);
        }
      },
    );
  }

  // Traduce con ML Kit (dentro del celular, sin API key).
  Future<String> _traducir(
      String texto, String idiomaOrigen, String idiomaDestino) async {
    final traductor = OnDeviceTranslator(
      sourceLanguage: _idiomasMlKit[idiomaOrigen.split('-')[0]]!,
      targetLanguage: _idiomasMlKit[idiomaDestino.split('-')[0]]!,
    );
    final traduccion = await traductor.translateText(texto);
    await traductor.close();
    return traduccion;
  }

  // Traduce y lee la traducción en voz alta.
  Future<void> _traducirYHablar(
      String texto, String idiomaOrigen, String idiomaDestino) async {
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

  @override
  Widget build(BuildContext context) {
    // Los botones se desactivan mientras se descargan los idiomas o se escucha.
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
                onPressed:
                    bloqueado ? null : () => _escuchar(_idiomaA, _idiomaB),
                child: const Text('Hablar (Persona A)'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed:
                    bloqueado ? null : () => _escuchar(_idiomaB, _idiomaA),
                child: const Text('Hablar (Persona B)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}