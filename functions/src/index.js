// .envファイルを読み込み（最初に実行する必要がある）
require('dotenv').config();

// Functions Framework 4.0.0 を使用
const functions = require('@google-cloud/functions-framework');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { log } = require('./utils/logger');

const app = express();

// 起動時の環境変数ログ表示（詳細版）
log('INFO', '=== WellFin AI Agent API Starting ===');
log('INFO', 'Environment variables loaded:', {
  NODE_ENV: process.env.NODE_ENV || 'NOT SET',
  ENVIRONMENT: process.env.ENVIRONMENT || 'NOT SET',
  WELLFIN_API_KEY: process.env.WELLFIN_API_KEY ? 'SET' : 'NOT SET',
  GOOGLE_CLOUD_PROJECT: process.env.GOOGLE_CLOUD_PROJECT || 'NOT SET',
  VERTEX_AI_LOCATION: process.env.VERTEX_AI_LOCATION || 'NOT SET',
  GOOGLE_APPLICATION_CREDENTIALS: process.env.GOOGLE_APPLICATION_CREDENTIALS ? 
    `SET (${process.env.GOOGLE_APPLICATION_CREDENTIALS})` : 'NOT SET',
  PORT: process.env.PORT || '8080 (default)'
});

// 設定ファイルの存在確認
const fs = require('fs');
const path = require('path');

if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  const credentialsPath = path.resolve(process.env.GOOGLE_APPLICATION_CREDENTIALS);
  if (fs.existsSync(credentialsPath)) {
    log('INFO', `Google Cloud credentials file found: ${credentialsPath}`);
  } else {
    log('WARN', `Google Cloud credentials file NOT found: ${credentialsPath}`);
  }
}

// .envファイルの存在確認
const envPath = path.resolve('.env');
if (fs.existsSync(envPath)) {
  log('INFO', `.env file found: ${envPath}`);
} else {
  log('WARN', `.env file NOT found: ${envPath}`);
}

log('INFO', '=== Environment Setup Complete ===');

// ミドルウェア
app.use(helmet());
app.use(cors());
app.use(express.json());

// ヘルスチェック
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '2.0.0-lts',
    environment: process.env.ENVIRONMENT || 'development',
    service: 'WellFin AI Agent API',
    functionsFramework: '4.0.0'
  });
});

// Vertex AI接続テスト（認証不要）
app.get('/test-ai', async (req, res) => {
  try {
    const { testVertexAIConnection } = require('./services/ai-service');
    const result = await testVertexAIConnection();
    
    res.json({
      ...result,
      timestamp: new Date().toISOString(),
      service: 'WellFin AI Agent API',
      functionsFramework: '4.0.0'
    });
  } catch (error) {
    log('ERROR', 'AI connection test failed', { error: error.message });
    res.status(500).json({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString(),
      service: 'WellFin AI Agent API'
    });
  }
});

// ルートエンドポイント
app.get('/', (req, res) => {
  res.json({
    message: 'WellFin AI Agent API',
    version: '2.0.0-lts',
    functionsFramework: '4.0.0',
    runtime: 'nodejs20',
    endpoints: {
      health: '/health',
      testAI: '/test-ai',
      analyzeTask: '/api/v1/analyze-task',
      optimizeSchedule: '/api/v1/optimize-schedule',
      recommendations: '/api/v1/recommendations'
    },
    features: {
      executionResults: 'エージェント実行結果をレスポンスに含む',
      actionTracking: '実行されたアクションの詳細追跡',
      performanceMetrics: '実行時間とパフォーマンス指標'
    }
  });
});

// APIキー認証ミドルウェア
app.use((req, res, next) => {
  try {
    // ヘルスチェック、ルートエンドポイント、AI接続テストは認証不要
    if (req.path === '/health' || req.path === '/' || req.path === '/test-ai') {
      return next();
    }
    
    // APIキー認証チェック
    const apiKey = req.headers['x-api-key'];
    const validApiKeys = [
      process.env.WELLFIN_API_KEY || 'dev-secret-key',
      process.env.DEV_TOKEN,
      process.env.API_KEY,
      'dev-secret-key' // デフォルトの開発用キー
    ].filter(Boolean);
    
    if (!apiKey) {
      log('ERROR', 'No API key provided', {
        headers: Object.keys(req.headers),
        userAgent: req.headers['user-agent']
      });
      return res.status(401).json({ 
        error: 'API key required',
        message: 'Please provide X-API-Key header' 
      });
    }
    
    if (!validApiKeys.includes(apiKey)) {
      log('ERROR', 'Invalid API key', {
        providedKey: apiKey.substring(0, 8) + '...',
        validKeyCount: validApiKeys.length
      });
      return res.status(401).json({ 
        error: 'Invalid API key',
        message: 'The provided API key is not valid' 
      });
    }
    
    // 認証成功
    req.userId = `api-user-${apiKey.substring(0, 8)}`;
    log('INFO', 'API key authentication successful', {
      userId: req.userId,
      endpoint: req.path
    });
    
    next();
  } catch (error) {
    log('ERROR', 'Authentication failed', { error: error.message });
    res.status(401).json({ error: 'Authentication error' });
  }
});

// ルート設定
app.use('/api/v1', require('./routes'));

// エラーハンドリング
app.use((error, req, res, next) => {
  log('ERROR', 'Unhandled error', { error: error.message });
  res.status(500).json({ error: 'Internal server error' });
});

// Cloud Run Functions用の関数エクスポート（Functions Framework 4.0.0）
functions.http('app', app);

// ローカル開発用のサーバー起動（Cloud Run Functionsでは無視される）
if (require.main === module) {
  const port = process.env.PORT || 8080;
app.listen(port, '0.0.0.0', () => {
    log('INFO', `=== Local Development Server Started ===`);
  log('INFO', `Server running on port ${port}`);
  log('INFO', `Environment: ${process.env.ENVIRONMENT || 'development'}`);
  log('INFO', `Access URLs:`);
  log('INFO', `  - Health Check: http://localhost:${port}/health`);
  log('INFO', `  - API Base: http://localhost:${port}/api/v1`);
  log('INFO', `=== Ready to Accept Requests ===`);
});
} 