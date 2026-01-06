import Link from "next/link";

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-6 p-6 text-center">
      <div className="space-y-3 max-w-2xl">
        <h1 className="text-3xl font-semibold">無料塾向けLINE出欠管理</h1>
        <p className="text-lg text-gray-700">
          Next.js + Tailwind CSS ベースのダッシュボードと LINE/モック向け申請UI を段階的に構築するプロジェクトです。
          現在は初期セットアップ段階で、以降のマイルストーンでAPI・ダッシュボード・モックUIを追加します。
        </p>
      </div>
      <div className="flex flex-col items-center gap-2 text-sm text-gray-600">
        <p>ダッシュボードとLIFF/モック画面は今後のマイルストーンで追加されます。</p>
        <Link className="text-blue-600 underline" href="/dashboard">
          仮ダッシュボードプレースホルダー
        </Link>
      </div>
    </main>
  );
}
