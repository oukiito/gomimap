// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:shared_preferences/shared_preferences.dart';

import 'update_journal.dart';

/// Web confirmation cache only; not a native power-loss durability guarantee.
Future<UpdateJournal> createUpdateJournal() async =>
    PreferencesUpdateJournal(await SharedPreferences.getInstance());

class PreferencesUpdateJournal implements UpdateJournal {
  PreferencesUpdateJournal(this.preferences);
  final SharedPreferences preferences;
  @override
  Future<String?> read() async =>
      preferences.getString('demo.update.journal.v1');
  @override
  Future<bool> write(String value) async {
    UpdateRecord.decode(value);
    try {
      if (await preferences.setString('demo.update.journal.v1', value)) {
        return true;
      }
    } catch (_) {
      /* Preserve last committed cache. */
    }
    try {
      await preferences.reload();
    } catch (_) {}
    return false;
  }
}
