// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract interface class NotificationsBridge {
  bool get available;
  Future<Map<String, dynamic>> status();
  Future<String> requestPermission();
  Future<bool> pause();
  Future<bool> apply(Map<String, Object?> plan);
  Future<bool> test();
  Future<void> openSettings();
  Future<Map<String, dynamic>?> consumeLaunch();
  void onOpen(void Function(Map<String, dynamic>) handler);
}

class AndroidNotificationsBridge implements NotificationsBridge {
  static const channel = MethodChannel('dev.gomimap.gomimap/notifications');
  bool _ready = false;
  @override
  bool get available => _ready;
  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      _ready = await channel.invokeMethod<bool>('available') ?? false;
    } catch (_) {
      _ready = false;
    }
  }

  @override
  Future<Map<String, dynamic>> status() async => Map<String, dynamic>.from(
    await channel.invokeMethod<Map>('status') ?? {},
  );
  @override
  Future<String> requestPermission() async =>
      await channel.invokeMethod<String>('requestPermission') ?? 'denied';
  @override
  Future<bool> pause() async =>
      await channel.invokeMethod<bool>('pause') ?? false;
  @override
  Future<bool> apply(Map<String, Object?> plan) async =>
      await channel.invokeMethod<bool>('apply', jsonEncode(plan)) ?? false;
  @override
  Future<bool> test() async =>
      await channel.invokeMethod<bool>('test') ?? false;
  @override
  Future<void> openSettings() => channel.invokeMethod<void>('openSettings');
  @override
  Future<Map<String, dynamic>?> consumeLaunch() async {
    final result = await channel.invokeMethod<Map>('consumeLaunch');
    return result == null ? null : Map<String, dynamic>.from(result);
  }

  @override
  void onOpen(void Function(Map<String, dynamic>) handler) {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'open' && call.arguments is Map) {
        handler(Map<String, dynamic>.from(call.arguments));
      }
    });
  }
}

class UnavailableNotificationsBridge implements NotificationsBridge {
  const UnavailableNotificationsBridge();
  @override
  bool get available => false;
  @override
  Future<Map<String, dynamic>> status() async => {};
  @override
  Future<String> requestPermission() async => 'denied';
  @override
  Future<bool> pause() async => true;
  @override
  Future<bool> apply(Map<String, Object?> plan) async => false;
  @override
  Future<bool> test() async => false;
  @override
  Future<void> openSettings() async {}
  @override
  Future<Map<String, dynamic>?> consumeLaunch() async => null;
  @override
  void onOpen(void Function(Map<String, dynamic>) handler) {}
}
