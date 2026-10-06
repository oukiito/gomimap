// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/demo_data.dart';
import '../data/demo_setup_store.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/presentation.dart';
import 'language_button.dart';

/// Shared confirmation flow for first-time demo setup and later corrections.
/// It cannot resolve GPS coordinates or select a real municipality district.
class DemoAreaSetup extends StatefulWidget {
  const DemoAreaSetup({
    super.key,
    required this.store,
    required this.initial,
    required this.onLanguageChanged,
    required this.onSaved,
    this.currentArea,
  });

  final DemoSetupStore store;
  final DemoSetupSnapshot initial;
  final DemoArea? currentArea;
  final Future<bool> Function(String) onLanguageChanged;
  final ValueChanged<DemoArea> onSaved;

  @override
  State<DemoAreaSetup> createState() => _DemoAreaSetupState();
}

class _DemoAreaSetupState extends State<DemoAreaSetup> {
  late DemoSetupSnapshot snapshot;
  bool saving = false;
  bool failed = false;
  bool get editing => widget.currentArea != null;
  bool get confirming => snapshot.phase == DemoSetupPhase.confirm;

  @override
  void initState() {
    super.initState();
    snapshot = widget.initial;
  }

  Future<void> moveTo(DemoSetupSnapshot next) async {
    if (saving) return;
    setState(() {
      saving = true;
      failed = false;
    });
    // Later corrections keep the confirmed district untouched until Save.
    var saved = editing && next.phase != DemoSetupPhase.districtSaved;
    if (!saved) {
      try {
        saved = await widget.store.save(next);
      } catch (_) {
        saved = false;
      }
    }
    if (!mounted) return;
    setState(() {
      saving = false;
      failed = !saved;
      if (saved) snapshot = next;
    });
    if (saved && next.phase == DemoSetupPhase.districtSaved) {
      widget.onSaved(next.area!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final candidate = snapshot.area;
    return PopScope(
      canPop: !saving && (editing || !confirming),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !saving && !editing && confirming) {
          moveTo(const DemoSetupSnapshot.choose());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          automaticallyImplyLeading: false,
          leading: editing
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: saving ? null : () => Navigator.pop(context),
                )
              : null,
          actions: [LanguageButton(onChanged: widget.onLanguageChanged)],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 660),
              child: Column(
                children: [
                  if (editing)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.currentArea(
                            l10n.areaName(
                              widget.currentArea!.name.toUpperCase(),
                            ),
                          ),
                          key: const ValueKey('setup-current-area'),
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Color(0xFF24684F),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView(
                      key: ValueKey(snapshot.phase),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEEC9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(l10n.sampleBanner),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          confirming
                              ? l10n.confirmAreaTitle
                              : l10n.setupAreaTitle,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(l10n.fictionalAreas),
                        if (snapshot.recovered) ...[
                          const SizedBox(height: 16),
                          Text(l10n.setupRecovery),
                        ],
                        const SizedBox(height: 20),
                        if (confirming && candidate != null) ...[
                          Semantics(
                            header: true,
                            child: Text(
                              l10n.candidateArea(
                                l10n.areaName(candidate.name.toUpperCase()),
                              ),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF1E8),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.demoDate(
                                    DateFormat.yMMMMd(l10n.localeName)
                                        .format(demoToday),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  demoCalendar(candidate)
                                      .on(demoToday)
                                      .localizedDescription(l10n),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            key: const ValueKey('confirm-area-save'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(48, 48),
                            ),
                            onPressed: saving
                                ? null
                                : () => moveTo(
                                    DemoSetupSnapshot.saved(candidate),
                                  ),
                            child: Text(l10n.confirmAreaAction),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                            ),
                            onPressed: saving
                                ? null
                                : () =>
                                      moveTo(const DemoSetupSnapshot.choose()),
                            child: Text(l10n.chooseAgain),
                          ),
                        ] else
                          for (final area in DemoArea.values)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: OutlinedButton(
                                key: ValueKey('choose-area-${area.name}'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(48, 64),
                                  padding: const EdgeInsets.all(16),
                                  alignment: Alignment.centerLeft,
                                ),
                                onPressed: saving
                                    ? null
                                    : () => moveTo(
                                        DemoSetupSnapshot.confirm(area),
                                      ),
                                child: Text(
                                  l10n.areaName(area.name.toUpperCase()),
                                ),
                              ),
                            ),
                        if (editing)
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                            ),
                            onPressed: saving
                                ? null
                                : () => Navigator.pop(context),
                            child: Text(l10n.cancel),
                          ),
                      ],
                    ),
                  ),
                  if (saving || failed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          saving ? l10n.savingArea : l10n.areaSaveError,
                          key: const ValueKey('setup-save-status'),
                          style: TextStyle(
                            color: failed
                                ? Theme.of(context).colorScheme.error
                                : null,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
