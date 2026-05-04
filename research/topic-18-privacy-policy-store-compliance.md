# Research Topic #18 — Privacy Policy & Store Compliance

Status: Resolved
Implementation Status: ⬜ Pending — required before Play Store submission; human review required before publishing
Owner: Claude

## Research Question

What privacy policy content is required before Play Store submission, what does the Google Play Data Safety form require, and what is the minimum viable policy for a no-accounts, no-ads, crash-reporting-only app?

## Decision To Unblock

A privacy policy URL is mandatory for Google Play Store submission. The Data Safety form must be completed accurately before any release. Neither exists yet.

> **Important:** This research summarises requirements and provides a draft. The final published privacy policy must be reviewed by the developer (Tom Hess) before publication. This is not legal advice.

---

## Google Play Requirements

### What Google Requires

1. A publicly accessible **privacy policy URL** must be provided in the Play Store listing before any app that collects or handles personal data can be submitted.
2. The **Data Safety form** in Play Console must be completed for every release. It asks:
   - Does the app collect data?
   - Is data shared with third parties?
   - Is data encrypted in transit?
   - Can users request data deletion?
3. For apps targeting children or mixed audiences, additional Family Policy compliance applies. Crosscue is not targeted at children — confirm this in the store listing.

### Crosscue Phase 1 Data Footprint

| Data type | Collected? | Shared? | Where stored |
|-----------|-----------|---------|-------------|
| Puzzle content (imported files) | No — parsed locally, not transmitted | No | Device only |
| Solve progress (guesses, timer, stats) | No — local only | No | Device only |
| Crash / error reports | Yes — if user enables (default: off; opt-in in Settings → Privacy) | Yes — Sentry or Firebase Crashlytics | Crash reporter |
| User feedback (optional) | Yes — if user submits | Yes — email or feedback tool | Email / support tool |
| Analytics | No | No | N/A |
| Advertising IDs | No | No | N/A |
| Device identifiers | App-generated UUID only (not IDFA/GAID) | No | Device only via Drift |
| Location | No | No | N/A |

**Play Data Safety answers (Phase 1):**
- Data collected: Yes (crash reports and feedback if user submits)
- Data types collected: App activity (crash/error info), App info (version, build, device model)
- Data shared with third parties: Yes (crash reporter — Sentry or Crashlytics)
- Data encrypted in transit: Yes
- Users can request deletion: Yes (crash report data subject to Sentry/Crashlytics deletion policy; local data deleted by uninstalling the app)
- Data is required for core app function: No (crash reporting is optional/togglable)

---

## Apple App Store Requirements (Phase 2)

- Privacy Nutrition Label (App Privacy section in App Store Connect) must be completed
- Categories: Diagnostics (crash data), Usage Data (if analytics added later)
- No tracking data (no IDFA, no cross-app tracking)
- Privacy policy URL required in App Store listing

---

## Minimum Viable Privacy Policy

The following draft is scoped to Phase 1. It should be published at a stable URL before Play Store submission (e.g. `https://example.com/crosscue/privacy` or a GitHub Pages page).

---

### Draft Privacy Policy — Crosscue

**Effective date:** [DATE]
**Developer:** Tom Hess
**Contact:** contact@example.com

#### What Crosscue Does Not Collect

Crosscue does not collect, store, or transmit:

- Your name, email address, or any account information
- Your puzzle answers, guesses, or solve history (this stays on your device)
- Puzzle files you import
- Advertising identifiers or device fingerprints
- Location data

#### What Crosscue May Collect

**Crash reports (optional, toggleable in Settings):**
When crash reporting is enabled (opt-in; off by default — see Settings → Privacy), Crosscue sends anonymous diagnostic information to [Sentry / Firebase Crashlytics] when the app crashes or encounters an error. This may include:
- App version and build number
- Device model and Android version
- A generated anonymous identifier (not linked to you or your Google account)
- The screen or feature active at the time of the crash
- Technical error details

This data is used only to diagnose and fix bugs. It does not include puzzle content, solve history, or any personally identifiable information. You can disable crash reporting at any time in Settings → Privacy.

**Feedback (optional, user-initiated):**
If you submit feedback through the app, you may choose to include your email address. This is entirely optional and is used only to respond to your feedback.

#### Local Data

All puzzle files, solve progress, stats, and settings are stored locally on your device. This data is included in your device's standard Android backup (via Google Auto Backup) to your Google account if you have backup enabled in Android Settings. Crosscue does not have access to your Google account or your backup data.

#### Third-Party Services

| Service | Purpose | Privacy policy |
|---------|---------|---------------|
| Sentry (or Firebase Crashlytics) | Crash and error reporting | [Link] |

#### Your Rights

You can:
- Disable crash reporting at any time in Settings → Privacy
- Delete all local app data by uninstalling Crosscue
- Request deletion of crash report data by contacting contact@example.com

#### Children

Crosscue is not directed at children under 13. If you believe a child has submitted personal information, please contact us at the address above.

#### Changes to This Policy

We may update this policy as the app adds new features. We will note the effective date above when it changes. Significant changes will be noted in the app's release notes.

#### Contact

contact@example.com

---

## Implementation Checklist

1. Publish the privacy policy at a stable public URL before Play Store submission. A GitHub Pages static page or a page on `raptortech.com` are both suitable.
2. Confirm the crash reporter vendor (Sentry vs. Firebase Crashlytics — see topic-05) and insert the correct name and privacy policy link into the published policy.
3. Complete the Play Console Data Safety form using the answers in the table above.
4. Add the privacy policy URL to the Play Store listing (Store Presence → App Content → Privacy Policy).
5. Add an "About Crosscue" entry in Settings (see topic-17 §12) linking to the privacy policy URL.
6. Confirm `android:hasFragileUserData="true"` is set in `AndroidManifest.xml` if the app intends to support data deletion on uninstall prompt (Android 10+).
7. When Phase 2 adds notifications, update the policy to mention notification identifiers (though these remain local with `flutter_local_notifications`).
8. When any analytics are added (Phase 2+), update the policy and Data Safety form before releasing.
9. Re-review for GDPR/UK GDPR applicability before EU/UK release (crash reporters may require a Data Processing Agreement with the vendor).

## Open Questions

| Question | Lean | Notes |
|----------|------|-------|
| Host privacy policy where? | `raptortech.com/crosscue/privacy` or GitHub Pages | Must be a stable, publicly accessible URL — not a local file |
| GDPR applicability? | Low risk for Phase 1 | App is local-only except crash reporter; check crash reporter's DPA before EU distribution |
| California CCPA? | Low risk | No sale of data, no advertising identifiers; review before US release if analytics are added |
| Delete crash data on request? | Yes, via vendor | Sentry and Crashlytics both support data deletion requests; document the process |

## Sources

- [Google Play Data Safety requirements](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Google Play privacy policy requirement](https://support.google.com/googleplay/android-developer/answer/9867108)
- [Apple App Store privacy nutrition labels](https://developer.apple.com/app-store/app-privacy-details/)
- [Sentry privacy policy](https://sentry.io/privacy/)
- [Firebase privacy and security](https://firebase.google.com/support/privacy)
- Internal: [topic-05-analytics-crash-reporting.md](topic-05-analytics-crash-reporting.md)
- Internal: [topic-04-monetization-model.md](topic-04-monetization-model.md)
