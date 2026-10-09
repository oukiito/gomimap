// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/address_questions.dart';
import '../domain/area_resolution.dart';
import '../domain/calendar_date.dart';
import '../domain/municipal_dataset.dart';
import '../l10n/generated/app_localizations.dart';
import 'identified_action.dart';
import 'language_button.dart';

enum _Answer { unknown }

class AddressAreaForm extends StatefulWidget {
  const AddressAreaForm({
    super.key,
    required this.dataset,
    required this.date,
    required this.onCandidate,
    required this.onLanguageChanged,
    this.currentAreaId,
  });
  final MunicipalDataset dataset;
  final CalendarDate date;
  final String? currentAreaId;
  final ValueChanged<String> onCandidate;
  final Future<bool> Function(String) onLanguageChanged;
  @override
  State<AddressAreaForm> createState() => _AddressAreaFormState();
}

class _AddressAreaFormState extends State<AddressAreaForm> {
  Map<String, Object?> facts = {};
  String? unknownField;
  final controllers = <String, TextEditingController>{};
  List<AddressQuestion> get questions =>
      addressQuestions(widget.dataset, widget.date);
  AppLocalizations get l10n => AppLocalizations.of(context);
  String districtName(String id) =>
      widget.dataset.kind == DatasetKind.fixture &&
          widget.dataset.municipality.id == 'demo-toshima' &&
          {'a', 'b'}.contains(id)
      ? l10n.areaName(id.toUpperCase())
      : widget.dataset.areas[id]?.name ?? id;
  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void answer(AddressQuestion q, Object? value) {
    if (q.number && value == _Answer.unknown) controllers[q.field]?.clear();
    final next = changeAddressAnswer(
      questions,
      facts,
      q.field,
      value == _Answer.unknown ? null : value,
    );
    for (final key in controllers.keys) {
      if (!next.containsKey(key) && key != q.field) controllers[key]!.clear();
    }
    setState(() {
      facts = next;
      unknownField = value == _Answer.unknown ? q.field : null;
    });
  }

  String label(AddressQuestion q) => switch (q.field) {
    'address.town' => l10n.addressTown,
    'address.chome' => l10n.addressChome,
    'address.block' => l10n.addressBlock,
    'address.streetSide' =>
      widget.dataset.kind == DatasetKind.fixture
          ? l10n.addressStreet
          : q.prompt,
    _ => q.prompt,
  };
  InputDecoration decoration(AddressQuestion q) => InputDecoration(
    labelText: label(q),
    filled: false,
    isDense: true,
    border: const UnderlineInputBorder(),
    enabledBorder: const UnderlineInputBorder(),
    focusedBorder: const UnderlineInputBorder(),
    contentPadding: const EdgeInsets.symmetric(vertical: 12),
    constraints: const BoxConstraints(minHeight: 48),
  );

  String option(AddressQuestion q, Object value) {
    if (value is bool) return value ? l10n.addressYes : l10n.addressNo;
    if (value is num) {
      return NumberFormat.decimalPattern(l10n.localeName).format(value);
    }
    if (q.field == 'address.streetSide') {
      if (value == 'along') return l10n.addressAlong;
      if (value == 'away') return l10n.addressAway;
    }
    if (widget.dataset.kind == DatasetKind.fixture && value == '架空町') {
      return l10n.addressFictionalTown;
    }
    return value
        .toString(); // Preserve source names without an approved translation.
  }

  @override
  Widget build(BuildContext context) {
    final qs = questions;
    final resolution = resolveArea(widget.dataset, widget.date, facts);
    var visible = true;
    final inputs = <Widget>[];
    for (final q in qs) {
      if (!visible) break;
      inputs.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: q.number
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    identifiedAction(
                      'address-field-${q.field.replaceAll('.', '-')}',
                      TextField(
                        controller: controllers.putIfAbsent(
                          q.field,
                          TextEditingController.new,
                        ),
                        keyboardType: TextInputType.number,
                        decoration: decoration(q),
                        onChanged: (text) => answer(q, addressInteger(text)),
                      ),
                    ),
                    TextButton(
                      onPressed: () => answer(q, _Answer.unknown),
                      child: Text(l10n.addressUnknown),
                    ),
                  ],
                )
              : identifiedAction(
                  'address-field-${q.field.replaceAll('.', '-')}',
                  InputDecorator(
                    decoration: decoration(q),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Object>(
                        isExpanded: true,
                        value: unknownField == q.field
                            ? _Answer.unknown
                            : facts[q.field],
                        hint: Text(l10n.addressSelect),
                        items: [
                          for (final value in q.choices)
                            DropdownMenuItem(
                              value: value,
                              child: Text(option(q, value)),
                            ),
                          DropdownMenuItem(
                            value: _Answer.unknown,
                            child: Text(l10n.addressUnknown),
                          ),
                        ],
                        onChanged: (value) => answer(q, value),
                      ),
                    ),
                  ),
                ),
        ),
      );
      visible =
          facts[q.field] != null &&
          resolveArea(widget.dataset, widget.date, {
                for (final entry in facts.entries)
                  if (qs.indexWhere((item) => item.field == entry.key) <=
                      qs.indexOf(q))
                    entry.key: entry.value,
              }).status !=
              AreaResolutionStatus.unsupported;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addressChoose),
        actions: [LanguageButton(onChanged: widget.onLanguageChanged)],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 660),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.currentAreaId == null
                          ? widget.dataset.municipality.name
                          : l10n.currentArea(
                              districtName(widget.currentAreaId!),
                            ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (widget.dataset.kind == DatasetKind.fixture) ...[
                        const SizedBox(height: 12),
                        Text(l10n.sampleBanner),
                      ],
                      const SizedBox(height: 20),
                      ...inputs,
                      if (resolution.status == AreaResolutionStatus.unsupported)
                        Text(l10n.addressUnsupported),
                      if (resolution.status == AreaResolutionStatus.ambiguous)
                        Text(l10n.addressConflict),
                      if (unknownField != null ||
                          resolution.status ==
                              AreaResolutionStatus.needsConfirmation ||
                          qs.isEmpty)
                        Text(l10n.addressNeedsConfirmation),
                      if (resolution.status ==
                          AreaResolutionStatus.matched) ...[
                        Text(
                          l10n.candidateArea(
                            districtName(resolution.candidates.single.area.id),
                          ),
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 12),
                      ],
                      identifiedAction(
                        'address-confirm-candidate',
                        FilledButton(
                          onPressed: resolution.matchedAreaId == null
                              ? null
                              : () => widget.onCandidate(
                                  resolution.matchedAreaId!,
                                ),
                          child: Text(l10n.addressFind),
                        ),
                      ),
                      if (unknownField != null ||
                          resolution.status ==
                              AreaResolutionStatus.unsupported ||
                          resolution.status == AreaResolutionStatus.ambiguous ||
                          resolution.status ==
                              AreaResolutionStatus.needsConfirmation ||
                          qs.isEmpty)
                        TextButton(
                          onPressed: () async {
                            var opened = false;
                            try {
                              opened = await launchUrl(
                                Uri.parse(
                                  widget.dataset.municipality.officialUrl,
                                ),
                              );
                            } catch (_) {}
                            if (!opened && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.sourceOpenError(
                                      widget.dataset.municipality.officialUrl,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(l10n.official),
                        ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
