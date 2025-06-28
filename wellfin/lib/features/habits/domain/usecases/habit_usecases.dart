import 'package:dartz/dartz.dart' as dartz;
import '../entities/habit.dart';
import '../repositories/habit_repository.dart';

/// 習慣作成ユースケース
class CreateHabitUseCase {
  final HabitRepository _repository;

  CreateHabitUseCase(this._repository);

  Future<dartz.Either<String, Habit>> call(Habit habit) async {
    return await _repository.createHabit(habit);
  }
}

/// 習慣取得ユースケース
class GetHabitUseCase {
  final HabitRepository _repository;

  GetHabitUseCase(this._repository);

  Future<dartz.Either<String, Habit?>> call(String habitId) async {
    return await _repository.getHabit(habitId);
  }
}

/// 全習慣取得ユースケース
class GetAllHabitsUseCase {
  final HabitRepository _repository;

  GetAllHabitsUseCase(this._repository);

  Future<dartz.Either<String, List<Habit>>> call(String userId) async {
    return await _repository.getAllHabits(userId);
  }
}

/// 今日の習慣取得ユースケース
class GetTodayHabitsUseCase {
  final HabitRepository _repository;

  GetTodayHabitsUseCase(this._repository);

  Future<dartz.Either<String, List<Habit>>> call(String userId) async {
    return await _repository.getTodayHabits(userId);
  }
}

/// 指定日の習慣取得ユースケース
class GetHabitsByDateUseCase {
  final HabitRepository _repository;

  GetHabitsByDateUseCase(this._repository);

  Future<dartz.Either<String, List<Habit>>> call(String userId, DateTime date) async {
    return await _repository.getHabitsByDate(userId, date);
  }
}

/// アクティブな習慣取得ユースケース
class GetActiveHabitsUseCase {
  final HabitRepository _repository;

  GetActiveHabitsUseCase(this._repository);

  Future<dartz.Either<String, List<Habit>>> call(String userId) async {
    return await _repository.getActiveHabits(userId);
  }
}

/// 終了した習慣取得ユースケース
class GetFinishedHabitsUseCase {
  final HabitRepository _repository;

  GetFinishedHabitsUseCase(this._repository);

  Future<dartz.Either<String, List<Habit>>> call(String userId) async {
    return await _repository.getFinishedHabits(userId);
  }
}

/// 一時停止中の習慣取得ユースケース
class GetPausedHabitsUseCase {
  final HabitRepository _repository;

  GetPausedHabitsUseCase(this._repository);

  Future<dartz.Either<String, List<Habit>>> call(String userId) async {
    return await _repository.getPausedHabits(userId);
  }
}

/// カテゴリ別習慣取得ユースケース
class GetHabitsByCategoryUseCase {
  final HabitRepository _repository;

  GetHabitsByCategoryUseCase(this._repository);

  Future<dartz.Either<String, List<Habit>>> call(String userId, String category) async {
    return await _repository.getHabitsByCategory(userId, category);
  }
}

/// 目標関連習慣取得ユースケース
class GetHabitsByGoalUseCase {
  final HabitRepository _repository;

  GetHabitsByGoalUseCase(this._repository);

  Future<dartz.Either<String, List<Habit>>> call(String userId, String goalId) async {
    return await _repository.getHabitsByGoal(userId, goalId);
  }
}

/// タグ別習慣取得ユースケース
class GetHabitsByTagUseCase {
  final HabitRepository _repository;

  GetHabitsByTagUseCase(this._repository);

  Future<dartz.Either<String, List<Habit>>> call(String userId, String tag) async {
    return await _repository.getHabitsByTag(userId, tag);
  }
}

/// 習慣更新ユースケース
class UpdateHabitUseCase {
  final HabitRepository _repository;

  UpdateHabitUseCase(this._repository);

  Future<dartz.Either<String, Habit>> call(Habit habit) async {
    return await _repository.updateHabit(habit);
  }
}

/// 習慣削除ユースケース
class DeleteHabitUseCase {
  final HabitRepository _repository;

  DeleteHabitUseCase(this._repository);

  Future<dartz.Either<String, void>> call(String habitId) async {
    return await _repository.deleteHabit(habitId);
  }
}

/// 習慣完了ユースケース
class CompleteHabitUseCase {
  final HabitRepository _repository;

  CompleteHabitUseCase(this._repository);

  Future<dartz.Either<String, Habit>> call(String habitId) async {
    return await _repository.completeHabit(habitId);
  }
}

/// 習慣一時停止ユースケース
class PauseHabitUseCase {
  final HabitRepository _repository;

  PauseHabitUseCase(this._repository);

  Future<dartz.Either<String, Habit>> call(String habitId) async {
    return await _repository.pauseHabit(habitId);
  }
}

/// 習慣再開ユースケース
class ResumeHabitUseCase {
  final HabitRepository _repository;

  ResumeHabitUseCase(this._repository);

  Future<dartz.Either<String, Habit>> call(String habitId) async {
    return await _repository.resumeHabit(habitId);
  }
}

/// 習慣統計取得ユースケース
class GetHabitStatisticsUseCase {
  final HabitRepository _repository;

  GetHabitStatisticsUseCase(this._repository);

  Future<dartz.Either<String, HabitStatistics>> call(String userId) async {
    return await _repository.getHabitStatistics(userId);
  }
}

/// 習慣ストリーク取得ユースケース
class GetHabitStreaksUseCase {
  final HabitRepository _repository;

  GetHabitStreaksUseCase(this._repository);

  Future<dartz.Either<String, List<HabitStreakInfo>>> call(String userId) async {
    return await _repository.getHabitStreaks(userId);
  }
}

/// 日々の取り組み記録ユースケース
class RecordDailyCompletionUseCase {
  final HabitRepository _repository;

  RecordDailyCompletionUseCase(this._repository);

  Future<dartz.Either<String, Habit>> call(String habitId) async {
    return await _repository.recordDailyCompletion(habitId);
  }
} 