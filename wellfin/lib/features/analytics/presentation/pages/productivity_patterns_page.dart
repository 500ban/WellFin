import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../calendar/presentation/providers/calendar_provider.dart';
import '../../../tasks/presentation/providers/task_provider.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../goals/presentation/providers/goal_provider.dart';
import '../providers/analytics_provider.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../habits/domain/entities/habit.dart';


/// Phase 5: 生産性パターン分析レポート画面
/// 時間帯別の生産性分析、集中時間の最適化提案、効率性の詳細分析
class ProductivityPatternsPage extends ConsumerStatefulWidget {
  const ProductivityPatternsPage({super.key});

  @override
  ConsumerState<ProductivityPatternsPage> createState() => _ProductivityPatternsPageState();
}

class _ProductivityPatternsPageState extends ConsumerState<ProductivityPatternsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _hasInitialized = false;
  AnalyticsData? _productivityData; // 生産性データを保持
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // データ読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductivityData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProductivityData() async {
    if (_isLoading || _hasInitialized) return;
    
    setState(() {
      _isLoading = true;
      _hasInitialized = true;
      _productivityData = null; // 古いデータをクリア
    });
    
    // 過去7日間のデータを読み込み
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    print('📅 生産性データ読み込み開始');
    
    try {
      // 各プロバイダーからデータを読み込み
      await Future.wait([
        ref.read(calendarProvider.notifier).loadEvents(weekAgo, now),
        ref.read(taskProvider.notifier).loadTasks(),
        ref.read(habitProvider.notifier).loadAllHabits(),
        ref.read(goalNotifierProvider.notifier).loadGoals(),
      ]);
      
      // 少し待ってから分析を実行
      await Future.delayed(const Duration(milliseconds: 300));
      await _generateProductivityAnalysis();
      
    } catch (error) {
      print('❌ 生産性データ読み込みエラー: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateProductivityAnalysis() async {
    final calendarState = ref.read(calendarProvider);
    final taskState = ref.read(taskProvider);
    final habitState = ref.read(habitProvider);
    final goalState = ref.read(goalNotifierProvider);

    // データを取得（空の場合は空配列を使用）
    final events = calendarState.events;
    final tasks = taskState.hasValue ? (taskState.value ?? <Task>[]) : <Task>[];
    final habits = habitState.hasValue ? (habitState.value ?? <Habit>[]) : <Habit>[];
    final goals = goalState.hasValue ? (goalState.value ?? <dynamic>[]) : <dynamic>[];

    print('📊 生産性分析データ:');
    print('  - タスク: ${tasks.length}件');
    print('  - 習慣: ${habits.length}件');
    print('  - 目標: ${goals.length}件');
    print('  - イベント: ${events.length}件');

    // 生産性データ専用の分析データを生成
    final productivityAnalyticsData = AnalyticsData.fromRealData(
      events: events,
      tasks: tasks,
      habits: habits,
      goals: goals,
    );

    if (mounted) {
      setState(() {
        _productivityData = productivityAnalyticsData;
      });
    }
    
    print('✅ 生産性分析完了');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          '📈 生産性パターン分析',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _hasInitialized = false;
              });
              _loadProductivityData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: '時間帯'),
            Tab(icon: Icon(Icons.psychology), text: '集中度'),
            Tab(icon: Icon(Icons.trending_up), text: '傾向'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTimePatternTab(),
          _buildFocusTab(),
          _buildTrendsTab(),
        ],
      ),
    );
  }

  /// 時間帯タブ
  Widget _buildTimePatternTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_productivityData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('時間帯データを読み込み中...'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasInitialized = false;
                });
                _loadProductivityData();
              },
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
          _buildProductivityScoreCard(_productivityData!),
          const SizedBox(height: 16),
          _buildTimePatternsCard(_productivityData!),
          const SizedBox(height: 16),
          _buildOptimalTimeCard(_productivityData!),
        ],
      ),
    );
  }

  /// 集中度タブ
  Widget _buildFocusTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_productivityData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('集中度データを読み込み中...'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasInitialized = false;
                });
                _loadProductivityData();
              },
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
          _buildFocusPatternsCard(_productivityData!),
          const SizedBox(height: 16),
          _buildInterruptionPatternsCard(_productivityData!),
        ],
      ),
    );
  }

  /// 傾向タブ
  Widget _buildTrendsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_productivityData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('傾向データを読み込み中...'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasInitialized = false;
                });
                _loadProductivityData();
              },
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
          _buildWeeklyTrendsCard(_productivityData!),
          const SizedBox(height: 16),
          _buildMonthlyTrendsCard(_productivityData!),
          const SizedBox(height: 16),
          _buildCategoryTrendsCard(_productivityData!),
        ],
      ),
    );
  }

  /// 最適な時間カード
  Widget _buildOptimalTimeCard(AnalyticsData data) {
    // 時間帯別の活動データから最適な時間を分析
    final hourlyData = data.hourlyDistribution;
    
    if (hourlyData.isEmpty) {
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
        child: const Column(
          children: [
            Icon(Icons.schedule, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('データが不足しています'),
          ],
        ),
      );
    }

    // 最も活動的な時間帯を見つける
    final maxEntry = hourlyData.entries.reduce((a, b) => a.value > b.value ? a : b);
    final optimalHour = maxEntry.key;
    final activityLevel = maxEntry.value;

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
            '⏰ 最適な時間帯',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${optimalHour}:00 - ${optimalHour + 1}:00',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '活動レベル: $activityLevel',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '💡 この時間帯に重要なタスクを集中させることをお勧めします',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 生産性スコアカード
  Widget _buildProductivityScoreCard(AnalyticsData data) {
    final overallScore = (data.todayEfficiencyScore + data.monthlyEfficiencyScore) / 2;
    
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
            '📊 総合生産性スコア',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.8),
                    Colors.green.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      overallScore.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      '/10',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildScoreItem(
                  '今日のスコア',
                  data.todayEfficiencyScore.toStringAsFixed(1),
                  data.todayEfficiencyScore / 10,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildScoreItem(
                  '月間スコア',
                  data.monthlyEfficiencyScore.toStringAsFixed(1),
                  data.monthlyEfficiencyScore / 10,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// スコア項目
  Widget _buildScoreItem(
    String title,
    String value,
    double progress,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
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

  /// 時間パターンカード
  Widget _buildTimePatternsCard(AnalyticsData data) {
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
            '⏰ 時間別生産性パターン',
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
                  final isPeakHour = entry.key >= 9 && entry.key <= 11 || entry.key >= 14 && entry.key <= 16;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        color: isPeakHour 
                            ? Colors.blue.withValues(alpha: 0.8)
                            : Colors.grey.withValues(alpha: 0.6),
                        width: 20,
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '青色のバーは生産性のピーク時間帯を示しています',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 集中パターンカード
  Widget _buildFocusPatternsCard(AnalyticsData data) {
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
            '🎯 集中パターン分析',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFocusMetric(
                  '今日の集中時間',
                  '${data.focusTimeHours.toStringAsFixed(1)}時間',
                  data.focusTimeHours / 8,
                  Icons.center_focus_strong,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFocusMetric(
                  '集中率',
                  '${(data.focusTimePercentage * 100).toStringAsFixed(1)}%',
                  data.focusTimePercentage,
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFocusMetric(
                  '月間総集中時間',
                  '${data.totalFocusTimeHours.toStringAsFixed(1)}時間',
                  data.totalFocusTimeHours / 160,
                  Icons.calendar_today,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFocusMetric(
                  '平均集中時間',
                  '${(data.totalFocusTimeHours / 30).toStringAsFixed(1)}時間/日',
                  (data.totalFocusTimeHours / 30) / 8,
                  Icons.av_timer,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 集中メトリクス
  Widget _buildFocusMetric(
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

  /// 中断パターンカード
  Widget _buildInterruptionPatternsCard(AnalyticsData data) {
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
            '🚫 中断パターン分析',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInterruptionMetric(
                  '今日の中断回数',
                  '${data.interruptionCount}回',
                  1.0 - (data.interruptionCount / 20),
                  Icons.block,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInterruptionMetric(
                  '月間総中断回数',
                  '${data.totalInterruptionCount}回',
                  1.0 - (data.totalInterruptionCount / 100),
                  Icons.calendar_today,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInterruptionMetric(
                  '平均中断回数',
                  '${(data.totalInterruptionCount / 30).toStringAsFixed(1)}回/日',
                  1.0 - ((data.totalInterruptionCount / 30) / 5),
                  Icons.av_timer,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInterruptionMetric(
                  'マルチタスク率',
                  '${(data.averageMultitaskingRate * 100).toStringAsFixed(1)}%',
                  1.0 - data.averageMultitaskingRate,
                  Icons.swap_horiz,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 中断メトリクス
  Widget _buildInterruptionMetric(
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

  /// 週間傾向カード
  Widget _buildWeeklyTrendsCard(AnalyticsData data) {
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
            '📈 週間生産性傾向',
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
                        const days = ['月', '火', '水', '木', '金', '土', '日'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(
                            days[value.toInt()],
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 1,
                lineBarsData: [
                  LineChartBarData(
                    spots: data.weeklyProgress.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value);
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withValues(alpha: 0.8),
                        Colors.green.withValues(alpha: 0.3),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.green,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withValues(alpha: 0.3),
                          Colors.green.withValues(alpha: 0.1),
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

  /// 月間傾向カード
  Widget _buildMonthlyTrendsCard(AnalyticsData data) {
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
            '📊 月間生産性傾向',
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
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 5 == 0 && value.toInt() >= 1 && value.toInt() <= 31) {
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

  /// カテゴリ傾向カード
  Widget _buildCategoryTrendsCard(AnalyticsData data) {
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
            '📋 カテゴリ別傾向',
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
} 