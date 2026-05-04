# Research Topic #4 — Monetization Model

Status: Resolved
Owner: Codex

## Research Question

Which monetization model should the app use, and what architecture does that imply for entitlements, paywalls, analytics, subscriptions, and store policy compliance?

## Decision To Unblock

Should monetization be built into Phase 1, and if so, which model avoids harming the core daily solving experience or creating store-policy risk?

## Recommendation

Ship Phase 1 as a free, no-ads, import-first app. Local puzzle import is enough for MVP; add a rights-cleared sample puzzle or explicitly licensed free feed only if it is available before launch. Build a lightweight entitlement boundary in the architecture, but avoid ad SDKs entirely. If support is included in the free version, make it store-managed voluntary support IAP, not external payments.

Use one support path for now:

1. Free app + voluntary `Supporter` tips inside the app.

Do not commit to a separate Pro app or a Pro unlock yet. Keep the entitlement boundary flexible enough to support Pro later, but treat it as a future product decision after the free app has real usage.

If Pro ever happens, suitable Pro benefits are app-owned convenience features, not third-party puzzle content: advanced stats, extra themes, custom icons, archive organization, backup/export tools, or home-screen widgets. Do not charge for access to free publisher content unless source licenses explicitly allow that model.

Use subscriptions only if the app later provides sustained recurring value, such as hosted cross-device sync, original licensed puzzle packs, or a maintained premium source service. Avoid subscriptions for one-time unlocks.

## Model Evaluation

| Model | Recommendation | Pros | Risks / Costs |
|-------|----------------|------|---------------|
| Free, no ads | Use for Phase 1 | Simplest launch, best UX, avoids ad privacy complexity, aligns with current source uncertainty | Revenue depends on voluntary support |
| Optional tip/supporter IAP | Good Phase 1 or Phase 2 support path | Low friction, store-compliant, keeps app fully usable | Must be framed as creator support, not charitable donation; still needs IAP handling |
| Paid Pro app | Defer | Simple user mental model if a paid tier becomes necessary | Premature now; separate app/listing overhead, duplicated release management, data migration/upgrade handoff |
| One-time Pro unlock IAP | Defer | Clear value if app-owned premium features emerge | Premature now; requires paywall/entitlement handling inside the app |
| Subscription | Defer | Works if recurring service value exists | Needs sustained value, cancellation/refund handling, clearer paywall copy, likely backend entitlement validation |
| Ads | Do not use | None worth the tradeoff for this product | Hurts solving focus, adds privacy/consent burden, ad SDKs, app privacy disclosures, possible Families/age-rating complications |
| Paid app download | Avoid initially | Simple store commerce | Raises trial friction before source/content quality is proven |
| External payments / Stripe | Avoid for digital app features | Useful for physical goods/services or web-only payments | Store policy risk for in-app digital goods; region-specific exceptions are complex |

## Store Policy Implications

### Google Play

- Google Play Billing is required for in-app purchases of digital goods, digital content, app functionality, subscriptions, ad-free versions, and cloud services in Play-distributed apps unless a specific exception/program applies.
- Apps generally must not lead users to non-Play payment methods for in-app digital goods unless enrolled in an eligible alternative/external billing program.
- Subscriptions must be transparent and provide sustained recurring value; one-time benefits should be sold as in-app products instead.

### Apple App Store

- Digital goods and in-app functionality should use Apple's In-App Purchase system unless a specific guideline/entitlement applies.
- Restorable purchases require restore support.
- Subscriptions need clear pricing, renewal, and value disclosure, and should map to ongoing value.
- App privacy disclosures are required for data collected by the app and third-party SDKs.

### Donations / Support

Avoid calling payments "donations" unless the recipient and flow qualify under store rules and local law. For this app, label voluntary payments as `Supporter`, `Tip`, or `Buy me a coffee`, and process them through store IAP if they are offered in the app.

Recommended copy:

- `Support development`
- `Buy a coffee`
- `Become a supporter`

Avoid:

- `Donate` unless this is legally/charitably true.
- Links to external payment pages from the app for digital support purchases unless a fresh store-policy review confirms the exact region and entitlement path.

## Flutter Package / Service Choices

| Need | Candidate | Recommendation |
|------|-----------|----------------|
| No ads | No ad package | Hard requirement. Do not add `google_mobile_ads` or other ad SDKs. |
| Simple support/tip IAP | `in_app_purchase` | Good first-party Flutter plugin for App Store and Google Play purchases. Use for voluntary support tiers. Requires product setup in each store, purchase-update handling, completion, restore, and local support status cache. |
| Subscriptions/cross-platform entitlement | `purchases_flutter` / RevenueCat | Consider only if subscriptions or server-side receipt validation become real needs. Adds third-party service dependency but simplifies entitlement tracking, webhooks, and subscription analytics. |
| Ads | None | Explicitly out of scope. |
| Stripe/external payments | `flutter_stripe` | Do not use for in-app digital feature unlocks in normal App Store / Play Store distribution. Consider only for physical goods, services consumed outside the app, or explicitly eligible region-specific external payment programs after legal review. |

## Architecture Implications

Add an app-internal entitlement boundary now without adding payment SDKs:

```dart
abstract class EntitlementService {
  Future<Entitlements> current();
  Stream<Entitlements> watch();
  Future<void> restorePurchases();
}

class FreeEntitlementService implements EntitlementService {
  // Phase 1: returns free defaults, no store dependency.
}
```

Suggested entitlement flags:

- `isSupporter`
- `supportTier`
- `isPro`
- `hasAdvancedStats`
- `hasCustomThemes`
- `hasHomeWidget`
- `hasCloudSync`

Note: export/import (`hasBackupExport`) is a **free feature** (see [topic-09](topic-09-backend-sync-decision.md) and [topic-17 §12](topic-17-ux-missing-details.md)); do not gate it behind Pro.

Keep all core solving features available without payment. If Pro features arrive later, gate only app-owned convenience features. Do not gate accessibility, basic local import, core solving, progress save/resume, or legally required attribution.

## Product Recommendation

### Free Version

- Free app.
- No ads.
- No premium source access.
- Store-managed support tiers are the preferred monetization model for now.
- Support tiers should not unlock essential solving features. They can unlock a small badge, supporter acknowledgement, or simply exist as voluntary support.

### Pro Version / Pro Unlock

- Undecided and deferred.
- Do not design around Pro until the free app has usage data and clear feature demand.
- If Pro becomes necessary, prefer a one-app `Pro` unlock IAP over a separate paid listing unless store positioning or user trust strongly favors a separate app.
- Benefits: extra themes, advanced stats, alternate app icons, archive tools, backup/export, and optional widgets.
- Include restore purchases.
- Keep copy clear: "Support development and unlock extras" rather than implying puzzle-source ownership.

### Separate Paid App Alternative

A separate paid `Pro` app can work, but it creates release and migration overhead:

- Two store listings.
- Two install bases.
- More QA/release management.
- Harder free-to-Pro data transfer.
- Potential confusion over which app has which features.

Recommendation: do not choose a separate paid app now. Keep this as a later decision if support tiers are insufficient or if a clear Pro feature bundle emerges.

### Phase 3 Candidate

- Subscription only if backend sync, licensed content, or hosted services create recurring operating cost and recurring value.
- Use RevenueCat or a small backend for server-side validation if entitlement must survive devices and accounts.

## Privacy And Analytics Impact

- No ads keeps the privacy surface small and avoids advertising identifiers.
- IAP support adds purchase metadata and restore flows, but it is much lighter than ads.
- Avoid purchase-event analytics beyond what is needed to debug support and entitlement state unless the privacy policy and store disclosures are ready.
- If RevenueCat is used later, update privacy policy, App Store privacy labels, and Play Data Safety before release.

## Open Decisions

| Decision | Lean | Notes |
|----------|------|-------|
| Should Phase 1 include payments? | Optional support IAP only | Fine if it is lightweight and store-managed; skip if it slows the MVP. |
| First paid product? | Support tiers | Fits the free version without forcing a paid/free product split. |
| Separate Pro app or one-app Pro unlock? | Undecided, defer | Do not choose until there is feature demand and usage data. |
| Ads ever? | No | Daily solving should feel calm and respectful. |
| Subscription ever? | Only with sync/licensed content/service costs | Must provide sustained recurring value. |
| External payments? | No for in-app digital features | Use store billing unless a future legal/policy review says otherwise. |

## Implementation Checklist

1. Add `EntitlementService` and `FreeEntitlementService` when app architecture starts.
2. If support tiers are scheduled, add `in_app_purchase` and define store product IDs:
   - `support.small`
   - `support.medium`
   - `support.large`
3. Implement purchase restore before release.
4. Make supporter UI read entitlement flags from `EntitlementService`.
5. Do not add ad SDKs.
6. Write store copy that frames payments as voluntary support, not charitable donations.
7. Re-review Apple and Google payment policies immediately before release because external-link and alternative-billing rules are changing.

## Sources

Accessed April 30, 2026.

- [Google Play Payments policy](https://support.google.com/googleplay/android-developer/answer/9858738?hl=en)
- [Understanding Google Play's Payments policy](https://support.google.com/googleplay/android-developer/answer/10281818?hl=en)
- [Google Play Subscriptions policy](https://support.google.com/googleplay/android-developer/answer/9900533?hl=en)
- [Apple App Store Guidelines hub](https://developer.apple.com/app-store/guidelines/)
- [Apple In-App Purchase overview](https://developer.apple.com/in-app-purchase/)
- [Apple User Privacy and Data Use](https://developer.apple.com/app-store/user-privacy-and-data-use/)
- [Flutter `in_app_purchase` package](https://pub.dev/packages/in_app_purchase)
- [RevenueCat `purchases_flutter` package](https://pub.dev/packages/purchases_flutter)
- [Google Mobile Ads Flutter package](https://pub.dev/packages/google_mobile_ads)
- [Google AdMob Flutter quick start](https://developers.google.com/admob/flutter/quick-start)
- [Stripe Flutter package](https://pub.dev/packages/flutter_stripe)
