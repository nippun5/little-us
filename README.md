# Little us

A colorful Flutter MVP for long-distance couples: a cozy shared home and an asynchronous Know Me Better game. Includes Android, iOS, and web project scaffolds, Supabase SQL, a persistent offline demo, and a Play Store asset kit.

## What works

- Illustrated interactive room: tap the cards, calendar, and pinned note.
- Email/password accounts and private invitation pairing when Supabase is configured.
- Three daily questions: choose your own answers and predict your partner’s.
- Server-enforced answer reveal after both submit; 30 shared hearts per completed round.
- Four sofa colors, purchased with earned hearts; owned colors are free to switch.
- Shared notes, deletion, reunion date picker, and countdown.
- Refresh on pull and every 15 seconds while the app is running.
- Account deletion and shared-home erasure, with explicit confirmation.
- Offline demo with local persistence and an explicitly labeled simulated partner action.

This is an MVP, not a published service. No chat, calls, photos, notifications, AI, ads, payments, or real-time sockets are included. The initial question library has 21 prompts rotating weekly; editing the ordering changes the interpretation of saved answers, so version the question catalog before changing it in a live release. Hearts are fictional and have no monetary value.

## Run the offline demo

Validated using Flutter 3.35.7 / Dart 3.9.2. Use the committed pubspec.lock for reproducible dependencies. This project uses supabase_flutter 2.18.3, whose initialization supports `publishableKey`.

```sh
flutter pub get
flutter run
```

Choose **Explore the demo home**. Demo state stays on the device. **Us → Delete local demo data** clears it. **Exit demo** keeps the state for later.

## Connect two phones

1. Create a Supabase project. Run `supabase/schema.sql` once in its SQL editor. It is intended for a new project and is not an idempotent migration.
2. Enable email/password authentication, require email confirmation, and configure your SMTP provider and confirmation site URL. Users confirm in their browser, then return to the app to sign in. No email-link session redirect is required by this MVP.
3. Set an appropriate minimum password length (at least eight), authentication rate limits, and project security settings. Never put a service-role key in this app.
4. Copy `config.example.json` to `config.json` and enter your project URL and publishable key. The define name `SUPABASE_ANON_KEY` is retained for compatibility; use the project's public/publishable client key, never its secret key.
5. Run `flutter run --dart-define-from-file=config.json` on each device.
6. Create and verify two different accounts. Person A creates a home and privately shares the generated code. Person B selects **I have an invite code** and joins.
7. Submit a round on both devices; refresh to reveal answers and receive hearts. Test note syncing, room changes, and deletion with disposable accounts before inviting real users.

The client does not directly read/write application tables. Authenticated RPC functions enforce membership and protect unrevealed answers. Invitations expire in seven days and become unusable after pairing. SQL uses row locks for purchases and round rewards. Direct table access is revoked and RLS is enabled with no table policies. The server uses UTC for daily round boundaries; reunion dates are displayed as local calendar dates.

There is no password recovery UI in this MVP. Configure and add a tested recovery flow before public launch. Supabase session storage uses the SDK's default local persistence, not a custom encrypted vault. Consider a secure-storage adapter for a production threat model. Content is NOT end-to-end encrypted.

## Validation

```sh
flutter analyze
flutter test
flutter build web --release
```

Tests cover local persistence/deletion, one-time rewards, purchases, deterministic question rotation, and narrow phone layouts. `supabase/verify.mjs` exercises real PostgreSQL semantics using PGlite with a minimal mock auth schema. It checks permissions, outsider access, hidden answers, rewards, duplicate submissions, purchases, and deletion cascades. It is not a replacement for a live Supabase Auth/network test.

```sh
cd supabase
npm install
npm test
```

See `docs/VALIDATION.md` for checks performed and remaining deployment work. No Android SDK or macOS/Xcode build was available here; native APK/AAB/iOS compilation and physical-device tests remain required.

## Build Android for release

Change `com.littleus.little_us` to an application ID you own before your first upload. Install the Android SDK required by your Flutter release. Configure your own upload keystore using `android/key.properties.example`; keep signing secrets out of source control.

```sh
flutter build appbundle --release --dart-define-from-file=config.json
```

The Gradle file does not silently sign release builds with a debug key. Without `android/key.properties`, it produces an unsigned release or the build tool may require signing configuration. Supply your real upload key for Play Console. Never ship a build with `SCREENSHOT=true`; that flag boots directly into the offline demonstration.

## Store deliverables

- `store/app-icon-512.png`: 512 × 512 PNG.
- `store/feature-graphic-1024x500.png`: 1024 × 500, opaque RGB PNG.
- Three screenshots: 1080 × 1920 PNG, captured directly with the Flutter rendering engine at phone dimensions with fictional demo data. Native Android status bars/system insets will differ; recapture on the final Android build before store submission.
- `docs/PRIVACY_POLICY.md` and `.html`: publication draft matching this implementation.
- `docs/DELETE_ACCOUNT.md` and `.html`: external deletion-request page template.
- `docs/PLAY_STORE.md`: listing copy, asset descriptions, and release checklist.

The generated brand illustrations were created with the built-in image-generation tool and exported to the requested dimensions. Prompts are in `store/ARTWORK.md`. Fonts are bundled for offline use; their SIL Open Font Licenses are in assets.

## Before publishing

Supply your legal operator name, support email, public policy URL, public deletion URL, project region, and verified backup/log retention periods. Publish those pages on HTTPS. Link the full published policy from the app (the included in-app summary is not a substitute for a completed policy). Monitor the deletion mailbox. Update the in-app policy summary after the full policy is finalized.

Complete Data safety using the actual deployed backend and SDK behavior, not an assumption that a couples app collects no data. Confirm your Play target API, signing, content rating, account deletion, and store audience requirements in Play Console. Implement a recovery flow, investigate polling/battery usage on physical devices, test text scaling and accessibility with real names, and run two-device acceptance tests.

## Project map

- `lib/main.dart` — application screens and navigation.
- `lib/room.dart` — responsive room illustration and object tap targets.
- `lib/store.dart` — demo persistence, auth, RPC actions, polling.
- `lib/models.dart` — question and decoration catalogs.
- `supabase/schema.sql` — backend schema and protected RPCs.
- `test/` — Flutter state and layout tests.
