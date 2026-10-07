# 開発用JSONのCloudflare配信

状態：2026-10-08。[Issue #26](https://github.com/oukiito/gomimap/issues/26)。初回配信・生成・認証確認・公開内容の照合を実装し、[開発用manifest](https://gomimap-data-dev.ouki-ito.workers.dev/manifest.json)を公開した。元データの完全なバイト一致、応答方針、条件付き取得、秘密パス404を確認済み。途中の空Workerを固定した復旧記録で再開した経過は[作業記録](work/2026-10-08-cloudflare-data.md)へ残した。実データ、アプリのHTTP更新、定期取得・公開・監視は後続。[保存設計](data-storage.md)、[認証の準備](cloudflare-setup.md)を参照。

## 公開するもの

対象Workerを`gomimap-data-dev`に固定し、Workers Static Assetsへ自作のschema-1 fixtureだけを配置する。Python標準ライブラリで公式REST APIを使い、新しいSDK／Wranglerパッケージは導入していない。公開アセットへの要求と保存は追加料金なしだが、存在しないパス等でWorkerコードが動く要求は別の制限・料金になる。[公式料金](https://developers.cloudflare.com/workers/static-assets/billing-and-limitations/)

| 公開パス | 内容 |
| --- | --- |
| `/manifest.json` | 開発／fixtureの印、自治体ID、版、サイズ、SHA-256、有効期間、元のGit commit、GPLの参照 |
| `/datasets/demo-toshima/toshima-demo-v1.<SHA-256>.json` | `data/datasets/fixtures/toshima-demo-v1.json`と同じバイト |
| `/LICENSE.txt` | リポジトリのGPL本文 |

`sourceCommit`はcanonical JSONを最後に変更したcommitで、Workerのデプロイcommitとは別。文書だけの更新でmanifestが変化せず、あとから同じ配信を検証できる。デプロイcommit・CI・公開照合は[作業記録](work/README.md)へ残す。manifest自体はschema-1の製品データではなく、`manifestVersion: 1`の配信案内。`kind: fixture`を省略しない。

ファイルの一覧はコードで明示する。生成フォルダー全体をアップロードせず、`.env`、`private/`、未承認の原文、アプリビルド、既存の余分なファイルを走査しない。内容のSHA-256をURLへ入れ、同一URLで別のバイトを配信しない。manifestは毎回再検証、版付きJSONは長期キャッシュ・immutableとする。CORSは認証なしで読む公開データだけに適用する。

## 実行手順

リポジトリ直下・完全なGit履歴を持つcheckoutから実行する。浅いcloneは最後に元JSONを変更したcommitを確定できないため拒否する。Dartは[開発手順](development.md)の固定SDKを使用し、PATHへ設定するか`--dart /path/to/dart`を指定する。以下は一般の開発者向けコマンドで、エージェントは全実行へ`rtk proxy`を付ける。

```sh
# Cloudflareへ接続せず、アプリと同じDart検証を通して公開候補を生成
python3 scripts/cloudflare_data.py prepare

# 専用ファイルを読み、トークンとworkers.devを読み取り確認
python3 scripts/cloudflare_data.py check

# 必須CIに成功してマージされた、変更のないmainで初回デプロイ
python3 scripts/cloudflare_data.py deploy

# 途中の空Workerだけを、固定したローカル復旧記録で再開
python3 scripts/cloudflare_data.py resume

# 公開済みのバイト・ヘッダー・条件付き要求・404を検証
python3 scripts/cloudflare_data.py verify
```

認証の既定は`private/cloudflare.env`。ファイルは所有者のみ読める600とし、重複キー・別Worker・不正な形式を拒否する。dotenvをshellで実行せず、環境の`CLOUDFLARE_*`や共有ログインを認証に使わない。APIキーはCloudflare公式APIのAuthorizationヘッダーだけへ送り、アセット・Workerの環境変数・ログには入れない。APIが返すアップロード用の短期JWTもメモリで処理する。

初回`deploy`は既にWorkerが存在すれば停止し、権限不足や未知の404も「存在しない」と見なさない。Cloudflareはアセット登録で空Workerを作成することがある。その不変ID・作成日時・アカウントのfingerprint・JSONのchecksumを`private/cloudflare-data-receipt.json`（600）へ記録する。`resume`はその記録と一致し、公開版が一度もなく公開ルートも無効なWorkerだけを受け入れる。別アカウント・別データ・別ID・名前変更・公開済みは拒否する。

アップロード完了後にも固定した不変IDと未公開状態を再確認する。存在確認と初回PUTの間の競合をAPI上で完全に排除するものではない。同じ名前のWorkerを同時に別処理で作成しない。復旧記録のない古い失敗は、作成時刻・未公開状態・IDを運用者が確認してからローカルに記録する。名前だけで任意の空Workerを採用したり、既存Workerを削除・強制上書きしたりしない。

元JSONの未コミット変更、Dart検証失敗、アップロード未完了では公開へ進まない。デプロイ後はmanifest・JSON・GPLの完全なバイト一致、Content-Type、CORS、nosniff、キャッシュ方針、ETagによる304、未知／秘密パスの404を確認する。公開検証に失敗した場合は、デプロイ自体を成功した利用者向け配信として報告しない。HTTPS・checksumは通信／内容の確認で、自治体の原文照合や電子署名の代わりではない。

公開照合のHTTP要求は`gomimap-data-verification/1.0`とリポジトリURLをUser-Agentへ明示し、通常取得と条件付き取得で同じ識別を使う。Python標準のUser-AgentではCloudflare 1010が返ることを実測し、識別を明示すると全照合が成功した。ブラウザを偽装したり、配信側の安全設定を無効化したりする対応ではない。アプリのHTTP更新を実装する際も、認証なしの実際のクライアントで疎通を確認する。[Cloudflare 1010の公式説明](https://developers.cloudflare.com/support/troubleshooting/http-status-codes/cloudflare-1xxx-errors/error-1010/)

## 次の工程

初回作成後は`gomimap-data-dev`限定のEditorトークンへ交換する。初回Adminトークンを失効させる前に、限定トークンでの認証確認を行う。この交換はトークン管理権限を持たない配信スクリプトでは行わず、メンテナーがダッシュボードで実施する。Workerを削除する手順ではない。[公式のWorkers権限](https://developers.cloudflare.com/workers/authorization/workers/)

既存Workerの更新・旧版保持・ロールバック、承認済みの実データ、manifestの端末検証・保存、自動配信CI、取得／差分PR／独立監視はまだない。初回配信コマンドの完成や公開中のfixtureを、これらの稼働・全国対応・豊島区の実予定として扱わない。

後続の実装・運用担当はメンテナーがG10／G11のIssueで割り当てる。原文照合、承認、障害対応と独立監視の通知先を指定してから有効化し、担当・通知先が未定の現状では定期処理を開始しない。

API仕様の一次資料：[Direct Uploads](https://developers.cloudflare.com/workers/static-assets/direct-upload/)、[Worker module metadata](https://developers.cloudflare.com/api/resources/workers/subresources/scripts/methods/update/)、[応答ヘッダー](https://developers.cloudflare.com/workers/static-assets/headers/)。2026-10-08に確認した仕様に基づく。
