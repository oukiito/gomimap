// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ごみまっぷ';

  @override
  String get language => '言語 / Language';

  @override
  String get languageSaveError => '言語を保存できませんでした。次回もう一度選んでください。';

  @override
  String get about => 'この試作について';

  @override
  String get sampleBanner => '開発用サンプル · 実際のごみ出しには使えません';

  @override
  String get today => '今日';

  @override
  String get tomorrow => '明日';

  @override
  String get searchTab => '分別を調べる';

  @override
  String get placesTab => '資源回収場所';

  @override
  String get chooseArea => '地域を選ぶ';

  @override
  String get fictionalAreas => '操作確認用の架空の地域です。';

  @override
  String areaName(String area) {
    return '豊島区・サンプル地域$area';
  }

  @override
  String get areaSaveError => '保存できませんでした。設定は変更されていません。もう一度試してください。';

  @override
  String sourceOpenError(String url) {
    return '公式ページを開けませんでした。\n$url';
  }

  @override
  String demoDate(String date) {
    return '$dateの表示例';
  }

  @override
  String get upcoming => 'この先の予定';

  @override
  String get officialToshima => '豊島区の公式情報を確認';

  @override
  String get official => '公式情報を確認';

  @override
  String get checkTime => '出し方・時間は公式情報で確認';

  @override
  String get noCollection => '収集はありません';

  @override
  String get uncertain => '収集予定の確認が必要';

  @override
  String get burnable => '燃やすごみ';

  @override
  String get recyclables => '資源';

  @override
  String get metals => '金属・陶器・ガラス';

  @override
  String get searchTitle => 'これは、何ごみ？';

  @override
  String get searchSubtitle => '品物の名前から出し方を調べます。';

  @override
  String get itemName => '品物の名前';

  @override
  String get searchHint => '例：電池、ペットボトル';

  @override
  String get noResults => '見つかりませんでした。別の名前で試すか、公式情報で確認してください。';

  @override
  String get disposal => '出し方を確認';

  @override
  String get disposalAndPlaces => '出し方・専用の回収場所';

  @override
  String get sampleSorting => '開発用サンプルの分別案内';

  @override
  String get findPlaces => '専用の回収場所を探す';

  @override
  String get officialDisposal => '公式の出し方を確認';

  @override
  String get placesSubtitle => '電池・小型家電・蛍光灯などの持ち込み先。\n普段のごみは「今日」で確認できます。';

  @override
  String get damageQuestion => '膨らみ・破損がありますか？';

  @override
  String get noDamage => 'ない';

  @override
  String get damagedOrUnknown => 'ある・わからない';

  @override
  String get damageWarning => '通常の回収箱へは案内しません。状態を確かめ、区の公式情報から相談先を確認してください。';

  @override
  String get officialBattery => '公式の回収方法・相談先を確認';

  @override
  String placesCount(int count) {
    return '回収場所の一覧（サンプル $count件）';
  }

  @override
  String get fictionalPoints => '架空の拠点です。訪問先として利用できません。';

  @override
  String get noPoints => 'この品目の確認済み回収場所はまだありません。区の公式案内を確認してください。';

  @override
  String get conditions => '受付条件を確認する';

  @override
  String samplePoint(String point) {
    return 'サンプル回収拠点$point';
  }

  @override
  String get samplePointDetail => '開発用の架空の回収場所';

  @override
  String acceptedItems(String items) {
    return '対象品目の例：$items';
  }

  @override
  String get pointConditions => '受付時間・利用条件：未登録\n実際の持ち込み先ではありません。経路案内は提供していません。';

  @override
  String get mapTitle => 'ここに回収場所の地図を表示';

  @override
  String get mapUnavailable => '地図はまだ接続していません。\n下の一覧で画面の動きを試せます。';

  @override
  String get aboutBody =>
      '2026年10月5日を基準にした架空の日程・地域・回収場所です。実際のごみ出しには使えません。\n\n通知・ウィジェット・位置情報の設定は、今後追加します。この試作から通知は届きません。\n\n保存するのは選んだサンプル地域と言語のみ。写真や位置情報は取得しません。';

  @override
  String get dryBattery => '乾電池';

  @override
  String get rechargeable => '充電池';

  @override
  String get appliance => '小型家電';

  @override
  String get lamp => '蛍光灯';

  @override
  String get dryBatteryHint => '電池の種類と状態を確かめてから、回収場所を選びます。';

  @override
  String get rechargeableHint => '乾電池の回収箱には入れず、種類・状態に合う方法を確認します。';

  @override
  String get applianceHint => '対象品目や投入口の大きさ、取り外せない電池の扱いを確認します。';

  @override
  String get lampHint => '割れているものやLED電球は扱いが異なるため、公式案内で確認します。';

  @override
  String get food => '生ごみ';

  @override
  String get pet => 'ペットボトル';

  @override
  String get cans => '缶・びん';

  @override
  String get bulky => '家具・大きなごみ';

  @override
  String get foodGuidance => '燃やすごみの表示例です。水を切って出します。';

  @override
  String get recyclingGuidance => '資源の表示例です。通常の収集日と出し方を確認します。';

  @override
  String get dryBatteryGuidance => '電池の種類に応じて回収方法を確認します。';

  @override
  String get rechargeableGuidance => '種類や膨張・破損の有無によって扱いが異なります。';

  @override
  String get applianceGuidance => '大きさや内蔵電池の扱いを確認します。';

  @override
  String get lampGuidance => '蛍光灯とLED電球は分けて確認します。';

  @override
  String get bulkyGuidance => '寸法や品目によって粗大ごみの扱いが変わります。区の品目案内・申込先を確認してください。';

  @override
  String collectionArea(String area) {
    return '収集地区：$area';
  }

  @override
  String get setupAreaTitle => 'サンプル地区を設定';

  @override
  String get confirmAreaTitle => 'この地区でよいですか？';

  @override
  String candidateArea(String area) {
    return '設定する地区：$area';
  }

  @override
  String currentArea(String area) {
    return '現在の設定：$area';
  }

  @override
  String get confirmAreaAction => 'この地区で設定';

  @override
  String get chooseAgain => '選び直す';

  @override
  String get savingArea => '保存しています…';

  @override
  String get setupRecovery => '地区の設定を読み込めませんでした。地区を選び直してください。';

  @override
  String get cancel => 'キャンセル';

  @override
  String collectionDeadline(String time) {
    return '出す時間：$timeまで';
  }

  @override
  String itemDeadline(String item, String time) {
    return '$item：$timeまで';
  }

  @override
  String get chooseCollectionItem => '持ち込む品物の種類を選んでください。';

  @override
  String backToItem(String item) {
    return '「$item」の説明に戻る';
  }

  @override
  String get close => '閉じる';

  @override
  String get widgetLabel => '今日のごみ';

  @override
  String get widgetSample => '開発用サンプル';

  @override
  String get widgetNext => '次回';

  @override
  String get widgetOfferTitle => '今日のごみをホーム画面に表示';

  @override
  String get widgetOfferBody => 'アプリを開かず、日付とごみの種類を確認できます。';

  @override
  String get widgetAdd => '追加する';

  @override
  String get widgetSkip => 'スキップ';

  @override
  String get widgetSettings => 'ホーム画面ウィジェット';

  @override
  String get widgetAdded => 'ホーム画面に追加されています';

  @override
  String get widgetRequested => '追加を要求しました。OSの確認で追加してください。';

  @override
  String get widgetUnsupported => 'ホーム画面を長押しし、「ウィジェット」から「ごみまっぷ」を追加できます。';

  @override
  String get widgetFailure => '追加要求ができませんでした。もう一度試すか、ホーム画面から追加してください。';

  @override
  String get widgetSaveError => '選択を保存できませんでした。もう一度試してください。';

  @override
  String get disposalDeadlinePassed => 'ごみ出しの締切を過ぎています';
}
