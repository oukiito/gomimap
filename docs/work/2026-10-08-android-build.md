# 最初のAndroid APKビルド

日付：2026-10-08。関連：[Issue #3](https://github.com/oukiito/gomimap/issues/3)。[準備記録](2026-10-08-android-preparation.md)に続き、メンテナーからAndroid Studioの初回セットアップ完了報告を受けた。アプリソースは`0a66c99ead99b2440c86ec170817cfe741cd66d3`、自作fixtureは前回と同じ版。

## SDKとJDK

- 初回セットアップでSDK・Platform-Tools・licenseファイルが作られたことを確認。Command-line Tools、プロジェクト指定API36とNDKは不足していた。
- Googleの公式`repository2-3.xml`でApple Silicon用Command-line Toolsの配布を確認。155,384,151 bytesと公式SHA-1 `ad03dc49bfacfd52c110b14104ea548b8a07e830`を照合して追加。既存のツールやlicenseファイルを上書きしていない。
- 指定API36、Build-Tools36.0.0、NDK28.2.13676358を追加。Gradleが依存に必要なAPI35とCMake3.22.1を追加し、既存のlicense同意を受け入れたことを出力で確認。条件への自動回答、`yes`入力、licenseファイルのコピーは行っていない。
- 付属JDKの実行が成功し、OpenJDK25.0.3（b508.16）を確認。Flutter doctorのAndroid toolchainは成功、全Android licenseの受入済み表示を確認。アプリ設定のJavaバイトコード対象は17のまま。
- 最新Command-line ToolsのsdkmanagerはAndroid CLIへ処理を委譲した。ダウンロード・SDK追加のみを実行し、出力が提案したagent用skill導入等は行っていない。IDE・SDK・Javaのグローバルな認証やアプリ署名設定を変更していない。

## APKの結果

`app/`で`flutter build apk --debug --no-pub`を実行し、Gradle assembleDebugが271.3秒で成功。初回ツール取得の時間は別に含まれる。

| 項目 | 実際に確認した結果 |
| --- | --- |
| 生成物 | `app/build/app/outputs/flutter-apk/app-debug.apk`。Git対象外、ストア公開・GitHub添付はしていない |
| サイズ | 159,204,324 bytes。複数CPU向けのデバッグ版で、製品の配布サイズではない |
| SHA-256 | `7dcf893d097180bc5e7adf61e8a9b74c25d11596d1811bc52206087fdce2e1c3` |
| アプリ | `dev.gomimap.gomimap`、versionName0.1.0、versionCode1 |
| SDK | 最低24、target／compile36 |
| CPU | arm64-v8a、armeabi-v7a、x86_64。Pixel向けのarm64を含む |
| 同梱 | canonicalのtoshima-demo-v1.jsonがAPKへ含まれることを確認 |
| 秘密の混入確認 | APK内544エントリーを展開読込し、ローカルCloudflareトークン・アカウントIDがないことを値を表示せず検査 |

Android Studio2026.2.1.8、Flutter3.47.6／Dart3.13.5、Gradle9.3.1、プロジェクト指定AGP9.1.0を使用。ビルド中にSDK XML版・将来のJava native accessの警告があったが、今回は成功した。警告だけを解消する目的で無関係な設定・依存を変更していない。

## 実機と残る作業

`adb devices -l`にAndroid端末はまだ表示されなかった。Pixel 10 Proの機種名と「最新版OS」はメンテナーの申告で、OS／APIの数値は未取得。インストール、起動、HTTP取得、端末保存、再起動・オフライン、Android戻る、文字拡大・TalkBackは**実機未確認**。チェックリストは[Android実機手順](../android-device-testing.md)に残す。

アプリコード・Dart依存・署名設定・API認証は変更していないため、ローカルで無関係なテストは繰り返していない。ビルド成功と完成バイナリのライセンス監査・ストア配布承認は別。[ライセンス記録](../licenses.md)の未完了範囲を継続し、iOSビルド・実機・一般公開も未完了。
