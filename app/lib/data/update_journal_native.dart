// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'update_journal.dart';

Future<UpdateJournal> createUpdateJournal() async => FileUpdateJournal(
  File(
    '${(await getApplicationSupportDirectory()).path}/update-coordination/current.json',
  ),
);

class FileUpdateJournal implements UpdateJournal {
  FileUpdateJournal(this.file);
  final File file;
  @override
  Future<String?> read() async {
    if (!await file.exists()) return null;
    if (await file.length() > 16384) {
      throw const FormatException('Journal too large');
    }
    return utf8.decode(await file.readAsBytes());
  }

  @override
  Future<bool> write(String value) async {
    try {
      UpdateRecord.decode(value);
      await file.parent.create(recursive: true);
      final pending = File('${file.path}.pending');
      await pending.writeAsBytes(utf8.encode(value), flush: true);
      await pending.rename(file.path);
      return true;
    } catch (_) {
      return false;
    }
  }
}
