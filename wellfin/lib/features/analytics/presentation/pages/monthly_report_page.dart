import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../calendar/presentation/providers/calendar_provider.dart';
import '../../../tasks/presentation/providers/task_provider.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../goals/presentation/providers/goal_provider.dart';
import '../providers/analytics_provider.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../habits/domain/entities/habit.dart';
import '../../../../shared/widgets/loading_widget.dart';


/// Phase 5: 月間サマリーレポート画面
/// 詳細な月間分析とグラフ機能を含む包括的なレポート
class MonthlyReportPage extends ConsumerStatefulWidget {
  const MonthlyReportPage({super.key});

  @override
  ConsumerState<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends ConsumerState<MonthlyReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _isLoading = false;
  AnalyticsData? _monthlyData; // 月間データを保持
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // データ読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMonthlyData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMonthlyData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _monthlyData = null; // 古いデータをクリア
    });
    
    final monthEnd = DateTime(_selectedMonthStart.year, _selectedMonthStart.month + 1, 0);
    
    print('📅 月間データ読み込み開始: ${DateFormat('yyyy/M').format(_selectedMonthStart)} (${DateFormat('M/d').format(_selectedMonthStart)} - ${DateFormat('M/d').format(monthEnd)})');
    
    try {
      // 各プロバイダーからデータを読み込み
      await Future.wait([
        ref.read(calendarProvider.notifier).loadEvents(_selectedMonthStart, monthEnd),
        ref.read(taskProvider.notifier).loadTasks(),
        ref.read(habitProvider.notifier).loadAllHabits(),
        ref.read(goalNotifierProvider.notifier).loadGoals(),
      ]);
      
      // 少し待ってからレポート生成
      await Future.delayed(const Duration(milliseconds: 300));
      await _generateMonthlyReport();
      
    } catch (error) {
      print('❌ 月間データ読み込みエラー: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateMonthlyReport() async {
    final calendarState = ref.read(calendarProvider);
    final taskState = ref.read(taskProvider);
    final habitState = ref.read(habitProvider);
    final goalState = ref.read(goalNotifierProvider);

    // データを取得（空の場合は空配列を使用）
    final allEvents = calendarState.events;
    final allTasks = taskState.hasValue ? (taskState.value ?? <Task>[]) : <Task>[];
    final allHabits = habitState.hasValue ? (habitState.value ?? <Habit>[]) : <Habit>[];
    final allGoals = goalState.hasValue ? (goalState.value ?? <dynamic>[]) : <dynamic>[];

    // 選択した月の期間でデータをフィルタリング
    final monthEnd = DateTime(_selectedMonthStart.year, _selectedMonthStart.month + 1, 0);
    
    // 月間のタスクをフィルタリング
    final monthlyTasks = allTasks.where((task) {
      return task.createdAt.isAfter(_selectedMonthStart.subtract(const Duration(days: 1))) &&
             task.createdAt.isBefore(monthEnd.add(const Duration(days: 1)));
    }).toList();
    
    // 月間のイベントをフィルタリング
    final monthlyEvents = allEvents.where((event) {
      return event.startTime.isAfter(_selectedMonthStart.subtract(const Duration(days: 1))) &&
             event.startTime.isBefore(monthEnd.add(const Duration(days: 1)));
    }).toList();
    
    // 習慣は全期間（月間での完了状況を分析するため）
    final monthlyHabits = allHabits;
    
    // 目標は全期間（月間での進捗を分析するため）
    final monthlyGoals = allGoals;

    print('📊 月間フィルタリング結果:');
    print('  - 月間タスク: ${monthlyTasks.length}件 (完了: ${monthlyTasks.where((t) => t.isCompleted).length}件)');
    print('  - 月間イベント: ${monthlyEvents.length}件');
    print('  - 習慣: ${monthlyHabits.length}件');
    print('  - 目標: ${monthlyGoals.length}件');

    // 月間データ専用の分析データを生成
    final monthlyAnalyticsData = AnalyticsData.fromRealData(
      events: monthlyEvents,
      tasks: monthlyTasks,
      habits: monthlyHabits,
      goals: monthlyGoals,
    );

    if (mounted) {
      setState(() {
        _monthlyData = monthlyAnalyticsData;
      });
    }
    
    print('✅ 月間レポート生成完了');
  }

  void _selectPreviousMonth() {
    setState(() {
      _selectedMonthStart = DateTime(_selectedMonthStart.year, _selectedMonthStart.month - 1, 1);
    });
    _loadMonthlyData();
  }

  void _selectNextMonth() {
    final nextMonth = DateTime(_selectedMonthStart.year, _selectedMonthStart.month + 1, 1);
    if (nextMonth.isBefore(DateTime.now())) {
      setState(() {
        _selectedMonthStart = nextMonth;
      });
      _loadMonthlyData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('月間レポート'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadMonthlyData(),
            tooltip: '再読み込み',
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          // Google Calendar認証エラーをチェック
          final analyticsNotifier = ref.read(analyticsProvider.notifier);
          final hasAuthError = analyticsNotifier.hasGoogleCalendarAuthError;
          final authErrorMessage = analyticsNotifier.lastGoogleCalendarAuthError;
          final isReauthenticating = analyticsNotifier.isReauthenticating;

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
                      _loadMonthlyData();
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

              // 月間レポート表示
              Expanded(
                child: _isLoading
                    ? const Center(child: LoadingWidget())
                    : _monthlyData == null
                        ? const Center(
                            child: Text(
                              '月間データを読み込み中...',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : _buildMonthlyReportContent(_monthlyData!),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 月間レポートコンテンツ
  Widget _buildMonthlyReportContent(AnalyticsData data) {
    return Column(
      children: [
        // 月間ナビゲーション
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                             IconButton(
                 icon: const Icon(Icons.chevron_left),
                 onPressed: _selectPreviousMonth,
               ),
               Text(
                 DateFormat('yyyy年M月').format(_selectedMonthStart),
                 style: const TextStyle(
                   fontSize: 18,
                   fontWeight: FontWeight.bold,
                 ),
               ),
               IconButton(
                 icon: const Icon(Icons.chevron_right),
                 onPressed: _selectNextMonth,
               ),
            ],
          ),
        ),
        
        // タブバー
        TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade700,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue.shade700,
          tabs: const [
            Tab(text: 'サマリー'),
            Tab(text: '詳細分析'),
            Tab(text: '傾向'),
          ],
        ),
        
        // タブビュー
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSummaryTab(),
              _buildDetailedAnalysisTab(),
              _buildTrendsTab(),
            ],
          ),
        ),
      ],
    );
  }

  /// サマリータブ
  Widget _buildSummaryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_monthlyData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('月間データを読み込み中...'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMonthlyData,
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthlyOverviewCard(_monthlyData!),
          const SizedBox(height: 16),
          _buildMonthlyProgressChart(_monthlyData!),
          const SizedBox(height: 16),
          _buildMonthlyMetricsGrid(_monthlyData!),
          const SizedBox(height: 16),
          _buildMonthlyInsightsCard(_monthlyData!),
        ],
      ),
    );
  }

  /// 月間概要カード
  Widget _buildMonthlyOverviewCard(AnalyticsData data) {
    final averageCompletionRate = data.monthlyProgress.isNotEmpty 
        ? data.monthlyProgress.reduce((a, b) => a + b) / data.monthlyProgress.length 
        : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 月間概要',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  '平均完了率',
                  '${(averageCompletionRate * 100).toStringAsFixed(1)}%',
                  averageCompletionRate,
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOverviewItem(
                  '効率性スコア',
                  '${data.monthlyEfficiencyScore.toStringAsFixed(1)}/10',
                  data.monthlyEfficiencyScore / 10,
                  Icons.speed,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  '総集中時間',
                  '${data.totalFocusTimeHours.toStringAsFixed(1)}時間',
                  data.totalFocusTimeHours / 160, // 160時間を基準
                  Icons.center_focus_strong,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOverviewItem(
                  '総中断回数',
                  '${data.totalInterruptionCount}回',
                  1.0 - (data.totalInterruptionCount / 100), // 100回を基準
                  Icons.block,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 概要項目
  Widget _buildOverviewItem(
    String title,
    String value,
    double progress,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  /// 月間進捗チャート
  Widget _buildMonthlyProgressChart(AnalyticsData data) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 月間進捗',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 0.2,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 1 && value.toInt() <= 31) {
                          return Text(
                            '${value.toInt()}日',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 0.2,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                minX: 1,
                maxX: 31,
                minY: 0,
                maxY: 1,
                lineBarsData: [
                  LineChartBarData(
                    spots: data.monthlyProgress.asMap().entries.map((entry) {
                      return FlSpot(entry.key + 1.0, entry.value);
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withValues(alpha: 0.8),
                        Colors.blue.withValues(alpha: 0.3),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.blue,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withValues(alpha: 0.3),
                          Colors.blue.withValues(alpha: 0.1),
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
    );
  }

  /// 月間メトリクスグリッド
  Widget _buildMonthlyMetricsGrid(AnalyticsData data) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 月間メトリクス',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'タスク完了',
                  '${data.totalCompletedTasks}/${data.totalTasks}',
                  data.totalTasks > 0 ? data.totalCompletedTasks / data.totalTasks : 0.0,
                  Icons.task_alt,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricItem(
                  '習慣達成',
                  '${data.totalCompletedHabits}/${data.totalHabits}',
                  data.totalHabits > 0 ? data.totalCompletedHabits / data.totalHabits : 0.0,
                  Icons.repeat,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  '目標進捗',
                  '${data.totalCompletedGoals}/${data.totalGoals}',
                  data.totalGoals > 0 ? data.totalCompletedGoals / data.totalGoals : 0.0,
                  Icons.flag,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricItem(
                  '平均マルチタスク率',
                  '${(data.averageMultitaskingRate * 100).toStringAsFixed(1)}%',
                  1.0 - data.averageMultitaskingRate, // 低い方が良い
                  Icons.swap_horiz,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// メトリクス項目
  Widget _buildMetricItem(
    String title,
    String value,
    double progress,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  /// 月間洞察カード
  Widget _buildMonthlyInsightsCard(AnalyticsData data) {
    final averageCompletionRate = data.monthlyProgress.isNotEmpty 
        ? data.monthlyProgress.reduce((a, b) => a + b) / data.monthlyProgress.length 
        : 0.0;
    
    String insight = '';
    String recommendation = '';
    
    if (averageCompletionRate >= 0.8) {
      insight = '素晴らしい月でした！高い完了率を維持できています。';
      recommendation = 'この調子で継続しましょう。';
    } else if (averageCompletionRate >= 0.6) {
      insight = '良い月でした。さらなる改善の余地があります。';
      recommendation = '優先度の高いタスクから取り組みましょう。';
    } else {
      insight = '今月は課題がありました。来月に向けて改善しましょう。';
      recommendation = 'タスクの見直しと時間管理の改善を検討してください。';
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 月間洞察',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '分析結果',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  insight,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '推奨事項',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  recommendation,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 詳細分析タブ
  Widget _buildDetailedAnalysisTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_monthlyData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('詳細分析データを読み込み中...'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMonthlyData,
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryAnalysisCard(_monthlyData!),
          const SizedBox(height: 16),
          _buildTimeDistributionCard(_monthlyData!),
          const SizedBox(height: 16),
          _buildProductivityAnalysisCard(_monthlyData!),
        ],
      ),
    );
  }

  /// カテゴリ分析カード
  Widget _buildCategoryAnalysisCard(AnalyticsData data) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 カテゴリ別分析',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: data.monthlyCategoryDistribution.entries.map((entry) {
                  final color = _getCategoryColor(entry.key);
                  return PieChartSectionData(
                    color: color,
                    value: entry.value,
                    title: '${entry.key}\n${entry.value.toStringAsFixed(1)}h',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// カテゴリ色取得
  Color _getCategoryColor(String category) {
    switch (category) {
      case '仕事':
        return Colors.blue;
      case '学習':
        return Colors.green;
      case '運動':
        return Colors.orange;
      case '個人':
        return Colors.purple;
      case '休憩':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  /// 時間分布カード
  Widget _buildTimeDistributionCard(AnalyticsData data) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 時間分布',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: data.hourlyDistribution.values.isNotEmpty 
                    ? data.hourlyDistribution.values.reduce((a, b) => a > b ? a : b).toDouble()
                    : 10,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}時',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                barGroups: data.hourlyDistribution.entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        color: Colors.blue.withValues(alpha: 0.7),
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 生産性分析カード
  Widget _buildProductivityAnalysisCard(AnalyticsData data) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🚀 生産性分析',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildProductivityMetric(
            '総集中時間',
            '${data.totalFocusTimeHours.toStringAsFixed(1)}時間',
            '平均${(data.totalFocusTimeHours / 30).toStringAsFixed(1)}時間/日',
            Icons.center_focus_strong,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildProductivityMetric(
            '総中断回数',
            '${data.totalInterruptionCount}回',
            '平均${(data.totalInterruptionCount / 30).toStringAsFixed(1)}回/日',
            Icons.block,
            Colors.red,
          ),
          const SizedBox(height: 12),
          _buildProductivityMetric(
            '平均マルチタスク率',
            '${(data.averageMultitaskingRate * 100).toStringAsFixed(1)}%',
            data.averageMultitaskingRate > 0.5 ? '高め' : '適切',
            Icons.swap_horiz,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildProductivityMetric(
            '平均休憩効率',
            '${data.averageBreakEfficiency.toStringAsFixed(1)}/10',
            data.averageBreakEfficiency > 7 ? '良好' : '改善余地あり',
            Icons.coffee,
            Colors.green,
          ),
        ],
      ),
    );
  }

  /// 生産性メトリクス
  Widget _buildProductivityMetric(
    String title,
    String value,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 傾向タブ
  Widget _buildTrendsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_monthlyData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('傾向データを読み込み中...'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMonthlyData,
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrendAnalysisCard(_monthlyData!),
          const SizedBox(height: 16),
          _buildImprovementSuggestionsCard(_monthlyData!),
        ],
      ),
    );
  }

  /// 傾向分析カード
  Widget _buildTrendAnalysisCard(AnalyticsData data) {
    // 月間進捗の傾向を分析
    final progress = data.monthlyProgress;
    String trend = '';
    String trendDescription = '';
    
    if (progress.length >= 4) {
      final firstQuarter = progress.take(progress.length ~/ 4).reduce((a, b) => a + b) / (progress.length ~/ 4);
      final lastQuarter = progress.skip(progress.length * 3 ~/ 4).reduce((a, b) => a + b) / (progress.length - progress.length * 3 ~/ 4);
      
      if (lastQuarter > firstQuarter + 0.1) {
        trend = '上昇傾向';
        trendDescription = '月の後半で生産性が向上しています。';
      } else if (lastQuarter < firstQuarter - 0.1) {
        trend = '下降傾向';
        trendDescription = '月の後半で生産性が低下しています。';
      } else {
        trend = '安定傾向';
        trendDescription = '一貫した生産性を維持しています。';
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 傾向分析',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trend,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  trendDescription,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 改善提案カード
  Widget _buildImprovementSuggestionsCard(AnalyticsData data) {
    final suggestions = <String>[];
    
    if (data.totalInterruptionCount > 50) {
      suggestions.add('中断回数が多いため、集中時間の確保を検討してください');
    }
    
    if (data.averageMultitaskingRate > 0.5) {
      suggestions.add('マルチタスク率が高いため、タスクの優先順位付けを改善してください');
    }
    
    if (data.totalFocusTimeHours < 80) {
      suggestions.add('集中時間が少ないため、時間管理の見直しを検討してください');
    }
    
    if (suggestions.isEmpty) {
      suggestions.add('現在の生産性は良好です。この調子で継続しましょう。');
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 改善提案',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...suggestions.map((suggestion) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
} 
