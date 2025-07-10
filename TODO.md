# AeroCache - Cache-Control Implementation TODO

## 実装済みのCache-Controlディレクティブ
- [x] `max-age` - Response directive (現在実装済み)
- [x] `expires` - Expires ヘッダーサポート (現在実装済み)

## 未実装のResponse Directives（レスポンスディレクティブ）

### 基本的なキャッシング制御
- [ ] `s-maxage` - 共有キャッシュ用のmax-age（プロキシ、CDN用）
- [ ] `no-cache` - 再検証が必要（キャッシュ可能だが使用前に検証必須）
- [ ] `no-store` - キャッシュ禁止（プライベート・共有キャッシュ両方）
- [ ] `private` - プライベートキャッシュのみ（ブラウザローカルキャッシュのみ）
- [ ] `public` - 共有キャッシュ可能（Authorization付きレスポンスもキャッシュ可）

### 再検証制御
- [ ] `must-revalidate` - staleになったら必ず再検証
- [ ] `proxy-revalidate` - 共有キャッシュでのmust-revalidate
- [ ] `must-understand` - ステータスコードを理解できる場合のみキャッシュ

### コンテンツ変換・最適化
- [ ] `no-transform` - 中間者によるコンテンツ変換禁止
- [ ] `immutable` - フレッシュな間は絶対に変更されない

### 高度なキャッシング戦略
- [ ] `stale-while-revalidate` - stale時にバックグラウンドで再検証しつつ古いデータを返す
- [ ] `stale-if-error` - エラー時にstaleなレスポンスを使用可能

## 未実装のRequest Directives（リクエストディレクティブ）

### 基本的なリクエスト制御
- [ ] `no-cache` - 再検証要求（強制リロード時に使用）
- [ ] `no-store` - キャッシュ保存禁止要求
- [ ] `max-age` - 指定秒数以内に生成されたレスポンスのみ受け入れ

### 詳細なキャッシュ制御
- [ ] `max-stale` - 指定秒数までのstaleレスポンス受け入れ
- [ ] `min-fresh` - 指定秒数以上フレッシュなレスポンスのみ受け入れ
- [ ] `only-if-cached` - キャッシュされたレスポンスのみ（ネットワークアクセス禁止）

### その他
- [ ] `no-transform` - コンテンツ変換禁止要求
- [ ] `stale-if-error` - エラー時のstaleレスポンス許可

## 実装優先度

### 高優先度（基本的なHTTPキャッシング動作）
1. [x] `no-cache` (Response) - 再検証必須キャッシング
2. [x] `no-store` (Response) - キャッシュ完全禁止
3. [x] `private` (Response) - プライベートキャッシュのみ
4. [x] `public` (Response) - 共有キャッシュ許可
5. [x] `must-revalidate` (Response) - stale時の強制再検証

### 中優先度（高度なキャッシング戦略）
6. [ ] `s-maxage` (Response) - 共有キャッシュ用max-age
7. [ ] `stale-while-revalidate` (Response) - バックグラウンド再検証
8. [ ] `immutable` (Response) - 不変コンテンツ
9. [ ] `no-cache` (Request) - 強制再検証要求
10. [ ] `max-age` (Request) - 許可する最大age

### 低優先度（特殊なユースケース）
11. [ ] `proxy-revalidate` (Response) - プロキシ用再検証
12. [ ] `must-understand` (Response) - 条件付きキャッシング
13. [ ] `no-transform` (Request/Response) - コンテンツ変換禁止
14. [ ] `stale-if-error` (Request/Response) - エラー時のフォールバック
15. [ ] `max-stale` (Request) - staleレスポンス許可
16. [ ] `min-fresh` (Request) - 最小フレッシュネス要求
17. [ ] `only-if-cached` (Request) - キャッシュのみモード
18. [ ] `no-store` (Request) - キャッシュ保存禁止要求

## 実装時の考慮事項

### パース機能強化
- [ ] Cache-Controlヘッダーの複数ディレクティブパース機能
- [ ] ディレクティブの優先順位処理
- [ ] 無効なディレクティブの適切な処理

### MetaInfo拡張
- [ ] 各ディレクティブ情報の保存
- [ ] ディレクティブベースの有効性判定
- [ ] キャッシュポリシー判定ロジック

### AeroCache API拡張
- [ ] リクエストオプションでのCache-Control指定
- [ ] レスポンスディレクティブの情報取得API
- [ ] キャッシュポリシーのカスタマイズ機能

### テスト追加
- [ ] 各ディレクティブの単体テスト
- [ ] 複数ディレクティブの組み合わせテスト
- [ ] エッジケースのテスト（無効値、競合など）

## 参考リンク
- [MDN Cache-Control](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control)
- [RFC 9111 - HTTP Caching](https://httpwg.org/specs/rfc9111.html)
- [RFC 5861 - HTTP Cache-Control Extensions for Stale Content](https://httpwg.org/specs/rfc5861.html)