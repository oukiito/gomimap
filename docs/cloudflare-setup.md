# Cloudflare配信の認証準備

状態：2026-10-08。アカウントは保有、独自ドメインは未取得。[開発用fixtureの初回配信と公開照合](cloudflare-data.md)を完了した。交換用トークンでactive・対象Workerへのアクセス・正式のcheck／verify成功を確認した。権限ポリシー自体の取得は許可されず、設定範囲をAPIで独立確認したものではない。メンテナーから初回Admin失効の完了報告を受け、初回の認証切り替えを完了扱いとした。失効自体はAPIで独立確認していない。自動配信CIは未実装。[保存設計](data-storage.md)と[運用設計](operations.md)を参照。

## 開発用の配信先

開発用JSONにはWorkers Static Assetsと`workers.dev`を候補とする。自作の架空JSONで動作を確かめ、再配布が未承認の自治体データや非公開原文は公開しない。独自ドメイン取得は開発開始の前提ではない。Cloudflareは本番用には独自ドメイン等を推奨している。[workers.devの公式説明](https://developers.cloudflare.com/workers/configuration/routing/workers-dev/)

対象Worker名は`gomimap-data-dev`。自作fixtureとmanifestを公開・照合済み。Flutter Webの試作画面を公開するWorkerとは用途を分ける。

## APIトークンを作る場所と権限

1. Cloudflareダッシュボードで対象アカウントを選ぶ。
2. **ダッシュボードで先にWorkerを作成しない**。初回CLIが`gomimap-data-dev`を作る。途中で空Workerだけが残った場合は、[固定した復旧記録によるresume](cloudflare-data.md)を使う。公開済みの場合は無理に削除・上書きせず、既存Worker更新の実装を待つ。
3. **Manage Account → API Tokens → Create Token**からアカウント所有のカスタムトークンを作る。名前は`gomimap-data-dev-deploy`など用途が分かるものにする。[トークン作成の公式手順](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)
4. 初回作成には以下の短期**Admin**設定を使う。作成後の交換用トークンには`gomimap-data-dev`だけを対象にWorkers **Editor**を付ける。Editorは既存Workerの更新・デプロイに使え、新規作成・削除はできない。現在のCLIには既存Worker更新は未実装なので、交換後も初回コマンドを再実行して更新することはできない。[Workersの権限と対象範囲](https://developers.cloudflare.com/workers/authorization/workers/)
5. ダッシュボードで`Copy account ID`を検索するか、Workers & PagesのAccount DetailsからAccount IDをコピーする。[Account IDの公式手順](https://developers.cloudflare.com/fundamentals/account/find-account-and-zone-ids/)

まだWorkerが存在しない場合、個別Worker対象のトークンは作れない。CLIで初回作成するにはWorkers製品全体の**Admin**が必要で、対象アカウントの他のWorkersも管理できる。配信コード・対象・検証方法を用意してから使い、作成後は対象Worker限定のEditorへ交換し、初回用は失効させる。初回作成をしていないのにEditorで作成できるとは扱わない。最初から全アカウント・全製品への権限やGlobal API Keyを渡す必要はない。

初回作成用を先に準備する場合の設定：

| 画面の項目 | 推奨設定 |
| --- | --- |
| Token name | `gomimap-data-dev-bootstrap` |
| Permission policies | **Start from scratch**。対象アカウントのWorkers製品へ**Admin**だけを付与 |
| Token expiration | **7 days**。初回作成後の失効・交換を優先 |
| Client IP address filtering | 固定の送信元IPを用意していなければ空欄 |
| Review token | 対象アカウントとWorkers Adminのみであることを確認して作成 |

「Edit Cloudflare Workers」は複数権限を含むテンプレートなので、この準備ではカスタムを使う。新しいWorkers Admin／Editorと古いWorkers Scripts Editを同一の権限と推測せず、表示が異なる場合は権限欄を確認してから作成する。トークン生成後の秘密画面を相談用スクリーンショットに含めない。

`workers.dev`を使う開発配信には独自ドメインのZone／DNS権限を付けない。R2の直接アップロードには別途バケット限定の認証が必要で、R2のS3キーだけではWorkerをデプロイできない。採用方式が決まる前にR2・D1・KV等の編集権限をまとめて追加しない。

Wranglerの`login`によるブラウザ認証も使えるが、現在のOAuth認証は細かい対象制限に対応しない。本プロジェクトでは対象を限定したアカウント所有APIトークンを優先する。[Wranglerと細かい権限制限](https://developers.cloudflare.com/workers/authorization/)

## ローカルで渡す

秘密の値をチャット・Issue・PRへ貼らない。リポジトリ直下の`private/cloudflare.env`へエディターで入力する。`private/`はGitの対象外で、Flutterの`.env.local`とは分離する。ローカルのこの準備では所有者だけが読める権限（macOS／Linuxでは600）の空のファイルを用意する。暗号化された保管庫ではないので、共有・同期・添付の対象にしない。

```dotenv
CLOUDFLARE_ACCOUNT_ID=ここをAccount_IDに置き換える
CLOUDFLARE_API_TOKEN=ここをAPIトークンに置き換える
CLOUDFLARE_WORKER_NAME=gomimap-data-dev
```

認証準備の連絡には秘密を含めず、保存先と完了状態だけを示す。確認時も値を画面・ログへ出さず、対象と認証結果だけを記録する。初回配信処理はこのファイルを明示的に読み、別プロジェクトの環境変数や共有ログインを使わない。`source`で実行する必要はない。[実行手順](cloudflare-data.md)で生成・認証・デプロイ・公開確認を分ける。

## GitHub Actionsへ移す場合

自動配信を実装する段階で、リポジトリの**Settings → Secrets and variables → Actions**へ`CLOUDFLARE_API_TOKEN`と`CLOUDFLARE_ACCOUNT_ID`を登録する。対象Worker限定のCI用トークンをローカル用と分ける。外部PRへ秘密を渡さず、承認済みの公開データだけを配信する。登録だけではジョブは稼働しない。[CloudflareのGitHub Actions認証](https://developers.cloudflare.com/workers/ci-cd/external-cicd/github-actions/)
