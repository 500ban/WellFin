import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_settings.dart';
import '../providers/notification_settings_provider.dart';
import '../../features/habits/domain/entities/habit.dart';

/// 通知曜日の定義
enum NotificationDays {
  monday,
  tuesday, 
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
  everyday,
}

/// 🔔 習慣リマインダースケジューラー
/// 個別習慣の時間・曜日設定に基づく通知スケジュール管理
class HabitReminderScheduler {
  
  final Ref _ref;
  
  HabitReminderScheduler(this._ref);

  /// 習慣のリマインダーをスケジュール
  Future<bool> scheduleHabitReminder({
    required Habit habit,
    HabitNotificationSettings? customSettings,
  }) async {
    try {
      // 通知設定を取得
      final notificationSettings = _ref.read(notificationSettingsProvider);
      final settings = customSettings ?? notificationSettings.habitSettings;
      
      // 通知が無効の場合はスキップ
      if (!settings.enabled) {
        return true;
      }
      
      // 習慣個別の設定を確認
      final habitSettings = settings.customSettings[habit.id];
      if (habitSettings != null && !habitSettings.enabled) {
        return true;
      }
      
      // 基本設定を使用
      final time = habitSettings?.customTime ?? settings.defaultTime;
      final days = habitSettings?.customDays ?? settings.defaultDays;
      
      // 通知メッセージを生成
      // final message = _generateReminderMessage(habit, settings);
      
      // 各曜日に対してスケジュール
      for (final dayInt in days) {
        final day = _convertIntToNotificationDay(dayInt);
        // final notificationId = _generateNotificationId(habit.id, day);
        // final scheduledTime = _calculateNextScheduledTime(time, day);
        
        // TODO: LocalNotificationServiceを使用して通知をスケジュール
        // await LocalNotificationService().scheduleHabitReminder(
        //   id: notificationId,
        //   habitName: habit.name,
        //   scheduledTime: scheduledTime,
        //   message: message,
        // );
        
                 debugPrint('習慣リマインダーをスケジュール: ${habit.title} - ${day.name} $time');
      }
      
      return true;
    } catch (e) {
      debugPrint('習慣リマインダーのスケジュール中にエラーが発生しました: $e');
      return false;
    }
  }

  /// 習慣のリマインダーをキャンセル
  Future<bool> cancelHabitReminder(String habitId) async {
    try {
      // 各曜日の通知をキャンセル
      for (final day in NotificationDays.values) {
        // final notificationId = _generateNotificationId(habitId, day);
        
        // TODO: LocalNotificationServiceを使用して通知をキャンセル
        // await LocalNotificationService().cancelNotification(notificationId);
        
        debugPrint('習慣リマインダーをキャンセル: $habitId - ${day.name}');
      }
      
      return true;
    } catch (e) {
      debugPrint('習慣リマインダーのキャンセル中にエラーが発生しました: $e');
      return false;
    }
  }

  /// 全習慣のリマインダーを更新
  Future<bool> updateAllHabitReminders(List<Habit> habits) async {
    try {
      int successCount = 0;
      
      for (final habit in habits) {
        // 既存の通知をキャンセル
        await cancelHabitReminder(habit.id);
        
        // 新しい通知をスケジュール
        final success = await scheduleHabitReminder(habit: habit);
        if (success) {
          successCount++;
        }
      }
      
      debugPrint('習慣リマインダー更新完了: $successCount/${habits.length}');
      return successCount == habits.length;
    } catch (e) {
      debugPrint('習慣リマインダーの更新中にエラーが発生しました: $e');
      return false;
    }
  }

  /// 特定の習慣のリマインダーを即座に実行
  Future<bool> triggerImmediateReminder(Habit habit) async {
    try {
      final notificationSettings = _ref.read(notificationSettingsProvider);
      final settings = notificationSettings.habitSettings;
      
      if (!settings.enabled) {
        return false;
      }
      
      // final message = _generateReminderMessage(habit, settings);
      // final notificationId = _generateNotificationId(habit.id, NotificationDays.everyday);
      
      // TODO: LocalNotificationServiceを使用して即座通知
      // await LocalNotificationService().showImmediateNotification(
      //   id: notificationId,
      //   title: '🌟 習慣リマインダー',
      //   message: message,
      //   category: NotificationCategory.habitReminders,
      // );
      
      debugPrint('即座習慣リマインダーを実行: ${habit.title}');
      return true;
    } catch (e) {
      debugPrint('即座習慣リマインダーの実行中にエラーが発生しました: $e');
      return false;
    }
  }

  /// 習慣リマインダーのスケジュール状況を取得
  Future<List<HabitReminderInfo>> getScheduledReminders() async {
    try {
      final reminders = <HabitReminderInfo>[];
      
      // TODO: LocalNotificationServiceから予定通知を取得
      // final pendingNotifications = await LocalNotificationService().getPendingNotifications();
      
      return reminders;
    } catch (e) {
      debugPrint('習慣リマインダーの取得中にエラーが発生しました: $e');
      return [];
    }
  }

  /// 週間習慣リマインダー統計を取得
  Future<HabitReminderStats> getWeeklyStats() async {
    try {
      final scheduledReminders = await getScheduledReminders();
      
      // 曜日別の統計を計算
      final dayStats = <NotificationDays, int>{};
      for (final day in NotificationDays.values) {
        dayStats[day] = scheduledReminders
            .where((reminder) => reminder.scheduledDays.contains(day))
            .length;
      }
      
      return HabitReminderStats(
        totalHabits: scheduledReminders.length,
        activeReminders: scheduledReminders.where((r) => r.isActive).length,
        dayStats: dayStats,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      debugPrint('習慣リマインダー統計の取得中にエラーが発生しました: $e');
      return HabitReminderStats.empty();
    }
  }

  // === プライベートメソッド ===



  /// 整数値をNotificationDayに変換
  NotificationDays _convertIntToNotificationDay(int dayInt) {
    switch (dayInt) {
      case 1:
        return NotificationDays.monday;
      case 2:
        return NotificationDays.tuesday;
      case 3:
        return NotificationDays.wednesday;
      case 4:
        return NotificationDays.thursday;
      case 5:
        return NotificationDays.friday;
      case 6:
        return NotificationDays.saturday;
      case 7:
        return NotificationDays.sunday;
      default:
        return NotificationDays.monday;
    }
  }






}

/// 習慣リマインダー情報
class HabitReminderInfo {
  final String habitId;
  final String habitName;
  final List<NotificationDays> scheduledDays;
  final String time;
  final bool isActive;
  final DateTime nextReminder;

  const HabitReminderInfo({
    required this.habitId,
    required this.habitName,
    required this.scheduledDays,
    required this.time,
    required this.isActive,
    required this.nextReminder,
  });

  factory HabitReminderInfo.fromJson(Map<String, dynamic> json) {
    return HabitReminderInfo(
      habitId: json['habitId'] ?? '',
      habitName: json['habitName'] ?? '',
      scheduledDays: (json['scheduledDays'] as List)
          .map((day) => NotificationDays.values[day])
          .toList(),
      time: json['time'] ?? '07:00',
      isActive: json['isActive'] ?? false,
      nextReminder: DateTime.parse(json['nextReminder']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'habitId': habitId,
      'habitName': habitName,
      'scheduledDays': scheduledDays.map((day) => day.index).toList(),
      'time': time,
      'isActive': isActive,
      'nextReminder': nextReminder.toIso8601String(),
    };
  }
}

/// 習慣リマインダー統計
class HabitReminderStats {
  final int totalHabits;
  final int activeReminders;
  final Map<NotificationDays, int> dayStats;
  final DateTime lastUpdate;

  const HabitReminderStats({
    required this.totalHabits,
    required this.activeReminders,
    required this.dayStats,
    required this.lastUpdate,
  });

  factory HabitReminderStats.empty() {
    return HabitReminderStats(
      totalHabits: 0,
      activeReminders: 0,
      dayStats: {},
      lastUpdate: DateTime.now(),
    );
  }

  double get activationRate {
    return totalHabits > 0 ? activeReminders / totalHabits : 0.0;
  }

  String get statusText {
    if (totalHabits == 0) return '習慣が登録されていません';
    if (activeReminders == 0) return 'アクティブなリマインダーがありません';
    return '$activeReminders/$totalHabits の習慣がアクティブです';
  }

  Map<String, dynamic> toJson() {
    return {
      'totalHabits': totalHabits,
      'activeReminders': activeReminders,
      'dayStats': dayStats.map((key, value) => MapEntry(key.name, value)),
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }
} 