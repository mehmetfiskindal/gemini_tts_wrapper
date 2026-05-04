## 0.2.0

- Add `DialogueBuilder` utility for creating multi-speaker dialogues with speaker configuration and pause tags.
- Add `DialogueGenerator` for generating multi-speaker dialogue audio (per-speaker or unified generation).
- Add `TtsValidator` for text length validation and automatic chunking to work around ~160 second API limit.
- Add `TtsLengthException` thrown when text exceeds safe duration limits.
- Add `audioProfile` parameter to `generate()` method for audio output profiles.
- Add `directorsNote` parameter to `generate()` method for tone/style control.
- Add `validateLength` option to `generate()` method (enabled by default) for automatic length validation.
- Add pause tag support (`[short pause]`, `[medium pause]`, `[long pause]`) in dialogue text.
- Add speaker-separated text generation to help reduce voice mixing issues.
- Update example app with multi-speaker dialogue demo.
- Add comprehensive tests for new utilities.

## 0.1.0

- Add one-shot Gemini TTS REST client (`GeminiTts`) returning audio bytes.
- Add `Uint8ListAudioSource` helper for in-memory playback with `just_audio`.
- Include a runnable Flutter example app.
