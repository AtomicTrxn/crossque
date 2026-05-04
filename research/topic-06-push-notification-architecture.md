# Research Topic #6 — Push Notification Architecture

Status: Resolved
Owner: Codex

## Research Question

Should optional puzzle reminders and streak reminders use local notifications, server-triggered push, or a hybrid approach?

## Decision To Unblock

Can the app support useful continue/import reminders without introducing a backend, device tokens, or unnecessary user data collection?

## Recommendation

Use local notifications only, but defer user-facing reminders until Phase 2/post-MVP unless they are deliberately pulled into scope. Let users opt in to reminders from Settings or an in-context prompt after they complete a puzzle. Do not add Firebase Cloud Messaging, APNs server push, device-token registration, or a notification backend unless a later feature truly requires server-originated notifications.

This fits the project's privacy posture: no backend identity, no device tokens, no behavioral targeting, no notification analytics, and no server-side reminder state.

## Architecture Choice

| Option | Pros | Costs / Risks | Recommendation |
|--------|------|---------------|----------------|
| Local notifications | No backend, no tokens, works offline, user-controlled, good for reminders | Less reliable for "new puzzle is available right now" if source fetch timing varies; scheduled notifications can drift with OS power management | Use post-MVP / Phase 2; no remote push |
| Remote push via FCM/APNs | Server can send source-specific alerts, silent refresh, campaign-style messages | Requires backend, device tokens, privacy disclosures, opt-out handling, delivery monitoring, more policy/security surface | Defer |
| Hybrid | Local reminders plus server alerts for special events | Flexible long-term | Too much for MVP | Consider only after backend/sync decision |

## Local Notification Types

| Notification | Trigger | Default | Notes |
|--------------|---------|---------|-------|
| Continue puzzle reminder | User-selected local time when an in-progress puzzle exists | Off | "Pick up where you left off" should open the active puzzle. |
| Import/solve reminder | User-selected local time when no active puzzle exists | Off | Import-first copy; do not imply a daily source exists. |
| Licensed daily puzzle reminder | User-selected local time after a licensed daily source exists | Off | Future-only; opens Home/Today for the licensed source. |
| Streak reminder | User-selected local time if no streak-eligible solve exists today | Off | Optional; avoid guilt-heavy copy. |
| Source failure alert | None | Off | Do not notify. Show in app instead. |
| Marketing/support messages | None | Off | Out of scope. |

No notification should include puzzle answers, clue text, source credentials, or imported file names.

## Permission Strategy

- Never request notification permission on first launch.
- Ask only after the user chooses a reminder feature or after a natural moment, such as completing the first puzzle.
- Explain the benefit before the system prompt.
- Provide Settings controls to:
  - Enable/disable reminders.
  - Choose reminder time.
  - Choose reminder types.
  - Disable sound/vibration where platform support allows.
- If permission is denied, keep the app fully usable and show a gentle link to system settings only when the user revisits reminder settings.

### Android

- Android 13/API 33+ requires runtime `POST_NOTIFICATIONS` permission for non-exempt notifications.
- Targeting Android 13+ gives the app control over when to show the permission prompt.
- Avoid exact alarms for Phase 1. Daily crossword reminders do not need alarm-clock precision.
- Avoid `SCHEDULE_EXACT_ALARM` and `USE_EXACT_ALARM` unless a future feature genuinely needs exact timing and can pass store scrutiny.
- Use normal/inexact scheduled notifications to avoid extra alarm permission friction.

### iOS

- Use `UNUserNotificationCenter` authorization through the Flutter plugin.
- Request only the interaction types needed: alert and optionally sound/badge.
- Ask in context because Apple explicitly frames notifications as potentially disruptive.
- Consider no badges for MVP; badges can create pressure and are not necessary for a calm crossword app.

## Package Choices

| Package | Purpose | Recommendation |
|---------|---------|----------------|
| `flutter_local_notifications` | Cross-platform local notifications and scheduling | Use when Phase 2/post-MVP reminders are pulled into scope, assuming project Flutter SDK can satisfy its current minimum version. |
| `flutter_timezone` | Get device time zone for zoned scheduling | Use with local notifications so daily reminder times behave correctly across time zones/DST. |
| `timezone` | Time zone database used by scheduling APIs | Add as direct dependency if scheduling with `zonedSchedule`. |
| `firebase_messaging` | FCM remote push | Do not add in Phase 1. |

## Data Model Additions

Store notification preferences locally in Drift/settings:

Keys use flat snake_case to match the rest of `app_settings` (see architecture doc settings inventory):

| Setting key | Example value |
|-------------|---------------|
| `daily_reminder_enabled` | `false` |
| `daily_reminder_time` | `"08:30"` |
| `streak_reminder_enabled` | `false` |
| `streak_reminder_time` | `"20:00"` |
| `notifications_sound_enabled` | `false` |
| `notifications_last_scheduled_at` | UTC ISO-8601 timestamp string |

Do not store device tokens in Phase 1 because there should be no remote push.

## Implementation Shape

```dart
abstract class NotificationScheduler {
  Future<NotificationPermissionState> permissionState();
  Future<NotificationPermissionState> requestPermission();
  Future<void> scheduleDailyReminder(LocalTime time);
  Future<void> scheduleStreakReminder(LocalTime time);
  Future<void> cancelDailyReminder();
  Future<void> cancelStreakReminder();
  Future<void> cancelAll();
}
```

Implementation notes:

- Initialize notification plugin without requesting iOS permissions immediately.
- Create Android channels only for reminder categories that are enabled.
- Use stable notification IDs, for example `1001` for daily reminder and `1002` for streak reminder, so rescheduling replaces previous reminders.
- Use payloads like `route=today` or `route=puzzle:{id}` only when the ID is local and non-sensitive.
- Re-schedule notifications when user changes time zone, reminder settings, app version, or after device reboot where platform support requires it.

## Copy Guidance

Keep copy calm and useful:

- `Crosscue reminder`
- `Remind me at 8:30 AM`
- `Pick up where you left off`
- `Ready for a puzzle?`

Avoid:

- Shame/guilt copy about broken streaks.
- Engagement-bait wording.
- Notifications about monetization/support.

## Risks

| Risk | Mitigation |
|------|------------|
| Notification permission prompt shown too early | Ask only after user enables reminders or after first completion. |
| Android exact alarm permission friction | Use inexact local scheduling; do not request exact alarm permission. |
| Time zone / DST issues | Use `zonedSchedule`, `timezone`, and `flutter_timezone`; reschedule on app launch if local zone changed. |
| Notifications feel spammy | Default off, limited types, no marketing, user-set quiet times. |
| Remote push later requires backend | Keep `NotificationScheduler` abstract so FCM can be added later without touching UI code. |

## Open Decisions

| Decision | Lean | Notes |
|----------|------|-------|
| Default reminders on or off? | Off | User should opt in. |
| Exact alarm permission? | No | Not justified for crossword reminders. |
| Badge count? | No for MVP | Badges add pressure and extra permission semantics. |
| Push notification backend? | No for Phase 1 | Revisit only with backend sync or licensed content. |
| Notification analytics? | No | Do not track opens/clicks in Phase 1. |

## Implementation Checklist

1. Add `NotificationScheduler` interface.
2. Add local settings for reminder preferences.
3. Add `flutter_local_notifications`, `timezone`, and `flutter_timezone` only when implementing reminders.
4. Initialize plugin without immediate permission prompt.
5. Add reminder settings UI.
6. Request notification permission only after user enables a reminder.
7. Schedule puzzle/streak reminders with stable IDs.
8. Add route handling for notification taps.
9. Test Android 13+ permission denied/granted flows.
10. Test iOS permission denied/granted flows.
11. Test time zone and DST behavior.
12. Keep `firebase_messaging` out of Phase 1.

## Sources

Accessed April 30, 2026.

- [Flutter local notifications package](https://pub.dev/packages/flutter_local_notifications)
- [Flutter timezone package](https://pub.dev/packages/flutter_timezone)
- [Android notification runtime permission](https://developer.android.com/guide/topics/ui/notifiers/notification-permission)
- [Android exact alarm changes](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms)
- [Firebase Cloud Messaging for Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive)
- [Apple asking permission to use notifications](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications)
- [Apple `UNUserNotificationCenter.requestAuthorization`](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization%28options%3Acompletionhandler%3A%29)
