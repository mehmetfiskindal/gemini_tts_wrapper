import 'package:test/test.dart';
import 'package:gemini_tts_wrapper/gemini_tts_wrapper.dart';

void main() {
  group('GeminiTts', () {
    test('can be instantiated', () {
      expect(GeminiTts(apiKey: 'test-key'), isNotNull);
    });

    test('builds one-shot request JSON', () {
      final req = TtsRequest.oneShot(
        text: 'Merhaba',
        responseMimeType: 'audio/wav',
        voice: 'aoide',
      ).json;

      expect(req['contents'], isA<List<dynamic>>());
      expect(req['generationConfig'], isA<Map<String, dynamic>>());
    });

    test('supports audioProfile and directorsNote', () {
      final req = TtsRequest.oneShot(
        text: 'Hello',
        responseMimeType: 'audio/wav',
        voice: 'aoide',
        audioProfile: 'headphone',
        directorsNote: 'Speak naturally',
      ).json;

      final speechConfig = (req['generationConfig'] as Map<String, dynamic>)['speech_config'] as Map<String, dynamic>;
      expect(speechConfig['audio_profile'], equals('headphone'));
      expect(speechConfig['directors_note'], equals('Speak naturally'));
    });
  });

  group('TtsValidator', () {
    test('validates short text as valid', () {
      final result = TtsValidator.validateTextLength('Hello world');
      expect(result.isValid, isTrue);
    });

    test('detects text that would exceed limit', () {
      // Create text that would be ~200 seconds at 15 chars/sec
      final longText = 'A' * 3000;
      final result = TtsValidator.validateTextLength(longText);
      expect(result.isValid, isFalse);
      expect(result.estimatedSeconds, greaterThan(155));
    });

    test('splits text into chunks', () {
      final longText = 'Sentence one. Sentence two. Sentence three.';
      final chunks = TtsValidator.splitIntoChunks(longText, maxDurationSeconds: 2);
      expect(chunks.length, greaterThan(0));
    });
  });

  group('DialogueBuilder', () {
    test('builds dialogue text', () {
      final builder = DialogueBuilder(
        speakers: {
          'Alice': const SpeakerConfig(name: 'Alice', voice: 'aoide'),
          'Bob': const SpeakerConfig(name: 'Bob', voice: 'charon'),
        },
      );

      builder.addLine(const DialogueLine(speaker: 'Alice', text: 'Hello!'));
      builder.addLine(const DialogueLine(speaker: 'Bob', text: 'Hi there!'));

      final text = builder.buildText();
      expect(text, contains('Alice'));
      expect(text, contains('Bob'));
      expect(text, contains('Hello!'));
      expect(text, contains('Hi there!'));
    });

    test('throws on unknown speaker', () {
      final builder = DialogueBuilder(
        speakers: {
          'Alice': const SpeakerConfig(name: 'Alice', voice: 'aoide'),
        },
      );

      expect(
        () => builder.addLine(const DialogueLine(speaker: 'Unknown', text: 'Hello')),
        throwsArgumentError,
      );
    });
  });
}
