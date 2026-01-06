# 無料塾向けLINE出欠管理とダッシュボードを実装する

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries, Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds. Maintained in accordance with .agent/PLANS.md.

## Purpose / Big Picture

保護者が塾の公式LINEアカウント経由でLIFF UIから出欠を申請し、スタッフがウェブダッシュボードで申請一覧・統計・メッセージ送受信を確認できるようにする。ローカル開発ではLINE連携が難しいため、ダッシュボード内に小さく配置したリンクからLINE模擬フロントエンドを開き、同等のフローを検証できるようにする。運用コストを抑えるため、Vercel + Next.js（App Router/API Routes）+ Supabase(PostgreSQL) + TypeScript/Reactで構成し、当面は認証なしだが将来拡張を見据える。

## Progress

- [x] (2026-01-06 15:45Z) ExecPlan下書きを作成し、PLANS.mdに従う運用方針を記載。
- [ ] (2026-01-06 16:40Z) Next.js/TypeScript/Reactベースのプロジェクトをセットアップし、ローカル(devcontainer)で起動確認できる状態にする。完了部分: App Router構成のソース/設定ファイル、Tailwind設定、devcontainerと環境変数テンプレートを追加。残課題: npm registry がプロキシで403になるため依存取得・起動確認が未完。接続可能になり次第 `npm install` と `npm run dev` で検証する。
- [ ] Supabaseスキーマ（保護者・児童・出欠・メッセージログ）を定義し、適用手順と環境変数管理を整える。
- [ ] LINE LIFF用フロントエンド（本番向け）と模擬フロントエンド（ローカル検証向け）を実装し、出欠申請APIと接続する。
- [ ] ダッシュボードSPAを実装し、一覧・統計・メッセージ送受信UIを提供する。模擬フロントエンドへのリンクを目立たない形で配置する。
- [ ] 統合動作確認（ローカル／Vercel）、受入基準を満たすテスト手順を固める。

## Surprises & Discoveries

- Observation: npm registry へのアクセスがプロキシ経由で 403 を返し、`npm view`/`npm create next-app`/`curl` いずれも失敗した。
  Evidence: `curl -I https://registry.npmjs.org/` が `HTTP/1.1 403 Forbidden` を返却。npm コマンドも同様に 403 が表示された。

## Decision Log

- Vercel + Next.js(App Router) + Supabase(PostgreSQL) + TypeScript/React を採用する。理由: 無料/低コスト運用と要件適合。(2026-01-06)
- 認証は当面スキップし、ガーディアン識別は LINE userId（LIFF）または模擬UI側の入力で代替し、将来Authを挿入できるようAPI層を抽象化する。(2026-01-06)
- npm registry への接続が 403 でブロックされているため、create-next-app での自動生成を断念し、手動で Next.js + Tailwind 構成ファイルとApp Router用の初期ページを作成する方針に切り替えた。接続回復後に `npm install` で依存を取得する。(2026-01-06)

## Outcomes & Retrospective

（作業完了後に記載）

## Context and Orientation

リポジトリは初期状態（README.mdのみ）。.agent/PLANS.md と本ExecPlanを追加。開発は devcontainer で行い、CODEX_HOME は `${containerWorkspaceFolder}/.codex`。docker compose は使わず、Supabase はクラウド（無料枠想定）を使用し、DBスキーマは SQL ファイルでバージョン管理する。主要コンポーネント:
- フロント: Next.js App Router。ダッシュボードSPA＋LIFF用ページ＋模擬LINE UIページ。
- API: Next.js API Routes（/app/api/*）。Supabaseサービスキーでサーバー側データアクセス。
- DB（Supabase）想定テーブル:
  - guardians: id(uuid), line_user_id(text unique nullable), name(text), phone(text optional), created_at.
  - students: id(uuid), name(text), grade(text), created_at.
  - guardian_students: guardian_id uuid, student_id uuid (多対多).
  - attendance_submissions: id uuid, guardian_id, student_id, date(date), status(text: present/absent/late/unknown), note(text), submitted_at timestamptz.
  - message_logs: id uuid, guardian_id, direction(text inbound/outbound), body(text), sent_at timestamptz, metadata(jsonb) for LINE message idなど。
  - statsはビュー or 集計クエリで提供（別テーブル不要）。

## Plan of Work

1) プロジェクト基盤
   - Next.js 14+ (App Router, TypeScript, ESLint) を `npm create next-app@latest` で生成し、Vercelデプロイ前提の設定を追加。
   - 環境変数テンプレート `.env.example` に Supabase URL/anon/service_role、LINE関連(LIFF_ID, LINE_MESSAGING_TOKEN, LINE_CHANNEL_SECRET)、デバッグ用MOCKフラグを記載。
   - devcontainer.json で Node20 feature、.codex マウント、CODEX_HOME 設定を行う。

2) DBスキーマとデータアクセス
   - `supabase/schema.sql` に上記テーブル定義と簡易サンプルデータ（2家庭/3児童程度）を記述。
   - 適用手順: Supabase SQLエディタでファイルを流す or supabase CLI が使えるなら `supabase db push`（要環境確認）。ロールバックはテーブルDROP手順を併記。
   - サーバー側 Supabase クライアントを `/lib/supabase/server.ts` として初期化（service role key）。クライアント側は anon key で read only（LIFFも含む）。

3) API層
   - `/app/api/attendance/route.ts`: POST で guardian identity（line_user_id or mock session id）、date、student_id、status、note を受け取り insert。GET で指定日範囲・児童で取得。
   - `/app/api/guardians/route.ts`: GET で保護者と紐付児童を取得、POST で仮登録（name, children, line_user_id）。
   - `/app/api/messages/route.ts`: GET で最近の message_logs, POST で outbound メッセージを記録し LINE送信（ローカルではモック送信で message_logs だけ作成）。
   - APIは zod などでバリデーションし、将来の認証導入に備えて identity 解決を一箇所にまとめる。

4) フロント（保護者向け LIFF/モック）
   - `/app/liff/page.tsx`: LINE LIFF 用。初回起動時に line profile を取得し、未登録なら簡易登録フォーム（保護者名＋児童名リスト）。登録後、日付/児童/出欠/備考のフォームで送信。
   - `/app/mock-line/page.tsx`: ローカル・非LINE向け。line_user_id を手動入力 or ランダム発行し、LIFFと同じフォームを再利用。送信先は同じ attendance API。
   - 共通 UI コンポーネントを `components/attendance-form.tsx` にまとめ、LIFFとモックから props で挙動を切替。

5) ダッシュボード（スタッフ向け SPA）
   - `/app/dashboard/page.tsx` で SPA。機能: 出欠一覧（フィルタ: 日付/児童/ステータス）、出席率/人数集計カード、メッセージスレッドビュー（message_logsを降順表示）、モックフロントへの小さなリンクボタン。
   - 状態管理は React Query または fetch + useSWR で最小限。CSSはシンプルなUIライブラリ（例: Tailwind or minimal CSS Modules）を採用。

6) 統計・クエリ
   - サーバー側で `attendance_submissions` から集計（全体出席率、児童ごとの出席率、日別人数）。APIで返し、ダッシュボードでカード表示。

7) テストと検証
   - 単体: zod スキーマ、サーバー関数の簡易テスト（Vitest or Jest）。E2Eは Cypress/Playwright まで不要なら手動検証手順を明示。
   - ローカル検証: `npm run dev` で dashboard + mock-line を開き、サンプルデータで送信→ダッシュボード反映を確認。
   - Vercel プレビュー: 環境変数を Vercel に設定し、Supabase 本番プロジェクトに接続、LIFF ID/LINE token を設定。モックUIは本番でも隅のリンクとして残すが目立たせない。

## Concrete Steps

1. プロジェクト初期化（まだ存在しない場合）:
   - 作業ディレクトリ: リポジトリルート。
   - コマンド例:
     - npm create next-app@latest --ts --app --src-dir --eslint --tailwind --import-alias '@/*'
     - npm install @supabase/supabase-js zod
2. 環境変数テンプレート作成: `.env.local` の代わりに `.env.example` を用意し、以下を記載:
   - NEXT_PUBLIC_SUPABASE_URL=
   - NEXT_PUBLIC_SUPABASE_ANON_KEY=
   - SUPABASE_SERVICE_ROLE_KEY=
   - NEXT_PUBLIC_LIFF_ID=
   - LINE_CHANNEL_SECRET=, LINE_MESSAGING_ACCESS_TOKEN=
   - MOCK_LINE_ENABLED=true
3. devcontainer 構築:
   - `.devcontainer/devcontainer.json` を作成し、Node20 feature, CODEX_HOME, ~/.codex マウントを設定。
   - `.codex/` ディレクトリをリポジトリに保持（空で可）。
4. DBスキーマ: `supabase/schema.sql` を作成し、Supabase SQL Editor で適用。主なDDLを記載し、リレーション・ユニーク制約を定義。
5. Supabase クライアント:
   - `lib/supabase/server.ts` に service role key を使うサーバーサイドクライアントを実装（API Routes専用）。
   - `lib/supabase/client.ts` に anon key を使うクライアントを実装（LIFF/mock用）。
6. API 実装:
   - /app/api/attendance/route.ts: GET/POST with zod validation, Supabase insert/select。
   - /app/api/guardians/route.ts: 登録と紐付け取得。
   - /app/api/messages/route.ts: ログ取得とアウトバウンド送信（ローカルはスタブで message_logs 追加のみ）。
7. フロント実装:
   - `components/attendance-form.tsx` で共通フォーム。
   - `/app/liff/page.tsx` で LIFF SDK を読み込み、profile取得→登録→送信。
   - `/app/mock-line/page.tsx` で line_user_id入力フォーム＋共通フォーム。MOCK_LINE_ENABLED=falseならアクセス拒否。
   - `/app/dashboard/page.tsx` で一覧、集計、メッセージログ、mockリンクを配置。
8. 集計ロジック:
   - API側で日付範囲クエリし、全体/児童別/日別を計算するヘルパーを追加。軽量な SQL 集計 or JS 集計のいずれかを採用。
9. テスト/検証:
   - `npm run lint`, `npm run test` (設定次第) を devcontainer 内で実行。
   - ローカル: `npm run dev` → `http://localhost:3000/dashboard` で一覧・統計確認、`mock-line` で申請→即時反映を目視確認。
   - Vercel プレビューで環境変数を設定し、実際の LIFF 端末で送信→ダッシュボード反映を確認。

## Validation and Acceptance

- ダッシュボード `http://localhost:3000/dashboard` が開き、サンプルデータまたは新規送信が一覧に表示され、日付フィルタが効く。
- 模擬フロント `/mock-line` から日付/児童/出欠を送信すると、attendance_submissions にレコードが追加され、ダッシュボードの一覧・統計が更新される。
- （本番）LIFF `/liff` から同様に送信でき、line_user_id 経由で guardians と紐づく。
- message_logs のGETで最新メッセージが確認でき、POSTでアウトバウンドメッセージが記録される（ローカルはスタブ、本番はLINE送信）。
- lint/test が通過し、主要UIがSSR/SPAともにビルド成功している（`npm run build` 成功）。
- Acceptance を満たしたら、スクショを添えて完了報告。

## Idempotence and Recovery

- スキーマ適用は CREATE IF NOT EXISTS/ON CONFLICT を使い、再実行可能にする。失敗時は schema.sql 冒頭の DROP 文でクリーン後に再適用。
- API は冪等性を考慮し、同じ guardian_id+student_id+date の重複を UNIQUE 制約＋UPSERT で防ぐ。
- mock-line は MOCK_LINE_ENABLED で有効/無効を切り替えられる。

## Artifacts and Notes

- Supabase スキーマファイル: supabase/schema.sql にDDLとサンプルデータを記載。
- 環境変数テンプレート: .env.example を共有し、Vercel/Supabase の値を投入して `.env.local` を各自作成。
- ダッシュボードからの模擬フロントリンクは目立たない小ボタン（例: 右上/フッターの “Mock LINE”）。

## Interfaces and Dependencies

- API Routes:
  - POST /api/attendance: body {date, studentId, status, note?, lineUserId?} → 200 with inserted row; validation via zod。
  - GET /api/attendance?from=YYYY-MM-DD&to=YYYY-MM-DD&studentId=... → attendance_submissions list + aggregates。
  - POST /api/guardians: body {name, children:[{name, grade}], lineUserId?} → create guardian + students + mapping。
  - GET /api/guardians?lineUserId=... → guardian + students。
  - POST /api/messages: body {guardianId, body} → log outbound and (prod) send via LINE Messaging API。
  - GET /api/messages?guardianId=... → message_logs list。
- Supabase クライアント:
  - server: lib/supabase/server.ts exports createServerClient(serviceRoleKey) returning SupabaseClient.
  - client: lib/supabase/client.ts exports createBrowserClient(anonKey) for LIFF/mock.
- UI コンポーネント:
  - components/attendance-form.tsx props: guardian, students, defaultDate, onSubmit(result)。
  - ダッシュボードカード: components/stats-card.tsx for displaying totals。

Updates:
- 2026-01-06: Progress/Surprises/Decisionを更新。npm registry 403 により create-next-app が利用できず、手動で初期セットアップを記述したことを追記。
