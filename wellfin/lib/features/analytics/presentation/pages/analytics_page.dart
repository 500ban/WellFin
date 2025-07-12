import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../calendar/presentation/providers/calendar_provider.dart';
import '../../../tasks/presentation/providers/task_provider.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../goals/presentation/providers/goal_provider.dart';
import '../providers/analytics_provider.dart';
import '../../../../shared/widgets/app_navigation_bar.dart';
import '../../../../shared/services/ai_agent_service.dart';
import '../../../../shared/models/user_model.dart';

/// Phase 5: 分析機能 - 実データ連携による時間使用状況詳細レポート
class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // データ読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalyticsData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAnalyticsData() {
    // 過去7日間のデータを読み込み
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    // 各プロバイダーからデータを読み込み
    ref.read(calendarProvider.notifier).loadEvents(weekAgo, now);
    ref.read(taskProvider.notifier).loadTasks();
    ref.read(habitProvider.notifier).loadAllHabits();
    ref.read(goalNotifierProvider.notifier).loadGoals();
    
    // 実データからレポート生成
    _generateRealDataReport();
  }

  void _generateRealDataReport() {
    // 各プロバイダーからデータを取得
    final calendarState = ref.read(calendarProvider);
    final taskState = ref.read(taskProvider);
    final habitState = ref.read(habitProvider);
    final goalState = ref.read(goalNotifierProvider);

    // データが読み込まれたらレポート生成
    if (taskState.hasValue && habitState.hasValue && goalState.hasValue) {
      final events = calendarState.events; // CalendarStateから直接取得
      final tasks = taskState.value ?? [];
      final habits = habitState.value ?? [];
      final goals = goalState.value ?? [];

      ref.read(analyticsProvider.notifier).generateWeeklyReportFromRealData(
        events: events,
        tasks: tasks,
        habits: habits,
        goals: goals,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // データ変更を監視して自動更新
    ref.listen<CalendarState>(calendarProvider, (previous, next) {
      _generateRealDataReport();
    });
    ref.listen<AsyncValue<dynamic>>(taskProvider, (previous, next) {
      if (next.hasValue) _generateRealDataReport();
    });
    ref.listen<AsyncValue<dynamic>>(habitProvider, (previous, next) {
      if (next.hasValue) _generateRealDataReport();
    });
    ref.listen<AsyncValue<dynamic>>(goalNotifierProvider, (previous, next) {
      if (next.hasValue) _generateRealDataReport();
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 分析レポート',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '実際のデータに基づく分析結果',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(icon: Icon(Icons.timeline), text: '時間分析'),
            Tab(icon: Icon(Icons.pie_chart), text: '分布'),
            Tab(icon: Icon(Icons.trending_up), text: '傾向'),
            Tab(icon: Icon(Icons.insights), text: '洞察'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTimeAnalysisTab(),
          _buildDistributionTab(),
          _buildTrendsTab(),
          _buildInsightsTab(),
        ],
      ),
      bottomNavigationBar: const AppNavigationBar(currentIndex: 3),
    );
  }

  /// 時間分析タブ
  Widget _buildTimeAnalysisTab() {
    return Consumer(
      builder: (context, ref, child) {
        final analyticsState = ref.watch(analyticsProvider);
        
        return analyticsState.when(
          data: (data) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildDailySummaryCard(data),
                const SizedBox(height: 16),
                _buildWeeklyProgressChart(data),
                const SizedBox(height: 16),
                _buildProductivityMetrics(data),
                const SizedBox(height: 16),
                _buildDataSummaryCard(data),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('エラー: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadAnalyticsData,
                  child: const Text('再読み込み'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// データサマリーカード
  Widget _buildDataSummaryCard(AnalyticsData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 データサマリー',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'タスク',
                  '${data.completedTasks}/${data.totalTasks}',
                  data.totalTasks > 0 ? data.completedTasks / data.totalTasks : 0.0,
                  Icons.task_alt,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  '習慣',
                  '${data.completedHabits}/${data.totalHabits}',
                  data.totalHabits > 0 ? data.completedHabits / data.totalHabits : 0.0,
                  Icons.repeat,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  '目標',
                  '${data.completedGoals}/${data.totalGoals}',
                  data.totalGoals > 0 ? data.completedGoals / data.totalGoals : 0.0,
                  Icons.flag,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'イベント',
                  '${data.totalCalendarEvents}件',
                  1.0,
                  Icons.event,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// サマリー項目
  Widget _buildSummaryItem(
    String title,
    String value,
    double progress,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  /// 日次サマリーカード
  Widget _buildDailySummaryCard(AnalyticsData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '今日の時間使用状況',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${DateTime.now().month}/${DateTime.now().day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTimeMetric(
                  '計画時間',
                  '${data.todayPlannedHours.toStringAsFixed(1)}h',
                  Icons.schedule,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeMetric(
                  '実績時間',
                  '${data.todayActualHours.toStringAsFixed(1)}h',
                  Icons.timer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeMetric(
                  '完了率',
                  '${(data.todayCompletionRate * 100).toStringAsFixed(0)}%',
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeMetric(
                  '効率性',
                  '${data.todayEfficiencyScore.toStringAsFixed(1)}/10',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 時間メトリック表示
  Widget _buildTimeMetric(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 週間進捗チャート
  Widget _buildWeeklyProgressChart(AnalyticsData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 週間進捗',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value * 100).toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['月', '火', '水', '木', '金', '土', '日'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(
                            days[value.toInt()],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.weeklyProgress
                        .asMap()
                        .entries
                        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                        .toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 生産性メトリック
  Widget _buildProductivityMetrics(AnalyticsData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚡ 生産性指標',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  '集中時間',
                  '${data.focusTimeHours.toStringAsFixed(1)}h',
                  Icons.psychology,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  '中断回数',
                  '${data.interruptionCount}回',
                  Icons.notifications_off,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                                  child: _buildMetricCard(
                    'マルチタスク',
                    '${(data.multitaskingRate * 100).toStringAsFixed(0)}%',
                    Icons.apps,
                    Colors.red,
                  ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  '休憩効率',
                  '${data.breakEfficiency.toStringAsFixed(1)}/10',
                  Icons.coffee,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// メトリックカード
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 分布タブ
  Widget _buildDistributionTab() {
    return Consumer(
      builder: (context, ref, child) {
        final analyticsState = ref.watch(analyticsProvider);
        
        return analyticsState.when(
          data: (data) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryDistributionChart(data),
                const SizedBox(height: 16),
                _buildTimeDistributionChart(data),
                const SizedBox(height: 16),
                _buildActivityBreakdown(data),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('エラー: $error'),
          ),
        );
      },
    );
  }

  /// カテゴリ別分布チャート
  Widget _buildCategoryDistributionChart(AnalyticsData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 カテゴリ別時間分布',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: data.categoryDistribution.isEmpty
                ? const Center(
                    child: Text(
                      'データがありません',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sections: data.categoryDistribution.entries.map((entry) {
                        final colors = [
                          Colors.blue,
                          Colors.green,
                          Colors.orange,
                          Colors.red,
                          Colors.purple,
                        ];
                        final index = data.categoryDistribution.keys.toList().indexOf(entry.key);
                        return PieChartSectionData(
                          color: colors[index % colors.length],
                          value: entry.value,
                          title: entry.key,
                          radius: 80,
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

  /// 時間分布チャート
  Widget _buildTimeDistributionChart(AnalyticsData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⏰ 時間別活動分布',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: data.hourlyDistribution.isEmpty
                ? const Center(
                    child: Text(
                      'データがありません',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: data.hourlyDistribution.values.isEmpty
                          ? 10
                          : data.hourlyDistribution.values.reduce((a, b) => a > b ? a : b).toDouble() + 1,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: data.hourlyDistribution.entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              color: Colors.blue,
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
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

  /// 活動内訳
  Widget _buildActivityBreakdown(AnalyticsData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 活動内訳',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildActivityItem('集中時間', data.focusTimePercentage, Colors.blue),
          _buildActivityItem('コミュニケーション', data.communicationPercentage, Colors.green),
          _buildActivityItem('学習', data.learningPercentage, Colors.orange),
          _buildActivityItem('休憩', data.breakPercentage, Colors.red),
        ],
      ),
    );
  }

  /// 活動項目
  Widget _buildActivityItem(String title, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  /// 傾向タブ
  Widget _buildTrendsTab() {
    return const Center(
      child: Text(
        '傾向分析機能は準備中です',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  /// 洞察タブ
  Widget _buildInsightsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final analyticsState = ref.watch(analyticsProvider);
        
        return analyticsState.when(
          data: (data) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAIOptimizationSection(data),
                const SizedBox(height: 16),
                _buildProductivityInsightsSection(),
                const SizedBox(height: 16),
                _buildPersonalizedRecommendations(),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('エラー: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadAnalyticsData,
                  child: const Text('再読み込み'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// AI最適化提案セクション
  Widget _buildAIOptimizationSection(AnalyticsData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '🤖 AI最適化提案',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Phase 5',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'あなたの分析データに基づいて、AI が個人化された改善提案を生成します。',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _generateAIRecommendations(data),
              icon: const Icon(Icons.auto_awesome, color: Colors.purple),
              label: const Text(
                'AI分析を開始',
                style: TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// AI推奨事項を生成
  Future<void> _generateAIRecommendations(AnalyticsData analyticsData) async {
    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI分析中...'),
                ],
              ),
            ),
          ),
        ),
      );

      // ユーザー情報を取得（簡易版）
      final userModel = UserModel(
        uid: 'current_user', // 実際の実装では認証済みユーザーのUIDを使用
        email: 'user@example.com',
        displayName: 'ユーザー',
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        timeZone: 'Asia/Tokyo',
        preferences: UserPreferences(),
        calendarSync: CalendarSync(),
        stats: UserStats(),
      );

      // AI最適化提案を取得
      final optimizationResult = await AIAgentService.getAnalyticsOptimization(
        analyticsData,
        userModel,
      );

      // ローディングを閉じる
      if (mounted) Navigator.of(context).pop();

      // AI提案結果を表示
      if (mounted) {
        _showAIRecommendationsDialog(optimizationResult);
      }
    } catch (e) {
      // ローディングを閉じる
      if (mounted) Navigator.of(context).pop();
      
      // エラー表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI分析でエラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// AI推奨事項ダイアログを表示
  void _showAIRecommendationsDialog(AnalyticsOptimizationResult result) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ヘッダー
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.purple.shade600],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'AI 最適化提案',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // コンテンツ
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 総合スコア
                      _buildOverallScoreCard(result.insights.overallScore),
                      const SizedBox(height: 16),
                      
                      // 推奨事項
                      if (result.recommendations.isNotEmpty) ...[
                        _buildRecommendationsSection(result.recommendations),
                        const SizedBox(height: 16),
                      ],
                      
                      // スケジュール最適化
                      _buildScheduleOptimizationSection(result.scheduleOptimization),
                      const SizedBox(height: 16),
                      
                      // 生産性インサイト
                      _buildInsightsSection(result.insights),
                    ],
                  ),
                ),
              ),
              
              // フッター
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('後で確認'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _applyRecommendations(result.recommendations);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('提案を適用'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 総合スコアカード
  Widget _buildOverallScoreCard(double score) {
    final Color scoreColor = score >= 80 
        ? Colors.green 
        : score >= 60 
            ? Colors.orange 
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: scoreColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${score.toInt()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '総合生産性スコア',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '完了率、効率性、集中力などを総合的に評価した結果です',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 推奨事項セクション
  Widget _buildRecommendationsSection(List<Recommendation> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 推奨改善事項',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...recommendations.map((rec) => _buildRecommendationCard(rec)),
      ],
    );
  }

  /// 推奨事項カード
  Widget _buildRecommendationCard(Recommendation recommendation) {
    final Color priorityColor = recommendation.priority == 'high' 
        ? Colors.red 
        : recommendation.priority == 'medium' 
            ? Colors.orange 
            : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: priorityColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  recommendation.priority.toUpperCase(),
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// スケジュール最適化セクション
  Widget _buildScheduleOptimizationSection(ScheduleOptimization optimization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⏰ スケジュール最適化',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (optimization.timeSlotOptimizations.isNotEmpty)
          _buildOptimizationList('時間配分の改善', optimization.timeSlotOptimizations),
        if (optimization.categoryBalancing.isNotEmpty)
          _buildOptimizationList('カテゴリバランス', optimization.categoryBalancing),
        if (optimization.efficiencyImprovements.isNotEmpty)
          _buildOptimizationList('効率性向上', optimization.efficiencyImprovements),
      ],
    );
  }

  /// 最適化リスト
  Widget _buildOptimizationList(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_right, color: Colors.blue.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// インサイトセクション
  Widget _buildInsightsSection(ProductivityInsights insights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💡 生産性インサイト',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildInsightsList('🎯 最高パフォーマンス時間', insights.peakPerformanceTimes, Colors.green),
        _buildInsightsList('⚠️ 低生産性時間', insights.lowProductivityTimes, Colors.orange),
        _buildInsightsList('🔄 習慣の提案', insights.habitRecommendations, Colors.blue),
        _buildInsightsList('🎯 目標戦略', insights.goalStrategies, Colors.purple),
      ],
    );
  }

  /// インサイトリスト
  Widget _buildInsightsList(String title, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// 推奨事項を適用
  void _applyRecommendations(List<Recommendation> recommendations) {
    // 実際の実装では、推奨事項に基づいてタスクやスケジュールを更新
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${recommendations.length}件の提案を適用しました'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: '詳細',
          onPressed: () {
            // 適用された変更の詳細を表示（将来実装）
          },
        ),
      ),
    );
  }

  /// 生産性インサイトセクション
  Widget _buildProductivityInsightsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 生産性トレンド',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '過去のデータから、あなたの生産性パターンを分析します。',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '• 最も生産的な時間帯: 9:00-11:00, 14:00-16:00\n'
            '• 集中力が低下する時間: 13:00-14:00\n'
            '• 週末の生産性: 平日の70%程度\n'
            '• 継続中の習慣: 朝の運動、夜の読書',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// パーソナライズされた推奨事項
  Widget _buildPersonalizedRecommendations() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 今週の重点改善ポイント',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecommendationItem(
            '🍅 ポモドーロテクニックの活用',
            '25分集中 + 5分休憩のサイクルで効率アップ',
            Colors.red,
          ),
          _buildRecommendationItem(
            '📝 タスクの事前準備',
            '前日夜に翌日のタスクを明確化',
            Colors.blue,
          ),
          _buildRecommendationItem(
            '💪 定期的な運動',
            '週3回の軽い運動で集中力向上',
            Colors.green,
          ),
        ],
      ),
    );
  }

  /// 推奨事項アイテム
  Widget _buildRecommendationItem(String title, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
