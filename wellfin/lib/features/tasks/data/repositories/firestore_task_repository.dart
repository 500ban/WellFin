import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../models/task_model.dart';

/// Firebase Firestoreを使用するタスクリポジトリの実装
class FirestoreTaskRepository implements TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 現在のユーザーIDを取得
  String? get _currentUserId => _auth.currentUser?.uid;

  /// ユーザーのタスクコレクション参照を取得
  CollectionReference<Map<String, dynamic>> _getTasksCollection() {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('ユーザーが認証されていません');
    }
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  @override
  Future<dartz.Either<String, Task>> createTask(Task task) async {
    try {
      final taskModel = TaskModel.fromDomain(task);
      final docRef = await _getTasksCollection().add(taskModel.toFirestore());
      // 作成されたタスクを取得して返す
      final doc = await docRef.get();
      final createdTask = TaskModel.fromFirestore(doc).toDomain();
      return dartz.Right(createdTask);
    } catch (e) {
      return dartz.Left('タスクの作成に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, Task?>> getTask(String taskId) async {
    try {
      final doc = await _getTasksCollection().doc(taskId).get();
      
      if (!doc.exists) {
        return dartz.Right(null);
      }
      
      final task = TaskModel.fromFirestore(doc).toDomain();
      return dartz.Right(task);
    } catch (e) {
      return dartz.Left('タスクの取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Task>>> getAllTasks(String userId) async {
    try {
      final querySnapshot = await _getTasksCollection()
          .orderBy('scheduledDate', descending: true)
          .get();
      
      final tasks = querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc).toDomain())
          .toList();
      
      return dartz.Right(tasks);
    } catch (e) {
      return dartz.Left('タスクの取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Task>>> getTodayTasks(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final querySnapshot = await _getTasksCollection()
          .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('scheduledDate', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('scheduledDate')
          .get();
      
      final tasks = querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc).toDomain())
          .toList();
      
      return dartz.Right(tasks);
    } catch (e) {
      return dartz.Left('今日のタスクの取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Task>>> getTasksByDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final querySnapshot = await _getTasksCollection()
          .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('scheduledDate', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('scheduledDate')
          .get();
      
      final tasks = querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc).toDomain())
          .toList();
      
      return dartz.Right(tasks);
    } catch (e) {
      return dartz.Left('指定日のタスクの取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Task>>> getOverdueTasks(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final querySnapshot = await _getTasksCollection()
          .where('scheduledDate', isLessThan: Timestamp.fromDate(startOfDay))
          .where('status', isNotEqualTo: 'completed')
          .orderBy('scheduledDate')
          .get();
      
      final tasks = querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc).toDomain())
          .toList();
      
      return dartz.Right(tasks);
    } catch (e) {
      return dartz.Left('期限切れタスクの取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Task>>> getCompletedTasks(String userId) async {
    try {
      final querySnapshot = await _getTasksCollection()
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .get();
      
      final tasks = querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc).toDomain())
          .toList();
      
      return dartz.Right(tasks);
    } catch (e) {
      return dartz.Left('完了タスクの取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Task>>> getInProgressTasks(String userId) async {
    try {
      final querySnapshot = await _getTasksCollection()
          .where('status', isEqualTo: 'in_progress')
          .orderBy('scheduledDate')
          .get();
      
      final tasks = querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc).toDomain())
          .toList();
      
      return dartz.Right(tasks);
    } catch (e) {
      return dartz.Left('進行中タスクの取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Task>>> getTasksByGoal(String userId, String goalId) async {
    try {
      final querySnapshot = await _getTasksCollection()
          .where('goalId', isEqualTo: goalId)
          .orderBy('scheduledDate')
          .get();
      
      final tasks = querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc).toDomain())
          .toList();
      
      return dartz.Right(tasks);
    } catch (e) {
      return dartz.Left('目標関連タスクの取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Task>>> getTasksByTag(String userId, String tag) async {
    try {
      final querySnapshot = await _getTasksCollection()
          .where('tags', arrayContains: tag)
          .orderBy('scheduledDate')
          .get();
      
      final tasks = querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc).toDomain())
          .toList();
      
      return dartz.Right(tasks);
    } catch (e) {
      return dartz.Left('タグ関連タスクの取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Task>>> getTasksByPriority(String userId, TaskPriority priority) async {
    try {
      final querySnapshot = await _getTasksCollection()
          .where('priority', isEqualTo: priority.value)
          .orderBy('scheduledDate')
          .get();
      
      final tasks = querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc).toDomain())
          .toList();
      
      return dartz.Right(tasks);
    } catch (e) {
      return dartz.Left('優先度別タスクの取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, Task>> updateTask(Task task) async {
    try {
      final taskModel = TaskModel.fromDomain(task);
      await _getTasksCollection().doc(task.id).update(taskModel.toFirestore());
      
      return dartz.Right(task);
    } catch (e) {
      return dartz.Left('タスクの更新に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, void>> deleteTask(String taskId) async {
    try {
      await _getTasksCollection().doc(taskId).delete();
      return dartz.Right(null);
    } catch (e) {
      return dartz.Left('タスクの削除に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, Task>> completeTask(String taskId) async {
    try {
      final docRef = _getTasksCollection().doc(taskId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        return dartz.Left('タスクが見つかりません');
      }
      
      final task = TaskModel.fromFirestore(doc).toDomain();
      final completedTask = task.markAsCompleted();
      final taskModel = TaskModel.fromDomain(completedTask);
      
      await docRef.update(taskModel.toFirestore());
      
      return dartz.Right(completedTask);
    } catch (e) {
      return dartz.Left('タスクの完了に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, Task>> uncompleteTask(String taskId) async {
    try {
      final docRef = _getTasksCollection().doc(taskId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        return dartz.Left('タスクが見つかりません');
      }
      
      final task = TaskModel.fromFirestore(doc).toDomain();
      final uncompletedTask = task.markAsPending();
      final taskModel = TaskModel.fromDomain(uncompletedTask);
      
      await docRef.update(taskModel.toFirestore());
      
      return dartz.Right(uncompletedTask);
    } catch (e) {
      return dartz.Left('タスクの未完了化に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, Task>> startTask(String taskId) async {
    try {
      final docRef = _getTasksCollection().doc(taskId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        return dartz.Left('タスクが見つかりません');
      }
      
      final task = TaskModel.fromFirestore(doc).toDomain();
      final startedTask = task.markAsInProgress();
      final taskModel = TaskModel.fromDomain(startedTask);
      
      await docRef.update(taskModel.toFirestore());
      
      return dartz.Right(startedTask);
    } catch (e) {
      return dartz.Left('タスクの開始に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, Task>> delayTask(String taskId) async {
    try {
      final docRef = _getTasksCollection().doc(taskId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        return dartz.Left('タスクが見つかりません');
      }
      
      final task = TaskModel.fromFirestore(doc).toDomain();
      final delayedTask = task.markAsDelayed();
      final taskModel = TaskModel.fromDomain(delayedTask);
      
      await docRef.update(taskModel.toFirestore());
      
      return dartz.Right(delayedTask);
    } catch (e) {
      return dartz.Left('タスクの遅延に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, Task>> addSubTask(String taskId, SubTask subTask) async {
    try {
      final docRef = _getTasksCollection().doc(taskId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        return dartz.Left('タスクが見つかりません');
      }
      
      final task = TaskModel.fromFirestore(doc).toDomain();
      final updatedTask = task.addSubTask(subTask);
      final taskModel = TaskModel.fromDomain(updatedTask);
      
      await docRef.update(taskModel.toFirestore());
      
      return dartz.Right(updatedTask);
    } catch (e) {
      return dartz.Left('サブタスクの追加に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, Task>> removeSubTask(String taskId, String subTaskId) async {
    try {
      final docRef = _getTasksCollection().doc(taskId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        return dartz.Left('タスクが見つかりません');
      }
      
      final task = TaskModel.fromFirestore(doc).toDomain();
      final updatedTask = task.removeSubTask(subTaskId);
      final taskModel = TaskModel.fromDomain(updatedTask);
      
      await docRef.update(taskModel.toFirestore());
      
      return dartz.Right(updatedTask);
    } catch (e) {
      return dartz.Left('サブタスクの削除に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, Task>> completeSubTask(String taskId, String subTaskId) async {
    try {
      final docRef = _getTasksCollection().doc(taskId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        return dartz.Left('タスクが見つかりません');
      }
      
      final task = TaskModel.fromFirestore(doc).toDomain();
      final updatedTask = task.completeSubTask(subTaskId);
      final taskModel = TaskModel.fromDomain(updatedTask);
      
      await docRef.update(taskModel.toFirestore());
      
      return dartz.Right(updatedTask);
    } catch (e) {
      return dartz.Left('サブタスクの完了に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, Task>> addTag(String taskId, String tag) async {
    try {
      final docRef = _getTasksCollection().doc(taskId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        return dartz.Left('タスクが見つかりません');
      }
      
      final task = TaskModel.fromFirestore(doc).toDomain();
      final updatedTask = task.addTag(tag);
      final taskModel = TaskModel.fromDomain(updatedTask);
      
      await docRef.update(taskModel.toFirestore());
      
      return dartz.Right(updatedTask);
    } catch (e) {
      return dartz.Left('タグの追加に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, Task>> removeTag(String taskId, String tag) async {
    try {
      final docRef = _getTasksCollection().doc(taskId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        return dartz.Left('タスクが見つかりません');
      }
      
      final task = TaskModel.fromFirestore(doc).toDomain();
      final updatedTask = task.removeTag(tag);
      final taskModel = TaskModel.fromDomain(updatedTask);
      
      await docRef.update(taskModel.toFirestore());
      
      return dartz.Right(updatedTask);
    } catch (e) {
      return dartz.Left('タグの削除に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Task>>> searchTasks(String userId, String query) async {
    try {
      // Firestoreでは全文検索が制限されているため、
      // クライアントサイドでフィルタリングを行う
      final allTasks = await getAllTasks(userId);
      
      return allTasks.fold(
        (error) => dartz.Left(error),
        (tasks) {
          final searchResults = tasks.where((task) {
            return task.title.toLowerCase().contains(query.toLowerCase()) ||
                   task.description.toLowerCase().contains(query.toLowerCase()) ||
                   task.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
          }).toList();
          
          return dartz.Right(searchResults);
        },
      );
    } catch (e) {
      return dartz.Left('タスクの検索に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, TaskStatistics>> getTaskStatistics(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final allTasks = await getAllTasks(userId);
      
      return allTasks.fold(
        (error) => dartz.Left(error),
        (tasks) {
          // 日付フィルタリング
          final filteredTasks = tasks.where((task) {
            if (startDate != null && task.scheduledDate.isBefore(startDate)) {
              return false;
            }
            if (endDate != null && task.scheduledDate.isAfter(endDate)) {
              return false;
            }
            return true;
          }).toList();
          
          final totalTasks = filteredTasks.length;
          final completedTasks = filteredTasks.where((task) => task.isCompleted).length;
          final pendingTasks = filteredTasks.where((task) => task.status == TaskStatus.pending).length;
          final overdueTasks = filteredTasks.where((task) => task.isOverdue).length;
          final inProgressTasks = filteredTasks.where((task) => task.isInProgress).length;
          final completionRate = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
          
          final totalSubTasks = filteredTasks.fold<int>(0, (sum, task) => sum + task.subTasks.length);
          final completedSubTasks = filteredTasks.fold<int>(0, (sum, task) => sum + task.subTasks.where((st) => st.isCompleted).length);
          final subTaskCompletionRate = totalSubTasks > 0 ? completedSubTasks / totalSubTasks : 0.0;
          
          final tasksByPriority = <TaskPriority, int>{};
          final tasksByDifficulty = <TaskDifficulty, int>{};
          final tasksByTag = <String, int>{};
          
          for (final task in filteredTasks) {
            tasksByPriority[task.priority] = (tasksByPriority[task.priority] ?? 0) + 1;
            tasksByDifficulty[task.difficulty] = (tasksByDifficulty[task.difficulty] ?? 0) + 1;
            for (final tag in task.tags) {
              tasksByTag[tag] = (tasksByTag[tag] ?? 0) + 1;
            }
          }
          
          final averageCompletionTime = filteredTasks.where((task) => task.actualDuration != null)
              .fold<double>(0.0, (sum, task) => sum + (task.actualDuration ?? 0)) / 
              filteredTasks.where((task) => task.actualDuration != null).length;
          
          final averageProcrastinationRisk = filteredTasks.fold<double>(0.0, (sum, task) => sum + task.procrastinationRisk) / totalTasks;
          
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
        },
      );
    } catch (e) {
      return dartz.Left('統計情報の取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, Task>> createNextRecurrence(String taskId) async {
    try {
      final docRef = _getTasksCollection().doc(taskId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        return dartz.Left('タスクが見つかりません');
      }
      
      final originalTask = TaskModel.fromFirestore(doc).toDomain();
      if (originalTask.repeatRule == null) {
        return dartz.Left('繰り返しルールが設定されていません');
      }
      
      final nextDate = originalTask.repeatRule!.getNextOccurrence(originalTask.scheduledDate);
      final nextTask = originalTask.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        scheduledDate: nextDate,
        status: TaskStatus.pending,
        completedAt: null,
      );
      
      final nextTaskModel = TaskModel.fromDomain(nextTask);
      await _getTasksCollection().add(nextTaskModel.toFirestore());
      
      return dartz.Right(nextTask);
    } catch (e) {
      return dartz.Left('次の繰り返しタスクの作成に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, Task>> updateProcrastinationRisk(String taskId, double risk) async {
    try {
      final docRef = _getTasksCollection().doc(taskId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        return dartz.Left('タスクが見つかりません');
      }
      
      final task = TaskModel.fromFirestore(doc).toDomain();
      final updatedTask = task.copyWith(procrastinationRisk: risk);
      final taskModel = TaskModel.fromDomain(updatedTask);
      
      await docRef.update(taskModel.toFirestore());
      
      return dartz.Right(updatedTask);
    } catch (e) {
      return dartz.Left('先延ばしリスクの更新に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Task>>> updateTasksBatch(List<Task> tasks) async {
    try {
      final batch = _firestore.batch();
      
      for (final task in tasks) {
        final taskModel = TaskModel.fromDomain(task);
        final docRef = _getTasksCollection().doc(task.id);
        batch.update(docRef, taskModel.toFirestore());
      }
      
      await batch.commit();
      
      return dartz.Right(tasks);
    } catch (e) {
      return dartz.Left('バッチ更新に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, bool>> isTaskSynced(String taskId) async {
    try {
      final doc = await _getTasksCollection().doc(taskId).get();
      
      if (!doc.exists) {
        return dartz.Right(false);
      }
      
      final task = TaskModel.fromFirestore(doc).toDomain();
      return dartz.Right(task.calendarEventId != null);
    } catch (e) {
      return dartz.Left('同期状態の確認に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Task>>> syncOfflineTasks(String userId) async {
    try {
      // オフラインタスクの同期は、Firestoreの自動同期機能により
      // アプリがオンラインに戻った時に自動的に処理される
      // ここでは現在のタスクを返す
      return getAllTasks(userId);
    } catch (e) {
      return dartz.Left('オフラインタスクの同期に失敗しました: $e');
    }
  }
} 