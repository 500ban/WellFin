import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../services/integration_test_service.dart';

class IntegrationTestPage extends ConsumerStatefulWidget {
  const IntegrationTestPage({super.key});

  @override
  ConsumerState<IntegrationTestPage> createState() => _IntegrationTestPageState();
}

class _IntegrationTestPageState extends ConsumerState<IntegrationTestPage> {
  final Logger _logger = Logger();
  bool _isLoading = false;
  String _result = '';
  String _error = '';
  late IntegrationTestService _testService;

  @override
  void initState() {
    super.initState();
    _testService = IntegrationTestService(ref);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔗 統合テスト'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 分析機能統合テスト
            _buildTestCard(
              title: '📊 分析機能統合テスト',
              description: '分析機能とデータ連携の統合テスト',
              onPressed: _runAnalyticsIntegrationTest,
            ),
            
            const SizedBox(height: 16),
            
            // 通知機能統合テスト
            _buildTestCard(
              title: '🔔 通知機能統合テスト',
              description: '通知機能と分析結果連携の統合テスト',
              onPressed: _runNotificationIntegrationTest,
            ),
            
            const SizedBox(height: 16),
            
            // パフォーマンステスト
            _buildTestCard(
              title: '⚡ パフォーマンステスト',
              description: '大量データでの動作確認',
              onPressed: _runPerformanceTest,
            ),
            
            const SizedBox(height: 16),
            
            // UI/UXテスト
            _buildTestCard(
              title: '🎨 UI/UXテスト',
              description: 'ユーザビリティとレスポンシブ確認',
              onPressed: _runUIUXTest,
            ),
            
            const SizedBox(height: 16),
            
            // エラーハンドリングテスト
            _buildTestCard(
              title: '🛡️ エラーハンドリングテスト',
              description: '異常時の動作確認',
              onPressed: _runErrorHandlingTest,
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
                        const Icon(Icons.info_outline, color: Colors.purple),
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
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 分析機能統合テスト
  Future<void> _runAnalyticsIntegrationTest() async {
    setState(() {
      _isLoading = true;
      _result = '';
      _error = '';
    });

    try {
      final result = await _testService.runAnalyticsIntegrationTest();
      
      if (result.success) {
        setState(() {
          _result = result.details ?? 'テスト完了';
        });
      } else {
        setState(() {
          _error = result.error ?? 'テスト失敗';
        });
      }
    } catch (e) {
      setState(() {
        _error = '分析機能統合テストエラー: $e';
      });
      _logger.e('分析機能統合テストエラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 通知機能統合テスト
  Future<void> _runNotificationIntegrationTest() async {
    setState(() {
      _isLoading = true;
      _result = '';
      _error = '';
    });

    try {
      final result = await _testService.runNotificationIntegrationTest();
      
      if (result.success) {
        setState(() {
          _result = result.details ?? 'テスト完了';
        });
      } else {
        setState(() {
          _error = result.error ?? 'テスト失敗';
        });
      }
    } catch (e) {
      setState(() {
        _error = '通知機能統合テストエラー: $e';
      });
      _logger.e('通知機能統合テストエラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// パフォーマンステスト
  Future<void> _runPerformanceTest() async {
    setState(() {
      _isLoading = true;
      _result = '';
      _error = '';
    });

    try {
      final result = await _testService.runPerformanceTest();
      
      if (result.success) {
        setState(() {
          _result = result.details ?? 'テスト完了';
        });
      } else {
        setState(() {
          _error = result.error ?? 'テスト失敗';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'パフォーマンステストエラー: $e';
      });
      _logger.e('パフォーマンステストエラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// UI/UXテスト
  Future<void> _runUIUXTest() async {
    setState(() {
      _isLoading = true;
      _result = '';
      _error = '';
    });

    try {
      final result = await _testService.runUIUXTest();
      
      if (result.success) {
        setState(() {
          _result = result.details ?? 'テスト完了';
        });
      } else {
        setState(() {
          _error = result.error ?? 'テスト失敗';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'UI/UXテストエラー: $e';
      });
      _logger.e('UI/UXテストエラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// エラーハンドリングテスト
  Future<void> _runErrorHandlingTest() async {
    setState(() {
      _isLoading = true;
      _result = '';
      _error = '';
    });

    try {
      final result = await _testService.runErrorHandlingTest();
      
      if (result.success) {
        setState(() {
          _result = result.details ?? 'テスト完了';
        });
      } else {
        setState(() {
          _error = result.error ?? 'テスト失敗';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'エラーハンドリングテストエラー: $e';
      });
      _logger.e('エラーハンドリングテストエラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


} 