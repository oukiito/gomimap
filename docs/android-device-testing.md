# Android実機の準備と動作確認

対象：開発用ごみまっぷ。ストア登録は不要。アプリの日程・地区は架空の表示例で、実際のごみ出しには使えない。[Issue #3](https://github.com/oukiito/gomimap/issues/3)の一部として、ビルド成功と実機確認を分けて記録する。

現在：2026-10-08にPixelで地区の保存・再起動保持と通常のHTTPS取得・JSON保存・原本一致を確認。オフライン画面は本人が確認した。debug／profileで起動性能を測定し、Pixelにはprofile版が入っている。Androidウィジェットの配置を確認し、2×2への縮小・オフライン・タップは本人が確認。締切切替版をデータ保持で更新し、40項目のSDK試験が成功。残る画面報告・実際のOS更新到達等は[ウィジェット記録](work/2026-10-08-android-widget.md)で追跡する。[ビルド記録](work/2026-10-08-android-build.md)、[実機の結果と限界](work/2026-10-08-pixel-runtime.md)を参照。

## Macの初回準備

1. Android Studioを公式配布から導入して開く。初回はStandardのセットアップを進め、SDKの利用条件は開発者本人が確認・同意する。Google Playの開発者アカウントやFlutterプラグインは、CLIから実機へ起動するための必須条件ではない。
2. SDK ManagerでAndroid API 36、SDK Platform-Tools、SDK Command-line Toolsを確認する。本プロジェクトの固定Flutter 3.47.6はcompile／target API 36、NDK `28.2.13676358`を指定している。必要なBuild-Tools・NDK等の不足はビルド時の出力で確認して追加する。
3. `flutter doctor -v`でAndroid toolchainを確認する。ライセンスが不足する場合、本人が`flutter doctor --android-licenses`を実行し、必要な条件を確認する。`yes`の自動入力や他の環境のlicenseファイルのコピーで代用しない。

Flutterは既存の`.tooling/flutter/bin/flutter`を使う。Android Studioの付属JDKを使い、グローバルなJava・Git認証を別のプロジェクト向けに切り替えない。iOS環境はこの準備の対象外。

根拠：[FlutterのAndroid準備](https://docs.flutter.dev/platform-integration/android/setup)、[Android Studioの導入](https://developer.android.com/studio/install)。SDKのAPI／NDKの指定は固定SDKの`FlutterExtension.kt`と`app/android/app/build.gradle.kts`を確認した。IDEの最新版とプロジェクトの固定Flutterを混同しない。

## PixelをUSBで接続

1. 「設定 → デバイス情報 → ビルド番号」を7回タップし、開発者向けオプションを表示する。必要な端末ロックの認証は本人が行う。
2. 「設定 → システム → 開発者向けオプション → USBデバッグ」を有効にする。
3. データ通信できるUSBケーブルでMacへ接続し、端末のロックを解除する。USBデバッグの許可が出たら、このMacへの接続であることを確認して本人が許可する。

機種・OSによりメニューが違う場合は設定内検索を使う。Macでは通常Windows用OEM USBドライバーは不要。OEMロック解除、ブートローダー操作、端末の初期化は不要。[Androidの開発者設定](https://developer.android.com/studio/debug/dev-options)、[実機への接続](https://developer.android.com/studio/run/device)。

## 接続後のビルド・起動

一般の開発者向けコマンド例。エージェントは[AGENTS.md](../AGENTS.md)に従い`rtk`を付ける。リポジトリ直下で接続端末を確認し、端末IDを確認して指定する。複数台の中から推測で選ばない。

```sh
.tooling/flutter/bin/flutter doctor -v
.tooling/flutter/bin/flutter devices
python3 scripts/prepare_demo_data.py
cd app
../.tooling/flutter/bin/flutter build apk --debug --no-pub
../.tooling/flutter/bin/flutter run --debug -d <接続したAndroidのID>
```

初回はGradle・Androidツールのダウンロードに時間がかかる。アプリ識別子は`dev.gomimap.gomimap`、最低APIは24。対応可否は接続後に数値のOS／APIを確認する。「最新版」という申告からOS番号を推測しない。既存の同じアプリがある場合は署名・版を確認し、インストール失敗を理由に勝手にアンインストール・データ消去しない。デバッグ署名のAPKをストア公開版として配布しない。

## 最初に確認する項目

| 項目 | 実機で確認する操作・期待結果 | 理由／設計 |
| --- | --- | --- |
| 初回 | サンプル地区A／Bを選び、確認して保存。保存前は地区を確定しない | [初回設定](ux-initial-setup.md)、誤った地区の予定を防ぐ |
| 今日 | 日本の現在日付・区分・締切・地区が読める | UX01・09、朝の判断 |
| 保存済み設定 | 言語・地区を変更し、アプリを閉じて再び起動。保存した設定を維持 | 選び直しの負担と誤案内を減らす |
| データ取得・保存 | 通信可能な状態でJSONの保存完了をアプリ専用領域から確認。キー・他アプリのデータ・端末識別子を公開しない | [更新 D01〜D03](ux-data-refresh.md)。画面が同じだけでは取得成功の証拠にしない |
| 通信なし | 確認済みの保存後、本人が一時的に通信を切り、アプリを閉じて再起動。保存済み／同梱から表示できる。終わったら通信を戻す | D01・05、朝の通信依存を減らす。架空の同梱と取得データは同じなので保存は別確認 |
| 分別 | 電池を検索し、乾電池と充電池の案内を区別。未回答／分からない条件を受入可能と断定しない | UX03・06、誤った回収先を防ぐ |
| 戻る | 品物→資源回収場所→Androidの戻るで品物へ。検索入力・条件を保持 | [ナビゲーション N05〜N06](ux-disposal-navigation.md) |
| 文字・読み上げ | 本人が必要に応じて文字サイズやTalkBackで、地区・主要操作・閉じるを確認 | UX07・09、文字や操作が欠けない |

GPS、実自治体の日程、通知、iOSウィジェット、実地図配信は現在未実装／未接続。Androidウィジェットは自作fixtureに実装し、SDK試験・実配置と本人の以前の版の操作報告を確認している。動いているような確認結果を付けない。期限切れ・破損・保存失敗の自動試験はあるが、実機でのOS強制終了・電源断の耐久性を代替しない。

記録にはアプリのコミット・版、端末モデル、数値のOS／API、確認操作と結果、未確認項目を残す。USBシリアル・詳細住所・通知などの個人情報・生の端末ログは公開しない。再インストールによる初回の再試験は設定・キャッシュを消すため、消去対象を確認して本人の許可を得る。

## AndroidウィジェットのSDK試験

新しい試験ライブラリを入れず、SDK標準のInstrumentationで共有する日程投影・日本日時・時間帯選択・不明・期限切れ・複数締切・文字拡大を確認する。`app/`で次を実行し、ネイティブ試験のJSONをDartの共有処理から再生成する。

```sh
flutter test --dart-define=GOMIMAP_EXPORT_WIDGET_FIXTURE=true test/home_widget_projection_test.dart
```

次に`app/android/`で付属JDKを`JAVA_HOME`に設定して`./gradlew :app:assembleDebugAndroidTest`を実行する。profile本体と試験APKをデータ保持で更新し、次を実行する。下記のIDは自分の接続端末を指定する。

```sh
adb -s <端末ID> install -r -t build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
adb -s <端末ID> shell am instrument -w dev.gomimap.gomimap.test/dev.gomimap.gomimap.WidgetChecksInstrumentation
```

APKの相対パスは`app/`を起点とする。結果Bundleの`result=PASS`と試験数を確認する。Instrumentationの終了コード`-1`はActivity.RESULT_OK。これはランチャーでの配置・縮小・オフライン表示・タップや、実際のOS更新到達とは別に記録する。端末時計や利用者の共有ファイルを試験で変更しない。

地区を保存した本体が投影を生成済みの場合は、追加の読み取り専用確認を実行できる。

```sh
adb -s <端末ID> shell am instrument -w -e verifyLive true dev.gomimap.gomimap.test/dev.gomimap.gomimap.WidgetChecksInstrumentation
```

このオプションは現在の保存ファイル・データ版・地区と、ネイティブの通常読み込み結果を確認する。44項目になる。未設定の端末や期限切れの投影では成功を前提にしない。画面を取得・操作せず、ランチャーの描画完了を保証する試験でもない。
