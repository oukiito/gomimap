# 開発用データのCloudflare初回配信

日付：2026-10-08（Asia/Tokyo）。関連：[Issue #26](https://github.com/oukiito/gomimap/issues/26)、G10・G11。

## 初回配信前の確認

専用のGit対象外ファイルから読み、Cloudflare公式APIでアカウントトークンがactive、workers.devのアカウントサブドメインが登録済み、対象`gomimap-data-dev`が未作成であることを確認した。秘密の値・アカウントID・token IDは公開記録に含めない。

Python標準ライブラリでRESTのアセット登録・アップロード・Worker作成を行う初回専用CLIと、開発／fixtureのmanifestを実装。アプリと同じDart検証に成功した自作JSON・manifest・GPL本文の3ファイルだけを生成した。新しいパッケージ・SDKなし。公開データ・環境変数へAPIキーを渡さない。

ローカルでPythonの境界・失敗系テストと実際のDart検証・生成を確認した。テストは別アカウント環境変数、秘密の反射を含むAPIエラー、上書き拒否、途中失敗、改変、応答方針を含む。CIでは完全なGit履歴から生成できることも確認する。実データ、端末HTTP更新、定期ジョブ、R2、ロールバック・旧版保持は未実装。初回コマンドの検証方法と制限は[配信手順](../cloudflare-data.md)へ記録。

この時点ではまだ公開デプロイをしていない。CIと初回公開後の照合結果は後続の記録へ追記する。

文書読者AIが会話履歴なしで範囲・実行順・秘密の扱いを確認した。以前の「Workerを手動で先に作成する」案は、既存Workerを拒否する現CLIと矛盾するため削除した。これは文書読解の確認で、コード承認・人の検証ではない。

## 最初の実配信で確認した不具合

[PR #27](https://github.com/oukiito/gomimap/pull/27)と[必須CI](https://github.com/oukiito/gomimap/actions/runs/37655040429)の成功後、mainから実行。アセット登録でCloudflareが空Workerを作成し、公開前の再確認がHTTP 404／10222（版がないため設定がない）を返して停止した。これは認証失敗ではなく、空Workerを自分で作った途中状態と未作成を区別していなかった実装の問題。

対象Workerは2026-10-08 01:52:53 JSTに作成され、公開版なし・public route無効をAPIで確認した。公開成功とは報告していない。対象ID・作成時刻・アカウントfingerprint・fixture checksumをローカルの復旧記録へ固定し、同じ未公開Workerだけを再開できるよう修正した。公開済み・他アカウント・別データ・ID／名前／作成状態の変更は拒否する回帰テストを追加した。APIキーと識別子そのものは公開記録に含めない。

## 再開と公開照合の完了

[PR #28](https://github.com/oukiito/gomimap/pull/28)と[必須CI](https://github.com/oukiito/gomimap/actions/runs/37656763417)の成功後、mainの`bb414375ccdc19c8e8509375a1ff5e3bb90ec4b5`から再開した。Cloudflareのデプロイ時刻は2026-10-08 02:12:26 JST。公開ルート有効、previewルート無効、Workerのobservability無効をAPIで読み戻した。Cloudflareの運用ログ全般が存在しないことを意味しない。

最初の公開照合ではPython標準User-AgentがHTTP 403／Cloudflare 1010で拒否された。用途とリポジトリを明示した`gomimap-data-verification/1.0`では取得できたため、その識別を通常・条件付き要求へ付けるよう修正した。ブラウザ偽装・安全設定の解除・再デプロイはしていない。

[公開manifest](https://gomimap-data-dev.ouki-ito.workers.dev/manifest.json)と版付きfixture、GPL本文の3ファイルが元と完全に同じバイトであることを正式の`verify`コマンドで確認した。fixtureは17,670 bytes、SHA-256は`bc6b36163774195cc3e0f35f251d8d6d9a832d13e020e73847a638f5f4e6a850`。`sourceCommit`は元JSONの`04abf0a2a0b1f24b903b831f48ef8bdae8c50a03`で、デプロイcommitと区別する。

Content-Type、CORS、nosniff、manifestの再検証・JSONのimmutable、ETagによる304、`/missing.json`・`/private/cloudflare.env`・`/.env.local`の404も実測で成功。ローカルPython全36テストが成功。アプリは同梱データを使っており、HTTP更新・端末DB・本番データ・取得／配信／監視の定期ジョブはまだ接続・稼働していない。

Codex内ブラウザでは公開URLが`ERR_BLOCKED_BY_CLIENT`になり、画面の証拠は取得できなかった。これはそのブラウザでの観察の制限として残し、CLIのHTTPS・全バイト一致の検証と混同しない。

初回Adminはこの確認時点では有効。メンテナーへ、`gomimap-data-dev`限定Editor・30日を候補としたトークンを専用ファイルへ保存するよう依頼した。新しい認証の確認後に初回Adminを失効する手順で、交換済みとは記録していない。CLIにはトークン管理権限を付けていない。

公開後の文書を読者AIが再読し、空Worker復旧と公開版更新、fixture公開とアプリ未接続、CLI照合とブラウザ制限、未完了のトークン交換が区別できることを確認した。人やコードの承認ではない。
