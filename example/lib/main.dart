import 'package:flutter/material.dart';
import 'package:gemini_tts_wrapper/gemini_tts_wrapper.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini One-shot TTS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _player = AudioPlayer();

  final _apiKeyController = TextEditingController();
  final _textController = TextEditingController(text: 'Merhaba dunya!');
  final _modelController = TextEditingController(
    text: 'gemini-3.1-flash-tts-preview',
  );

  static const _voices = <String>['aoide', 'charon', 'puck'];

  var _voice = _voices.first;
  var _isBusy = false;
  String? _lastError;

  @override
  void dispose() {
    _player.dispose();
    _apiKeyController.dispose();
    _textController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _generateAndPlay() async {
    final apiKey = _apiKeyController.text.trim();
    final text = _textController.text.trim();
    final model = _modelController.text.trim();

    if (apiKey.isEmpty || text.isEmpty || model.isEmpty) {
      setState(() {
        _lastError = 'API key, model, and text are required.';
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _lastError = null;
    });

    try {
      final tts = GeminiTts(apiKey: apiKey, model: model);
      final bytes = await tts.generate(text: text, voice: _voice);

      await _player.setAudioSource(
        Uint8ListAudioSource(bytes, contentType: 'audio/wav'),
      );
      await _player.play();
    } catch (e) {
      setState(() {
        _lastError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Gemini One-shot TTS'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'Gemini API key',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Model',
                helperText: 'Example: gemini-3.1-flash-tts-preview',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _voice,
              items: [
                for (final v in _voices)
                  DropdownMenuItem(value: v, child: Text(v)),
              ],
              onChanged: _isBusy ? null : (v) => setState(() => _voice = v!),
              decoration: const InputDecoration(
                labelText: 'Voice',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Text',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isBusy ? null : _generateAndPlay,
              child: _isBusy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Generate and play'),
            ),
            if (_lastError != null) ...[
              const SizedBox(height: 12),
              Text(
                _lastError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Security: Don\'t ship long-lived API keys in production apps. '
              'Use a server-side proxy.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
