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


/// Phase 5: 週間サマリーレポート画面
/// 詳細な週間分析とグラフ機能を含む包括的なレポート
class WeeklyReportPage extends ConsumerStatefulWidget {
  const WeeklyReportPage({super.key});

  @override
  ConsumerState<WeeklyReportPage> createState() => _WeeklyReportPageState();
}

class _WeeklyReportPageState extends ConsumerState<WeeklyReportPage>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  DateTime _selectedWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  bool _isLoading = false;
  bool _hasInitialized = false;
  AnalyticsData? _weeklyData; // 週間データを保持
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // データ読み込み（遅延実行）
    Future.delayed(const Duration(milliseconds: 100), () {
      _loadWeeklyData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWeeklyData() async {
    // 重複実行を防ぐ
    if (_isLoading || _hasInitialized) return;
    
    setState(() {
      _isLoading = true;
      _hasInitialized = true;
      _weeklyData = null; // 古いデータをクリア
    });
    
    final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
    
    print('📅 週間データ読み込み開始: ${DateFormat('M/d').format(_selectedWeekStart)} - ${DateFormat('M/d').format(weekEnd)}');
    
    try {
      // 各プロバイダーからデータを読み込み
      await Future.wait([
        ref.read(taskProvider.notifier).loadTasks(),
        ref.read(habitProvider.notifier).loadAllHabits(),
        ref.read(goalNotifierProvider.notifier).loadGoals(),
        ref.read(calendarProvider.notifier).loadEvents(_selectedWeekStart, weekEnd),
      ]);
      
      // 少し待ってからレポート生成
      await Future.delayed(const Duration(milliseconds: 300));
      await _generateWeeklyReport();
      
    } catch (error) {
      print('❌ 週間データ読み込みエラー: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateWeeklyReport() async {
    final calendarState = ref.read(calendarProvider);
    final taskState = ref.read(taskProvider);
    final habitState = ref.read(habitProvider);
    final goalState = ref.read(goalNotifierProvider);

    // データを取得（空の場合は空配列を使用）
    final allEvents = calendarState.events;
    final allTasks = taskState.hasValue ? (taskState.value ?? <Task>[]) : <Task>[];
    final allHabits = habitState.hasValue ? (habitState.value ?? <Habit>[]) : <Habit>[];
    final allGoals = goalState.hasValue ? (goalState.value ?? <dynamic>[]) : <dynamic>[];

    // 選択した週の期間でデータをフィルタリング
    final weekEnd = _selectedWeekStart.add(const Duration(days: 7));
    
    // 週間のタスクをフィルタリング
    final weeklyTasks = allTasks.where((task) {
      return task.createdAt.isAfter(_selectedWeekStart.subtract(const Duration(days: 1))) &&
             task.createdAt.isBefore(weekEnd);
    }).toList();
    
    // 週間のイベントをフィルタリング
    final weeklyEvents = allEvents.where((event) {
      return event.startTime.isAfter(_selectedWeekStart.subtract(const Duration(days: 1))) &&
             event.startTime.isBefore(weekEnd);
    }).toList();
    
    // 習慣は全期間（週間での完了状況を分析するため）
    final weeklyHabits = allHabits;
    
    // 目標は全期間（週間での進捗を分析するため）
    final weeklyGoals = allGoals;

    print('📊 週間フィルタリング結果:');
    print('  - 週間タスク: ${weeklyTasks.length}件 (完了: ${weeklyTasks.where((t) => t.isCompleted).length}件)');
    print('  - 週間イベント: ${weeklyEvents.length}件');
    print('  - 習慣: ${weeklyHabits.length}件');
    print('  - 目標: ${weeklyGoals.length}件');

    // 週間データ専用の分析データを生成
    final weeklyAnalyticsData = AnalyticsData.fromRealData(
      events: weeklyEvents,
      tasks: weeklyTasks,
      habits: weeklyHabits,
      goals: weeklyGoals,
    );

    if (mounted) {
      setState(() {
        _weeklyData = weeklyAnalyticsData;
      });
    }
    
    print('✅ 週間レポート生成完了');
  }

  void _selectPreviousWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
    });
    _loadWeeklyData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 週間レポート',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${DateFormat('M/d').format(_selectedWeekStart)} - ${DateFormat('M/d').format(_selectedWeekStart.add(const Duration(days: 6)))}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _selectPreviousWeek,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
                _hasInitialized = false;
              });
              _loadWeeklyData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(icon: Icon(Icons.summarize), text: 'サマリー'),
            Tab(icon: Icon(Icons.timeline), text: '詳細分析'),
            Tab(icon: Icon(Icons.trending_up), text: '傾向'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildDetailedAnalysisTab(),
          _buildTrendsTab(),
        ],
      ),
    );
  }

  /// サマリータブ
  Widget _buildSummaryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_weeklyData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('週間データを読み込み中...'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasInitialized = false;
                });
                _loadWeeklyData();
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
          _buildWeekNavigationCard(),
          const SizedBox(height: 16),
          _buildWeeklyOverviewCard(_weeklyData!),
          const SizedBox(height: 16),
          _buildWeeklyProgressChart(_weeklyData!),
          const SizedBox(height: 16),
          _buildWeeklyStatsCard(_weeklyData!),
        ],
      ),
    );
  }

  /// 週間概要カード
  Widget _buildWeeklyOverviewCard(AnalyticsData data) {
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
          Row(
            children: [
              const Text(
                '📊 週間概要',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.help_outline, size: 20),
                onPressed: () => _showAnalysisDetails(context, 'taskCompletionRate'),
                tooltip: '分析詳細を表示',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'タスク完了率',
                  '${(data.todayCompletionRate * 100).toStringAsFixed(1)}%',
                  data.todayCompletionRate,
                  Icons.task_alt,
                  Colors.blue,
                  'taskCompletionRate',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  '効率性スコア',
                  '${data.todayEfficiencyScore.toStringAsFixed(1)}',
                  data.todayEfficiencyScore / 10,
                  Icons.speed,
                  Colors.green,
                  'efficiencyScore',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  '習慣実行率',
                  data.totalHabits > 0 ? '${((data.completedHabits / data.totalHabits) * 100).toStringAsFixed(1)}%' : '-',
                  data.totalHabits > 0 ? data.completedHabits / data.totalHabits : 0.0,
                  Icons.loop,
                  Colors.purple,
                  'habitCompletionRate',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  '目標進捗',
                  data.totalGoals > 0 ? '${((data.completedGoals / data.totalGoals) * 100).toStringAsFixed(1)}%' : '-',
                  data.totalGoals > 0 ? data.completedGoals / data.totalGoals : 0.0,
                  Icons.flag,
                  Colors.orange,
                  'goalProgress',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 分析詳細情報を表示するダイアログ
  void _showAnalysisDetails(BuildContext context, String analysisType) {
    final details = AnalyticsData.getAnalysisDetails();
    final info = details[analysisType];
    
    if (info == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                info['title'],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '📝 説明',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(info['description']),
              const SizedBox(height: 16),
              const Text(
                '📊 計算式',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  info['formula'],
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '🎯 目標範囲',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  info['goodRange'],
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '💡 改善のヒント',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...info['tips'].map<Widget>((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(child: Text(tip)),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// メトリックカード（_buildOverviewItemと同じ実装）
  Widget _buildMetricCard(
    String title,
    String value,
    double progress,
    IconData icon,
    Color color,
    String analysisType,
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
              IconButton(
                icon: const Icon(Icons.info_outline, size: 16),
                onPressed: () => _showAnalysisDetails(context, analysisType),
                tooltip: '分析詳細を表示',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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

  /// 週間ナビゲーションカード
  Widget _buildWeekNavigationCard() {
    return Container(
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
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
                             setState(() {
                 _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
                 _hasInitialized = false;
               });
              _loadWeeklyData();
            },
          ),
          Column(
            children: [
              Text(
                '${_selectedWeekStart.month}/${_selectedWeekStart.day} - ${_selectedWeekStart.add(const Duration(days: 6)).month}/${_selectedWeekStart.add(const Duration(days: 6)).day}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '週間レポート',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
                _isLoading = false; // ここでは_hasInitializedを削除
              });
              _loadWeeklyData();
            },
          ),
        ],
      ),
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
            '📊 週間進捗',
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
                          radius: 4,
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

  /// 詳細分析タブ
  Widget _buildDetailedAnalysisTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_weeklyData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('詳細分析データを読み込み中...'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWeeklyData,
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
          _buildCategoryAnalysisCard(_weeklyData!),
          const SizedBox(height: 16),
          _buildTimeDistributionCard(_weeklyData!),
          const SizedBox(height: 16),
          _buildProductivityAnalysisCard(_weeklyData!),
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
                sections: data.categoryDistribution.entries.map((entry) {
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
            '⏰ 時間別分布',
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
                        color: Colors.blue.withValues(alpha: 0.8),
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
            '集中時間',
            '${data.focusTimeHours.toStringAsFixed(1)}時間',
            '${(data.focusTimePercentage * 100).toStringAsFixed(1)}%',
                              Icons.center_focus_strong,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildProductivityMetric(
            '中断回数',
            '${data.interruptionCount}回',
            '平均${(data.interruptionCount / 7).toStringAsFixed(1)}回/日',
            Icons.block,
            Colors.red,
          ),
          const SizedBox(height: 12),
          _buildProductivityMetric(
            'マルチタスク率',
            '${(data.multitaskingRate * 100).toStringAsFixed(1)}%',
            data.multitaskingRate > 0.5 ? '高め' : '適切',
            Icons.swap_horiz,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildProductivityMetric(
            '休憩効率',
            '${data.breakEfficiency.toStringAsFixed(1)}/10',
            data.breakEfficiency > 7 ? '良好' : '改善余地あり',
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

    if (_weeklyData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('傾向データを読み込み中...'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWeeklyData,
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
          _buildTrendAnalysisCard(_weeklyData!),
          const SizedBox(height: 16),
          _buildImprovementSuggestionsCard(_weeklyData!),
        ],
      ),
    );
  }

  /// 傾向分析カード
  Widget _buildTrendAnalysisCard(AnalyticsData data) {
    // 週間進捗の傾向を分析
    final progress = data.weeklyProgress;
    String trend = '';
    String trendDescription = '';
    
    if (progress.length >= 2) {
      final firstHalf = progress.take(progress.length ~/ 2).reduce((a, b) => a + b) / (progress.length ~/ 2);
      final secondHalf = progress.skip(progress.length ~/ 2).reduce((a, b) => a + b) / (progress.length - progress.length ~/ 2);
      
      if (secondHalf > firstHalf + 0.1) {
        trend = '上昇傾向';
        trendDescription = '週の後半で生産性が向上しています。';
      } else if (secondHalf < firstHalf - 0.1) {
        trend = '下降傾向';
        trendDescription = '週の後半で生産性が低下しています。';
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
    
    if (data.interruptionCount > 10) {
      suggestions.add('中断回数が多いため、集中時間の確保を検討してください');
    }
    
    if (data.multitaskingRate > 0.5) {
      suggestions.add('マルチタスク率が高いため、タスクの優先順位付けを改善してください');
    }
    
    if (data.focusTimeHours < 4) {
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

  /// 週間統計カード
  Widget _buildWeeklyStatsCard(AnalyticsData data) {
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
            '📈 週間統計',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '集中時間',
                  '${data.focusTimeHours.toStringAsFixed(1)}時間',
                  Icons.center_focus_strong,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '中断回数',
                  '${data.interruptionCount}回',
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
                child: _buildStatItem(
                  '完了タスク',
                  '${data.completedTasks}件',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'イベント',
                  '${data.totalCalendarEvents}件',
                  Icons.event,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 統計項目
  Widget _buildStatItem(
    String title,
    String value,
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
        ],
      ),
    );
  }
} 
