# Research Topic #8 — CI/CD And Release Pipeline

Status: Resolved
Owner: Codex

## Research Question

What CI/CD, signing, flavor, test, artifact, and Play Store release workflow should the Flutter app use?

## Decision To Unblock

What release pipeline should be set up early enough to avoid painful store-release surprises, while staying lightweight before the app has production signing and store accounts?

## Recommendation

Use GitHub Actions for CI from the start, with separate lanes for validation, unsigned/debug artifacts, and later signed release artifacts. For Phase 1 development, automate analysis/tests and build Android debug/profile artifacts. Defer automated Play Store and App Store uploads until package IDs, signing keys, store listings, privacy disclosures, and release ownership are settled.

Prefer a single Flutter flavor initially (`dev` can be configuration-only), and introduce formal `dev/staging/prod` flavors only when backend endpoints, store app IDs, or source/license environments require them.

Use fastlane later for store upload and metadata management, not as the first CI dependency. The earliest pipeline should be boring: `flutter pub get`, `flutter analyze`, `flutter test`, build artifacts, upload artifacts.

## Pipeline Stages

| Stage | Trigger | Purpose | Recommendation |
|-------|---------|---------|----------------|
| PR validation | Pull request / branch push | Catch analyzer, formatting, tests, and build issues | Add first |
| Android artifact build | Main branch or manual dispatch | Produce installable artifact for device testing | Add early, unsigned/debug first |
| Android signed release build | Release tag/manual dispatch | Produce Play Store `.aab` | Add when upload keystore and Play Console exist |
| Play Store internal track upload | Manual dispatch/tag | Upload `.aab` to internal testing | Add near beta |
| iOS validation build | Manual/macOS runner | Verify iOS compiles | Add before iOS Phase 2 |
| TestFlight upload | Manual dispatch/tag | Upload `.ipa` to TestFlight | Add when Apple Developer/App Store Connect setup exists |

## Recommended GitHub Actions Jobs

### `validate`

Run on every PR and push:

- Check out code.
- Set up Flutter using a pinned version.
- Run `flutter pub get`.
- Run formatting check once code exists: `dart format --set-exit-if-changed .`.
- Run `flutter analyze`.
- Run `flutter test`.

### `android_debug_artifact`

Run on main or manual dispatch:

- Build an APK for manual install: `flutter build apk --debug` or `flutter build apk --profile`.
- Upload artifact with `actions/upload-artifact`.
- Do not include hidden files in artifacts.

### `android_release_candidate`

Add later:

- Decode upload keystore from GitHub Actions secrets.
- Generate `key.properties` at build time.
- Run `flutter build appbundle --release`.
- Upload `.aab` as a short-lived artifact.
- Optionally upload to Play internal testing with fastlane `upload_to_play_store`.

### `ios_release_candidate`

Add later on macOS runner:

- Use Xcode/macOS runner.
- Set up Flutter.
- Install CocoaPods dependencies.
- Configure signing.
- Run `flutter build ipa`.
- Upload to TestFlight manually or with fastlane `pilot`.

## Versioning

Use Flutter's `version: x.y.z+build` in `pubspec.yaml`.

Recommended policy:

- `x.y.z`: user-visible release version.
- `build`: monotonically increasing integer for stores.
- CI release builds should pass `--build-name` and `--build-number` only if there is a single source of truth, such as tag + run number.
- Keep changelog/release notes in repo once public releases begin.

Suggested pre-release convention:

- Internal builds: `0.1.0+<github_run_number>`.
- First public MVP: `1.0.0+<build>`.

## Android Signing

Follow Flutter's Android release docs:

- Use Android App Bundles (`.aab`) for Play Store.
- Use Play App Signing.
- Create an upload keystore.
- Store the keystore outside git.
- In CI, store keystore as encrypted/base64 GitHub secret plus passwords/alias as separate secrets.
- Generate `android/key.properties` during CI and keep it gitignored.
- Never upload keystore or key properties as artifacts.

Required secrets later:

- `ANDROID_UPLOAD_KEYSTORE_BASE64`
- `ANDROID_UPLOAD_KEYSTORE_PASSWORD`
- `ANDROID_UPLOAD_KEY_ALIAS`
- `ANDROID_UPLOAD_KEY_PASSWORD`
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`

## iOS Signing

iOS release automation is not needed for Android Phase 1, but plan for it:

- Requires macOS runner and Xcode.
- Requires Apple Developer Program.
- Requires Bundle ID and App Store Connect app record.
- For CI signing, use either manually managed certificates/profiles or fastlane `match`.
- fastlane `match` can store encrypted signing assets in a private git repo/cloud bucket and should run read-only on CI.
- TestFlight upload can use App Store Connect API keys through fastlane `pilot`.

Required secrets later:

- App Store Connect API key ID.
- App Store Connect issuer ID.
- App Store Connect private key.
- Match storage credentials/passphrase if using `match`.

## Fastlane Use

Do not start with fastlane unless store upload is imminent.

Use fastlane later for:

- Play Store internal track upload via `upload_to_play_store` / `supply`.
- Play metadata management under `fastlane/metadata/android`.
- TestFlight upload via `pilot`.
- iOS signing sync via `match` if needed.

Add a `Gemfile` and commit `Gemfile.lock` if fastlane is introduced, so CI uses a pinned fastlane version.

## Flavors

Start simple:

- One package/application ID for now.
- Use build-time Dart defines for feature toggles or local config.
- Add formal flavors only when needed.

If flavors become necessary:

| Flavor | Use |
|--------|-----|
| `dev` | Local development, debug services, non-store package ID |
| `staging` | Internal testing with release-like config |
| `prod` | Store release |

Avoid flavor explosion; it multiplies signing, store, and QA work.

## Quality Gates

Minimum before merging:

- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`

Before beta:

- Android release build succeeds.
- Smoke test install on a physical Android device.
- Accessibility smoke test for grid.
- Import and solve fixture puzzle.
- Crash reporter disabled/enabled settings tested.
- No accidental secrets in artifacts.

Before public release:

- Store privacy labels / Play Data Safety complete.
- Terms/source legal review complete.
- Android target SDK current enough for Play requirements.
- Release signing verified.
- Backup/restore or data migration tested if schema changed.

## Suggested Initial Workflow

```yaml
name: Flutter CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - run: dart format --set-exit-if-changed .
      - run: flutter analyze
      - run: flutter test
```

Add artifact build only after a Flutter app exists:

```yaml
  android-artifact:
    runs-on: ubuntu-latest
    needs: validate
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter build apk --debug
      - uses: actions/upload-artifact@v4
        with:
          name: android-debug-apk
          path: build/app/outputs/flutter-apk/app-debug.apk
          if-no-files-found: error
          retention-days: 7
```

## Risks

| Risk | Mitigation |
|------|------------|
| Store signing delayed until release week | Create upload keystore and Play internal track before beta. |
| Secrets leak through artifacts | Never include hidden files; explicitly upload only known build outputs. |
| iOS automation consumes time too early | Defer until Phase 2; manual TestFlight first is acceptable. |
| Flutter version drift breaks CI | Pin Flutter version in workflow or project tool config. |
| Flavors create maintenance overhead | Add only when there are real environment differences. |

## Open Decisions

| Decision | Lean | Notes |
|----------|------|-------|
| CI provider | GitHub Actions | Good default if repo is on GitHub. |
| Store upload automation | Defer | Add when internal testing tracks exist. |
| Android artifact type | Debug/profile APK early, release AAB later | APK is easier for manual testing; AAB is for Play. |
| iOS CI | Defer | Android Phase 1 does not need it. |
| Fastlane | Later | Useful for store upload/metadata, not needed for first validation CI. |
| Flavors | Defer | Use one app ID until environment differences appear. |

## Implementation Checklist

1. Add `.github/workflows/flutter-ci.yml` once the Flutter app exists.
2. Pin Flutter version.
3. Add format/analyze/test jobs.
4. Add Android debug artifact upload after first app scaffold.
5. Create Android upload keystore before beta.
6. Add signed `.aab` build job using GitHub secrets.
7. Set up Play Console internal testing track.
8. Add fastlane only when uploading to Play/TestFlight becomes a regular workflow.
9. Add iOS build/TestFlight automation during iOS Phase 2.
10. Document release checklist in repo before first public release.

## Sources

Accessed April 30, 2026.

- [Flutter Android build and release docs](https://docs.flutter.dev/deployment/android)
- [Flutter iOS build and release docs](https://docs.flutter.dev/deployment/ios)
- [subosito/flutter-action](https://github.com/subosito/flutter-action)
- [GitHub Actions upload-artifact](https://github.com/actions/upload-artifact)
- [fastlane Android release deployment](https://docs.fastlane.tools/getting-started/android/release-deployment/)
- [fastlane `upload_to_play_store`](https://docs.fastlane.tools/actions/upload_to_play_store)
- [fastlane `pilot` / TestFlight upload](https://docs.fastlane.tools/actions/pilot/)
- [fastlane `match` / code signing](https://docs.fastlane.tools/actions/match/)
