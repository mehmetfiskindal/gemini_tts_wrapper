import 'dart:typed_data';

import 'package:gemini_tts_wrapper/src/gemini_tts_base.dart';
import 'package:gemini_tts_wrapper/src/utils/tts_validator.dart';

/// Represents a single line in a dialogue.
class DialogueLine {
  /// Creates a dialogue line with speaker and text.
  const DialogueLine({
    required this.speaker,
    required this.text,
    this.voice,
    this.pausesBefore = const [],
    this.pausesAfter = const [],
  });

  /// Speaker identifier (e.g., 'Alice', 'Bob').
  final String speaker;

  /// The text to speak.
  final String text;

  /// Optional voice override for this speaker.
  final String? voice;

  /// Pause tags to insert before this line.
  /// Note: Gemini 3.1 Flash TTS may ignore [short pause] - use [medium pause] or [long pause].
  final List<String> pausesBefore;

  /// Pause tags to insert after this line.
  final List<String> pausesAfter;

  /// Formats the line with speaker prefix and pause tags.
  String toFormattedText() {
    final buffer = StringBuffer();

    for (final pause in pausesBefore) {
      buffer.write('[$pause] ');
    }

    buffer.write('**$speaker**: $text');

    for (final pause in pausesAfter) {
      buffer.write(' [$pause]');
    }

    return buffer.toString();
  }
}

/// Configuration for a dialogue speaker.
class SpeakerConfig {
  /// Creates speaker configuration.
  const SpeakerConfig({
    required this.name,
    required this.voice,
    this.description,
  });

  /// Speaker name used in dialogue lines.
  final String name;

  /// Voice to use for this speaker (e.g., 'aoide', 'charon', 'puck').
  final String voice;

  /// Optional description of the speaker for context.
  final String? description;
}

/// Builder for creating multi-speaker dialogues with Gemini TTS.
///
/// Note: As of Gemini 3.1 Flash TTS preview, voice mixing (where speakers
/// read each other's lines) is a known non-deterministic issue. This builder
/// attempts to minimize this by:
/// - Using explicit speaker prefixes in text
/// - Generating each speaker's lines separately when possible
/// - Adding clear speaker markers
class DialogueBuilder {
  /// Creates a dialogue builder with speaker configurations.
  DialogueBuilder({
    required this.speakers,
    this.context,
  }) : _lines = [];

  /// Speaker configurations by name.
  final Map<String, SpeakerConfig> speakers;

  /// Optional context/scene description to prepend.
  final String? context;

  final List<DialogueLine> _lines;

  /// Adds a line to the dialogue.
  void addLine(DialogueLine line) {
    if (!speakers.containsKey(line.speaker)) {
      throw ArgumentError(
        'Speaker "${line.speaker}" not configured. '
        'Available speakers: ${speakers.keys.join(', ')}',
      );
    }
    _lines.add(line);
  }

  /// Adds multiple lines at once.
  void addLines(List<DialogueLine> lines) {
    for (final line in lines) {
      addLine(line);
    }
  }

  /// Builds the complete dialogue text.
  ///
  /// Returns formatted text with speaker markers and pause tags.
  String buildText() {
    final buffer = StringBuffer();

    if (context != null && context!.isNotEmpty) {
      buffer.writeln('Context: $context');
      buffer.writeln();
    }

    // Add speaker definitions for context
    buffer.writeln('Speakers:');
    for (final speaker in speakers.values) {
      if (speaker.description != null) {
        buffer.writeln('- ${speaker.name}: ${speaker.description}');
      } else {
        buffer.writeln('- ${speaker.name}');
      }
    }
    buffer.writeln();

    // Add dialogue
    for (final line in _lines) {
      buffer.writeln(line.toFormattedText());
    }

    return buffer.toString();
  }

  /// Splits dialogue into speaker-separated chunks.
  ///
  /// This can help reduce voice mixing issues by generating each
  /// speaker's lines separately and concatenating the audio.
  ///
  /// Returns a map of speaker name to their combined text.
  Map<String, String> buildSpeakerSeparatedTexts() {
    final result = <String, String>{};

    for (final speaker in speakers.keys) {
      final speakerLines = _lines.where((l) => l.speaker == speaker);
      if (speakerLines.isEmpty) continue;

      final buffer = StringBuffer();
      for (final line in speakerLines) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.write(line.toFormattedText());
      }
      result[speaker] = buffer.toString();
    }

    return result;
  }

  /// Validates that the dialogue can fit within safe duration limits.
  ///
  /// Returns validation results for the full text and per-speaker texts.
  Map<String, TtsValidationResult> validate({bool perSpeaker = false}) {
    final results = <String, TtsValidationResult>{};

    // Validate full dialogue
    final fullText = buildText();
    results['full'] = TtsValidator.validateTextLength(fullText);

    if (perSpeaker) {
      final separated = buildSpeakerSeparatedTexts();
      for (final entry in separated.entries) {
        results[entry.key] = TtsValidator.validateTextLength(entry.value);
      }
    }

    return results;
  }

  /// Gets all lines for a specific speaker.
  List<DialogueLine> getLinesForSpeaker(String speakerName) {
    return _lines.where((l) => l.speaker == speakerName).toList();
  }

  /// Returns the number of lines in the dialogue.
  int get lineCount => _lines.length;

  /// Returns the number of unique speakers with lines.
  int get activeSpeakerCount {
    final active = _lines.map((l) => l.speaker).toSet();
    return active.length;
  }
}

/// Generator for creating multi-speaker dialogue audio.
///
/// This class helps work around voice mixing issues by providing options
/// for how to generate the audio.
class DialogueGenerator {
  /// Creates a dialogue generator with the given TTS client.
  DialogueGenerator({required this.tts});

  /// The TTS client to use for generation.
  final GeminiTts tts;

  /// Generates dialogue audio by separating speakers.
  ///
  /// This approach generates each speaker's lines separately using their
  /// configured voice, then returns the combined audio bytes. This can
  /// help reduce voice mixing issues.
  ///
  /// Note: Pause timing between speakers will be approximate since audio
  /// is generated separately.
  Future<Map<String, Uint8List>> generatePerSpeaker(
    DialogueBuilder builder, {
    String responseMimeType = 'audio/wav',
    String? directorsNote,
  }) async {
    final results = <String, Uint8List>{};
    final texts = builder.buildSpeakerSeparatedTexts();

    for (final entry in texts.entries) {
      final speaker = entry.key;
      final text = entry.value;
      final config = builder.speakers[speaker]!;

      final bytes = await tts.generate(
        text: text,
        voice: config.voice,
        responseMimeType: responseMimeType,
        directorsNote: directorsNote,
        validateLength: true,
      );

      results[speaker] = bytes;
    }

    return results;
  }

  /// Generates full dialogue in one request.
  ///
  /// This uses the first speaker's voice for the entire dialogue.
  /// Voice mixing may occur with this approach.
  Future<Uint8List> generateUnified(
    DialogueBuilder builder, {
    String? voice,
    String responseMimeType = 'audio/wav',
    String? directorsNote,
  }) async {
    final text = builder.buildText();
    final defaultVoice = voice ?? builder.speakers.values.first.voice;

    return tts.generate(
      text: text,
      voice: defaultVoice,
      responseMimeType: responseMimeType,
      directorsNote: directorsNote,
      validateLength: true,
    );
  }
}
