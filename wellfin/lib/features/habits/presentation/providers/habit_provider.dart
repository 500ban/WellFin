import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/habit.dart';
import '../../domain/usecases/habit_usecases.dart';
import '../../data/repositories/firestore_habit_repository.dart';

/// 習慣プロバイダー
final habitProvider = StateNotifierProvider<HabitNotifier, AsyncValue<List<Habit>>>(
  (ref) => HabitNotifier(
    createHabitUseCase: ref.read(createHabitUseCaseProvider),
    getTodayHabitsUseCase: ref.read(getTodayHabitsUseCaseProvider),
    getAllHabitsUseCase: ref.read(getAllHabitsUseCaseProvider),
    updateHabitUseCase: ref.read(updateHabitUseCaseProvider),
    deleteHabitUseCase: ref.read(deleteHabitUseCaseProvider),
    completeHabitUseCase: ref.read(completeHabitUseCaseProvider),
    recordDailyCompletionUseCase: ref.read(recordDailyCompletionUseCaseProvider),
    pauseHabitUseCase: ref.read(pauseHabitUseCaseProvider),
    resumeHabitUseCase: ref.read(resumeHabitUseCaseProvider),
  ),
);

/// 習慣ノーティファイア
class HabitNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  final CreateHabitUseCase createHabitUseCase;
  final GetTodayHabitsUseCase getTodayHabitsUseCase;
  final GetAllHabitsUseCase getAllHabitsUseCase;
  final UpdateHabitUseCase updateHabitUseCase;
  final DeleteHabitUseCase deleteHabitUseCase;
  final CompleteHabitUseCase completeHabitUseCase;
  final RecordDailyCompletionUseCase recordDailyCompletionUseCase;
  final PauseHabitUseCase pauseHabitUseCase;
  final ResumeHabitUseCase resumeHabitUseCase;

  HabitNotifier({
    required this.createHabitUseCase,
    required this.getTodayHabitsUseCase,
    required this.getAllHabitsUseCase,
    required this.updateHabitUseCase,
    required this.deleteHabitUseCase,
    required this.completeHabitUseCase,
    required this.recordDailyCompletionUseCase,
    required this.pauseHabitUseCase,
    required this.resumeHabitUseCase,
  }) : super(const AsyncValue.loading());

  /// 現在のユーザーIDを取得
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// 習慣を読み込み
  Future<void> loadHabits() async {
    state = const AsyncValue.loading();
    
    final userId = _currentUserId;
    if (userId == null) {
      state = AsyncValue.error('ユーザーが認証されていません', StackTrace.current);
      return;
    }
    
    final result = await getTodayHabitsUseCase(userId);
    
    state = result.fold(
      (error) => AsyncValue.error(error, StackTrace.current),
      (habits) => AsyncValue.data(habits),
    );
  }

  /// 全習慣を読み込み
  Future<void> loadAllHabits() async {
    state = const AsyncValue.loading();
    
    final userId = _currentUserId;
    if (userId == null) {
      state = AsyncValue.error('ユーザーが認証されていません', StackTrace.current);
      return;
    }
    
    final result = await getAllHabitsUseCase(userId);
    
    result.fold(
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
      },
      (habits) {
        state = AsyncValue.data(habits);
      },
    );
  }

  /// 今日の習慣を読み込み
  Future<void> loadTodayHabits() async {
    state = const AsyncValue.loading();
    
    final userId = _currentUserId;
    if (userId == null) {
      state = AsyncValue.error('ユーザーが認証されていません', StackTrace.current);
      return;
    }
    
    final result = await getTodayHabitsUseCase(userId);
    
    state = result.fold(
      (error) => AsyncValue.error(error, StackTrace.current),
      (habits) => AsyncValue.data(habits),
    );
  }

  /// 習慣を作成
  Future<void> createHabit(Habit habit) async {
    final result = await createHabitUseCase(habit);
    
    result.fold(
      (error) {
        // エラーハンドリング
        state = AsyncValue.error(error, StackTrace.current);
      },
      (newHabit) {
        // 成功時は現在の習慣リストに追加
        state.whenData((habits) {
          state = AsyncValue.data([...habits, newHabit]);
        });
      },
    );
  }

  /// 習慣を更新
  Future<void> updateHabit(Habit habit) async {
    final result = await updateHabitUseCase(habit);
    
    result.fold(
      (error) {
        // エラーハンドリング
        state = AsyncValue.error(error, StackTrace.current);
      },
      (updatedHabit) {
        // 成功時は現在の習慣リストを更新
        state.whenData((habits) {
          final updatedHabits = habits.map((h) {
            return h.id == updatedHabit.id ? updatedHabit : h;
          }).toList();
          state = AsyncValue.data(updatedHabits);
        });
      },
    );
  }

  /// 習慣を削除
  Future<void> deleteHabit(String habitId) async {
    final result = await deleteHabitUseCase(habitId);
    
    result.fold(
      (error) {
        // エラーハンドリング
        state = AsyncValue.error(error, StackTrace.current);
      },
      (_) {
        // 成功時は現在の習慣リストから削除
        state.whenData((habits) {
          final updatedHabits = habits.where((h) => h.id != habitId).toList();
          state = AsyncValue.data(updatedHabits);
        });
      },
    );
  }

  /// 習慣を終了
  Future<void> finishHabit(String habitId) async {
    final result = await completeHabitUseCase(habitId);
    
    result.fold(
      (error) {
        // エラーハンドリング
        state = AsyncValue.error(error, StackTrace.current);
      },
      (finishedHabit) {
        // 成功時は現在の習慣リストを更新
        state.whenData((habits) {
          final updatedHabits = habits.map((h) {
            return h.id == finishedHabit.id ? finishedHabit : h;
          }).toList();
          state = AsyncValue.data(updatedHabits);
        });
      },
    );
  }

  /// 習慣を完了（今日の完了を記録）
  Future<void> markHabitAsCompleted(String habitId) async {
    final result = await completeHabitUseCase(habitId);
    
    result.fold(
      (error) {
        // エラーハンドリング
        state = AsyncValue.error(error, StackTrace.current);
      },
      (completedHabit) {
        // 成功時は現在の習慣リストを更新
        state.whenData((habits) {
          final updatedHabits = habits.map((h) {
            return h.id == completedHabit.id ? completedHabit : h;
          }).toList();
          state = AsyncValue.data(updatedHabits);
        });
      },
    );
  }

  /// 習慣を一時停止
  Future<void> pauseHabit(String habitId) async {
    final result = await pauseHabitUseCase(habitId);
    
    result.fold(
      (error) {
        // エラーハンドリング
        state = AsyncValue.error(error, StackTrace.current);
      },
      (pausedHabit) {
        // 成功時は現在の習慣リストを更新
        state.whenData((habits) {
          final updatedHabits = habits.map((h) {
            return h.id == pausedHabit.id ? pausedHabit : h;
          }).toList();
          state = AsyncValue.data(updatedHabits);
        });
      },
    );
  }

  /// 習慣を再開
  Future<void> resumeHabit(String habitId) async {
    final result = await resumeHabitUseCase(habitId);
    
    result.fold(
      (error) {
        // エラーハンドリング
        state = AsyncValue.error(error, StackTrace.current);
      },
      (resumedHabit) {
        // 成功時は現在の習慣リストを更新
        state.whenData((habits) {
          final updatedHabits = habits.map((h) {
            return h.id == resumedHabit.id ? resumedHabit : h;
          }).toList();
          state = AsyncValue.data(updatedHabits);
        });
      },
    );
  }

  /// 習慣の日々の取り組みを記録
  Future<void> recordDailyCompletion(String habitId) async {
    final result = await recordDailyCompletionUseCase(habitId);
    
    result.fold(
      (error) {
        // エラーハンドリング
        state = AsyncValue.error(error, StackTrace.current);
      },
      (updatedHabit) {
        // 成功時は現在の習慣リストを更新
        state.whenData((habits) {
          final updatedHabits = habits.map((h) {
            return h.id == updatedHabit.id ? updatedHabit : h;
          }).toList();
          state = AsyncValue.data(updatedHabits);
        });
      },
    );
  }
}

// 実際のFirestoreリポジトリを使用
final _firestoreHabitRepository = FirestoreHabitRepository();

// ユースケースプロバイダー（Firestore実装）
final createHabitUseCaseProvider = Provider<CreateHabitUseCase>((ref) {
  return CreateHabitUseCase(_firestoreHabitRepository);
});

final getTodayHabitsUseCaseProvider = Provider<GetTodayHabitsUseCase>((ref) {
  return GetTodayHabitsUseCase(_firestoreHabitRepository);
});

final getAllHabitsUseCaseProvider = Provider<GetAllHabitsUseCase>((ref) {
  return GetAllHabitsUseCase(_firestoreHabitRepository);
});

final updateHabitUseCaseProvider = Provider<UpdateHabitUseCase>((ref) {
  return UpdateHabitUseCase(_firestoreHabitRepository);
});

final deleteHabitUseCaseProvider = Provider<DeleteHabitUseCase>((ref) {
  return DeleteHabitUseCase(_firestoreHabitRepository);
});

final completeHabitUseCaseProvider = Provider<CompleteHabitUseCase>((ref) {
  return CompleteHabitUseCase(_firestoreHabitRepository);
});

final recordDailyCompletionUseCaseProvider = Provider<RecordDailyCompletionUseCase>((ref) {
  return RecordDailyCompletionUseCase(_firestoreHabitRepository);
});

final pauseHabitUseCaseProvider = Provider<PauseHabitUseCase>((ref) {
  return PauseHabitUseCase(_firestoreHabitRepository);
});

final resumeHabitUseCaseProvider = Provider<ResumeHabitUseCase>((ref) {
  return ResumeHabitUseCase(_firestoreHabitRepository);
});

final getHabitStatisticsUseCaseProvider = Provider<GetHabitStatisticsUseCase>((ref) {
  return GetHabitStatisticsUseCase(_firestoreHabitRepository);
});

final getHabitStreaksUseCaseProvider = Provider<GetHabitStreaksUseCase>((ref) {
  return GetHabitStreaksUseCase(_firestoreHabitRepository);
}); 