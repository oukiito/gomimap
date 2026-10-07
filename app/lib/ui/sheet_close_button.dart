// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

class SheetCloseButton extends StatelessWidget {
  const SheetCloseButton({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: TextButton.icon(
      key: const ValueKey('sheet-close'),
      onPressed: onPressed,
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      icon: const Icon(Icons.close, size: 20),
      label: Text(AppLocalizations.of(context).close),
    ),
  );
}
