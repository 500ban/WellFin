const { VertexAI } = require('@google-cloud/vertexai');
const { LanguageServiceClient } = require('@google-cloud/language');
const { log } = require('../utils/logger');

// Vertex AI初期化（Cloud Run Functions対応）
const PROJECT_ID = process.env.GOOGLE_CLOUD_PROJECT;
const LOCATION = process.env.VERTEX_AI_LOCATION || 'asia-northeast1';

// デバッグ情報ログ
log('INFO', 'Initializing Vertex AI', {
  projectId: PROJECT_ID,
  location: LOCATION,
  nodeEnv: process.env.NODE_ENV,
  hasGoogleCredentials: !!process.env.GOOGLE_APPLICATION_CREDENTIALS
});

// VertexAI インスタンスを初期化（Cloud Run Functions対応）
let vertexAI;
try {
  vertexAI = new VertexAI({
    project: PROJECT_ID,
    location: LOCATION,
    // Cloud Run Functionsでは自動的にサービスアカウント認証が使用される
  });
  log('INFO', 'Vertex AI initialized successfully');
} catch (error) {
  log('ERROR', 'Failed to initialize Vertex AI', { error: error.message });
  throw error;
}

// asia-northeast1で利用可能なGeminiモデル（公式ドキュメント準拠）
const MODEL_NAME = 'gemini-1.5-flash';

// generativeModelを取得する関数（遅延初期化）
const getGenerativeModel = () => {
  try {
    return vertexAI.getGenerativeModel({
      model: MODEL_NAME,
      // 安全性設定を追加（公式ドキュメント推奨）
      safetySettings: [
        {
          category: 'HARM_CATEGORY_HATE_SPEECH',
          threshold: 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          category: 'HARM_CATEGORY_DANGEROUS_CONTENT',
          threshold: 'BLOCK_MEDIUM_AND_ABOVE',
        },
      ],
      // 生成設定を追加（公式ドキュメント推奨）
      generationConfig: {
        maxOutputTokens: 1024,
        temperature: 0.1,
        topP: 0.8,
      },
    });
  } catch (error) {
    log('ERROR', 'Failed to get generative model', { 
      error: error.message,
      model: MODEL_NAME,
      project: PROJECT_ID,
      location: LOCATION 
    });
    throw error;
  }
};

// Natural Language API初期化
const languageClient = new LanguageServiceClient();

// Vertex AI共通処理：Gemini APIを呼び出してJSONレスポンスを取得
const callGeminiAPI = async (prompt, operation) => {
  try {
    log('INFO', `Starting Vertex AI Gemini ${operation}`, { 
      project: PROJECT_ID,
      location: LOCATION,
      model: MODEL_NAME
    });

    // Google公式ドキュメントに準拠したリクエスト構造
    const request = {
      contents: [
        {
          role: 'user',
          parts: [{ text: prompt }]
        }
      ]
    };

    log('INFO', `Sending request to Vertex AI Gemini for ${operation}`, { 
      model: MODEL_NAME,
      location: LOCATION
    });

    // Vertex AI APIを呼び出し（遅延初期化）
    const generativeModel = getGenerativeModel();
    const result = await generativeModel.generateContent(request);
    
    // レスポンスを取得
    const response = result.response;
    
    // 候補が存在することを確認
    if (!response.candidates || response.candidates.length === 0) {
      throw new Error('No candidates returned from Vertex AI Gemini');
    }
    
    const candidate = response.candidates[0];
    
    // 安全性チェック
    if (candidate.finishReason === 'SAFETY') {
      throw new Error('Content was blocked by safety filters');
    }
    
    // テキストを抽出
    const text = candidate.content.parts[0].text;
    
    log('INFO', `Vertex AI Gemini response received for ${operation}`, { 
      textLength: text.length,
      finishReason: candidate.finishReason,
      responsePreview: text.substring(0, 100) + '...'
    });
    
    // JSONを抽出してパース
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      log('ERROR', 'No JSON found in response', { fullResponse: text });
      throw new Error(`No valid JSON found in Vertex AI response for ${operation}`);
    }
    
    try {
      const parsedResult = JSON.parse(jsonMatch[0]);
      
      log('INFO', `${operation} completed successfully with Vertex AI`, { 
        resultKeys: Object.keys(parsedResult)
      });
      
      return parsedResult;
    } catch (parseError) {
      log('ERROR', 'Failed to parse JSON response', { 
        error: parseError.message,
        rawResponse: jsonMatch[0]
      });
      throw new Error(`Failed to parse JSON response from Vertex AI Gemini for ${operation}`);
    }
    
  } catch (error) {
    // 認証エラーの詳細ログ
    if (error.message && error.message.includes('GoogleAuthError')) {
      log('ERROR', `Vertex AI Authentication Error for ${operation}`, { 
        error: error.message,
        project: PROJECT_ID,
        location: LOCATION,
        model: MODEL_NAME,
        serviceAccount: process.env.GOOGLE_APPLICATION_CREDENTIALS ? 'set' : 'not set',
        metadata: 'Cloud Run Functions should auto-authenticate'
      });
    } else {
      log('ERROR', `Vertex AI Gemini API error for ${operation}`, { 
        error: error.message,
        stack: error.stack,
        code: error.code,
        project: PROJECT_ID,
        location: LOCATION,
        model: MODEL_NAME
      });
    }
    throw error;
  }
};

// タスク分析（Vertex AI Gemini API使用 - Google公式ドキュメント準拠）
const analyzeTaskWithGemini = async (userInput, scheduledDate) => {
  const prompt = `
あなたは優秀なタスク分析アシスタントです。以下のユーザー入力からタスク情報を正確に抽出してください。

ユーザー入力: "${userInput}"
予定日: ${scheduledDate || '未指定'}

以下の正確なJSON形式で回答してください（他の文章は含めないでください）:
{
  "title": "タスクの明確なタイトル",
  "description": "タスクの詳細な説明",
  "priority": 1から5の整数（1=低、5=高）,
  "difficulty": 1から5の整数（1=簡単、5=困難）,
  "estimatedDuration": 予想所要時間（分単位の整数）,
  "tags": ["関連するタグの配列"],
  "isSkippable": ブール値（true または false）
}
`;

  const result = await callGeminiAPI(prompt, 'task analysis');
  
  // 結果の検証
  if (!result.title || !result.description) {
    throw new Error('Invalid task analysis result: missing required fields');
  }
  
  return result;
};

// スケジュール最適化（Vertex AI Gemini API使用）
const optimizeScheduleWithGemini = async (tasks, taskHistory, preferences) => {
  try {
    log('INFO', 'Starting Vertex AI Gemini schedule optimization', { 
      taskCount: tasks.length,
      hasPreferences: !!preferences,
      hasTaskHistory: !!taskHistory
    });

    const prompt = `
あなたは優秀なスケジュール最適化アシスタントです。以下のタスクリストを分析し、最適なスケジュールを作成してください。

タスクリスト:
${JSON.stringify(tasks, null, 2)}

ユーザー設定:
${JSON.stringify(preferences, null, 2)}

過去のタスク履歴（参考情報）:
${taskHistory ? JSON.stringify(taskHistory.slice(0, 5), null, 2) : '履歴なし'}

以下の正確なJSON形式で最適化されたスケジュールを回答してください（他の文章は含めないでください）:
{
  "optimizedTasks": [
    {
      "id": "タスクID",
      "title": "タスクタイトル",
      "priority": "優先度（low/medium/high/urgent）",
      "estimatedDuration": 所要時間（分）,
      "scheduledTime": "最適な開始時間（ISO 8601形式）",
      "category": "カテゴリ",
      "optimizationReason": "最適化の理由"
    }
  ],
  "optimizationInsights": [
    "最適化に関する洞察やアドバイス"
  ],
  "efficiencyScore": 効率スコア（0-1の数値）,
  "timeDistribution": {
    "morning": 午前のタスク数,
    "afternoon": 午後のタスク数,
    "evening": 夕方のタスク数
  }
}
`;

    const result = await callGeminiAPI(prompt, 'schedule optimization');
    
    // 結果の検証
    if (!result.optimizedTasks || !Array.isArray(result.optimizedTasks)) {
      throw new Error('Invalid schedule optimization result: missing optimizedTasks array');
    }
    
    return result;
  } catch (error) {
    log('ERROR', 'Schedule optimization with Gemini failed', { error: error.message });
    throw error;
  }
};

// 推奨事項生成（Vertex AI Gemini API使用）
const generateRecommendationsWithGemini = async (userProfile, context, userId) => {
  try {
    log('INFO', 'Starting Vertex AI Gemini recommendations generation', { 
      userId,
      hasUserProfile: !!userProfile,
      hasContext: !!context
    });

    const prompt = `
あなたは優秀な生産性コンサルタントです。ユーザーの情報を分析し、パーソナライズされた推奨事項を生成してください。

ユーザープロファイル:
${JSON.stringify(userProfile, null, 2)}

現在の状況:
${JSON.stringify(context, null, 2)}

以下の正確なJSON形式で推奨事項を回答してください（他の文章は含めないでください）:
{
  "recommendations": [
    {
      "type": "推奨タイプ（productivity/habit/schedule/goal）",
      "title": "推奨事項のタイトル",
      "description": "詳細な説明",
      "priority": "優先度（low/medium/high）",
      "actionable": true,
      "estimatedImpact": "予想効果（low/medium/high）",
      "implementationSteps": ["実行ステップ1", "実行ステップ2"],
      "timeframe": "実行期間（例：1週間、1ヶ月）"
    }
  ],
  "insights": {
    "strengths": ["ユーザーの強み"],
    "improvementAreas": ["改善すべき領域"],
    "riskFactors": ["注意すべきリスク要因"]
  },
  "personalizedTips": [
    "ユーザーに特化したアドバイス"
  ],
  "nextActions": [
    "次に取るべき具体的なアクション"
  ]
}
`;

    const result = await callGeminiAPI(prompt, 'recommendations generation');
    
    // 結果の検証
    if (!result.recommendations || !Array.isArray(result.recommendations)) {
      throw new Error('Invalid recommendations result: missing recommendations array');
    }
    
    return result;
  } catch (error) {
    log('ERROR', 'Recommendations generation with Gemini failed', { error: error.message });
    throw error;
  }
};

// 生産性パターン分析
const analyzeProductivityPattern = async (taskHistory) => {
  const hourlyProductivity = {};
  
  // 時間帯別の完了率を分析
  for (let hour = 0; hour < 24; hour++) {
    const hourTasks = taskHistory.filter(task => {
      const completedAt = new Date(task.completedAt);
      return completedAt.getHours() === hour;
    });
    
    hourlyProductivity[hour] = hourTasks.length > 0 
      ? hourTasks.filter(t => t.completed).length / hourTasks.length 
      : 0;
  }
  
  return hourlyProductivity;
};

// スケジュール最適化（メイン関数 - Vertex AI使用）
const optimizeSchedule = async (tasks, taskHistory, preferences) => {
  try {
    // Vertex AI Geminiを使用してスケジュール最適化
    const geminiResult = await optimizeScheduleWithGemini(tasks, taskHistory, preferences);
    
    // Geminiの結果を標準形式に変換
    const optimizedTasks = geminiResult.optimizedTasks.map(task => ({
      ...task,
      id: task.id || `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      scheduledTime: task.scheduledTime || calculateOptimalTime(task.scheduledDate, 9),
      optimizationScore: geminiResult.efficiencyScore || 0.8
    }));
    
    return optimizedTasks;
  } catch (error) {
    log('ERROR', 'Schedule optimization error', { error: error.message });
    
    // フォールバック：ルールベースの最適化
    log('WARN', 'Falling back to rule-based schedule optimization');
    return fallbackOptimizeSchedule(tasks, taskHistory, preferences);
  }
};

// フォールバック：ルールベースのスケジュール最適化
const fallbackOptimizeSchedule = async (tasks, taskHistory, preferences) => {
  const productivityPattern = await analyzeProductivityPattern(taskHistory || []);
  
  const optimizedTasks = tasks.map(task => {
    const optimalHour = findOptimalHour(task, productivityPattern);
    
    return {
      ...task,
      id: task.id || `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      scheduledTime: calculateOptimalTime(task.scheduledDate, optimalHour),
      optimizationScore: calculateOptimizationScore(task, productivityPattern)
    };
  });
  
  return optimizedTasks;
};

// 推奨生成（メイン関数 - Vertex AI使用）
const generateRecommendations = async (userId, userProfile, context) => {
  try {
    // Vertex AI Geminiを使用して推奨事項生成
    const geminiResult = await generateRecommendationsWithGemini(userProfile, context, userId);
    
    // Geminiの結果を標準形式に変換
    const recommendations = geminiResult.recommendations.map(rec => ({
      ...rec,
      id: rec.id || `rec_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      estimatedImpact: rec.estimatedImpact || 'medium'
    }));
    
    return recommendations;
  } catch (error) {
    log('ERROR', 'Recommendations generation error', { error: error.message });
    
    // フォールバック：ルールベースの推奨生成
    log('WARN', 'Falling back to rule-based recommendations generation');
    return fallbackGenerateRecommendations(userId);
  }
};

// フォールバック：ルールベースの推奨生成
const fallbackGenerateRecommendations = async (userId) => {
  const recommendations = [];
  
  recommendations.push({
    type: 'productivity_tip',
    title: '生産性向上のヒント',
    description: '朝の時間帯は集中力が高いため、重要なタスクを午前中に配置することをお勧めします。',
    priority: 'medium',
    category: 'productivity'
  });
  
  recommendations.push({
    type: 'habit_suggestion',
    title: '習慣形成のアドバイス',
    description: '小さな習慣から始めて、徐々に習慣を積み重ねていくことで継続しやすくなります。',
    priority: 'high',
    category: 'habits'
  });
  
  return recommendations;
};

// 最適な時間帯を見つける
const findOptimalHour = (task, productivityPattern) => {
  let bestHour = 9; // デフォルトは午前9時
  let bestScore = 0;
  
  // 優先度を数値に変換（OpenAPI仕様の文字列形式に対応）
  const priorityValue = getPriorityValue(task.priority);
  const priorityWeight = priorityValue / 5;
  
  for (let hour = 6; hour <= 22; hour++) {
    const productivity = productivityPattern[hour] || 0;
    const score = productivity * priorityWeight;
    
    if (score > bestScore) {
      bestScore = score;
      bestHour = hour;
    }
  }
  
  return bestHour;
};

// 優先度を数値に変換
const getPriorityValue = (priority) => {
  const priorityMap = {
    'low': 1,
    'medium': 3,
    'high': 4,
    'urgent': 5
  };
  return priorityMap[priority] || 3;
};

// 最適な時間を計算
const calculateOptimalTime = (scheduledDate, optimalHour) => {
  // scheduledDateがない場合は今日の日付を使用
  const date = scheduledDate ? new Date(scheduledDate) : new Date();
  // 日付が無効な場合は今日の日付を使用
  if (isNaN(date.getTime())) {
    date = new Date();
  }
  date.setHours(optimalHour, 0, 0, 0);
  return date.toISOString();
};

// 最適化スコアを計算
const calculateOptimizationScore = (task, productivityPattern) => {
  const hour = new Date(task.scheduledDate).getHours();
  const productivity = productivityPattern[hour] || 0;
  return productivity * (getPriorityValue(task.priority) / 5);
};

// Vertex AI 接続テスト機能
const testVertexAIConnection = async () => {
  try {
    log('INFO', 'Testing Vertex AI connection', { 
      project: PROJECT_ID,
      location: LOCATION,
      model: MODEL_NAME
    });

    // 簡単なテストプロンプト
    const testPrompt = `
このテストプロンプトに対して、以下のJSON形式で回答してください:
{
  "status": "success",
  "message": "Vertex AI connection is working",
  "timestamp": "${new Date().toISOString()}"
}
`;

    const result = await callGeminiAPI(testPrompt, 'connection test');
    
    log('INFO', 'Vertex AI connection test successful', { 
      result: result
    });
    
    return {
      success: true,
      project: PROJECT_ID,
      location: LOCATION,
      model: MODEL_NAME,
      result: result
    };
  } catch (error) {
    log('ERROR', 'Vertex AI connection test failed', { 
      error: error.message,
      project: PROJECT_ID,
      location: LOCATION
    });
    
    return {
      success: false,
      error: error.message,
      project: PROJECT_ID,
      location: LOCATION
    };
  }
};

module.exports = {
  analyzeTaskWithGemini,
  optimizeSchedule,
  generateRecommendations,
  analyzeProductivityPattern,
  testVertexAIConnection
}; 