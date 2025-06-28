import 'package:dartz/dartz.dart' as dartz;
import '../entities/habit.dart';

/// 習慣リポジトリのインターフェース
abstract class HabitRepository {
  /// 習慣を作成
  Future<dartz.Either<String, Habit>> createHabit(Habit habit);
  
  /// 習慣を取得
  Future<dartz.Either<String, Habit?>> getHabit(String habitId);
  
  /// ユーザーの全習慣を取得
  Future<dartz.Either<String, List<Habit>>> getAllHabits(String userId);
  
  /// 今日の習慣を取得
  Future<dartz.Either<String, List<Habit>>> getTodayHabits(String userId);
  
  /// 指定日の習慣を取得
  Future<dartz.Either<String, List<Habit>>> getHabitsByDate(String userId, DateTime date);
  
  /// アクティブな習慣を取得
  Future<dartz.Either<String, List<Habit>>> getActiveHabits(String userId);
  
  /// 終了した習慣を取得
  Future<dartz.Either<String, List<Habit>>> getFinishedHabits(String userId);
  
  /// 一時停止中の習慣を取得
  Future<dartz.Either<String, List<Habit>>> getPausedHabits(String userId);
  
  /// カテゴリ別の習慣を取得
  Future<dartz.Either<String, List<Habit>>> getHabitsByCategory(String userId, String category);
  
  /// 目標関連の習慣を取得
  Future<dartz.Either<String, List<Habit>>> getHabitsByGoal(String userId, String goalId);
  
  /// タグ別の習慣を取得
  Future<dartz.Either<String, List<Habit>>> getHabitsByTag(String userId, String tag);
  
  /// 習慣を更新
  Future<dartz.Either<String, Habit>> updateHabit(Habit habit);
  
  /// 習慣を削除
  Future<dartz.Either<String, void>> deleteHabit(String habitId);
  
  /// 習慣を完了
  Future<dartz.Either<String, Habit>> completeHabit(String habitId);
  
  /// 日々の取り組みを記録
  Future<dartz.Either<String, Habit>> recordDailyCompletion(String habitId);
  
  /// 習慣を一時停止
  Future<dartz.Either<String, Habit>> pauseHabit(String habitId);
  
  /// 習慣を再開
  Future<dartz.Either<String, Habit>> resumeHabit(String habitId);
  
  /// 習慣の統計情報を取得
  Future<dartz.Either<String, HabitStatistics>> getHabitStatistics(String userId);
  
  /// 習慣のストリーク情報を取得
  Future<dartz.Either<String, List<HabitStreakInfo>>> getHabitStreaks(String userId);
}

/// 習慣の統計情報
class HabitStatistics {
  final int totalHabits;
  final int activeHabits;
  final int completedHabits;
  final int pausedHabits;
  final double averageCompletionRate;
  final int totalCompletions;
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> categoryDistribution;
  final Map<String, double> weeklyProgress;

  const HabitStatistics({
    required this.totalHabits,
    required this.activeHabits,
    required this.completedHabits,
    required this.pausedHabits,
    required this.averageCompletionRate,
    required this.totalCompletions,
    required this.currentStreak,
    required this.longestStreak,
    required this.categoryDistribution,
    required this.weeklyProgress,
  });
}

/// 習慣のストリーク情報
class HabitStreakInfo {
  final String habitId;
  final String habitTitle;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastCompletionDate;
  final bool isCompletedToday;

  const HabitStreakInfo({
    required this.habitId,
    required this.habitTitle,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastCompletionDate,
    required this.isCompletedToday,
  });
} 