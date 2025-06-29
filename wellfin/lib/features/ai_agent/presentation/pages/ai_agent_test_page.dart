import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../../shared/services/ai_agent_service.dart';

class AIAgentTestPage extends StatefulWidget {
  const AIAgentTestPage({super.key});

  @override
  State<AIAgentTestPage> createState() => _AIAgentTestPageState();
}

class _AIAgentTestPageState extends State<AIAgentTestPage> {
  final Logger _logger = Logger();
  bool _isLoading = false;
  String _result = '';
  String _error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AIエージェント API テスト'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ヘルスチェック
            _buildTestCard(
              title: 'ヘルスチェック',
              description: 'APIサーバーの接続状態を確認',
              onPressed: _testHealthCheck,
            ),
            
            const SizedBox(height: 16),
            
            // タスク分析テスト
            _buildTestCard(
              title: 'タスク分析',
              description: 'タスクの詳細分析を実行',
              onPressed: _testAnalyzeTask,
            ),
            
            const SizedBox(height: 16),
            
            // スケジュール最適化テスト
            _buildTestCard(
              title: 'スケジュール最適化',
              description: 'タスクのスケジュール最適化を実行',
              onPressed: _testOptimizeSchedule,
            ),
            
            const SizedBox(height: 16),
            
            // 推奨事項テスト
            _buildTestCard(
              title: '推奨事項生成',
              description: 'ユーザー向けの推奨事項を生成',
              onPressed: _testRecommendations,
            ),
            
            const SizedBox(height: 24),
            
            // 結果表示エリア
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'テスト結果',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_error.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_result.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green),
                                        SizedBox(width: 8),
                                        Text(
                                          '成功',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _result,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard({
    required String title,
    required String description,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ヘルスチェックテスト
  Future<void> _testHealthCheck() async {
    _setLoading(true);
    _clearResults();

    try {
      final isHealthy = await AIAgentService.healthCheck();
      
      setState(() {
        _result = isHealthy 
          ? '✅ APIサーバーが正常に動作しています\nURL: ${AIAgentService.currentBaseUrl}'
          : '❌ APIサーバーに接続できませんでした';
      });
    } catch (e) {
      _logger.e('Health check failed', error: e);
      _setError('ヘルスチェックエラー: $e');
    } finally {
      _setLoading(false);
    }
  }

  // タスク分析テスト
  Future<void> _testAnalyzeTask() async {
    _setLoading(true);
    _clearResults();

    try {
      final result = await AIAgentService.analyzeTaskViaAPI(
        title: 'プロジェクト計画書作成',
        description: '新規プロジェクトの計画書を作成する必要があります。技術仕様書、スケジュール、リソース配分を含む包括的な計画書を作成してください。',
        priority: 'high',
        deadline: '2025-07-15',
        estimatedHours: 8,
      );
      
      setState(() {
        _result = _formatJsonResult(result);
      });
    } catch (e) {
      _logger.e('Task analysis failed', error: e);
      _setError('タスク分析エラー: $e');
    } finally {
      _setLoading(false);
    }
  }

  // スケジュール最適化テスト
  Future<void> _testOptimizeSchedule() async {
    _setLoading(true);
    _clearResults();

    try {
      final result = await AIAgentService.optimizeScheduleViaAPI(
        tasks: [
          {
            'title': 'プロジェクト計画書作成',
            'priority': 'high',
            'estimatedHours': 8,
            'deadline': '2025-07-15',
          },
          {
            'title': 'チームミーティング',
            'priority': 'medium',
            'estimatedHours': 2,
            'deadline': '2025-07-10',
          },
          {
            'title': '技術調査',
            'priority': 'low',
            'estimatedHours': 4,
            'deadline': '2025-07-20',
          },
        ],
        preferences: {
          'workHours': {
            'start': '09:00',
            'end': '18:00',
          },
          'breakTime': 60,
          'focusBlocks': 4,
        },
      );
      
      setState(() {
        _result = _formatJsonResult(result);
      });
    } catch (e) {
      _logger.e('Schedule optimization failed', error: e);
      _setError('スケジュール最適化エラー: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 推奨事項テスト
  Future<void> _testRecommendations() async {
    _setLoading(true);
    _clearResults();

    try {
      final result = await AIAgentService.getRecommendationsViaAPI(
        userProfile: {
          'productivityLevel': 'high',
          'preferredWorkHours': 'morning',
          'focusAreas': ['project_management', 'technical_skills'],
        },
        context: {
          'currentTasks': 5,
          'upcomingDeadlines': 2,
          'recentPerformance': 'good',
        },
      );
      
      setState(() {
        _result = _formatJsonResult(result);
      });
    } catch (e) {
      _logger.e('Recommendations failed', error: e);
      _setError('推奨事項生成エラー: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  void _clearResults() {
    setState(() {
      _result = '';
      _error = '';
    });
  }

  void _setError(String error) {
    setState(() {
      _error = error;
    });
  }

  String _formatJsonResult(Map<String, dynamic> result) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(result);
  }
} 