// SPDX-License-Identifier: GPL-3.0-or-later

import '../data/demo_data.dart';
import '../domain/schedule.dart';
import 'generated/app_localizations.dart';

extension SchedulePresentation on DaySchedule {
  String localizedDescription(AppLocalizations l10n) => switch (status) {
    ScheduleStatus.none => l10n.noCollection,
    ScheduleStatus.needsConfirmation => l10n.uncertain,
    ScheduleStatus.collection =>
      collections
          .map(
            (entry) => switch (entry.category.displayKey) {
              'burnable' => l10n.burnable,
              'recyclables' => l10n.recyclables,
              'metals' => l10n.metals,
              // Preserve source names when no verified translation is available.
              _ => entry.category.name,
            },
          )
          .join(l10n.localeName == 'ja' ? '・' : ', '),
  };
}

extension SpecialItemPresentation on SpecialItem {
  String localizedName(AppLocalizations l10n) => switch (this) {
    SpecialItem.dryBattery => l10n.dryBattery,
    SpecialItem.rechargeable => l10n.rechargeable,
    SpecialItem.appliance => l10n.appliance,
    SpecialItem.lamp => l10n.lamp,
  };
  String localizedHint(AppLocalizations l10n) => switch (this) {
    SpecialItem.dryBattery => l10n.dryBatteryHint,
    SpecialItem.rechargeable => l10n.rechargeableHint,
    SpecialItem.appliance => l10n.applianceHint,
    SpecialItem.lamp => l10n.lampHint,
  };
}

extension SortingItemPresentation on SortingItem {
  String localizedName(AppLocalizations l10n) => switch (kind) {
    SortingKind.food => l10n.food,
    SortingKind.pet => l10n.pet,
    SortingKind.cans => l10n.cans,
    SortingKind.dryBattery => l10n.dryBattery,
    SortingKind.rechargeable => l10n.rechargeable,
    SortingKind.appliance => l10n.appliance,
    SortingKind.lamp => l10n.lamp,
    SortingKind.bulky => l10n.bulky,
  };
  String localizedGuidance(AppLocalizations l10n) => switch (kind) {
    SortingKind.food => l10n.foodGuidance,
    SortingKind.pet || SortingKind.cans => l10n.recyclingGuidance,
    SortingKind.dryBattery => l10n.dryBatteryGuidance,
    SortingKind.rechargeable => l10n.rechargeableGuidance,
    SortingKind.appliance => l10n.applianceGuidance,
    SortingKind.lamp => l10n.lampGuidance,
    SortingKind.bulky => l10n.bulkyGuidance,
  };
  bool matches(String query, AppLocalizations l10n) =>
      '${localizedName(l10n)} $keywords'.toLowerCase().contains(
        query.trim().toLowerCase(),
      );
}
