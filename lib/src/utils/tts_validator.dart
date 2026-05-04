/// Exception thrown when TTS text exceeds safe duration limits.
class TtsLengthException implements Exception {
  /// Creates a length exception with details.
  const TtsLengthException(this.text, this.estimatedSeconds, this.message);

  /// The text that was too long.
  final String text;

  /// Estimated duration in seconds.
  final double estimatedSeconds;

  /// Human-readable explanation.
  final String message;

  @override
  String toString() =>
      'TtsLengthException: $message (estimated: ${estimatedSeconds.toStringAsFixed(1)}s)';
}

/// Validation result for TTS text length.
class TtsValidationResult {
  /// Creates a validation result.
  const TtsValidationResult({
    required this.isValid,
    required this.estimatedSeconds,
    required this.message,
  });

  /// Whether the text passes validation.
  final bool isValid;

  /// Estimated audio duration in seconds.
  final double estimatedSeconds;

  /// Human-readable message about the validation.
  final String message;
}

/// Validator for TTS requests to help work around API limitations.
///
/// As of Gemini 3.1 Flash TTS preview, there is a hard stop around 160 seconds
/// of audio output, even though the API accepts unlimited text input.
class TtsValidator {
  // Average speaking rates (characters per second) for different languages.
  // These are conservative estimates that account for natural pauses.
  static const _avgCharsPerSecond = 15.0; // ~150 words per minute
  static const _maxSafeDurationSeconds = 155.0; // 5 second buffer from 160s limit

  /// Validates text length against known API limitations.
  ///
  /// Returns a [TtsValidationResult] with estimated duration and validity.
  static TtsValidationResult validateTextLength(String text) {
    // Rough estimation: average speaking rate
    final estimatedSeconds = text.length / _avgCharsPerSecond;

    if (estimatedSeconds > _maxSafeDurationSeconds) {
      return TtsValidationResult(
        isValid: false,
        estimatedSeconds: estimatedSeconds,
        message:
            'Text may exceed the ~160 second audio limit of Gemini 3.1 Flash TTS. '
            'Consider splitting into chunks of ${_maxSafeDurationSeconds.toInt()} seconds or less. '
            'Your text is estimated at ${estimatedSeconds.toStringAsFixed(0)} seconds.',
      );
    }

    return TtsValidationResult(
      isValid: true,
      estimatedSeconds: estimatedSeconds,
      message:
          'Text length OK (estimated ${estimatedSeconds.toStringAsFixed(0)}s audio)',
    );
  }

  /// Estimates audio duration for the given text in seconds.
  static double estimateDuration(String text) {
    return text.length / _avgCharsPerSecond;
  }

  /// Splits text into chunks that should fit within the safe duration limit.
  ///
  /// Attempts to split at sentence boundaries for natural breaks.
  static List<String> splitIntoChunks(
    String text, {
    double maxDurationSeconds = _maxSafeDurationSeconds,
  }) {
    final maxChars = (maxDurationSeconds * _avgCharsPerSecond).floor();
    final chunks = <String>[];
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));

    var currentChunk = StringBuffer();
    var currentLength = 0;

    for (final sentence in sentences) {
      final sentenceLength = sentence.length;

      if (currentLength + sentenceLength > maxChars && currentLength > 0) {
        // Start a new chunk
        chunks.add(currentChunk.toString().trim());
        currentChunk = StringBuffer(sentence);
        currentLength = sentenceLength;
      } else {
        currentChunk.write(sentence);
        currentLength += sentenceLength;
      }
    }

    // Add the last chunk if not empty
    if (currentLength > 0) {
      chunks.add(currentChunk.toString().trim());
    }

    return chunks;
  }
}
