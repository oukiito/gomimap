// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';

import 'identified_action.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/languages.dart';

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key, required this.onChanged});
  final Future<bool> Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = Localizations.localeOf(context).toLanguageTag();
    return identifiedAction(
      'language-menu',
      PopupMenuButton<String>(
        icon: const Icon(Icons.language),
        tooltip: l10n.language,
        initialValue: current,
        onSelected: (code) async {
          final saved = await onChanged(code);
          if (!saved && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).languageSaveError),
              ),
            );
          }
        },
        itemBuilder: (context) => [
          for (final option in languageNames.entries)
            CheckedPopupMenuItem<String>(
              value: option.key,
              checked: option.key == current,
              child: Semantics(
                identifier: 'language-${option.key}',
                child: Text(option.value),
              ),
            ),
        ],
      ),
    );
  }
}
