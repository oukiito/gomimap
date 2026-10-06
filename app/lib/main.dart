// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'l10n/generated/app_localizations.dart';
import 'l10n/languages.dart';
import 'l10n/presentation.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/demo_data.dart';
import 'domain/schedule.dart';
import 'ui/collection_map.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(GomimapApp(preferences: preferences));
}

class GomimapApp extends StatefulWidget {
  const GomimapApp({super.key, required this.preferences});
  final SharedPreferences preferences;
  @override
  State<GomimapApp> createState() => _GomimapAppState();
}

class _GomimapAppState extends State<GomimapApp> {
  Locale? locale;

  @override
  void initState() {
    super.initState();
    final saved = widget.preferences.getString('app.language');
    locale = savedLocale(saved);
  }

  Future<bool> changeLanguage(String code) async {
    final selected = savedLocale(code);
    if (selected == null) return false;
    setState(() => locale = selected);
    try {
      return await widget.preferences.setString('app.language', code);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
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
    home: HomeShell(
      preferences: widget.preferences,
      onLanguageChanged: changeLanguage,
    ),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.preferences,
    required this.onLanguageChanged,
  });
  final SharedPreferences preferences;
  final Future<bool> Function(String) onLanguageChanged;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  String dateLabel(DateTime date) =>
      DateFormat.MEd(l10n.localeName).format(date);
  int tab = 0;
  late DemoArea area;
  SpecialItem special = SpecialItem.dryBattery;
  String query = '';
  bool? damaged;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    area = widget.preferences.getString('demo.area') == 'b'
        ? DemoArea.b
        : DemoArea.a;
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
    final selected = await showModalBottomSheet<DemoArea>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.chooseArea,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(l10n.fictionalAreas),
              const SizedBox(height: 16),
              for (final value in DemoArea.values)
                ListTile(
                  title: Text(l10n.areaName(value.name.toUpperCase())),
                  trailing: value == area ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(context, value),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() => area = selected);
    try {
      if (await widget.preferences.setString('demo.area', selected.name)) {
        return;
      }
    } catch (_) {
      /* Display a recoverable persistence error below. */
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.areaSaveError)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        l10n.appTitle,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          onPressed: showSettings,
          icon: const Icon(Icons.settings_outlined),
          tooltip: l10n.about,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.language),
          tooltip: l10n.language,
          initialValue: Localizations.localeOf(context).toLanguageTag(),
          onSelected: (code) async {
            final saved = await widget.onLanguageChanged(code);
            if (!saved && context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.languageSaveError)));
            }
          },
          itemBuilder: (context) => [
            for (final option in languageNames.entries)
              CheckedPopupMenuItem<String>(
                value: option.key,
                checked:
                    option.key ==
                    Localizations.localeOf(context).toLanguageTag(),
                child: Text(option.value),
              ),
          ],
        ),
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
                  key: ValueKey(tab),
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
      onDestinationSelected: (value) => setState(() => tab = value),
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
    final calendar = demoCalendar(area);
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          l10n.demoDate(DateFormat.yMMMMd(l10n.localeName).format(demoToday)),
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ),
      scheduleCard(l10n.today, calendar.on(demoToday), prominent: true),
      const SizedBox(height: 12),
      scheduleCard(
        l10n.tomorrow,
        calendar.on(demoToday.add(const Duration(days: 1))),
      ),
      const SizedBox(height: 28),
      Text(
        l10n.upcoming,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      for (var offset = 2; offset < 7; offset++)
        scheduleRow(calendar.on(demoToday.add(Duration(days: offset)))),
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
  }) => Container(
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
          Text(
            '$day  ${dateLabel(schedule.date)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
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
          Text(
            schedule.localizedDescription(l10n),
            style: TextStyle(
              fontSize: prominent ? 30 : 23,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          if (schedule.status == ScheduleStatus.collection) ...[
            const SizedBox(height: 10),
            Text(l10n.checkTime, style: const TextStyle(fontSize: 14)),
          ],
          if (schedule.status == ScheduleStatus.needsConfirmation)
            TextButton(onPressed: official, child: Text(l10n.official)),
        ],
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

  void showItem(SortingItem item) {
    showModalBottomSheet<void>(
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
                      special = item.special!;
                      damaged = null;
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
  }

  List<Widget> placesPage() {
    final batteryQuestion = special == SpecialItem.rechargeable;
    final canShowPoints = !batteryQuestion || damaged == false;
    final points = canShowPoints
        ? demoPoints.where((point) => point.accepts.contains(special)).toList()
        : <CollectionPoint>[];
    return [
      heading(l10n.placesTab, l10n.placesSubtitle),
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
      Text(special.localizedHint(l10n), style: const TextStyle(height: 1.6)),
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
              onSelected: (_) => setState(() => damaged = false),
            ),
            ChoiceChip(
              label: Text(l10n.damagedOrUnknown),
              selected: damaged == true,
              onSelected: (_) => setState(() => damaged = true),
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
      if (canShowPoints) CollectionMap(points: points, onSelected: showPoint),
      const SizedBox(height: 20),
      Text(
        l10n.placesCount(points.length),
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 6),
      Text(l10n.fictionalPoints),
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
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            areaContext(),
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
          ],
        ),
      ),
    ),
  );
}
