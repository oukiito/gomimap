// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:shared_preferences/shared_preferences.dart';

/// Answer to the offer is independent of OS-confirmed widget placement.
class WidgetOfferStore {
  WidgetOfferStore(this.preferences, {required bool legacyDistrictSaved}) {
    final saved = preferences.get(key);
    answered = saved is bool ? saved : saved != null || legacyDistrictSaved;
  }
  static const key = 'widget.offer.answered.v1';
  final SharedPreferences preferences;
  late bool answered;
  Future<bool> ensurePending() async {
    if (answered || preferences.containsKey(key)) return true;
    return _write(false);
  }

  Future<bool> answer() async {
    if (!await _write(true)) return false;
    answered = true;
    return true;
  }

  Future<bool> _write(bool value) async {
    try {
      if (await preferences.setBool(key, value)) return true;
    } catch (_) {
      /* Keep the last committed answer. */
    }
    // The legacy plugin optimistically changes its cache before host success.
    try {
      await preferences.reload();
    } catch (_) {
      /* In-memory answer stays. */
    }
    return false;
  }
}
