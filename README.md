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

Play in-memory bytes with `just_audio`:

```dart
import 'package:just_audio/just_audio.dart';
import 'package:gemini_tts_wrapper/gemini_tts_wrapper.dart';

final player = AudioPlayer();
await player.setAudioSource(Uint8ListAudioSource(bytes, contentType: 'audio/wav'));
await player.play();
```

## Example App

Run the included example:

```sh
cd example
flutter run
```

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
