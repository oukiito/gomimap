// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/foundation.dart';

import '../data/demo_setup_store.dart';
import '../data/update_coordinator.dart';
import 'notification_bridge.dart';
import 'notification_state.dart';

class NotificationController extends ChangeNotifier {
  NotificationController({
    required this.store,
    required this.bridge,
    required this.plan,
  });
  UpdateCoordinator? coordinator;
  final NotificationStateStore store;
  final NotificationsBridge bridge;
  final Map<String, Object?> Function(NotificationSettings) plan;
  Map<String, dynamic> state = {};
  bool busy = false, failed = false;
  bool _disposed = false;
  void changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _queue = Future.value();
  Future<T> serial<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action(), onError: (_) => action());
    _queue = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  Future<bool> pause() async {
    if (!bridge.available) return true;
    try {
      return await bridge.pause();
    } catch (_) {
      return false;
    }
  }

  Future<void> refresh() async {
    final updates = coordinator;
    if (updates != null) {
      await updates.reconcile();
      failed = updates.failed;
      changed();
    } else {
      await serial(_refresh);
    }
  }

  /// Only called inside the update coordinator's serial operation.
  Future<bool> reflectNow() async {
    await _refresh();
    return !failed;
  }

  Future<void> _refresh() async {
    if (!bridge.available) return;
    try {
      failed = !await bridge.apply(plan(store.settings));
      state = await bridge.status();
    } catch (_) {
      failed = true;
      state = {};
    }
    changed();
  }

  Future<bool> save(
    NotificationSettings desired, {
    required bool answer,
  }) async {
    final updates = coordinator;
    if (updates != null) {
      busy = true;
      changed();
      try {
        final committed = await updates.change('notifications', {
          'notifications': desired.toJson(),
          'notificationAnswered': answer,
        }, () => store.save(desired, answer: answer));
        failed = updates.failed;
        return committed;
      } finally {
        busy = false;
        changed();
      }
    }
    return serial(() async {
      busy = true;
      failed = false;
      changed();
      try {
        if (!await pause()) {
          failed = true;
          return false;
        }
        if (!await store.save(desired, answer: answer)) {
          await _refresh();
          failed = true;
          return false;
        }
        await _refresh();
        return true; // Desired save and OS reflection are distinct.
      } finally {
        busy = false;
        changed();
      }
    });
  }

  Future<bool> skip() => save(const NotificationSettings(), answer: true);
}

/// Stop old notifications before a district commits. Keep the current district
/// if stop/save fails; reconcile the old plan if the district write failed.
class NotificationSetupStore implements DemoSetupStore {
  NotificationSetupStore(this.delegate, this.notifications);
  final DemoSetupStore delegate;
  final NotificationController notifications;
  @override
  DemoSetupSnapshot read() => delegate.read();
  @override
  Future<bool> save(DemoSetupSnapshot snapshot) {
    final updates = notifications.coordinator;
    if (updates != null && snapshot.phase == DemoSetupPhase.districtSaved) {
      return updates.change(
        'district',
        {'areaId': snapshot.area!.name},
        () async {
          if (!await notifications.store.ensurePending()) return false;
          return delegate.save(snapshot);
        },
      );
    }
    return notifications.serial(() async {
      if (snapshot.phase != DemoSetupPhase.districtSaved) {
        return delegate.save(snapshot);
      }
      if (!await notifications.store.ensurePending() ||
          !await notifications.pause()) {
        return false;
      }
      final result = await delegate.save(snapshot);
      if (!result) await notifications._refresh();
      return result;
    });
  }
}
