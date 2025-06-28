import 'package:dartz/dartz.dart' as dartz;
import '../entities/task.dart';

/// タスクリポジトリのインターフェース
/// データアクセス層の抽象化
abstract class TaskRepository {
  /// タスクを作成
  Future<dartz.Either<String, Task>> createTask(Task task);

  /// タスクを取得
  Future<dartz.Either<String, Task?>> getTask(String taskId);

  /// ユーザーの全タスクを取得
  Future<dartz.Either<String, List<Task>>> getAllTasks(String userId);

  /// 今日のタスクを取得
  Future<dartz.Either<String, List<Task>>> getTodayTasks(String userId);

  /// 指定日のタスクを取得
  Future<dartz.Either<String, List<Task>>> getTasksByDate(String userId, DateTime date);

  /// 期限切れのタスクを取得
  Future<dartz.Either<String, List<Task>>> getOverdueTasks(String userId);

  /// 完了済みタスクを取得
  Future<dartz.Either<String, List<Task>>> getCompletedTasks(String userId);

  /// 進行中のタスクを取得
  Future<dartz.Either<String, List<Task>>> getInProgressTasks(String userId);

  /// 特定の目標に関連するタスクを取得
  Future<dartz.Either<String, List<Task>>> getTasksByGoal(String userId, String goalId);

  /// 特定のタグを持つタスクを取得
  Future<dartz.Either<String, List<Task>>> getTasksByTag(String userId, String tag);

  /// 優先度でタスクを取得
  Future<dartz.Either<String, List<Task>>> getTasksByPriority(String userId, TaskPriority priority);

  /// タスクを更新
  Future<dartz.Either<String, Task>> updateTask(Task task);

  /// タスクを削除
  Future<dartz.Either<String, void>> deleteTask(String taskId);

  /// タスクを完了状態に変更
  Future<dartz.Either<String, Task>> completeTask(String taskId);

  /// タスクを未完了状態に変更
  Future<dartz.Either<String, Task>> uncompleteTask(String taskId);

  /// タスクを進行中状態に変更
  Future<dartz.Either<String, Task>> startTask(String taskId);

  /// タスクを遅延状態に変更
  Future<dartz.Either<String, Task>> delayTask(String taskId);

  /// サブタスクを追加
  Future<dartz.Either<String, Task>> addSubTask(String taskId, SubTask subTask);

  /// サブタスクを削除
  Future<dartz.Either<String, Task>> removeSubTask(String taskId, String subTaskId);

  /// サブタスクを完了
  Future<dartz.Either<String, Task>> completeSubTask(String taskId, String subTaskId);

  /// タグを追加
  Future<dartz.Either<String, Task>> addTag(String taskId, String tag);

  /// タグを削除
  Future<dartz.Either<String, Task>> removeTag(String taskId, String tag);

  /// タスクを検索
  Future<dartz.Either<String, List<Task>>> searchTasks(String userId, String query);

  /// タスクの統計情報を取得
  Future<dartz.Either<String, TaskStatistics>> getTaskStatistics(String userId, {DateTime? startDate, DateTime? endDate});

  /// 繰り返しタスクの次のインスタンスを作成
  Future<dartz.Either<String, Task>> createNextRecurrence(String taskId);

  /// タスクの先延ばしリスクを更新（AI予測）
  Future<dartz.Either<String, Task>> updateProcrastinationRisk(String taskId, double risk);

  /// バッチでタスクを更新
  Future<dartz.Either<String, List<Task>>> updateTasksBatch(List<Task> tasks);

  /// タスクの同期状態を確認
  Future<dartz.Either<String, bool>> isTaskSynced(String taskId);

  /// オフラインで作成されたタスクを同期
  Future<dartz.Either<String, List<Task>>> syncOfflineTasks(String userId);
}

/// タスクの統計情報
class TaskStatistics {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int overdueTasks;
  final int inProgressTasks;
  final double completionRate;
  final int totalSubTasks;
  final int completedSubTasks;
  final double subTaskCompletionRate;
  final Map<TaskPriority, int> tasksByPriority;
  final Map<TaskDifficulty, int> tasksByDifficulty;
  final Map<String, int> tasksByTag;
  final double averageCompletionTime; // 分単位
  final double averageProcrastinationRisk;

  const TaskStatistics({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.inProgressTasks,
    required this.completionRate,
    required this.totalSubTasks,
    required this.completedSubTasks,
    required this.subTaskCompletionRate,
    required this.tasksByPriority,
    required this.tasksByDifficulty,
    required this.tasksByTag,
    required this.averageCompletionTime,
    required this.averageProcrastinationRisk,
  });

  /// 統計情報を空の状態で作成
  factory TaskStatistics.empty() {
    return const TaskStatistics(
      totalTasks: 0,
      completedTasks: 0,
      pendingTasks: 0,
      overdueTasks: 0,
      inProgressTasks: 0,
      completionRate: 0.0,
      totalSubTasks: 0,
      completedSubTasks: 0,
      subTaskCompletionRate: 0.0,
      tasksByPriority: {},
      tasksByDifficulty: {},
      tasksByTag: {},
      averageCompletionTime: 0.0,
      averageProcrastinationRisk: 0.0,
    );
  }

  /// 統計情報をコピーして更新
  TaskStatistics copyWith({
    int? totalTasks,
    int? completedTasks,
    int? pendingTasks,
    int? overdueTasks,
    int? inProgressTasks,
    double? completionRate,
    int? totalSubTasks,
    int? completedSubTasks,
    double? subTaskCompletionRate,
    Map<TaskPriority, int>? tasksByPriority,
    Map<TaskDifficulty, int>? tasksByDifficulty,
    Map<String, int>? tasksByTag,
    double? averageCompletionTime,
    double? averageProcrastinationRisk,
  }) {
    return TaskStatistics(
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      overdueTasks: overdueTasks ?? this.overdueTasks,
      inProgressTasks: inProgressTasks ?? this.inProgressTasks,
      completionRate: completionRate ?? this.completionRate,
      totalSubTasks: totalSubTasks ?? this.totalSubTasks,
      completedSubTasks: completedSubTasks ?? this.completedSubTasks,
      subTaskCompletionRate: subTaskCompletionRate ?? this.subTaskCompletionRate,
      tasksByPriority: tasksByPriority ?? this.tasksByPriority,
      tasksByDifficulty: tasksByDifficulty ?? this.tasksByDifficulty,
      tasksByTag: tasksByTag ?? this.tasksByTag,
      averageCompletionTime: averageCompletionTime ?? this.averageCompletionTime,
      averageProcrastinationRisk: averageProcrastinationRisk ?? this.averageProcrastinationRisk,
    );
  }
} 