# GitHub接続と初回公開

日付：2026-10-06。関連計画：[G01／Issue #1](https://github.com/oukiito/gomimap/issues/1)。

## 公開前の確認

- プロジェクト用GH_CONFIG_DIRでGitHubユーザーoukiitoとして認証済み。認証情報の保存先はOSのkeyring。
- 初回接続時に公開リポジトリoukiito/gomimapが存在し、リモートのブランチは空であることを確認。originをHTTPSで接続。
- このチェックアウト専用のGit資格情報ヘルパーで同じghプロファイルを利用。グローバル設定を変更せず、環境GH_TOKEN/GITHUB_TOKENによる上書きを避ける構成。
- コミット著者はoukiito、メールはGitHubのnoreply形式。個人メールを初回コミットへ含めていない。
- 初回コミットb810f35をローカルmainに作成。GPL、ソース、設計、共通文書、通知原文、CI定義を含む。
- 公開候補245ファイル（.gitattributes追加後）。候補内の高確度のトークン・秘密鍵パターンに一致なし。任意形式の秘密情報がないことを保証する検査ではない。
- 86パッケージのライセンス本文はGitのステージ内容でも記録済みSHA-256と一致。上流原文の改行等を保持する属性を追加。
- 文書内部リンク89件とgit diffの空白検査を確認。参照するFlutterタグとcheckoutの固定コミットは公式リポジトリに存在。
- G01〜G12のIssue本文と保護ルールの下書きをGit対象外の.tooling/github-bootstrapに準備。

## 初回の権限エラー

初回のコードpushはHTTP 403で拒否された。Issue作成も`Resource not accessible by personal access token`で拒否され、この時点ではソース送信とIssue作成はできなかった。

認証成功と書き込み許可は異なるため、トークンの対象リポジトリと書き込み権限を利用者に確認依頼した。利用者が権限を変更した後、同じプロファイルで再確認して再開した。

## 権限変更後の結果

- oukiitoの認証を再確認し、初回コミットb810f35をmainへpushした。[公開ソース](https://github.com/oukiito/gomimap)。
- G01〜G12を[Issue #1〜#12](https://github.com/oukiito/gomimap/issues)へ登録し、実URLを[ロードマップ](../roadmap.md)へ対応付けた。3つのマイルストーンと不足ラベルを追加した。
- 初回mainの[Flutter checks](https://github.com/oukiito/gomimap/actions/runs/37348261578)は成功。依存ロックの強制、整形、静的解析、Flutterテスト、Webビルドの全ステップが成功した。
- 実チェック名appと提供元GitHub Actions（App ID 15368）を確認してmainを保護した。PR経由、最新ベースへの追従、必須app、管理者にも適用、会話の解決を必須とし、force pushと削除を禁止。APIの読み戻しで確認した。
- メンテナー1人のため独立した人の必須承認件数は0件。AIによる確認を人の承認と数えない。
- Private vulnerability reportingを有効化し、GETの結果enabled=trueを確認した。[非公開報告フォーム](https://github.com/oukiito/gomimap/security/advisories/new)。テスト用の架空脆弱性は送信していない。
- 実際の運用状態に合わせて共通文書と設計文書を更新した。変更はcodex/1-github-project-setupからPRにし、PRのCI結果と完了確認をIssue #1へ記録する。

## 残る作業

豊島区の実データ・再利用条件、通知、ウィジェット、位置設定、取得・更新・監視、両OSの実機確認は未完了。行動規範の相談用の常設非公開窓口は未整備で、相談手順を行動規範に明記した。

ストア登録、一般利用者へのアプリ配布は別の作業。ソース公開をアプリの一般公開と扱わない。
