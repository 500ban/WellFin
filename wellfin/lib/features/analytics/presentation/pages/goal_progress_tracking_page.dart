import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/analytics_provider.dart';
import '../../../calendar/presentation/providers/calendar_provider.dart';
import '../../../tasks/presentation/providers/task_provider.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../goals/presentation/providers/goal_provider.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../habits/domain/entities/habit.dart';

/// Phase 5: 目標進捗トラッキング画面
/// 詳細な目標進捗と達成予測を含むトラッキング画面
class GoalProgressTrackingPage extends ConsumerStatefulWidget {
  const GoalProgressTrackingPage({super.key});

  @override
  ConsumerState<GoalProgressTrackingPage> createState() => _GoalProgressTrackingPageState();
}

class _GoalProgressTrackingPageState extends ConsumerState<GoalProgressTrackingPage>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  bool _isLoading = false;
  bool _hasInitialized = false;
  AnalyticsData? _goalData; // 目標データを保持
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // データ読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGoalData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGoalData() async {
    if (_isLoading || _hasInitialized) return;
    
    setState(() {
      _isLoading = true;
      _hasInitialized = true;
      _goalData = null; // 古いデータをクリア
    });
    
    print('📅 目標データ読み込み開始');
    
    try {
      // 各プロバイダーからデータを読み込み
      await Future.wait([
        ref.read(calendarProvider.notifier).loadEvents(
          DateTime.now().subtract(const Duration(days: 30)),
          DateTime.now(),
        ),
        ref.read(taskProvider.notifier).loadTasks(),
        ref.read(habitProvider.notifier).loadAllHabits(),
        ref.read(goalNotifierProvider.notifier).loadGoals(),
      ]);
      
      // 少し待ってから分析を実行
      await Future.delayed(const Duration(milliseconds: 300));
      await _generateGoalProgressAnalysis();
      
    } catch (error) {
      print('❌ 目標データ読み込みエラー: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateGoalProgressAnalysis() async {
    final calendarState = ref.read(calendarProvider);
    final taskState = ref.read(taskProvider);
    final habitState = ref.read(habitProvider);
    final goalState = ref.read(goalNotifierProvider);

    // データを取得（空の場合は空配列を使用）
    final events = calendarState.events;
    final tasks = taskState.hasValue ? (taskState.value ?? <Task>[]) : <Task>[];
    final habits = habitState.hasValue ? (habitState.value ?? <Habit>[]) : <Habit>[];
    final goals = goalState.hasValue ? (goalState.value ?? <dynamic>[]) : <dynamic>[];

    print('📊 目標分析データ:');
    print('  - タスク: ${tasks.length}件');
    print('  - 習慣: ${habits.length}件');
    print('  - 目標: ${goals.length}件');
    print('  - イベント: ${events.length}件');

    // 目標データ専用の分析データを生成
    final goalAnalyticsData = AnalyticsData.fromRealData(
      events: events,
      tasks: tasks,
      habits: habits,
      goals: goals,
    );

    if (mounted) {
      setState(() {
        _goalData = goalAnalyticsData;
      });
    }
    
    print('✅ 目標分析完了');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          '🎯 目標進捗トラッキング',
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
              _loadGoalData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(icon: Icon(Icons.flag), text: '進捗'),
            Tab(icon: Icon(Icons.timeline), text: '予測'),
            Tab(icon: Icon(Icons.insights), text: '分析'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProgressTab(),
          _buildPredictionTab(),
          _buildAnalysisTab(),
        ],
      ),
    );
  }

  /// 進捗タブ
  Widget _buildProgressTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_goalData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('目標データを読み込み中...'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasInitialized = false;
                });
                _loadGoalData();
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
          _buildOverallProgressCard(_goalData!),
          const SizedBox(height: 16),
          _buildGoalProgressChart(_goalData!),
          const SizedBox(height: 16),
          _buildCategoryProgressCard(_goalData!),
          const SizedBox(height: 16),
          _buildMilestoneCard(_goalData!),
        ],
      ),
    );
  }

  /// 全体進捗カード
  Widget _buildOverallProgressCard(AnalyticsData data) {
    final overallProgress = data.totalGoals > 0 
        ? data.totalCompletedGoals / data.totalGoals 
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
          Row(
            children: [
              const Text(
                '📊 全体進捗',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.help_outline, size: 20),
                onPressed: () => _showAnalysisDetails(context, 'goalProgress'),
                tooltip: '分析詳細を表示',
              ),
            ],
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
                    Colors.green.withValues(alpha: 0.8),
                    Colors.blue.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.totalGoals > 0 ? '${(overallProgress * 100).toStringAsFixed(1)}%' : '-',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      '達成率',
                      style: TextStyle(
                        fontSize: 12,
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
                child: _buildProgressItem(
                  '完了目標',
                  '${data.totalCompletedGoals}',
                  data.totalCompletedGoals / (data.totalGoals > 0 ? data.totalGoals : 1),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressItem(
                  '進行中',
                  '${data.totalGoals - data.totalCompletedGoals}',
                  (data.totalGoals - data.totalCompletedGoals) / (data.totalGoals > 0 ? data.totalGoals : 1),
                  Icons.pending,
                  Colors.orange,
                ),
              ),
            ],
          ),
          // デバッグ情報（開発中のみ表示）
          if (data.totalGoals > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 詳細情報',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '総目標数: ${data.totalGoals}件',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '完了目標数: ${data.totalCompletedGoals}件',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '進捗率: ${(overallProgress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 進捗項目
  Widget _buildProgressItem(
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

  /// 目標進捗チャート
  Widget _buildGoalProgressChart(AnalyticsData data) {
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
            '📈 目標進捗推移',
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
                          radius: 3,
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

  /// カテゴリ進捗カード
  Widget _buildCategoryProgressCard(AnalyticsData data) {
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
            '📋 カテゴリ別進捗',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCategoryProgressItem(
                  'タスク',
                  data.totalTasks > 0 ? '${data.totalCompletedTasks}/${data.totalTasks}' : '-',
                  data.totalTasks > 0 ? data.totalCompletedTasks / data.totalTasks : 0.0,
                  Icons.task_alt,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCategoryProgressItem(
                  '習慣',
                  data.totalHabits > 0 ? '${data.totalCompletedHabits}/${data.totalHabits}' : '-',
                  data.totalHabits > 0 ? data.totalCompletedHabits / data.totalHabits : 0.0,
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
                child: _buildCategoryProgressItem(
                  '目標',
                  data.totalGoals > 0 ? '${data.totalCompletedGoals}/${data.totalGoals}' : '-',
                  data.totalGoals > 0 ? data.totalCompletedGoals / data.totalGoals : 0.0,
                  Icons.flag,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCategoryProgressItem(
                  'イベント',
                  '${data.totalCalendarEvents}',
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

  /// カテゴリ進捗項目
  Widget _buildCategoryProgressItem(
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

  /// マイルストーンカード
  Widget _buildMilestoneCard(AnalyticsData data) {
    final milestones = <String>[];
    
    if (data.totalCompletedTasks >= 10) {
      milestones.add('10個のタスクを完了しました！');
    }
    
    if (data.totalCompletedHabits >= 5) {
      milestones.add('5つの習慣を継続しています！');
    }
    
    if (data.totalCompletedGoals >= 1) {
      milestones.add('最初の目標を達成しました！');
    }
    
    if (data.focusTimeHours >= 5) {
      milestones.add('5時間の集中時間を達成しました！');
    }
    
    if (milestones.isEmpty) {
      milestones.add('最初のマイルストーンに向けて頑張りましょう！');
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
            '🏆 マイルストーン',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...milestones.map((milestone) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.yellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.yellow.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    milestone,
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

  /// 予測タブ
  Widget _buildPredictionTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_goalData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('予測データを読み込み中...'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasInitialized = false;
                });
                _loadGoalData();
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
          _buildCompletionPredictionCard(_goalData!),
          const SizedBox(height: 16),
          _buildTimelinePredictionCard(_goalData!),
          const SizedBox(height: 16),
          _buildRiskAssessmentCard(_goalData!),
        ],
      ),
    );
  }

  /// 完了予測カード
  Widget _buildCompletionPredictionCard(AnalyticsData data) {
    // 現在の進捗率から完了予測を計算
    final currentProgress = data.totalGoals > 0 
        ? data.totalCompletedGoals / data.totalGoals 
        : 0.0;
    
    final estimatedCompletionDays = currentProgress > 0 
        ? (30 * (1.0 - currentProgress) / currentProgress).round()
        : 30;
    
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
            '🔮 完了予測',
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
                  '予測完了日',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '約${estimatedCompletionDays}日後',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '現在の進捗率: ${(currentProgress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// タイムライン予測カード
  Widget _buildTimelinePredictionCard(AnalyticsData data) {
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
            '📅 タイムライン予測',
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
                         if (value.toInt() % 5 == 0 && value.toInt() >= 1 && value.toInt() <= 60) {
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
                maxX: 60,
                minY: 0,
                maxY: 1,
                lineBarsData: [
                  // 実際の進捗
                  LineChartBarData(
                    spots: data.monthlyProgress.asMap().entries.map((entry) {
                      return FlSpot(entry.key + 1.0, entry.value);
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
                          radius: 3,
                          color: Colors.green,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                  // 予測線
                  LineChartBarData(
                    spots: List.generate(60, (index) {
                      if (index < data.monthlyProgress.length) {
                        return FlSpot(index + 1.0, data.monthlyProgress[index]);
                      } else {
                        // 予測値（現在の進捗率から線形予測）
                        final currentProgress = data.monthlyProgress.isNotEmpty 
                            ? data.monthlyProgress.last 
                            : 0.0;
                        final predictedProgress = currentProgress + (index - data.monthlyProgress.length + 1) * 0.02;
                        return FlSpot(index + 1.0, predictedProgress.clamp(0.0, 1.0));
                      }
                    }),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withValues(alpha: 0.6),
                        Colors.blue.withValues(alpha: 0.2),
                      ],
                    ),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
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
                    '点線は予測進捗を示しています',
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

  /// リスク評価カード
  Widget _buildRiskAssessmentCard(AnalyticsData data) {
    final risks = <String>[];
    
    if (data.averageMultitaskingRate > 0.5) {
      risks.add('マルチタスク率が高いため、目標達成に影響する可能性があります');
    }
    
    if (data.totalInterruptionCount > 50) {
      risks.add('中断回数が多いため、集中力の低下が懸念されます');
    }
    
    if (data.focusTimeHours < 4) {
      risks.add('集中時間が少ないため、目標達成に時間がかかる可能性があります');
    }
    
    if (risks.isEmpty) {
      risks.add('現在のリスクは低いです。この調子で継続しましょう。');
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
            '⚠️ リスク評価',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...risks.map((risk) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    risk,
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

  /// 分析タブ
  Widget _buildAnalysisTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_goalData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('分析データを読み込み中...'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasInitialized = false;
                });
                _loadGoalData();
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
          _buildGoalAnalysisCard(_goalData!),
          const SizedBox(height: 16),
          _buildPerformanceAnalysisCard(_goalData!),
          const SizedBox(height: 16),
          _buildRecommendationsCard(_goalData!),
        ],
      ),
    );
  }

  /// 目標分析カード
  Widget _buildGoalAnalysisCard(AnalyticsData data) {
    final goalCompletionRate = data.totalGoals > 0 
        ? data.totalCompletedGoals / data.totalGoals 
        : 0.0;
    
    String analysis = '';
    if (goalCompletionRate >= 0.8) {
      analysis = '素晴らしい進捗です！高い達成率を維持できています。';
    } else if (goalCompletionRate >= 0.6) {
      analysis = '良い進捗です。さらなる改善の余地があります。';
    } else if (goalCompletionRate >= 0.4) {
      analysis = '進捗はありますが、改善が必要です。';
    } else {
      analysis = '進捗が遅れています。戦略の見直しを検討してください。';
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
            '📊 目標分析',
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
                  '分析結果',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  analysis,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// パフォーマンス分析カード
  Widget _buildPerformanceAnalysisCard(AnalyticsData data) {
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
            '🚀 パフォーマンス分析',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceMetric(
                  '効率性',
                  '${data.todayEfficiencyScore.toStringAsFixed(1)}/10',
                  data.todayEfficiencyScore / 10,
                  Icons.speed,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceMetric(
                  '集中力',
                  '${(data.focusTimePercentage * 100).toStringAsFixed(1)}%',
                  data.focusTimePercentage,
                  Icons.center_focus_strong,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceMetric(
                  '継続性',
                  '${(data.breakEfficiency).toStringAsFixed(1)}/10',
                  data.breakEfficiency / 10,
                  Icons.repeat,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceMetric(
                  '安定性',
                  '${(1.0 - data.averageMultitaskingRate).toStringAsFixed(2)}',
                  1.0 - data.averageMultitaskingRate,
                  Icons.trending_up,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// パフォーマンスメトリクス
  Widget _buildPerformanceMetric(
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

  /// 推奨事項カード
  Widget _buildRecommendationsCard(AnalyticsData data) {
    final recommendations = <String>[];
    
    if (data.focusTimeHours < 4) {
      recommendations.add('集中時間を増やすため、ポモドーロテクニックを試してください');
    }
    
    if (data.averageMultitaskingRate > 0.5) {
      recommendations.add('マルチタスクを減らし、一度に一つのタスクに集中してください');
    }
    
    if (data.totalInterruptionCount > 50) {
      recommendations.add('中断を減らすため、集中時間中は通知をオフにしてください');
    }
    
    if (data.breakEfficiency < 7) {
      recommendations.add('休憩の質を向上させるため、適切な休憩時間を設定してください');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('現在のパフォーマンスは良好です。この調子で継続しましょう。');
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
            '💡 推奨事項',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...recommendations.map((recommendation) => Container(
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
                    recommendation,
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
} 
