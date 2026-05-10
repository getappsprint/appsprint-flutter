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
        'sendTestEvent': {'success': true, 'message': 'ok'},
        'getDeviceInfo': {'deviceModel': 'iPhone15,2', 'locale': 'en-US'},
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
    await AppSprint.instance.configure(
      const AppSprintConfig(apiKey: 'test-key', isDebug: true),
    );

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
    await AppSprint.instance.sendEvent(
      AppSprintEventType.purchase,
      name: 'checkout',
      params: {'revenue': 4.99, 'currency': 'USD', 'source': 'test'},
    );

    expect(calls.single.method, 'sendEvent');
    expect(calls.single.arguments, {
      'eventType': 'purchase',
      'name': 'checkout',
      'revenue': 4.99,
      'currency': 'USD',
      'parameters': {'revenue': 4.99, 'currency': 'USD', 'source': 'test'},
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
    final appSprintId = await AppSprint.instance.getAppSprintId();
    final deviceInfo = await AppSprintNative.getDeviceInfo();

    expect(testResult.success, true);
    expect(testResult.message, 'ok');
    expect(attribution?.isAttributed, true);
    expect(attribution?.source, 'tracking_link');
    expect(attribution?.matchType, 'ip_user_agent');
    expect(attribution?.link?['name'], 'spring');
    expect(appSprintId, 'app_123');
    expect(deviceInfo.deviceModel, 'iPhone15,2');
    expect(deviceInfo.locale, 'en-US');
  });

  test('native utility API surface matches documented wrapper methods', () async {
    await AppSprintNative.getAdServicesToken();
    await AppSprintNative.requestTrackingAuthorization();
    await AppSprint.instance.destroy();

    expect(calls.map((call) => call.method), containsAll(<String>[
      'getAdServicesToken',
      'requestTrackingAuthorization',
      'destroy',
    ]));
  });
}
