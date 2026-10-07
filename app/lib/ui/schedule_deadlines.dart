// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';

import '../domain/schedule.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/presentation.dart';

class ScheduleDeadlines extends StatelessWidget {
  const ScheduleDeadlines({super.key, required this.schedule});
  final DaySchedule schedule;

  @override
  Widget build(BuildContext context) {
    if (schedule.status != ScheduleStatus.collection ||
        schedule.collections.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final times = schedule.collections
        .map((entry) => entry.deadline.toString())
        .toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (times.length == 1)
          Text(
            l10n.collectionDeadline(times.single),
            style: const TextStyle(fontWeight: FontWeight.w600),
          )
        else
          for (final entry in schedule.collections)
            Text(
              l10n.itemDeadline(
                entry.localizedName(l10n),
                entry.deadline.toString(),
              ),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
      ],
    );
  }
}
