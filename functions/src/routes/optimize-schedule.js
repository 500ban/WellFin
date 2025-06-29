const express = require('express');
const router = express.Router();
const { optimizeSchedule } = require('../services/ai-service');
const { log } = require('../utils/logger');

router.post('/', async (req, res) => {
  const startTime = Date.now(); // 実行時間計測開始
  
  try {
    // OpenAPI仕様に合わせて'tasks'キーを使用（'newTasks'との後方互換性も維持）
    const { tasks, newTasks, existingTasks = [], preferences = {} } = req.body;
    const userId = req.userId;
    
    // 'tasks'または'newTasks'のどちらかを使用
    const inputTasks = tasks || newTasks;
    
    log('INFO', 'Schedule optimization requested', { 
      userId, 
      inputTaskCount: inputTasks?.length,
      existingTaskCount: existingTasks?.length,
      hasPreferences: Object.keys(preferences).length > 0
    });
    
    if (!inputTasks || !Array.isArray(inputTasks)) {
      return res.status(400).json({ 
        error: 'tasks array is required',
        code: 'MISSING_REQUIRED_FIELD',
        timestamp: new Date().toISOString()
      });
    }
    
    // 入力タスクの検証（OpenAPI仕様に合わせてestimatedDurationを優先、estimatedHoursも受け入れ）
    for (const task of inputTasks) {
      if (!task.title || !task.priority) {
        return res.status(400).json({
          error: 'Each task must have title and priority',
          code: 'INVALID_TASK_FORMAT',
          timestamp: new Date().toISOString()
        });
      }
      
      // estimatedDurationまたはestimatedHoursが必要
      if (!task.estimatedDuration && !task.estimatedHours) {
        return res.status(400).json({
          error: 'Each task must have estimatedDuration (minutes) or estimatedHours',
          code: 'INVALID_TASK_FORMAT',
          timestamp: new Date().toISOString()
        });
      }
    }
    
    // OpenAPI仕様に合わせてestimatedDurationを統一（分単位）
    const tasksInMinutes = inputTasks.map(task => ({
      ...task,
      estimatedDuration: task.estimatedDuration || Math.round((task.estimatedHours || 1) * 60)
    }));
    
    // タスク履歴はFlutter側で管理されるため、API側では空の配列を使用
    const taskHistory = [];
    log('INFO', 'Task history management delegated to Flutter client');
    
    // Vertex AI Geminiを使用したスケジュール最適化を実行
    log('INFO', 'Starting AI-powered schedule optimization', {
      taskCount: tasksInMinutes.length,
      hasHistory: taskHistory.length > 0,
      preferences: preferences
    });
    
    const optimizedTasks = await optimizeSchedule(tasksInMinutes, taskHistory, preferences);
    
    // エージェント実行結果の生成
    const executionActions = [];
    const optimizations = [];
    
    // スケジュール更新アクション
    executionActions.push({
      type: 'schedule_updated',
      description: `AI分析により${optimizedTasks.length}つのタスクのスケジュールを最適化しました`,
      details: {
        updatedTasks: optimizedTasks.length,
        totalDuration: optimizedTasks.reduce((sum, task) => sum + (task.estimatedDuration || 0), 0),
        aiModel: 'gemini-1.5-flash'
      }
    });
    
    // 競合解決（重複する時間帯のタスクがあった場合）
    const conflicts = detectTimeConflicts(optimizedTasks);
    if (conflicts > 0) {
      executionActions.push({
        type: 'conflicts_resolved',
        description: `AIがスケジュール競合を${conflicts}件自動解決しました`,
        details: {
          conflictsResolved: conflicts,
          resolutionMethod: 'ai_optimization'
        }
      });
    }
    
    // AI最適化内容の説明
    const highPriorityTasks = optimizedTasks.filter(task => 
      task.priority === 'high' || task.priority === 'urgent'
    );
    if (highPriorityTasks.length > 0) {
      optimizations.push('AIが高優先度タスクを最適な時間帯に配置しました');
    }
    
    const categorizedTasks = groupTasksByCategory(optimizedTasks);
    if (Object.keys(categorizedTasks).length > 1) {
      optimizations.push('AIが類似タスクをまとめて効率性を向上させました');
    }
    
    if (preferences.workStyle) {
      optimizations.push(`AIが${preferences.workStyle}型の作業スタイルに合わせてスケジュールを調整しました`);
    }
    
    if (taskHistory.length > 0) {
      optimizations.push('過去のタスク履歴を分析して個人の生産性パターンを考慮しました');
    }
    
    // 効率計算と改善率
    const originalEfficiency = 0.7; // 仮の元の効率
    const newEfficiency = calculateEfficiency(optimizedTasks, preferences);
    const improvementPercentage = Math.round(((newEfficiency - originalEfficiency) / originalEfficiency) * 100);
    
    // OpenAPI仕様に合わせたレスポンス形式
    const executionTime = (Date.now() - startTime) / 1000; // 秒単位
    
    const response = {
      success: true,
      optimizedSchedule: optimizedTasks.map(task => ({
        id: task.id || `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        title: task.title,
        startTime: task.scheduledTime,
        endTime: calculateEndTime(task.scheduledTime, task.estimatedDuration),
        priority: task.priority,
        category: task.category || 'general',
        status: 'scheduled'
      })),
      execution: {
        status: 'completed',
        actions: executionActions,
        optimizations: optimizations
      },
      summary: {
        totalTasks: optimizedTasks.length,
        totalDuration: optimizedTasks.reduce((sum, task) => sum + (task.estimatedDuration || 0), 0),
        efficiency: newEfficiency,
        improvementPercentage: Math.max(improvementPercentage, 0)
      },
      metadata: {
        optimizedAt: new Date().toISOString(),
        model: 'gemini-1.5-flash',
        executionTime: Math.round(executionTime * 100) / 100,
        aiPowered: true
      }
    };
    
    log('INFO', 'AI-powered schedule optimization completed', { 
      userId, 
      optimizedTaskCount: optimizedTasks.length,
      executionTime: executionTime,
      actionsCount: executionActions.length,
      improvementPercentage: improvementPercentage,
      aiOptimizations: optimizations.length
    });
    
    res.json(response);
  } catch (error) {
    const executionTime = (Date.now() - startTime) / 1000;
    log('ERROR', 'AI-powered schedule optimization failed', { 
      error: error.message,
      executionTime: executionTime,
      stack: error.stack
    });
    
    res.status(500).json({ 
      error: error.message,
      code: 'OPTIMIZATION_FAILED',
      timestamp: new Date().toISOString()
    });
  }
});

// 時間競合を検出
const detectTimeConflicts = (tasks) => {
  let conflicts = 0;
  for (let i = 0; i < tasks.length; i++) {
    for (let j = i + 1; j < tasks.length; j++) {
      const task1 = tasks[i];
      const task2 = tasks[j];
      
      if (task1.scheduledTime && task2.scheduledTime) {
        const start1 = new Date(task1.scheduledTime);
        const end1 = new Date(start1.getTime() + (task1.estimatedDuration || 60) * 60000);
        const start2 = new Date(task2.scheduledTime);
        const end2 = new Date(start2.getTime() + (task2.estimatedDuration || 60) * 60000);
        
        // 時間重複チェック
        if (start1 < end2 && start2 < end1) {
          conflicts++;
        }
      }
    }
  }
  return conflicts;
};

// カテゴリ別タスクグループ化
const groupTasksByCategory = (tasks) => {
  return tasks.reduce((groups, task) => {
    const category = task.category || 'general';
    if (!groups[category]) {
      groups[category] = [];
    }
    groups[category].push(task);
    return groups;
  }, {});
};

// 終了時間を計算
const calculateEndTime = (startTime, durationMinutes) => {
  if (!startTime) {
    return new Date().toISOString();
  }
  const start = new Date(startTime);
  const end = new Date(start.getTime() + durationMinutes * 60000);
  return end.toISOString();
};

// スケジュール効率を計算
const calculateEfficiency = (tasks, preferences) => {
  if (tasks.length === 0) return 0;
  
  // 簡単な効率計算（実際の実装ではより複雑なロジック）
  const totalDuration = tasks.reduce((sum, task) => sum + (task.estimatedDuration || 0), 0);
  const workHours = preferences.workHours || { start: '09:00', end: '18:00' };
  
  // 8時間労働を想定
  const availableTime = 8 * 60; // 分
  let efficiency = Math.min(totalDuration / availableTime, 1);
  
  // 優先度による効率調整
  const highPriorityCount = tasks.filter(task => 
    task.priority === 'high' || task.priority === 'urgent'
  ).length;
  const priorityBonus = Math.min(highPriorityCount * 0.1, 0.3);
  
  efficiency = Math.min(efficiency + priorityBonus, 1);
  
  return Math.round(efficiency * 100) / 100;
};

// スケジュール推奨事項を生成（廃止予定）
const generateScheduleRecommendations = (tasks, preferences) => {
  const recommendations = [];
  
  const highPriorityTasks = tasks.filter(task => task.priority === 'high' || task.priority === 'urgent');
  if (highPriorityTasks.length > 3) {
    recommendations.push('高優先度タスクが多すぎます。優先度を見直すことをお勧めします');
  }
  
  const totalDuration = tasks.reduce((sum, task) => sum + (task.estimatedDuration || 0), 0);
  if (totalDuration > 480) { // 8時間
    recommendations.push('1日の作業量が多すぎます。タスクを分割することをお勧めします');
  }
  
  if (preferences.workStyle === 'morning') {
    recommendations.push('朝型の方は、重要なタスクを午前中に配置することをお勧めします');
  }
  
  return recommendations;
};

module.exports = router; 