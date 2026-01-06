# 無料塾向けLINE出欠管理とダッシュボード

Next.js（App Router）と Supabase を使って、無料塾の出欠申請フローとダッシュボードを実装するプロジェクトです。現在は初期セットアップ段階で、今後のマイルストーンで API・ダッシュボード・LIFF/モックフロントを追加していきます。

## 開発環境の準備

1. Node.js 20 系と npm を利用してください。
2. プロキシ越しの環境では `HTTP_PROXY` / `HTTPS_PROXY` を適切に設定したうえで依存パッケージを取得します。
3. 依存をインストールし、開発サーバーを起動します。

```
npm install
npm run dev
```

`package-lock.json` はネットワーク制限下で生成できないため依存解決情報のみを記載しています。実際の環境で `npm install` を実行すると完全版に更新されます。

## ディレクトリ構成（抜粋）

- `src/app` : Next.js App Router のエントリ。
- `src/app/dashboard` : ダッシュボードのプレースホルダー。
- `src/app/api` : API ルートの配置場所（現在は `/api/hello` のみ）。
- `public/` : 公開静的ファイル。
- `.devcontainer/` : Devcontainer 設定。
- `.codex/` : CODEX_HOME 用ディレクトリ。

## 今後の予定

exec_plans/free-school-attendance.md に従って API、データベーススキーマ、LIFF/モック UI、ダッシュボードを順次実装します。
