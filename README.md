# gemini_tts_wrapper

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![Powered by Mason](https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge)](https://github.com/felangel/mason)
[![License: MIT][license_badge]][license_link]

Client-side (REST) Gemini TTS wrapper for **one-shot** audio output.

This package calls the Generative Language API `:generateContent` endpoint with
`response_mime_type` set to an audio type (default: `audio/wav`) and returns the
decoded audio bytes as `Uint8List`.

It also includes `Uint8ListAudioSource` to play those bytes directly from memory
via `just_audio` (no temporary file required).

## Security Note

Using a long-lived Gemini API key directly in a client app is **not secure**.
For production, prefer a server-side proxy (Cloud Functions, Cloud Run, etc.)
and short-lived tokens or additional auth.

## Installation 💻

**❗ In order to start using Gemini Tts Wrapper you must have the [Flutter SDK][flutter_install_link] installed on your machine.**

Install via `flutter pub add`:

```sh
flutter pub add gemini_tts_wrapper
```

## Usage

### Basic Usage

Generate one-shot TTS audio bytes:

```dart
import 'package:gemini_tts_wrapper/gemini_tts_wrapper.dart';

final tts = GeminiTts(apiKey: 'YOUR_API_KEY');
final bytes = await tts.generate(
  text: 'Merhaba dunya!',
  voice: 'aoide',
  responseMimeType: 'audio/wav',
);
```

### Advanced Options

```dart
final bytes = await tts.generate(
  text: 'Your text here',
  voice: 'aoide',  // 'aoide', 'charon', or 'puck'
  responseMimeType: 'audio/wav',
  audioProfile: 'headphone',  // May not work in all languages
  directorsNote: 'Speak in a casual, natural tone',  // May be ignored
);
```

### Play Audio

Play in-memory bytes with `just_audio`:

```dart
import 'package:just_audio/just_audio.dart';
import 'package:gemini_tts_wrapper/gemini_tts_wrapper.dart';

final player = AudioPlayer();
await player.setAudioSource(Uint8ListAudioSource(bytes, contentType: 'audio/wav'));
await player.play();
```

### Dialogue/Multi-Speaker Support

To work around voice mixing issues in dialogues, use the `DialogueBuilder`:

```dart
final builder = DialogueBuilder(
  context: 'A conversation at a coffee shop',
  speakers: {
    'Alice': SpeakerConfig(name: 'Alice', voice: 'aoide'),
    'Bob': SpeakerConfig(name: 'Bob', voice: 'charon'),
  },
);

builder.addLines([
  DialogueLine(speaker: 'Alice', text: 'Hey Bob!'),
  DialogueLine(
    speaker: 'Bob',
    text: 'Hi Alice!',
    pausesBefore: ['medium pause'],  // [short pause] may not work
  ),
]);

final generator = DialogueGenerator(tts: tts);
final audioSegments = await generator.generatePerSpeaker(builder);
```

### Text Length Validation

The wrapper includes validation to warn about the ~160 second audio limit:

```dart
final result = TtsValidator.validateTextLength(longText);
if (!result.isValid) {
  print('Warning: ${result.message}');
  // Split into chunks
  final chunks = TtsValidator.splitIntoChunks(longText);
}
```

## Known API Limitations (Gemini 3.1 Flash TTS Preview)

⚠️ **Important:** The Gemini 3.1 Flash TTS API has several known limitations:

### 1. ~160 Second Audio Hard Limit
- The API accepts unlimited text input but hard-stops audio generation around 160 seconds
- This wrapper validates text length and throws `TtsLengthException` if the estimated duration exceeds safe limits
- Use `TtsValidator.splitIntoChunks()` to split long text into manageable segments

### 2. Voice Mixing in Dialogues
- Speakers frequently read each other's lines (non-deterministic behavior)
- **Workaround**: Use `DialogueGenerator.generatePerSpeaker()` to generate each speaker's lines separately
- The example app demonstrates this approach

### 3. Audio Profile & Director's Note
- These parameters may not work consistently, especially in non-English languages (e.g., Finnish)
- Voices may default to dramatic/fake tones even when casual/natural is requested
- These options are available but your mileage may vary

### 4. Pause Tags
- `[short pause]` tags are often ignored by the API
- **Workaround**: Use `[medium pause]` or `[long pause]` instead
- The `DialogueLine` class includes helper properties for adding pauses

### 5. Chunking Required for Long Content
- For content longer than ~160 seconds of audio, you must implement chunking
- The wrapper provides `TtsValidator` utilities to help estimate and split content appropriately

## Example App

Run the included example:

```sh
cd example
flutter run
```

The example includes:
- Basic TTS generation with all available options
- Text length validation with warnings
- A complete dialogue demo showing multi-speaker support

---

## Continuous Integration 🤖

Gemini Tts Wrapper comes with a built-in [GitHub Actions workflow][github_actions_link] powered by [Very Good Workflows][very_good_workflows_link] but you can also add your preferred CI/CD solution.

Out of the box, on each pull request and push, the CI `formats`, `lints`, and `tests` the code. This ensures the code remains consistent and behaves correctly as you add functionality or make changes. The project uses [Very Good Analysis][very_good_analysis_link] for a strict set of analysis options used by our team. Code coverage is enforced using the [Very Good Workflows][very_good_coverage_link].

---

## Running Tests 🧪

For first time users, install the [very_good_cli][very_good_cli_link]:

```sh
dart pub global activate very_good_cli
```

To run all unit tests:

```sh
very_good test --coverage
```

To view the generated coverage report you can use [lcov](https://github.com/linux-test-project/lcov).

```sh
# Generate Coverage Report
genhtml coverage/lcov.info -o coverage/

# Open Coverage Report
open coverage/index.html
```

[flutter_install_link]: https://docs.flutter.dev/get-started/install
[github_actions_link]: https://docs.github.com/en/actions/learn-github-actions
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[logo_black]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_white.png#gh-dark-mode-only
[mason_link]: https://github.com/felangel/mason
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_link]: https://pub.dev/packages/very_good_cli
[very_good_coverage_link]: https://github.com/marketplace/actions/very-good-coverage
[very_good_ventures_link]: https://verygood.ventures
[very_good_ventures_link_light]: https://verygood.ventures#gh-light-mode-only
[very_good_ventures_link_dark]: https://verygood.ventures#gh-dark-mode-only
[very_good_workflows_link]: https://github.com/VeryGoodOpenSource/very_good_workflows
