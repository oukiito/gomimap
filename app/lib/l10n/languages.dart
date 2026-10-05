// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/widgets.dart';

/// Native names stay readable even when the current UI language is unfamiliar.
const languageNames = {
  'ja': '日本語',
  'en': 'English',
  'zh-Hans': '简体中文',
  'zh-Hant': '繁體中文',
  'ko': '한국어',
  'vi': 'Tiếng Việt',
  'ne': 'नेपाली',
  'pt': 'Português',
  'es': 'Español',
  'fil': 'Filipino / Tagalog',
};

Locale? savedLocale(String? code) {
  final tag = code?.replaceAll('_', '-');
  if (!languageNames.containsKey(tag)) return null;
  final parts = tag!.split('-');
  return Locale.fromSubtags(
    languageCode: parts.first,
    scriptCode: parts.length == 2 ? parts.last : null,
  );
}

final appLocales = List<Locale>.unmodifiable(
  languageNames.keys.map((code) => savedLocale(code)!),
);

Locale resolveAppLocale(List<Locale>? preferred, Iterable<Locale> supported) {
  for (final candidate in preferred ?? const <Locale>[]) {
    final language = candidate.languageCode == 'tl'
        ? 'fil'
        : candidate.languageCode;
    if (language == 'zh') {
      // An explicit script takes priority over region (e.g. zh-Hans-TW).
      final traditional =
          candidate.scriptCode == 'Hant' ||
          (candidate.scriptCode == null &&
              const {'TW', 'HK', 'MO'}.contains(candidate.countryCode));
      return savedLocale(traditional ? 'zh-Hant' : 'zh-Hans')!;
    }
    for (final value in supported) {
      if (language == value.languageCode) return value;
    }
  }
  return const Locale('ja');
}
