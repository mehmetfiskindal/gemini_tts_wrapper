/// Request payload for Gemini TTS `generateContent`.
///
/// This is intentionally small and JSON-focused so API changes stay localized.
class TtsRequest {
  /// Creates a request with the given raw JSON body.
  const TtsRequest({required this.json});

  /// One-shot TTS request for a single [text].
  ///
  /// This follows the preview-style shape shown in the prompt.
  ///
  /// [audioProfile] - Audio profile for output (e.g., 'default', 'wearable', 'headphone').
  /// Note: As of Gemini 3.1 Flash TTS preview, audio profiles may not work consistently
  /// in all languages.
  ///
  /// [directorsNote] - Director's note for controlling tone and style.
  /// Note: As of Gemini 3.1 Flash TTS preview, director's notes may be ignored
  /// especially in non-English languages like Finnish.
  factory TtsRequest.oneShot({
    required String text,
    required String responseMimeType,
    required String voice,
    String? audioProfile,
    String? directorsNote,
  }) {
    final speechConfig = <String, Object?>{
      'voice_config': {
        'predefined_voice': voice,
      },
      if (audioProfile != null) 'audio_profile': audioProfile,
      if (directorsNote != null) 'directors_note': directorsNote,
    };

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
          'speech_config': speechConfig,
        },
      },
    );
  }

  /// Raw JSON body sent to the API.
  final Map<String, Object?> json;
}
