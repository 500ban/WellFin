import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_settings.dart';
import '../providers/notification_settings_provider.dart' show notificationSettingsProvider;
import '../../features/tasks/domain/entities/task.dart';

/// 🔔 タスク締切スケジューラー
/// 優先度・時間設定に基づく締切前通知を管理
class TaskDeadlineScheduler {
  final Ref _ref;
  
  TaskDeadlineScheduler(this._ref);

  /// タスクの締切通知をスケジュール
  Future<bool> scheduleTaskDeadline({
    required Task task,
    TaskNotificationSettings? customSettings,
  }) async {
    try {
      // 通知設定を取得
      final notificationSettings = _ref.read(notificationSettingsProvider);
      final settings = customSettings ?? notificationSettings.taskSettings;
      
      // 通知が無効の場合はスキップ
      if (!settings.deadlineAlertsEnabled) {
        return true;
      }
      
      // 締切日がない場合はスキップ
      if (task.scheduledDate.isBefore(DateTime.now())) {
        return true;
      }
      
      // 基本設定を使用
      final alertHours = settings.alertHours;
      
      // 通知メッセージを生成
      // final message = _generateDeadlineMessage(task, settings);
      
      // 各アラート時間に対して通知をスケジュール
      for (final hour in alertHours) {
        final deadlineTime = task.scheduledDate;
        final notificationTime = deadlineTime.subtract(Duration(hours: hour));
        
        // 過去の時刻でない場合のみスケジュール
        if (notificationTime.isAfter(DateTime.now())) {
          // final notificationId = _generateNotificationId(task.id, 'deadline_$hour');
          
          // TODO: LocalNotificationServiceを使用して通知をスケジュール
          // await LocalNotificationService().scheduleTaskDeadline(
          //   id: notificationId,
          //   taskTitle: task.title,
          //   scheduledTime: notificationTime,
          //   message: message,
          // );
          
          debugPrint('タスク締切通知をスケジュール: ${task.title} - ${hour}時間前');
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('タスク締切通知のスケジュール中にエラーが発生しました: $e');
      return false;
    }
  }

  /// タスクの締切通知をキャンセル
  Future<bool> cancelTaskDeadline(String taskId) async {
    try {
      // 各アラート時間の通知をキャンセル
      final alertHours = [1, 8, 24]; // 一般的なアラート時間
      for (final _ in alertHours) {
        // final notificationId = _generateNotificationId(taskId, 'deadline_$hour');
        
        // TODO: LocalNotificationServiceを使用して通知をキャンセル
        // await LocalNotificationService().cancelNotification(notificationId);
      }
      
      debugPrint('タスク締切通知をキャンセル: $taskId');
      
      return true;
    } catch (e) {
      debugPrint('タスク締切通知のキャンセル中にエラーが発生しました: $e');
      return false;
    }
  }

  /// 全タスクの締切通知を更新
  Future<bool> updateAllTaskDeadlines(List<Task> tasks) async {
    try {
      int successCount = 0;
      
      for (final task in tasks) {
        // 既存の通知をキャンセル
        await cancelTaskDeadline(task.id);
        
        // 新しい通知をスケジュール
        final success = await scheduleTaskDeadline(task: task);
        if (success) {
          successCount++;
        }
      }
      
      debugPrint('タスク締切通知更新完了: $successCount/${tasks.length}');
      return successCount == tasks.length;
    } catch (e) {
      debugPrint('タスク締切通知の更新中にエラーが発生しました: $e');
      return false;
    }
  }

  /// 緊急タスクの即座通知
  Future<bool> triggerUrgentTaskNotification(Task task) async {
    try {
      final notificationSettings = _ref.read(notificationSettingsProvider);
      final settings = notificationSettings.taskSettings;
      
      if (!settings.deadlineAlertsEnabled) {
        return false;
      }
      
      // final message = _generateUrgentMessage(task);
      // final notificationId = _generateNotificationId(task.id, 'urgent');
      
      // TODO: LocalNotificationServiceを使用して即座通知
      // await LocalNotificationService().showImmediateNotification(
      //   id: notificationId,
      //   title: '🚨 緊急タスク',
      //   message: message,
      //   category: NotificationCategory.taskDeadlines,
      // );
      
      debugPrint('緊急タスク通知を実行: ${task.title}');
      return true;
    } catch (e) {
      debugPrint('緊急タスク通知の実行中にエラーが発生しました: $e');
      return false;
    }
  }

  /// 今日のタスクリスト通知
  Future<bool> sendTodayTasksNotification(List<Task> tasks) async {
    try {
      final notificationSettings = _ref.read(notificationSettingsProvider);
      final settings = notificationSettings.taskSettings;
      
      if (!settings.deadlineAlertsEnabled) {
        return false;
      }
      
      final todayTasks = tasks.where((task) => task.isToday).toList();
      if (todayTasks.isEmpty) {
        return false;
      }
      
      // final message = _generateTodayTasksMessage(todayTasks);
      // final notificationId = _generateNotificationId('today', 'tasks');
      
      // TODO: LocalNotificationServiceを使用して通知
      // await LocalNotificationService().showImmediateNotification(
      //   id: notificationId,
      //   title: '📅 今日のタスク',
      //   message: message,
      //   category: NotificationCategory.taskDeadlines,
      // );
      
      debugPrint('今日のタスク通知を送信: ${todayTasks.length}件');
      return true;
    } catch (e) {
      debugPrint('今日のタスク通知の送信中にエラーが発生しました: $e');
      return false;
    }
  }

  /// 過期タスクの通知
  Future<bool> sendOverdueTasksNotification(List<Task> tasks) async {
    try {
      final notificationSettings = _ref.read(notificationSettingsProvider);
      final settings = notificationSettings.taskSettings;
      
      if (!settings.deadlineAlertsEnabled) {
        return false;
      }
      
      final overdueTasks = tasks.where((task) => task.isOverdue).toList();
      if (overdueTasks.isEmpty) {
        return false;
      }
      
      // final message = _generateOverdueMessage(overdueTasks);
      // final notificationId = _generateNotificationId('overdue', 'tasks');
      
      // TODO: LocalNotificationServiceを使用して通知
      // await LocalNotificationService().showImmediateNotification(
      //   id: notificationId,
      //   title: '⚠️ 過期タスク',
      //   message: message,
      //   category: NotificationCategory.taskDeadlines,
      // );
      
      debugPrint('過期タスク通知を送信: ${overdueTasks.length}件');
      return true;
    } catch (e) {
      debugPrint('過期タスク通知の送信中にエラーが発生しました: $e');
      return false;
    }
  }

  /// タスク締切通知の統計を取得
  Future<TaskDeadlineStats> getDeadlineStats() async {
    try {
      // TODO: LocalNotificationServiceから予定通知を取得
      // final pendingNotifications = await LocalNotificationService().getPendingNotifications();
      
      final pendingCount = 0; // TODO: 実際の予定通知数を取得
      
      return TaskDeadlineStats(
        pendingNotifications: pendingCount,
        todayTasks: 0,
        overdueTasks: 0,
        completedTasks: 0,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      debugPrint('タスク締切統計の取得中にエラーが発生しました: $e');
      return TaskDeadlineStats.empty();
    }
  }

  // === プライベートメソッド ===










}

/// タスク締切統計
class TaskDeadlineStats {
  final int pendingNotifications;
  final int todayTasks;
  final int overdueTasks;
  final int completedTasks;
  final DateTime lastUpdate;

  const TaskDeadlineStats({
    required this.pendingNotifications,
    required this.todayTasks,
    required this.overdueTasks,
    required this.completedTasks,
    required this.lastUpdate,
  });

  factory TaskDeadlineStats.empty() {
    return TaskDeadlineStats(
      pendingNotifications: 0,
      todayTasks: 0,
      overdueTasks: 0,
      completedTasks: 0,
      lastUpdate: DateTime.now(),
    );
  }

  double get completionRate {
    final totalTasks = todayTasks + overdueTasks + completedTasks;
    return totalTasks > 0 ? completedTasks / totalTasks : 0.0;
  }

  String get statusText {
    if (pendingNotifications == 0) return '通知予定なし';
    return '$pendingNotifications件の通知が予定されています';
  }

  Map<String, dynamic> toJson() {
    return {
      'pendingNotifications': pendingNotifications,
      'todayTasks': todayTasks,
      'overdueTasks': overdueTasks,
      'completedTasks': completedTasks,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }
} 