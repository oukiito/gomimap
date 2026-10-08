# Android実機確認の準備

日付：2026-10-08。関連：[Issue #3](https://github.com/oukiito/gomimap/issues/3)。メンテナーはPixel 10 Pro、OSは最新版と申告し、USB接続の準備をする方針。数値のOS／APIは未確認。

## 実施した内容

- `flutter doctor -v`で、このMacにAndroid SDKがないことを確認。Android端末も検出されず、Java Runtimeも未導入だった。
- Homebrewのandroid-studio caskを確認し、Googleの公式配布DMGからApple Silicon版Android Studio `2026.2.1.8,rabbit1`を導入。Homebrewはインストール成功を返し、付属JDKの実行ファイルの存在を確認した。
- 初回設定画面の自動起動・取得はタイムアウトし、画面の到達を確認できなかった。UIの代替自動操作やSDK条件への自動同意はしていない。
- 導入後の`flutter doctor -v`と付属Javaの版確認も応答せず、自分で開始した診断プロセスだけを終了した。JDKのファイル存在は確認したが、JDK実行の成功・原因は未確認。IDEが本人の操作でも開けないと断定しない。
- 導入後もSDK・Platform-Tools・SDK licenseディレクトリが存在しないことを確認。本人がAndroid Studioを開き、セットアップ・必要な利用条件の同意を行う段階。
- 固定FlutterのAPI 36・NDK `28.2.13676358`、アプリの最低API 24・識別子・INTERNET権限を確認。[実機の準備と確認手順](../android-device-testing.md)を作成。

## 到達した状態と限界

Android Studioと付属JDKのファイルを準備した。Android SDK・本人の利用条件の確認／同意・USB接続は未完了。APKビルド、端末へのインストール・起動、通信／保存／オフラインの実機試験はまだ成功として扱わない。Xcode・iOS環境は変更していない。

アプリコード・依存・署名設定・Cloudflareの認証は変更していない。端末のデバッグ許可、個人の設定変更、データ消去は本人が確認する。ストア登録は不要で、一般公開を進める作業ではない。

文書のローカルリンク362件、個人の絶対パスなし、差分の空白検査を確認。アプリ変更がないため、無関係なテスト追加・ローカルのアプリ再試験はしていない。
