# 開発環境・実行手順

ストア登録より先に画面・ルールを開発する。現在は開発用サンプルを使うPoCであり、利用者へ配布する版ではない。通常起動は日本の現在日付で、固定日は試験の注入に限定する。区域・日程・回収拠点は架空。

以下のコマンド例は一般の開発者向け。開発エージェントは[AGENTS.md](../AGENTS.md)に従い、実行時に`rtk`／`rtk proxy`を付ける。

## 構成

- `app/`：Flutterアプリ。iOS／Androidが製品対象、Webは画面確認用。
- `data/datasets/fixtures/`：自作の架空JSON。`app/assets/generated/`へコピーして同梱する。`demo_data.dart`の分別・地図の架空データとは用途を分ける。
- `app/lib/domain/`：スキーマ1、日程・住所条件・受入条件・公開根拠の検証。
- `app/lib/data/demo_setup_store.dart`／`app/lib/ui/demo_area_setup.dart`：初回・変更の地区確認と保存状態。
- `app/lib/ui/collection_map.dart`：地図の描画と未接続時の代替表示。
- `app/test/`：日程・画面操作の回帰テスト。
- `data/sources/`：自治体の出典・利用条件のメタデータ。製品の収集予定とは別。
- `scripts/validate_sources.py`／`scripts/tests/`：出典登録簿と再配布条件の検証。
- `.github/workflows/flutter.yml`：PR／mainで出典検証・Pythonテスト・Flutter整形・解析・テスト・Webビルド。

Flutter **3.47.6**、Dart **3.13.5**を使用。Flutterコミットは`5fc346839b5d0eef006ed8404392afb4dfae428d`。依存バージョンは`app/pubspec.lock`を共有する。既存環境がない場合は、プロジェクトルートで以下を実行する。

```sh
git clone --depth 1 --branch 3.47.6 https://github.com/flutter/flutter.git .tooling/flutter
python3 scripts/prepare_demo_data.py
cd app
../.tooling/flutter/bin/flutter pub get --enforce-lockfile
../.tooling/flutter/bin/flutter run -d chrome
```

通常のFlutterインストールがある場合は`flutter`コマンドでよい。`.tooling/`はGit対象外。次のチェックはリポジトリ直下から実行する。すでに`app/`にいる場合は先頭の`cd app`を省く。

```sh
cd app
../.tooling/flutter/bin/dart format --output=none --set-exit-if-changed lib test tool
../.tooling/flutter/bin/flutter analyze
../.tooling/flutter/bin/flutter test
../.tooling/flutter/bin/flutter build web
```

## 同梱データと検証

日程の元データを変更した場合、リポジトリ直下で`python3 scripts/prepare_demo_data.py`を再実行してからテスト・ビルドする。生成した同梱JSONはGitに追加せず、`data/datasets/fixtures/toshima-demo-v1.json`のみを編集する。スキーマ・公開検査は[データ仕様](data-schema-v1.md)、保存先とfixtureのHTTP取得・保存は[保存・配信](data-storage.md)を参照する。端末DB・実データ・配信ジョブは未実装。

## ネイティブ環境

2026-10-05のローカル確認環境にはXcode本体とAndroid SDKがなかった。2026-10-08にAndroidのデバッグAPKのビルドと、Pixelでの初回操作・地区保存を確認。iOSビルド・実機と、Androidの残る場面は未検証。PoCの設定下限はiOS 15／Android API 24。最終サポート範囲は実機試験で決める。アプリ識別子`dev.gomimap.gomimap`は仮で、ストア登録前に確定する。署名も開発用のテンプレート段階。

2026-10-08にAndroid Studioと付属JDKを導入し、本人の初回SDKセットアップ後、不足していた公式ツール・指定API／NDKを追加した。Android toolchainは成功。Pixel 10 Pro／Android17で地区の保存・再起動保持と通常のHTTPS取得・JSON保存・原本一致を確認。オフライン画面は本人が確認し、profileで起動性能を測定した。残る操作・異常系は継続する。[Android実機の手順](android-device-testing.md)、[準備記録](work/2026-10-08-android-preparation.md)、[初回ビルド](work/2026-10-08-android-build.md)、[実機結果](work/2026-10-08-pixel-runtime.md)を参照する。

性能は実機のprofileで確認する。`app/`から`flutter run --profile --trace-startup -d <接続したAndroidのID>`で起動指標を取得でき、出力は`build/start_up_info.json`／`build/start_up_timeline.json`。生トレースはGitへ追加せず、公開するのは必要な指標と条件に絞る。debugとrelease相当、初回描画とOSを含む全起動時間を区別する。[起動の設計](ux-startup.md)を参照。

iOSはXcode、AndroidはAndroid SDKとJDK等を用意し、`flutter doctor`の必要項目を解消してから`flutter run`で確認する。iOSの無料Personal Teamには有効期間等の制限があり、継続配布・TestFlightの代わりにはしない。[Apple公式](https://developer.apple.com/support/compare-memberships/)

## ローカル設定ファイル

リポジトリ直下の`.env.local`は`.gitignore`で除外され、Flutter起動時に読み込める。`.env.local`はリポジトリ直下に置き、`app/`から相対指定する。

```sh
# リポジトリ直下で作成（既存の.env.localがある場合は実行不要）
cp .env.example .env.local

# app/ディレクトリへ移動して起動（タイル設定が空なら未接続表示）
cd app
../.tooling/flutter/bin/flutter run -d chrome --dart-define-from-file=../.env.local
```

Flutterは`--dart-define-from-file`で`.env`形式の設定を読み込む。[Flutter 3.13で追加](https://docs.flutter.dev/release/release-notes/release-notes-3.13.0)。値はビルドしたアプリから取り出せるため、秘密のLLM/APIキーは入れない。地図配信のクライアント識別子を使う場合も、許可するアプリやドメインを配信元で制限する。Gitへの追加前に`git check-ignore -v .env.local`で除外を確認する。`.env.example`にはキーや実在の契約情報を書かない。

## 地図の接続

2026-10-06にGoogle Mapsの依存と両OSのAPIキー設定を除去し、`flutter_map`へ移行した。Webでも同じ描画を使う。デフォルトでは外部タイルを取得せず、未接続表示を維持する。

利用条件を確認した配信元を、次の3つの`--dart-define`で設定する。3つが揃い、URLがHTTPSで、タイルURLに`{z}`・`{x}`・`{y}`が含まれる場合に描画する。

- `MAP_TILE_URL`：XYZタイルURL
- `MAP_ATTRIBUTION`：配信元が指定する帰属表示（地図上に常時表示）
- `MAP_ATTRIBUTION_URL`：帰属表示から開くHTTPSの権利情報ページ

秘密のサーバーキーをクライアントへ埋め込まない。製品版の配信元・契約は未確定。タイル設定を有効にしても拠点は架空のままであり、実際の訪問案内には使わない。未接続表示・ピン選択・帰属表示をテスト済み。実配信との接続、通信失敗時の案内、両OS実機試験は未完了。

OSM標準タイルサーバーを無条件で製品の配信元にしない。[公式利用条件](https://operations.osmfoundation.org/policies/tiles/)に従い、帰属表示、アプリ識別、HTTPキャッシュ、Web Refererなどを配信元ごとに確認する。先読み・一括ダウンロードは実装していない。

## 初回の地区選択

未設定の場合はサンプル地区の選択→確認→保存から開始する。候補は確認前の日程へ適用せず、途中で終了した場合は確認画面を再開する。後からの変更も確認画面を経由し、取消・保存失敗なら旧地区を保持する。対応Androidは地区保存後に初回ウィジェット提案、回答後は「今日」へ進む。実住所・GPS、通知・iOSの任意手順は未実装。理由と保存状態は[初回設定](ux-initial-setup.md#試作へ実装した初回の動作)、次の実装条件は[残る設計](remaining-design.md)を参照する。

試作の地区と進行状態は`demo.setup.v1`へ保存する。既存の有効な`demo.area`を引き継ぎ、新形式の保存後は新キーを優先する。実地区の設定へサンプルIDを流用しない。設定を初回状態で試す場合は端末のアプリデータ／Webのサイトデータを消す。言語設定なども消えるため、実際の利用者のデータで試さない。

## このPoCにない機能

位置候補、実住所からの区域判定、通知予約、iOSウィジェット、実自治体データの取得・配信、定期更新・監視、写真AIは未実装。AndroidウィジェットとCloudflareのfixture取得・保存は実装済み。分別案内は動線確認用で、粗大ごみの寸法判定・申込先への直接リンクは未実装。通知の設定をしたように見せるスイッチは置かない。両OSのウィジェットは初回版の対象。

公式リンクは豊島区のごみ・リサイクル総合ページ。個別日付の根拠ページや品目別の直接リンクは、公開可能な公式データ導入時に持たせる。

## GitHubでの開発

貢献者向けのIssue・PR手順は[CONTRIBUTING](../CONTRIBUTING.md)、メンテナーのアカウント設定と公開状況は[GitHub運用](github-workflow.md)を参照する。過去の確認結果は[作業記録](work/README.md)に残す。

出典登録簿を変更する場合は、リポジトリ直下で以下も実行する。Python 3の標準ライブラリのみで動作する。利用条件の検査と日程・座標の正確性の検証は別で、詳しくは[豊島区の出典登録簿](sources/toshima.md)を参照する。

```sh
python3 scripts/validate_sources.py
python3 -m unittest discover -s scripts/tests -v
```

## 開発用データの取得・保存の確認

開発用fixtureは保存済み／同梱から起動し、表示後に固定のCloudflare公開URLを認証なしで確認する。地区・言語・精密位置を要求へ付けない。更新周期・保存ファイル・失敗時の扱い・Webの限界は[保存設計](data-storage.md)を参照。端末DB、実自治体データ、両OS実機確認は未完了。

通常のテストはネットワークを使わない。公開fixtureの実HTTPS取得・ファイル保存・再読込を明示的に確認する場合は、`app/`で次を実行する。認証ファイルは不要。

```sh
flutter test --no-pub --dart-define=GOMIMAP_VERIFY_LIVE_DATA=true test/live_dataset_test.dart
```

これは開発マシンのFlutter試験で、iOS／Android実機の保存や通信の成功を意味しない。Web確認版全体をオフラインで再読込できるPWAではない。

## 多言語対応

画面文言は`app/lib/l10n/app_*.arb`で管理する。日本語・英語・中国語（簡体字／繁体字）・韓国語・ベトナム語・ネパール語・ポルトガル語・スペイン語・フィリピノ語（タガログ語）を提供する。Flutterの`gen-l10n`で`lib/l10n/generated/`へ型付きクラスを生成し、生成コードは直接編集しない。`flutter pub get`／ビルド時にも再生成する。言語追加時はARB、`lib/l10n/languages.dart`の母語表記・ロケール、iOSの`CFBundleLocalizations`、テストを更新する。中国語の基底`app_zh.arb`は簡体字のフォールバックで、選択肢には簡体字・繁体字だけを表示する。追加の宣伝・説明文は不要。

`intl`で日付をロケール別に表示。自治体の日程判定は表示言語に影響されない。サンプルの品目・日程は安定IDから翻訳へ変換し、検索用の各言語の別名は表示言語と独立させている。公式の施設名など、確認済み翻訳がない実データの名称は将来も原文を保持する。

言語設定は`app.language`にBCP 47タグ（例：`ja`、`zh-Hant`）を保存。台湾・香港・マカオの中国語は繁体字、それ以外は簡体字を選ぶ。明示的なHans／Hant設定がある場合は地域より優先する。端末の`tl`は`fil`へ対応付ける。初回は端末の対応言語、非対応なら日本語。翻訳は実装用の初稿で、公開前に各言語話者による分別・電池注意事項の内容確認を行う。変更は即時反映し、保存失敗は通知する。保存対象は言語、サンプル地区とその選択・確認段階。Web、Flutterの画面テストで検証し、ネイティブ実機での言語切り替えは未検証。
