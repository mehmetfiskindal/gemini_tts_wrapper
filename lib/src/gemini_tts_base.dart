import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:gemini_tts_wrapper/src/models/tts_request.dart';
import 'package:gemini_tts_wrapper/src/services/gemini_api_client.dart';
import 'package:gemini_tts_wrapper/src/utils/tts_validator.dart';

/// Public facade for one-shot (non-streaming) TTS generation.
class GeminiTts {
  /// Creates a TTS facade using the provided [apiKey].
  GeminiTts({
    required String apiKey,
    Dio? dio,
    this.model = 'gemini-3.1-flash-tts-preview',
  }) : _client = GeminiApiClient(apiKey: apiKey, dio: dio);

  final GeminiApiClient _client;

  /// Model name used in the Generative Language API endpoint.
  ///
  /// Example: `gemini-3.1-flash-tts-preview`.
  final String model;

  /// Generates audio bytes (default: WAV) for the given [text].
  ///
  /// [audioProfile] - Audio profile for output (e.g., 'default', 'wearable', 'headphone').
  /// Note: As of Gemini 3.1 Flash TTS preview, audio profiles may not work consistently.
  ///
  /// [directorsNote] - Director's note for controlling tone and style.
  /// Note: As of Gemini 3.1 Flash TTS preview, director's notes may be ignored in some languages.
  ///
  /// Throws [TtsLengthException] if text exceeds estimated safe duration limit (~160 seconds).
  Future<Uint8List> generate({
    required String text,
    String voice = 'aoide',
    String responseMimeType = 'audio/wav',
    String? audioProfile,
    String? directorsNote,
    bool validateLength = true,
  }) {
    if (validateLength) {
      final validation = TtsValidator.validateTextLength(text);
      if (!validation.isValid) {
        throw TtsLengthException(
          text,
          validation.estimatedSeconds,
          validation.message,
        );
      }
    }

    final request = TtsRequest.oneShot(
      text: text,
      responseMimeType: responseMimeType,
      voice: voice,
      audioProfile: audioProfile,
      directorsNote: directorsNote,
    );

    return _client.generateTtsBytes(model: model, request: request);
  }
}
