import '../entities/goal.dart';
import '../repositories/goal_repository.dart';

/// 目標作成ユースケース
class CreateGoalUseCase {
  final GoalRepository repository;

  CreateGoalUseCase(this.repository);

  Future<Goal> call(Goal goal) async {
    // バリデーション
    if (goal.title.trim().isEmpty) {
      throw ArgumentError('目標のタイトルは必須です');
    }
    if (goal.progress < 0.0 || goal.progress > 1.0) {
      throw ArgumentError('進捗は0.0から1.0の間である必要があります');
    }
    if (goal.targetDate != null && goal.startDate.isAfter(goal.targetDate!)) {
      throw ArgumentError('開始日は目標日より前である必要があります');
    }

    return await repository.createGoal(goal);
  }
}

/// 目標取得ユースケース
class GetGoalUseCase {
  final GoalRepository repository;

  GetGoalUseCase(this.repository);

  Future<Goal?> call(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('目標IDは必須です');
    }
    return await repository.getGoal(id);
  }
}

/// すべての目標取得ユースケース
class GetAllGoalsUseCase {
  final GoalRepository repository;

  GetAllGoalsUseCase(this.repository);

  Future<List<Goal>> call() async {
    return await repository.getAllGoals();
  }
}

/// アクティブな目標取得ユースケース
class GetActiveGoalsUseCase {
  final GoalRepository repository;

  GetActiveGoalsUseCase(this.repository);

  Future<List<Goal>> call() async {
    return await repository.getActiveGoals();
  }
}

/// カテゴリ別目標取得ユースケース
class GetGoalsByCategoryUseCase {
  final GoalRepository repository;

  GetGoalsByCategoryUseCase(this.repository);

  Future<List<Goal>> call(GoalCategory category) async {
    return await repository.getGoalsByCategory(category);
  }
}

/// ステータス別目標取得ユースケース
class GetGoalsByStatusUseCase {
  final GoalRepository repository;

  GetGoalsByStatusUseCase(this.repository);

  Future<List<Goal>> call(GoalStatus status) async {
    return await repository.getGoalsByStatus(status);
  }
}

/// 優先度別目標取得ユースケース
class GetGoalsByPriorityUseCase {
  final GoalRepository repository;

  GetGoalsByPriorityUseCase(this.repository);

  Future<List<Goal>> call(GoalPriority priority) async {
    return await repository.getGoalsByPriority(priority);
  }
}

/// 期限切れ目標取得ユースケース
class GetOverdueGoalsUseCase {
  final GoalRepository repository;

  GetOverdueGoalsUseCase(this.repository);

  Future<List<Goal>> call() async {
    return await repository.getOverdueGoals();
  }
}

/// 期限が近い目標取得ユースケース
class GetGoalsWithDeadlineWithinUseCase {
  final GoalRepository repository;

  GetGoalsWithDeadlineWithinUseCase(this.repository);

  Future<List<Goal>> call(int days) async {
    if (days < 0) {
      throw ArgumentError('日数は0以上である必要があります');
    }
    return await repository.getGoalsWithDeadlineWithin(days);
  }
}

/// 目標更新ユースケース
class UpdateGoalUseCase {
  final GoalRepository repository;

  UpdateGoalUseCase(this.repository);

  Future<Goal> call(Goal goal) async {
    // バリデーション
    if (goal.title.trim().isEmpty) {
      throw ArgumentError('目標のタイトルは必須です');
    }
    if (goal.progress < 0.0 || goal.progress > 1.0) {
      throw ArgumentError('進捗は0.0から1.0の間である必要があります');
    }
    if (goal.targetDate != null && goal.startDate.isAfter(goal.targetDate!)) {
      throw ArgumentError('開始日は目標日より前である必要があります');
    }

    return await repository.updateGoal(goal);
  }
}

/// 目標削除ユースケース
class DeleteGoalUseCase {
  final GoalRepository repository;

  DeleteGoalUseCase(this.repository);

  Future<void> call(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('目標IDは必須です');
    }
    await repository.deleteGoal(id);
  }
}

/// 目標進捗更新ユースケース
class UpdateGoalProgressUseCase {
  final GoalRepository repository;

  UpdateGoalProgressUseCase(this.repository);

  Future<Goal> call(String goalId, double progress) async {
    if (goalId.isEmpty) {
      throw ArgumentError('目標IDは必須です');
    }
    if (progress < 0.0 || progress > 1.0) {
      throw ArgumentError('進捗は0.0から1.0の間である必要があります');
    }

    return await repository.updateGoalProgress(goalId, progress);
  }
}

/// マイルストーン追加ユースケース
class AddMilestoneUseCase {
  final GoalRepository repository;

  AddMilestoneUseCase(this.repository);

  Future<Goal> call(String goalId, Milestone milestone) async {
    if (goalId.isEmpty) {
      throw ArgumentError('目標IDは必須です');
    }
    if (milestone.title.trim().isEmpty) {
      throw ArgumentError('マイルストーンのタイトルは必須です');
    }
    if (milestone.progress < 0.0 || milestone.progress > 1.0) {
      throw ArgumentError('マイルストーンの進捗は0.0から1.0の間である必要があります');
    }

    return await repository.addMilestone(goalId, milestone);
  }
}

/// マイルストーン更新ユースケース
class UpdateMilestoneUseCase {
  final GoalRepository repository;

  UpdateMilestoneUseCase(this.repository);

  Future<Goal> call(String goalId, String milestoneId, Milestone milestone) async {
    if (goalId.isEmpty) {
      throw ArgumentError('目標IDは必須です');
    }
    if (milestoneId.isEmpty) {
      throw ArgumentError('マイルストーンIDは必須です');
    }
    if (milestone.title.trim().isEmpty) {
      throw ArgumentError('マイルストーンのタイトルは必須です');
    }
    if (milestone.progress < 0.0 || milestone.progress > 1.0) {
      throw ArgumentError('マイルストーンの進捗は0.0から1.0の間である必要があります');
    }

    return await repository.updateMilestone(goalId, milestoneId, milestone);
  }
}

/// マイルストーン削除ユースケース
class RemoveMilestoneUseCase {
  final GoalRepository repository;

  RemoveMilestoneUseCase(this.repository);

  Future<Goal> call(String goalId, String milestoneId) async {
    if (goalId.isEmpty) {
      throw ArgumentError('目標IDは必須です');
    }
    if (milestoneId.isEmpty) {
      throw ArgumentError('マイルストーンIDは必須です');
    }

    return await repository.removeMilestone(goalId, milestoneId);
  }
}

/// 目標完了ユースケース
class MarkGoalAsCompletedUseCase {
  final GoalRepository repository;

  MarkGoalAsCompletedUseCase(this.repository);

  Future<Goal> call(String goalId) async {
    if (goalId.isEmpty) {
      throw ArgumentError('目標IDは必須です');
    }
    return await repository.markGoalAsCompleted(goalId);
  }
}

/// 目標一時停止ユースケース
class PauseGoalUseCase {
  final GoalRepository repository;

  PauseGoalUseCase(this.repository);

  Future<Goal> call(String goalId) async {
    if (goalId.isEmpty) {
      throw ArgumentError('目標IDは必須です');
    }
    return await repository.pauseGoal(goalId);
  }
}

/// 目標再開ユースケース
class ResumeGoalUseCase {
  final GoalRepository repository;

  ResumeGoalUseCase(this.repository);

  Future<Goal> call(String goalId) async {
    if (goalId.isEmpty) {
      throw ArgumentError('目標IDは必須です');
    }
    return await repository.resumeGoal(goalId);
  }
}

/// 目標キャンセルユースケース
class CancelGoalUseCase {
  final GoalRepository repository;

  CancelGoalUseCase(this.repository);

  Future<Goal> call(String goalId) async {
    if (goalId.isEmpty) {
      throw ArgumentError('目標IDは必須です');
    }
    return await repository.cancelGoal(goalId);
  }
}

/// 目標統計取得ユースケース
class GetGoalStatisticsUseCase {
  final GoalRepository repository;

  GetGoalStatisticsUseCase(this.repository);

  Future<GoalStatistics> call() async {
    return await repository.getGoalStatistics();
  }
}

/// 目標進捗履歴取得ユースケース
class GetGoalProgressHistoryUseCase {
  final GoalRepository repository;

  GetGoalProgressHistoryUseCase(this.repository);

  Future<List<GoalProgress>> call(String goalId) async {
    if (goalId.isEmpty) {
      throw ArgumentError('目標IDは必須です');
    }
    return await repository.getGoalProgressHistory(goalId);
  }
}

/// 目標検索ユースケース
class SearchGoalsUseCase {
  final GoalRepository repository;

  SearchGoalsUseCase(this.repository);

  Future<List<Goal>> call(String query) async {
    if (query.trim().isEmpty) {
      return await repository.getAllGoals();
    }
    return await repository.searchGoals(query.trim());
  }
}

/// 目標並び替えユースケース
class SortGoalsUseCase {
  final GoalRepository repository;

  SortGoalsUseCase(this.repository);

  Future<List<Goal>> call(GoalSortOption sortOption) async {
    return await repository.sortGoals(sortOption);
  }
} 