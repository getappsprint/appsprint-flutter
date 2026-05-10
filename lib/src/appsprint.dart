import 'appsprint_native.dart';
import 'types.dart';

class AppSprint {
  AppSprint._();

  static final AppSprint instance = AppSprint._();

  Future<bool> configure(AppSprintConfig config) {
    if (config.apiKey.trim().isEmpty) {
      throw ArgumentError.value(
        config.apiKey,
        'apiKey',
        'AppSprint.configure requires a non-empty apiKey.',
      );
    }

    return AppSprintNative.configure({
      'apiKey': config.apiKey,
      'apiUrl': config.apiUrl,
      'enableAppleAdsAttribution': config.enableAppleAdsAttribution,
      'isDebug': config.isDebug,
      'logLevel': config.logLevel,
      'customerUserId': config.customerUserId,
    });
  }

  Future<bool> sendEvent(AppSprintEventType eventType, {String? name, Map<String, Object?>? params}) {
    return AppSprintNative.sendEvent({
      'eventType': appSprintEventTypeValues[eventType],
      'name': name,
      'revenue': params?['revenue'] ?? params?['price'],
      'currency': params?['currency'],
      'parameters': params,
    });
  }

  Future<TestEventResult> sendTestEvent() async {
    final result = await AppSprintNative.sendTestEvent();
    return TestEventResult(
      success: result?['success'] as bool? ?? false,
      message: result?['message'] as String? ?? 'Unknown error',
    );
  }

  Future<void> flush() => AppSprintNative.flush();

  Future<void> clearData() => AppSprintNative.clearData();

  Future<void> setCustomerUserId(String userId) => AppSprintNative.setCustomerUserId(userId);

  Future<bool> enableAppleAdsAttribution() => AppSprintNative.enableAppleAdsAttribution();

  Future<String?> getAppSprintId() => AppSprintNative.getAppSprintId();

  Future<AttributionResult?> getAttribution() async {
    final raw = await AppSprintNative.getAttribution();
    if (raw == null) return null;
    return AttributionResult.fromJson(raw);
  }

  Future<Map<String, String>> getAttributionParams() => AppSprintNative.getAttributionParams();

  Future<bool> isInitialized() => AppSprintNative.isInitialized();

  Future<bool> isSdkDisabled() => AppSprintNative.isSdkDisabled();

  Future<void> destroy() => AppSprintNative.destroy();
}
