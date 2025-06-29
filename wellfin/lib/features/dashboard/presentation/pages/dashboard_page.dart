import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/ai_agent_service.dart';
import '../../../tasks/presentation/pages/task_list_page.dart';
import '../../../tasks/presentation/providers/task_provider.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/widgets/task_filter_bar.dart';
import '../../../habits/presentation/pages/habit_list_page.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../habits/domain/entities/habit.dart';
import '../../../goals/presentation/pages/goal_list_page.dart';
import '../../../goals/presentation/providers/goal_provider.dart';
import '../../../ai_agent/presentation/pages/ai_agent_test_page.dart';

// AI推奨状態管理のProvider
final aiRecommendationsProvider = StateNotifierProvider<AIRecommendationsNotifier, AsyncValue<RecommendationsResult?>>((ref) {
  return AIRecommendationsNotifier();
});

class AIRecommendationsNotifier extends StateNotifier<AsyncValue<RecommendationsResult?>> {
  AIRecommendationsNotifier() : super(const AsyncValue.data(null));

  Future<void> loadRecommendations({
    Map<String, dynamic>? userProfile,
    Map<String, dynamic>? context,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await AIAgentService.getRecommendations(
        userProfile: userProfile,
        context: context,
      );
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void clearRecommendations() {
    state = const AsyncValue.data(null);
  }
}

// AI分析状態管理のProvider
final aiAnalysisProvider = StateNotifierProvider<AIAnalysisNotifier, AsyncValue<TaskAnalysisResult?>>((ref) {
  return AIAnalysisNotifier();
});

class AIAnalysisNotifier extends StateNotifier<AsyncValue<TaskAnalysisResult?>> {
  AIAnalysisNotifier() : super(const AsyncValue.data(null));

  Future<void> analyzeTask(String userInput) async {
    state = const AsyncValue.loading();
    try {
      final result = await AIAgentService.analyzeTask(userInput: userInput);
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void clearAnalysis() {
    state = const AsyncValue.data(null);
  }
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // ダッシュボード読み込み時にタスクと習慣と目標を取得
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskProvider.notifier).loadTasks();
      ref.read(habitProvider.notifier).loadTodayHabits();
      ref.read(goalNotifierProvider.notifier).loadGoals();
      
      // AI推奨事項も取得
      _loadAIRecommendations();
    });
  }

  void _loadAIRecommendations() async {
    try {
      print('AI推奨事項の取得を開始: APIキー認証方式');
      
      final userData = ref.read(currentUserDataProvider);
      userData.whenData((userModel) {
        if (userModel != null) {
          final userProfile = {
            'goals': ['生産性向上', 'ワークライフバランス改善'],
            'preferences': {
              'workStyle': 'morning',
              'focusDuration': 90,
            },
          };
          
          final context = {
            'currentTasks': ['日常業務', 'プロジェクト推進'],
            'recentActivity': ['朝の運動習慣', '読書時間確保'],
          };
          
          ref.read(aiRecommendationsProvider.notifier).loadRecommendations(
            userProfile: userProfile,
            context: context,
          );
        } else {
          print('AI推奨事項の取得をスキップ: ユーザーデータが未取得');
        }
      });
    } catch (e) {
      print('AI推奨事項の読み込みでエラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(currentUserDataProvider);
    final authState = ref.watch(authStateProvider);

    // 認証状態が変更された場合の処理
    authState.when(
      data: (user) {
        if (user == null) {
          // ユーザーがログアウトした場合、ログインページに遷移
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            }
          });
        }
      },
      loading: () {},
      error: (_, __) {},
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WellFin',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showSettingsBottomSheet();
            },
            tooltip: '設定',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                final authActions = ref.read(authActionsProvider);
                await authActions.signOut();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ログアウトに失敗しました: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            tooltip: 'ログアウト',
          ),
        ],
      ),
      body: userData.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('ユーザー情報が見つかりません'),
            );
          }
          return _buildDashboardContent(context, user);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('エラーが発生しました: $error'),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ユーザー情報カード
          _buildUserInfoCard(user),
          const SizedBox(height: 24),
          
          // 今日のサマリー
          _buildTodaySummaryCard(user),
          const SizedBox(height: 24),
          
          // クイックアクセスメニュー
          _buildQuickAccessMenu(),
          const SizedBox(height: 24),
          
          // AI推奨セクション
          _buildAIRecommendationsCard(),
          const SizedBox(height: 24),
          
          // スケジュール最適化セクション
          _buildScheduleOptimizationCard(),
          const SizedBox(height: 24),
          
          // 習慣トラッキング
          _buildHabitsCard(),
          const SizedBox(height: 24),
          
          // 今日のタスク
          _buildTodayTasksCard(context),
          const SizedBox(height: 24),
          
          // 生産性分析
          _buildProductivityCard(user),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: user.photoURL != null
                  ? NetworkImage(user.photoURL!)
                  : null,
              child: user.photoURL == null
                  ? Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.displayName}さん',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '今日を楽しみましょう！',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummaryCard(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今日のサマリー',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Consumer(
              builder: (context, ref, child) {
                final taskState = ref.watch(taskProvider);
                final habitState = ref.watch(habitProvider);
                
                return taskState.when(
                  data: (tasks) {
                    final todayTasks = tasks.where((t) => t.isToday).toList();
                    final completedToday = todayTasks.where((t) => t.isCompleted).length;
                    final totalToday = todayTasks.length;
                    final todayCompletionRate = totalToday > 0 ? completedToday / totalToday : 0.0;
                    final highPriorityToday = todayTasks.where((t) => 
                      (t.priority == TaskPriority.high || t.priority == TaskPriority.urgent) && 
                      !t.isCompleted
                    ).length;
                    
                    return habitState.when(
                      data: (habits) {
                        final activeHabits = habits.where((h) => h.status == HabitStatus.active).toList();
                        final completedHabits = activeHabits.where((h) => h.isCompletedToday).length;
                        final totalHabits = activeHabits.length;
                        final completionRate = totalHabits > 0 ? completedHabits / totalHabits : 0.0;
                        
                        return Column(
                          children: [
                            // タスク統計
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryItem(
                                    '今日のタスク',
                                    '$completedToday/$totalToday',
                                    Icons.task_alt,
                                    Colors.green,
                                  ),
                                ),
                                Expanded(
                                  child: _buildSummaryItem(
                                    'タスク完了率',
                                    '${(todayCompletionRate * 100).toInt()}%',
                                    Icons.trending_up,
                                    Colors.green,
                                  ),
                                ),
                                Expanded(
                                  child: _buildSummaryItem(
                                    '高優先度',
                                    '$highPriorityToday',
                                    Icons.priority_high,
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // 習慣統計
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryItem(
                                    '今日の習慣',
                                    '$completedHabits/$totalHabits',
                                    Icons.repeat,
                                    Colors.orange,
                                  ),
                                ),
                                Expanded(
                                  child: _buildSummaryItem(
                                    '習慣完了率',
                                    '${(completionRate * 100).toInt()}%',
                                    Icons.check_circle,
                                    Colors.orange,
                                  ),
                                ),
                                Expanded(
                                  child: _buildSummaryItem(
                                    '連続達成',
                                    '${user.stats.streakDays}日',
                                    Icons.local_fire_department,
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // 目標統計
                            Consumer(
                              builder: (context, ref, child) {
                                final goalState = ref.watch(goalNotifierProvider);
                                return goalState.when(
                                  data: (goals) {
                                    final activeGoals = goals.where((g) => g.isInProgress).length;
                                    final completedGoals = goals.where((g) => g.isCompleted).length;
                                    final totalGoals = goals.length;
                                    final goalCompletionRate = totalGoals > 0 ? completedGoals / totalGoals : 0.0;
                                    
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: _buildSummaryItem(
                                            'アクティブ目標',
                                            '$activeGoals',
                                            Icons.flag,
                                            Colors.purple,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildSummaryItem(
                                            '目標完了率',
                                            '${(goalCompletionRate * 100).toInt()}%',
                                            Icons.trending_up,
                                            Colors.purple,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildSummaryItem(
                                            '総目標数',
                                            '$totalGoals',
                                            Icons.assessment,
                                            Colors.purple,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                  loading: () => Row(
                                    children: [
                                      Expanded(
                                        child: _buildSummaryItem(
                                          'アクティブ目標',
                                          '読み込み中...',
                                          Icons.flag,
                                          Colors.purple,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildSummaryItem(
                                          '目標完了率',
                                          '読み込み中...',
                                          Icons.trending_up,
                                          Colors.purple,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildSummaryItem(
                                          '総目標数',
                                          '読み込み中...',
                                          Icons.assessment,
                                          Colors.purple,
                                        ),
                                      ),
                                    ],
                                  ),
                                  error: (_, __) => Row(
                                    children: [
                                      Expanded(
                                        child: _buildSummaryItem(
                                          'アクティブ目標',
                                          'エラー',
                                          Icons.flag,
                                          Colors.purple,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildSummaryItem(
                                          '目標完了率',
                                          'エラー',
                                          Icons.trending_up,
                                          Colors.purple,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildSummaryItem(
                                          '総目標数',
                                          'エラー',
                                          Icons.assessment,
                                          Colors.purple,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                      loading: () => Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              '今日のタスク',
                              '$completedToday/$totalToday',
                              Icons.task_alt,
                              Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              'タスク完了率',
                              '${(todayCompletionRate * 100).toInt()}%',
                              Icons.trending_up,
                              Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              '高優先度',
                              '$highPriorityToday',
                              Icons.priority_high,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      error: (_, __) => Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              '今日のタスク',
                              '$completedToday/$totalToday',
                              Icons.task_alt,
                              Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              'タスク完了率',
                              '${(todayCompletionRate * 100).toInt()}%',
                              Icons.trending_up,
                              Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              '高優先度',
                              '$highPriorityToday',
                              Icons.priority_high,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          '今日のタスク',
                          '読み込み中...',
                          Icons.task_alt,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          'タスク完了率',
                          '読み込み中...',
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          '高優先度',
                          '読み込み中...',
                          Icons.priority_high,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  error: (_, __) => Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          '今日のタスク',
                          'エラー',
                          Icons.task_alt,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          'タスク完了率',
                          'エラー',
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          '高優先度',
                          'エラー',
                          Icons.priority_high,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessMenu() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'クイックアクセス',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // メインアクション
            Row(
              children: [
                Expanded(
                  child: _buildQuickAccessItem(
                    'タスク',
                    Icons.task,
                    Colors.green,
                    () => _navigateToTaskListWithFilter(TaskFilter.all),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAccessItem(
                    '習慣',
                    Icons.repeat,
                    Colors.orange,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const HabitListPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAccessItem(
                    '目標',
                    Icons.flag,
                    Colors.purple,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const GoalListPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // デバッグ情報（開発環境のみ）
            if (const bool.fromEnvironment('dart.vm.product') == false) ...[
              const SizedBox(height: 12),
            Row(
              children: [
                  Expanded(
                    child: _buildQuickAccessItem(
                      'API接続テスト',
                      Icons.network_check,
                      Colors.teal,
                      () {
                        _showApiConnectionDialog();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAccessItem(
                    'AIテスト',
                    Icons.psychology,
                    Colors.blue,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AIAgentTestPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()), // 空のスペース
              ],
            ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessItem(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIRecommendationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI推奨',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    _loadAIRecommendations();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Consumer(
              builder: (context, ref, child) {
                final aiRecommendationsState = ref.watch(aiRecommendationsProvider);
                
                return aiRecommendationsState.when(
                  data: (result) {
                    if (result == null) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '今日の生産性を向上させるためのAI提案を準備中...',
              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            CircularProgressIndicator(),
                          ],
                        ),
                      );
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AIが${result.recommendations.length}つの推奨事項を分析しました',
                          style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
                        
                        // 推奨事項リスト
                        ...result.recommendations.take(3).map((rec) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildAIRecommendationItem(
                            rec.title,
                            rec.description,
                            _getRecommendationIcon(rec.type),
                            _getRecommendationColor(rec.priority),
                            rec.estimatedImpact,
            ),
                        )),
                        
                        // 実行結果の表示
                        if (result.execution.actions.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.blue,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'AI実行結果: ${result.execution.status}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
            ),
            const SizedBox(height: 8),
                                ...result.execution.actions.take(2).map((action) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• ${action.description}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],
                        
                        // より多くの推奨事項を表示するボタン
                        if (result.recommendations.length > 3) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              _showAllRecommendations(result);
                            },
                            child: Text('他${result.recommendations.length - 3}件の推奨事項を表示'),
                          ),
                        ],
                      ],
                      );
                  },
                  loading: () => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'AIが最新の推奨事項を分析中...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        CircularProgressIndicator(),
          ],
        ),
      ),
                  error: (error, stack) => Column(
                    children: [
                      Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
            size: 20,
          ),
                            const SizedBox(width: 8),
          Expanded(
            child: Text(
                                'AI推奨の取得に失敗しました: ${error.toString()}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
            ),
          ),
        ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          _loadAIRecommendations();
                        },
                        child: const Text('再試行'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildTodayTasksCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.today,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                const Text(
                  '今日のタスク',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                          onPressed: () {
                            _navigateToTaskListWithFilter(TaskFilter.today);
                          },
                          child: const Text('設定'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Consumer(
              builder: (context, ref, child) {
                final taskState = ref.watch(taskProvider);
                return taskState.when(
                  data: (tasks) {
                    final todayTasks = tasks.where((task) => task.isToday).toList();
                    
                    if (todayTasks.isEmpty) {
                      // 今日のタスクが最初から存在しない場合
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.calendar_today_outlined,
                                size: 32,
                                color: Colors.blue[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '今日のタスクはありません',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '新しいタスクを追加して、\n生産的な一日を始めましょう',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 14,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    
                    // 今日のタスクがすべて完了している場合の判定
                    final completedTodayTasks = todayTasks.where((t) => t.isCompleted).length;
                    final allTasksCompleted = completedTodayTasks == todayTasks.length && todayTasks.isNotEmpty;
                    
                    if (allTasksCompleted) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle,
                                size: 32,
                                color: Colors.green[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '今日のタスクは完了です！',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '素晴らしい一日でした\nお疲れ様でした！',
                              style: TextStyle(
                                color: Colors.green[600],
                                fontSize: 14,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    
                    // 優先度順にソート
                    todayTasks.sort((a, b) {
                      if (a.isCompleted != b.isCompleted) {
                        return a.isCompleted ? 1 : -1;
                      }
                      return b.priority.index.compareTo(a.priority.index);
                    });
                    
                    return Column(
                      children: [
                        // 進捗バー
                        if (todayTasks.isNotEmpty) ...[
                          Consumer(
                            builder: (context, ref, child) {
                              final completedCount = todayTasks.where((t) => t.isCompleted).length;
                              final totalCount = todayTasks.length;
                              final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
                              
                              return Column(
                                children: [
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${(progress * 100).toInt()}% 完了',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            },
                          ),
                        ],
                        
                        // タスクリスト
                        ...todayTasks.map((task) => _buildTodayTaskItem(task, context)),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[400],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'タスクの読み込みに失敗しました',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(taskProvider.notifier).loadTasks();
                          },
                          child: const Text('再試行'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTaskItem(Task task, BuildContext context) {
    final isCompleted = task.isCompleted;
    
    return GestureDetector(
      onTap: () {
        if (isCompleted) {
          ref.read(taskProvider.notifier).uncompleteTask(task.id);
        } else {
          ref.read(taskProvider.notifier).completeTask(task.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            // タスク情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タスクタイトルと優先度バッジを縦に配置
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? Colors.grey[600] : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // 優先度バッジとサブタスク情報を横に配置
                  Row(
                    children: [
                      // 優先度バッジ
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(task.priority).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          task.priority.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getPriorityColor(task.priority),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      if (task.subTasks.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.checklist,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${task.subTasks.where((t) => t.isCompleted).length}/${task.subTasks.length}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // 完了チェックボックス（右端）
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsCard() {
    final habitsState = ref.watch(habitProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.repeat,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                const Text(
                  '習慣トラッキング',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HabitListPage(),
                      ),
                    );
                  },
                  child: const Text('設定'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            habitsState.when(
              data: (habits) {
                // statusがactiveの習慣のみ表示
                final activeHabits = habits.where((h) => h.status == HabitStatus.active).toList();
                if (activeHabits.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '今日の習慣はありません\n新しい習慣を作成しましょう',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                }
                final completedHabits = activeHabits.where((h) => h.isCompletedToday).length;
                final totalHabits = activeHabits.length;
                final completionRate = totalHabits > 0 ? completedHabits / totalHabits : 0.0;
                return Column(
                  children: [
                    // サマリー情報
                    Row(
                      children: [
                        Expanded(
                          child: _buildHabitSummaryItem(
                            '完了',
                            completedHabits,
                            totalHabits,
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildHabitSummaryItem(
                            '残り',
                            totalHabits - completedHabits,
                            totalHabits,
                            Icons.pending,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 進捗バー
                    LinearProgressIndicator(
                      value: completionRate,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(completionRate * 100).toInt()}% 完了',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 習慣リスト（最大3つまで表示）
                    ...activeHabits.take(3).map((habit) => _buildHabitListItem(habit)),
                    if (activeHabits.length > 3) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          '他 ${activeHabits.length - 3} 個の習慣...',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '習慣の読み込みに失敗しました',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(habitProvider.notifier).loadTodayHabits();
                        },
                        child: const Text('再試行'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitSummaryItem(String label, int count, int total, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildHabitListItem(Habit habit) {
    final isCompleted = habit.isCompletedToday;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCompleted ? Colors.green.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _getCategoryColor(habit.category),
              child: Icon(
                habit.frequency.icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          habit.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? Colors.grey : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(habit.category).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          habit.category.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getCategoryColor(habit.category),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        habit.frequency.icon,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        habit.frequency.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.local_fire_department,
                        size: 12,
                        color: Colors.orange[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${habit.currentStreak}日',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                // 習慣の日々の取り組みを記録
                ref.read(habitProvider.notifier).recordDailyCompletion(habit.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isCompleted ? Colors.green : Colors.grey,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(HabitCategory category) {
    switch (category) {
      case HabitCategory.health:
        return Colors.green;
      case HabitCategory.work:
        return Colors.blue;
      case HabitCategory.learning:
        return Colors.purple;
      case HabitCategory.fitness:
        return Colors.orange;
      case HabitCategory.mindfulness:
        return Colors.teal;
      case HabitCategory.social:
        return Colors.pink;
      case HabitCategory.financial:
        return Colors.amber;
      case HabitCategory.creative:
        return Colors.indigo;
      case HabitCategory.personal:
        return Colors.cyan;
      case HabitCategory.other:
        return Colors.grey;
    }
  }

  Widget _buildProductivityCard(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                const Text(
                  '生産性分析',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // 詳細分析ページに遷移
                  },
                  child: const Text('詳細'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // タスク統計
            Consumer(
              builder: (context, ref, child) {
                final taskState = ref.watch(taskProvider);
                return taskState.when(
                  data: (tasks) {
                    final totalTasks = tasks.length;
                    final completedTasks = tasks.where((t) => t.isCompleted).length;
                    final todayTasks = tasks.where((t) => t.isToday).toList();
                    final completedToday = todayTasks.where((t) => t.isCompleted).length;
                    final totalToday = todayTasks.length;
                    
                    // 優先度別分布
                    final highPriorityTasks = tasks.where((t) => t.priority == TaskPriority.high || t.priority == TaskPriority.urgent).length;
                    final mediumPriorityTasks = tasks.where((t) => t.priority == TaskPriority.medium).length;
                    final lowPriorityTasks = tasks.where((t) => t.priority == TaskPriority.low).length;
                    
                    // サブタスク統計
                    final totalSubTasks = tasks.fold<int>(0, (sum, task) => sum + task.subTasks.length);
                    final completedSubTasks = tasks.fold<int>(0, (sum, task) => sum + task.subTasks.where((st) => st.isCompleted).length);
                    
                    return Column(
                      children: [
                        // メイン統計
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                '全体完了率',
                                '${totalTasks > 0 ? ((completedTasks / totalTasks) * 100).toInt() : 0}%',
                                Icons.check_circle,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatItem(
                                '今日の完了率',
                                '${totalToday > 0 ? ((completedToday / totalToday) * 100).toInt() : 0}%',
                                Icons.today,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 優先度分布
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                '高優先度',
                                '$highPriorityTasks',
                                Icons.priority_high,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatItem(
                                '中優先度',
                                '$mediumPriorityTasks',
                                Icons.remove,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatItem(
                                '低優先度',
                                '$lowPriorityTasks',
                                Icons.keyboard_arrow_down,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // サブタスク進捗
                        if (totalSubTasks > 0) ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  'サブタスク',
                                  '$completedSubTasks/$totalSubTasks',
                                  Icons.checklist,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatItem(
                                  'サブタスク完了率',
                                  '${totalSubTasks > 0 ? ((completedSubTasks / totalSubTasks) * 100).toInt() : 0}%',
                                  Icons.analytics,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // ユーザー統計
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                '今週の完了率',
                                '${(user.stats.completionRate * 100).toInt()}%',
                                Icons.trending_up,
                                const Color(0xFF2196F3),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatItem(
                                '連続達成日数',
                                '${user.stats.streakDays}日',
                                Icons.local_fire_department,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[400],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '統計の読み込みに失敗しました',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
    }
  }

  void _navigateToTaskListWithFilter(TaskFilter filter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskListPage(initialFilter: filter),
      ),
    );
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ハンドル
            Container(
              margin: const EdgeInsets.only(top: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // タイトル
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.settings, size: 28, color: Colors.blue),
                  const SizedBox(width: 16),
                  const Text(
                    '設定',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 設定メニュー
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // 管理機能セクション
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      '管理機能',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  _buildSettingsItem(
                    icon: Icons.task_alt,
                    title: 'タスク管理',
                    subtitle: 'タスクの作成・編集・管理',
                    iconColor: Colors.green,
                    backgroundColor: Colors.green.withValues(alpha: 0.05),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTaskListWithFilter(TaskFilter.all);
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.repeat,
                    title: '習慣設定',
                    subtitle: '習慣の作成・編集・管理',
                    iconColor: Colors.orange,
                    backgroundColor: Colors.orange.withValues(alpha: 0.05),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const HabitListPage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.flag,
                    title: '目標設定',
                    subtitle: '目標の作成・編集・管理',
                    iconColor: Colors.purple,
                    backgroundColor: Colors.purple.withValues(alpha: 0.05),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const GoalListPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // アプリ設定セクション
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'アプリ設定',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  _buildSettingsItem(
                    icon: Icons.notifications,
                    title: '通知設定',
                    subtitle: 'プッシュ通知の管理',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.info,
                    title: 'アプリについて',
                    subtitle: 'バージョン情報',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (iconColor ?? Colors.blue).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? Colors.blue, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }

  // AI推奨事項表示用のヘルパーメソッド
  Widget _buildAIRecommendationItem(
    String title,
    String description,
    IconData icon,
    Color color,
    String impact,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getImpactColor(impact).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  impact.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getImpactColor(impact),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  IconData _getRecommendationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'productivity':
        return Icons.trending_up;
      case 'habit':
        return Icons.repeat;
      case 'schedule':
        return Icons.schedule;
      case 'goal':
        return Icons.flag;
      case 'health':
        return Icons.health_and_safety;
      case 'work':
        return Icons.work;
      default:
        return Icons.lightbulb;
    }
  }

  Color _getRecommendationColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Color _getImpactColor(String impact) {
    switch (impact.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildScheduleOptimizationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  color: Colors.purple,
                ),
                const SizedBox(width: 8),
                const Text(
                  'スケジュール最適化',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    _optimizeSchedule();
                  },
                  tooltip: '最適化実行',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Consumer(
              builder: (context, ref, child) {
                final taskState = ref.watch(taskProvider);
                
                return taskState.when(
                  data: (tasks) {
                    final uncompletedTasks = tasks.where((t) => !t.isCompleted).toList();
                    
                    if (uncompletedTasks.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple[200]!),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 32,
                              color: Colors.purple[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'すべてのタスクが完了しています',
                              style: TextStyle(
                                color: Colors.purple[700],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final todayTasks = uncompletedTasks.where((t) => t.isToday).length;
                    final upcomingTasks = uncompletedTasks.where((t) => !t.isToday).length;
                    final highPriorityTasks = uncompletedTasks.where((t) => 
                      t.priority == TaskPriority.high || t.priority == TaskPriority.urgent
                    ).length;
                    
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildOptimizationStatItem(
                                '今日',
                                '$todayTasks',
                                Icons.today,
                                Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildOptimizationStatItem(
                                '予定',
                                '$upcomingTasks',
                                Icons.schedule,
                                Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildOptimizationStatItem(
                                '高優先度',
                                '$highPriorityTasks',
                                Icons.priority_high,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.purple[600],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'AIがあなたのタスクを分析し、最適なスケジュールを提案します',
                                  style: TextStyle(
                                    color: Colors.purple[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[400],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'タスクの読み込みに失敗しました',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _optimizeSchedule() async {
    try {
      final taskState = ref.read(taskProvider);
      await taskState.when(
        data: (tasks) async {
          final uncompletedTasks = tasks.where((t) => !t.isCompleted).toList();
          
          if (uncompletedTasks.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('最適化するタスクがありません'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }
          
          // タスクデータを準備
          final taskData = uncompletedTasks.map((task) => {
            'id': task.id,
            'title': task.title,
            'priority': task.priority.name,
            'estimatedDuration': task.estimatedDuration,
            'scheduledDate': task.scheduledDate.toIso8601String(),
            'difficulty': task.difficulty.name,
          }).toList();
          
          // スケジュール最適化APIを呼び出し
          final result = await AIAgentService.optimizeSchedule(
            tasks: taskData,
            preferences: {
              'workHours': {
                'start': '09:00',
                'end': '18:00',
              },
              'breakTime': 60,
              'focusBlocks': 4,
            },
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('スケジュールを最適化しました（${result.optimizedSchedule.length}件のタスク）'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: '確認',
                  onPressed: () {
                    _navigateToTaskListWithFilter(TaskFilter.all);
                  },
                ),
              ),
            );
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('スケジュール最適化に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAllRecommendations(RecommendationsResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ハンドル
            Container(
              margin: const EdgeInsets.only(top: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // タイトル
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.psychology, size: 28, color: Colors.green),
                  const SizedBox(width: 16),
                  Text(
                    'AI推奨事項 (${result.recommendations.length}件)',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 推奨事項リスト
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: result.recommendations.length,
                itemBuilder: (context, index) {
                  final rec = result.recommendations[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildAIRecommendationItem(
                      rec.title,
                      rec.description,
                      _getRecommendationIcon(rec.type),
                      _getRecommendationColor(rec.priority),
                      rec.estimatedImpact,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApiConnectionDialog() async {
    // API接続と認証状態をテストするダイアログを表示
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API接続テスト'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('接続テストを実行中...'),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
    
    try {
      // 1. Firebase認証状態をチェック
      final authStatus = await AIAgentService.checkAuthStatus();
      
      // 2. API接続をテスト
      final healthCheck = await AIAgentService.healthCheck();
      
      // 3. 結果をダイアログで表示
      if (mounted) {
        Navigator.of(context).pop(); // ローディングダイアログを閉じる
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('API接続テスト結果'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                      const Text(
                      '認証状態:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('✅ 認証方式: ${authStatus['authMethod']}'),
                    Text('✅ APIキー設定: ${authStatus['apiKeySet']}'),
                    Text('✅ APIキー長: ${authStatus['apiKeyLength']}文字'),
                    Text('✅ デフォルトキー: ${authStatus['isDefaultKey']}'),
                    Text('✅ 有効なキー: ${authStatus['isValidKey']}'),
                    if (authStatus['error'] != null) 
                      Text('❌ エラー: ${authStatus['error']}'),
                  
                  const SizedBox(height: 16),
                  
                  const Text(
                    'API接続:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('✅ ヘルスチェック: ${healthCheck ? "成功" : "失敗"}'),
                  Text('✅ ベースURL: ${AIAgentService.currentBaseUrl}'),
                  Text('✅ プラットフォーム: ${Platform.operatingSystem}'),
                  
                  const SizedBox(height: 16),
                  
                  if (!authStatus['apiKeySet'] || !healthCheck)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: const Text(
                        '問題が検出されました。ログアウト後に再ログインを試してください。',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
              if (!authStatus['apiKeySet'] || authStatus['isDefaultKey'] == true)
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('アプリを再起動して適切なAPIキーを設定してください'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 5),
                        ),
                      );
                    }
                  },
                  child: const Text('APIキー設定'),
                ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // ローディングダイアログを閉じる
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('テストエラー'),
            content: Text('接続テスト中にエラーが発生しました:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      }
    }
  }
} 