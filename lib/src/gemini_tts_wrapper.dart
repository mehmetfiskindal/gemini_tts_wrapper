import 'dart:typed_data';

// Kept for backward compatibility as a deprecated facade.
// ignore_for_file: remove_deprecations_in_breaking_versions

import 'package:dio/dio.dart';

import 'package:gemini_tts_wrapper/src/gemini_tts_base.dart';

/// Backward-compatible wrapper around [GeminiTts].
///
/// Prefer using [GeminiTts] directly.
@Deprecated('Use GeminiTts instead.')
class GeminiTtsWrapper {
  /// Creates a wrapper which delegates to [GeminiTts].
  @Deprecated('Use GeminiTts instead.')
  GeminiTtsWrapper({
    required String apiKey,
    Dio? dio,
    String model = 'gemini-3.1-flash-tts-preview',
  }) : _tts = GeminiTts(apiKey: apiKey, dio: dio, model: model);

  final GeminiTts _tts;

  /// Generates audio bytes (default: WAV) for the given [text].
  @Deprecated('Use GeminiTts.generate instead.')
  Future<Uint8List> generate({
    required String text,
    String voice = 'aoide',
    String responseMimeType = 'audio/wav',
  }) {
    return _tts.generate(
      text: text,
      voice: voice,
      responseMimeType: responseMimeType,
    );
  }
}
