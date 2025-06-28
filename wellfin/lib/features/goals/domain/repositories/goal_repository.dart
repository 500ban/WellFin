import '../entities/goal.dart';

/// 目標管理のリポジトリインターフェース
/// データアクセス層の抽象化
abstract class GoalRepository {
  /// 目標を作成
  Future<Goal> createGoal(Goal goal);

  /// 目標を取得
  Future<Goal?> getGoal(String id);

  /// すべての目標を取得
  Future<List<Goal>> getAllGoals();

  /// アクティブな目標を取得
  Future<List<Goal>> getActiveGoals();

  /// カテゴリ別の目標を取得
  Future<List<Goal>> getGoalsByCategory(GoalCategory category);

  /// ステータス別の目標を取得
  Future<List<Goal>> getGoalsByStatus(GoalStatus status);

  /// 優先度別の目標を取得
  Future<List<Goal>> getGoalsByPriority(GoalPriority priority);

  /// 期限切れの目標を取得
  Future<List<Goal>> getOverdueGoals();

  /// 期限が近い目標を取得（指定日数以内）
  Future<List<Goal>> getGoalsWithDeadlineWithin(int days);

  /// 目標を更新
  Future<Goal> updateGoal(Goal goal);

  /// 目標を削除
  Future<void> deleteGoal(String id);

  /// 目標の進捗を更新
  Future<Goal> updateGoalProgress(String goalId, double progress);

  /// マイルストーンを追加
  Future<Goal> addMilestone(String goalId, Milestone milestone);

  /// マイルストーンを更新
  Future<Goal> updateMilestone(String goalId, String milestoneId, Milestone milestone);

  /// マイルストーンを削除
  Future<Goal> removeMilestone(String goalId, String milestoneId);

  /// 目標を完了状態に変更
  Future<Goal> markGoalAsCompleted(String goalId);

  /// 目標を一時停止
  Future<Goal> pauseGoal(String goalId);

  /// 目標を再開
  Future<Goal> resumeGoal(String goalId);

  /// 目標をキャンセル
  Future<Goal> cancelGoal(String goalId);

  /// 目標の統計情報を取得
  Future<GoalStatistics> getGoalStatistics();

  /// 目標の進捗履歴を取得
  Future<List<GoalProgress>> getGoalProgressHistory(String goalId);

  /// 目標を検索（タイトル、説明、タグで検索）
  Future<List<Goal>> searchGoals(String query);

  /// 目標を並び替え（重要度、期限、作成日、進捗）
  Future<List<Goal>> sortGoals(GoalSortOption sortOption);
}

/// 目標の統計情報
class GoalStatistics {
  final int totalGoals;
  final int activeGoals;
  final int completedGoals;
  final int pausedGoals;
  final int cancelledGoals;
  final int overdueGoals;
  final double averageProgress;
  final Map<GoalCategory, int> goalsByCategory;
  final Map<GoalPriority, int> goalsByPriority;
  final int totalMilestones;
  final int completedMilestones;

  GoalStatistics({
    required this.totalGoals,
    required this.activeGoals,
    required this.completedGoals,
    required this.pausedGoals,
    required this.cancelledGoals,
    required this.overdueGoals,
    required this.averageProgress,
    required this.goalsByCategory,
    required this.goalsByPriority,
    required this.totalMilestones,
    required this.completedMilestones,
  });

  /// 完了率
  double get completionRate {
    if (totalGoals == 0) return 0.0;
    return completedGoals / totalGoals;
  }

  /// マイルストーン完了率
  double get milestoneCompletionRate {
    if (totalMilestones == 0) return 0.0;
    return completedMilestones / totalMilestones;
  }

  /// 安全な平均進捗（NaNや無限大を防ぐ）
  double get safeAverageProgress {
    if (averageProgress.isNaN || averageProgress.isInfinite) {
      return 0.0;
    }
    return averageProgress.clamp(0.0, 1.0);
  }

  /// 安全な完了率（NaNや無限大を防ぐ）
  double get safeCompletionRate {
    final rate = completionRate;
    if (rate.isNaN || rate.isInfinite) {
      return 0.0;
    }
    return rate.clamp(0.0, 1.0);
  }

  /// 安全なマイルストーン完了率（NaNや無限大を防ぐ）
  double get safeMilestoneCompletionRate {
    final rate = milestoneCompletionRate;
    if (rate.isNaN || rate.isInfinite) {
      return 0.0;
    }
    return rate.clamp(0.0, 1.0);
  }
} 