# 人口順位4〜10の一次調査

2026-10-10／Codex／[Issue #73](https://github.com/oukiito/gomimap/issues/73)。公式入口と反例候補の確認で、MR01〜09の詳細票の完了ではない。数値と順序は[一覧](README.md)。検索で見つかった旧資料を現行日程へ採用しない。全件とも製品実装開始不可・収集日データの公開不可、問い合わせ未送信、監視未稼働。

| 順位・自治体 | 公式の確認先・今回確認した点 | 次の調査／未解決 |
| --- | --- | --- |
| 4 札幌市 | [北区カレンダー対応](https://www.city.sapporo.jp/seiso/kaisyu/02_kita/index.html)。2026-09-01更新、条・西○丁目等から番号を選ぶ。版に2026年9月〜2027年9月等の期間がある | 条／丁目と町番地の別体系、全区・全番号・期間差。月めくり版と通年版を無条件に同一視しない |
| 5 福岡市 | [中央区の2026年4月案内](https://www.city.fukuoka.lg.jp/shicho/koho/fsdweb/reiwa8_dayori/0401/40chuo1606.html)。持ち出し日の日没〜午前0時を案内 | 全市の地区別対応と締切、集合住宅、夜間の持ち出し日。朝の時刻を全国共通にしない |
| 6 川崎市 | [収集計画課](https://www.city.kawasaki.jp/300/soshiki/7-6-2-0-0.html)に2026-04-01の高津・宮前区一覧の導線。[多言語地域別一覧](https://www.city.kawasaki.jp/300/cmsfiles/contents/0000040/40087/collectionday2.pdf)にプラスチックの段階導入の記述 | 原PDFは検索索引の記述まで。全区の現行リンク・適用日・改定、古い一覧との置換を確認する |
| 7 神戸市 | [収集日のFAQ](https://faq.city.kobe.lg.jp/faq/show/3843?site_domain=default)、[場所のFAQ](https://faq.city.kobe.lg.jp/faq/show/669?site_domain=default)、[ステーション案内](https://www.city.kobe.lg.jp/a04164/kurashi/recycle/gomi/shisetsu/cleanstation/cleanstation/index.html)。地域管理と実際の利用場所の確認が重要 | 住所検索で一意にならない条件、利用世帯の範囲、看板と表の差、年末年始。最寄りの地点へ割り当てない |
| 8 京都市 | [収集日マップ](https://www.city.kyoto.lg.jp/kankyo/page/0000000509.html)、[ごみ出しルール](https://www.city.kyoto.lg.jp/sogo/page/0000246821.html)、[プラ分別の公式案内](https://kogomi.city.kyoto.lg.jp/plabunbetsu/)。市収集と民間業者の集合住宅で案内が分かれる | 建物がどちらの方式か、品目別の実施主体、管理者へ確認すべき範囲。市の表へ強制適合させない |
| 9 さいたま市 | [収集日カレンダー案内](https://www.city.saitama.lg.jp/001/006/010/003/p042612.html)。地区で選択。通常と、もえるごみの早朝地区で時間案内が異なる | 早朝地区の範囲と地域の決まり、カレンダーの版／実日付。朝6時通知が既に遅い地域を見落とさない |
| 10 広島市 | [収集日FAQ](https://www.city.hiroshima.lg.jp/faq/gomi-kankyo/1001569/1002050.html)、[公式オープンデータ候補](https://hiroshima-opendata.dataeye.jp/datasets/1338)。年度表と地区・品目・日付のCSV案内がある | CSVのライセンス・原本・地区と住所の対応・年度境界・訂正版を精査。CSVがあるだけでGPS自動設定できるとしない |

MR01〜02は所在・実施主体の一部のみ、MR03〜06は上表の構造候補のみ、MR07は共通設計、MR08の全行期待値とMR09の運用は未完了。取得・保管・加工・LLM送信・配布の各利用条件は個別に未確認。原資料全体は本リポジトリへ収録しない。

都市部以外は[反例候補の一次調査](representative-regions.md)まで。町村・広域組合・離島の全体調査は未完了。全国候補リストがあることと全国の方式を網羅したことは別である。
