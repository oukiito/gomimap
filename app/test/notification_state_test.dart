// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gomimap/notifications/notification_state.dart';

void main() {
  test('first offer and desired settings persist as one value; legacy users are not prompted', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(
      NotificationStateStore(prefs, legacyDistrictSaved: true).answered,
      isTrue,
    );
    final fresh = NotificationStateStore(prefs, legacyDistrictSaved: false);
    expect(fresh.answered, isFalse);
    expect(await fresh.ensurePending(), isTrue);
    expect(
      NotificationStateStore(prefs, legacyDistrictSaved: true).answered,
      isFalse,
    );
    expect(
      await fresh.save(
        const NotificationSettings(
          enabled: true,
          morningMinute: 420,
          eveningEnabled: true,
        ),
        answer: true,
      ),
      isTrue,
    );
    final restart = NotificationStateStore(prefs, legacyDistrictSaved: true);
    expect(restart.settings.morningMinute, 420);
    expect(restart.settings.eveningEnabled, isTrue);
    expect(restart.answered, isTrue);
  });
  test('corrupt preferences recover to off, not silently enabled', () async {
    SharedPreferences.setMockInitialValues({
      NotificationStateStore.key: 'broken',
    });
    final prefs = await SharedPreferences.getInstance();
    final state = NotificationStateStore(prefs, legacyDistrictSaved: false);
    expect(state.settings.enabled, isFalse);
    expect(state.recovered, isTrue);
    expect(
      () => NotificationSettings.decode({
        'enabled': true,
        'morningMinute': 1440,
        'eveningEnabled': false,
        'eveningMinute': 1200,
      }),
      throwsFormatException,
    );
  });
}
