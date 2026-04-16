import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:gemini_tts_wrapper/src/models/tts_request.dart';
import 'package:gemini_tts_wrapper/src/services/gemini_api_client.dart';

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
  Future<Uint8List> generate({
    required String text,
    String voice = 'aoide',
    String responseMimeType = 'audio/wav',
  }) {
    final request = TtsRequest.oneShot(
      text: text,
      responseMimeType: responseMimeType,
      voice: voice,
    );

    return _client.generateTtsBytes(model: model, request: request);
  }
}
