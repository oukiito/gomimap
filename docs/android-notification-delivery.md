# Android通知の実配送の隔離試験

2026-10-09。#51、V04、NT13、QT05。手動テストボタンと異なり、短い実予約→AlarmManager→Receiver→OS投稿を確認する。通常版・個人端末の時計や設定は変えない。

## 前提・ビルド

- 専用Androidエミュレータと別ID `dev.gomimap.gomimap.qa`。通常版はこの計測を記録しない。native runnerもQA package／ranchu・goldfishを検査してから保存へ進む。
- [QA時計](qa-clock.md)の実時計モード、サンプル地区の確認保存、日本語、OS通知許可を明示していること。試験中にQA本体を開くと通常の再照合が試験planを置き換えるため、ホームへ戻してから準備する。
- `app/`でQA profileをビルドし、通常ビルドで出力を上書きする前にGit対象外へ退避する。

```sh
flutter build apk --profile --no-pub --target-platform android-arm64 --dart-define=GOMIMAP_QA=true
```

`app/android/`で付属JDKをJAVA_HOMEへ設定し、同じQA定義でSDK-only試験APKを生成する。SDKの試験ライブラリは追加しない。

```sh
./gradlew -Pdart-defines=R09NSU1BUF9RQT10cnVl :app:assembleDebugAndroidTest
```

退避したQA profile本体と`app/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk`を専用エミュレータへデータ保持でインストールする。個人端末・通常版へこの短期試験を実行しない。起動／許可確認はMaestro MCPで行い、ホームへ戻す。エージェントのシェル実行はrtkを付ける。

## 予約・観察・復旧

リポジトリ直下から実行する。以下のemulator-5556は今回の専用AVDの例であり、Maestroのlist_devicesで対象を確認して指定する。CLIはemulator形式、ro.kernel.qemu=1、QAのインストールを確認する。adbがPATHにない場合は`--adb <SDKのadbのパス>`を追加する。

```sh
python3 scripts/android_notification_delivery.py --device emulator-5556 prepare --case basic --delay-seconds 45
python3 scripts/android_notification_delivery.py --device emulator-5556 report
python3 scripts/android_notification_delivery.py --device emulator-5556 cleanup
```

prepareは既存QAのjournalを専用backupに保存し、1件の架空試験planへ置き換える。サンプル地区・実時計・OS許可がなければ拒否する。通知設定の希望や地区・言語は書き換えない。Instrumentationは予約後すぐ終了し、待機中のプロセスから投稿しない。reportはrun-asで自作のcaseとeventだけを読み、アプリを再起動しない。

配送時刻・世代・通知ID・OSのpostTime・idle状態・起動後経過時間をQA専用ファイルへ最大32件記録する。本文・端末ID・位置・個人写真・外部通信は含めない。OS投稿後にだけpostedを記録し、実際のactiveNotificationsも照合する。reportのdeliveredはcaseのdue／ID／期限／OS投稿時刻が一致した自動投稿だけ。manualは配送成功に数えない。

| ケース | 操作・意味 |
| --- | --- |
| basic | 短い実予約後、アプリ未起動のまま到達を観察 |
| reboot | 180秒以上先へ準備→`reboot`。アプリを開かず、BOOT_COMPLETEDと後続の自動投稿を観察。sys.boot_completedも確認 |
| expiry | 予約時刻の1ms後を失効とする架空plan。Receiverが動いたこととpostedがないことを区別。たまたま1ms以内に配送された場合は期限の仕様上有効なので結果を記録する |
| cancel | 予約直後に所有予約を取消・0件を確認。観測時間内に旧予約が投稿されないことを補足確認 |
| doze | 準備→`doze`で専用AVDだけをbattery unplug／force-idle。reportだけで観察し、画面操作でidleを解除しない。届いた時点のidleを記録。終わったら`awake`／cleanup |

reboot／dozeは対応するcaseの準備済みmarkerがある場合だけ実行する。Doze進入失敗時は解除する。cleanupはforced idle解除とbattery resetを試してから、旧journalのplan／paused状態を復元する。試験で投稿した自作IDも消す。失敗時は完了と書かず再実行し、端末初期化やアプリデータ削除で代用しない。旧QA設定・ウィジェット配置を残す。

## 画面と理由

| ID | 要素・操作 | 理由・戻る・保持・失敗・確認 |
| --- | --- | --- |
| NT13／QT05 | QAの自動通知に「テスト」、case、絶対日付、架空の配送試験と非実用の本文 | 実際のごみ通知と試験を取り違えないため。製品UIへ操作を追加しない。短期通知を現在のごみ分類の正しさの根拠にしない。旧QA planはcleanupで復元。投稿時刻と実OSカードを別々に確認 |

到達後は`capture_android_notification.py`で新しいMaestro MCP接続を作り、list_devices→inspect_screenで通知欄を取得する。再起動でデスクトップ側のcached driverがUNAVAILABLEになっても、試験者の操作待ちへせず、この新しい接続を使う。自作通知行のapp名とタイトルが同じ行に存在することを検査し、他アプリの同じタイトルを撮影しない。

```sh
python3 scripts/capture_android_notification.py --device emulator-5556 --output .tooling/notification-delivery/basic-card.png
```

このCLIもQA／エミュレータとcaseの自動投稿を検査する。Doze計測が終わったらawakeで解除し、撮影する。ログはGit対象外へ保存する。自作カードのタイトル・本文をassertし、自作カードのタイトル・本文をassert、`android:id/notification_main_column_container`へcropして撮影する。他アプリの通知や全画面を公開しない。撮影前にQA本体をlaunchAppすると再照合で通知を消すため、予約待機・証拠取得中は起動しない。

## 判定の限界

不正確アラームは希望時刻より遅れることがある。[Android公式](https://developer.android.com/develop/background-work/services/alarms)。Dozeではallow-while-idleにも頻度制約があり、連続した短い試験と実利用の1日1〜2回を同一視しない。[公式の制約と試験](https://developer.android.com/training/monitoring-device-state/doze-standby)。

観測終了時に届いていない場合は、経過時間・idle・Receiver起動の有無を記録する。予約時刻で必ず届く保証・配送不可能という結論へ変換しない。正確な6時、全メーカー、Pixel実機、iOS、実データ、長期未起動は別条件。[実行記録](work/2026-10-09-android-notification-delivery.md)。
