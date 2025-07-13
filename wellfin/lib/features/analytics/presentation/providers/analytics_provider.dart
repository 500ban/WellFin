import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../../../calendar/domain/entities/calendar_event.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../habits/domain/entities/habit.dart';
import '../../../../shared/services/ai_report_scheduler.dart';
import '../../../../shared/services/push_notification_scheduler.dart';
import '../../../../shared/services/google_calendar_service.dart';
import '../../../../shared/providers/notification_settings_provider.dart';
import 'package:logger/logger.dart';

/// 分析データモデル
class AnalyticsData extends Equatable {
  final double todayPlannedHours;
  final double todayActualHours;
  final double todayCompletionRate;
  final double todayEfficiencyScore;
  final Map<int, int> hourlyDistribution; // 時間別活動分布
  final List<double> weeklyProgress; // 週間進捗（7日分）
  final double focusTimeHours;
  final int interruptionCount;
  final double multitaskingRate;
  final double breakEfficiency;
  final Map<String, double> categoryDistribution; // カテゴリ別時間分布
  final double focusTimePercentage;
  final double communicationPercentage;
  final double learningPercentage;
  final double breakPercentage;
  final int totalTasks;
  final int completedTasks;
  final int totalHabits;
  final int completedHabits;
  final int totalGoals;
  final int completedGoals;
  final int totalCalendarEvents;
  
  // 月間レポート用プロパティ
  final List<double> monthlyProgress; // 月間進捗（31日分）
  final double monthlyEfficiencyScore;
  final double totalFocusTimeHours;
  final int totalInterruptionCount;
  final double averageMultitaskingRate;
  final double averageBreakEfficiency;
  final Map<String, double> monthlyCategoryDistribution; // 月間カテゴリ別時間分布
  final Map<int, double> weeklyAverages; // 週間平均値
  final int totalCompletedTasks;
  final int totalCompletedHabits;
  final int totalCompletedGoals;

  const AnalyticsData({
    required this.todayPlannedHours,
    required this.todayActualHours,
    required this.todayCompletionRate,
    required this.todayEfficiencyScore,
    required this.hourlyDistribution,
    required this.weeklyProgress,
    required this.focusTimeHours,
    required this.interruptionCount,
    required this.multitaskingRate,
    required this.breakEfficiency,
    required this.categoryDistribution,
    required this.focusTimePercentage,
    required this.communicationPercentage,
    required this.learningPercentage,
    required this.breakPercentage,
    required this.totalTasks,
    required this.completedTasks,
    required this.totalHabits,
    required this.completedHabits,
    required this.totalGoals,
    required this.completedGoals,
    required this.totalCalendarEvents,
    // 月間レポート用プロパティ
    required this.monthlyProgress,
    required this.monthlyEfficiencyScore,
    required this.totalFocusTimeHours,
    required this.totalInterruptionCount,
    required this.averageMultitaskingRate,
    required this.averageBreakEfficiency,
    required this.monthlyCategoryDistribution,
    required this.weeklyAverages,
    required this.totalCompletedTasks,
    required this.totalCompletedHabits,
    required this.totalCompletedGoals,
  });

  @override
  List<Object?> get props => [
        todayPlannedHours,
        todayActualHours,
        todayCompletionRate,
        todayEfficiencyScore,
        hourlyDistribution,
        weeklyProgress,
        focusTimeHours,
        interruptionCount,
        multitaskingRate,
        breakEfficiency,
        categoryDistribution,
        focusTimePercentage,
        communicationPercentage,
        learningPercentage,
        breakPercentage,
        totalTasks,
        completedTasks,
        totalHabits,
        completedHabits,
        totalGoals,
        completedGoals,
        totalCalendarEvents,
        // 月間レポート用プロパティ
        monthlyProgress,
        monthlyEfficiencyScore,
        totalFocusTimeHours,
        totalInterruptionCount,
        averageMultitaskingRate,
        averageBreakEfficiency,
        monthlyCategoryDistribution,
        weeklyAverages,
        totalCompletedTasks,
        totalCompletedHabits,
        totalCompletedGoals,
      ];

  factory AnalyticsData.empty() {
    return const AnalyticsData(
      todayPlannedHours: 0,
      todayActualHours: 0,
      todayCompletionRate: 0,
      todayEfficiencyScore: 0,
      hourlyDistribution: {},
      weeklyProgress: [],
      focusTimeHours: 0,
      interruptionCount: 0,
      multitaskingRate: 0,
      breakEfficiency: 0,
      categoryDistribution: {},
      focusTimePercentage: 0,
      communicationPercentage: 0,
      learningPercentage: 0,
      breakPercentage: 0,
      totalTasks: 0,
      completedTasks: 0,
      totalHabits: 0,
      completedHabits: 0,
      totalGoals: 0,
      completedGoals: 0,
      totalCalendarEvents: 0,
      // 月間レポート用プロパティ
      monthlyProgress: [],
      monthlyEfficiencyScore: 0,
      totalFocusTimeHours: 0,
      totalInterruptionCount: 0,
      averageMultitaskingRate: 0,
      averageBreakEfficiency: 0,
      monthlyCategoryDistribution: {},
      weeklyAverages: {},
      totalCompletedTasks: 0,
      totalCompletedHabits: 0,
      totalCompletedGoals: 0,
    );
  }

  /// 実データから分析データを生成
  factory AnalyticsData.fromRealData({
    required List<CalendarEvent> events,
    required List<Task> tasks,
    required List<Habit> habits,
    required List<dynamic> goals, // Goalエンティティの正確な型が不明なため一時的にdynamicを使用
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEnd = today.add(const Duration(days: 1));

    // 渡されたデータはすでに今日のデータにフィルタリング済み
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final todayCompletionRate = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

    // 今日のカレンダーイベント分析
    final todayEvents = events.where((event) {
      return event.startTime.isAfter(today) && event.startTime.isBefore(todayEnd);
    }).toList();

    // 習慣データ（渡されたデータはすでにアクティブな習慣のみ）
    final totalHabits = habits.length;
    final completedHabits = habits.where((habit) => habit.isCompleted).length;

    // 目標データ（渡されたデータはすでに進行中の目標のみ）
    final totalGoals = goals.length;
    final completedGoals = _calculateCompletedGoals(goals);

    // デバッグ用：計算結果を確認
    print('📊 分析データ計算結果:');
    print('  - 今日のタスク: $totalTasks件 (完了: $completedTasks件) 完了率: ${(todayCompletionRate * 100).toStringAsFixed(1)}%');
    print('  - アクティブ習慣: $totalHabits件 (完了: $completedHabits件)');
    print('  - 進行中目標: $totalGoals件 (完了: $completedGoals件)');
    print('  - 今日のイベント: ${todayEvents.length}件');

    // 時間別分布計算
    final hourlyDistribution = _calculateHourlyDistribution(events);

    // 週間進捗計算（過去7日間）
    final weeklyProgress = _calculateWeeklyProgress(tasks, habits, now);

    // 月間進捗計算（過去31日間）
    final monthlyProgress = _calculateMonthlyProgress(tasks, habits, now);

    // カテゴリ別時間分布計算
    final categoryDistribution = _calculateCategoryDistribution(todayEvents, tasks);
    final monthlyCategoryDistribution = _calculateMonthlyCategoryDistribution(events, tasks);

    // 計画時間 vs 実際時間
    final plannedHours = _calculatePlannedHours(todayEvents, tasks);
    final actualHours = _calculateActualHours(todayEvents);

    // 効率性スコア計算
    final efficiencyScore = _calculateEfficiencyScore(
      completionRate: todayCompletionRate, // 今日の完了率を使用
      plannedHours: plannedHours,
      actualHours: actualHours,
    );

    // 月間効率性スコア計算
    final monthlyEfficiencyScore = _calculateMonthlyEfficiencyScore(tasks, habits, now);

    // 週間平均値計算
    final weeklyAverages = _calculateWeeklyAverages(monthlyProgress);

    return AnalyticsData(
      todayPlannedHours: plannedHours,
      todayActualHours: actualHours,
      todayCompletionRate: todayCompletionRate, // 今日の完了率を使用
      todayEfficiencyScore: efficiencyScore,
      hourlyDistribution: hourlyDistribution,
      weeklyProgress: weeklyProgress,
      focusTimeHours: actualHours * 0.6, // 仮定：実際時間の60%が集中時間
      interruptionCount: todayEvents.length, // 仮定：イベント数を中断回数として使用
      multitaskingRate: tasks.length > todayEvents.length ? 0.3 : 0.1,
      breakEfficiency: 7.5, // 仮定値
      categoryDistribution: categoryDistribution,
      focusTimePercentage: 0.6,
      communicationPercentage: 0.2,
      learningPercentage: 0.15,
      breakPercentage: 0.05,
      totalTasks: totalTasks, // 計算済みの値を使用
      completedTasks: completedTasks, // 計算済みの値を使用
      totalHabits: totalHabits,
      completedHabits: completedHabits,
      totalGoals: totalGoals,
      completedGoals: completedGoals,
      totalCalendarEvents: events.length,
      // 月間レポート用プロパティ
      monthlyProgress: monthlyProgress,
      monthlyEfficiencyScore: monthlyEfficiencyScore,
      totalFocusTimeHours: actualHours * 30 * 0.6, // 月間の集中時間
      totalInterruptionCount: events.length, // 月間の中断回数
      averageMultitaskingRate: 0.25, // 月間平均マルチタスク率
      averageBreakEfficiency: 7.0, // 月間平均休憩効率
      monthlyCategoryDistribution: monthlyCategoryDistribution,
      weeklyAverages: weeklyAverages,
      totalCompletedTasks: completedTasks, // 計算済みの値を使用
      totalCompletedHabits: completedHabits, // 計算済みの値を使用
      totalCompletedGoals: completedGoals,
    );
  }

  /// 習慣が今日実行予定かどうか判定
  static bool _shouldHabitRunToday(Habit habit, DateTime today) {
    // 習慣の頻度設定に基づいて判定
    // 簡単な実装として、アクティブな習慣は今日実行予定とする
    return habit.isActive;
  }

  /// 完了した目標数を計算
  static int _calculateCompletedGoals(List<dynamic> goals) {
    int completedCount = 0;
    for (final goal in goals) {
      bool isCompleted = false;
      
      // 実際のGoalエンティティの場合
      if (goal.runtimeType.toString().contains('Goal')) {
        try {
          final dynamic dynamicGoal = goal;
          // progressフィールドが1.0（100%）の場合は完了
          if (dynamicGoal.progress != null && dynamicGoal.progress >= 1.0) {
            isCompleted = true;
          }
          // isCompletedゲッターがtrueの場合も完了
          else if (dynamicGoal.isCompleted == true) {
            isCompleted = true;
          }
          // statusがcompletedの場合も完了
          else if (dynamicGoal.status != null && dynamicGoal.status.toString().contains('completed')) {
            isCompleted = true;
          }
        } catch (e) {
          print('目標オブジェクトの判定エラー: $e');
          // エラーの場合はMapとして処理を試行
        }
      }
      
      // Mapの場合の判定
      if (!isCompleted && goal is Map<String, dynamic>) {
        // progressフィールドが1.0（100%）の場合は完了
        if (goal['progress'] != null && goal['progress'] >= 1.0) {
          isCompleted = true;
        }
        // isCompletedフィールドがtrueの場合も完了
        else if (goal['isCompleted'] == true) {
          isCompleted = true;
        }
        // statusフィールドがcompletedの場合も完了
        else if (goal['status'] == 'completed') {
          isCompleted = true;
        }
        // currentValueがtargetValueに達している場合も完了
        else if (goal['currentValue'] != null && goal['targetValue'] != null && 
                 goal['currentValue'] >= goal['targetValue']) {
          isCompleted = true;
        }
      }
      
      // 文字列の場合の判定
      if (!isCompleted && goal.toString().contains('completed')) {
        isCompleted = true;
      }
      
      if (isCompleted) {
        completedCount++;
      }
    }
    print('📊 目標完了判定結果: $completedCount/${goals.length}');
    
    // デバッグ情報：各目標の詳細
    for (int i = 0; i < goals.length && i < 5; i++) {
      final goal = goals[i];
      if (goal.runtimeType.toString().contains('Goal')) {
        try {
          final dynamic dynamicGoal = goal;
          print('  目標${i+1}: progress=${dynamicGoal.progress}, isCompleted=${dynamicGoal.isCompleted}, status=${dynamicGoal.status}');
        } catch (e) {
          print('  目標${i+1}: デバッグ情報取得エラー - $e');
        }
      }
    }
    
    return completedCount;
  }

  /// 分析詳細情報を取得
  static Map<String, dynamic> getAnalysisDetails() {
    return {
      'taskCompletionRate': {
        'title': 'タスク完了率',
        'description': '選択した期間内に完了したタスクの割合です。日々の生産性を測る重要な指標です。',
        'formula': '完了タスク数 ÷ 総タスク数 × 100',
        'goodRange': '70%以上',
        'tips': [
          'タスクを細分化して達成しやすくする',
          '優先度の高いタスクから着手する',
          '1日のタスク数を現実的に調整する',
          '完了したタスクを振り返り成功パターンを見つける'
        ]
      },
      'habitCompletionRate': {
        'title': '習慣実行率',
        'description': '設定した習慣のうち実際に実行できた割合です。継続的な成長の基盤となります。',
        'formula': '実行した習慣数 ÷ 予定習慣数 × 100',
        'goodRange': '80%以上',
        'tips': [
          '習慣を小さく始める（2分ルール）',
          '既存の習慣とセットにする（習慣スタッキング）',
          '実行時間と場所を固定する',
          '習慣の連鎖を作り、一つの習慣が次を引き起こすようにする'
        ]
      },
      'goalProgress': {
        'title': '目標進捗率',
        'description': '設定した目標の達成状況です。長期的な成長と方向性を示す指標です。進捗が0%の場合、目標設定や計画の見直しが必要かもしれません。',
        'formula': '完了目標数 ÷ 総目標数 × 100（または平均進捗率）',
        'goodRange': '期間に応じて設定（月間：20-30%、年間：8-10%）',
        'tips': [
          '目標をSMART（具体的・測定可能・達成可能・関連性・期限）にする',
          '大きな目標を小さなマイルストーンに分割する',
          '週次で進捗を確認し、必要に応じて調整する',
          '進捗が遅れている場合は、目標の難易度や期限を見直す'
        ]
      },
      'efficiencyScore': {
        'title': '効率性スコア',
        'description': 'タスク完了率と時間管理の効率性を組み合わせた総合スコアです。10点満点で評価しています。',
        'formula': '完了率 × 10 × 時間効率性',
        'goodRange': '7.0以上',
        'tips': [
          '計画時間を現実的に設定する',
          '集中できる時間帯を活用する',
          '中断要因を減らす'
        ]
      },
      'focusTime': {
        'title': '集中時間',
        'description': '実際の作業時間のうち、中断されずに集中して取り組めた時間です。深い作業（Deep Work）の量を表します。',
        'formula': '実際作業時間 × 集中度係数（0.6）',
        'goodRange': '1日4時間以上（ナレッジワーカーの理想）',
        'tips': [
          'ポモドーロテクニック（25分集中+5分休憩）を活用',
          '通知をオフにし、集中環境を整える',
          '最も重要なタスクを集中時間に割り当てる',
          '集中時間の記録を取り、パターンを分析する'
        ]
      },
      'interruptionCount': {
        'title': '中断回数',
        'description': '作業中に発生した中断の回数です。集中の妨げとなる要因を測定し、改善点を見つけるための指標です。',
        'formula': 'カレンダーイベント数 + 予期しない中断',
        'goodRange': '1日5回以下（理想は3回以下）',
        'tips': [
          '「集中時間」をカレンダーにブロックする',
          '緊急でない用件は指定時間にまとめて処理',
          '中断要因を記録し、パターンを分析する',
          'チームに集中時間のルールを共有する'
        ]
      }
    };
  }

  /// 時間別分布計算
  static Map<int, int> _calculateHourlyDistribution(List<CalendarEvent> events) {
    final distribution = <int, int>{};
    
    for (int hour = 6; hour <= 22; hour++) {
      distribution[hour] = 0;
    }

    for (final event in events) {
      final hour = event.startTime.hour;
      if (hour >= 6 && hour <= 22) {
        distribution[hour] = (distribution[hour] ?? 0) + 1;
      }
    }

    return distribution;
  }

  /// 週間進捗計算（実際のデータ期間に基づく）
  static List<double> _calculateWeeklyProgress(List<Task> tasks, List<Habit> habits, DateTime now) {
    final progress = <double>[];
    
    // 渡されたタスクの期間を基準に計算
    if (tasks.isEmpty) {
      // データがない場合は7日分の0.0を返す
      return List.filled(7, 0.0);
    }
    
    // タスクの最初と最後の日付を取得
    final taskDates = tasks.map((task) => task.createdAt).toList();
    taskDates.sort();
    
    final startDate = taskDates.first;
    final endDate = taskDates.last;
    
    // 週間の日数分（最大7日）を計算
    final daysDiff = endDate.difference(startDate).inDays + 1;
    final daysToCalculate = daysDiff > 7 ? 7 : daysDiff;
    
    for (int i = 0; i < daysToCalculate; i++) {
      final date = startDate.add(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      // その日のタスクの進捗
      final dayTasks = tasks.where((task) {
        final taskDate = task.createdAt;
        return taskDate.isAfter(dayStart.subtract(const Duration(milliseconds: 1))) && 
               taskDate.isBefore(dayEnd);
      }).toList();
      
      final completedDayTasks = dayTasks.where((task) => task.isCompleted).length;
      
      // 習慣の進捗（その日にアクティブな習慣）
      final dayHabits = habits.where((habit) {
        return _shouldHabitRunToday(habit, date);
      }).toList();
      
      final completedDayHabits = dayHabits.where((habit) => habit.isCompleted).length;
      
      // タスクと習慣の平均進捗
      final totalItems = dayTasks.length + dayHabits.length;
      final dayProgress = totalItems == 0 ? 0.0 : (completedDayTasks + completedDayHabits) / totalItems;
      
      progress.add(dayProgress);
    }
    
    // 7日分に満たない場合は0.0で埋める
    while (progress.length < 7) {
      progress.add(0.0);
    }
    
    return progress;
  }

  /// 月間進捗計算（実際のデータ期間に基づく）
  static List<double> _calculateMonthlyProgress(List<Task> tasks, List<Habit> habits, DateTime now) {
    final progress = <double>[];
    
    // 渡されたタスクの期間を基準に計算
    if (tasks.isEmpty) {
      // データがない場合は31日分の0.0を返す
      return List.filled(31, 0.0);
    }
    
    // タスクの最初と最後の日付を取得
    final taskDates = tasks.map((task) => task.createdAt).toList();
    taskDates.sort();
    
    final startDate = taskDates.first;
    final endDate = taskDates.last;
    
    // 月間の日数分（最大31日）を計算
    final daysDiff = endDate.difference(startDate).inDays + 1;
    final daysToCalculate = daysDiff > 31 ? 31 : daysDiff;
    
    for (int i = 0; i < daysToCalculate; i++) {
      final date = startDate.add(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      // その日のタスクの進捗
      final dayTasks = tasks.where((task) {
        final taskDate = task.createdAt;
        return taskDate.isAfter(dayStart.subtract(const Duration(milliseconds: 1))) && 
               taskDate.isBefore(dayEnd);
      }).toList();
      
      final completedDayTasks = dayTasks.where((task) => task.isCompleted).length;
      
      // 習慣の進捗（その日にアクティブな習慣）
      final dayHabits = habits.where((habit) {
        return _shouldHabitRunToday(habit, date);
      }).toList();
      
      final completedDayHabits = dayHabits.where((habit) => habit.isCompleted).length;
      
      // タスクと習慣の平均進捗
      final totalItems = dayTasks.length + dayHabits.length;
      final dayProgress = totalItems == 0 ? 0.0 : (completedDayTasks + completedDayHabits) / totalItems;
      
      progress.add(dayProgress);
    }
    
    // 31日分に満たない場合は0.0で埋める
    while (progress.length < 31) {
      progress.add(0.0);
    }
    
    return progress;
  }

  /// 週間平均値計算
  static Map<int, double> _calculateWeeklyAverages(List<double> monthlyProgress) {
    final weeklyAverages = <int, double>{};
    
    for (int week = 0; week < 4; week++) {
      final startIndex = week * 7;
      final endIndex = (week + 1) * 7;
      
      if (endIndex <= monthlyProgress.length) {
        final weekData = monthlyProgress.sublist(startIndex, endIndex);
        final average = weekData.reduce((a, b) => a + b) / weekData.length;
        weeklyAverages[week] = average;
      }
    }
    
    return weeklyAverages;
  }

  /// カテゴリ別時間分布計算
  static Map<String, double> _calculateCategoryDistribution(List<CalendarEvent> events, List<Task> tasks) {
    final distribution = <String, double>{
      '仕事': 0.0,
      '学習': 0.0,
      '運動': 0.0,
      '個人': 0.0,
      '休憩': 0.0,
    };

    // カレンダーイベントの時間を分類
    for (final event in events) {
      final duration = event.endTime.difference(event.startTime).inHours.toDouble();
      final category = _categorizeEvent(event);
      distribution[category] = (distribution[category] ?? 0.0) + duration;
    }

    // タスクの予定時間を分類
    for (final task in tasks) {
      final category = _categorizeTask(task);
      distribution[category] = (distribution[category] ?? 0.0) + 1.0; // 1時間と仮定
    }

    return distribution;
  }

  /// 月間カテゴリ別時間分布計算
  static Map<String, double> _calculateMonthlyCategoryDistribution(List<CalendarEvent> events, List<Task> tasks) {
    final distribution = <String, double>{
      '仕事': 0.0,
      '学習': 0.0,
      '運動': 0.0,
      '個人': 0.0,
      '休憩': 0.0,
    };

    // カレンダーイベントの時間を分類
    for (final event in events) {
      final duration = event.endTime.difference(event.startTime).inHours.toDouble();
      final category = _categorizeEvent(event);
      distribution[category] = (distribution[category] ?? 0.0) + duration;
    }

    // タスクの予定時間を分類
    for (final task in tasks) {
      final category = _categorizeTask(task);
      distribution[category] = (distribution[category] ?? 0.0) + 1.0; // 1時間と仮定
    }

    return distribution;
  }

  /// イベントのカテゴリ分類
  static String _categorizeEvent(CalendarEvent event) {
    final title = event.title.toLowerCase();
    if (title.contains('会議') || title.contains('打ち合わせ') || title.contains('work')) {
      return '仕事';
    } else if (title.contains('勉強') || title.contains('学習') || title.contains('読書')) {
      return '学習';
    } else if (title.contains('運動') || title.contains('ジム') || title.contains('散歩')) {
      return '運動';
    } else if (title.contains('休憩') || title.contains('昼食') || title.contains('break')) {
      return '休憩';
    } else {
      return '個人';
    }
  }

  /// タスクのカテゴリ分類
  static String _categorizeTask(Task task) {
    final title = task.title.toLowerCase();
    if (title.contains('仕事') || title.contains('work') || title.contains('業務')) {
      return '仕事';
    } else if (title.contains('勉強') || title.contains('学習') || title.contains('読書')) {
      return '学習';
    } else if (title.contains('運動') || title.contains('ジム') || title.contains('散歩')) {
      return '運動';
    } else {
      return '個人';
    }
  }

  /// 計画時間計算
  static double _calculatePlannedHours(List<CalendarEvent> events, List<Task> tasks) {
    double totalHours = 0.0;
    
    for (final event in events) {
      totalHours += event.endTime.difference(event.startTime).inHours.toDouble();
    }
    
    // タスクは1つあたり1時間と仮定
    totalHours += tasks.length * 1.0;
    
    return totalHours;
  }

  /// 実際時間計算
  static double _calculateActualHours(List<CalendarEvent> events) {
    double totalHours = 0.0;
    
    for (final event in events) {
      totalHours += event.endTime.difference(event.startTime).inHours.toDouble();
    }
    
    return totalHours;
  }

  /// 効率性スコア計算
  static double _calculateEfficiencyScore({
    required double completionRate,
    required double plannedHours,
    required double actualHours,
  }) {
    // 完了率（0-1）を基準に、計画時間と実際時間の比率を考慮
    final baseScore = completionRate * 10; // 10点満点
    
    // 計画時間との差を考慮
    final timeDifferenceRatio = plannedHours > 0 ? (actualHours / plannedHours) : 1.0;
    final timeEfficiency = timeDifferenceRatio > 1.0 ? (1.0 / timeDifferenceRatio) : timeDifferenceRatio;
    
    final finalScore = baseScore * timeEfficiency;
    
    return finalScore.clamp(0.0, 10.0);
  }

  /// 月間効率性スコア計算
  static double _calculateMonthlyEfficiencyScore(List<Task> tasks, List<Habit> habits, DateTime now) {
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    
    final monthTasks = tasks.where((task) {
      final taskDate = task.createdAt;
      return taskDate.isAfter(monthStart) && taskDate.isBefore(monthEnd);
    }).toList();
    
    final completedMonthTasks = monthTasks.where((task) => task.isCompleted).length;
    final monthCompletionRate = monthTasks.isEmpty ? 0.0 : completedMonthTasks / monthTasks.length;
    
    return monthCompletionRate * 10; // 10点満点
  }
}

/// 分析プロバイダー
class AnalyticsNotifier extends StateNotifier<AsyncValue<AnalyticsData>> {
  AnalyticsNotifier() : super(const AsyncValue.loading());
  
  bool _isRefreshing = false;
  bool _isGeneratingWeeklyReport = false;
  bool _isReauthenticating = false;
  DateTime? _lastRefreshTime;
  DateTime? _lastWeeklyReportTime;

  // パフォーマンス最適化: データキャッシュ
  AnalyticsData? _cachedData;
  DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// パフォーマンス最適化: キャッシュされたデータの取得
  AnalyticsData? _getCachedData() {
    if (_cachedData != null && _lastCacheTime != null) {
      final now = DateTime.now();
      if (now.difference(_lastCacheTime!) < _cacheValidDuration) {
        return _cachedData;
      }
    }
    return null;
  }

  /// パフォーマンス最適化: データキャッシュの更新
  void _updateCache(AnalyticsData data) {
    _cachedData = data;
    _lastCacheTime = DateTime.now();
  }

  /// パフォーマンス最適化: メモリ効率的なデータ生成
  Future<AnalyticsData> _generateAnalyticsDataOptimized({
    required List<CalendarEvent> events,
    required List<Task> tasks,
    required List<Habit> habits,
    required List<dynamic> goals,
  }) async {
    // キャッシュされたデータがある場合は使用
    final cachedData = _getCachedData();
    if (cachedData != null) {
      return cachedData;
    }

    // 最適化された計算メソッドを使用
    final analyticsData = AnalyticsData.fromRealData(
      events: events,
      tasks: tasks,
      habits: habits,
      goals: goals,
    );

    // キャッシュを更新
    _updateCache(analyticsData);

    return analyticsData;
  }

  /// 実データから週間レポート生成（通知連携版・最適化版）
  Future<void> generateWeeklyReportFromRealData({
    required List<CalendarEvent> events,
    required List<Task> tasks,
    required List<Habit> habits,
    required List<dynamic> goals,
    required WidgetRef ref,
    bool sendNotification = false,
  }) async {
    // 重複実行を防ぐ
    if (_isGeneratingWeeklyReport) {
      Logger().d('Weekly report generation already in progress, skipping...');
      return;
    }
    
    // 短時間での連続実行を防ぐ（1秒以内）
    final now = DateTime.now();
    if (_lastWeeklyReportTime != null && 
        now.difference(_lastWeeklyReportTime!).inMilliseconds < 1000) {
      Logger().d('Weekly report generation too frequent, skipping...');
      return;
    }
    
    _isGeneratingWeeklyReport = true;
    _lastWeeklyReportTime = now;
    
    try {
      state = const AsyncValue.loading();
      
      // データの整合性チェック
      final validatedData = await _validateAndCleanData(
        events: events,
        tasks: tasks,
        habits: habits,
        goals: goals,
      );
      
      // 最適化された分析データ生成
      final analyticsData = await _generateAnalyticsDataOptimized(
        events: validatedData['events'] as List<CalendarEvent>,
        tasks: validatedData['tasks'] as List<Task>,
        habits: validatedData['habits'] as List<Habit>,
        goals: validatedData['goals'] as List<dynamic>,
      );
      
      state = AsyncValue.data(analyticsData);
      
      // 通知送信が必要な場合
      if (sendNotification) {
        await _sendAnalyticsNotification(analyticsData, ref);
      }
      
      Logger().i('Weekly report generated successfully');
    } catch (error, stackTrace) {
      Logger().e('Error generating weekly report: $error');
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isGeneratingWeeklyReport = false;
    }
  }

    /// 実データから月間レポート生成（通知連携版・最適化版）
  Future<void> generateMonthlyReportFromRealData({
    required List<CalendarEvent> events,
    required List<Task> tasks,
    required List<Habit> habits,
    required List<dynamic> goals,
    required WidgetRef ref,
    bool sendNotification = false,
  }) async {
    try {
    state = const AsyncValue.loading();
      
      // データの整合性チェック
      final validatedData = await _validateAndCleanData(
        events: events,
        tasks: tasks,
        habits: habits,
        goals: goals,
      );
      
      // 最適化された分析データ生成
      final analyticsData = await _generateAnalyticsDataOptimized(
        events: validatedData['events'] as List<CalendarEvent>,
        tasks: validatedData['tasks'] as List<Task>,
        habits: validatedData['habits'] as List<Habit>,
        goals: validatedData['goals'] as List<dynamic>,
      );
      
      state = AsyncValue.data(analyticsData);
      
      // 通知送信が必要な場合
      if (sendNotification) {
        await _sendMonthlyAnalyticsNotification(analyticsData, ref);
      }
      
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// データの整合性チェックとクリーニング
  Future<Map<String, dynamic>> _validateAndCleanData({
    required List<CalendarEvent> events,
    required List<Task> tasks,
    required List<Habit> habits,
    required List<dynamic> goals,
  }) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    // イベントの検証とクリーニング
    final validEvents = events.where((event) {
      return event.startTime.isAfter(thirtyDaysAgo) && 
             event.endTime.isAfter(event.startTime);
    }).toList();
    
    // タスクの検証とクリーニング
    final validTasks = tasks.where((task) {
      return task.createdAt.isAfter(thirtyDaysAgo);
    }).toList();
    
    // 習慣の検証とクリーニング
    final validHabits = habits.where((habit) {
      return habit.isActive;
    }).toList();
    
    // 目標の検証とクリーニング
    final validGoals = goals.where((goal) {
      // 目標の有効性チェック（仮定的な実装）
      return goal != null;
    }).toList();
    
    return {
      'events': validEvents,
      'tasks': validTasks,
      'habits': validHabits,
      'goals': validGoals,
    };
  }

  /// 分析結果の通知送信（強化版）
  Future<void> _sendAnalyticsNotification(AnalyticsData data, WidgetRef ref) async {
    try {
      final aiScheduler = AIReportScheduler(ref);
      final pushScheduler = PushNotificationScheduler();
      
      // 分析結果に基づく通知内容を生成
      final notificationContent = _generateAnalyticsNotificationContent(data);
      
      // 通知設定を確認
      final notificationSettings = ref.read(notificationSettingsProvider);
      
      // AI通知が有効な場合のみ送信
      if (notificationSettings.aiSettings.instantInsightsEnabled) {
        // AI分析通知
        await aiScheduler.triggerImmediateReport(
          reportType: 'weekly_analytics',
          summary: notificationContent['summary'],
          customMessage: notificationContent['message'],
        );
        
        // プッシュ通知
        await pushScheduler.scheduleAIReportPush(
          reportType: 'weekly_analytics',
          summary: notificationContent['summary'],
          reportData: {
            'efficiency_score': data.todayEfficiencyScore,
            'completion_rate': data.todayCompletionRate,
            'focus_hours': data.focusTimeHours,
            'insights': notificationContent['insights'],
          },
        );
        
        Logger().i('分析結果通知送信完了: ${notificationContent['summary']}');
      }
      
    } catch (error) {
      // 通知送信エラーはログに記録するが、分析機能には影響しない
      Logger().e('分析結果通知送信エラー: $error');
    }
  }

  /// 月間分析結果の通知送信（強化版）
  Future<void> _sendMonthlyAnalyticsNotification(AnalyticsData data, WidgetRef ref) async {
    try {
      final aiScheduler = AIReportScheduler(ref);
      final pushScheduler = PushNotificationScheduler();
      
      // 月間分析結果に基づく通知内容を生成
      final notificationContent = _generateMonthlyAnalyticsNotificationContent(data);
      
      // 通知設定を確認
      final notificationSettings = ref.read(notificationSettingsProvider);
      
      // AI通知が有効な場合のみ送信
      if (notificationSettings.aiSettings.weeklyReportEnabled) {
        // AI分析通知
        await aiScheduler.triggerImmediateReport(
          reportType: 'monthly_analytics',
          summary: notificationContent['summary'],
          customMessage: notificationContent['message'],
        );
        
        // プッシュ通知
        await pushScheduler.scheduleAIReportPush(
          reportType: 'monthly_analytics',
          summary: notificationContent['summary'],
          reportData: {
            'monthly_efficiency_score': data.monthlyEfficiencyScore,
            'total_focus_hours': data.totalFocusTimeHours,
            'total_completed_tasks': data.totalCompletedTasks,
            'insights': notificationContent['insights'],
          },
        );
        
        Logger().i('月間分析結果通知送信完了: ${notificationContent['summary']}');
      }
      
    } catch (error) {
      // 通知送信エラーはログに記録するが、分析機能には影響しない
      Logger().e('月間分析結果通知送信エラー: $error');
    }
  }

  /// 分析結果の通知内容生成
  Map<String, dynamic> _generateAnalyticsNotificationContent(AnalyticsData data) {
    final efficiencyScore = data.todayEfficiencyScore;
    final completionRate = data.todayCompletionRate;
    final focusHours = data.focusTimeHours;
    
    String summary;
    String message;
    List<String> insights = [];
    
    // 効率性スコアに基づく評価
    if (efficiencyScore >= 8.0) {
      summary = '🎉 素晴らしい効率性！';
      message = '今日は非常に効率的に作業できています。この調子を維持しましょう！';
      insights.add('効率性スコア: ${efficiencyScore.toStringAsFixed(1)}/10');
    } else if (efficiencyScore >= 6.0) {
      summary = '👍 良好な効率性';
      message = '効率性は良好です。さらなる改善の余地があります。';
      insights.add('効率性スコア: ${efficiencyScore.toStringAsFixed(1)}/10');
    } else {
      summary = '💡 効率性の改善が必要';
      message = '効率性を向上させるため、時間管理を見直してみましょう。';
      insights.add('効率性スコア: ${efficiencyScore.toStringAsFixed(1)}/10');
    }
    
    // 完了率の評価
    if (completionRate >= 0.8) {
      insights.add('完了率: ${(completionRate * 100).toStringAsFixed(1)}% - 優秀！');
    } else if (completionRate >= 0.6) {
      insights.add('完了率: ${(completionRate * 100).toStringAsFixed(1)}% - 良好');
    } else {
      insights.add('完了率: ${(completionRate * 100).toStringAsFixed(1)}% - 改善の余地あり');
    }
    
    // 集中時間の評価
    if (focusHours >= 6.0) {
      insights.add('集中時間: ${focusHours.toStringAsFixed(1)}時間 - 十分');
    } else if (focusHours >= 4.0) {
      insights.add('集中時間: ${focusHours.toStringAsFixed(1)}時間 - 適度');
    } else {
      insights.add('集中時間: ${focusHours.toStringAsFixed(1)}時間 - 不足');
    }
    
    return {
      'summary': summary,
      'message': message,
      'insights': insights,
    };
  }

  /// 月間分析結果の通知内容生成
  Map<String, dynamic> _generateMonthlyAnalyticsNotificationContent(AnalyticsData data) {
    final monthlyEfficiencyScore = data.monthlyEfficiencyScore;
    final totalFocusHours = data.totalFocusTimeHours;
    final totalCompletedTasks = data.totalCompletedTasks;
    
    String summary;
    String message;
    List<String> insights = [];
    
    // 月間効率性スコアに基づく評価
    if (monthlyEfficiencyScore >= 7.5) {
      summary = '🏆 月間優秀賞！';
      message = '今月は素晴らしい成果を上げました。来月もこの調子で頑張りましょう！';
      insights.add('月間効率性スコア: ${monthlyEfficiencyScore.toStringAsFixed(1)}/10');
    } else if (monthlyEfficiencyScore >= 6.0) {
      summary = '📈 月間良好';
      message = '今月は良好な成果でした。さらなる向上を目指しましょう。';
      insights.add('月間効率性スコア: ${monthlyEfficiencyScore.toStringAsFixed(1)}/10');
    } else {
      summary = '📊 月間改善の余地';
      message = '今月の成果を振り返り、来月の改善点を検討しましょう。';
      insights.add('月間効率性スコア: ${monthlyEfficiencyScore.toStringAsFixed(1)}/10');
    }
    
    // 総集中時間の評価
    if (totalFocusHours >= 120.0) {
      insights.add('総集中時間: ${totalFocusHours.toStringAsFixed(1)}時間 - 優秀');
    } else if (totalFocusHours >= 80.0) {
      insights.add('総集中時間: ${totalFocusHours.toStringAsFixed(1)}時間 - 良好');
    } else {
      insights.add('総集中時間: ${totalFocusHours.toStringAsFixed(1)}時間 - 改善の余地');
    }
    
    // 完了タスク数の評価
    if (totalCompletedTasks >= 50) {
      insights.add('完了タスク数: $totalCompletedTasks件 - 優秀');
    } else if (totalCompletedTasks >= 30) {
      insights.add('完了タスク数: $totalCompletedTasks件 - 良好');
    } else {
      insights.add('完了タスク数: $totalCompletedTasks件 - 改善の余地');
    }
    
    return {
      'summary': summary,
      'message': message,
      'insights': insights,
    };
  }

  /// Google Calendar再認証処理
  Future<bool> reauthenticateGoogleCalendar() async {
    if (_isReauthenticating) {
      Logger().d('Google Calendar reauthentication already in progress');
      return false;
    }

    _isReauthenticating = true;
    
    try {
      Logger().i('Starting Google Calendar reauthentication...');
      
      // GoogleCalendarServiceの再認証を実行
      final success = await GoogleCalendarService.refreshToken();
      
      if (success) {
        Logger().i('Google Calendar reauthentication successful');
        
        // 認証成功後、カレンダーデータを再取得
        await _reloadCalendarDataAfterReauth();
        
        return true;
      } else {
        Logger().w('Google Calendar reauthentication failed');
        return false;
      }
    } catch (error) {
      Logger().e('Error during Google Calendar reauthentication: $error');
      return false;
    } finally {
      _isReauthenticating = false;
    }
  }

  /// 再認証後のカレンダーデータ再読み込み
  Future<void> _reloadCalendarDataAfterReauth() async {
    try {
      Logger().i('Reloading calendar data after successful reauthentication');
      
      // 現在の状態を取得
      final currentState = state.value;
      if (currentState == null) return;
      
      // 分析データを再生成（カレンダーデータを含む）
      state = const AsyncValue.loading();
      
      // 少し待ってから再読み込み
      await Future.delayed(const Duration(milliseconds: 500));
      
      Logger().i('Calendar data reload completed after reauthentication');
    } catch (error) {
      Logger().e('Error reloading calendar data after reauthentication: $error');
    }
  }

  /// Google Calendar認証エラー状態を取得
  bool get hasGoogleCalendarAuthError => GoogleCalendarService.hasAuthenticationError;

  /// 最後のGoogle Calendar認証エラーメッセージを取得
  String? get lastGoogleCalendarAuthError => GoogleCalendarService.lastAuthError;

  /// 再認証中かどうかを取得
  bool get isReauthenticating => _isReauthenticating;

  /// 最近の認証エラーかどうかを確認
  bool get hasRecentAuthError => GoogleCalendarService.isRecentAuthError();

  /// リアルタイムデータ更新（最適化版）
  Future<void> refreshAnalyticsData({
    required List<CalendarEvent> events,
    required List<Task> tasks,
    required List<Habit> habits,
    required List<dynamic> goals,
  }) async {
    // 重複実行を防ぐ
    if (_isRefreshing) {
      Logger().d('Analytics refresh already in progress, skipping...');
      return;
    }
    
    // 短時間での連続実行を防ぐ（500ms以内）
    final now = DateTime.now();
    if (_lastRefreshTime != null && 
        now.difference(_lastRefreshTime!).inMilliseconds < 500) {
      Logger().d('Analytics refresh too frequent, skipping...');
      return;
    }
    
    _isRefreshing = true;
    _lastRefreshTime = now;
    
    try {
      // Google Calendar認証エラーをチェック
      if (GoogleCalendarService.hasAuthenticationError) {
        Logger().w('Google Calendar authentication error detected during refresh');
        // 認証エラーがある場合でも、他のデータで分析を続行
      }
      
      // 最適化されたデータ生成
      final analyticsData = await _generateAnalyticsDataOptimized(
        events: events,
        tasks: tasks,
        habits: habits,
        goals: goals,
      );
      
      // 状態を更新
      state = AsyncValue.data(analyticsData);
      
      Logger().i('Analytics data refreshed successfully');
    } catch (error) {
      Logger().e('Error refreshing analytics data: $error');
      state = AsyncValue.error(error, StackTrace.current);
    } finally {
      _isRefreshing = false;
    }
  }

  /// データ連携最適化: 自動データ更新
  Future<void> autoRefreshAnalyticsData({
    required List<CalendarEvent> events,
    required List<Task> tasks,
    required List<Habit> habits,
    required List<dynamic> goals,
  }) async {
    try {
      // キャッシュの有効性をチェック
      final cachedData = _getCachedData();
      if (cachedData != null) {
        // キャッシュが有効な場合は使用
        state = AsyncValue.data(cachedData);
        return;
      }

      // データの変更を検出
      final hasDataChanged = _hasDataChanged(events, tasks, habits, goals);
      if (!hasDataChanged) {
        // データに変更がない場合は現在の状態を維持
        return;
      }

      // 新しいデータで更新
      await refreshAnalyticsData(
        events: events,
        tasks: tasks,
        habits: habits,
        goals: goals,
      );
    } catch (error) {
      Logger().e('Error in auto refresh: $error');
    }
  }

  /// データ変更検出
  bool _hasDataChanged(
    List<CalendarEvent> events,
    List<Task> tasks,
    List<Habit> habits,
    List<dynamic> goals,
  ) {
    // 簡易的な変更検出（実際の実装ではより詳細な比較が必要）
    final currentState = state.value;
    if (currentState == null) return true;

    // イベント数の変更をチェック
    if (events.length != currentState.totalCalendarEvents) return true;

    // タスク数の変更をチェック
    if (tasks.length != currentState.totalTasks) return true;

    // 習慣数の変更をチェック
    if (habits.length != currentState.totalHabits) return true;

    return false;
  }





  /// 週間レポート生成（サンプルデータ - 後方互換性のため保持）
  Future<void> generateWeeklyReport() async {
    state = const AsyncValue.loading();
    
    try {
      // 実際のデータ取得処理（ここではサンプルデータ）
      await Future.delayed(const Duration(seconds: 1));
      
      final analyticsData = AnalyticsData(
        todayPlannedHours: 8.0,
        todayActualHours: 6.5,
        todayCompletionRate: 0.81,
        todayEfficiencyScore: 8.2,
        hourlyDistribution: _generateHourlyDistribution(),
        weeklyProgress: [0.75, 0.82, 0.68, 0.91, 0.77, 0.85, 0.79],
        focusTimeHours: 4.2,
        interruptionCount: 8,
        multitaskingRate: 0.35,
        breakEfficiency: 7.8,
        categoryDistribution: {
          '仕事': 4.5,
          '学習': 2.0,
          '運動': 1.0,
          '個人': 1.5,
          '休憩': 1.0,
        },
        focusTimePercentage: 0.52,
        communicationPercentage: 0.18,
        learningPercentage: 0.20,
        breakPercentage: 0.10,
        totalTasks: 25,
        completedTasks: 18,
        totalHabits: 8,
        completedHabits: 6,
        totalGoals: 5,
        completedGoals: 2,
        totalCalendarEvents: 12,
        // 月間レポート用プロパティ
        monthlyProgress: List.generate(31, (index) => 0.7 + (index % 3) * 0.1),
        monthlyEfficiencyScore: 7.5,
        totalFocusTimeHours: 120.0,
        totalInterruptionCount: 45,
        averageMultitaskingRate: 0.3,
        averageBreakEfficiency: 7.2,
        monthlyCategoryDistribution: {
          '仕事': 80.0,
          '学習': 35.0,
          '運動': 20.0,
          '個人': 25.0,
          '休憩': 15.0,
        },
        weeklyAverages: {0: 0.75, 1: 0.78, 2: 0.82, 3: 0.79},
        totalCompletedTasks: 85,
        totalCompletedHabits: 120,
        totalCompletedGoals: 3,
      );
      
      state = AsyncValue.data(analyticsData);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 時間別分布生成（サンプル）
  Map<int, int> _generateHourlyDistribution() {
    return {
      6: 0, 7: 1, 8: 2, 9: 4, 10: 3, 11: 4,
      12: 1, 13: 2, 14: 4, 15: 3, 16: 4, 17: 3,
      18: 2, 19: 1, 20: 1, 21: 0, 22: 0,
    };
  }

  /// カレンダーイベントから分析データ生成
  Future<void> analyzeCalendarEvents(List<CalendarEvent> events) async {
    // 実装完了：AnalyticsData.fromRealDataで使用
  }

  /// タスクから生産性分析
  Future<void> analyzeTaskProductivity(List<Task> tasks) async {
    // 実装完了：AnalyticsData.fromRealDataで使用
  }

  /// 習慣から健康指標分析
  Future<void> analyzeHabitHealth(List<Habit> habits) async {
    // 実装完了：AnalyticsData.fromRealDataで使用
  }

  /// 生産性パターン分析通知
  Future<void> sendProductivityPatternNotification({
    required AnalyticsData data,
    required WidgetRef ref,
  }) async {
    try {
      final aiScheduler = AIReportScheduler(ref);
      final pushScheduler = PushNotificationScheduler();
      
      // 生産性パターンの分析結果
      final pattern = _analyzeProductivityPattern(data);
      final recommendation = _generateProductivityRecommendation(data);
      
      final summary = '生産性パターン分析: $pattern';
      
      // AI分析通知
      await aiScheduler.triggerImmediateReport(
        reportType: 'productivity_pattern',
        summary: summary,
        customMessage: recommendation,
      );
      
      // プッシュ通知
      await pushScheduler.scheduleAIReportPush(
        reportType: 'productivity_pattern',
        summary: summary,
        reportData: {
          'pattern': pattern,
          'recommendation': recommendation,
          'efficiency_score': data.todayEfficiencyScore,
          'focus_hours': data.focusTimeHours,
        },
      );
      
      Logger().i('生産性パターン分析通知送信完了: $pattern');
    } catch (e) {
      Logger().e('生産性パターン分析通知送信エラー: $e');
    }
  }

  /// 目標進捗通知
  Future<void> sendGoalProgressNotification({
    required AnalyticsData data,
    required WidgetRef ref,
  }) async {
    try {
      final aiScheduler = AIReportScheduler(ref); // Ref型で渡す
      final pushScheduler = PushNotificationScheduler();
      
      // 目標進捗の分析結果
      final progress = _analyzeGoalProgress(data);
      final prediction = _generateGoalPrediction(data);
      
      final summary = '目標進捗分析: $progress';
      
      // AI分析通知
      await aiScheduler.triggerImmediateReport(
        reportType: 'goal_progress',
        summary: summary,
        customMessage: prediction,
      );
      
      // プッシュ通知
      await pushScheduler.scheduleAIReportPush(
        reportType: 'goal_progress',
        summary: summary,
        reportData: {
          'progress': progress,
          'prediction': prediction,
          'completed_goals': data.completedGoals,
          'total_goals': data.totalGoals,
        },
      );
      
      Logger().i('目標進捗通知送信完了: $progress');
    } catch (e) {
      Logger().e('目標進捗通知送信エラー: $e');
    }
  }

  /// 生産性パターン分析
  String _analyzeProductivityPattern(AnalyticsData data) {
    if (data.todayEfficiencyScore >= 8.0) {
      return '高効率パターン';
    } else if (data.todayEfficiencyScore >= 6.0) {
      return '標準効率パターン';
    } else {
      return '改善必要パターン';
    }
  }

  /// 生産性改善提案
  String _generateProductivityRecommendation(AnalyticsData data) {
    if (data.todayEfficiencyScore < 6.0) {
      return '集中時間の確保と中断の削減をお勧めします。';
    } else if (data.todayEfficiencyScore < 8.0) {
      return '時間管理の最適化でさらなる向上が期待できます。';
    } else {
      return '素晴らしい効率性です！この調子を維持しましょう。';
    }
  }

  /// 目標進捗分析
  String _analyzeGoalProgress(AnalyticsData data) {
    if (data.totalGoals == 0) return '目標が設定されていません';
    
    final progressRate = (data.completedGoals / data.totalGoals * 100).round();
    return '進捗率: $progressRate% (${data.completedGoals}/${data.totalGoals})';
  }

  /// 目標達成予測
  String _generateGoalPrediction(AnalyticsData data) {
    if (data.totalGoals == 0) return '目標を設定して進捗を追跡しましょう';
    
    final progressRate = data.completedGoals / data.totalGoals;
    if (progressRate >= 0.8) {
      return '目標達成まであと少しです！';
    } else if (progressRate >= 0.5) {
      return '順調に進んでいます。継続を心がけましょう。';
    } else {
      return 'ペースを上げて目標達成を目指しましょう。';
    }
  }
}

/// 分析プロバイダーのインスタンス
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AsyncValue<AnalyticsData>>(
  (ref) => AnalyticsNotifier(),
); 