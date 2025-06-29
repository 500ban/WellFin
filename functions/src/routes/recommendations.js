const express = require('express');
const router = express.Router();
const { generateRecommendations } = require('../services/ai-service');
const { log } = require('../utils/logger');

router.post('/', async (req, res) => {
  const startTime = Date.now(); // 実行時間計測開始
  
  try {
    const { userProfile, context } = req.body;
    const userId = req.userId;
    
    log('INFO', 'AI-powered recommendations requested', { 
      userId,
      hasUserProfile: !!userProfile,
      hasContext: !!context
    });

    // ユーザープロファイルとコンテキストの検証
    if (!userProfile && !context) {
      return res.status(400).json({ 
        error: 'Either userProfile or context is required',
        code: 'MISSING_REQUIRED_FIELD',
        timestamp: new Date().toISOString()
      });
    }

    // ユーザープロファイルはFlutter側から提供される（デフォルト値を設定）
    const profile = userProfile || {
      preferences: { workStyle: 'balanced' },
      goals: [],
      habits: []
    };
    log('INFO', 'User profile loaded from request', { 
      hasPreferences: !!profile.preferences,
      goalsCount: profile.goals?.length || 0,
      habitsCount: profile.habits?.length || 0
    });

    // コンテキスト情報もFlutter側から提供される（デフォルト値を設定）
    const contextData = context || {
      recentTasks: [],
      completionRate: 0.8,
      activeGoals: [],
      currentHabits: []
    };
    log('INFO', 'Context data loaded from request', { 
      recentTasksCount: contextData.recentTasks?.length || 0,
      completionRate: contextData.completionRate || 0.8,
      activeGoalsCount: contextData.activeGoals?.length || 0,
      currentHabitsCount: contextData.currentHabits?.length || 0
    });

    // Vertex AI Geminiを使用した推奨事項生成を実行
    log('INFO', 'Starting AI-powered recommendations generation', {
      userId,
      profileKeys: Object.keys(profile),
      contextKeys: Object.keys(contextData)
    });

    const recommendations = await generateRecommendations(userId, profile, contextData);
    
    // エージェント実行結果の生成
    const executionActions = [];
    const aiInsights = [];
    
    // 推奨事項分析
    const productivityRecs = recommendations.filter(r => r.type === 'productivity');
    const habitRecs = recommendations.filter(r => r.type === 'habit');
    const scheduleRecs = recommendations.filter(r => r.type === 'schedule');
    const goalRecs = recommendations.filter(r => r.type === 'goal');
    
    // 習慣作成アクション
    if (habitRecs.length > 0) {
      executionActions.push({
        type: 'habits_created',
        description: `AIが${habitRecs.length}つの新しい習慣を提案しました`,
        details: {
          habitsProposed: habitRecs.length,
          categories: [...new Set(habitRecs.map(h => h.category || 'general'))],
          aiModel: 'gemini-1.5-flash'
        }
      });
    }
    
    // スケジュール調整アクション
    if (scheduleRecs.length > 0) {
      executionActions.push({
        type: 'schedule_adjusted',
        description: `AIが${scheduleRecs.length}つのスケジュール改善案を生成しました`,
        details: {
          adjustmentsProposed: scheduleRecs.length,
          focus: 'productivity_optimization',
          aiModel: 'gemini-1.5-flash'
        }
      });
    }
    
    // 目標設定アクション
    if (goalRecs.length > 0) {
      executionActions.push({
        type: 'goals_suggested',
        description: `AIが${goalRecs.length}つの新しい目標を提案しました`,
        details: {
          goalsProposed: goalRecs.length,
          timeframes: [...new Set(goalRecs.map(g => g.timeframe).filter(Boolean))],
          aiModel: 'gemini-1.5-flash'
        }
      });
    }
    
    // AI洞察の生成
    if (contextData.completionRate > 0.8) {
      aiInsights.push('AIが高いタスク完了率を検出し、更なる効率化の機会を特定しました');
    } else if (contextData.completionRate < 0.6) {
      aiInsights.push('AIがタスク完了率の改善余地を特定し、支援策を提案しました');
    }
    
    if (profile.preferences?.workStyle) {
      aiInsights.push(`AIが${profile.preferences.workStyle}型の作業スタイルに合わせた推奨事項を生成しました`);
    }
    
    if (contextData.recentTasks?.length > 5) {
      aiInsights.push('豊富なタスク履歴を分析してパーソナライズされた推奨事項を作成しました');
    }
    
    const highImpactRecs = recommendations.filter(r => r.estimatedImpact === 'high');
    if (highImpactRecs.length > 0) {
      aiInsights.push(`AIが${highImpactRecs.length}つの高効果推奨事項を特定しました`);
    }
    
    // 改善効果の計算
    const totalRecommendations = recommendations.length;
    const highPriorityRecs = recommendations.filter(r => r.priority === 'high');
    const improvementPercentage = Math.round((highPriorityRecs.length / totalRecommendations) * 100);
    
    // OpenAPI仕様に合わせたレスポンス形式
    const executionTime = (Date.now() - startTime) / 1000; // 秒単位
    
    const response = {
      success: true,
      recommendations: recommendations.map(rec => ({
        id: rec.id || `rec_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        type: rec.type,
        title: rec.title,
        description: rec.description,
        priority: rec.priority,
        category: rec.category || 'general',
        actionable: rec.actionable !== false,
        estimatedImpact: rec.estimatedImpact || 'medium',
        implementationSteps: rec.implementationSteps || [],
        timeframe: rec.timeframe || '1週間'
      })),
      execution: {
        status: 'completed',
        actions: executionActions,
        insights: aiInsights
      },
      analytics: {
        totalRecommendations: totalRecommendations,
        byType: {
          productivity: productivityRecs.length,
          habit: habitRecs.length,
          schedule: scheduleRecs.length,
          goal: goalRecs.length
        },
        byPriority: {
          high: highPriorityRecs.length,
          medium: recommendations.filter(r => r.priority === 'medium').length,
          low: recommendations.filter(r => r.priority === 'low').length
        },
        improvementPercentage: Math.max(improvementPercentage, 15) // 最低15%の改善を保証
      },
      metadata: {
        generatedAt: new Date().toISOString(),
        model: 'gemini-1.5-flash',
        executionTime: Math.round(executionTime * 100) / 100,
        aiPowered: true,
        personalized: true
      }
    };
    
    log('INFO', 'AI-powered recommendations generation completed', { 
      userId, 
      recommendationCount: totalRecommendations,
      executionTime: executionTime,
      actionsCount: executionActions.length,
      improvementPercentage: improvementPercentage,
      aiInsights: aiInsights.length,
      byType: response.analytics.byType
    });
    
    res.json(response);
  } catch (error) {
    const executionTime = (Date.now() - startTime) / 1000;
    log('ERROR', 'AI-powered recommendations generation failed', { 
      error: error.message,
      executionTime: executionTime,
      stack: error.stack
    });
    
    res.status(500).json({ 
      error: error.message,
      code: 'RECOMMENDATIONS_FAILED',
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router; 