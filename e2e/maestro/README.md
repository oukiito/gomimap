# MaestroによるAndroidのUI試験

関連：[Issue #42](https://github.com/oukiito/gomimap/issues/42)、[方式](../../docs/android-ui-test-strategy.md)、[実行記録と画像](../../docs/work/2026-10-09-maestro-ui-poc.md)。専用API37エミュレータでOS追加、画面取得、日英の本体／ウィジェット比較とタップ復帰が成功した。実機・iOS・UI用CIはこの結果に含まない。

対象は専用エミュレータ。個人Pixelのデータ消去や権限変更をしない。対象IDを明示し、複数セッションから同時に操作しない。

## 起動準備

リポジトリ直下で公式CLIをローカル配置し、版を確認する。エージェントのコマンドには`rtk proxy`を付ける。

```sh
python3 scripts/install_maestro.py
python3 scripts/maestro_runtime.py --version
python3 scripts/check_maestro_mcp.py
```

CLIは2.11.0、公式archive SHA-256を固定。ホスト側のSDK／JDKは`app/android/local.properties`と`GOMIMAP_ANDROID_SDK`／`GOMIMAP_JAVA_HOME`で指定する。起動時だけ環境変数を設定し、グローバル設定を変更しない。

MCPは`python3 scripts/maestro_runtime.py mcp --no-viewer --working-dir <リポジトリ絶対パス>`をSTDIOサーバーとして登録する。`.codex/config.toml`は個人の絶対パスを含むためGit対象外。Codexの再起動後に提供ツールと対象エミュレータを確認できた。別の環境でも接続後の一覧・画面を調べ、承認ポリシーに従う。

## 手順

1. 専用エミュレータへ新しいAPKをインストールして起動する。
2. `setup-area.yaml`で日本語・サンプルAを選ぶ。初回のウィジェット画面と実際のOS追加確認をMCPで検査し、表示された確認操作へ進む。未確認の固定座標や確認文言を使わない。
3. 実際にウィジェットが1つ配置されたことを確認して、本体の今日を開く。
4. `app/`から次を実行し、現在時刻の期待値を取得する。日付・締切を跨いだ場合は取り直す。

```sh
flutter test --no-pub tool/maestro_expectation_test.dart
# 英語を選んだ場合
flutter test --no-pub tool/maestro_expectation_test.dart --dart-define=GOMIMAP_MAESTRO_LOCALE=en
```

5. `.tooling/maestro-results/expectation.json`の`env`を、MCPの`run`へ渡す。`device_id`は専用エミュレータ、`files`は`e2e/maestro/flows/widget-smoke.yaml`を指定する。
6. A01本体、A02ウィジェット、A03復帰後のassertと画像を確認する。Flowが存在すること・要求受理・モデル読み込みの成功だけで合格にしない。

言語変更も試す場合、5のファイルを`language-widget-smoke.yaml`へ変更する。`EXPECTED_LOCALE`の言語を選び、その後同じ比較Flowを実行する。反対の言語から変更して試し、終了後は選んでいた言語へ戻す。試験対象はサンプルAで、実地区へ推測で対応付けない。

テストは本体とネイティブの実画面の日付・地区・種類、ウィジェットの締切を同じ期待値と比較する。FlutterのKeyとは別のSemantics IDを使い、画像は本体カードと自作ウィジェットへ絞る。PNGは`.tooling/maestro-results/<RUN_ID>/A01-app.png`・`A02-widget.png`・`A03-returned-app.png`に保存する。現在の時計を使うSmokeで、仮の試験時計による締切／0時再現を実装したものではない。

締切・0時の固定時計試験は別のQA APKと`clock-step.yaml`を使う。[QAの手順](../../docs/qa-clock.md)と[独立したケース期待値](clock-cases.json)を参照。通常SmokeとQAを同じapplication IDにしない。複数締切は本文をスワイプして追加PNGへ保存する。

Flowは`clearState: false`・`stopApp: false`で地区と配置を保持する。権限の`all: deny`は専用エミュレータ限定の条件で、個人端末へそのまま実行しない。OSの確認文言は端末ごとに再検査する。

Maestroの結果・画像・ログは`.tooling/`、`build/`、`.maestro/`などGit対象外に置く。クラウド・追加AI解析は有効にしない。秘密や私物画面の画像を公開PRへ送らない。
