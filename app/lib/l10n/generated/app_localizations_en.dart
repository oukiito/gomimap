// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Gomimap';

  @override
  String get language => 'Language / 言語';

  @override
  String get languageSaveError =>
      'Could not save your language. Please select it again next time.';

  @override
  String get about => 'About this prototype';

  @override
  String get sampleBanner => 'Demo data · Do not use for actual waste disposal';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get searchTab => 'Sorting';

  @override
  String get placesTab => 'Recycling locations';

  @override
  String get chooseArea => 'Select area';

  @override
  String get fictionalAreas => 'Fictional areas for testing.';

  @override
  String areaName(String area) {
    return 'Toshima · Sample area $area';
  }

  @override
  String get areaSaveError =>
      'Could not save. Your setting has not changed. Please try again.';

  @override
  String sourceOpenError(String url) {
    return 'Could not open the official page.\n$url';
  }

  @override
  String demoDate(String date) {
    return 'Sample for $date';
  }

  @override
  String get upcoming => 'Upcoming collections';

  @override
  String get officialToshima => 'Toshima official information (Japanese)';

  @override
  String get official => 'Official information (Japanese)';

  @override
  String get checkTime => 'Check official disposal instructions and times';

  @override
  String get noCollection => 'No collection';

  @override
  String get uncertain => 'Collection schedule needs confirmation';

  @override
  String get burnable => 'Burnable waste';

  @override
  String get recyclables => 'Recyclables';

  @override
  String get metals => 'Metal, ceramics and glass';

  @override
  String get searchTitle => 'How do I dispose of this?';

  @override
  String get searchSubtitle => 'Search by item name.';

  @override
  String get itemName => 'Item name';

  @override
  String get searchHint => 'e.g. battery, plastic bottle';

  @override
  String get noResults =>
      'No results. Try another name or check the official information.';

  @override
  String get disposal => 'Disposal instructions';

  @override
  String get disposalAndPlaces => 'Disposal and collection locations';

  @override
  String get sampleSorting => 'Sample sorting instructions';

  @override
  String get findPlaces => 'Find collection locations';

  @override
  String get officialDisposal => 'Official disposal instructions (Japanese)';

  @override
  String get placesSubtitle =>
      'Drop-off locations for batteries, small electronics and fluorescent tubes.\nFor regular waste, see Today.';

  @override
  String get damageQuestion => 'Is it swollen or damaged?';

  @override
  String get noDamage => 'No';

  @override
  String get damagedOrUnknown => 'Yes / Not sure';

  @override
  String get damageWarning =>
      'Do not use a regular collection box. Check the condition and contact the ward using its official guidance.';

  @override
  String get officialBattery =>
      'Official battery guidance and contacts (Japanese)';

  @override
  String placesCount(int count) {
    return 'Sample locations ($count)';
  }

  @override
  String get fictionalPoints =>
      'These locations are fictional. Do not visit them.';

  @override
  String get noPoints =>
      'No verified locations for this item yet. Check the ward’s official guidance.';

  @override
  String get conditions => 'Check acceptance conditions';

  @override
  String samplePoint(String point) {
    return 'Sample collection point $point';
  }

  @override
  String get samplePointDetail => 'Fictional collection location for testing';

  @override
  String acceptedItems(String items) {
    return 'Example accepted items: $items';
  }

  @override
  String get pointConditions =>
      'Hours and conditions: not registered.\nThis is not a real drop-off location. Directions are unavailable.';

  @override
  String get mapTitle => 'Collection map';

  @override
  String get mapUnavailable =>
      'The map is not connected yet.\nUse the list below to try the prototype.';

  @override
  String get aboutBody =>
      'This development sample uses fictional schedules, areas and collection sites. Do not use it for actual waste disposal.\n\nArea, language and reminder settings are stored on your device. Photos and location are not collected.';

  @override
  String get dryBattery => 'Dry-cell batteries';

  @override
  String get rechargeable => 'Rechargeable batteries';

  @override
  String get appliance => 'Small electronics';

  @override
  String get lamp => 'Fluorescent tubes';

  @override
  String get dryBatteryHint =>
      'Check the battery type and condition before choosing a location.';

  @override
  String get rechargeableHint =>
      'Do not put these in dry-cell battery boxes. Check the method for their type and condition.';

  @override
  String get applianceHint =>
      'Check accepted items, slot size and rules for built-in batteries.';

  @override
  String get lampHint =>
      'Broken tubes and LED bulbs have different rules. Check official guidance.';

  @override
  String get food => 'Food waste';

  @override
  String get pet => 'PET bottles';

  @override
  String get cans => 'Cans and glass bottles';

  @override
  String get bulky => 'Furniture and bulky waste';

  @override
  String get foodGuidance =>
      'Sample burnable-waste guidance: drain liquids before disposal.';

  @override
  String get recyclingGuidance =>
      'Sample recyclable guidance: check regular collection days and preparation rules.';

  @override
  String get dryBatteryGuidance =>
      'Check collection methods for the battery type.';

  @override
  String get rechargeableGuidance =>
      'Rules vary by type and whether the battery is swollen or damaged.';

  @override
  String get applianceGuidance =>
      'Check size limits and rules for built-in batteries.';

  @override
  String get lampGuidance =>
      'Check fluorescent tubes and LED bulbs separately.';

  @override
  String get bulkyGuidance =>
      'Bulky-waste rules depend on dimensions and item type. Check the ward’s item guide and booking information.';

  @override
  String collectionArea(String area) {
    return 'Collection area: $area';
  }

  @override
  String get setupAreaTitle => 'Set a demo district';

  @override
  String get confirmAreaTitle => 'Use this district?';

  @override
  String candidateArea(String area) {
    return 'District to save: $area';
  }

  @override
  String currentArea(String area) {
    return 'Current setting: $area';
  }

  @override
  String get confirmAreaAction => 'Save this district';

  @override
  String get chooseAgain => 'Choose again';

  @override
  String get savingArea => 'Saving…';

  @override
  String get setupRecovery =>
      'Your district setting could not be read. Please choose it again.';

  @override
  String get cancel => 'Cancel';

  @override
  String collectionDeadline(String time) {
    return 'Put out by $time';
  }

  @override
  String itemDeadline(String item, String time) {
    return '$item: put out by $time';
  }

  @override
  String get chooseCollectionItem =>
      'Choose the type of item you want to drop off.';

  @override
  String backToItem(String item) {
    return 'Back to $item instructions';
  }

  @override
  String get close => 'Close';

  @override
  String get widgetLabel => 'Waste schedule';

  @override
  String get widgetSample => 'Development sample';

  @override
  String get widgetNext => 'Next schedule';

  @override
  String get widgetOfferTitle => 'Show your waste schedule on the home screen';

  @override
  String get widgetOfferBody =>
      'See the date and waste type without opening the app.';

  @override
  String get widgetAdd => 'Add widget';

  @override
  String get widgetSkip => 'Skip';

  @override
  String get widgetSettings => 'Home screen widget';

  @override
  String get widgetAdded => 'Added to the home screen';

  @override
  String get widgetRequested =>
      'Addition requested. Confirm in the system dialog.';

  @override
  String get widgetUnsupported =>
      'Touch and hold the home screen, select Widgets, then add Gomimap.';

  @override
  String get widgetFailure =>
      'Could not request the widget. Retry or add it from the home screen.';

  @override
  String get widgetSaveError => 'Could not save your choice. Please retry.';

  @override
  String get disposalDeadlinePassed => 'The disposal deadline has passed';

  @override
  String get notifications => 'Waste reminders';

  @override
  String get notificationIntro => 'Get a reminder on collection mornings.';

  @override
  String get notificationEnabled => 'Morning reminder';

  @override
  String get notificationEvening => 'Also remind the evening before';

  @override
  String get notificationSave => 'Save';

  @override
  String get notificationLater => 'Later';

  @override
  String get notificationPermission =>
      'Notifications are not allowed on this device';

  @override
  String get notificationOsSettings => 'Open device notification settings';

  @override
  String get notificationNone => 'No collection dates can be scheduled';

  @override
  String get notificationFixture =>
      'The normal app does not schedule sample reminders';

  @override
  String notificationReserved(int count) {
    return 'Scheduled: $count';
  }

  @override
  String notificationPreview(int count) {
    return 'Test clock: $count preview reminders';
  }

  @override
  String notificationNext(String when) {
    return 'Next reminder: $when';
  }

  @override
  String get notificationError =>
      'Could not save or apply changes. Check settings and scheduled reminders.';

  @override
  String get notificationRetry => 'Retry';

  @override
  String get notificationTest => 'Show test notification';

  @override
  String notificationMorningTitle(String date) {
    return 'Waste today, $date';
  }

  @override
  String notificationEveningTitle(String date) {
    return 'Prepare for tomorrow, $date';
  }

  @override
  String notificationTestTitle(String title) {
    return 'Test: $title';
  }

  @override
  String get notificationChangedArea =>
      'This reminder is for a different area. Showing your current area.';

  @override
  String get notificationUpdated =>
      'The schedule has changed since this reminder.';

  @override
  String get notificationOfferTitle => 'Remind me on collection days';

  @override
  String get mapLoadError => 'The map could not be loaded';

  @override
  String get mapRetry => 'Retry';

  @override
  String get mapShowList => 'View list';

  @override
  String get addressChoose => 'Choose by address';

  @override
  String get addressTown => 'Town';

  @override
  String get addressChome => 'Chome';

  @override
  String get addressBlock => 'Block number';

  @override
  String get addressStreet => 'Along Fictional Street?';

  @override
  String get addressSelect => 'Choose an option';

  @override
  String get addressYes => 'Yes';

  @override
  String get addressNo => 'No';

  @override
  String get addressAlong => 'Along the street';

  @override
  String get addressAway => 'Not along the street';

  @override
  String get addressFictionalTown => 'Fictional town';

  @override
  String get addressFind => 'Review this district';

  @override
  String get addressUnknown => 'Not sure';

  @override
  String get addressUnsupported => 'No supported collection district was found';

  @override
  String get addressConflict => 'More than one collection district matches';

  @override
  String get addressNeedsConfirmation => 'Check the collection district';

  @override
  String get addressDataChanged =>
      'The information changed. Choose the district again';

  @override
  String get updateEffectsError =>
      'Notifications or widgets could not be updated.';
}
