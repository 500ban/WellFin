FROM node:24-slim

WORKDIR /app

# 依存関係のインストール
COPY package*.json ./
RUN npm install --only=production

# アプリケーションコードのコピー
COPY . .

# ポート設定
EXPOSE 3000

# ヘルスチェック
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# アプリケーション起動
CMD ["npm", "start"] 