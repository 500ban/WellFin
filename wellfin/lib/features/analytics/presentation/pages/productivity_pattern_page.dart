import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../calendar/presentation/providers/calendar_provider.dart';
import '../../../tasks/presentation/providers/task_provider.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../goals/presentation/providers/goal_provider.dart';
import '../providers/analytics_provider.dart';


/// Phase 5: 生産性パターン分析レポート画面
/// 時間帯別の生産性分析、集中時間の最適化提案、効率性の詳細分析
class ProductivityPatternPage extends ConsumerStatefulWidget {
  const ProductivityPatternPage({super.key});

  @override
  ConsumerState<ProductivityPatternPage> createState() => _ProductivityPatternPageState();
}

class _ProductivityPatternPageState extends ConsumerState<ProductivityPatternPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
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

  void _loadProductivityData() {
    // 過去7日間のデータを読み込み
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    // 各プロバイダーからデータを読み込み
    ref.read(calendarProvider.notifier).loadEvents(weekAgo, now);
    ref.read(taskProvider.notifier).loadTasks();
    ref.read(habitProvider.notifier).loadAllHabits();
    ref.read(goalNotifierProvider.notifier).loadGoals();
    
    // 生産性パターン分析
    _generateProductivityAnalysis();
  }

  void _generateProductivityAnalysis() {
    final calendarState = ref.read(calendarProvider);
    final taskState = ref.read(taskProvider);
    final habitState = ref.read(habitProvider);
    final goalState = ref.read(goalNotifierProvider);

    if (taskState.hasValue && habitState.hasValue && goalState.hasValue) {
      final events = calendarState.events;
      final tasks = taskState.value ?? [];
      final habits = habitState.value ?? [];
      final goals = goalState.value ?? [];

      ref.read(analyticsProvider.notifier).generateWeeklyReportFromRealData(
        events: events,
        tasks: tasks,
        habits: habits,
        goals: goals,
        ref: ref,
        sendNotification: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // データ変更を監視して自動更新
    ref.listen<CalendarState>(calendarProvider, (previous, next) {
      _generateProductivityAnalysis();
    });
    ref.listen<AsyncValue<dynamic>>(taskProvider, (previous, next) {
      if (next.hasValue) _generateProductivityAnalysis();
    });
    ref.listen<AsyncValue<dynamic>>(habitProvider, (previous, next) {
      if (next.hasValue) _generateProductivityAnalysis();
    });
    ref.listen<AsyncValue<dynamic>>(goalNotifierProvider, (previous, next) {
      if (next.hasValue) _generateProductivityAnalysis();
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚀 生産性パターン分析',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '時間帯別の生産性と最適化提案',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: '時間帯分析'),
            Tab(icon: Icon(Icons.center_focus_strong), text: '集中時間'),
            Tab(icon: Icon(Icons.trending_up), text: '最適化提案'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTimeSlotAnalysisTab(),
          _buildFocusTimeTab(),
          _buildOptimizationTab(),
        ],
      ),
    );
  }

  /// 時間帯分析タブ
  Widget _buildTimeSlotAnalysisTab() {
    return Consumer(
      builder: (context, ref, child) {
        final analyticsState = ref.watch(analyticsProvider);
        
        return analyticsState.when(
          data: (data) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductivityHeatmap(data),
                const SizedBox(height: 16),
                _buildTimeSlotBreakdown(data),
                const SizedBox(height: 16),
                _buildProductivityInsights(data),
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
                  onPressed: _loadProductivityData,
                  child: const Text('再読み込み'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 生産性ヒートマップ
  Widget _buildProductivityHeatmap(AnalyticsData data) {
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
            '🔥 生産性ヒートマップ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: data.hourlyDistribution.values.isNotEmpty 
                    ? data.hourlyDistribution.values.reduce((a, b) => a > b ? a : b).toDouble() * 1.2
                    : 10,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${group.x}時: ${rod.toY.toInt()}件',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
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
                  final intensity = entry.value / (data.hourlyDistribution.values.reduce((a, b) => a > b ? a : b));
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        color: _getProductivityColor(intensity),
                        width: 25,
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
          Row(
            children: [
              const Text('低', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withValues(alpha: 0.3),
                        Colors.orange.withValues(alpha: 0.5),
                        Colors.yellow.withValues(alpha: 0.7),
                        Colors.green.withValues(alpha: 0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Text('高', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  /// 生産性色取得
  Color _getProductivityColor(double intensity) {
    if (intensity >= 0.8) {
      return Colors.green.withValues(alpha: 0.9);
    } else if (intensity >= 0.6) {
      return Colors.yellow.withValues(alpha: 0.7);
    } else if (intensity >= 0.4) {
      return Colors.orange.withValues(alpha: 0.5);
    } else {
      return Colors.red.withValues(alpha: 0.3);
    }
  }

  /// 時間帯詳細
  Widget _buildTimeSlotBreakdown(AnalyticsData data) {
    // 時間帯を分類
    final morningHours = {6, 7, 8, 9, 10, 11};
    final afternoonHours = {12, 13, 14, 15, 16, 17};
    final eveningHours = {18, 19, 20, 21, 22, 23};
    
    final morningActivity = morningHours.fold<int>(0, (sum, hour) => sum + (data.hourlyDistribution[hour] ?? 0));
    final afternoonActivity = afternoonHours.fold<int>(0, (sum, hour) => sum + (data.hourlyDistribution[hour] ?? 0));
    final eveningActivity = eveningHours.fold<int>(0, (sum, hour) => sum + (data.hourlyDistribution[hour] ?? 0));
    
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
            '⏰ 時間帯別分析',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimeSlotItem(
            '朝 (6-11時)',
            morningActivity,
            '最も生産的な時間帯',
            Icons.wb_sunny,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildTimeSlotItem(
            '午後 (12-17時)',
            afternoonActivity,
            '安定した作業時間',
            Icons.wb_sunny_outlined,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildTimeSlotItem(
            '夜 (18-23時)',
            eveningActivity,
            '集中力が低下する時間帯',
            Icons.nightlight,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  /// 時間帯項目
  Widget _buildTimeSlotItem(
    String title,
    int activity,
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
                    fontSize: 16,
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
            '$activity件',
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

  /// 生産性洞察
  Widget _buildProductivityInsights(AnalyticsData data) {
    // 最も生産的な時間帯を特定
    final maxHour = data.hourlyDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    String insight = '';
    String recommendation = '';
    
    if (maxHour >= 6 && maxHour <= 11) {
      insight = '朝の時間帯が最も生産的です。';
      recommendation = '重要なタスクは朝にスケジュールしましょう。';
    } else if (maxHour >= 12 && maxHour <= 17) {
      insight = '午後の時間帯が最も生産的です。';
      recommendation = '午後に集中して作業する時間を確保しましょう。';
    } else {
      insight = '夜の時間帯に活動が集中しています。';
      recommendation = '朝や午後の時間も活用することを検討しましょう。';
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
            '💡 生産性洞察',
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

  /// 集中時間タブ
  Widget _buildFocusTimeTab() {
    return Consumer(
      builder: (context, ref, child) {
        final analyticsState = ref.watch(analyticsProvider);
        
        return analyticsState.when(
          data: (data) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFocusTimeAnalysis(data),
                const SizedBox(height: 16),
                _buildInterruptionAnalysis(data),
                const SizedBox(height: 16),
                _buildFocusOptimization(data),
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

  /// 集中時間分析
  Widget _buildFocusTimeAnalysis(AnalyticsData data) {
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
            '🎯 集中時間分析',
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
                  '総集中時間',
                  '${data.focusTimeHours.toStringAsFixed(1)}時間',
                  '${(data.focusTimePercentage * 100).toStringAsFixed(1)}%',
                  Icons.center_focus_strong,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFocusMetric(
                  '中断回数',
                  '${data.interruptionCount}回',
                  '平均${(data.interruptionCount / 7).toStringAsFixed(1)}回/日',
                  Icons.block,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFocusMetric(
                  'マルチタスク率',
                  '${(data.multitaskingRate * 100).toStringAsFixed(1)}%',
                  data.multitaskingRate > 0.5 ? '高め' : '適切',
                  Icons.swap_horiz,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFocusMetric(
                  '休憩効率',
                  '${data.breakEfficiency.toStringAsFixed(1)}/10',
                  data.breakEfficiency > 7 ? '良好' : '改善余地あり',
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

  /// 集中メトリクス
  Widget _buildFocusMetric(
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
          const SizedBox(height: 4),
          Text(
            description,
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

  /// 中断分析
  Widget _buildInterruptionAnalysis(AnalyticsData data) {
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
            '🚫 中断分析',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '中断の影響',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '中断により集中時間が${(data.focusTimeHours * 0.3).toStringAsFixed(1)}時間減少している可能性があります。',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 集中最適化
  Widget _buildFocusOptimization(AnalyticsData data) {
    final suggestions = <String>[];
    
    if (data.interruptionCount > 10) {
      suggestions.add('通知をオフにして集中時間を確保する');
    }
    
    if (data.multitaskingRate > 0.5) {
      suggestions.add('一度に1つのタスクに集中する');
    }
    
    if (data.focusTimeHours < 4) {
      suggestions.add('ポモドーロテクニックを活用する');
    }
    
    if (suggestions.isEmpty) {
      suggestions.add('現在の集中時間は良好です。この調子で継続しましょう。');
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
            '💡 集中最適化',
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

  /// 最適化提案タブ
  Widget _buildOptimizationTab() {
    return Consumer(
      builder: (context, ref, child) {
        final analyticsState = ref.watch(analyticsProvider);
        
        return analyticsState.when(
          data: (data) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOptimizationSummary(data),
                const SizedBox(height: 16),
                _buildScheduleOptimization(data),
                const SizedBox(height: 16),
                _buildProductivityTips(data),
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

  /// 最適化サマリー
  Widget _buildOptimizationSummary(AnalyticsData data) {
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
            '🎯 最適化サマリー',
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
                const Text(
                  '現在の生産性スコア',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${data.todayEfficiencyScore.toStringAsFixed(1)}/10',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.todayEfficiencyScore >= 8 
                      ? '優秀な生産性です！'
                      : data.todayEfficiencyScore >= 6
                          ? '良好な生産性です。さらなる改善の余地があります。'
                          : '改善の余地があります。以下の提案を参考にしてください。',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// スケジュール最適化
  Widget _buildScheduleOptimization(AnalyticsData data) {
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
            '📅 スケジュール最適化',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildOptimizationItem(
            '重要タスクの配置',
            '最も生産的な時間帯に重要なタスクを配置する',
            Icons.priority_high,
            Colors.red,
          ),
          const SizedBox(height: 12),
          _buildOptimizationItem(
            '休憩時間の確保',
            '集中時間の間に適切な休憩を入れる',
            Icons.coffee,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildOptimizationItem(
            '中断の最小化',
            '通知をオフにして集中時間を確保する',
            Icons.block,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  /// 最適化項目
  Widget _buildOptimizationItem(
    String title,
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
                    fontSize: 16,
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
        ],
      ),
    );
  }

  /// 生産性のヒント
  Widget _buildProductivityTips(AnalyticsData data) {
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
            '💡 生産性のヒント',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            'ポモドーロテクニック',
            '25分集中 + 5分休憩のサイクルを繰り返す',
            Icons.timer,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            '2分ルール',
            '2分以内で終わるタスクは即座に実行する',
            Icons.flash_on,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            '時間ブロッキング',
            '特定の時間帯を特定のタスクに割り当てる',
            Icons.schedule,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            'Eisenhower Matrix',
            'タスクを重要度と緊急度で分類する',
            Icons.grid_on,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  /// ヒント項目
  Widget _buildTipItem(
    String title,
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
                    fontSize: 16,
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
        ],
      ),
    );
  }
} 
