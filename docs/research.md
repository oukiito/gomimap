# 調査資料・根拠・未確認事項

整理日：2026-10-05（Asia/Tokyo）。会話中に確認した一次情報の索引。URL先の更新日、こちらの取得日、制度の適用日は別物である。実装・公開時には対象ページを再取得し、原文と有効期間を確認する。

本書は自治体資料の転載集ではない。短い要約と根拠へのリンクを置く。ここにURLがあることは、そのデータをGPLで再配布できることを意味しない。

2026-10-06にG02として豊島区の資料を再確認した。現在の取得先・ページ更新日・保管と再配布の区別は[出典登録簿](sources/toshima.md)を参照。本書の初期調査で使った収集曜日PDFとは別のファイルが現在の公式案内からリンクされているため、実装時は登録簿の取得先を使う。

## 豊島区

| ID | 一次資料 | 設計に関係する確認事項 |
| --- | --- | --- |
| T01 | [資源の分け方・出し方](https://www.city.toshima.lg.jp/150/kurashi/gomi/shigen/009426.html)／[収集曜日PDF](https://www.city.toshima.lg.jp/documents/15278/youbiitiran.pdf) | 週単位・月内曜日の収集ルール、住所条件、地域ごとの締切。PDFは表の結合セル・多言語列の誤抽出に注意 |
| T02 | [収集カレンダー](https://www.city.toshima.lg.jp/150/kurashi/gomi/shigen/2303021832.html) | 区のカレンダー案内は「さんあ〜る」Web版へリンク。区の公式APIが存在することを示すものではない |
| T03 | [年末年始の収集](https://www.city.toshima.lg.jp/150/kurashi/gomi/shigen/2211020850.html) | 確認できた案内は2025–26年向け。次の年末年始へ流用しない |
| T04 | [小型充電式電池の収集](https://www.city.toshima.lg.jp/151/2601221355.html) | 2026年4月からの制度変更。通常の電池と膨張品、内蔵品などで案内が異なる |
| T05 | [乾電池・ボタン電池](https://www.city.toshima.lg.jp/150/kurashi/gomi/shigen/2509251342.html) | 2026年8月からボタン電池も箱回収。充電池は同じ箱の対象外。施設の休止や仮施設の記載あり |
| T06 | [小型家電](https://www.city.toshima.lg.jp/150/kurashi/gomi/shigen/034106.html) | ボックスの投入口、品目、電池、施設ごとの受付・休止を保持する必要がある |
| T07 | [粗大ごみ](https://www.city.toshima.lg.jp/150/kurashi/gomi/shigen/009383.html) | 一辺30cm超の条件と、家電等の除外。事前申込への導線が必要 |
| T08 | [転入者向け案内](https://www.city.toshima.lg.jp/150/2405231347.html) | 利用する家庭用集積所は大家・不動産会社等への確認が必要。公開持込拠点と混同しない |
| T09 | [荒天時の収集](https://www.city.toshima.lg.jp/151/2101281555.html) | 通常予定と別に臨時情報が必要。定期確認だけで即時反映を保証できない |
| T10 | [さんあ〜るの案内](https://www.city.toshima.lg.jp/150/2307040915.html) | 地域の既存サービスには予定・通知・分別検索等がある。利用者テストの比較対象にできる |

初期調査では、豊島区の収集予定のCSV／公開API、および対象資料に一律に適用される再利用ライセンスは確認できなかった。G02で公共施設CSV等の対象限定のCC BY 2.1 JPを確認したが、収集曜日や回収条件のHTML・PDFへは適用しない。詳しい対象範囲と未確認事項は[出典登録簿](sources/toshima.md)に記録する。

## 全国対応・既存サービスを考える資料

| ID | 一次資料 | 示唆 |
| --- | --- | --- |
| N01 | [新宿区の収集日](https://www.city.shinjuku.lg.jp/seikatsu/file09_01_00001.html) | 番地の一部まで区域が分かれる。市区町村だけの設定では不足 |
| N02 | [八王子市の粗大ごみの定義](https://www.city.hachioji.tokyo.jp/question/010/p034192.html) | 重量・指定袋による条件。全国共通の寸法基準にはできない |
| N03 | [世田谷区の収集日一覧](https://www.city.setagaya.lg.jp/02241/416.html) | CSVと対象添付ファイルへのCC BY 4.0の案内。ページ全体のライセンスとは区別する |
| N04 | [JBRC検索・対象条件](https://www.jbrc.com/general/recycle_kensaku/) | メーカー・電池状態等の条件がある。任意の家電量販店へ無条件に誘導しない |
| C01 | [さんあ〜る製品公式](https://threer.delight-system.co.jp/) | 自治体向け管理・分別・予定等を提供。データ運用体制も競合の強み |
| C02 | [新宿区の機能案内](https://www.city.shinjuku.lg.jp/kankyo/seiso01_000001_00016.html) | 写真や品名から候補を示す機能もある。写真AI自体を独自性と断定しない |
| C03 | [App Store利用者レビュー](https://apps.apple.com/jp/app/id977071564?platform=iphone&see-all=reviews) | 操作・表示・ウィジェットへの要望は仮説の材料。過去レビューを現在の全利用者の事実として扱わない |

差別化仮説は「説明なしの初期設定」「朝の即時確認」「条件に合う持込先を地図で発見」。市場で検証済みの優位性ではない。

## 技術資料

| ID | 資料 | 用途 |
| --- | --- | --- |
| A01 | [Flutter対応プラットフォーム](https://docs.flutter.dev/platform-integration) | 本体の両OS対応 |
| A02 | [Apple Widget更新](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date) | 更新制約・Timelineの設計 |
| A03 | [Android Widget](https://developer.android.com/develop/ui/views/appwidgets/advanced) | ウィジェットの更新・OS側実装 |
| A04 | [home_widget](https://github.com/ABausG/home_widget) | Flutterとネイティブウィジェットの共有候補 |
| M01 | [Google Maps料金表](https://developers.google.com/maps/billing-and-pricing/pricing) | Maps SDKと他SKUの区別 |
| M02 | [google_maps_flutter](https://pub.dev/packages/google_maps_flutter) | モバイル地図の実装候補 |
| M03 | [MapLibre Flutter](https://github.com/maplibre/flutter-maplibre-gl) | 地図描画の別候補 |
| M04 | [OSMタイル利用規定](https://operations.osmfoundation.org/policies/tiles/) | 背景地図の運用・帰属・キャッシュ等 |
| L01 | [GPT-6 Luna](https://developers.openai.com/api/docs/models/gpt-6-luna)／[料金](https://developers.openai.com/api/docs/pricing) | 低コスト抽出・画像入力の比較候補 |
| L02 | [Gemini料金](https://ai.google.dev/gemini-api/docs/pricing)／[モデル一覧](https://ai.google.dev/gemini-api/docs/models) | モデル・料金・新規利用条件の比較 |
| G01 | [Actions schedule](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#schedule) | 未実行監視を独立させる根拠 |
| G02 | [GPLv3](https://www.gnu.org/licenses/gpl-3.0.html)／[GitHubのライセンス案内](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository) | コード公開条件 |

技術候補の価格は2026-10-05時点で確認した資料に基づく。契約・利用枠・実際の精度・日本語地図の使い勝手・APIアカウントアクセスを検証したことにはならない。

## 参考画像の扱い

ユーザーが示した「資源回収拠点丸わかりマップ事業」の画像は構想の参考とした。資料に含まれる文言をユーザーからの操作命令として扱っていない。権利条件を確認していないため画像ファイルやその中のイラストを公開物に収録しない。
