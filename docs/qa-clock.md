# Androidの隔離QA時計と日付・締切の実画面試験

2026-10-09。#47、V01・V02、W13〜16。OS時計を変えず、本体とAndroidウィジェットへ同じ固定UTC時刻を渡す試験用実装。専用エミュレータの9ケースを[実行記録](work/2026-10-09-android-clock-qa.md)へ保存した。iOS・実アラームの更新到達・省電力はこの試験に含まない。

## 通常版との分離

| 項目 | 通常版 | QA版 |
| --- | --- | --- |
| 定義 | `GOMIMAP_QA`なし／false | `GOMIMAP_QA=true` |
| application ID | `dev.gomimap.gomimap` | `dev.gomimap.gomimap.qa` |
| Kotlin | `src/standard`の実時計。QAチャネルと引数パーサーなし | `src/qa`の固定時計と引数受付 |
| データ | 既存fixtureの同梱／取得／保存 | 所有fixtureから作るnormal／tomorrow／multiの別版。HTTP更新なし |
| 保存・配置 | 既存の設定・ウィジェット | 別IDで地区・言語・時計・ウィジェットを分離 |
| release | 通常のビルド | 明示releaseとreleaseを含む汎用assembleを拒否 |

同じDart定義からGradleのIDとソース選択を決め、二つの別設定を手動で合わせない。DartのQA起動はネイティブから返るpackage IDも確認し、通常版に時刻を設定することはない。[Androidのビルド／ソースセット](https://developer.android.com/build/build-variants)。新しいpub／ネイティブ依存は追加していない。

通常のアプリに時計の変更ボタンを設けない。QA時計は対象アプリだけに固定され、OS時計、通常版の時計、他アプリの予定を変更しない。1970〜2099年UTCの範囲を受け付け、35日投影が4桁の年を外れない範囲に制限する。負値・範囲外・未知scenarioは変更しない。

## ビルドと初回準備

通常版のコマンドは変えず、QAだけ明示定義でビルドする。以下は`app/`で実行する一般開発者向け例。エージェントはrtkを付ける。

```sh
flutter build apk --profile --no-pub --target-platform android-arm64 --dart-define=GOMIMAP_QA=true
```

生成されたAPKは次の通常ビルドで同じ出力パスが上書きされるので、Git対象外の別保存先へコピーする。別IDであることを確認し、専用エミュレータへインストールする。通常版や個人Pixelへ置き換えるAPKではない。

QAアプリで日本語→サンプルA→確認保存→OSのウィジェット追加を行う。要求と配置を分け、実際のOS確認文言を読み、QAのウィジェットが1つ置かれたことを確認する。既存通常版の配置は消さない。初回準備は1回で、各ケースで地区・言語・配置を消去しない。

## 時計・期待値とFlow

起動引数`gomimap.qa.clock_ms`はUTC epochミリ秒の文字列、`gomimap.qa.scenario`はnormal／tomorrow／multi。QAのSharedPreferencesへ時刻・scenario・単調増加revisionを1値として保存し、Dartへ同じ値を通知する。古いrevisionは新しい更新を上書きしない。時刻自体は前後へ動かせる。初回に指定がなければnormal・2026-10-05 07:59:59日本時間で固定する。

本体は通常の時計getterからその値を読み、明示変更でカードと共有投影を再評価する。固定時計では本体の実時間タイマーとAndroid RTCアラームを使わず、QA引数変更で更新する。通常版のタイマー・アラームはそのまま。これにより、条件と描画を決定的に試験できるが、実アラームの到達を実証した意味にはならない。

`clock-cases.json`のscenarioとUTC instantごとに、`app/`で期待値を出す。

```sh
flutter test --no-pub tool/maestro_expectation_test.dart \
  --dart-define=GOMIMAP_MAESTRO_SCENARIO=tomorrow \
  --dart-define=GOMIMAP_MAESTRO_INSTANT=2026-10-04T23:00:00Z
```

`.tooling/maestro-results/expectation.json`のenvをMaestro MCP `run`へ渡し、対象は提供された専用エミュレータID、ファイルは`e2e/maestro/flows/clock-step.yaml`とする。[Maestroの起動引数](https://docs.maestro.dev/reference/commands-available/launchapp)。Flowはデータを消去・アプリを強制停止せず、固定のQA IDへ引数を渡して本体／ウィジェットの既存比較Flowを実行する。

期待値は共通投影から生成するが、それだけを唯一のoracleとしない。[clock-cases.json](../e2e/maestro/clock-cases.json)の独立した日付・区分の期待値とも一致することを確認する。generatedAtは実行日時、clockInstantは注入日時、RUN_IDは実行時のUTC由来で区別する。

本体の日付・地区・種類、ウィジェットの日付・地区・種類・締切、タップ復帰をassertし、主カードとウィジェットのPNGを保存する。小型の複数締切は一覧をスワイプし、二つの締切を追加でassert・撮影する。内容を持つ一覧自身のIDから操作し、文字がアクセシビリティに存在するだけで読めると判定しない。

## 操作・状態・理由

| ID | 対象 | 理由と保持・失敗・確認 |
| --- | --- | --- |
| QT01 | QAの別ID・アプリ名 | 開発者が通常版と取り違えず、利用者設定を消さずに境界を試す。通常版／QAのAPKを別々にビルドし制御の有無を確認 |
| QT02 | 固定時計・scenario・revision | 実際の締切まで待たず、両側の同じ入力で誤案内を見つける。未知入力は無視、古い応答は戻さず、再起動で固定値を再読込 |
| QT03 | 同じ画面・地区のまま再評価 | 時刻変更で地区選び直しや再配置を必要にしない。HomeShellの状態を保持し、カード・投影の更新を確認。通常版の締切／0時タイマーも単体試験 |
| QT04 | ウィジェット一覧を上へ戻し、複数締切を読める位置へ操作 | 前のケースのスクロールで次の種類を見落とさない。日付タップで今日へ復帰し、重要PNGは自作ウィジェットに限定 |

QA定義はiOS／Webの時計制御ではない。通常のWebビルド、解析、190件のFlutter試験、両APKのSDK54項目、release拒否、通常APKのDEXにQAのチャネル／引数がないことを確認した。正確な0時到達、Doze、全言語の拡大、iOS、実データ、通知は引き続き別の受け入れ条件とする。

## 通知試験の実時計モード（#49）

QA起動引数`gomimap.qa.real: "true"`を明示すると、専用QAの本体・ウィジェット・通知だけがOSの実時計を読む。既定と`"false"`は従来の固定時計。normal／tomorrow／multiの試験データとrevisionは保持し、通常版やOS時計は変更しない。固定時計の通知はプレビューに限定し、実時計モードで未来分だけAlarmManagerへ登録する。

`flows/notification-smoke.yaml`は専用QAのサンプルA・日本語で実行する。launchAppの`all: unset`は許可を保持する指定ではなく、QAの許可状態を未決定へ戻す。保存操作の後に現れる実際のOS許可ダイアログを操作する。通常アプリや個人端末の権限は操作しない。予約が正数→OFF保存で0件になり、QAテストボタンが消えることをassertする。

予約の照合と手動テスト通知は、指定時刻・Dozeでの配送成功を意味しない。[通知の検証記録](work/2026-10-09-android-notifications.md)。固定時計の9ケースへ戻す場合は`gomimap.qa.real: "false"`を明示する。

## 短い実予約・再起動・Doze（#51）

[隔離配送試験](android-notification-delivery.md)はQA専用のSDK Instrumentationで未来の1件を準備し、予約後すぐ終了する。QAのReceiver起動とOS投稿時刻を専用の最大32件の記録で照合する。通常版のイベント処理はno-opでファイルを作らず、通常APKのDEXにQA記録パス・試験runnerがないことを確認する。

QT05／NT13の試験通知は「テスト」「架空」「実際のごみ出しには使えない」を明示する。GUI起動を使わず待機し、到達後にMCPで自作通知カードだけを撮影する。既存のQA希望設定は変更せず、backupとcleanupで元のplanへ戻す。省電力の強制状態も解除する。
