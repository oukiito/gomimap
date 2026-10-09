# 権利確認済みCSVカタログの取得・変更監視

2026-10-10。[Issue #58](https://github.com/oukiito/gomimap/issues/58)、#53の1／5番の部分対応。実際のごみ日程・受付条件・本番データ更新を提供した記録ではない。

## 実装範囲

対象を権利確認済みの公共施設CSV／オープンデータ一覧の2件へ固定した。許可が取り消された・対象が消えた場合、対象を減らして成功とはしない。archive allowed・current reference・レビュー済み列を検査し、未確認HTML／PDF12件へHTTPを送らない。

CSVの取得はUser-Agent、20秒timeout、最大3試行、2MiB上限、redirect禁止。CSV列と行数・本文hashを照合し、owner専用の私有cacheへ原子的に保存。304は完全な検証済み本文と照合する。キャッシュ破損・空本文・構造変更・HTTP失敗を変更なしにしない。最後の試行と直近成功を分ける。

候補はsource ID、旧hash、取得メタデータのみ。許可・出典の適用範囲・本番承認は変更しない。候補適用は原資料を審査してから行い、旧hashが違う場合を拒否する。本文、認証キー、利用者情報はIssueや公開記録へ含めない。

## 実際の取得

| 対象 | 取得・再取得 | 本文bytes | データ行 | 比較 |
| --- | --- | --- | --- | --- |
| 公共施設CSV | 成功 | 81198 | 558 | 登録したhashと一致、unchanged |
| オープンデータ一覧 | 成功 | 1485 | 13 | 登録したhashと一致、unchanged |

[metadata結果JSON](evidence/2026-10-10-cleared-catalog-monitor.json)。この558件は施設の数であり、資源回収拠点数ではない。未確認の収集曜日PDFを明示指定した試験はHTTP前のfailed・complete=falseとなった。

## Workflowと確認の層

source-monitor.ymlに週次月曜03:17日本時間／手動起動を設定した。contents:read／issues:write、同時実行を直列化、失敗と変更はbotの1つのIssueに集約。同じfingerprintや正常時はIssueを書き換えない。通知文は未確認原文やremote errorを貼らず、runのリンクへ誘導する。失敗は最終job outcomeにも残す。

この記録の作成時はローカル取得・模擬APIの検証が完了した段階。取り込み後にGitHubで手動workflowを実行し、active／run／外部health結果を[Issue #58](https://github.com/oukiito/gomimap/issues/58)に追記する。初回定時実行の到達・実障害の通知到達を設定だけで合格にしない。

Python73件PASS。新規21件で304・同本文／異ヘッダー、空／不正／構造変化、許可撤回・消失・未レビュー列、破損cache、失敗時に直近成功保持、候補の旧hash／許可、通知の非反復／remote error非表示、外部healthの無効／失敗／期限／無関係branchを確認。破損JSONがlistの場合の初期例外は型検査を加えて再確認した。原資料・キー・正確な位置を公開していない。

新しいSDK・Python／npm／pub／Maven依存なし。Python標準ライブラリ、既存の出典validator、既存pinのactions/checkoutを使う。CSVのライセンスはCC BY2.1 JPを維持し、一般の資料へ適用を広げない。

## 継続条件

ごみ日程・分別・受付・告知の許諾、日次取得、意味差分と抽出精度、月次LLMの契約／実行、独立の監視実行基盤／通知先、承認後の実データCloudflare配信は未完了。health probeはコマンドであり、常設監視と呼ばない。OpenAIのローカル予定実行の要件を調査し、Mac／アプリONが必要な補助を常設監視の代替にしない。[公式仕様](https://learn.chatgpt.com/docs/automations?surface=app)。

#53と#10を継続し、未確認資料を勝手に公開／LLM送信しない。
