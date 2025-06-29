const express = require('express');
const router = express.Router();
const { analyzeTaskWithGemini } = require('../services/ai-service');
const { log } = require('../utils/logger');

router.post('/', async (req, res) => {
  const startTime = Date.now(); // 実行時間計測開始
  
  try {
    const { userInput, scheduledDate, priority } = req.body;
    const userId = req.userId;
    
    log('INFO', 'AI-powered task analysis requested', { userId, userInput });
    
    if (!userInput) {
      return res.status(400).json({ 
        error: 'userInput is required',
        code: 'MISSING_REQUIRED_FIELD',
        timestamp: new Date().toISOString()
      });
    }
    
    // Vertex AI Geminiを使用したタスク分析を実行
    log('INFO', 'Starting AI-powered task analysis', { userId, inputLength: userInput.length });
    const aiAnalysis = await analyzeTaskWithGemini(userInput, scheduledDate);
    
    // エージェント実行結果の生成
    const executionActions = [];
    const executionRecommendations = [];
    
    // タスク作成アクション
    const taskId = `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    executionActions.push({
      type: 'task_created',
      description: 'AIが分析したタスクを作成しました',
      details: {
        taskId: taskId,
        title: aiAnalysis.title || extractTitle(userInput),
        priority: priority || mapPriority(aiAnalysis.priority),
        category: aiAnalysis.category || 'general',
        aiModel: 'gemini-1.5-flash'
      }
    });
    
    // サブタスク生成（複雑なタスクの場合）
    const estimatedDuration = aiAnalysis.estimatedDuration || 60;
    if (estimatedDuration > 120) {
      const subtasks = generateSubtasks(aiAnalysis.title || extractTitle(userInput));
      executionActions.push({
        type: 'subtasks_generated',
        description: `複雑なタスクのため、${subtasks.length}つのサブタスクを生成しました`,
        details: {
          count: subtasks.length,
          subtasks: subtasks
        }
      });
    }
    
    // 実行推奨事項の生成
    if (mapPriority(aiAnalysis.priority) === 'high' || mapPriority(aiAnalysis.priority) === 'urgent') {
      executionRecommendations.push('高優先度タスクのため、明日の朝一番に取り組むことをお勧めします');
    }
    
    if (estimatedDuration > 90) {
      executionRecommendations.push('集中できる2時間のブロックを確保してください');
    } else {
      executionRecommendations.push('短時間で完了できるため、隙間時間を活用できます');
    }
    
    // OpenAPI仕様に合わせたレスポンス形式
    const executionTime = (Date.now() - startTime) / 1000; // 秒単位
    
    const analysis = {
      success: true,
      analysis: {
        title: aiAnalysis.title || extractTitle(userInput),
        description: aiAnalysis.description || userInput,
        category: aiAnalysis.category || 'general',
        priority: priority || mapPriority(aiAnalysis.priority),
        estimatedDuration: estimatedDuration,
        complexity: mapComplexity(aiAnalysis.difficulty),
        tags: aiAnalysis.tags || generateTags(userInput),
        suggestions: generateSuggestions(aiAnalysis)
      },
      execution: {
        status: 'completed',
        actions: executionActions,
        recommendations: executionRecommendations
      },
      metadata: {
        analyzedAt: new Date().toISOString(),
        model: 'gemini-1.5-flash',
        executionTime: Math.round(executionTime * 100) / 100,
        aiPowered: true
      }
    };
    
    // Firestoreへの保存は不要（データ管理はFlutter側で実施）
    log('INFO', 'Analysis completed without data persistence');
    
    log('INFO', 'AI-powered task analysis completed', { 
      userId, 
      taskId: taskId,
      executionTime: executionTime,
      actionsCount: executionActions.length,
      aiModel: 'gemini-1.5-flash'
    });
    
    res.json(analysis);
  } catch (error) {
    const executionTime = (Date.now() - startTime) / 1000;
    log('ERROR', 'AI-powered task analysis failed', { 
      error: error.message,
      executionTime: executionTime,
      stack: error.stack
    });
    
    res.status(500).json({ 
      error: error.message,
      code: 'ANALYSIS_FAILED',
      timestamp: new Date().toISOString()
    });
  }
});

// タイトル抽出（userInputから）
const extractTitle = (userInput) => {
  const colonIndex = userInput.indexOf(':');
  if (colonIndex > 0) {
    return userInput.substring(0, colonIndex).trim();
  }
  return userInput.length > 50 ? userInput.substring(0, 50) + '...' : userInput;
};

// サブタスク生成
const generateSubtasks = (title) => {
  const subtasks = [];
  
  if (title.includes('計画') || title.includes('プロジェクト')) {
    subtasks.push('要件定義・スコープ確認');
    subtasks.push('タスク分解・スケジュール作成');
    subtasks.push('リスク分析・対策検討');
  } else if (title.includes('資料') || title.includes('レポート')) {
    subtasks.push('情報収集・調査');
    subtasks.push('構成・アウトライン作成');
    subtasks.push('執筆・編集・校正');
  } else {
    subtasks.push('準備・情報整理');
    subtasks.push('実行・作業');
    subtasks.push('確認・完了処理');
  }
  
  return subtasks;
};

// タグ生成
const generateTags = (userInput) => {
  const tags = [];
  const input = userInput.toLowerCase();
  
  if (input.includes('会議') || input.includes('ミーティング')) tags.push('会議');
  if (input.includes('資料') || input.includes('文書')) tags.push('文書作成');
  if (input.includes('計画') || input.includes('プロジェクト')) tags.push('プロジェクト管理');
  if (input.includes('レビュー') || input.includes('確認')) tags.push('レビュー');
  if (input.includes('学習') || input.includes('勉強')) tags.push('学習');
  if (input.includes('開発') || input.includes('プログラム')) tags.push('開発');
  
  return tags.length > 0 ? tags : ['一般'];
};

// 優先度マッピング
const mapPriority = (aiPriority) => {
  if (typeof aiPriority === 'number') {
    if (aiPriority <= 1) return 'low';
    if (aiPriority <= 2) return 'medium';
    if (aiPriority <= 4) return 'high';
    return 'urgent';
  }
  
  if (typeof aiPriority === 'string') {
    const priority = aiPriority.toLowerCase();
    if (['low', 'medium', 'high', 'urgent'].includes(priority)) {
      return priority;
    }
  }
  
  return 'medium';
};

// 複雑さマッピング
const mapComplexity = (difficulty) => {
  if (typeof difficulty === 'number') {
    if (difficulty <= 2) return 'easy';
    if (difficulty <= 4) return 'medium';
    return 'hard';
  }
  return 'medium';
};

// 改善提案生成
const generateSuggestions = (aiAnalysis) => {
  const suggestions = [];
  
  if (aiAnalysis.estimatedDuration > 120) {
    suggestions.push('大きなタスクなので、小さなサブタスクに分割することをお勧めします');
  }
  
  if (aiAnalysis.priority >= 4) {
    suggestions.push('高優先度タスクなので、他のタスクより先に取り組むことをお勧めします');
  }
  
  if (aiAnalysis.isSkippable) {
    suggestions.push('このタスクは後回しにできる可能性があります');
  }
  
  if (aiAnalysis.estimatedDuration <= 30) {
    suggestions.push('短時間で完了できるため、隙間時間を活用してください');
  }
  
  return suggestions;
};

module.exports = router; 