// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../notifications/notification_controller.dart';
import '../notifications/notification_state.dart';
import '../data/demo_data.dart';
import 'identified_action.dart';
import 'language_button.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({
    super.key,
    required this.controller,
    required this.area,
    required this.firstTime,
    required this.onDone,
    required this.onLanguageChanged,
    required this.fixture,
    required this.qa,
  });
  final NotificationController controller;
  final DemoArea area;
  final bool firstTime, fixture, qa;
  final VoidCallback onDone;
  final Future<bool> Function(String) onLanguageChanged;
  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage>
    with WidgetsBindingObserver {
  late bool enabled, evening;
  late int morningMinute, eveningMinute;
  bool saving = false;
  String? error;
  AppLocalizations get l10n => AppLocalizations.of(context);
  @override
  void initState() {
    super.initState();
    final s = widget.controller.store.settings;
    enabled = widget.firstTime ? true : s.enabled;
    evening = s.eveningEnabled;
    morningMinute = s.morningMinute;
    eveningMinute = s.eveningMinute;
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(changed);
    widget.controller.refresh();
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) widget.controller.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(changed);
    super.dispose();
  }

  String time(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
  Future<void> chooseTime(bool night) async {
    final minute = night ? eveningMinute : morningMinute;
    final chosen = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (chosen != null && mounted) {
      setState(() {
        if (night) {
          eveningMinute = chosen.hour * 60 + chosen.minute;
        } else {
          morningMinute = chosen.hour * 60 + chosen.minute;
        }
      });
    }
  }

  Future<void> save() async {
    if (saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      if (enabled && widget.controller.state['permission'] != 'allowed') {
        await widget.controller.bridge.requestPermission();
      }
      final ok = await widget.controller.save(
        NotificationSettings(
          enabled: enabled,
          morningMinute: morningMinute,
          eveningEnabled: evening,
          eveningMinute: eveningMinute,
        ),
        answer: true,
      );
      if (!mounted) return;
      if (!ok) {
        setState(() {
          saving = false;
          error = l10n.notificationError;
        });
        return;
      }
      if (widget.firstTime) {
        widget.onDone();
        return;
      }
      setState(() {
        saving = false;
        error = widget.controller.failed ? l10n.notificationError : null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = l10n.notificationError;
        });
      }
    }
  }

  Future<void> skip() async {
    if (saving) return;
    setState(() => saving = true);
    final ok = await widget.controller.skip();
    if (!mounted) return;
    if (ok) {
      widget.onDone();
    } else {
      setState(() {
        saving = false;
        error = l10n.notificationError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    final permission = state['permission'];
    final preview = state['preview'] == true;
    final count = (preview ? state['planCount'] : state['count']) as int? ?? 0;
    final next = state['nextDue'] as int? ?? 0;
    return PopScope(
      canPop: !saving && !widget.firstTime,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.notifications),
          automaticallyImplyLeading: !widget.firstTime,
          actions: [LanguageButton(onChanged: widget.onLanguageChanged)],
        ),
        body: SafeArea(
          child: Semantics(
            identifier: 'notification-content',
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  l10n.areaName(widget.area.name.toUpperCase()),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                if (widget.firstTime) ...[
                  Text(
                    l10n.notificationOfferTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.notificationIntro),
                ],
                if (!widget.firstTime)
                  identifiedAction(
                    'notification-enabled',
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.notifications),
                      value: enabled,
                      onChanged: saving
                          ? null
                          : (v) => setState(() => enabled = v),
                    ),
                  ),
                identifiedAction(
                  'notification-morning-time',
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.notificationEnabled),
                    subtitle: Text(time(morningMinute)),
                    trailing: const Icon(Icons.schedule),
                    onTap: saving ? null : () => chooseTime(false),
                  ),
                ),
                if (!widget.firstTime) ...[
                  identifiedAction(
                    'notification-evening',
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.notificationEvening),
                      value: evening,
                      onChanged: saving || !enabled
                          ? null
                          : (v) => setState(() => evening = v),
                    ),
                  ),
                  if (evening)
                    identifiedAction(
                      'notification-evening-time',
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.notificationEvening),
                        subtitle: Text(time(eveningMinute)),
                        trailing: const Icon(Icons.schedule),
                        onTap: saving ? null : () => chooseTime(true),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                if (!widget.firstTime && state.isNotEmpty) ...[
                  Text(
                    permission == 'allowed'
                        ? (preview
                              ? l10n.notificationPreview(count)
                              : l10n.notificationReserved(count))
                        : l10n.notificationPermission,
                  ),
                  if (permission != 'allowed')
                    TextButton(
                      onPressed: saving
                          ? null
                          : widget.controller.bridge.openSettings,
                      child: Text(l10n.notificationOsSettings),
                    ),
                  if (widget.fixture && !widget.qa)
                    Text(l10n.notificationFixture),
                  if (widget.controller.store.settings.enabled &&
                      count == 0 &&
                      permission == 'allowed' &&
                      !(widget.fixture && !widget.qa))
                    Text(l10n.notificationNone),
                  if (permission == 'allowed' && count > 0 && next > 0)
                    Text(
                      l10n.notificationNext(
                        DateFormat('M/d HH:mm', l10n.localeName).format(
                          DateTime.fromMillisecondsSinceEpoch(
                            next,
                            isUtc: true,
                          ).add(const Duration(hours: 9)),
                        ),
                      ),
                    ),
                ],
                if (error != null || widget.controller.failed)
                  Semantics(
                    liveRegion: true,
                    child: Text(error ?? l10n.notificationError),
                  ),
                const SizedBox(height: 16),
                identifiedAction(
                  'notification-save',
                  FilledButton(
                    onPressed: saving ? null : save,
                    child: Text(
                      widget.firstTime
                          ? l10n.notificationOfferTitle
                          : l10n.notificationSave,
                    ),
                  ),
                ),
                if (widget.firstTime)
                  identifiedAction(
                    'notification-later',
                    TextButton(
                      onPressed: saving ? null : skip,
                      child: Text(l10n.notificationLater),
                    ),
                  )
                else ...[
                  TextButton(
                    onPressed: saving ? null : widget.onDone,
                    child: Text(l10n.cancel),
                  ),
                  if (widget.controller.failed)
                    TextButton(
                      onPressed: saving ? null : widget.controller.refresh,
                      child: Text(l10n.notificationRetry),
                    ),
                  if (widget.qa && permission == 'allowed' && count > 0)
                    identifiedAction(
                      'notification-test',
                      OutlinedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final ok = await widget.controller.bridge
                                    .test();
                                if (!ok && mounted) {
                                  setState(
                                    () => error = l10n.notificationError,
                                  );
                                }
                              },
                        child: Text(l10n.notificationTest),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
