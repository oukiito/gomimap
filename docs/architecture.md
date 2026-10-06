# 技術構成・地図・LLM・費用

状態：2026-10-05調査に基づく推奨案。製品要件の合意とは別に、実機PoC、契約・利用条件、価格・アクセス可否の再確認を経て採用する。Flutterのローカル環境と画面・ルールPoCを構築済み。有料API呼出・契約・実機検証は未実施。

2026-10-07に、自治体別の版付きJSON・区域／日程／受入判定と同梱fixtureを実装。メモリ内の更新候補検証までで、端末DB・HTTP更新は未実装。利用者の希望に基づきCloudflare配信＋端末保存を推奨し、R2 Standard＋独自ドメインを第一候補にする。[実装したスキーマ](data-schema-v1.md)、[保存・配信と料金の確認](data-storage.md)を参照する。Cloudflareの契約・公開設定はまだ行っていない。

## 推奨する構成

| 部分 | 推奨案 | 理由・検証する点 |
| --- | --- | --- |
| アプリ | Flutter / Dart | 両OSの画面・分別ルール・予定計算を共有。地図・通知・読み上げ・文字拡大を実機検証 |
| 端末データ | drift＋shared_preferences | 有効な予定・品目・拠点を通信なしで読める。具体的ライブラリはPoC後に固定 |
| iOSウィジェット | SwiftUI / WidgetKit | 共有データからTimelineを作る。Flutterとの連携にhome_widgetを候補とする |
| Androidウィジェット | KotlinのApp Widget / Glance | OS固有の表示・更新を担当。日程判定は本体で生成した表示データを共有 |
| 地図 | flutter_mapへ移行済み | GPL指定によりGoogle製SDKを保留。タイル配信は別契約。2026-10-06にGoogle依存とキー設定を除去。配信元は未設定 |
| 通知 | flutter_local_notifications＋timezone | サーバーから全利用者へ毎朝配信せず、取得済み予定を端末で予約 |
| 自治体取得・検証 | Pythonの小さなバッチ | HTML／CSV／PDFの扱い、差分、スキーマ検証をまとめる。取得元ごとのアダプター |
| 配信 | Cloudflare R2 Standard＋独自ドメインを第一候補に、版付きJSONをHTTPSで静的配信 | GitHubで承認・履歴、Cloudflareで配信、端末でオフライン利用。契約・配信設定・利用量別費用は未確定 |
| CI・取得ジョブ | GitHub Actionsを候補 | PR検証・履歴管理。独立した外部監視が必要 |

Flutterは[公式のマルチプラットフォーム資料](https://docs.flutter.dev/platform-integration)でiOS／Android対応を確認した。既存のReact／TypeScript資産はないため、React Nativeへ合わせる利点は現状確認できない。Swift＋Kotlinで全体を別開発する案は保守対象が増える。FlutterでもウィジェットやOS権限の作業は残る。

PoCはFlutter 3.47.6／Dart 3.13.5、iOS 15／Android API 24を設定下限とし、lockfileとCI定義で環境を揃えた。製品の最終対応範囲と状態管理ライブラリは実機検証後に固定する。詳細は[開発手順](development.md)を参照。

## 地図サービスの比較

| 候補 | 費用・条件 | 評価 |
| --- | --- | --- |
| Google MapsのモバイルSDK | 調査時の公式料金表でMaps SDKは無料枠Unlimited。Places、Geocoding、Routes、WebのDynamic Maps等は別SKU | 当初の推奨。GPL採用後はSDKの配布条件が未確認のため保留 |
| MapLibre＋商用OSM由来タイル | 描画ライブラリと背景地図配信は別。配信業者の料金・無料枠・帰属表示・利用条件を確認する必要がある | 差替え候補。無料で無制限に使えるとは扱わない |
| OSM標準タイルサーバーへの直接依存 | SLAなし。アクセス・キャッシュ・帰属表示・大量取得等の規定あり | 公開アプリの無制限無料インフラとして計画しない |

根拠：[Google料金表](https://developers.google.com/maps/billing-and-pricing/pricing)、[Flutterパッケージ](https://pub.dev/packages/google_maps_flutter)、[MapLibre Flutter](https://github.com/maplibre/flutter-maplibre-gl)、[OSMタイルポリシー](https://operations.osmfoundation.org/policies/tiles/)。

初期はモバイルの背景地図と自作マーカーを利用し、Places検索・アプリ内経路計算を必須にしない。経路は外部地図に渡す。地図の著作権表示をカード等で隠さない。将来のWeb版は別料金条件で評価する。

利用者住所の自由入力APIより、自治体・町丁目・番地条件の選択を基本にする。GPSからの候補作成は端末機能または利用条件を確認した境界データをPoCで比較する。失敗時の手動選択は必須。施設の座標を外部APIで作る場合、保存・再配布・別地図での利用条件を確認する。

地図SDKはiOS／Androidでキーを分け、各アプリ識別子と対象APIを制限する。モバイルSDKのキーは抽出可能な識別情報として管理し、秘密のLLMキーと同じ防御を期待しない。公開リポジトリには実キーを置かない。

## ウィジェットと通知の境界

本体は同じルールエンジンから、対象日・区分・締切・状態・有効期限を持つ表示データを作る。ウィジェット側で自治体固有の日程ロジックを重複実装しない。

iOSのTimeline、Androidの更新処理はいずれもOSの制御を受ける。ウィジェットの更新時刻と朝6時の通知は別の仕組みで扱う。背景処理の成功、アプリ長期未起動時の再取得、正確な時刻の通知を無条件に保証しない。試用版では権限拒否・再起動・省電力・期限切れ・地域変更も検証する。

資料：[Appleの更新仕様](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date)、[Android App Widget](https://developer.android.com/develop/ui/views/appwidgets/advanced)、[home_widget](https://github.com/ABausG/home_widget)。home_widgetの採用でネイティブ側のUI実装が不要になるわけではない。

初回だけ追加を提案し、地区・言語を引き継ぐ。Androidは対応ランチャーを確認してOSの追加要求へ渡し、iPhoneは短い追加手順を示す。要求の受理と配置成功は別状態とし、スキップ・取消・未確認でも本体を使える。[初回設定の設計図](ux-initial-setup.md)にOS公式根拠と例外を記録する。両OSのネイティブ実装は未完了。

## LLMの役割と候補

役割は(1)変更箇所の抽出補助、(2)月次の抜け・矛盾確認、(3)将来の写真からの品物候補提示。利用者へ表示する収集日や回収可否は検証済みルールから決める。画像生成モデルは今回の写真認識用途とは異なる。

2026-10-05に確認した標準料金。USD／100万トークン。比較は短いコンテキストの通常テキスト入出力で、画像換算・推論・追加ツール・地域等の料金は別途確認する。

| 候補 | 入力 | 出力 | 位置付け |
| --- | --- | --- | --- |
| GPT-6 Luna | $0.10 | $0.50 | 抽出・画像入力の第一検証候補。精度とアカウントからの利用可否は未測定 |
| Gemini 3.5 Flash-Lite | $0.30 | $2.50 | 比較候補。画像入力を含む低コスト用途で評価 |

根拠：[OpenAIモデル資料](https://developers.openai.com/api/docs/models/gpt-6-luna)、[OpenAI料金](https://developers.openai.com/api/docs/pricing)、[Gemini料金](https://ai.google.dev/gemini-api/docs/pricing)、[Geminiモデル一覧](https://ai.google.dev/gemini-api/docs/models)。モデル・価格は実装時に再確認する。Geminiの旧2.5系には既存利用者向けのアクセス制約が案内されているため、新規プロジェクトの前提にはしない。

比較評価は自治体の表・PDF・日付例外・電池条件などに正解を人が付け、項目抽出の正確性、根拠箇所、誤った確定の件数、応答時間、実トークン量で行う。自己申告の信頼度や別LLMの同意だけで合格にしない。利用モデルとプロンプトの変更もデータ抽出の回帰検証対象にする。

通常ページ取得はHTTP等で行い、検索付きLLMを毎回使わない。公開情報の変更部分を送る。第三者のWeb本文はデータとして扱い、その中の命令でツールを実行したり設定を変えたりしない。

写真機能は初回非表示で、画像収集も行わない。追加時はサーバー経由のAPI、回数制限・サイズ制限・費用上限・濫用対策が必要。EXIFを除去し、画像の保存・提供先・保持期間を説明する。無料API枠のデータ利用条件を私的な写真にそのまま適用しない。

## 月3,000円の管理

以下は見積金額ではなく、PoCで検証する月額の配分案。MAU・地図表示数・データ配信量・抽出件数が未確定のため、総額保証はしない。

| 枠 | 配分案 |
| --- | ---: |
| データ配信・バッチ・独立監視 | 1,000円 |
| LLM抽出・月次点検 | 1,000円 |
| 地図関連API・その他・為替変動の余裕 | 1,000円 |

例として1,000回、各回10,000入力＋1,000出力トークンなら、通常テキスト料金の計算はGPT-6 Lunaで$1.50、Gemini 3.5 Flash-Liteで$5.50。実際の入力長・推論出力・再試行・画像トークン・税・為替・追加APIは含まない。写真1枚の費用は解像度とモデル別換算を実測してから見積もる。

利用者100／1,000／10,000人のシナリオをG03で試算する。予算アラートだけでは自動停止しないサービスもあるため、アプリ側の呼出上限・同時実行制御・リトライ上限とサービス側の制限を組み合わせる。超過見込み時は新規の任意AI処理を止め、確認済みの収集予定を端末で利用できる状態は維持する。

ストア登録費、ドメイン、試験端末、開発者の作業時間は別途明示する。請求が必要な契約を無料と見なして着手しない。

## ライセンス確認後の更新

2026-10-05のGPL指定に合わせ、現在の依存と候補のライセンスを[専用文書](licenses.md)に記録した。地図は`flutter_map`、通知は`flutter_local_notifications`、ウィジェットは`home_widget`、DBは`drift`を第一検証候補とする。状態管理は非同期更新導入時にRiverpodを検証。位置情報候補`geolocator`はAndroid側のGoogle Play services依存を確認したため保留し、OS標準APIへの接続と比較する。2026-10-06に地図描画のみflutter_mapへ移行。他候補は未導入。
