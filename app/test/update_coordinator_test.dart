// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/data/update_coordinator.dart';
import 'package:gomimap/data/update_journal.dart';
import 'package:gomimap/data/update_journal_native.dart';
import 'package:gomimap/notifications/notification_state.dart';

Map<String, Object?> selection() => {
  'municipalityId': 'demo-toshima',
  'areaId': 'a',
  'datasetVersion': 'v1',
  'locale': 'ja',
  'notifications': const NotificationSettings().toJson(),
  'notificationAnswered': true,
};

class FaultJournal extends MemoryUpdateJournal {
  int writes = 0;
  int? reject;
  @override
  Future<bool> write(String value) async {
    writes++;
    if (writes == reject) return false;
    return super.write(value);
  }
}

void main() {
  for (final phase in ['prepared', 'stopped', 'committed', 'needsRetry']) {
    for (final committed in [false, true]) {
      test(
        'restart $phase restores actual ${committed ? 'new' : 'old'} state',
        () async {
          final old = selection(), target = {...selection(), 'areaId': 'b'};
          final actual = committed ? target : old;
          final journal = MemoryUpdateJournal()
            ..value = UpdateRecord(
              7,
              PendingUpdate(
                reason: 'district',
                previous: old,
                target: target,
                phase: phase,
              ),
            ).encode();
          final events = <String>[];
          final c = UpdateCoordinator(
            journal: journal,
            readState: () => actual,
            stop: () async {
              events.add('stop');
              return true;
            },
            reflect: () async {
              events.add('reflect:${actual['areaId']}');
              return true;
            },
          );
          addTearDown(c.dispose);
          expect(await c.reconcile(), isTrue);
          expect(events, ['stop', 'reflect:${committed ? 'b' : 'a'}']);
          expect(UpdateRecord.decode(journal.value).pending, isNull);
          expect(UpdateRecord.decode(journal.value).sequence, 7);
        },
      );
    }
  }
  for (final failure in ['journal', 'stop', 'commit']) {
    test('$failure failure never commits new selection', () async {
      var state = selection();
      final journal = FaultJournal()..reject = failure == 'journal' ? 1 : null;
      var commits = 0;
      final reflected = <Object?>[];
      final c = UpdateCoordinator(
        journal: journal,
        readState: () => state,
        stop: () async => failure != 'stop',
        reflect: () async {
          reflected.add(state['areaId']);
          return true;
        },
      );
      addTearDown(c.dispose);
      expect(
        await c.change('district', {'areaId': 'b'}, () async {
          commits++;
          if (failure == 'commit') return false;
          state = {...state, 'areaId': 'b'};
          return true;
        }),
        isFalse,
      );
      expect(state['areaId'], 'a');
      expect(commits, failure == 'commit' ? 1 : 0);
      expect(reflected, failure == 'commit' ? ['a'] : isEmpty);
      expect(c.failed, isTrue);
    });
  }
  test(
    'OS failure retains committed selection and pending until retry',
    () async {
      var state = selection();
      var osOk = false;
      final journal = MemoryUpdateJournal();
      final c = UpdateCoordinator(
        journal: journal,
        readState: () => state,
        stop: () async => true,
        reflect: () async => osOk,
      );
      addTearDown(c.dispose);
      expect(
        await c.change('language', {'locale': 'en'}, () async {
          state = {...state, 'locale': 'en'};
          return true;
        }),
        isTrue,
      );
      expect(state['locale'], 'en');
      expect(UpdateRecord.decode(journal.value).pending!.phase, 'needsRetry');
      osOk = true;
      expect(await c.reconcile(), isTrue);
      expect(UpdateRecord.decode(journal.value).pending, isNull);
    },
  );
  test(
    'crash after state commit before phase write recovers new state',
    () async {
      var state = selection();
      final journal = FaultJournal()..reject = 3;
      final c = UpdateCoordinator(
        journal: journal,
        readState: () => state,
        stop: () async => true,
        reflect: () async => true,
      );
      addTearDown(c.dispose);
      expect(
        await c.change('district', {'areaId': 'b'}, () async {
          state = {...state, 'areaId': 'b'};
          return true;
        }),
        isTrue,
      );
      expect(UpdateRecord.decode(journal.value).pending!.phase, 'stopped');
      expect(await c.reconcile(), isTrue);
      expect(UpdateRecord.decode(journal.value).pending, isNull);
      expect(state['areaId'], 'b');
    },
  );
  for (final fault in ['corrupt', 'mismatch']) {
    test('$fault fails closed and pauses without reflecting', () async {
      final journal = MemoryUpdateJournal()
        ..value = fault == 'corrupt'
            ? 'broken'
            : UpdateRecord(
                1,
                PendingUpdate(
                  reason: 'district',
                  previous: selection(),
                  target: {...selection(), 'areaId': 'b'},
                  phase: 'stopped',
                ),
              ).encode();
      var stops = 0, reflections = 0, commits = 0;
      final c = UpdateCoordinator(
        journal: journal,
        readState: () => {...selection(), 'datasetVersion': 'unrelated'},
        stop: () async {
          stops++;
          return true;
        },
        reflect: () async {
          reflections++;
          return true;
        },
      );
      addTearDown(c.dispose);
      expect(await c.reconcile(), isFalse);
      expect(
        await c.change('language', {'locale': 'en'}, () async {
          commits++;
          return true;
        }),
        isFalse,
      );
      expect(stops, greaterThan(0));
      expect(reflections, 0);
      expect(commits, 0);
    });
  }
  test(
    'concurrent changes serialize and preserve the preceding commit',
    () async {
      var state = selection();
      final events = <String>[];
      final gate = Completer<void>();
      final journal = MemoryUpdateJournal();
      final c = UpdateCoordinator(
        journal: journal,
        readState: () => state,
        stop: () async => true,
        reflect: () async {
          events.add('${state['areaId']}:${state['locale']}');
          return true;
        },
      );
      addTearDown(c.dispose);
      final district = c.change('district', {'areaId': 'b'}, () async {
        await gate.future;
        state = {...state, 'areaId': 'b'};
        return true;
      });
      final language = c.change('language', {'locale': 'en'}, () async {
        state = {...state, 'locale': 'en'};
        return true;
      });
      gate.complete();
      expect(await district, isTrue);
      expect(await language, isTrue);
      expect(events, ['b:ja', 'b:en']);
      expect(UpdateRecord.decode(journal.value).sequence, 2);
    },
  );
  testWidgets('a timed-out platform call cannot overwrite a newer commit', (
    tester,
  ) async {
    var state = selection();
    final oldEffect = Completer<bool>();
    var reflects = 0, secondCommits = 0;
    final journal = MemoryUpdateJournal();
    final c = UpdateCoordinator(
      journal: journal,
      readState: () => state,
      stop: () async => true,
      reflect: () {
        reflects++;
        return reflects == 1 ? oldEffect.future : Future.value(true);
      },
    );
    addTearDown(c.dispose);
    final first = c.change('language', {'locale': 'en'}, () async {
      state = {...state, 'locale': 'en'};
      return true;
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 16));
    expect(await first, isTrue);
    expect(c.failed, isTrue);
    final second = c.change('district', {'areaId': 'b'}, () async {
      secondCommits++;
      state = {...state, 'areaId': 'b'};
      return true;
    });
    await tester.pump();
    expect(secondCommits, 0);
    expect(state['areaId'], 'a');
    oldEffect.complete(true);
    await tester.pump();
    expect(await second, isTrue);
    expect(secondCommits, 1);
    expect(state['locale'], 'en');
    expect(state['areaId'], 'b');
    expect(UpdateRecord.decode(journal.value).pending, isNull);
  });
  test(
    'file journal survives reconstruction and ignores incomplete temp',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'gomimap-journal-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/current.json');
      final journal = FileUpdateJournal(file);
      expect(await journal.write(UpdateRecord(3, null).encode()), isTrue);
      await File('${file.path}.pending').writeAsString('broken');
      expect(
        UpdateRecord.decode(await FileUpdateJournal(file).read()).sequence,
        3,
      );
      expect(await journal.write('invalid'), isFalse);
      expect(UpdateRecord.decode(await journal.read()).sequence, 3);
      await file.writeAsString('a' * 16385);
      expect(journal.read(), throwsFormatException);
    },
  );
  test(
    'journal rejects unknown fields, missing keys and private addresses',
    () {
      expect(
        () => validateSelection({...selection(), 'address': 'private'}),
        throwsFormatException,
      );
      expect(
        () => UpdateRecord.decode('{"version":1,"sequence":0}'),
        throwsFormatException,
      );
      expect(
        () => UpdateRecord.decode('{"version":2,"sequence":0,"pending":null}'),
        throwsFormatException,
      );
    },
  );
}
