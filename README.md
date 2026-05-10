# appsprint-flutter

AppSprint mobile attribution SDK for Flutter. It tracks installs, attribution, lifecycle events, custom events, and revenue events, with local event queueing for transient failures.

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  appsprint_flutter: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Quick start

Initialize the SDK as early as possible in app startup:

```dart
import 'package:appsprint_flutter/appsprint_flutter.dart';

await AppSprint.instance.configure(
  const AppSprintConfig(
    apiKey: 'YOUR_API_KEY',
  ),
);
```

### Configuration

| Option | Type | Required | Default |
|---|---|---|---|
| `apiKey` | `String` | Yes | — |
| `apiUrl` | `String` | No | `https://api.appsprint.app` |
| `enableAppleAdsAttribution` | `bool` | No | `true` |
| `isDebug` | `bool` | No | `false` |
| `logLevel` | `int` | No | `2` |
| `customerUserId` | `String?` | No | `null` |

Log levels:

`0 = debug`, `1 = info`, `2 = warn`, `3 = error`

## Android permissions and privacy

The Android package declares `android.permission.INTERNET` and `com.google.android.gms.permission.AD_ID`. The native Android SDK reads the Google Advertising ID during install registration, omits it when Limit Ad Tracking is enabled, and never sends the all-zero advertising ID.

If you publish an Android app with this SDK, include advertising ID collection in your Play Console Data safety answers and privacy policy.

## Sending events

```dart
import 'package:appsprint_flutter/appsprint_flutter.dart';

await AppSprint.instance.sendEvent(AppSprintEventType.login);
await AppSprint.instance.sendEvent(AppSprintEventType.signUp);
await AppSprint.instance.sendEvent(
  AppSprintEventType.purchase,
  params: {
    'revenue': 9.99,
    'currency': 'USD',
  },
);

await AppSprint.instance.sendEvent(
  AppSprintEventType.custom,
  name: 'onboarding_step',
  params: {
    'screen': 'welcome',
    'step': 1,
  },
);
```

Supported `eventType` values:

`login` | `sign_up` | `register` | `purchase` | `subscribe` | `start_trial` | `add_payment_info` | `add_to_cart` | `add_to_wishlist` | `initiate_checkout` | `view_content` | `view_item` | `search` | `share` | `tutorial_complete` | `achieve_level` | `level_start` | `level_complete` | `custom`

Notes:

- Use `eventType: AppSprintEventType.custom` together with the optional `name` argument for custom event names.
- Revenue fields are accepted through `params['revenue']` or `params['price']`, plus `params['currency']`.
- If an event cannot be delivered, it is queued locally and retried on the next initialization or explicit flush.

## Public API

### `AppSprint`

```dart
import 'package:appsprint_flutter/appsprint_flutter.dart';
```

Available methods:

- `AppSprint.instance.configure(config)` initializes the SDK and performs install tracking when needed.
- `sendEvent(eventType, {name, params})` sends or queues an event.
- `sendTestEvent()` sends a diagnostic event and returns `{ success, message }`.
- `flush()` retries queued events immediately.
- `clearData()` clears cached SDK state and the local event queue.
- `isSdkDisabled()` returns whether the SDK has been disabled because the API key was rejected.
- `setCustomerUserId(userId)` updates the customer user id locally and remotely when possible.
- `getAppSprintId()` returns the cached AppSprint install identifier, if available.
- `getAttribution()` returns the last cached attribution result, if available.
- `getAttributionParams()` returns the partner-ready attribution payload.
- `enableAppleAdsAttribution()` re-enables Apple Ads attribution on iOS and returns `false` on Android.
- `isInitialized()` reports whether `configure()` completed.
- `destroy()` removes SDK listeners.

### `AppSprintNative`

```dart
import 'package:appsprint_flutter/appsprint_flutter.dart';
```

Available methods:

- `getDeviceInfo()`
- `getAdServicesToken()`
- `requestTrackingAuthorization()`

Example ATT request on iOS:

```dart
final authorized = await AppSprintNative.requestTrackingAuthorization();
```

## Attribution

The SDK tracks install attribution once an install is registered. You can read the cached values at any time:

```dart
final attribution = await AppSprint.instance.getAttribution();
final appsprintId = await AppSprint.instance.getAppSprintId();
```

`AttributionResult.source` can be:

`apple_ads` | `fingerprint` | `organic`

## Offline and retry behavior

- The SDK keeps up to `100` queued events in local storage.
- Queued events are flushed after `configure()` and when the app moves to the background.
- Failed flushes keep the unsent events queued for a later retry.
- A rejected API key (`401` or `403`) disables the SDK and drops future events until cached data is cleared.

## Local development

Point the SDK at a non-production backend during development:

```dart
await AppSprint.instance.configure(
  const AppSprintConfig(
    apiKey: 'YOUR_API_KEY',
    apiUrl: 'http://localhost:3000',
    isDebug: true,
  ),
);
```

## License

MIT
