// just_audio's byte source APIs are currently marked experimental.
// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

/// Plays audio bytes directly from memory using just_audio.
class Uint8ListAudioSource extends StreamAudioSource {
  /// Creates an in-memory audio source from a byte buffer.
  Uint8ListAudioSource(this._buffer, {this.contentType = 'audio/wav'});

  final Uint8List _buffer;

  /// MIME type reported to just_audio.
  final String contentType;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final s = start ?? 0;
    final e = end ?? _buffer.length;

    return StreamAudioResponse(
      sourceLength: _buffer.length,
      contentLength: e - s,
      offset: s,
      contentType: contentType,
      stream: Stream<Uint8List>.value(_buffer.sublist(s, e)),
    );
  }
}
