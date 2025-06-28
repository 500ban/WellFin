import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_goal_repository.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/usecases/goal_usecases.dart';

/// 目標リポジトリプロバイダー
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return FirestoreGoalRepository();
});

/// 目標ユースケースプロバイダー
final createGoalUseCaseProvider = Provider<CreateGoalUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return CreateGoalUseCase(repository);
});

final getGoalUseCaseProvider = Provider<GetGoalUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GetGoalUseCase(repository);
});

final getAllGoalsUseCaseProvider = Provider<GetAllGoalsUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GetAllGoalsUseCase(repository);
});

final getActiveGoalsUseCaseProvider = Provider<GetActiveGoalsUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GetActiveGoalsUseCase(repository);
});

final getGoalsByCategoryUseCaseProvider = Provider<GetGoalsByCategoryUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GetGoalsByCategoryUseCase(repository);
});

final getGoalsByStatusUseCaseProvider = Provider<GetGoalsByStatusUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GetGoalsByStatusUseCase(repository);
});

final getGoalsByPriorityUseCaseProvider = Provider<GetGoalsByPriorityUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GetGoalsByPriorityUseCase(repository);
});

final getOverdueGoalsUseCaseProvider = Provider<GetOverdueGoalsUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GetOverdueGoalsUseCase(repository);
});

final getGoalsWithDeadlineWithinUseCaseProvider = Provider<GetGoalsWithDeadlineWithinUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GetGoalsWithDeadlineWithinUseCase(repository);
});

final updateGoalUseCaseProvider = Provider<UpdateGoalUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return UpdateGoalUseCase(repository);
});

final deleteGoalUseCaseProvider = Provider<DeleteGoalUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return DeleteGoalUseCase(repository);
});

final updateGoalProgressUseCaseProvider = Provider<UpdateGoalProgressUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return UpdateGoalProgressUseCase(repository);
});

final addMilestoneUseCaseProvider = Provider<AddMilestoneUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return AddMilestoneUseCase(repository);
});

final updateMilestoneUseCaseProvider = Provider<UpdateMilestoneUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return UpdateMilestoneUseCase(repository);
});

final removeMilestoneUseCaseProvider = Provider<RemoveMilestoneUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return RemoveMilestoneUseCase(repository);
});

final markGoalAsCompletedUseCaseProvider = Provider<MarkGoalAsCompletedUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return MarkGoalAsCompletedUseCase(repository);
});

final pauseGoalUseCaseProvider = Provider<PauseGoalUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return PauseGoalUseCase(repository);
});

final resumeGoalUseCaseProvider = Provider<ResumeGoalUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return ResumeGoalUseCase(repository);
});

final cancelGoalUseCaseProvider = Provider<CancelGoalUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return CancelGoalUseCase(repository);
});

final getGoalStatisticsUseCaseProvider = Provider<GetGoalStatisticsUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GetGoalStatisticsUseCase(repository);
});

final getGoalProgressHistoryUseCaseProvider = Provider<GetGoalProgressHistoryUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GetGoalProgressHistoryUseCase(repository);
});

final searchGoalsUseCaseProvider = Provider<SearchGoalsUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return SearchGoalsUseCase(repository);
});

final sortGoalsUseCaseProvider = Provider<SortGoalsUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return SortGoalsUseCase(repository);
});

/// 目標状態管理プロバイダー
class GoalNotifier extends StateNotifier<AsyncValue<List<Goal>>> {
  final GetAllGoalsUseCase _getAllGoalsUseCase;
  final CreateGoalUseCase _createGoalUseCase;
  final UpdateGoalUseCase _updateGoalUseCase;
  final DeleteGoalUseCase _deleteGoalUseCase;
  final UpdateGoalProgressUseCase _updateGoalProgressUseCase;
  final AddMilestoneUseCase _addMilestoneUseCase;
  final UpdateMilestoneUseCase _updateMilestoneUseCase;
  final RemoveMilestoneUseCase _removeMilestoneUseCase;
  final MarkGoalAsCompletedUseCase _markGoalAsCompletedUseCase;
  final PauseGoalUseCase _pauseGoalUseCase;
  final ResumeGoalUseCase _resumeGoalUseCase;
  final CancelGoalUseCase _cancelGoalUseCase;

  GoalNotifier({
    required GetAllGoalsUseCase getAllGoalsUseCase,
    required CreateGoalUseCase createGoalUseCase,
    required UpdateGoalUseCase updateGoalUseCase,
    required DeleteGoalUseCase deleteGoalUseCase,
    required UpdateGoalProgressUseCase updateGoalProgressUseCase,
    required AddMilestoneUseCase addMilestoneUseCase,
    required UpdateMilestoneUseCase updateMilestoneUseCase,
    required RemoveMilestoneUseCase removeMilestoneUseCase,
    required MarkGoalAsCompletedUseCase markGoalAsCompletedUseCase,
    required PauseGoalUseCase pauseGoalUseCase,
    required ResumeGoalUseCase resumeGoalUseCase,
    required CancelGoalUseCase cancelGoalUseCase,
  }) : _getAllGoalsUseCase = getAllGoalsUseCase,
       _createGoalUseCase = createGoalUseCase,
       _updateGoalUseCase = updateGoalUseCase,
       _deleteGoalUseCase = deleteGoalUseCase,
       _updateGoalProgressUseCase = updateGoalProgressUseCase,
       _addMilestoneUseCase = addMilestoneUseCase,
       _updateMilestoneUseCase = updateMilestoneUseCase,
       _removeMilestoneUseCase = removeMilestoneUseCase,
       _markGoalAsCompletedUseCase = markGoalAsCompletedUseCase,
       _pauseGoalUseCase = pauseGoalUseCase,
       _resumeGoalUseCase = resumeGoalUseCase,
       _cancelGoalUseCase = cancelGoalUseCase,
       super(const AsyncValue.loading());

  /// 目標一覧を取得
  Future<void> loadGoals() async {
    state = const AsyncValue.loading();
    try {
      final goals = await _getAllGoalsUseCase();
      state = AsyncValue.data(goals);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 目標を作成
  Future<void> createGoal(Goal goal) async {
    try {
      final newGoal = await _createGoalUseCase(goal);
      state.whenData((goals) {
        state = AsyncValue.data([newGoal, ...goals]);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 目標を更新
  Future<void> updateGoal(Goal goal) async {
    try {
      final updatedGoal = await _updateGoalUseCase(goal);
      state.whenData((goals) {
        final updatedGoals = goals.map((g) => g.id == goal.id ? updatedGoal : g).toList();
        state = AsyncValue.data(updatedGoals);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 目標を削除
  Future<void> deleteGoal(String goalId) async {
    try {
      await _deleteGoalUseCase(goalId);
      state.whenData((goals) {
        final updatedGoals = goals.where((goal) => goal.id != goalId).toList();
        state = AsyncValue.data(updatedGoals);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 目標の進捗を更新
  Future<void> updateGoalProgress(String goalId, double progress) async {
    try {
      final updatedGoal = await _updateGoalProgressUseCase(goalId, progress);
      
      // 進捗が100%になった場合、自動的に目標を完了状態に変更
      if (progress >= 1.0 && updatedGoal.status != GoalStatus.completed) {
        final completedGoal = await _markGoalAsCompletedUseCase(goalId);
        state.whenData((goals) {
          final updatedGoals = goals.map((g) => g.id == goalId ? completedGoal : g).toList();
          state = AsyncValue.data(updatedGoals);
        });
      } else {
        state.whenData((goals) {
          final updatedGoals = goals.map((g) => g.id == goalId ? updatedGoal : g).toList();
          state = AsyncValue.data(updatedGoals);
        });
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// マイルストーンを追加
  Future<void> addMilestone(String goalId, Milestone milestone) async {
    try {
      final updatedGoal = await _addMilestoneUseCase(goalId, milestone);
      state.whenData((goals) {
        final updatedGoals = goals.map((g) => g.id == goalId ? updatedGoal : g).toList();
        state = AsyncValue.data(updatedGoals);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// マイルストーンを更新
  Future<void> updateMilestone(String goalId, String milestoneId, Milestone milestone) async {
    try {
      final updatedGoal = await _updateMilestoneUseCase(goalId, milestoneId, milestone);
      state.whenData((goals) {
        final updatedGoals = goals.map((g) => g.id == goalId ? updatedGoal : g).toList();
        state = AsyncValue.data(updatedGoals);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// マイルストーンを削除
  Future<void> removeMilestone(String goalId, String milestoneId) async {
    try {
      final updatedGoal = await _removeMilestoneUseCase(goalId, milestoneId);
      state.whenData((goals) {
        final updatedGoals = goals.map((g) => g.id == goalId ? updatedGoal : g).toList();
        state = AsyncValue.data(updatedGoals);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 目標を完了状態に変更
  Future<void> markGoalAsCompleted(String goalId) async {
    try {
      final updatedGoal = await _markGoalAsCompletedUseCase(goalId);
      state.whenData((goals) {
        final updatedGoals = goals.map((g) => g.id == goalId ? updatedGoal : g).toList();
        state = AsyncValue.data(updatedGoals);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 目標を一時停止
  Future<void> pauseGoal(String goalId) async {
    try {
      final updatedGoal = await _pauseGoalUseCase(goalId);
      state.whenData((goals) {
        final updatedGoals = goals.map((g) => g.id == goalId ? updatedGoal : g).toList();
        state = AsyncValue.data(updatedGoals);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 目標を再開
  Future<void> resumeGoal(String goalId) async {
    try {
      final updatedGoal = await _resumeGoalUseCase(goalId);
      state.whenData((goals) {
        final updatedGoals = goals.map((g) => g.id == goalId ? updatedGoal : g).toList();
        state = AsyncValue.data(updatedGoals);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 目標をキャンセル
  Future<void> cancelGoal(String goalId) async {
    try {
      final updatedGoal = await _cancelGoalUseCase(goalId);
      state.whenData((goals) {
        final updatedGoals = goals.map((g) => g.id == goalId ? updatedGoal : g).toList();
        state = AsyncValue.data(updatedGoals);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// 目標状態管理プロバイダー
final goalNotifierProvider = StateNotifierProvider<GoalNotifier, AsyncValue<List<Goal>>>((ref) {
  return GoalNotifier(
    getAllGoalsUseCase: ref.watch(getAllGoalsUseCaseProvider),
    createGoalUseCase: ref.watch(createGoalUseCaseProvider),
    updateGoalUseCase: ref.watch(updateGoalUseCaseProvider),
    deleteGoalUseCase: ref.watch(deleteGoalUseCaseProvider),
    updateGoalProgressUseCase: ref.watch(updateGoalProgressUseCaseProvider),
    addMilestoneUseCase: ref.watch(addMilestoneUseCaseProvider),
    updateMilestoneUseCase: ref.watch(updateMilestoneUseCaseProvider),
    removeMilestoneUseCase: ref.watch(removeMilestoneUseCaseProvider),
    markGoalAsCompletedUseCase: ref.watch(markGoalAsCompletedUseCaseProvider),
    pauseGoalUseCase: ref.watch(pauseGoalUseCaseProvider),
    resumeGoalUseCase: ref.watch(resumeGoalUseCaseProvider),
    cancelGoalUseCase: ref.watch(cancelGoalUseCaseProvider),
  );
});

/// 目標統計プロバイダー（効率的版）
final goalStatisticsEfficientProvider = Provider<AsyncValue<GoalStatistics>>((ref) {
  final goalsAsync = ref.watch(goalNotifierProvider);
  
  return goalsAsync.when(
    data: (goals) {
      try {
        final activeGoals = goals.where((goal) => goal.isInProgress).length;
        final completedGoals = goals.where((goal) => goal.isCompleted).length;
        final pausedGoals = goals.where((goal) => goal.isPaused).length;
        final cancelledGoals = goals.where((goal) => goal.isCancelled).length;
        final overdueGoals = goals.where((goal) => goal.isOverdue).length;
        
        // 平均進捗の計算を安全に行う
        double averageProgress = 0.0;
        if (goals.isNotEmpty) {
          final totalProgress = goals.fold<double>(0.0, (sum, goal) => sum + goal.progress);
          averageProgress = totalProgress / goals.length;
        }
        
        final goalsByCategory = <GoalCategory, int>{};
        for (final category in GoalCategory.values) {
          goalsByCategory[category] = goals.where((goal) => goal.category == category).length;
        }
        
        final goalsByPriority = <GoalPriority, int>{};
        for (final priority in GoalPriority.values) {
          goalsByPriority[priority] = goals.where((goal) => goal.priority == priority).length;
        }
        
        final totalMilestones = goals.fold<int>(0, (sum, goal) => sum + goal.milestones.length);
        final completedMilestones = goals.fold<int>(0, (sum, goal) => sum + goal.completedMilestonesCount);
        
        final statistics = GoalStatistics(
          totalGoals: goals.length,
          activeGoals: activeGoals,
          completedGoals: completedGoals,
          pausedGoals: pausedGoals,
          cancelledGoals: cancelledGoals,
          overdueGoals: overdueGoals,
          averageProgress: averageProgress,
          goalsByCategory: goalsByCategory,
          goalsByPriority: goalsByPriority,
          totalMilestones: totalMilestones,
          completedMilestones: completedMilestones,
        );
        
        return AsyncValue.data(statistics);
      } catch (e) {
        return AsyncValue.error(e, StackTrace.current);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// 目標統計プロバイダー
final goalStatisticsProvider = FutureProvider<GoalStatistics>((ref) async {
  // 目標リストの変更を監視して統計を再計算
  final goalsAsync = ref.watch(goalNotifierProvider);
  
  return goalsAsync.when(
    data: (goals) async {
      final useCase = ref.watch(getGoalStatisticsUseCaseProvider);
      return await useCase();
    },
    loading: () => throw Exception('目標データを読み込み中です'),
    error: (error, stack) => throw Exception('統計の計算に失敗しました: $error'),
  );
});

/// アクティブな目標プロバイダー
final activeGoalsProvider = FutureProvider<List<Goal>>((ref) async {
  final useCase = ref.watch(getActiveGoalsUseCaseProvider);
  return await useCase();
});

/// 期限切れ目標プロバイダー
final overdueGoalsProvider = FutureProvider<List<Goal>>((ref) async {
  final useCase = ref.watch(getOverdueGoalsUseCaseProvider);
  return await useCase();
});

/// 期限が近い目標プロバイダー（7日以内）
final upcomingDeadlinesProvider = FutureProvider<List<Goal>>((ref) async {
  final useCase = ref.watch(getGoalsWithDeadlineWithinUseCaseProvider);
  return await useCase(7);
}); 