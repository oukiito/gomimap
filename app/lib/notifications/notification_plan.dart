// SPDX-License-Identifier: GPL-3.0-or-later

import '../domain/schedule.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/presentation.dart';
import 'notification_state.dart';

/// Japan-only local notifications. Never backfill a missed trigger or turn an
/// unknown day into a collection. Native performs a final delivery-time guard.
Map<String, Object?> notificationPlan({
  required List<DaySchedule> days,
  required NotificationSettings settings,
  required DateTime now,
  required AppLocalizations l10n,
  required String areaLabel,
  required String locale,
  required DateTime validUntil,
  bool allowQaFixtures = false,
}) {
  final entries = <Map<String, Object?>>[];
  bool eligible(DaySchedule day) =>
      day.canNotify ||
      (allowQaFixtures &&
          day.fixture &&
          day.status == ScheduleStatus.collection &&
          day.collections.isNotEmpty &&
          day.municipalityId != null &&
          day.datasetVersion != null &&
          day.reasons.isEmpty &&
          day.collections.every(
            (e) =>
                e.sourceIds.isNotEmpty &&
                e.sourceIds.every(day.sources.containsKey),
          ));
  for (final day in days.take(14)) {
    if (!settings.enabled || !eligible(day)) continue;
    for (final evening in [false, if (settings.eveningEnabled) true]) {
      final minute = evening ? settings.eveningMinute : settings.morningMinute;
      final due = day.day.startInJapanUtc.add(
        Duration(minutes: minute, days: evening ? -1 : 0),
      );
      if (!due.isAfter(now.toUtc()) || !due.isBefore(validUntil)) continue;
      final remaining = day.collections
          .where(
            (e) => evening || e.deadline.hour * 60 + e.deadline.minute > minute,
          )
          .toList();
      if (remaining.isEmpty) continue;
      final end = evening
          ? day.day.startInJapanUtc
          : remaining
                .map(
                  (e) => day.day.startInJapanUtc.add(
                    Duration(
                      hours: e.deadline.hour,
                      minutes: e.deadline.minute,
                    ),
                  ),
                )
                .reduce((a, b) => a.isAfter(b) ? a : b);
      final expires = end.isBefore(validUntil) ? end : validUntil;
      if (!due.isBefore(expires)) continue;
      entries.add({
        'id': entries.length + 1,
        'due': due.millisecondsSinceEpoch,
        'expires': expires.millisecondsSinceEpoch,
        'date': day.day.toString(),
        'kind': evening ? 'evening' : 'morning',
        'title': evening
            ? l10n.notificationEveningTitle(day.day.toString())
            : l10n.notificationMorningTitle(day.day.toString()),
        'areaLabel': areaLabel,
        'separator': locale == 'ja' ? '・' : ', ',
        'collections': [
          for (final e in remaining)
            {
              'name': e.localizedName(l10n),
              'detail': l10n.itemDeadline(
                e.localizedName(l10n),
                e.deadline.toString(),
              ),
              'deadline': day.day.startInJapanUtc
                  .add(
                    Duration(
                      hours: e.deadline.hour,
                      minutes: e.deadline.minute,
                    ),
                  )
                  .millisecondsSinceEpoch,
            },
        ],
      });
    }
  }
  final first = days.firstOrNull;
  return {
    'schemaVersion': 1,
    'municipalityId': first?.municipalityId ?? 'demo-toshima',
    'areaId': first?.areaId ?? '',
    'datasetVersion': first?.datasetVersion,
    'locale': locale,
    'fixture': days.any((d) => d.fixture),
    'channelName': l10n.notifications,
    'testTitle': l10n.notificationTestTitle('{title}'),
    'entries': entries,
  };
}
