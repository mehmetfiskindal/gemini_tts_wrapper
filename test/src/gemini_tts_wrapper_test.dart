import 'package:flutter_test/flutter_test.dart';
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
  });
}
