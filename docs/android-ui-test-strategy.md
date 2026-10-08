# Androidの画面取得・操作を含む自動試験

状態：Maestro 2.11.0とプロジェクト用MCPを導入。Codex再起動後に専用API37エミュレータでOS追加・画面取得・A01〜A04のassert・タップ復帰と日英の言語変更を確認した。[準備記録](work/2026-10-09-maestro-preparation.md)、[実行記録](work/2026-10-09-maestro-ui-poc.md)。UI用CI・Pixel実機のMaestro試験・時刻境界のUI試験は未実施。関連：[Issue #3](https://github.com/oukiito/gomimap/issues/3)、[Issue #7](https://github.com/oukiito/gomimap/issues/7)。実機確認は[ウィジェット記録](work/2026-10-08-android-widget.md)。

## 推奨

**Maestro CLIと公式Maestro MCP**で、画面の要素を調べて操作し、成功した手順をYAMLへ保存する。エミュレータの本体とホーム画面の比較はこの構成で確認できた。必要になった細かなウィジェット操作をAndroid UI Automatorで補う。Pixel 10 Pro／Android 17のMaestro動作を確認した結論ではない。

Maestroの公式資料はAndroid実機の操作と、FlutterのSemanticsを利用した試験を説明している。[対応プラットフォーム](https://docs.maestro.dev/get-started/supported-platform/android)、[Flutter対応](https://docs.maestro.dev/get-started/supported-platform/flutter)。MCPは画面の要素・画像取得、Flow実行を提供し、Viewerはブラウザーに端末を表示する。[公式MCPとViewer](https://docs.maestro.dev/get-started/maestro-mcp)。

scrcpyとAndroid Studioのミラーは、目視確認・手動操作の補助として使う。テスト結果の判定と再実行は、専用のテストランナーで管理する。

## 比較

| 方法 | 画面取得・操作の範囲 | ごみまっぷでの用途・選択理由 | 制約 |
| --- | --- | --- | --- |
| Flutter `integration_test` | Dartからアプリ内のタップ・入力・表示確認。画面画像の取得も可能 | 地区保存、分別検索、言語変更、画面遷移。既存Dartテストへつなぎやすい | ホーム画面・権限ダイアログ等のネイティブUIは直接操作できない |
| Maestro CLI／MCP | アクセシビリティの要素を選び、タップ・スクロール・確認・画像保存。Android実機対応 | 最初の候補。アプリ内からホーム画面までの用件をYAMLへ記録。アプリのpub依存追加は不要 | FlutterのKeyは外部から見えない。SemanticsのIDが必要。ランチャー固有の配置・縮小はPixelで検証する |
| Android UI Automator | アプリ外を含むネイティブUIの要素検索・操作・画像取得 | ウィジェット、OS追加ダイアログ、サイズ変更の細かな補完。既存Kotlin試験へ接続する | Android専用。AndroidXの試験依存と推移的依存の確認が必要 |
| Patrol | DartのFlutter試験にOS操作を追加 | Flutterの内部状態・試験時計とOS操作を一つの試験へつなぐ場合の代案 | pub・ネイティブ設定と依存が増える。固定Flutter／GradleとのPoCが必要 |
| Appium＋UiAutomator2 | WebDriver経由でネイティブ要素を操作・画面取得 | 大きな端末行列、外部の試験基盤との統合が必要な段階の代案 | サーバー・ドライバー・クライアント設定が増える。Flutterは外部に公開した要素が必要 |
| ADB | Android公式の画面取得・録画・開発コマンド | 診断用の部品。要素を待つ・合否判定する仕組みは別途必要 | 固定座標中心の操作は端末・文字サイズで壊れやすい。今回のセッションでは直接取得が拒否された |
| scrcpy／Android Studio | USB端末のミラー表示と手動操作 | 人が流れ・表示を確認する補助 | ミラーが表示された事実だけではテスト成功にならない。既存Macの操作ツールからの接続は未成立 |

根拠：[Flutter試験の範囲](https://docs.flutter.dev/testing/overview)、[integration_testの画面取得](https://github.com/flutter/flutter/blob/master/packages/integration_test/README.md)、[UI Automator](https://developer.android.com/training/testing/other-components/ui-automator)、[Patrolのネイティブ操作](https://patrol.leancode.co/documentation/native/overview)、[Appium UiAutomator2](https://github.com/appium/appium-uiautomator2-driver)、[ADB](https://developer.android.com/tools/adb)、[scrcpy](https://github.com/Genymobile/scrcpy)、[Studioの端末ミラー](https://developer.android.com/studio/run/device)。

UI Automatorの解説には古いalpha版の依存例が残っているが、[公式リリース表](https://developer.android.com/jetpack/androidx/releases/test-uiautomator)では2.4.0が安定版。導入時は安定版を固定して検証する。Appium UiAutomator2の現行系はAppium 3とAndroid API 26以上が対象のため、アプリの最低API 24を同じ構成で確認できるとは扱わない。Maestroの[iOS公式資料](https://docs.maestro.dev/get-started/supported-platform/ios)はSimulator中心で、iPhone実機の確認をAndroidと同じ方式で約束しない。

## AIによる探索と回帰試験

| 段階 | 動作 | 合否の根拠 |
| --- | --- | --- |
| 探索 | MCPで現在の画面構造を読む。必要なときだけ画像を取得。操作後は要素を読み直す | 操作要求が受理されたことと、画面へ反映されたことを分ける |
| シナリオ化 | 成功した操作をYAMLのFlowへ保存し、Issue・W／S／TのIDへ対応付ける | 初期状態、操作、期待する文字・日付・地区・対象画面を明示 |
| 回帰 | 同じFlowを再実行。画像・結果XML・失敗ステップを保存する | 表示条件のassertと画像が揃って成功。欠落・接続切断・不安定な待機は未確認／失敗 |
| 評価 | AIが画像を見て文字切れ・重なり等を指摘。人の観察も継続 | AIの判断を独立した人の承認や利用者の使いやすさの実証と扱わない |

MCPツール名は版によって変わるため、接続後の提供ツールを確認する。調査時の資料では`inspect_screen`・`take_screenshot`・`run`・`open_maestro_viewer`を説明している。旧資料の`tap_on`等がそのまま存在すると推測しない。実端末IDを明示し、複数セッション・端末から同時に操作しない。

## 接続準備の案

現在のMacではAndroid SDKと付属JDK、USBのPixel接続によるSDK試験は確認済み。Maestro CLIは2.11.0を導入済み。Codexの再起動後に`list_devices`・`inspect_screen`・`take_screenshot`・`run`を使い、専用エミュレータを明示してPoCを実行した。

1. 画面取得・操作が許可された試験環境と対象端末を確認する。
2. [公式手順](https://docs.maestro.dev/maestro-cli/how-to-install-maestro-cli)でMaestroを導入し、版を固定する。要件はJava 17以上。導入結果は準備記録へ保存した。
3. `JAVA_HOME`・Android SDK・Maestroの実行パスを、その試験環境の設定へ指定する。グローバルな他プロジェクトの設定を変えない。
4. CodexへローカルSTDIOサーバーを登録する。[OpenAI公式MCP設定](https://developers.openai.com/codex/mcp)はプロジェクト範囲の`.codex/config.toml`も説明している。以下は汎用構成例。実際の登録は個人パスを含むGit対象外の設定と、プロジェクト内の起動スクリプトを使用した。

```toml
[mcp_servers.maestro]
command = "/path/to/maestro"
args = ["mcp"]

[mcp_servers.maestro.env]
JAVA_HOME = "/path/to/jdk"
ANDROID_HOME = "/path/to/android/sdk"
MAESTRO_CLI_NO_ANALYTICS = "true"
```

公式の一般的なCLI登録例は`codex mcp add maestro -- maestro mcp`。この例はユーザー範囲の設定を変える可能性があるため、本プロジェクトでは範囲を確認して使う。Desktopでの設定・接続の再読み込みは[Maestro公式のCodex手順](https://docs.maestro.dev/get-started/maestro-mcp)を参照。既存セッションへ即座にツールが追加されるとは扱わず、接続後に提供ツール・対象Pixel・画面構造の取得を確認する。

## 最初のPoCと受け入れ条件

| 試験ID | 対象・手順 | 期待する結果・理由 |
| --- | --- | --- |
| A01 | 専用試験環境の地区保存済み画面で、今日の予定を取得 | 本体の地区・日付・状態をassertし、実画面PNGを保存。モデルの読み込み成功との違いを確認 |
| A02 | Homeへ戻り、既存の試験用ウィジェットを調べる | 表示対象日・地区・種類・締切、今日／次回のラベルが本体と一致。根拠はW01・02・04・12・14 |
| A03 | 試験用ウィジェットをタップ | 本体の今日へ到達し地区を保持。検索語の保持は別の操作試験で確認する。根拠はW07 |
| A04 | 言語を変え、アプリからHomeへ戻る | 本体とウィジェットが同じ言語。検索対象を文言ではなく固定IDで選ぶ |
| A05 | 専用試験環境で2×2・文字200%・長い訳へ変更 | 日付・地区・予定が読め、スクロールで全内容が確認できる。根拠はW04・05 |
| A06 | 本体とAndroidの双方へ同じ試験時刻を注入し、締切直前・ちょうど・経過・0時を進める | 今日の未締切区分→次回の切替。今日／次回の不明を飛ばさない。根拠はW13〜16 |
| A07 | 専用環境で追加・取消・スキップ・再起動・削除後の再追加を実行 | 配置と要求を区別し、通常起動で再提案しない。根拠はW08〜11 |

A01〜A03の1本と日英のA04が専用エミュレータで成功した。A05の200%・他の長い訳、A06の時刻注入、A07の取消等は残る。Maestroで扱えない操作が生じた場合はUI Automatorを検討し、実際の描画を確認できなければ成功とはしない。

`ValueKey('today-schedule')`等はDartの試験用で、外部ランナーから見えるIDではない。PoC用の`Semantics(identifier: ...)`を操作・予定要素へ追加し、10言語で固定の識別子を使う。読み上げの日本語等のラベルは保持し、利用者にテストIDを見せない。[MaestroのFlutter識別子](https://docs.maestro.dev/get-started/supported-platform/flutter)。

A06の本体用`clock`注入だけではネイティブウィジェットの時刻は変わらない。専用ビルドでネイティブにも試験時計を用意し、同じ時間帯を選ばせる必要がある。実装は未着手。OS時計を個人端末で変更して再現しない。AIのテストが実時間を読むだけでは日付境界の再現試験にならない。

## 成果物・実行場所

Maestroは[結果XML／HTML・スクリーンショット等](https://docs.maestro.dev/maestro-flows/workspace-management/test-reports-and-artifacts)を保存できる。テストのFlowはGitで管理し、未確認の画像・端末ログはGit対象外に置く。採用時は失敗ステップ・対象ビルド・データ版・時刻・言語・端末モデルと画像を対応付ける。

- 最初はローカルの許可された環境でPoC。クラウド契約・外部アップロード・LLM画像評価は初回の条件へ入れない。
- PRの反復確認は専用エミュレータを候補とする。手元Pixelはローカルで端末を確認して実行する。現在の必須CIは`app`で、UI実機ジョブは未設定。
- 初回設定のやり直し・権限・通信・言語・文字サイズの変更は専用環境で行う。個人Pixelの設定・配置を無断で消さない。
- `launchApp`は既定で権限を許可する仕様がある。試験用APKで権限状態を明示する。[Maestro起動設定](https://docs.maestro.dev/reference/commands-available/launchapp)。Appiumも`noReset`等を明示し、データ保持を前提にする。[Appium設定](https://github.com/appium/appium-uiautomator2-driver)。
- 私物ホーム画面の通知・他アプリ・端末IDを公開画像へ含めない。対象ウィジェットだけの画像を作れるかもPoCで確認する。全体の画像は非公開で保存する。
- [Maestroの環境変数](https://docs.maestro.dev/maestro-cli/environment-variables)にanalytics無効化がある。クラウド送信や追加AI評価を有効にした場合は別途費用・送信内容を確認する。

## ライセンスと費用

Maestro CLI、Patrol、Appium、scrcpyの各プロジェクトはApache-2.0を採用している。[Maestro](https://github.com/mobile-dev-inc/Maestro/blob/main/LICENSE)、[Patrol](https://github.com/leancodepl/patrol/blob/master/LICENSE)、[Appium](https://github.com/appium/appium/blob/master/LICENSE)、[scrcpy](https://github.com/Genymobile/scrcpy)。これは各プロジェクトの原文確認で、将来選ぶ版の推移的依存・ネイティブ成果物まで監査した意味ではない。[ライセンス記録](licenses.md)の導入前検査に従う。

まずローカルのOSS構成を候補とし、有料クラウド・AI評価の契約はしない。クラウドサービスの費用や利用条件はコードのライセンスとは別に調べる。スクリーンショットを毎操作LLMへ送ることを回帰試験の必須条件にせず、assertで判定し、重要な画面や失敗時に絞って画像を確認する。

## 実行権限の扱い

調査時に個人PixelへのADB直接キャプチャは自動承認レビューで拒否され、再試行していない。今回の画面操作は、新たに提供されたMaestro MCPで専用エミュレータを対象に実行した。MCP接続だけで他の対象への操作許可が得られるとは扱わず、各環境の対象・実行条件を確認する。

## 準備したファイル

[Flowと実行手順](../e2e/maestro/README.md)、`scripts/install_maestro.py`、`scripts/maestro_runtime.py`を追加した。固定ID・読み上げ・クリック動作の理由は[準備記録](work/2026-10-09-maestro-preparation.md)、実画面の合否と修正は[実行記録](work/2026-10-09-maestro-ui-poc.md)へ分けて保存した。
