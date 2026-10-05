# GitHub公開・開発運用

## 公開・運用状況

2026-10-06時点で、ローカルGit、GPLのライセンス本文、共通文書、Issue・PRテンプレート、Flutter用CI定義を用意しています。GitHubリモート、Issue・PR、保護ルール、GitHub上のCI実行、定期更新ジョブは未設定です。

公開予定先・メンテナーは`oukiito/gomimap`／`@oukiito`です。作業ブランチは`feat/local-app-poc`。公開済みのリポジトリURLや架空のIssue番号は記載しません。

投稿者向けの手順は[CONTRIBUTING](../CONTRIBUTING.md)、非公開の脆弱性報告は[SECURITY](../SECURITY.md)を参照してください。本書はメンテナー向けの運用方針です。

## GitHub認証

このプロジェクトでGitHubへアクセスするときは`oukiito`を使います。アカウントごとに`GH_CONFIG_DIR`を分け、複数セッションで共有の`gh auth switch`に依存しない方針です。次は初回認証の例で、実際の認証は未実施です。

```sh
GH_CONFIG_DIR=~/.config/gh-gomimap gh auth login
GH_CONFIG_DIR=~/.config/gh-gomimap gh auth status
```

以後もGitHub API操作には同じプロファイルを明示します。操作前にアクティブなユーザーが`oukiito`であることと、対象リポジトリを確認してください。環境に`GH_TOKEN`／`GITHUB_TOKEN`があると保存済み認証より優先されるため、意図しないアカウントを上書きしていないかも確認します。

この設定は`gh`のIssue・PR等のAPI操作に適用します。Gitのpush認証はリモートURL・SSH鍵／資格情報ヘルパーの設定を別に確認します。`user.name`／`user.email`はコミット著者の設定で、認証アカウントの選択とは異なります。

トークンはOSの資格情報ストアを使い、リポジトリやチャットへ貼りません。`.env.local`はFlutter用の公開してよい設定だけに使い、GitHubトークンをFlutterのビルド設定へ渡しません。

## 初回公開で設定するもの

1. 正しいアカウントと公開先を確認し、公開対象・履歴・秘密情報・第三者の権利表示を点検する。
2. リポジトリを作成・接続し、公開可能な自作物を送信する。
3. [開発計画](roadmap.md)の作業を実Issueへ移し、対応するURLを記録する。
4. GitHub Actionsを試験PRで実行し、実際のチェック名を確認して保護ルールを設定する。
5. Private vulnerability reportingを有効にし、非公開報告の窓口が利用できることを確認する。行動規範の相談用窓口も整える。

[LICENSE](../LICENSE)と[COPYING](../COPYING.md)のGPL-3.0-or-laterは自作部分に適用します。依存ライブラリ、素材、自治体資料の扱いは[ライセンス調査](licenses.md)で確認します。完成バイナリ・ストア配布の監査は未完了です。

## IssueとPR

- Issueには利用者の困りごと、対象／対象外、仕様へのリンク、受け入れ条件、検証方法を記載する。
- ラベル案：bug、feature、data、docs、security、priority:high、blocked。milestone案：Foundation、Toshima Beta、Public v1。
- 原則1つの目的につき1つの小さなPR。ブランチ名はissue番号と短い目的にする。
- PRは関連Issue、変更後の挙動、検証結果、影響・戻し方を書く。未実施のテストは未実施と記録する。
- データ更新PRは出典と適用日、日程・受入条件の前後差分、人による確認欄を必須にする。
- 不具合を直すついでの大規模リファクタリングや、根拠のない機能追加は別Issueにする。

提供したテンプレート：[機能](../.github/ISSUE_TEMPLATE/feature.md)、[不具合](../.github/ISSUE_TEMPLATE/bug.md)、[データ訂正](../.github/ISSUE_TEMPLATE/data-correction.md)、[文書修正](../.github/ISSUE_TEMPLATE/docs.md)、[PR](../.github/PULL_REQUEST_TEMPLATE.md)。ラベルの作成やIssueの登録はまだ行っていない。

## レビューとマージ

人が重要な自治体情報変更を確認する。コードも目的・品質・セキュリティ・テストを確認してからマージする。AIレビューは補助であり、独立した人の承認として数えない。

メンテナー1人の場合、PR作成者本人には承認制限があるため、「他の人の承認1件」を必須にして永続的にマージ不能にしない。必須CIとPR経由を基本にし、1人の確認記録を残す。複数メンテナー体制になったら独立レビューをルール化する。

## CIの設計案

現行定義はDartの整形・静的解析・Flutterテスト・Webビルド。文書変更はローカルリンクと公開物の内容も確認する。取得処理導入後はPythonの取得／スキーマテスト、ビルド環境準備後は両OSのビルド確認を追加する。通知・ウィジェット・位置情報の実機試験はCIだけで代替しない。

データCIでは区域例外、月内曜日、有効期間、参照整合、受入条件、休止・移転、利用条件の確認状態を検証する。基準データをコピーしただけの無意味なテストにしない。

外部PRには秘密情報を渡さない。取得ジョブ、候補PR作成、公開処理の権限を分離し、最小権限・依存関係固定・Actionsの信頼性確認を行う。本番署名鍵、LLMキー、地図キーをテストデータへ混ぜない。

## 公開物とプライバシー

| 公開できる候補 | 条件確認や分離が必要 |
| --- | --- |
| 自作コード、設計文書、架空の試験データ | 自治体PDF・画像・抽出データ、地図由来の住所・座標 |
| 原文の短い要約、根拠URL、変更の説明 | 利用者の住所・位置履歴・撮影画像、取得元の全文スナップショット |
| 設定の見本、依存関係・ライセンス一覧 | APIキー、認証トークン、署名鍵、サービスアカウント、課金情報 |

添付の参考画像をアプリ素材として転載する許可は確認していないため、リポジトリに収録しない。自治体ロゴ・キャラクターも同様。公開資料の存在と自由な再配布を同一視しない。

ログイン不要でも地図SDK等が外部通信する。実際に採用したSDKと送信内容を調べ、プライバシー方針・ストアの申告に反映する。アプリの一般公開前に問い合わせ・セキュリティ報告経路を用意する。

## GitHubリポジトリの初回公開前

- リポジトリの現在ファイルだけでなく履歴にも秘密情報がない。
- ライセンスの適用範囲、第三者の権利表示、データの利用条件と出典表示が整っている。
- READMEの実装状態が事実と一致し、非公式アプリであることが分かる。
- 文書段階に対応した必須CIと保護ルールを設定・確認する。GitHub上で初めて試せるチェックは、初回公開直後に試験PRで検証し、本実装のマージ前に有効化する。

## データ配信・ストア一般公開前

- アプリ・データに対応した必須CI、保護ルール、更新ジョブ、独立監視を実際に試験している。
- データ訂正とロールバックの手順を試し、通知先に試験通知が届いている。
- ストア公開の判断には[プロダクト仕様](product-spec.md)の一般公開条件も満たす。

G01の設計文書・コードの公開は、G10の運用基盤完成を待つ必要はない。未稼働の機能はREADMEに明記する。

## ドキュメントの配置

[ドキュメント一覧](README.md)を入口とし、共通文書はリポジトリルート、詳細な仕様・設計・運用は`docs/`、テンプレートとCIは`.github/`へ置きます。仕様は目的、READMEは現状、CHANGELOGは利用者に関係する変更を扱います。

参考：[GitHubの貢献ガイド配置](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/setting-guidelines-for-repository-contributors)、[Issueテンプレート](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository)。
