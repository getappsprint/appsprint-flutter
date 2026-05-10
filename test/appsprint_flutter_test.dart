import 'package:appsprint_flutter/appsprint_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('appsprint_flutter/native');
  final calls = <MethodCall>[];
  final responseMap = <String, dynamic>{};

  setUp(() {
    calls.clear();
    responseMap
      ..clear()
      ..addAll({
        'configure': true,
        'sendEvent': true,
        'enableAppleAdsAttribution': true,
        'sendTestEvent': {'success': true, 'message': 'ok'},
        'getAttributionParams': {
          'appsprintId': 'app_123',
          'appstackId': 'app_123',
          'gclid': 'gclid_123',
        },
        'getDeviceInfo': {
          'deviceModel': 'iPhone15,2',
          'locale': 'en-US',
          'gaid': '38400000-8cf0-11bd-b23e-10b96e40000d',
        },
      });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return responseMap[call.method];
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('configure delegates to native channel', () async {
    final configured = await AppSprint.instance.configure(
      const AppSprintConfig(apiKey: 'test-key', isDebug: true),
    );

    expect(configured, true);
    expect(calls.single.method, 'configure');
    expect(calls.single.arguments, {
      'apiKey': 'test-key',
      'apiUrl': 'https://api.appsprint.app',
      'enableAppleAdsAttribution': true,
      'isDebug': true,
      'logLevel': 2,
      'customerUserId': null,
    });
  });

  test('configure rejects empty apiKey before native call', () async {
    expect(
      () => AppSprint.instance.configure(const AppSprintConfig(apiKey: '   ')),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          'AppSprint.configure requires a non-empty apiKey.',
        ),
      ),
    );

    expect(calls, isEmpty);
  });

  test('sendEvent delegates mapped event type and params', () async {
    final sent = await AppSprint.instance.sendEvent(
      AppSprintEventType.purchase,
      name: 'checkout',
      params: {'revenue': 4.99, 'currency': 'USD', 'source': 'test'},
    );

    expect(sent, true);
    expect(calls.single.method, 'sendEvent');
    expect(calls.single.arguments, {
      'eventType': 'purchase',
      'name': 'checkout',
      'revenue': 4.99,
      'currency': 'USD',
      'parameters': {'revenue': 4.99, 'currency': 'USD', 'source': 'test'},
    });
  });

  test('sendEvent accepts price as revenue fallback', () async {
    await AppSprint.instance.sendEvent(
      AppSprintEventType.purchase,
      name: 'checkout',
      params: {'price': 5, 'currency': 'EUR'},
    );

    expect(calls.single.method, 'sendEvent');
    expect(calls.single.arguments, {
      'eventType': 'purchase',
      'name': 'checkout',
      'revenue': 5,
      'currency': 'EUR',
      'parameters': {'price': 5, 'currency': 'EUR'},
    });
  });

  test('public API returns typed values', () async {
    responseMap['getAttribution'] = {
      'isAttributed': true,
      'source': 'tracking_link',
      'matchType': 'ip_user_agent',
      'link': {'id': 'link_123', 'name': 'spring'},
      'utmSource': 'newsletter',
    };
    responseMap['getAppSprintId'] = 'app_123';

    final testResult = await AppSprint.instance.sendTestEvent();
    final attribution = await AppSprint.instance.getAttribution();
    final attributionParams = await AppSprint.instance.getAttributionParams();
    final appSprintId = await AppSprint.instance.getAppSprintId();
    final deviceInfo = await AppSprintNative.getDeviceInfo();

    expect(testResult.success, true);
    expect(testResult.message, 'ok');
    expect(attribution?.isAttributed, true);
    expect(attribution?.source, 'tracking_link');
    expect(attribution?.matchType, 'ip_user_agent');
    expect(attribution?.link?['name'], 'spring');
    expect(attributionParams['gclid'], 'gclid_123');
    expect(appSprintId, 'app_123');
    expect(deviceInfo.deviceModel, 'iPhone15,2');
    expect(deviceInfo.locale, 'en-US');
    expect(deviceInfo.gaid, '38400000-8cf0-11bd-b23e-10b96e40000d');
  });

  test('native utility API surface matches documented wrapper methods', () async {
    await AppSprintNative.getAdServicesToken();
    await AppSprintNative.requestTrackingAuthorization();
    await AppSprint.instance.enableAppleAdsAttribution();
    await AppSprint.instance.destroy();

    expect(calls.map((call) => call.method), containsAll(<String>[
      'getAdServicesToken',
      'requestTrackingAuthorization',
      'enableAppleAdsAttribution',
      'destroy',
    ]));
  });
}
