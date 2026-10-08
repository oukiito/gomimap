// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:intl/intl.dart';

import '../data/demo_data.dart';
import '../domain/calendar_date.dart';
import '../domain/municipal_dataset.dart';
import '../domain/schedule.dart';
import '../domain/schedule_focus.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/languages.dart';
import '../l10n/presentation.dart';

/// A bounded, offline view of the same calendar. Native selects a time segment;
/// it never invents recurrences or turns missing coverage into no collection.
String buildWidgetProjection({
  required MunicipalDataset? dataset,
  required DemoArea area,
  required CalendarDate start,
  required DateTime generatedAt,
}) {
  final calendar = demoCalendar(area, dataset: dataset);
  final days = [for (var i = 0; i < 35; i++) calendar.onDate(start.addDays(i))];
  final locales = <String, Object?>{};
  for (final locale in appLocales) {
    final l10n = lookupAppLocalizations(locale);
    Map<String, Object?> presentation(DaySchedule day) => {
      'status': day.status.name,
      'title': day.localizedDescription(l10n),
      'lines': [
        for (final collection in day.collections)
          '${collection.localizedName(l10n)}: ${l10n.collectionDeadline(collection.deadline.toString())}',
      ],
      'dateLabel': DateFormat.MEd(l10n.localeName).format(day.date),
    };
    Map<String, Object?> segment(int index, int minute) {
      final focus = scheduleFocus(days.sublist(index), minute);
      final next = days
          .where(
            (day) =>
                day.day.compareTo(focus.day) > 0 &&
                day.status != ScheduleStatus.none,
          )
          .firstOrNull;
      final prefix = focus.day == days[index].day
          ? l10n.today
          : focus.day == days[index].day.addDays(1)
          ? l10n.tomorrow
          : l10n.widgetNext;
      return {
        ...presentation(focus),
        'minute': minute,
        'targetDate': focus.day.toString(),
        'dateLabel':
            '$prefix ${DateFormat.MEd(l10n.localeName).format(focus.date)}',
        'next': next == null
            ? ''
            : '${l10n.widgetNext}: ${DateFormat.MEd(l10n.localeName).format(next.date)} ${next.localizedDescription(l10n)}',
      };
    }

    locales[locale.toLanguageTag()] = {
      'areaName': l10n.areaName(area.name.toUpperCase()),
      'sample': l10n.widgetSample,
      'uncertain': l10n.uncertain,
      'chooseArea': l10n.chooseArea,
      'next': l10n.widgetNext,
      'days': {
        for (var index = 0; index < days.length; index++)
          days[index].day.toString(): {
            ...presentation(days[index]),
            'segments': [
              for (final minute in focusBoundaries(days[index]))
                segment(index, minute),
            ],
          },
      },
    };
  }
  return jsonEncode({
    'schemaVersion': 2,
    'municipalityId': 'demo-toshima',
    'areaId': area.name,
    'datasetVersion': calendar.dataset?.version,
    'fixture': true,
    'generatedAt': generatedAt.toUtc().millisecondsSinceEpoch,
    'start': start.toString(),
    'end': start.addDays(35).toString(),
    'locales': locales,
  });
}
