// SPDX-License-Identifier: GPL-3.0-or-later

import '../data/demo_setup_store.dart';
import 'widget_offer_store.dart';

/// Persist the pending offer before committing a first district, so a restart
/// cannot misclassify this new setup as a pre-widget legacy installation.
class WidgetSetupStore implements DemoSetupStore {
  WidgetSetupStore(this.delegate, this.offer);
  final DemoSetupStore delegate;
  final WidgetOfferStore offer;
  @override
  DemoSetupSnapshot read() => delegate.read();
  @override
  Future<bool> save(DemoSetupSnapshot snapshot) async {
    if (snapshot.phase == DemoSetupPhase.districtSaved &&
        !await offer.ensurePending()) {
      return false;
    }
    return delegate.save(snapshot);
  }
}
