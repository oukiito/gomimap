// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get appTitle => 'Gomimap';

  @override
  String get language => 'Wika / Language';

  @override
  String get languageSaveError =>
      'Hindi na-save ang wika. Piliin itong muli sa susunod.';

  @override
  String get about => 'Tungkol sa prototype';

  @override
  String get sampleBanner =>
      'Halimbawang datos · Huwag gamitin sa aktuwal na pagtatapon';

  @override
  String get today => 'Ngayon';

  @override
  String get tomorrow => 'Bukas';

  @override
  String get searchTab => 'Pagbukod';

  @override
  String get placesTab => 'Lugar ng pag-recycle';

  @override
  String get chooseArea => 'Pumili ng lugar';

  @override
  String get fictionalAreas => 'Kathang-isip na mga lugar para sa pagsubok.';

  @override
  String areaName(String area) {
    return 'Toshima · Halimbawang lugar $area';
  }

  @override
  String get areaSaveError =>
      'Hindi ma-save. Hindi nagbago ang setting. Mangyaring subukan muli.';

  @override
  String sourceOpenError(String url) {
    return 'Hindi mabuksan ang opisyal na pahina.\n$url';
  }

  @override
  String demoDate(String date) {
    return 'Halimbawa para sa $date';
  }

  @override
  String get upcoming => 'Mga susunod na koleksyon';

  @override
  String get officialToshima => 'Opisyal na impormasyon ng Toshima (Japanese)';

  @override
  String get official => 'Opisyal na impormasyon (Japanese)';

  @override
  String get checkTime => 'Tingnan ang opisyal na paraan at oras ng pagtatapon';

  @override
  String get noCollection => 'Walang koleksyon';

  @override
  String get uncertain => 'Kailangang kumpirmahin ang iskedyul ng koleksyon';

  @override
  String get burnable => 'Nasusunog na basura';

  @override
  String get recyclables => 'Mga nare-recycle';

  @override
  String get metals => 'Metal, seramika at salamin';

  @override
  String get searchTitle => 'Paano ito itatapon?';

  @override
  String get searchSubtitle => 'Hanapin gamit ang pangalan ng bagay.';

  @override
  String get itemName => 'Pangalan ng bagay';

  @override
  String get searchHint => 'Hal.: baterya, plastik na bote';

  @override
  String get noResults =>
      'Walang nahanap. Subukan ang ibang pangalan o tingnan ang opisyal na impormasyon.';

  @override
  String get disposal => 'Paraan ng pagtatapon';

  @override
  String get disposalAndPlaces => 'Paraan at lugar ng koleksyon';

  @override
  String get sampleSorting => 'Halimbawang gabay sa pagbukod';

  @override
  String get findPlaces => 'Maghanap ng lugar ng koleksyon';

  @override
  String get officialDisposal => 'Opisyal na paraan ng pagtatapon (Japanese)';

  @override
  String get placesSubtitle =>
      'Mga lugar para sa baterya, maliliit na elektroniko at fluorescent na tubo.\nPara sa karaniwang basura, tingnan ang Ngayon.';

  @override
  String get damageQuestion => 'Namamaga o sira ba ito?';

  @override
  String get noDamage => 'Hindi';

  @override
  String get damagedOrUnknown => 'Oo / Hindi sigurado';

  @override
  String get damageWarning =>
      'Huwag ilagay sa karaniwang kahon ng koleksyon. Suriin ang kondisyon at tingnan ang opisyal na gabay ng ward para malaman kung sino ang kokontakin.';

  @override
  String get officialBattery =>
      'Opisyal na gabay at kontak para sa baterya (Japanese)';

  @override
  String placesCount(int count) {
    return 'Mga halimbawang lugar ($count)';
  }

  @override
  String get fictionalPoints =>
      'Kathang-isip ang mga lugar na ito. Huwag puntahan.';

  @override
  String get noPoints =>
      'Wala pang kumpirmadong lugar para sa bagay na ito. Tingnan ang opisyal na gabay ng ward.';

  @override
  String get conditions => 'Tingnan ang mga kondisyon';

  @override
  String samplePoint(String point) {
    return 'Halimbawang lugar ng koleksyon $point';
  }

  @override
  String get samplePointDetail => 'Kathang-isip na lugar para sa pagsubok';

  @override
  String acceptedItems(String items) {
    return 'Halimbawa ng mga tinatanggap: $items';
  }

  @override
  String get pointConditions =>
      'Oras at kondisyon: hindi pa nakarehistro.\nHindi ito aktuwal na lugar ng pagtanggap. Walang direksyon papunta rito.';

  @override
  String get mapTitle => 'Mapa ng koleksyon';

  @override
  String get mapUnavailable =>
      'Hindi pa nakakonekta ang mapa.\nSubukan ang listahan sa ibaba.';

  @override
  String get aboutBody =>
      'Gumagamit ang development sample ng kathang-isip na iskedyul, lugar at koleksiyon. Huwag gamitin sa aktuwal na pagtatapon ng basura.\n\nNasa device ang lugar, wika at setting ng paalala. Hindi kinokolekta ang mga larawan o lokasyon.';

  @override
  String get dryBattery => 'Mga dry-cell na baterya';

  @override
  String get rechargeable => 'Mga rechargeable na baterya';

  @override
  String get appliance => 'Maliliit na elektroniko';

  @override
  String get lamp => 'Mga fluorescent na tubo';

  @override
  String get dryBatteryHint =>
      'Suriin ang uri at kondisyon ng baterya bago pumili ng lugar.';

  @override
  String get rechargeableHint =>
      'Huwag ilagay sa kahon para sa dry-cell na baterya. Tingnan ang paraang angkop sa uri at kondisyon nito.';

  @override
  String get applianceHint =>
      'Suriin ang mga tinatanggap, laki ng butas at patakaran para sa built-in na baterya.';

  @override
  String get lampHint =>
      'Magkaiba ang patakaran para sa basag na tubo at LED na bombilya. Tingnan ang opisyal na gabay.';

  @override
  String get food => 'Basurang pagkain';

  @override
  String get pet => 'Mga boteng PET';

  @override
  String get cans => 'Mga lata at boteng salamin';

  @override
  String get bulky => 'Muwebles at malalaking basura';

  @override
  String get foodGuidance =>
      'Halimbawa para sa nasusunog na basura: patuluin muna ang likido bago itapon.';

  @override
  String get recyclingGuidance =>
      'Halimbawa para sa nare-recycle: tingnan ang araw ng koleksyon at paraan ng paghahanda.';

  @override
  String get dryBatteryGuidance =>
      'Tingnan ang paraan ng koleksyon para sa uri ng baterya.';

  @override
  String get rechargeableGuidance =>
      'Nag-iiba ang patakaran ayon sa uri at kung namamaga o sira ang baterya.';

  @override
  String get applianceGuidance =>
      'Suriin ang limitasyon sa laki at patakaran para sa built-in na baterya.';

  @override
  String get lampGuidance =>
      'Tingnan nang magkahiwalay ang patakaran para sa fluorescent na tubo at LED na bombilya.';

  @override
  String get bulkyGuidance =>
      'Nakadepende sa sukat at uri ang patakaran para sa malalaking basura. Tingnan ang gabay sa mga bagay at pagpapareserba ng ward.';

  @override
  String collectionArea(String area) {
    return 'Lugar ng koleksyon: $area';
  }

  @override
  String get setupAreaTitle => 'Magtakda ng halimbawang lugar';

  @override
  String get confirmAreaTitle => 'Gamitin ang lugar na ito?';

  @override
  String candidateArea(String area) {
    return 'Lugar na ise-save: $area';
  }

  @override
  String currentArea(String area) {
    return 'Kasalukuyang setting: $area';
  }

  @override
  String get confirmAreaAction => 'I-save ang lugar na ito';

  @override
  String get chooseAgain => 'Pumili muli';

  @override
  String get savingArea => 'Sine-save…';

  @override
  String get setupRecovery =>
      'Hindi mabasa ang setting ng lugar. Mangyaring pumili muli.';

  @override
  String get cancel => 'Kanselahin';

  @override
  String collectionDeadline(String time) {
    return 'Ilabas bago mag-$time';
  }

  @override
  String itemDeadline(String item, String time) {
    return '$item: ilabas bago mag-$time';
  }

  @override
  String get chooseCollectionItem =>
      'Piliin ang uri ng bagay na dadalhin sa lugar ng koleksyon.';

  @override
  String backToItem(String item) {
    return 'Bumalik sa mga tagubilin para sa $item';
  }

  @override
  String get close => 'Isara';

  @override
  String get widgetLabel => 'Iskedyul ng basura';

  @override
  String get widgetSample => 'Halimbawa para sa pag-develop';

  @override
  String get widgetNext => 'Susunod na iskedyul';

  @override
  String get widgetOfferTitle =>
      'Ipakita ang iskedyul ng basura sa home screen';

  @override
  String get widgetOfferBody =>
      'Tingnan ang petsa at uri ng basura nang hindi binubuksan ang app.';

  @override
  String get widgetAdd => 'Idagdag';

  @override
  String get widgetSkip => 'Laktawan';

  @override
  String get widgetSettings => 'Widget sa home screen';

  @override
  String get widgetAdded => 'Naidagdag sa home screen';

  @override
  String get widgetRequested =>
      'Hiniling ang pagdagdag. Kumpirmahin sa dialog ng system.';

  @override
  String get widgetUnsupported =>
      'Pindutin nang matagal ang home screen, piliin ang Widgets, at idagdag ang Gomimap.';

  @override
  String get widgetFailure =>
      'Hindi nahiling ang pagdagdag. Subukan muli o idagdag mula sa home screen.';

  @override
  String get widgetSaveError => 'Hindi na-save ang pinili. Subukan muli.';

  @override
  String get disposalDeadlinePassed => 'Lumipas na ang oras ng pagtatapon';

  @override
  String get notifications => 'Mga paalala sa koleksiyon';

  @override
  String get notificationIntro => 'Magpaalala sa umagang may koleksiyon.';

  @override
  String get notificationEnabled => 'Paalala sa umaga';

  @override
  String get notificationEvening => 'Magpaalala rin sa gabi bago nito';

  @override
  String get notificationSave => 'I-save';

  @override
  String get notificationLater => 'Mamaya';

  @override
  String get notificationPermission =>
      'Hindi pinapayagan ang mga notification sa device';

  @override
  String get notificationOsSettings => 'Buksan ang mga setting ng notification';

  @override
  String get notificationNone =>
      'Walang araw ng koleksiyon na maaaring iiskedyul';

  @override
  String get notificationFixture =>
      'Hindi nag-iiskedyul ng halimbawang paalala ang normal na app';

  @override
  String notificationReserved(int count) {
    return 'Naka-iskedyul: $count';
  }

  @override
  String notificationPreview(int count) {
    return 'Orasan ng pagsubok: preview ng $count paalala';
  }

  @override
  String notificationNext(String when) {
    return 'Susunod na paalala: $when';
  }

  @override
  String get notificationError =>
      'Hindi na-save o na-apply. Suriin ang mga setting at paalala.';

  @override
  String get notificationRetry => 'Subukang muli';

  @override
  String get notificationTest => 'Ipakita ang test notification';

  @override
  String notificationMorningTitle(String date) {
    return 'Basura ngayong $date';
  }

  @override
  String notificationEveningTitle(String date) {
    return 'Paghahanda para bukas, $date';
  }

  @override
  String notificationTestTitle(String title) {
    return 'Pagsubok: $title';
  }

  @override
  String get notificationChangedArea =>
      'Para sa ibang lugar ang paalalang ito. Ipinapakita ang kasalukuyang lugar.';

  @override
  String get notificationUpdated =>
      'Nagbago ang iskedyul matapos ang paalalang ito.';

  @override
  String get notificationOfferTitle =>
      'Ipaalala sa akin ang mga araw ng koleksiyon';

  @override
  String get mapLoadError => 'Hindi ma-load ang mapa';

  @override
  String get mapRetry => 'Subukan muli';

  @override
  String get mapShowList => 'Tingnan ang listahan';

  @override
  String get addressChoose => 'Pumili ayon sa address';

  @override
  String get addressTown => 'Pangalan ng lugar';

  @override
  String get addressChome => 'Chome';

  @override
  String get addressBlock => 'Numero ng bloke';

  @override
  String get addressStreet => 'Tabi ba ng kathang-isip na kalye?';

  @override
  String get addressSelect => 'Pumili ng opsyon';

  @override
  String get addressYes => 'Oo';

  @override
  String get addressNo => 'Hindi';

  @override
  String get addressAlong => 'Tabi ng kalye';

  @override
  String get addressAway => 'Hindi tabi ng kalye';

  @override
  String get addressFictionalTown => 'Kathang-isip na lugar';

  @override
  String get addressFind => 'Suriin ang distritong ito';

  @override
  String get addressUnknown => 'Hindi sigurado';

  @override
  String get addressUnsupported => 'Walang nahanap na sinusuportahang distrito';

  @override
  String get addressConflict => 'Hindi matukoy ang iisang distrito';

  @override
  String get addressNeedsConfirmation => 'Kailangang kumpirmahin ang distrito';

  @override
  String get addressDataChanged =>
      'Nagbago ang impormasyon. Piliin muli ang distrito';
}
