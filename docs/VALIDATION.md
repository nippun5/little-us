# Validation and deployment status

## Completed

- Flutter 3.35.7 / Dart 3.9.2 dependency resolution.
- Flutter static analysis.
- Five Flutter tests: reward visibility and idempotency, purchase balance protection, persistence and deletion, question rotation, and all five tabs at 360 × 800 logical pixels.
- Separate screenshot-rendering test with production fonts at 432 × 768 logical pixels, exported at 2.5× to 1080 × 1920. Visually reviewed; missing decorative glyphs removed and small-screen overflow fixed.
- Release web compilation.
- Fifteen SQL assertions in PGlite (PostgreSQL) with a mocked Supabase auth schema: direct access denied, outsider isolation, one-time invitation, hidden answers, reveal, reward once, duplicate rejection, decoration charging, insufficient funds, note storage/isolation, home deletion, notes/rounds cascade, account removal.
- Export dimensions and PNG integrity checked for all five store assets.

## Not performed here

- Live Supabase Auth/email confirmation and two-phone synchronization: no project credentials supplied.
- Android APK/AAB compilation, signing, emulator/physical-device testing: Android SDK unavailable.
- iOS compilation/signing: no macOS/Xcode.
- Play Console upload or publication.
- Real-world email delivery, recovery, hosting retention, accessibility audit, load/concurrency testing, or penetration testing.

## Environment notes

Flutter's initial startup tried cloud metadata detection and was blocked. Reading the SDK source identified its supported CI-mode branch, which avoids the metadata request. Subsequent Flutter checks ran with CI mode and telemetry suppression. A browser capture could not run under the environment's Unix-socket restriction; the screenshots instead use Flutter's own headless renderer and the app's real widgets.

The local SQL harness checks database behavior, not Supabase service deployment, email flows, network authorization headers, or production operational configuration. The full policy remains a publication draft until operator details and retention settings are supplied.
