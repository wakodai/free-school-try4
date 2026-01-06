# Repository Agent Guide

- 本リポジトリへの回答は必ず日本語で行うこと。
- 複雑な機能開発や大きめの改修では、.agent/PLANS.md に従った ExecPlan を exec_plans/ 配下に作成・更新して進めること。
- devcontainer 環境を前提に作業すること。CODEX_HOME は `${containerWorkspaceFolder}/.codex` とし、macOS では `~/.codex` を `/home/vscode/.codex` に bind mount する (devcontainer.json 参照)。
- MCP サーバを npx で利用できるよう、devcontainer では Node.js 20 フィーチャを有効にすること。
- ローカル検証は devcontainer 内で行い、docker compose は使用しないこと。
- LINE 受付のローカル検証はダッシュボード内からリンクする模擬フロントエンドを利用すること。
