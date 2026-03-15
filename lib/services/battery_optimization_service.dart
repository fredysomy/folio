import 'package:flutter/services.dart';

class BatteryOptimizationService {
  static const _channel = MethodChannel('com.example.networth_tracker/battery');

  Future<bool> isIgnoringOptimizations() async {
    try {
      return await _channel.invokeMethod<bool>(
            'isIgnoringBatteryOptimizations',
          ) ??
          true;
    } catch (_) {
      return true;
    }
  }

  Future<void> requestIgnoreOptimizations() async {
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {
      // User might be on an unsupported device; ignore silently.
    }
  }
}
