import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fil.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fil'),
    Locale('ja'),
    Locale('ko'),
    Locale('ne'),
    Locale('pt'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ja, this message translates to:
  /// **'ごみまっぷ'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In ja, this message translates to:
  /// **'言語 / Language'**
  String get language;

  /// No description provided for @languageSaveError.
  ///
  /// In ja, this message translates to:
  /// **'言語を保存できませんでした。次回もう一度選んでください。'**
  String get languageSaveError;

  /// No description provided for @about.
  ///
  /// In ja, this message translates to:
  /// **'この試作について'**
  String get about;

  /// No description provided for @sampleBanner.
  ///
  /// In ja, this message translates to:
  /// **'開発用サンプル · 実際のごみ出しには使えません'**
  String get sampleBanner;

  /// No description provided for @today.
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In ja, this message translates to:
  /// **'明日'**
  String get tomorrow;

  /// No description provided for @searchTab.
  ///
  /// In ja, this message translates to:
  /// **'分別を調べる'**
  String get searchTab;

  /// No description provided for @placesTab.
  ///
  /// In ja, this message translates to:
  /// **'資源回収場所'**
  String get placesTab;

  /// No description provided for @chooseArea.
  ///
  /// In ja, this message translates to:
  /// **'地域を選ぶ'**
  String get chooseArea;

  /// No description provided for @fictionalAreas.
  ///
  /// In ja, this message translates to:
  /// **'操作確認用の架空の地域です。'**
  String get fictionalAreas;

  /// No description provided for @areaName.
  ///
  /// In ja, this message translates to:
  /// **'豊島区・サンプル地域{area}'**
  String areaName(String area);

  /// No description provided for @areaSaveError.
  ///
  /// In ja, this message translates to:
  /// **'保存できませんでした。設定は変更されていません。もう一度試してください。'**
  String get areaSaveError;

  /// No description provided for @sourceOpenError.
  ///
  /// In ja, this message translates to:
  /// **'公式ページを開けませんでした。\n{url}'**
  String sourceOpenError(String url);

  /// No description provided for @demoDate.
  ///
  /// In ja, this message translates to:
  /// **'{date}の表示例'**
  String demoDate(String date);

  /// No description provided for @upcoming.
  ///
  /// In ja, this message translates to:
  /// **'この先の予定'**
  String get upcoming;

  /// No description provided for @officialToshima.
  ///
  /// In ja, this message translates to:
  /// **'豊島区の公式情報を確認'**
  String get officialToshima;

  /// No description provided for @official.
  ///
  /// In ja, this message translates to:
  /// **'公式情報を確認'**
  String get official;

  /// No description provided for @checkTime.
  ///
  /// In ja, this message translates to:
  /// **'出し方・時間は公式情報で確認'**
  String get checkTime;

  /// No description provided for @noCollection.
  ///
  /// In ja, this message translates to:
  /// **'収集はありません'**
  String get noCollection;

  /// No description provided for @uncertain.
  ///
  /// In ja, this message translates to:
  /// **'収集予定の確認が必要'**
  String get uncertain;

  /// No description provided for @burnable.
  ///
  /// In ja, this message translates to:
  /// **'燃やすごみ'**
  String get burnable;

  /// No description provided for @recyclables.
  ///
  /// In ja, this message translates to:
  /// **'資源'**
  String get recyclables;

  /// No description provided for @metals.
  ///
  /// In ja, this message translates to:
  /// **'金属・陶器・ガラス'**
  String get metals;

  /// No description provided for @searchTitle.
  ///
  /// In ja, this message translates to:
  /// **'これは、何ごみ？'**
  String get searchTitle;

  /// No description provided for @searchSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'品物の名前から出し方を調べます。'**
  String get searchSubtitle;

  /// No description provided for @itemName.
  ///
  /// In ja, this message translates to:
  /// **'品物の名前'**
  String get itemName;

  /// No description provided for @searchHint.
  ///
  /// In ja, this message translates to:
  /// **'例：電池、ペットボトル'**
  String get searchHint;

  /// No description provided for @noResults.
  ///
  /// In ja, this message translates to:
  /// **'見つかりませんでした。別の名前で試すか、公式情報で確認してください。'**
  String get noResults;

  /// No description provided for @disposal.
  ///
  /// In ja, this message translates to:
  /// **'出し方を確認'**
  String get disposal;

  /// No description provided for @disposalAndPlaces.
  ///
  /// In ja, this message translates to:
  /// **'出し方・専用の回収場所'**
  String get disposalAndPlaces;

  /// No description provided for @sampleSorting.
  ///
  /// In ja, this message translates to:
  /// **'開発用サンプルの分別案内'**
  String get sampleSorting;

  /// No description provided for @findPlaces.
  ///
  /// In ja, this message translates to:
  /// **'専用の回収場所を探す'**
  String get findPlaces;

  /// No description provided for @officialDisposal.
  ///
  /// In ja, this message translates to:
  /// **'公式の出し方を確認'**
  String get officialDisposal;

  /// No description provided for @placesSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'電池・小型家電・蛍光灯などの持ち込み先。\n普段のごみは「今日」で確認できます。'**
  String get placesSubtitle;

  /// No description provided for @damageQuestion.
  ///
  /// In ja, this message translates to:
  /// **'膨らみ・破損がありますか？'**
  String get damageQuestion;

  /// No description provided for @noDamage.
  ///
  /// In ja, this message translates to:
  /// **'ない'**
  String get noDamage;

  /// No description provided for @damagedOrUnknown.
  ///
  /// In ja, this message translates to:
  /// **'ある・わからない'**
  String get damagedOrUnknown;

  /// No description provided for @damageWarning.
  ///
  /// In ja, this message translates to:
  /// **'通常の回収箱へは案内しません。状態を確かめ、区の公式情報から相談先を確認してください。'**
  String get damageWarning;

  /// No description provided for @officialBattery.
  ///
  /// In ja, this message translates to:
  /// **'公式の回収方法・相談先を確認'**
  String get officialBattery;

  /// No description provided for @placesCount.
  ///
  /// In ja, this message translates to:
  /// **'回収場所の一覧（サンプル {count}件）'**
  String placesCount(int count);

  /// No description provided for @fictionalPoints.
  ///
  /// In ja, this message translates to:
  /// **'架空の拠点です。訪問先として利用できません。'**
  String get fictionalPoints;

  /// No description provided for @noPoints.
  ///
  /// In ja, this message translates to:
  /// **'この品目の確認済み回収場所はまだありません。区の公式案内を確認してください。'**
  String get noPoints;

  /// No description provided for @conditions.
  ///
  /// In ja, this message translates to:
  /// **'受付条件を確認する'**
  String get conditions;

  /// No description provided for @samplePoint.
  ///
  /// In ja, this message translates to:
  /// **'サンプル回収拠点{point}'**
  String samplePoint(String point);

  /// No description provided for @samplePointDetail.
  ///
  /// In ja, this message translates to:
  /// **'開発用の架空の回収場所'**
  String get samplePointDetail;

  /// No description provided for @acceptedItems.
  ///
  /// In ja, this message translates to:
  /// **'対象品目の例：{items}'**
  String acceptedItems(String items);

  /// No description provided for @pointConditions.
  ///
  /// In ja, this message translates to:
  /// **'受付時間・利用条件：未登録\n実際の持ち込み先ではありません。経路案内は提供していません。'**
  String get pointConditions;

  /// No description provided for @mapTitle.
  ///
  /// In ja, this message translates to:
  /// **'ここに回収場所の地図を表示'**
  String get mapTitle;

  /// No description provided for @mapUnavailable.
  ///
  /// In ja, this message translates to:
  /// **'地図はまだ接続していません。\n下の一覧で画面の動きを試せます。'**
  String get mapUnavailable;

  /// No description provided for @aboutBody.
  ///
  /// In ja, this message translates to:
  /// **'架空の日程・地域・回収場所を使う開発用サンプルです。実際のごみ出しには使えません。\n\n地区・言語・通知の設定は端末に保存します。写真や位置情報は取得しません。'**
  String get aboutBody;

  /// No description provided for @dryBattery.
  ///
  /// In ja, this message translates to:
  /// **'乾電池'**
  String get dryBattery;

  /// No description provided for @rechargeable.
  ///
  /// In ja, this message translates to:
  /// **'充電池'**
  String get rechargeable;

  /// No description provided for @appliance.
  ///
  /// In ja, this message translates to:
  /// **'小型家電'**
  String get appliance;

  /// No description provided for @lamp.
  ///
  /// In ja, this message translates to:
  /// **'蛍光灯'**
  String get lamp;

  /// No description provided for @dryBatteryHint.
  ///
  /// In ja, this message translates to:
  /// **'電池の種類と状態を確かめてから、回収場所を選びます。'**
  String get dryBatteryHint;

  /// No description provided for @rechargeableHint.
  ///
  /// In ja, this message translates to:
  /// **'乾電池の回収箱には入れず、種類・状態に合う方法を確認します。'**
  String get rechargeableHint;

  /// No description provided for @applianceHint.
  ///
  /// In ja, this message translates to:
  /// **'対象品目や投入口の大きさ、取り外せない電池の扱いを確認します。'**
  String get applianceHint;

  /// No description provided for @lampHint.
  ///
  /// In ja, this message translates to:
  /// **'割れているものやLED電球は扱いが異なるため、公式案内で確認します。'**
  String get lampHint;

  /// No description provided for @food.
  ///
  /// In ja, this message translates to:
  /// **'生ごみ'**
  String get food;

  /// No description provided for @pet.
  ///
  /// In ja, this message translates to:
  /// **'ペットボトル'**
  String get pet;

  /// No description provided for @cans.
  ///
  /// In ja, this message translates to:
  /// **'缶・びん'**
  String get cans;

  /// No description provided for @bulky.
  ///
  /// In ja, this message translates to:
  /// **'家具・大きなごみ'**
  String get bulky;

  /// No description provided for @foodGuidance.
  ///
  /// In ja, this message translates to:
  /// **'燃やすごみの表示例です。水を切って出します。'**
  String get foodGuidance;

  /// No description provided for @recyclingGuidance.
  ///
  /// In ja, this message translates to:
  /// **'資源の表示例です。通常の収集日と出し方を確認します。'**
  String get recyclingGuidance;

  /// No description provided for @dryBatteryGuidance.
  ///
  /// In ja, this message translates to:
  /// **'電池の種類に応じて回収方法を確認します。'**
  String get dryBatteryGuidance;

  /// No description provided for @rechargeableGuidance.
  ///
  /// In ja, this message translates to:
  /// **'種類や膨張・破損の有無によって扱いが異なります。'**
  String get rechargeableGuidance;

  /// No description provided for @applianceGuidance.
  ///
  /// In ja, this message translates to:
  /// **'大きさや内蔵電池の扱いを確認します。'**
  String get applianceGuidance;

  /// No description provided for @lampGuidance.
  ///
  /// In ja, this message translates to:
  /// **'蛍光灯とLED電球は分けて確認します。'**
  String get lampGuidance;

  /// No description provided for @bulkyGuidance.
  ///
  /// In ja, this message translates to:
  /// **'寸法や品目によって粗大ごみの扱いが変わります。区の品目案内・申込先を確認してください。'**
  String get bulkyGuidance;

  /// No description provided for @collectionArea.
  ///
  /// In ja, this message translates to:
  /// **'収集地区：{area}'**
  String collectionArea(String area);

  /// No description provided for @setupAreaTitle.
  ///
  /// In ja, this message translates to:
  /// **'サンプル地区を設定'**
  String get setupAreaTitle;

  /// No description provided for @confirmAreaTitle.
  ///
  /// In ja, this message translates to:
  /// **'この地区でよいですか？'**
  String get confirmAreaTitle;

  /// No description provided for @candidateArea.
  ///
  /// In ja, this message translates to:
  /// **'設定する地区：{area}'**
  String candidateArea(String area);

  /// No description provided for @currentArea.
  ///
  /// In ja, this message translates to:
  /// **'現在の設定：{area}'**
  String currentArea(String area);

  /// No description provided for @confirmAreaAction.
  ///
  /// In ja, this message translates to:
  /// **'この地区で設定'**
  String get confirmAreaAction;

  /// No description provided for @chooseAgain.
  ///
  /// In ja, this message translates to:
  /// **'選び直す'**
  String get chooseAgain;

  /// No description provided for @savingArea.
  ///
  /// In ja, this message translates to:
  /// **'保存しています…'**
  String get savingArea;

  /// No description provided for @setupRecovery.
  ///
  /// In ja, this message translates to:
  /// **'地区の設定を読み込めませんでした。地区を選び直してください。'**
  String get setupRecovery;

  /// No description provided for @cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// No description provided for @collectionDeadline.
  ///
  /// In ja, this message translates to:
  /// **'出す時間：{time}まで'**
  String collectionDeadline(String time);

  /// No description provided for @itemDeadline.
  ///
  /// In ja, this message translates to:
  /// **'{item}：{time}まで'**
  String itemDeadline(String item, String time);

  /// No description provided for @chooseCollectionItem.
  ///
  /// In ja, this message translates to:
  /// **'持ち込む品物の種類を選んでください。'**
  String get chooseCollectionItem;

  /// No description provided for @backToItem.
  ///
  /// In ja, this message translates to:
  /// **'「{item}」の説明に戻る'**
  String backToItem(String item);

  /// No description provided for @close.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get close;

  /// No description provided for @widgetLabel.
  ///
  /// In ja, this message translates to:
  /// **'ごみの予定'**
  String get widgetLabel;

  /// No description provided for @widgetSample.
  ///
  /// In ja, this message translates to:
  /// **'開発用サンプル'**
  String get widgetSample;

  /// No description provided for @widgetNext.
  ///
  /// In ja, this message translates to:
  /// **'次回'**
  String get widgetNext;

  /// No description provided for @widgetOfferTitle.
  ///
  /// In ja, this message translates to:
  /// **'ごみの予定をホーム画面に表示'**
  String get widgetOfferTitle;

  /// No description provided for @widgetOfferBody.
  ///
  /// In ja, this message translates to:
  /// **'アプリを開かず、日付とごみの種類を確認できます。'**
  String get widgetOfferBody;

  /// No description provided for @widgetAdd.
  ///
  /// In ja, this message translates to:
  /// **'追加する'**
  String get widgetAdd;

  /// No description provided for @widgetSkip.
  ///
  /// In ja, this message translates to:
  /// **'スキップ'**
  String get widgetSkip;

  /// No description provided for @widgetSettings.
  ///
  /// In ja, this message translates to:
  /// **'ホーム画面ウィジェット'**
  String get widgetSettings;

  /// No description provided for @widgetAdded.
  ///
  /// In ja, this message translates to:
  /// **'ホーム画面に追加されています'**
  String get widgetAdded;

  /// No description provided for @widgetRequested.
  ///
  /// In ja, this message translates to:
  /// **'追加を要求しました。OSの確認で追加してください。'**
  String get widgetRequested;

  /// No description provided for @widgetUnsupported.
  ///
  /// In ja, this message translates to:
  /// **'ホーム画面を長押しし、「ウィジェット」から「ごみまっぷ」を追加できます。'**
  String get widgetUnsupported;

  /// No description provided for @widgetFailure.
  ///
  /// In ja, this message translates to:
  /// **'追加要求ができませんでした。もう一度試すか、ホーム画面から追加してください。'**
  String get widgetFailure;

  /// No description provided for @widgetSaveError.
  ///
  /// In ja, this message translates to:
  /// **'選択を保存できませんでした。もう一度試してください。'**
  String get widgetSaveError;

  /// No description provided for @disposalDeadlinePassed.
  ///
  /// In ja, this message translates to:
  /// **'ごみ出しの締切を過ぎています'**
  String get disposalDeadlinePassed;

  /// No description provided for @notifications.
  ///
  /// In ja, this message translates to:
  /// **'ごみの日の通知'**
  String get notifications;

  /// No description provided for @notificationIntro.
  ///
  /// In ja, this message translates to:
  /// **'収集がある朝に通知します。'**
  String get notificationIntro;

  /// No description provided for @notificationEnabled.
  ///
  /// In ja, this message translates to:
  /// **'朝の通知'**
  String get notificationEnabled;

  /// No description provided for @notificationEvening.
  ///
  /// In ja, this message translates to:
  /// **'前夜にも通知'**
  String get notificationEvening;

  /// No description provided for @notificationSave.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get notificationSave;

  /// No description provided for @notificationLater.
  ///
  /// In ja, this message translates to:
  /// **'あとで'**
  String get notificationLater;

  /// No description provided for @notificationPermission.
  ///
  /// In ja, this message translates to:
  /// **'端末で通知が許可されていません'**
  String get notificationPermission;

  /// No description provided for @notificationOsSettings.
  ///
  /// In ja, this message translates to:
  /// **'端末の通知設定を開く'**
  String get notificationOsSettings;

  /// No description provided for @notificationNone.
  ///
  /// In ja, this message translates to:
  /// **'予約できる収集予定がありません'**
  String get notificationNone;

  /// No description provided for @notificationFixture.
  ///
  /// In ja, this message translates to:
  /// **'通常版ではサンプルの通知を予約しません'**
  String get notificationFixture;

  /// No description provided for @notificationReserved.
  ///
  /// In ja, this message translates to:
  /// **'予約済み：{count}件'**
  String notificationReserved(int count);

  /// No description provided for @notificationPreview.
  ///
  /// In ja, this message translates to:
  /// **'試験時計：予約プレビュー{count}件'**
  String notificationPreview(int count);

  /// No description provided for @notificationNext.
  ///
  /// In ja, this message translates to:
  /// **'次の予定：{when}'**
  String notificationNext(String when);

  /// No description provided for @notificationError.
  ///
  /// In ja, this message translates to:
  /// **'保存または反映に失敗しました。設定と予約状況を確認してください。'**
  String get notificationError;

  /// No description provided for @notificationRetry.
  ///
  /// In ja, this message translates to:
  /// **'再試行'**
  String get notificationRetry;

  /// No description provided for @notificationTest.
  ///
  /// In ja, this message translates to:
  /// **'テスト通知を表示'**
  String get notificationTest;

  /// No description provided for @notificationMorningTitle.
  ///
  /// In ja, this message translates to:
  /// **'今日{date}のごみ'**
  String notificationMorningTitle(String date);

  /// No description provided for @notificationEveningTitle.
  ///
  /// In ja, this message translates to:
  /// **'明日{date}の準備'**
  String notificationEveningTitle(String date);

  /// No description provided for @notificationTestTitle.
  ///
  /// In ja, this message translates to:
  /// **'テスト：{title}'**
  String notificationTestTitle(String title);

  /// No description provided for @notificationChangedArea.
  ///
  /// In ja, this message translates to:
  /// **'別の収集地区の通知です。現在の地区を表示します。'**
  String get notificationChangedArea;

  /// No description provided for @notificationUpdated.
  ///
  /// In ja, this message translates to:
  /// **'通知後に予定が更新されています。'**
  String get notificationUpdated;

  /// No description provided for @notificationOfferTitle.
  ///
  /// In ja, this message translates to:
  /// **'ごみの日を通知'**
  String get notificationOfferTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'es',
    'fil',
    'ja',
    'ko',
    'ne',
    'pt',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fil':
      return AppLocalizationsFil();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'ne':
      return AppLocalizationsNe();
    case 'pt':
      return AppLocalizationsPt();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
