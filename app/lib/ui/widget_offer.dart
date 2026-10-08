// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';

import 'identified_action.dart';

import 'package:intl/intl.dart';

import '../data/demo_data.dart';
import '../domain/municipal_dataset.dart';
import '../domain/calendar_date.dart';
import '../domain/schedule_focus.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/presentation.dart';
import '../widgets/widget_bridge.dart';
import '../widgets/widget_offer_store.dart';
import 'schedule_deadlines.dart';
import 'language_button.dart';

class WidgetOffer extends StatefulWidget {
  const WidgetOffer({
    super.key,
    required this.area,
    required this.dataset,
    required this.date,
    this.minute = 0,
    required this.bridge,
    required this.store,
    required this.firstTime,
    required this.publish,
    required this.onDone,
    required this.onLanguageChanged,
  });
  final DemoArea area;
  final MunicipalDataset? dataset;
  final DateTime date;
  final int minute;
  final HomeWidgetBridge bridge;
  final WidgetOfferStore store;
  final bool firstTime;
  final Future<bool> Function() publish;
  final VoidCallback onDone;
  final Future<bool> Function(String) onLanguageChanged;
  @override
  State<WidgetOffer> createState() => _WidgetOfferState();
}

class _WidgetOfferState extends State<WidgetOffer> with WidgetsBindingObserver {
  bool? supported;
  bool added = false, requested = false, busy = false;
  String? error;
  AppLocalizations get l10n => AppLocalizations.of(context);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  Future<void> _check() async {
    final canPin = await widget.bridge.pinSupported();
    final exists = await widget.bridge.isAdded();
    if (mounted) {
      setState(() {
        supported = canPin;
        added = exists;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<bool> _answer() async =>
      !widget.firstTime || await widget.store.answer();
  Future<void> _skip() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    if (await _answer()) {
      if (mounted) widget.onDone();
    } else if (mounted) {
      setState(() {
        busy = false;
        error = l10n.widgetSaveError;
      });
    }
  }

  Future<void> _add() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    if (!await widget.publish()) {
      if (mounted) {
        setState(() {
          busy = false;
          error = l10n.widgetFailure;
        });
      }
      return;
    }
    if (!await _answer()) {
      if (mounted) {
        setState(() {
          busy = false;
          error = l10n.widgetSaveError;
        });
      }
      return;
    }
    final accepted = await widget.bridge.requestPin();
    if (!mounted) return;
    setState(() {
      busy = false;
      requested = accepted;
      error = accepted ? null : l10n.widgetFailure;
    });
    // OS placement callback is separate; never call the request "added".
    if (accepted && widget.firstTime) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final calendar = demoCalendar(widget.area, dataset: widget.dataset);
    final today = CalendarDate.fromFields(widget.date);
    final day = scheduleFocus([
      for (var i = 0; i < 35; i++) calendar.onDate(today.addDays(i)),
    ], widget.minute);
    final label = day.day == today
        ? l10n.today
        : day.day == today.addDays(1)
        ? l10n.tomorrow
        : l10n.widgetNext;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.widgetSettings),
        automaticallyImplyLeading: !widget.firstTime,
        actions: [LanguageButton(onChanged: widget.onLanguageChanged)],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l10n.areaName(widget.area.name.toUpperCase()),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.widgetOfferTitle,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(l10n.widgetOfferBody),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$label ${DateFormat.MEd(l10n.localeName).format(day.date)}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.widgetSample,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      day.localizedDescription(l10n),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ScheduleDeadlines(schedule: day),
                  ],
                ),
              ),
            ),
            if (added)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(l10n.widgetAdded),
              ),
            if (requested && !added)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(l10n.widgetRequested),
              ),
            if (supported == false)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(l10n.widgetUnsupported),
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error!, semanticsLabel: error),
              ),
            const SizedBox(height: 16),
            if (supported == true && !added)
              identifiedAction(
                'widget-add',
                FilledButton(
                  onPressed: busy ? null : _add,
                  child: Text(l10n.widgetAdd),
                ),
              ),
            if (widget.firstTime)
              identifiedAction(
                'widget-skip',
                TextButton(
                  key: const ValueKey('widget-offer-skip'),
                  onPressed: busy ? null : _skip,
                  child: Text(l10n.widgetSkip),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
