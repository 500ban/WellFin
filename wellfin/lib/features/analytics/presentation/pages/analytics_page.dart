import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_provider.dart';
import '../../../calendar/presentation/providers/calendar_provider.dart';
import '../../../tasks/presentation/providers/task_provider.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../goals/presentation/providers/goal_provider.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../habits/domain/entities/habit.dart';
import '../../../../shared/widgets/loading_widget.dart';


/// Phase 5: 分析機能メインページ
/// 各種分析レポートへのナビゲーションと概要表示
class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  bool _isLoading = false;
  bool _hasInitialized = false;
  bool _hasTriggeredAnalytics = false; // 分析データ読み込みのフラグ追加
  
  @override
  void initState() {
    super.initState();
    // 初期化時にデータを読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    if (_hasInitialized) return;
    _hasInitialized = true;
    
    // 各プロバイダーからデータを読み込み（全データ）
    ref.read(taskProvider.notifier).loadTasks(); // 全タスクを取得
    ref.read(habitProvider.notifier).loadAllHabits(); // 全習慣を取得
    ref.read(goalNotifierProvider.notifier).loadGoals(); // 全目標を取得
    
    // カレンダーデータも読み込み
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    ref.read(calendarProvider.notifier).loadEvents(monthAgo, now);
  }

  // 手動リフレッシュ用（フラグをリセット）
  void _refreshAnalytics() {
    _hasTriggeredAnalytics = false;
    // プロバイダーを再読み込み
    ref.read(taskProvider.notifier).loadTasks();
    ref.read(habitProvider.notifier).loadTodayHabits();
    ref.read(goalNotifierProvider.notifier).loadGoals();
    
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    ref.read(calendarProvider.notifier).loadEvents(startOfDay, endOfDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          '📊 分析ダッシュボード',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) => IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black87),
              onPressed: () => _refreshAnalytics(),
              tooltip: 'データを更新',
            ),
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final taskState = ref.watch(taskProvider);
          final habitState = ref.watch(habitProvider);
          final goalState = ref.watch(goalNotifierProvider);
          final calendarState = ref.watch(calendarProvider);
          final analyticsState = ref.watch(analyticsProvider);

          // Google Calendar認証エラーをチェック
          final analyticsNotifier = ref.read(analyticsProvider.notifier);
          final hasAuthError = analyticsNotifier.hasGoogleCalendarAuthError;
          final authErrorMessage = analyticsNotifier.lastGoogleCalendarAuthError;
          final isReauthenticating = analyticsNotifier.isReauthenticating;

          // 今日のデータを取得（ダッシュボードと同じ方法）
          final tasks = taskState.maybeWhen(
            data: (data) => data,
            orElse: () => <Task>[],
          );
          final habits = habitState.maybeWhen(
            data: (data) => data,
            orElse: () => <Habit>[],
          );
          final goals = goalState.maybeWhen(
            data: (data) => data,
            orElse: () => <dynamic>[],
          );

          // 今日のタスクのみを抽出
          final todayTasks = tasks.where((t) => t.isToday).toList();
          final completedTodayTasks = todayTasks.where((t) => t.isCompleted).length;
          final todayTaskCompletionRate = todayTasks.isEmpty ? 0.0 : completedTodayTasks / todayTasks.length;

          // 今日の習慣のみを抽出
          final activeHabits = habits.where((h) => h.status == HabitStatus.active).toList();
          final completedTodayHabits = activeHabits.where((h) => h.isCompletedToday).length;

          // 進行中の目標を抽出
          final activeGoals = goals.where((g) => g.isInProgress).toList();

          // カレンダーイベント
          final events = calendarState.events;

          // デバッグ用：実際のデータ数を確認
          print('📊 今日の分析データ:');
          print('  - 今日のタスク: ${todayTasks.length}件 (完了: $completedTodayTasks件) 完了率: ${(todayTaskCompletionRate * 100).toStringAsFixed(1)}%');
          print('  - アクティブ習慣: ${activeHabits.length}件 (完了: $completedTodayHabits件)');
          print('  - 進行中目標: ${activeGoals.length}件');
          print('  - イベント: ${events.length}件');

          final isAllLoaded =
            taskState is AsyncData &&
            habitState is AsyncData &&
            goalState is AsyncData;

          // 全データが読み込まれた場合のみ分析データを更新（一度だけ）
          if (isAllLoaded && !_hasTriggeredAnalytics && !_isLoading) {
            _hasTriggeredAnalytics = true; // フラグを設定して一度だけ実行
            
            // 非同期で実行して無限ループを避ける
            Future.microtask(() {
              ref.read(analyticsProvider.notifier).refreshAnalyticsData(
                events: events,
                tasks: todayTasks, // 今日のタスクのみを渡す
                habits: activeHabits, // アクティブな習慣のみを渡す
                goals: activeGoals, // 進行中の目標のみを渡す
              );
            });
          }

          return Column(
            children: [
              // Google Calendar認証エラー表示
              if (hasAuthError)
                GoogleCalendarReauthWidget(
                  errorMessage: authErrorMessage,
                  isLoading: isReauthenticating,
                  onReauthenticate: () async {
                    final success = await analyticsNotifier.reauthenticateGoogleCalendar();
                    if (success) {
                      // 再認証成功後、データを再読み込み
                      _refreshAnalytics();
                    } else {
                      // 再認証失敗時のエラー表示
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('再認証に失敗しました。しばらく経ってから再度お試しください。'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              
              // 分析データ表示
              Expanded(
                child: analyticsState.when(
                  data: (data) => _buildAnalyticsContent(data),
                  loading: () => const Center(child: LoadingWidget()),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'エラーが発生しました',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$error',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _refreshAnalytics(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('再読み込み'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 分析データ表示コンテンツ
  Widget _buildAnalyticsContent(AnalyticsData data) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: SingleChildScrollView(
        key: ValueKey(data.hashCode),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(data),
            const SizedBox(height: 24),
            _buildAnalysisMenu(),
            const SizedBox(height: 24),
            _buildQuickInsights(data),
          ],
        ),
      ),
    );
  }

  /// 概要カード
  Widget _buildOverviewCards(AnalyticsData data) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        const Text(
          '📈 今日の概要',
                  style: TextStyle(
            fontSize: 20,
                    fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
          Row(
            children: [
            Expanded(child: _buildOverviewCard(
              '効率性スコア',
              '${data.todayEfficiencyScore.toStringAsFixed(1)}/10',
              Icons.speed,
              Colors.blue,
              data.todayEfficiencyScore / 10,
            )),
              const SizedBox(width: 16),
            Expanded(child: _buildOverviewCard(
              '完了率',
              data.todayCompletionRate.isNaN ? '-' : '${(data.todayCompletionRate * 100).toStringAsFixed(1)}%',
              Icons.check_circle,
              Colors.green,
              data.todayCompletionRate,
            )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
            Expanded(child: _buildOverviewCard(
              '集中時間',
              '${data.focusTimeHours.toStringAsFixed(1)}時間',
              Icons.center_focus_strong,
              Colors.orange,
              data.focusTimeHours / 8,
            )),
              const SizedBox(width: 16),
            Expanded(child: _buildOverviewCard(
              '中断回数',
              '${data.interruptionCount}回',
              Icons.block,
              Colors.red,
              1.0 - (data.interruptionCount / 20),
            )),
            ],
          ),
        ],
    );
  }

  /// 概要カード（UI/UX最適化版）
  Widget _buildOverviewCard(
    String title,
    String value,
    IconData icon,
    Color color,
    double progress,
  ) {
    return SizedBox(
      height: 170,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 分析メニュー
  Widget _buildAnalysisMenu() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
          '📊 分析レポート',
            style: TextStyle(
            fontSize: 20,
              fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildAnalysisMenuItem(
              '週間レポート',
              '過去7日間の詳細分析',
              Icons.calendar_view_week,
                          Colors.blue,
              () => Navigator.pushNamed(context, '/weekly-report'),
            )),
            const SizedBox(width: 16),
            Expanded(child: _buildAnalysisMenuItem(
              '月間レポート',
              '過去31日間の包括的分析',
              Icons.calendar_month,
                          Colors.green,
              () => Navigator.pushNamed(context, '/monthly-report'),
            )),
          ],
        ),
        const SizedBox(height: 16),
        Row(
        children: [
            Expanded(child: _buildAnalysisMenuItem(
              '生産性パターン',
              '詳細な生産性分析と最適化',
              Icons.analytics,
              Colors.orange,
              () => Navigator.pushNamed(context, '/productivity-patterns'),
            )),
            const SizedBox(width: 16),
            Expanded(child: _buildAnalysisMenuItem(
              '目標進捗',
              '目標達成の進捗と予測',
              Icons.flag,
              Colors.purple,
              () => Navigator.pushNamed(context, '/goal-progress'),
            )),
          ],
        ),
      ],
    );
  }

  /// 分析メニュー項目（UI/UX最適化版）
  Widget _buildAnalysisMenuItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      height: 150,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11, // 小さめ
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }



  /// クイックインサイト
  Widget _buildQuickInsights(AnalyticsData data) {
    final insights = <Map<String, dynamic>>[];
    
    // 効率性スコアのインサイト
    if (data.todayEfficiencyScore >= 8.0) {
      insights.add({
        'title': '素晴らしい効率性！',
        'message': '今日は非常に効率的に作業できています。',
        'icon': Icons.emoji_events,
        'color': Colors.green,
      });
    } else if (data.todayEfficiencyScore >= 6.0) {
      insights.add({
        'title': '良好な効率性',
        'message': '効率性は良好です。さらなる改善の余地があります。',
        'icon': Icons.trending_up,
        'color': Colors.blue,
      });
    } else {
      insights.add({
        'title': '効率性の改善が必要',
        'message': '効率性を向上させるため、時間管理を見直してみましょう。',
        'icon': Icons.lightbulb,
        'color': Colors.orange,
      });
    }
    
    // 集中時間のインサイト
    if (data.focusTimeHours >= 6.0) {
      insights.add({
        'title': '十分な集中時間',
        'message': '集中時間が十分確保できています。',
        'icon': Icons.center_focus_strong,
        'color': Colors.green,
      });
    } else if (data.focusTimeHours >= 4.0) {
      insights.add({
        'title': '適度な集中時間',
        'message': '集中時間は適度です。さらに増やすことを検討してください。',
        'icon': Icons.timer,
        'color': Colors.blue,
      });
    } else {
      insights.add({
        'title': '集中時間が不足',
        'message': '集中時間が少ないため、時間管理の見直しを検討してください。',
        'icon': Icons.warning,
        'color': Colors.red,
      });
    }
    
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
          '💡 クイックインサイト',
            style: TextStyle(
            fontSize: 20,
              fontWeight: FontWeight.bold,
            color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
        ...insights.map((insight) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
            borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
            border: Border.all(
              color: (insight['color'] as Color).withValues(alpha: 0.2),
              width: 1,
            ),
      ),
      child: Row(
        children: [
              Icon(
                insight['icon'] as IconData,
                color: insight['color'] as Color,
                size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                      insight['title'] as String,
                      style: const TextStyle(
                    fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                      insight['message'] as String,
                      style: const TextStyle(
                    fontSize: 12,
                        color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        )).toList(),
      ],
    );
  }
}
