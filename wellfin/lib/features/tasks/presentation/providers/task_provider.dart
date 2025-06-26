import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/task_usecases.dart';
import '../../data/repositories/firestore_task_repository.dart';

/// タスクプロバイダー
final taskProvider = StateNotifierProvider<TaskNotifier, AsyncValue<List<Task>>>(
  (ref) => TaskNotifier(
    createTaskUseCase: ref.read(createTaskUseCaseProvider),
    getTodayTasksUseCase: ref.read(getTodayTasksUseCaseProvider),
    updateTaskUseCase: ref.read(updateTaskUseCaseProvider),
    deleteTaskUseCase: ref.read(deleteTaskUseCaseProvider),
    completeTaskUseCase: ref.read(completeTaskUseCaseProvider),
  ),
);

/// タスクノーティファイア
class TaskNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final CreateTaskUseCase createTaskUseCase;
  final GetTodayTasksUseCase getTodayTasksUseCase;
  final UpdateTaskUseCase updateTaskUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;
  final CompleteTaskUseCase completeTaskUseCase;

  TaskNotifier({
    required this.createTaskUseCase,
    required this.getTodayTasksUseCase,
    required this.updateTaskUseCase,
    required this.deleteTaskUseCase,
    required this.completeTaskUseCase,
  }) : super(const AsyncValue.loading());

  /// 現在のユーザーIDを取得
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// タスクを読み込み
  Future<void> loadTasks() async {
    state = const AsyncValue.loading();
    
    final userId = _currentUserId;
    if (userId == null) {
      state = AsyncValue.error('ユーザーが認証されていません', StackTrace.current);
      return;
    }
    
    final result = await getTodayTasksUseCase(userId);
    
    state = result.fold(
      (error) => AsyncValue.error(error, StackTrace.current),
      (tasks) => AsyncValue.data(tasks),
    );
  }

  /// 今日のタスクを読み込み
  Future<void> loadTodayTasks() async {
    state = const AsyncValue.loading();
    
    final userId = _currentUserId;
    if (userId == null) {
      state = AsyncValue.error('ユーザーが認証されていません', StackTrace.current);
      return;
    }
    
    final result = await getTodayTasksUseCase(userId);
    
    state = result.fold(
      (error) => AsyncValue.error(error, StackTrace.current),
      (tasks) => AsyncValue.data(tasks),
    );
  }

  /// タスクを作成
  Future<void> createTask(Task task) async {
    final result = await createTaskUseCase(task);
    
    result.fold(
      (error) {
        // エラーハンドリング
        state = AsyncValue.error(error, StackTrace.current);
      },
      (newTask) {
        // 成功時は現在のタスクリストに追加
        state.whenData((tasks) {
          state = AsyncValue.data([...tasks, newTask]);
        });
      },
    );
  }

  /// タスクを更新
  Future<void> updateTask(Task task) async {
    final result = await updateTaskUseCase(task);
    
    result.fold(
      (error) {
        // エラーハンドリング
        state = AsyncValue.error(error, StackTrace.current);
      },
      (updatedTask) {
        // 成功時は現在のタスクリストを更新
        state.whenData((tasks) {
          final updatedTasks = tasks.map((t) {
            return t.id == updatedTask.id ? updatedTask : t;
          }).toList();
          state = AsyncValue.data(updatedTasks);
        });
      },
    );
  }

  /// タスクを削除
  Future<void> deleteTask(String taskId) async {
    final result = await deleteTaskUseCase(taskId);
    
    result.fold(
      (error) {
        // エラーハンドリング
        state = AsyncValue.error(error, StackTrace.current);
      },
      (_) {
        // 成功時は現在のタスクリストから削除
        state.whenData((tasks) {
          final updatedTasks = tasks.where((t) => t.id != taskId).toList();
          state = AsyncValue.data(updatedTasks);
        });
      },
    );
  }

  /// タスクを完了
  Future<void> completeTask(String taskId) async {
    final result = await completeTaskUseCase(taskId);
    
    result.fold(
      (error) {
        // エラーハンドリング
        state = AsyncValue.error(error, StackTrace.current);
      },
      (completedTask) {
        // 成功時は現在のタスクリストを更新
        state.whenData((tasks) {
          final updatedTasks = tasks.map((t) {
            return t.id == completedTask.id ? completedTask : t;
          }).toList();
          state = AsyncValue.data(updatedTasks);
        });
      },
    );
  }

  /// タスクを開始
  Future<void> startTask(String taskId) async {
    state.whenData((tasks) {
      final updatedTasks = tasks.map((task) {
        if (task.id == taskId) {
          return task.markAsInProgress();
        }
        return task;
      }).toList();
      state = AsyncValue.data(updatedTasks);
    });
  }

  /// タスクを遅延
  Future<void> delayTask(String taskId) async {
    state.whenData((tasks) {
      final updatedTasks = tasks.map((task) {
        if (task.id == taskId) {
          return task.markAsDelayed();
        }
        return task;
      }).toList();
      state = AsyncValue.data(updatedTasks);
    });
  }
}

// 実際のFirestoreリポジトリを使用
final _firestoreTaskRepository = FirestoreTaskRepository();

// ユースケースプロバイダー（Firestore実装）
final createTaskUseCaseProvider = Provider<CreateTaskUseCase>((ref) {
  return CreateTaskUseCase(_firestoreTaskRepository);
});

final getTodayTasksUseCaseProvider = Provider<GetTodayTasksUseCase>((ref) {
  return GetTodayTasksUseCase(_firestoreTaskRepository);
});

final updateTaskUseCaseProvider = Provider<UpdateTaskUseCase>((ref) {
  return UpdateTaskUseCase(_firestoreTaskRepository);
});

final deleteTaskUseCaseProvider = Provider<DeleteTaskUseCase>((ref) {
  return DeleteTaskUseCase(_firestoreTaskRepository);
});

final completeTaskUseCaseProvider = Provider<CompleteTaskUseCase>((ref) {
  return CompleteTaskUseCase(_firestoreTaskRepository);
});

/// モックタスクリポジトリ（一時的な実装）
class MockTaskRepository implements TaskRepository {
  final List<Task> _tasks = [];

  @override
  Future<dartz.Either<String, Task>> createTask(Task task) async {
    _tasks.add(task);
    return dartz.Right(task);
  }

  @override
  Future<dartz.Either<String, Task?>> getTask(String taskId) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      return dartz.Right(task);
    } catch (e) {
      return dartz.Right(null);
    }
  }

  @override
  Future<dartz.Either<String, List<Task>>> getAllTasks(String userId) async {
    return dartz.Right(_tasks);
  }

  @override
  Future<dartz.Either<String, List<Task>>> getTodayTasks(String userId) async {
    final today = DateTime.now();
    final todayTasks = _tasks.where((task) {
      return task.scheduledDate.year == today.year &&
             task.scheduledDate.month == today.month &&
             task.scheduledDate.day == today.day;
    }).toList();
    return dartz.Right(todayTasks);
  }

  @override
  Future<dartz.Either<String, List<Task>>> getTasksByDate(String userId, DateTime date) async {
    final tasks = _tasks.where((task) {
      return task.scheduledDate.year == date.year &&
             task.scheduledDate.month == date.month &&
             task.scheduledDate.day == date.day;
    }).toList();
    return dartz.Right(tasks);
  }

  @override
  Future<dartz.Either<String, List<Task>>> getOverdueTasks(String userId) async {
    final now = DateTime.now();
    final overdueTasks = _tasks.where((task) {
      return task.scheduledDate.isBefore(DateTime(now.year, now.month, now.day)) &&
             !task.isCompleted;
    }).toList();
    return dartz.Right(overdueTasks);
  }

  @override
  Future<dartz.Either<String, List<Task>>> getCompletedTasks(String userId) async {
    final completedTasks = _tasks.where((task) => task.isCompleted).toList();
    return dartz.Right(completedTasks);
  }

  @override
  Future<dartz.Either<String, List<Task>>> getInProgressTasks(String userId) async {
    final inProgressTasks = _tasks.where((task) => task.isInProgress).toList();
    return dartz.Right(inProgressTasks);
  }

  @override
  Future<dartz.Either<String, List<Task>>> getTasksByGoal(String userId, String goalId) async {
    final goalTasks = _tasks.where((task) => task.goalId == goalId).toList();
    return dartz.Right(goalTasks);
  }

  @override
  Future<dartz.Either<String, List<Task>>> getTasksByTag(String userId, String tag) async {
    final tagTasks = _tasks.where((task) => task.tags.contains(tag)).toList();
    return dartz.Right(tagTasks);
  }

  @override
  Future<dartz.Either<String, List<Task>>> getTasksByPriority(String userId, TaskPriority priority) async {
    final priorityTasks = _tasks.where((task) => task.priority == priority).toList();
    return dartz.Right(priorityTasks);
  }

  @override
  Future<dartz.Either<String, Task>> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      return dartz.Right(task);
    }
    return dartz.Left('タスクが見つかりません');
  }

  @override
  Future<dartz.Either<String, void>> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
    return dartz.Right(null);
  }

  @override
  Future<dartz.Either<String, Task>> completeTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final completedTask = _tasks[index].markAsCompleted();
      _tasks[index] = completedTask;
      return dartz.Right(completedTask);
    }
    return dartz.Left('タスクが見つかりません');
  }

  @override
  Future<dartz.Either<String, Task>> startTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final startedTask = _tasks[index].markAsInProgress();
      _tasks[index] = startedTask;
      return dartz.Right(startedTask);
    }
    return dartz.Left('タスクが見つかりません');
  }

  @override
  Future<dartz.Either<String, Task>> delayTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final delayedTask = _tasks[index].markAsDelayed();
      _tasks[index] = delayedTask;
      return dartz.Right(delayedTask);
    }
    return dartz.Left('タスクが見つかりません');
  }

  @override
  Future<dartz.Either<String, Task>> addSubTask(String taskId, SubTask subTask) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final updatedTask = _tasks[index].addSubTask(subTask);
      _tasks[index] = updatedTask;
      return dartz.Right(updatedTask);
    }
    return dartz.Left('タスクが見つかりません');
  }

  @override
  Future<dartz.Either<String, Task>> removeSubTask(String taskId, String subTaskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final updatedTask = _tasks[index].removeSubTask(subTaskId);
      _tasks[index] = updatedTask;
      return dartz.Right(updatedTask);
    }
    return dartz.Left('タスクが見つかりません');
  }

  @override
  Future<dartz.Either<String, Task>> completeSubTask(String taskId, String subTaskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final updatedTask = _tasks[index].completeSubTask(subTaskId);
      _tasks[index] = updatedTask;
      return dartz.Right(updatedTask);
    }
    return dartz.Left('タスクが見つかりません');
  }

  @override
  Future<dartz.Either<String, Task>> addTag(String taskId, String tag) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final updatedTask = _tasks[index].addTag(tag);
      _tasks[index] = updatedTask;
      return dartz.Right(updatedTask);
    }
    return dartz.Left('タスクが見つかりません');
  }

  @override
  Future<dartz.Either<String, Task>> removeTag(String taskId, String tag) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final updatedTask = _tasks[index].removeTag(tag);
      _tasks[index] = updatedTask;
      return dartz.Right(updatedTask);
    }
    return dartz.Left('タスクが見つかりません');
  }

  @override
  Future<dartz.Either<String, TaskStatistics>> getTaskStatistics(String userId, {DateTime? startDate, DateTime? endDate}) async {
    final totalTasks = _tasks.length;
    final completedTasks = _tasks.where((task) => task.isCompleted).length;
    final pendingTasks = _tasks.where((task) => task.status == TaskStatus.pending).length;
    final overdueTasks = _tasks.where((task) => task.isOverdue).length;
    final inProgressTasks = _tasks.where((task) => task.isInProgress).length;
    final completionRate = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    
    final totalSubTasks = _tasks.fold<int>(0, (sum, task) => sum + task.subTasks.length);
    final completedSubTasks = _tasks.fold<int>(0, (sum, task) => sum + task.subTasks.where((st) => st.isCompleted).length);
    final subTaskCompletionRate = totalSubTasks > 0 ? completedSubTasks / totalSubTasks : 0.0;
    
    final tasksByPriority = <TaskPriority, int>{};
    final tasksByDifficulty = <TaskDifficulty, int>{};
    final tasksByTag = <String, int>{};
    
    for (final task in _tasks) {
      tasksByPriority[task.priority] = (tasksByPriority[task.priority] ?? 0) + 1;
      tasksByDifficulty[task.difficulty] = (tasksByDifficulty[task.difficulty] ?? 0) + 1;
      for (final tag in task.tags) {
        tasksByTag[tag] = (tasksByTag[tag] ?? 0) + 1;
      }
    }
    
    final averageCompletionTime = _tasks.where((task) => task.actualDuration != null)
        .fold<double>(0.0, (sum, task) => sum + (task.actualDuration ?? 0)) / 
        _tasks.where((task) => task.actualDuration != null).length;
    
    final averageProcrastinationRisk = _tasks.fold<double>(0.0, (sum, task) => sum + task.procrastinationRisk) / totalTasks;
    
    final statistics = TaskStatistics(
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      pendingTasks: pendingTasks,
      overdueTasks: overdueTasks,
      inProgressTasks: inProgressTasks,
      completionRate: completionRate,
      totalSubTasks: totalSubTasks,
      completedSubTasks: completedSubTasks,
      subTaskCompletionRate: subTaskCompletionRate,
      tasksByPriority: tasksByPriority,
      tasksByDifficulty: tasksByDifficulty,
      tasksByTag: tasksByTag,
      averageCompletionTime: averageCompletionTime.isNaN ? 0.0 : averageCompletionTime,
      averageProcrastinationRisk: averageProcrastinationRisk.isNaN ? 0.0 : averageProcrastinationRisk,
    );
    
    return dartz.Right(statistics);
  }

  @override
  Future<dartz.Either<String, Task>> createNextRecurrence(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final originalTask = _tasks[index];
      if (originalTask.repeatRule != null) {
        final nextDate = originalTask.repeatRule!.getNextOccurrence(originalTask.scheduledDate);
        final nextTask = originalTask.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          scheduledDate: nextDate,
          status: TaskStatus.pending,
          completedAt: null,
        );
        _tasks.add(nextTask);
        return dartz.Right(nextTask);
      }
    }
    return dartz.Left('タスクが見つからないか、繰り返しルールが設定されていません');
  }

  @override
  Future<dartz.Either<String, Task>> updateProcrastinationRisk(String taskId, double risk) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final updatedTask = _tasks[index].copyWith(procrastinationRisk: risk);
      _tasks[index] = updatedTask;
      return dartz.Right(updatedTask);
    }
    return dartz.Left('タスクが見つかりません');
  }

  @override
  Future<dartz.Either<String, List<Task>>> updateTasksBatch(List<Task> tasks) async {
    for (final task in tasks) {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
      }
    }
    return dartz.Right(tasks);
  }

  @override
  Future<dartz.Either<String, bool>> isTaskSynced(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    return dartz.Right(task.calendarEventId != null);
  }

  @override
  Future<dartz.Either<String, List<Task>>> syncOfflineTasks(String userId) async {
    // モック実装では、オフラインタスクは既に同期済みとみなす
    return dartz.Right(_tasks);
  }

  @override
  Future<dartz.Either<String, List<Task>>> searchTasks(String userId, String query) async {
    final searchResults = _tasks.where((task) {
      return task.title.toLowerCase().contains(query.toLowerCase()) ||
             task.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
    return dartz.Right(searchResults);
  }
} 