// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get appTitle => 'Gomimap';

  @override
  String get language => 'भाषा / Language';

  @override
  String get languageSaveError =>
      'भाषा सुरक्षित गर्न सकिएन। अर्को पटक फेरि छान्नुहोस्।';

  @override
  String get about => 'यस नमुनाबारे';

  @override
  String get sampleBanner =>
      'नमुना डेटा · वास्तविक फोहोर फाल्न प्रयोग नगर्नुहोस्';

  @override
  String get today => 'आज';

  @override
  String get tomorrow => 'भोलि';

  @override
  String get searchTab => 'वर्गीकरण';

  @override
  String get placesTab => 'पुनर्चक्रण स्थल';

  @override
  String get chooseArea => 'क्षेत्र छान्नुहोस्';

  @override
  String get fictionalAreas => 'यी परीक्षणका लागि काल्पनिक क्षेत्रहरू हुन्।';

  @override
  String areaName(String area) {
    return 'तोशिमा · नमुना क्षेत्र $area';
  }

  @override
  String get areaSaveError =>
      'क्षेत्र सुरक्षित गर्न सकिएन। अर्को पटक फेरि छान्नुहोस्।';

  @override
  String sourceOpenError(String url) {
    return 'आधिकारिक पृष्ठ खोल्न सकिएन।\n$url';
  }

  @override
  String demoDate(String date) {
    return '$date को नमुना';
  }

  @override
  String get upcoming => 'आगामी सङ्कलन तालिका';

  @override
  String get officialToshima => 'तोशिमाको आधिकारिक जानकारी (जापानी)';

  @override
  String get official => 'आधिकारिक जानकारी (जापानी)';

  @override
  String get checkTime => 'फाल्ने तरिका र समय आधिकारिक जानकारीमा हेर्नुहोस्';

  @override
  String get noCollection => 'सङ्कलन हुँदैन';

  @override
  String get uncertain => 'सङ्कलन तालिका पुष्टि गर्नुपर्छ';

  @override
  String get burnable => 'जलाउन मिल्ने फोहोर';

  @override
  String get recyclables => 'पुनर्चक्रणयोग्य वस्तु';

  @override
  String get metals => 'धातु, माटाका भाँडा र सिसा';

  @override
  String get searchTitle => 'यो कसरी फाल्ने?';

  @override
  String get searchSubtitle => 'वस्तुको नामबाट खोज्नुहोस्।';

  @override
  String get itemName => 'वस्तुको नाम';

  @override
  String get searchHint => 'जस्तै: ब्याट्री, प्लास्टिकको बोतल';

  @override
  String get noResults =>
      'फेला परेन। अर्को नामले खोज्नुहोस् वा आधिकारिक जानकारी हेर्नुहोस्।';

  @override
  String get disposal => 'फाल्ने तरिका';

  @override
  String get disposalAndPlaces => 'फाल्ने तरिका र सङ्कलन स्थल';

  @override
  String get sampleSorting => 'वर्गीकरणको नमुना निर्देशन';

  @override
  String get findPlaces => 'सङ्कलन स्थल खोज्नुहोस्';

  @override
  String get officialDisposal => 'फाल्ने आधिकारिक तरिका (जापानी)';

  @override
  String get placesSubtitle =>
      'ब्याट्री, साना विद्युतीय उपकरण र फ्लोरोसेन्ट बत्ती बुझाउने स्थल।\nसामान्य फोहोरका लागि ‘आज’ हेर्नुहोस्।';

  @override
  String get damageQuestion => 'फुलेको वा बिग्रिएको छ?';

  @override
  String get noDamage => 'छैन';

  @override
  String get damagedOrUnknown => 'छ / थाहा छैन';

  @override
  String get damageWarning =>
      'सामान्य सङ्कलन बाकसमा नराख्नुहोस्। अवस्था जाँचेर सम्पर्क स्थानका लागि वडाको आधिकारिक निर्देशन हेर्नुहोस्।';

  @override
  String get officialBattery => 'ब्याट्री सङ्कलन निर्देशन र सम्पर्क (जापानी)';

  @override
  String placesCount(int count) {
    return 'नमुना सङ्कलन स्थल ($count)';
  }

  @override
  String get fictionalPoints => 'यी स्थल काल्पनिक हुन्। यहाँ नजानुहोस्।';

  @override
  String get noPoints =>
      'यस वस्तुका लागि पुष्टि भएको सङ्कलन स्थल अझै छैन। वडाको आधिकारिक निर्देशन हेर्नुहोस्।';

  @override
  String get conditions => 'स्वीकार गर्ने सर्त हेर्नुहोस्';

  @override
  String samplePoint(String point) {
    return 'नमुना सङ्कलन स्थल $point';
  }

  @override
  String get samplePointDetail => 'परीक्षणका लागि काल्पनिक सङ्कलन स्थल';

  @override
  String acceptedItems(String items) {
    return 'स्वीकार गरिने वस्तुका उदाहरण: $items';
  }

  @override
  String get pointConditions =>
      'स्वीकार गर्ने समय र सर्त: दर्ता गरिएको छैन।\nयो वास्तविक बुझाउने स्थल होइन। बाटोको निर्देशन उपलब्ध छैन।';

  @override
  String get mapTitle => 'सङ्कलन स्थलको नक्सा';

  @override
  String get mapUnavailable =>
      'नक्सा अझै जोडिएको छैन।\nतलको सूचीबाट नमुना प्रयोग गर्न सक्नुहुन्छ।';

  @override
  String get aboutBody =>
      'तालिका, क्षेत्र र सङ्कलन स्थल काल्पनिक हुन् र २०२६ अक्टोबर ५ मा आधारित छन्। वास्तविक फोहोर फाल्न प्रयोग नगर्नुहोस्।\n\nसूचना, विजेट र स्थानसम्बन्धी सेटिङ अझै बनेका छैनन्। यो नमुनाले सूचना पठाउँदैन।\n\nछानिएको नमुना क्षेत्र र भाषा मात्र सुरक्षित गरिन्छ। फोटो वा स्थानको जानकारी सङ्कलन गरिँदैन।';

  @override
  String get dryBattery => 'सुक्खा ब्याट्री';

  @override
  String get rechargeable => 'रिचार्जेबल ब्याट्री';

  @override
  String get appliance => 'साना विद्युतीय उपकरण';

  @override
  String get lamp => 'फ्लोरोसेन्ट बत्ती';

  @override
  String get dryBatteryHint =>
      'सङ्कलन स्थल छान्नुअघि ब्याट्रीको प्रकार र अवस्था जाँच्नुहोस्।';

  @override
  String get rechargeableHint =>
      'सुक्खा ब्याट्रीको सङ्कलन बाकसमा नराख्नुहोस्। प्रकार र अवस्थाअनुसारको तरिका हेर्नुहोस्।';

  @override
  String get applianceHint =>
      'स्वीकार गरिने वस्तु, बाकसको प्वालको आकार र भित्र जडित ब्याट्रीको नियम जाँच्नुहोस्।';

  @override
  String get lampHint =>
      'फुटेको बत्ती र LED बल्बको नियम फरक हुन्छ। आधिकारिक निर्देशन हेर्नुहोस्।';

  @override
  String get food => 'खानेकुराको फोहोर';

  @override
  String get pet => 'PET बोतल';

  @override
  String get cans => 'क्यान र सिसाका बोतल';

  @override
  String get bulky => 'फर्निचर र ठूला फोहोर';

  @override
  String get foodGuidance =>
      'जलाउन मिल्ने फोहोरको नमुना निर्देशन: फाल्नुअघि पानी तर्काउनुहोस्।';

  @override
  String get recyclingGuidance =>
      'पुनर्चक्रणको नमुना निर्देशन: नियमित सङ्कलन दिन र तयारीको तरिका जाँच्नुहोस्।';

  @override
  String get dryBatteryGuidance =>
      'ब्याट्रीको प्रकारअनुसार सङ्कलन तरिका जाँच्नुहोस्।';

  @override
  String get rechargeableGuidance =>
      'ब्याट्रीको प्रकार र फुलेको वा बिग्रिएको अवस्थाअनुसार नियम फरक हुन्छ।';

  @override
  String get applianceGuidance =>
      'आकारको सीमा र भित्र जडित ब्याट्रीको नियम जाँच्नुहोस्।';

  @override
  String get lampGuidance =>
      'फ्लोरोसेन्ट बत्ती र LED बल्बको नियम छुट्टाछुट्टै जाँच्नुहोस्।';

  @override
  String get bulkyGuidance =>
      'ठूला फोहोरका नियम आकार र वस्तुको प्रकारअनुसार फरक हुन्छन्। वडाको वस्तु सूची र बुकिङ जानकारी हेर्नुहोस्।';

  @override
  String collectionArea(String area) {
    return 'फोहोर सङ्कलन क्षेत्र: $area';
  }
}
