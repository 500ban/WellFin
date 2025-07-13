import 'package:dartz/dartz.dart' as dartz;
import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// タスク作成ユースケース
class CreateTaskUseCase {
  final TaskRepository repository;

  CreateTaskUseCase(this.repository);

  Future<dartz.Either<String, Task>> call(Task task) async {
    return await repository.createTask(task);
  }
}

/// タスク取得ユースケース
class GetTaskUseCase {
  final TaskRepository repository;

  GetTaskUseCase(this.repository);

  Future<dartz.Either<String, Task?>> call(String taskId) async {
    return await repository.getTask(taskId);
  }
}

/// 今日のタスク取得ユースケース
class GetTodayTasksUseCase {
  final TaskRepository repository;

  GetTodayTasksUseCase(this.repository);

  Future<dartz.Either<String, List<Task>>> call(String userId) async {
    return await repository.getTodayTasks(userId);
  }
}

/// 全タスク取得ユースケース
class GetAllTasksUseCase {
  final TaskRepository repository;

  GetAllTasksUseCase(this.repository);

  Future<dartz.Either<String, List<Task>>> call(String userId) async {
    return await repository.getAllTasks(userId);
  }
}

/// 指定日のタスク取得ユースケース
class GetTasksByDateUseCase {
  final TaskRepository repository;

  GetTasksByDateUseCase(this.repository);

  Future<dartz.Either<String, List<Task>>> call(String userId, DateTime date) async {
    return await repository.getTasksByDate(userId, date);
  }
}

/// 期限切れタスク取得ユースケース
class GetOverdueTasksUseCase {
  final TaskRepository repository;

  GetOverdueTasksUseCase(this.repository);

  Future<dartz.Either<String, List<Task>>> call(String userId) async {
    return await repository.getOverdueTasks(userId);
  }
}

/// 完了済みタスク取得ユースケース
class GetCompletedTasksUseCase {
  final TaskRepository repository;

  GetCompletedTasksUseCase(this.repository);

  Future<dartz.Either<String, List<Task>>> call(String userId) async {
    return await repository.getCompletedTasks(userId);
  }
}

/// 進行中タスク取得ユースケース
class GetInProgressTasksUseCase {
  final TaskRepository repository;

  GetInProgressTasksUseCase(this.repository);

  Future<dartz.Either<String, List<Task>>> call(String userId) async {
    return await repository.getInProgressTasks(userId);
  }
}

/// 目標別タスク取得ユースケース
class GetTasksByGoalUseCase {
  final TaskRepository repository;

  GetTasksByGoalUseCase(this.repository);

  Future<dartz.Either<String, List<Task>>> call(String userId, String goalId) async {
    return await repository.getTasksByGoal(userId, goalId);
  }
}

/// タグ別タスク取得ユースケース
class GetTasksByTagUseCase {
  final TaskRepository repository;

  GetTasksByTagUseCase(this.repository);

  Future<dartz.Either<String, List<Task>>> call(String userId, String tag) async {
    return await repository.getTasksByTag(userId, tag);
  }
}

/// 優先度別タスク取得ユースケース
class GetTasksByPriorityUseCase {
  final TaskRepository repository;

  GetTasksByPriorityUseCase(this.repository);

  Future<dartz.Either<String, List<Task>>> call(String userId, TaskPriority priority) async {
    return await repository.getTasksByPriority(userId, priority);
  }
}

/// タスク更新ユースケース
class UpdateTaskUseCase {
  final TaskRepository repository;

  UpdateTaskUseCase(this.repository);

  Future<dartz.Either<String, Task>> call(Task task) async {
    return await repository.updateTask(task);
  }
}

/// タスク削除ユースケース
class DeleteTaskUseCase {
  final TaskRepository repository;

  DeleteTaskUseCase(this.repository);

  Future<dartz.Either<String, void>> call(String taskId) async {
    return await repository.deleteTask(taskId);
  }
}

/// タスク完了ユースケース
class CompleteTaskUseCase {
  final TaskRepository repository;

  CompleteTaskUseCase(this.repository);

  Future<dartz.Either<String, Task>> call(String taskId) async {
    return await repository.completeTask(taskId);
  }
}

/// タスク未完了ユースケース
class UncompleteTaskUseCase {
  final TaskRepository repository;

  UncompleteTaskUseCase(this.repository);

  Future<dartz.Either<String, Task>> call(String taskId) async {
    return await repository.uncompleteTask(taskId);
  }
}

/// タスク開始ユースケース
class StartTaskUseCase {
  final TaskRepository repository;

  StartTaskUseCase(this.repository);

  Future<dartz.Either<String, Task>> call(String taskId) async {
    return await repository.startTask(taskId);
  }
}

/// タスク遅延ユースケース
class DelayTaskUseCase {
  final TaskRepository repository;

  DelayTaskUseCase(this.repository);

  Future<dartz.Either<String, Task>> call(String taskId) async {
    return await repository.delayTask(taskId);
  }
}

/// サブタスク追加ユースケース
class AddSubTaskUseCase {
  final TaskRepository repository;

  AddSubTaskUseCase(this.repository);

  Future<dartz.Either<String, Task>> call(String taskId, SubTask subTask) async {
    return await repository.addSubTask(taskId, subTask);
  }
}

/// サブタスク削除ユースケース
class RemoveSubTaskUseCase {
  final TaskRepository repository;

  RemoveSubTaskUseCase(this.repository);

  Future<dartz.Either<String, Task>> call(String taskId, String subTaskId) async {
    return await repository.removeSubTask(taskId, subTaskId);
  }
}

/// サブタスク完了ユースケース
class CompleteSubTaskUseCase {
  final TaskRepository repository;

  CompleteSubTaskUseCase(this.repository);

  Future<dartz.Either<String, Task>> call(String taskId, String subTaskId) async {
    return await repository.completeSubTask(taskId, subTaskId);
  }
}

/// タグ追加ユースケース
class AddTagUseCase {
  final TaskRepository repository;

  AddTagUseCase(this.repository);

  Future<dartz.Either<String, Task>> call(String taskId, String tag) async {
    return await repository.addTag(taskId, tag);
  }
}

/// タグ削除ユースケース
class RemoveTagUseCase {
  final TaskRepository repository;

  RemoveTagUseCase(this.repository);

  Future<dartz.Either<String, Task>> call(String taskId, String tag) async {
    return await repository.removeTag(taskId, tag);
  }
}

/// タスク検索ユースケース
class SearchTasksUseCase {
  final TaskRepository repository;

  SearchTasksUseCase(this.repository);

  Future<dartz.Either<String, List<Task>>> call(String userId, String query) async {
    return await repository.searchTasks(userId, query);
  }
}

/// タスク統計取得ユースケース
class GetTaskStatisticsUseCase {
  final TaskRepository repository;

  GetTaskStatisticsUseCase(this.repository);

  Future<dartz.Either<String, TaskStatistics>> call(String userId, {DateTime? startDate, DateTime? endDate}) async {
    return await repository.getTaskStatistics(userId, startDate: startDate, endDate: endDate);
  }
}

/// 繰り返しタスク次回作成ユースケース
class CreateNextRecurrenceUseCase {
  final TaskRepository repository;

  CreateNextRecurrenceUseCase(this.repository);

  Future<dartz.Either<String, Task>> call(String taskId) async {
    return await repository.createNextRecurrence(taskId);
  }
}

/// 先延ばしリスク更新ユースケース
class UpdateProcrastinationRiskUseCase {
  final TaskRepository repository;

  UpdateProcrastinationRiskUseCase(this.repository);

  Future<dartz.Either<String, Task>> call(String taskId, double risk) async {
    return await repository.updateProcrastinationRisk(taskId, risk);
  }
}

/// バッチタスク更新ユースケース
class UpdateTasksBatchUseCase {
  final TaskRepository repository;

  UpdateTasksBatchUseCase(this.repository);

  Future<dartz.Either<String, List<Task>>> call(List<Task> tasks) async {
    return await repository.updateTasksBatch(tasks);
  }
}

/// タスク同期確認ユースケース
class IsTaskSyncedUseCase {
  final TaskRepository repository;

  IsTaskSyncedUseCase(this.repository);

  Future<dartz.Either<String, bool>> call(String taskId) async {
    return await repository.isTaskSynced(taskId);
  }
}

/// オフラインタスク同期ユースケース
class SyncOfflineTasksUseCase {
  final TaskRepository repository;

  SyncOfflineTasksUseCase(this.repository);

  Future<dartz.Either<String, List<Task>>> call(String userId) async {
    return await repository.syncOfflineTasks(userId);
  }
} 