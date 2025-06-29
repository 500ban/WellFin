const express = require('express');
const router = express.Router();
const { testVertexAIConnection } = require('../services/ai-service');
const { log } = require('../utils/logger');

// Vertex AI認証詳細テストエンドポイント
router.get('/', async (req, res) => {
  try {
    log('INFO', 'Vertex AI authentication test requested');
    
    // 環境変数情報を取得
    const envInfo = {
      PROJECT_ID: process.env.GOOGLE_CLOUD_PROJECT || 'NOT_SET',
      VERTEX_AI_LOCATION: process.env.VERTEX_AI_LOCATION || 'NOT_SET',
      NODE_ENV: process.env.NODE_ENV || 'NOT_SET',
      ENVIRONMENT: process.env.ENVIRONMENT || 'NOT_SET',
      HAS_GOOGLE_CREDENTIALS: !!process.env.GOOGLE_APPLICATION_CREDENTIALS,
      GOOGLE_CREDENTIALS_PATH: process.env.GOOGLE_APPLICATION_CREDENTIALS || 'NOT_SET',
    };

    log('INFO', 'Environment variables for Vertex AI', envInfo);

    // Google Cloud Metadata APIからサービスアカウント情報を取得
    let serviceAccountInfo = {};
    try {
      const { GoogleAuth } = require('google-auth-library');
      const auth = new GoogleAuth();
      const client = await auth.getClient();
      const projectId = await auth.getProjectId();
      
      serviceAccountInfo = {
        projectId: projectId,
        clientEmail: client.email || 'UNKNOWN',
        authType: client.constructor.name,
        hasCredentials: !!client.credentials,
      };
    } catch (authError) {
      serviceAccountInfo = {
        error: authError.message,
        authTestFailed: true
      };
    }

    log('INFO', 'Service account information', serviceAccountInfo);

    // Vertex AI接続テストを実行
    const vertexTestResult = await testVertexAIConnection();
    
    log('INFO', 'Vertex AI test completed', vertexTestResult);

    // 総合的な結果を返す
    const result = {
      timestamp: new Date().toISOString(),
      environment: envInfo,
      serviceAccount: serviceAccountInfo,
      vertexAITest: vertexTestResult,
      status: vertexTestResult.success ? 'SUCCESS' : 'FAILED',
      recommendations: []
    };

    // エラーの場合は推奨事項を追加
    if (!vertexTestResult.success) {
      result.recommendations = [
        'Check if Vertex AI API is enabled',
        'Verify service account has aiplatform.admin role',
        'Ensure Cloud Run Functions is using correct service account',
        'Check project ID configuration'
      ];
    }

    res.status(vertexTestResult.success ? 200 : 500).json(result);

  } catch (error) {
    log('ERROR', 'Vertex AI authentication test failed', { 
      error: error.message,
      stack: error.stack 
    });

    res.status(500).json({
      timestamp: new Date().toISOString(),
      status: 'ERROR',
      error: error.message,
      message: 'Vertex AI authentication test failed completely'
    });
  }
});

module.exports = router; 