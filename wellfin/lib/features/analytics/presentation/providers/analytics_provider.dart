import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../../../calendar/domain/entities/calendar_event.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../habits/domain/entities/habit.dart';

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
    );
  }
}

/// 分析プロバイダー
class AnalyticsNotifier extends StateNotifier<AsyncValue<AnalyticsData>> {
  AnalyticsNotifier() : super(AsyncValue.data(AnalyticsData.empty()));

  /// 週間レポート生成
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
    // 実装予定：イベントデータから時間使用状況を分析
  }

  /// タスクから生産性分析
  Future<void> analyzeTaskProductivity(List<Task> tasks) async {
    // 実装予定：タスク完了データから生産性指標を計算
  }

  /// 習慣から健康指標分析
  Future<void> analyzeHabitHealth(List<Habit> habits) async {
    // 実装予定：習慣データから健康・ライフスタイル指標を分析
  }
}

/// 分析プロバイダーのインスタンス
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AsyncValue<AnalyticsData>>(
  (ref) => AnalyticsNotifier(),
); 