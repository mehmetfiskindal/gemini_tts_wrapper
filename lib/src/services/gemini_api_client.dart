import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:gemini_tts_wrapper/src/models/tts_request.dart';

/// Low-level HTTP client for Gemini (Generative Language API).
class GeminiApiClient {
  /// Creates an HTTP client for the Generative Language API.
  GeminiApiClient({required this.apiKey, Dio? dio}) : _dio = dio ?? Dio();

  /// API key used as `?key=` query parameter.
  final String apiKey;
  final Dio _dio;

  /// Calls `:generateContent` for the given [model] and returns audio bytes.
  ///
  /// Expects the response to include Base64 audio data.
  Future<Uint8List> generateTtsBytes({
    required String model,
    required TtsRequest request,
  }) async {
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$url?key=$apiKey',
        data: request.json,
        options: Options(
          responseType: ResponseType.json,
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data;
      if (data == null) {
        throw const FormatException('Empty JSON response.');
      }

      final base64Audio = _extractBase64Audio(data);
      return base64Decode(base64Audio);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      throw Exception('TTS request failed (status=$status): $body');
    } on FormatException catch (e) {
      throw Exception('Unexpected TTS response format: ${e.message}');
    }
  }

  String _extractBase64Audio(Map<String, dynamic> json) {
    // Common (nonstandard) shortcut used in some wrappers/examples.
    final direct = json['audio_data'];
    if (direct is String && direct.isNotEmpty) return direct;

    // Typical `generateContent` shape:
    // candidates[0].content.parts[0].inlineData.data
    final candidates = json['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final c0 = candidates.first;
      if (c0 is Map) {
        final content = c0['content'];
        if (content is Map) {
          final parts = content['parts'];
          if (parts is List) {
            for (final p in parts) {
              if (p is Map) {
                // Some APIs use `inlineData`, some `inline_data`.
                final inline = p['inlineData'] ?? p['inline_data'];
                if (inline is Map) {
                  final data = inline['data'];
                  if (data is String && data.isNotEmpty) return data;
                }
              }
            }
          }
        }
      }
    }

    throw FormatException(
      'Could not find Base64 audio data in response keys: '
      '${json.keys.toList()}. '
      'Expected `audio_data` or '
      '`candidates[0].content.parts[*].inlineData.data`.',
    );
  }
}
