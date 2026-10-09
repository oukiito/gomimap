// SPDX-License-Identifier: GPL-3.0-or-later
import 'update_journal.dart';
import 'update_journal_native.dart'
    if (dart.library.js_interop) 'update_journal_web.dart'
    as platform;

Future<UpdateJournal> createUpdateJournal() async {
  try {
    return await platform.createUpdateJournal();
  } catch (_) {
    // Keep the app readable; mutations fail closed while storage is unavailable.
    return const UnavailableUpdateJournal();
  }
}

class UnavailableUpdateJournal implements UpdateJournal {
  const UnavailableUpdateJournal();
  @override
  Future<String?> read() async =>
      throw const FormatException('Journal unavailable');
  @override
  Future<bool> write(String value) async => false;
}
