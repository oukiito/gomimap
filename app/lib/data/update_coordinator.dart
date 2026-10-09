// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/foundation.dart';

import 'update_journal.dart';

/// Durable saga for one committed setting/data change and its OS effects.
/// Actual committed state decides recovery, including a crash between writes.
class UpdateCoordinator extends ChangeNotifier {
  UpdateCoordinator({
    required this.journal,
    required this.readState,
    required this.stop,
    required this.reflect,
  });
  final UpdateJournal journal;
  final Map<String, Object?> Function() readState;
  final Future<bool> Function() stop, reflect;
  bool busy = false, failed = false;
  bool _disposed = false;
  Future<void> _queue = Future.value();
  Future<void> _effects = Future.value();
  void changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<T> serial<T>(Future<T> Function() action) {
    final next = _queue.then((_) => action(), onError: (_) => action());
    _queue = next.then<void>((_) {}, onError: (_) {});
    return next;
  }

  Future<bool> bounded(Future<bool> Function() work) async {
    // timeout does not cancel a platform call. Keep late completion serialized
    // so it can never apply an old effect after a newer selection commits.
    final operation = _effects.then((_) => work(), onError: (_) => work());
    _effects = operation.then<void>((_) {}, onError: (_) {});
    try {
      return await operation.timeout(const Duration(seconds: 15));
    } catch (_) {
      return false;
    }
  }

  Future<void> save(UpdateRecord record) async {
    if (!await journal.write(record.encode())) {
      throw const FormatException('Journal write failed');
    }
  }

  Future<bool> reconcile() => serial(() async {
    busy = true;
    changed();
    try {
      return await recover();
    } finally {
      busy = false;
      changed();
    }
  });
  Future<bool> recover() async {
    try {
      final record = UpdateRecord.decode(await journal.read());
      final pending = record.pending;
      if (pending != null) {
        final actual = readState();
        validateSelection(actual);
        if (!sameSelection(actual, pending.previous) &&
            !sameSelection(actual, pending.target)) {
          await bounded(stop);
          failed = true;
          return false;
        }
        if (!await bounded(stop)) {
          failed = true;
          return false;
        }
      }
      final ok = await bounded(reflect);
      if (!ok) {
        failed = true;
        return false;
      }
      if (pending != null) await save(UpdateRecord(record.sequence, null));
      failed = false;
      return true;
    } catch (_) {
      await bounded(stop);
      failed = true;
      return false;
    }
  }

  /// true means the app state committed, not that every OS effect succeeded.
  Future<bool> change(
    String reason,
    Map<String, Object?> delta,
    Future<bool> Function() commit,
  ) => serial(() async {
    busy = true;
    changed();
    var committed = false;
    try {
      final existing = UpdateRecord.decode(await journal.read());
      if (existing.pending != null && !await recover()) return false;
      final previous = readState();
      validateSelection(previous);
      final target = {...previous, ...delta};
      validateSelection(target);
      final pending = PendingUpdate(
        reason: reason,
        previous: previous,
        target: target,
        phase: 'prepared',
      );
      final record = UpdateRecord(existing.sequence + 1, pending);
      // Decode validates reason/phase before persisting any new intent.
      UpdateRecord.decode(record.encode());
      await save(record);
      if (!await bounded(stop)) {
        failed = true;
        return false;
      }
      pending.phase = 'stopped';
      await save(record);
      committed = await commit();
      final actual = readState();
      validateSelection(actual);
      if (committed && !sameSelection(actual, target) ||
          !committed && !sameSelection(actual, previous)) {
        failed = true;
        return committed;
      }
      pending.phase = committed ? 'committed' : 'needsRetry';
      await save(record);
      if (await bounded(reflect)) {
        await save(UpdateRecord(record.sequence, null));
        failed = !committed;
      } else {
        pending.phase = 'needsRetry';
        await save(record);
        failed = true;
      }
      return committed;
    } catch (_) {
      await bounded(stop);
      failed = true;
      return committed;
    } finally {
      busy = false;
      changed();
    }
  });
}
