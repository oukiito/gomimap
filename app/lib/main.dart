// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter/material.dart';

import 'ui/identified_action.dart';

import 'package:intl/intl.dart';

import 'l10n/generated/app_localizations.dart';
import 'l10n/languages.dart';
import 'l10n/presentation.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/demo_data.dart';
import 'data/update_coordinator.dart';
import 'data/update_journal.dart';
import 'data/update_journal_factory.dart';
import 'data/demo_setup_store.dart';
import 'data/demo_dataset_repository.dart';
import 'domain/municipal_dataset.dart';
import 'domain/schedule.dart';
import 'domain/calendar_date.dart';
import 'domain/schedule_focus.dart';
import 'widgets/widget_bridge.dart';
import 'widgets/widget_offer_store.dart';
import 'widgets/widget_setup_store.dart';
import 'widgets/widget_projection.dart';
import 'ui/widget_offer.dart';
import 'ui/collection_map.dart';
import 'ui/demo_area_setup.dart';
import 'ui/language_button.dart';
import 'ui/schedule_deadlines.dart';
import 'ui/sheet_close_button.dart';
import 'qa/qa_runtime.dart';
import 'notifications/notification_bridge.dart';
import 'notifications/notification_controller.dart';
import 'notifications/notification_state.dart';
import 'notifications/notification_plan.dart';
import 'ui/notification_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final journal = await createUpdateJournal();
  final bridge = AndroidHomeWidgetBridge();
  await bridge.initialize();
  final notifications = AndroidNotificationsBridge();
  await notifications.initialize();
  if (qaBuild) {
    final runtime = await QaRuntime.connect();
    runApp(
      ListenableBuilder(
        listenable: runtime,
        builder: (context, _) => GomimapApp(
          preferences: preferences,
          updateJournal: journal,
          dataset: runtime.dataset,
          widgetBridge: bridge,
          notificationsBridge: notifications,
          mapTileSource: MapTileSource.forApp(),
          clock: () => runtime.now(),
          clockFrozen: runtime.frozen,
        ),
      ),
    );
    return;
  }
  final repository = await loadDemoDatasetRepository();
  runApp(
    GomimapApp(
      preferences: preferences,
      updateJournal: journal,
      repository: repository,
      widgetBridge: bridge,
      notificationsBridge: notifications,
      mapTileSource: MapTileSource.forApp(),
    ),
  );
}

class GomimapApp extends StatefulWidget {
  const GomimapApp({
    super.key,
    required this.preferences,
    this.setupStore,
    this.updateJournal,
    this.dataset,
    this.repository,
    this.widgetBridge,
    this.displayDate,
    this.clock,
    this.clockFrozen = false,
    this.notificationsBridge,
    this.allowQaNotifications = qaBuild,
    this.mapTileSource = const MapTileSource.fromEnvironment(),
  });
  final SharedPreferences preferences;
  final DemoSetupStore? setupStore;
  final UpdateJournal? updateJournal;
  final MunicipalDataset? dataset;
  final DemoDatasetRepository? repository;
  final HomeWidgetBridge? widgetBridge;

  /// Explicit fixture date for tests; normal runs use the Japanese civil date.
  final DateTime? displayDate;
  final DateTime Function()? clock;
  final bool clockFrozen;
  final NotificationsBridge? notificationsBridge;
  final bool allowQaNotifications;
  final MapTileSource mapTileSource;
  @override
  State<GomimapApp> createState() => _GomimapAppState();
}

class _GomimapAppState extends State<GomimapApp> with WidgetsBindingObserver {
  Locale? locale;
  late final DemoSetupStore setupStore;
  late DemoSetupSnapshot setup;
  late final HomeWidgetBridge bridge;
  late final WidgetOfferStore offer;
  late final NotificationController notifications;
  UpdateCoordinator? updates;
  final homeKey = GlobalKey<_HomeShellState>();
  final navigatorKey = GlobalKey<NavigatorState>();
  Timer? midnight;
  Future<bool> publishing = Future.value(true);
  String? cachedProjection;
  MunicipalDataset? projectedDataset;
  DemoArea? projectedArea;
  CalendarDate? projectedDay;
  DateTime now() => widget.clock?.call() ?? DateTime.now();
  DateTime get displayDate =>
      widget.displayDate ?? CalendarDate.inJapan(now()).value;
  int get displayMinute {
    final date =
        widget.displayDate ?? now().toUtc().add(const Duration(hours: 9));
    return date.hour * 60 + date.minute;
  }

  MunicipalDataset? get dataset => widget.repository?.current ?? widget.dataset;

  @override
  void initState() {
    super.initState();
    final saved = widget.preferences.getString('app.language');
    locale = savedLocale(saved);
    final base =
        widget.setupStore ?? PreferencesDemoSetupStore(widget.preferences);
    setup = base.read();
    bridge = widget.widgetBridge ?? const UnavailableHomeWidgetBridge();
    offer = WidgetOfferStore(
      widget.preferences,
      legacyDistrictSaved: setup.phase == DemoSetupPhase.districtSaved,
    );
    notifications = NotificationController(
      store: NotificationStateStore(
        widget.preferences,
        legacyDistrictSaved: setup.phase == DemoSetupPhase.districtSaved,
      ),
      bridge:
          widget.notificationsBridge ?? const UnavailableNotificationsBridge(),
      plan: buildNotifications,
    );
    final district = bridge.available ? WidgetSetupStore(base, offer) : base;
    setupStore = notifications.bridge.available || widget.updateJournal != null
        ? NotificationSetupStore(district, notifications)
        : district;
    if (widget.updateJournal != null) {
      updates = UpdateCoordinator(
        journal: widget.updateJournal!,
        readState: () => {
          'municipalityId': dataset?.municipality.id,
          'areaId': setupStore.read().phase == DemoSetupPhase.districtSaved
              ? setupStore.read().area?.name
              : null,
          'datasetVersion': dataset?.version,
          // Persist the device-default choice, not a transient resolved locale.
          'locale': locale?.toLanguageTag() ?? 'und',
          'notifications': notifications.store.settings.toJson(),
          'notificationAnswered': notifications.store.answered,
        },
        stop: () async {
          try {
            await publishing;
          } catch (_) {
            /* Drain older projections. */
          }
          return notifications.pause();
        },
        reflect: () async {
          final widgetOk =
              !bridge.available ||
              setupStore.read().phase != DemoSetupPhase.districtSaved ||
              await publishWidget(raw: true);
          final notificationOk = await notifications.reflectNow();
          return widgetOk && notificationOk;
        },
      );
      updates!.addListener(updateStatusChanged);
      notifications.coordinator = updates;
      widget.repository?.coordinator = updates;
    }
    notifications.bridge.onOpen(openNotification);
    bridge.setOpenTodayHandler(openToday);
    scheduleDisplayRefresh();
    WidgetsBinding.instance.addObserver(this);
    widget.repository?.addListener(datasetChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.repository?.refresh());
      if (mounted) unawaited(refreshEffects());
      unawaited(
        notifications.bridge.consumeLaunch().then((target) {
          if (target != null && mounted) openNotification(target);
        }),
      );
      unawaited(
        bridge.consumeLaunch().then((fromWidget) {
          if (fromWidget && mounted) openToday();
        }),
      );
    });
  }

  void updateStatusChanged() {
    if (mounted) setState(() {});
  }

  void datasetChanged() {
    scheduleDisplayRefresh();
    if (mounted) setState(() {});
    if (mounted) unawaited(refreshEffects());
  }

  @override
  void didUpdateWidget(covariant GomimapApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clock != widget.clock ||
        oldWidget.clockFrozen != widget.clockFrozen ||
        !identical(oldWidget.dataset, widget.dataset)) {
      scheduleDisplayRefresh();
      unawaited(refreshEffects());
    }
  }

  void openToday() {
    if (!mounted || setup.phase != DemoSetupPhase.districtSaved) return;
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    homeKey.currentState?.selectToday();
  }

  void scheduleDisplayRefresh() {
    midnight?.cancel();
    if (widget.displayDate != null || widget.clockFrozen) return;
    final instant = now().toUtc();
    final today = CalendarDate.inJapan(instant);
    var next = today.addDays(1).startInJapanUtc;
    final area = setupStore.read().area;
    if (area != null) {
      for (final entry in demoCalendar(
        area,
        dataset: dataset,
      ).onDate(today).collections) {
        final boundary = today.startInJapanUtc.add(
          Duration(hours: entry.deadline.hour, minutes: entry.deadline.minute),
        );
        if (boundary.isAfter(instant) && boundary.isBefore(next)) {
          next = boundary;
        }
      }
    }
    midnight = Timer(next.difference(now().toUtc()), () {
      if (!mounted) return;
      setState(() {});
      unawaited(publishWidget());
      scheduleDisplayRefresh();
    });
  }

  Future<void> refreshEffects() async {
    if (updates != null) {
      await notifications.refresh();
    } else {
      await publishWidget();
      await notifications.refresh();
    }
  }

  Future<bool> publishWidget({bool raw = false}) {
    if (!raw && updates != null) return updates!.reconcile();
    if (!bridge.available ||
        setupStore.read().phase != DemoSetupPhase.districtSaved) {
      return Future.value(false);
    }
    final area = setupStore.read().area!;
    final day = CalendarDate.fromFields(displayDate);
    if (cachedProjection == null ||
        !identical(projectedDataset, dataset) ||
        projectedArea != area ||
        projectedDay != day) {
      cachedProjection = buildWidgetProjection(
        dataset: dataset,
        area: area,
        start: day,
        generatedAt: now(),
      );
      projectedDataset = dataset;
      projectedArea = area;
      projectedDay = day;
    }
    final projection = cachedProjection!;
    publishing = publishing.then(
      (_) => bridge.publish(projection),
      onError: (_) => bridge.publish(projection),
    );
    return publishing;
  }

  void savedArea(DemoArea area) {
    setState(() => setup = DemoSetupSnapshot.saved(area));
    scheduleDisplayRefresh();
    unawaited(refreshEffects());
  }

  void showWidgetSettings() {
    final current = setupStore.read();
    if (current.area == null) return;
    navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (context) => WidgetOffer(
          area: current.area!,
          dataset: dataset,
          date: displayDate,
          minute: displayMinute,
          bridge: bridge,
          store: offer,
          firstTime: false,
          publish: publishWidget,
          onLanguageChanged: changeLanguage,
          onDone: () => navigatorKey.currentState?.pop(),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      scheduleDisplayRefresh();
      unawaited(widget.repository?.refresh());
      unawaited(refreshEffects());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.repository?.removeListener(datasetChanged);
    midnight?.cancel();
    if (identical(widget.repository?.coordinator, updates)) {
      widget.repository?.coordinator = null;
    }
    notifications.dispose();
    updates?.removeListener(updateStatusChanged);
    updates?.dispose();
    super.dispose();
  }

  Future<bool> changeLanguage(String code) async {
    final selected = savedLocale(code);
    if (selected == null) return false;
    if (updates != null) {
      return updates!.change('language', {'locale': code}, () async {
        try {
          if (!await widget.preferences.setString('app.language', code)) {
            await widget.preferences.reload();
            return false;
          }
          if (mounted) setState(() => locale = selected);
          return true;
        } catch (_) {
          await widget.preferences.reload();
          return false;
        }
      });
    }
    try {
      if (!await notifications.pause()) return false;
      if (!await widget.preferences.setString('app.language', code)) {
        await widget.preferences.reload();
        await notifications.refresh();
        return false;
      }
      if (mounted) setState(() => locale = selected);
      unawaited(refreshEffects());
      return true;
    } catch (_) {
      unawaited(notifications.refresh());
      return false;
    }
  }

  Map<String, Object?> buildNotifications(NotificationSettings settings) {
    final saved = setupStore.read();
    final area = saved.phase == DemoSetupPhase.districtSaved
        ? saved.area
        : null;
    final tag =
        locale ??
        resolveAppLocale(
          WidgetsBinding.instance.platformDispatcher.locales,
          appLocales,
        );
    final l10n = lookupAppLocalizations(tag);
    final today = CalendarDate.inJapan(now());
    final calendar = demoCalendar(area ?? DemoArea.a, dataset: dataset);
    return notificationPlan(
      days: [for (var i = 0; i < 14; i++) calendar.onDate(today.addDays(i))],
      settings: area == null ? const NotificationSettings() : settings,
      now: now(),
      l10n: l10n,
      areaLabel: l10n.areaName((area ?? DemoArea.a).name.toUpperCase()),
      locale: tag.toLanguageTag(),
      validUntil: dataset?.period.end.startInJapanUtc ?? now(),
      allowQaFixtures: widget.allowQaNotifications,
    );
  }

  void openNotification(Map<String, dynamic> target) {
    if (!mounted || setup.phase != DemoSetupPhase.districtSaved) return;
    openToday();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (target['areaId'] != setup.area!.name) {
        final c = navigatorKey.currentContext!;
        ScaffoldMessenger.of(c).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(c).notificationChangedArea),
          ),
        );
        return;
      }
      try {
        homeKey.currentState?.showSchedule(
          CalendarDate.parse(target['date'] as String),
          updated: target['datasetVersion'] != dataset?.version,
        );
      } catch (_) {
        /* Reject invalid deep link. */
      }
    });
  }

  Widget notificationPage({required bool firstTime}) =>
      NotificationSettingsPage(
        controller: notifications,
        area: setup.area!,
        firstTime: firstTime,
        qa: widget.allowQaNotifications,
        fixture: dataset?.kind == DatasetKind.fixture,
        onLanguageChanged: changeLanguage,
        onDone: () =>
            firstTime ? setState(() {}) : navigatorKey.currentState?.pop(),
      );
  void showNotificationSettings() => navigatorKey.currentState?.push(
    MaterialPageRoute<void>(builder: (_) => notificationPage(firstTime: false)),
  );

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigatorKey,
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    debugShowCheckedModeBanner: false,
    locale: locale,
    supportedLocales: appLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    localeListResolutionCallback: resolveAppLocale,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF247457),
        primary: const Color(0xFF24684F),
        surface: const Color(0xFFFAFBF7),
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFBF7),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFAFBF7),
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    home: setup.phase == DemoSetupPhase.districtSaved
        ? bridge.available && !offer.answered
              ? WidgetOffer(
                  area: setup.area!,
                  dataset: dataset,
                  date: displayDate,
                  minute: displayMinute,
                  bridge: bridge,
                  store: offer,
                  firstTime: true,
                  publish: publishWidget,
                  onDone: () => setState(() {}),
                  onLanguageChanged: changeLanguage,
                )
              : notifications.bridge.available && !notifications.store.answered
              ? notificationPage(firstTime: true)
              : HomeShell(
                  key: homeKey,
                  updates: updates,
                  area: setup.area!,
                  dataset: dataset,
                  displayDate: displayDate,
                  displayMinute: displayMinute,
                  onAreaSaved: savedArea,
                  onWidgetSettings: bridge.available
                      ? showWidgetSettings
                      : null,
                  setupStore: setupStore,
                  onLanguageChanged: changeLanguage,
                  mapTileSource: widget.mapTileSource,
                  onNotificationSettings: notifications.bridge.available
                      ? showNotificationSettings
                      : null,
                )
        : DemoAreaSetup(
            store: setupStore,
            dataset: dataset,
            initial: setup,
            previewDate: displayDate,
            onLanguageChanged: changeLanguage,
            onSaved: savedArea,
          ),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.area,
    required this.dataset,
    required this.setupStore,
    required this.onLanguageChanged,
    required this.displayDate,
    this.displayMinute = 0,
    required this.onAreaSaved,
    this.onWidgetSettings,
    this.onNotificationSettings,
    this.updates,
    this.mapTileSource = const MapTileSource.fromEnvironment(),
  });
  final DemoArea area;
  final UpdateCoordinator? updates;
  final MunicipalDataset? dataset;
  final DemoSetupStore setupStore;
  final Future<bool> Function(String) onLanguageChanged;
  final DateTime displayDate;
  final int displayMinute;
  final ValueChanged<DemoArea> onAreaSaved;
  final VoidCallback? onWidgetSettings;
  final VoidCallback? onNotificationSettings;
  final MapTileSource mapTileSource;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  String dateLabel(DateTime date) =>
      DateFormat.MEd(l10n.localeName).format(date);
  int tab = 0;
  late DemoArea area;
  SpecialItem? special;
  ({SortingItem item, bool? damaged})? mapOrigin;
  String query = '';
  bool? damaged;
  final searchController = TextEditingController();
  final mapView = CollectionMapView();
  final mapListKey = GlobalKey();

  void selectToday() {
    setState(() {
      tab = 0;
      mapOrigin = null;
    });
  }

  void showSchedule(CalendarDate date, {bool updated = false}) {
    final day = demoCalendar(area, dataset: widget.dataset).onDate(date);
    final current = CalendarDate.fromFields(widget.displayDate);
    final expired =
        date.compareTo(current) < 0 ||
        (date == current &&
            day.collections.isNotEmpty &&
            day.collections.every(
              (e) =>
                  e.deadline.hour * 60 + e.deadline.minute <=
                  widget.displayMinute,
            ));
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SheetCloseButton(onPressed: () => Navigator.pop(sheet)),
              areaContext(),
              Semantics(
                identifier: 'notification-target-date',
                child: Text(
                  DateFormat.yMMMMd(l10n.localeName).format(date.value),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (updated) Text(l10n.notificationUpdated),
              const SizedBox(height: 12),
              Text(
                day.localizedDescription(l10n),
                style: const TextStyle(fontSize: 24),
              ),
              if (expired && day.status == ScheduleStatus.collection)
                Text(l10n.disposalDeadlinePassed),
              ScheduleDeadlines(schedule: day),
              Text(l10n.checkTime),
              TextButton(
                onPressed: official,
                child: Text(l10n.officialToshima),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheet),
                child: Text(l10n.today),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    area = widget.area;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> official() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await launchUrl(
        Uri.parse(officialWasteUrl),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {
      /* Keep the source URL available if the OS cannot open it. */
    }
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: SelectableText(l10n.sourceOpenError(officialWasteUrl))),
    );
  }

  Future<void> changeArea() async {
    final selected = await Navigator.of(context).push<DemoArea>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => DemoAreaSetup(
          store: widget.setupStore,
          dataset: widget.dataset,
          initial: const DemoSetupSnapshot.choose(),
          currentArea: area,
          previewDate: widget.displayDate,
          onLanguageChanged: widget.onLanguageChanged,
          onSaved: (value) => Navigator.pop(context, value),
        ),
      ),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() => area = selected);
    widget.onAreaSaved(selected);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: tab != 2 || mapOrigin == null,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && tab == 2 && mapOrigin != null) returnToItem();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.appTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          identifiedAction(
            'settings-open',
            IconButton(
              onPressed: showSettings,
              icon: const Icon(Icons.settings_outlined),
              tooltip: l10n.about,
            ),
          ),
          LanguageButton(onChanged: widget.onLanguageChanged),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 660),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: areaContext(canChange: true),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 660),
                  child: ListView(
                    key: PageStorageKey((
                      tab,
                      tab == 2 ? mapOrigin?.item.kind : null,
                    )),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEEC9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.sampleBanner,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF654B16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...switch (tab) {
                        0 => todayPage(),
                        1 => searchPage(),
                        _ => placesPage(),
                      },
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() {
          tab = value;
          if (value != 2) mapOrigin = null;
        }),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.wb_sunny_outlined),
            selectedIcon: const Icon(Icons.wb_sunny),
            label: l10n.today,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search),
            label: l10n.searchTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: l10n.placesTab,
          ),
        ],
      ),
    ),
  );

  Widget areaContext({bool canChange = false}) {
    final content = Row(
      children: [
        const Icon(Icons.place_outlined, size: 18, color: Color(0xFF24684F)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.collectionArea(l10n.areaName(area.name.toUpperCase())),
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF24684F),
            ),
          ),
        ),
        if (canChange) const Icon(Icons.expand_more, size: 20),
      ],
    );
    if (!canChange) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: content,
      );
    }
    return Tooltip(
      message: l10n.chooseArea,
      child: TextButton(
        key: const ValueKey('collection-area-context'),
        onPressed: changeArea,
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.centerLeft,
        ),
        child: content,
      ),
    );
  }

  Widget heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade700, height: 1.6),
        ),
      ],
    ),
  );

  List<Widget> todayPage() {
    final calendar = demoCalendar(area, dataset: widget.dataset);
    final day = CalendarDate.fromFields(widget.displayDate);
    final days = [for (var i = 0; i < 35; i++) calendar.onDate(day.addDays(i))];
    final focus = scheduleFocus(days, widget.displayMinute);
    final original = days.first;
    final today =
        focus.day == day &&
            original.status == ScheduleStatus.collection &&
            focus.collections.length != original.collections.length
        ? DaySchedule(
            day: day,
            areaId: original.areaId,
            municipalityId: original.municipalityId,
            datasetVersion: original.datasetVersion,
            fixture: original.fixture,
            status: original.status,
            collections: original.collections.where(
              (entry) =>
                  entry.deadline.hour * 60 + entry.deadline.minute <=
                  widget.displayMinute,
            ),
            reasons: original.reasons,
            sources: original.sources,
          )
        : original;
    final history =
        focus.day != day ||
        focus.collections.length != original.collections.length;
    final focusLabel = focus.day == day
        ? l10n.today
        : focus.day == day.addDays(1)
        ? l10n.tomorrow
        : l10n.widgetNext;
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          l10n.demoDate(
            DateFormat.yMMMMd(l10n.localeName).format(widget.displayDate),
          ),
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ),
      scheduleCard(focusLabel, focus, prominent: true),
      const SizedBox(height: 12),
      if (history) scheduleCard(l10n.today, today, showExpired: true),
      if (focus.day != day.addDays(1)) ...[
        if (history) const SizedBox(height: 12),
        scheduleCard(l10n.tomorrow, days[1]),
      ],
      const SizedBox(height: 28),
      Text(
        l10n.upcoming,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      for (var offset = 2; offset < 7; offset++)
        if (days[offset].day != focus.day)
          scheduleRow(
            calendar.on(widget.displayDate.add(Duration(days: offset))),
          ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: official,
        icon: const Icon(Icons.open_in_new, size: 18),
        label: Text(l10n.officialToshima),
      ),
    ];
  }

  Widget scheduleCard(
    String day,
    DaySchedule schedule, {
    bool prominent = false,
    bool showExpired = false,
  }) => Semantics(
    identifier: prominent ? 'schedule-primary' : null,
    child: Container(
      key: prominent ? const ValueKey('today-schedule') : null,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: prominent ? const Color(0xFF24684F) : const Color(0xFFEAF1E8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: prominent ? Colors.white : const Color(0xFF203D30),
          fontSize: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              identifier: prominent ? 'schedule-primary-date' : null,
              child: Text(
                '$day  ${dateLabel(schedule.date)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 18),
            Icon(
              schedule.status == ScheduleStatus.collection
                  ? Icons.delete_outline
                  : Icons.event_available_outlined,
              size: prominent ? 44 : 28,
              color: prominent ? Colors.white : const Color(0xFF24684F),
            ),
            const SizedBox(height: 10),
            Semantics(
              identifier: prominent ? 'schedule-primary-description' : null,
              child: Text(
                schedule.localizedDescription(l10n),
                style: TextStyle(
                  fontSize: prominent ? 30 : 23,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
            ),
            if (schedule.status == ScheduleStatus.collection) ...[
              const SizedBox(height: 10),
              if (showExpired &&
                  schedule.collections.every(
                    (entry) =>
                        entry.deadline.hour * 60 + entry.deadline.minute <=
                        widget.displayMinute,
                  ))
                Text(
                  l10n.disposalDeadlinePassed,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ScheduleDeadlines(schedule: schedule),
              const SizedBox(height: 8),
              Text(l10n.checkTime, style: const TextStyle(fontSize: 14)),
            ],
            if (schedule.status == ScheduleStatus.needsConfirmation)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: prominent ? Colors.white : null,
                  minimumSize: const Size(48, 48),
                ),
                onPressed: official,
                child: Text(l10n.official),
              ),
          ],
        ),
      ),
    ),
  );

  Widget scheduleRow(DaySchedule schedule) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLabel(schedule.date),
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),
        Text(
          schedule.localizedDescription(l10n),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        if (schedule.status == ScheduleStatus.needsConfirmation)
          TextButton.icon(
            onPressed: official,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(l10n.official),
          ),
        const Divider(),
      ],
    ),
  );

  List<Widget> searchPage() {
    final matches = sortingItems
        .where((item) => item.matches(query, l10n))
        .toList();
    return [
      heading(l10n.searchTitle, l10n.searchSubtitle),
      TextField(
        controller: searchController,
        onChanged: (value) => setState(() => query = value),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          labelText: l10n.itemName,
          hintText: l10n.searchHint,
        ),
      ),
      const SizedBox(height: 20),
      if (matches.isEmpty) ...[
        Text(l10n.noResults),
        TextButton(onPressed: official, child: Text(l10n.official)),
      ],
      for (final item in matches)
        Card(
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
            title: Text(
              item.localizedName(l10n),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              item.special == null ? l10n.disposal : l10n.disposalAndPlaces,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showItem(item),
          ),
        ),
    ];
  }

  void returnToItem() {
    final origin = mapOrigin;
    if (tab != 2 || origin == null) return;
    setState(() {
      tab = 1;
      special = origin.item.special;
      damaged = origin.damaged;
    });
    showItem(origin.item);
  }

  void answerDamage(bool value) => setState(() {
    damaged = value;
    final origin = mapOrigin;
    if (origin != null && origin.item.special == special) {
      mapOrigin = (item: origin.item, damaged: value);
    }
  });

  Future<void> showItem(SortingItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SheetCloseButton(onPressed: () => Navigator.pop(sheet)),
              areaContext(),
              heading(item.localizedName(l10n), l10n.sampleSorting),
              Text(
                item.localizedGuidance(l10n),
                style: const TextStyle(fontSize: 18, height: 1.7),
              ),
              const SizedBox(height: 24),
              if (item.special != null)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheet);
                    setState(() {
                      final previous = mapOrigin;
                      final answer = previous?.item.kind == item.kind
                          ? previous?.damaged
                          : null;
                      mapOrigin = (item: item, damaged: answer);
                      special = item.special!;
                      damaged = answer;
                      tab = 2;
                    });
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: Text(l10n.findPlaces),
                ),
              TextButton.icon(
                onPressed: official,
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.officialDisposal),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted && tab != 2) setState(() => mapOrigin = null);
  }

  List<Widget> placesPage() {
    final selected = special;
    final batteryQuestion = special == SpecialItem.rechargeable;
    final canShowPoints =
        selected != null && (!batteryQuestion || damaged == false);
    final points = canShowPoints
        ? demoPoints.where((point) => point.accepts.contains(special)).toList()
        : <CollectionPoint>[];
    return [
      if (mapOrigin != null)
        TextButton.icon(
          key: const ValueKey('return-to-item'),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: returnToItem,
          icon: const Icon(Icons.arrow_back),
          label: Text(l10n.backToItem(mapOrigin!.item.localizedName(l10n))),
        ),
      Text(
        l10n.placesTab,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: SpecialItem.values
            .map(
              (item) => ChoiceChip(
                label: Text(item.localizedName(l10n)),
                selected: item == special,
                onSelected: (_) => setState(() {
                  special = item;
                  damaged = null;
                }),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 16),
      if (selected == null)
        Text(l10n.chooseCollectionItem, style: const TextStyle(height: 1.6))
      else
        Text(selected.localizedHint(l10n), style: const TextStyle(height: 1.6)),
      if (batteryQuestion) ...[
        const SizedBox(height: 12),
        Text(
          l10n.damageQuestion,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.noDamage),
              selected: damaged == false,
              onSelected: (_) => answerDamage(false),
            ),
            ChoiceChip(
              label: Text(l10n.damagedOrUnknown),
              selected: damaged == true,
              onSelected: (_) => answerDamage(true),
            ),
          ],
        ),
        if (damaged != false)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l10n.damageWarning),
          ),
        TextButton(onPressed: official, child: Text(l10n.officialBattery)),
      ],
      const SizedBox(height: 20),
      CollectionMap(
        key: const ValueKey('collection-map'),
        points: selected == null ? demoPoints : points,
        onSelected: showPoint,
        tileSource: widget.mapTileSource,
        view: mapView,
        onShowList: canShowPoints && points.isNotEmpty
            ? () {
                final c = mapListKey.currentContext;
                if (c != null) {
                  Scrollable.ensureVisible(
                    c,
                    duration: const Duration(milliseconds: 250),
                  );
                }
              }
            : null,
      ),
      if (canShowPoints) ...[
        const SizedBox(height: 20),
        Text(
          l10n.placesCount(points.length),
          key: mapListKey,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(l10n.fictionalPoints),
      ],
      if (canShowPoints && points.isEmpty) ...[
        const SizedBox(height: 16),
        Text(l10n.noPoints),
        TextButton(onPressed: official, child: Text(l10n.official)),
      ],
      for (final point in points)
        Card(
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(l10n.samplePoint(point.id.toUpperCase())),
            subtitle: Text(l10n.conditions),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showPoint(point),
          ),
        ),
    ];
  }

  void showPoint(CollectionPoint point) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetCloseButton(onPressed: () => Navigator.pop(sheet)),
            areaContext(),
            heading(
              l10n.samplePoint(point.id.toUpperCase()),
              l10n.samplePointDetail,
            ),
            Text(
              l10n.acceptedItems(
                point.accepts
                    .map((item) => item.localizedName(l10n))
                    .join(l10n.localeName == 'ja' ? '・' : ', '),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.pointConditions, style: const TextStyle(height: 1.7)),
            TextButton(onPressed: official, child: Text(l10n.officialToshima)),
          ],
        ),
      ),
    ),
  );

  void showSettings() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetCloseButton(onPressed: () => Navigator.pop(sheet)),
            areaContext(),
            if (widget.updates != null)
              ListenableBuilder(
                listenable: widget.updates!,
                builder: (context, _) => widget.updates!.failed
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            liveRegion: true,
                            child: Text(l10n.updateEffectsError),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                            ),
                            onPressed: widget.updates!.busy
                                ? null
                                : widget.updates!.reconcile,
                            child: Text(l10n.notificationRetry),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                changeArea();
              },
              icon: const Icon(Icons.edit_location_alt_outlined),
              label: Text(l10n.chooseArea),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.about,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.aboutBody,
              style: const TextStyle(fontSize: 16, height: 1.7),
            ),
            if (widget.onWidgetSettings != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: identifiedAction(
                  'settings-widget',
                  OutlinedButton.icon(
                    icon: const Icon(Icons.widgets_outlined),
                    label: Text(l10n.widgetSettings),
                    onPressed: () {
                      Navigator.pop(sheet);
                      widget.onWidgetSettings!();
                    },
                  ),
                ),
              ),
            if (widget.onNotificationSettings != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: identifiedAction(
                  'settings-notifications',
                  OutlinedButton.icon(
                    icon: const Icon(Icons.notifications_outlined),
                    label: Text(l10n.notifications),
                    onPressed: () {
                      Navigator.pop(sheet);
                      widget.onNotificationSettings!();
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
