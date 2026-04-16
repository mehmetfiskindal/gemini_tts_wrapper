/// Request payload for Gemini TTS `generateContent`.
///
/// This is intentionally small and JSON-focused so API changes stay localized.
class TtsRequest {
  /// Creates a request with the given raw JSON body.
  const TtsRequest({required this.json});

  /// One-shot TTS request for a single [text].
  ///
  /// This follows the preview-style shape shown in the prompt.
  factory TtsRequest.oneShot({
    required String text,
    required String responseMimeType,
    required String voice,
  }) {
    return TtsRequest(
      json: <String, Object?>{
        'contents': [
          {
            'parts': [
              {'text': text},
            ],
          },
        ],
        'generationConfig': {
          // Note: preview docs/examples often use snake_case.
          'response_mime_type': responseMimeType,
          'speech_config': {
            'voice_config': {
              'predefined_voice': voice,
            },
          },
        },
      },
    );
  }

  /// Raw JSON body sent to the API.
  final Map<String, Object?> json;
}
