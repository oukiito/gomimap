// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract interface class HomeWidgetBridge {
  bool get available;
  Future<void> initialize();
  Future<bool> publish(String projection);
  Future<bool> pinSupported();
  Future<bool> requestPin();
  Future<bool> isAdded();
  Future<bool> consumeLaunch();
  void setOpenTodayHandler(VoidCallback callback);
}

class AndroidHomeWidgetBridge implements HomeWidgetBridge {
  static const channel = MethodChannel('dev.gomimap.gomimap/home_widget');
  @override
  bool get available => _ready;
  bool _ready = false;
  @override
  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      _ready = await channel.invokeMethod<bool>('available') ?? false;
    } catch (_) {
      _ready = false;
    }
  }

  @override
  Future<bool> publish(String projection) => _bool('publish', projection);
  @override
  Future<bool> pinSupported() => _bool('pinSupported');
  @override
  Future<bool> requestPin() => _bool('requestPin');
  @override
  Future<bool> isAdded() => _bool('isAdded');
  @override
  Future<bool> consumeLaunch() => _bool('consumeLaunch');
  Future<bool> _bool(String method, [Object? arguments]) async {
    if (!available) return false;
    try {
      return await channel.invokeMethod<bool>(method, arguments) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  void setOpenTodayHandler(VoidCallback callback) {
    if (!available) return;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'openToday') callback();
    });
  }
}

class UnavailableHomeWidgetBridge implements HomeWidgetBridge {
  const UnavailableHomeWidgetBridge();
  @override
  bool get available => false;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> publish(String projection) async => false;
  @override
  Future<bool> pinSupported() async => false;
  @override
  Future<bool> requestPin() async => false;
  @override
  Future<bool> isAdded() async => false;
  @override
  Future<bool> consumeLaunch() async => false;
  @override
  void setOpenTodayHandler(VoidCallback callback) {}
}
