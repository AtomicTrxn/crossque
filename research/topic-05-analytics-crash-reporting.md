# Research Topic #5 — Analytics & Crash Reporting

Status: Resolved
Owner: Codex

## Research Question

What should the app instrument, which analytics/crash tools should it use, and what consent/privacy model is required?

## Decision To Unblock

What telemetry should be added early so the team can debug crashes and understand core product health without compromising the app's calm, privacy-respecting posture?

## Recommendation

Add bug/feedback and crash reporting early, but do not add general product analytics in Phase 1. Prefer Sentry for crash/error reporting plus an explicit user-initiated feedback path. Keep the internal analytics interface as a no-op or local debug logger unless a future feature has a specific, written measurement need.

If the project already chooses Firebase for push notifications or backend-adjacent features, Firebase Crashlytics is also a reasonable crash-reporting choice. Avoid adding both Sentry and Firebase Crashlytics. Pick one crash pipeline.

Do not use ad identifiers, session replay, heatmaps, broad autocapture, behavioral funnels, or background usage profiling. Do not log clue text, puzzle answers, user-entered letters, imported file names, source credentials, raw URLs containing tokens, precise solve behavior, or per-user puzzle history.

The default stance is data minimization: collect the least data that still lets the developer receive feedback, diagnose crashes, and fix bugs.

## Tool Evaluation

| Tool | Use Case | Pros | Risks / Costs | Recommendation |
|------|----------|------|----------------|----------------|
| Sentry Flutter | Crash/error reporting, non-fatal exceptions, release health, performance if enabled | Strong Flutter support, native crash support, offline caching, good issue triage, can avoid Firebase dependency | Third-party SDK; must configure PII and sampling carefully | Preferred Phase 1 crash reporter if no Firebase dependency exists |
| Firebase Crashlytics | Crash/error reporting integrated with Firebase | Mature mobile crash pipeline, Flutter support, native crashes, custom keys, opt-in collection support | Pulls app toward Firebase stack; automatic collection defaults need explicit privacy choices | Good alternative if Firebase is already chosen |
| Firebase Analytics | Product analytics | Common mobile analytics, integrates with Crashlytics breadcrumbs and Firebase ecosystem | Can collect by default unless configured; heavier privacy/store disclosure surface | Avoid for Phase 1 |
| PostHog Flutter | Product analytics, feature flags, possible self-hosting | Open-source friendly, event analytics, self-host option | More product analytics surface than needed for MVP | Avoid for Phase 1 |
| Amplitude Flutter | Product analytics | Strong product analytics, official Flutter SDK | More growth-product oriented; additional vendor and consent surface | Avoid |

## Phase 1 Data Collection Scope

### User-Initiated Feedback

Provide a feedback/bug report flow that lets the user control what is sent.

Capture only with explicit user action:

- User-written description.
- Optional contact email if the user chooses to include it.
- App version, build number, platform, OS version, device model/class, locale.
- Optional diagnostic bundle toggle, default off or clearly explained.

Do not attach puzzle content, screenshots, source credentials, imported files, or solve history by default. If a screenshot or diagnostic attachment is ever added, show a preview/summary and require explicit confirmation.

### Crash/Error Reporting

Capture:

- Fatal Flutter errors.
- Uncaught async/zoned errors.
- Native crashes where the selected SDK supports them.
- Non-fatal parser/source errors with sanitized context.
- App version, build number, platform, OS version, device class, locale, and source ID.

Do not capture:

- Puzzle answers.
- Player guesses.
- Full clue text.
- User credentials or cookies.
- Raw source response bodies.
- Imported file names if they may contain personal information.
- Per-user puzzle history.
- Precise solve behavior or timing.

Recommended custom crash keys:

| Key | Example | Notes |
|-----|---------|-------|
| `screen` | `solve` | Current top-level screen only |
| `source_id` | `guardian` | No URL/token |
| `puzzle_format` | `ipuz` | Format only |
| `grid_size` | `15x15` | Safe aggregate context |
| `offline_mode` | `true` | Useful for source/cache errors |
| `app_theme` | `dark` | Helpful for UI rendering issues |
| `accessibility_text_scale` | `1.3` | Helps diagnose layout issues |

### Product Analytics

Do not enable product analytics in Phase 1. Keep `AnalyticsService` as a no-op or debug-only interface so app code does not grow direct vendor calls.

If analytics is later approved, use a small event taxonomy only for specific product questions. These events are examples of the maximum acceptable scope, not Phase 1 requirements:

| Event | Properties |
|-------|------------|
| `app_opened` | `version`, `platform`, `build` |
| `puzzle_started` | `source_id`, `format`, `grid_size`, `is_offline` |
| `puzzle_completed` | `source_id`, `format`, `grid_size`, `elapsed_bucket`, `used_check`, `used_reveal` |
| `puzzle_imported` | `format`, `grid_size`, `success` |
| `source_fetch_failed` | `source_id`, `error_category`, `status_code_bucket` |
| `support_screen_viewed` | none or `entry_point` |
| `support_purchase_started` | `tier` |
| `support_purchase_completed` | `tier` |

Avoid precise solve times in analytics. Use buckets like `<5m`, `5-15m`, `15-30m`, `30m+`. Keep this entire section disabled unless the user-facing privacy model and a concrete measurement question exist.

## Consent And Privacy Model

- Crash reporting should be user-controllable from Settings. The conservative path is an onboarding/settings toggle for `Share crash reports`.
- Product analytics should be off in Phase 1. If added later, it should be opt-in.
- Provide a Settings privacy section with:
  - `Send feedback`
  - `Share crash reports`
  - `Share anonymous usage analytics` only if analytics is later added
  - `Reset analytics identifier` if the selected analytics SDK supports it
- Persist the user's choice locally.
- In debug builds, disable remote crash and analytics collection by default.
- For EU/UK/California users, avoid non-essential analytics until consent UX and privacy policy are ready.
- Provide plain-language copy that says the app does not sell data, does not use ads, and does not collect puzzle answers or typed guesses.

## Architecture Implications

Add app-owned interfaces so vendor choice stays swappable:

```dart
abstract class CrashReporter {
  Future<void> setEnabled(bool enabled);
  Future<void> setContext(Map<String, Object?> context);
  Future<void> recordError(Object error, StackTrace stack, {
    String? reason,
    bool fatal = false,
  });
}

abstract class AnalyticsService {
  Future<void> setEnabled(bool enabled);
  Future<void> track(String event, Map<String, Object?> properties);
}

abstract class FeedbackReporter {
  Future<void> sendFeedback(FeedbackReport report);
}
```

Recommended implementations:

- `NoopAnalyticsService` for Phase 1 if analytics is deferred.
- `DebugAnalyticsService` for local development logs.
- `SentryCrashReporter` or `FirebaseCrashReporter`, not both.
- `EmailFeedbackReporter`, `GitHubIssueFeedbackReporter`, or `SentryUserFeedbackReporter` depending on preferred workflow.

## Implementation Notes

### If Using Sentry

- Use `sentry_flutter`.
- Disable or sample performance tracing unless needed.
- Do not enable broad PII collection.
- Consider Sentry user feedback for crash-adjacent bug reports, but do not attach puzzle content automatically.
- Configure environment names: `dev`, `staging`, `production`.
- Upload debug symbols/source maps as part of release CI if obfuscation/split debug info is used.
- Scrub breadcrumbs and custom contexts to prevent puzzle content leakage.

### If Using Firebase Crashlytics

- Use `firebase_crashlytics`.
- Disable automatic collection natively if implementing opt-in.
- Use `setCrashlyticsCollectionEnabled` from the user's privacy setting.
- Wire `FlutterError.onError`, zoned errors, and isolate errors.
- Add custom keys, not unique values in exception messages.
- Ensure symbol upload/dSYM configuration works in CI/release builds.

### If Using Firebase Analytics

- Do not use `firebase_analytics` in Phase 1.
- Use it only after consent/store disclosure decisions.
- Use `setAnalyticsCollectionEnabled`.
- Reset analytics data if the user opts out and the SDK supports it.
- Keep event names stable and properties low-cardinality.

## Event Naming Rules

- Use snake_case.
- Keep event names action-based: `puzzle_started`, `puzzle_completed`.
- Keep properties low-cardinality.
- Never include free-form clue text, answer text, guesses, file paths, or raw exception messages as analytics properties.
- Bucket sensitive numeric values.

## Open Decisions

| Decision | Lean | Notes |
|----------|------|-------|
| Crash vendor | Sentry unless Firebase is already needed | Avoid adding Firebase only for crashes if Sentry is simpler for the stack. |
| Product analytics vendor | None in Phase 1 | Use an interface and debug/no-op implementation only. |
| Crash collection default | User-controllable | Safer: ask/toggle in Settings. |
| Usage analytics default | Off | Add only with explicit opt-in and concrete measurement need. |
| Session replay/heatmaps | No | Too invasive for a puzzle app. |
| Feedback channel | User-initiated only | User controls description, contact info, and any diagnostics. |

## Implementation Checklist

1. Add `CrashReporter` and `AnalyticsService` interfaces.
2. Add `FeedbackReporter`.
3. Add `NoopAnalyticsService` and `DebugAnalyticsService`.
4. Choose one crash reporter: Sentry or Firebase Crashlytics.
5. Add privacy settings for feedback, crash reports, and future anonymous usage analytics.
6. Disable remote collection in debug builds.
7. Add crash context keys with no puzzle content.
8. Keep product analytics disabled in Phase 1.
9. Update App Store privacy labels, Play Data Safety, and privacy policy before release.
10. Add CI/release steps for symbol upload if the selected crash reporter requires it.

## Sources

Accessed April 30, 2026.

- [Sentry Flutter docs](https://docs.sentry.io/platforms/flutter/)
- [Sentry Dart package](https://pub.dev/packages/sentry)
- [Firebase Crashlytics overview](https://firebase.google.com/docs/crashlytics)
- [Firebase Crashlytics Flutter custom reports](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports)
- [Firebase Crashlytics deobfuscated reports for Flutter](https://firebase.google.com/docs/crashlytics/flutter/get-deobfuscated-reports)
- [Firebase Analytics data collection controls](https://firebase.google.com/docs/analytics/configure-data-collection)
- [PostHog Flutter package](https://pub.dev/packages/posthog_flutter)
- [Amplitude Flutter package](https://pub.dev/packages/amplitude_flutter)
