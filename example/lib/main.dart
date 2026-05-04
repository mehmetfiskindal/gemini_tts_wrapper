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
  final _directorsNoteController = TextEditingController();

  static const _voices = <String>['aoide', 'charon', 'puck'];
  static const _audioProfiles = <String?>[
    null,
    'default',
    'wearable',
    'headphone',
  ];

  var _voice = _voices.first;
  String? _audioProfile;
  var _isBusy = false;
  String? _lastError;
  String? _validationWarning;

  @override
  void dispose() {
    _player.dispose();
    _apiKeyController.dispose();
    _textController.dispose();
    _modelController.dispose();
    _directorsNoteController.dispose();
    super.dispose();
  }

  void _validateText() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _validationWarning = null);
      return;
    }

    final result = TtsValidator.validateTextLength(text);
    setState(() {
      _validationWarning = result.isValid ? null : result.message;
    });
  }

  Future<void> _generateAndPlay() async {
    final apiKey = _apiKeyController.text.trim();
    final text = _textController.text.trim();
    final model = _modelController.text.trim();
    final directorsNote = _directorsNoteController.text.trim();

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
      final bytes = await tts.generate(
        text: text,
        voice: _voice,
        audioProfile: _audioProfile,
        directorsNote: directorsNote.isEmpty ? null : directorsNote,
      );

      await _player.setAudioSource(
        Uint8ListAudioSource(bytes, contentType: 'audio/wav'),
      );
      await _player.play();
    } on TtsLengthException catch (e) {
      setState(() {
        _lastError = e.message;
      });
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

  void _showDialogueDemo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DialogueDemoPage(
          apiKey: _apiKeyController.text.trim(),
          model: _modelController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Gemini One-shot TTS'),
        actions: [
          TextButton(
            onPressed: _showDialogueDemo,
            child: const Text(
              'Dialogue Demo',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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
            DropdownButtonFormField<String?>(
              value: _audioProfile,
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                for (final p in _audioProfiles.where((p) => p != null))
                  DropdownMenuItem(value: p, child: Text(p!)),
              ],
              onChanged: _isBusy
                  ? null
                  : (v) => setState(() => _audioProfile = v),
              decoration: const InputDecoration(
                labelText: 'Audio Profile',
                helperText: 'Note: May not work in all languages',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _directorsNoteController,
              decoration: const InputDecoration(
                labelText: "Director's Note",
                helperText: 'Tone/style instructions (may be ignored)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Text',
                border: OutlineInputBorder(),
                helperText: '~160s max audio. Use [medium pause] or [long pause] tags.',
              ),
              maxLines: 6,
              onChanged: (_) => _validateText(),
            ),
            if (_validationWarning != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationWarning!,
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

class DialogueDemoPage extends StatefulWidget {
  const DialogueDemoPage({
    required this.apiKey,
    required this.model,
    super.key,
  });

  final String apiKey;
  final String model;

  @override
  State<DialogueDemoPage> createState() => _DialogueDemoPageState();
}

class _DialogueDemoPageState extends State<DialogueDemoPage> {
  final _player = AudioPlayer();
  var _isBusy = false;
  String? _lastError;
  String _status = '';

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _generateDialogue() async {
    if (widget.apiKey.isEmpty) {
      setState(() {
        _lastError = 'API key required. Go back and enter an API key.';
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _lastError = null;
      _status = 'Building dialogue...';
    });

    try {
      // Create a dialogue with multiple speakers
      final builder = DialogueBuilder(
        context: 'A casual conversation between two friends at a coffee shop.',
        speakers: {
          'Alice': const SpeakerConfig(
            name: 'Alice',
            voice: 'aoide',
            description: 'Friendly and energetic',
          ),
          'Bob': const SpeakerConfig(
            name: 'Bob',
            voice: 'charon',
            description: 'Calm and thoughtful',
          ),
        },
      );

      builder.addLines([
        const DialogueLine(
          speaker: 'Alice',
          text: "Hey Bob! Long time no see. How have you been?",
        ),
        const DialogueLine(
          speaker: 'Bob',
          text: "Alice! Great to see you too. I've been well, thanks. Just busy with work.",
          pausesBefore: ['medium pause'],
        ),
        const DialogueLine(
          speaker: 'Alice',
          text: "I know what you mean. [medium pause] So, are you still working on that project?",
          pausesBefore: ['medium pause'],
        ),
        const DialogueLine(
          speaker: 'Bob',
          text: "Yeah, actually we just launched it last week!",
          pausesBefore: ['medium pause'],
        ),
      ]);

      // Validate before generating
      final validation = builder.validate();
      if (!validation['full']!.isValid) {
        setState(() {
          _status = 'Warning: ${validation['full']!.message}';
        });
      }

      final tts = GeminiTts(apiKey: widget.apiKey, model: widget.model);
      final generator = DialogueGenerator(tts: tts);

      setState(() => _status = 'Generating dialogue audio...');

      // Generate each speaker separately to avoid voice mixing
      final audioSegments = await generator.generatePerSpeaker(builder);

      setState(() => _status = 'Playing audio segments...');

      // Play each segment
      for (final entry in audioSegments.entries) {
        final speaker = entry.key;
        final bytes = entry.value;

        setState(() => _status = 'Playing: $speaker');

        await _player.setAudioSource(
          Uint8ListAudioSource(bytes, contentType: 'audio/wav'),
        );
        await _player.play();
        await _player.processingStateStream
            .firstWhere((state) => state == ProcessingState.completed);
      }

      setState(() => _status = 'Dialogue complete!');
    } catch (e) {
      setState(() {
        _lastError = e.toString();
        _status = '';
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dialogue Demo'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Dialogue Mode Demo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'This demo shows how to structure multi-speaker dialogues '
                'to work around voice mixing issues. Each speaker is generated '
                'separately with their own voice.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sample Dialogue:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Alice (aoide): Hey Bob! Long time no see.\n'
                  'Bob (charon): [medium pause] Alice! Great to see you too.\n'
                  'Alice (aoide): [medium pause] So, are you still working on that project?\n'
                  'Bob (charon): [medium pause] Yeah, actually we just launched it!',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
              if (_status.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_status)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton(
                onPressed: _isBusy ? null : _generateDialogue,
                child: _isBusy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Generate and Play Dialogue'),
              ),
              if (_lastError != null) ...[
                const SizedBox(height: 16),
                Text(
                  _lastError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
