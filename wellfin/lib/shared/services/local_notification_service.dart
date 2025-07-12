import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;


/// 📱 ローカル通知サービス
/// flutter_local_notifications基盤とチャンネル設定を管理
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  static const String _channelIdHabits = 'habit_reminders';
  static const String _channelIdTasks = 'task_deadlines';
  static const String _channelIdAI = 'ai_reports';
  static const String _channelIdGeneral = 'general';

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  
  /// 初期化
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // タイムゾーンデータの初期化
      tz.initializeTimeZones();
      
      // Android設定
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS設定 - 権限要求を有効化
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      // 通知プラグインの初期化
      final initialized = await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
      );
      
      if (initialized == true) {
        await _createNotificationChannels();
        
        // 🔔 通知権限を要求
        print('🔔 [Permission] Requesting notification permission...');
        final permissionStatus = await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
        print('🔔 [Permission] Permission request result: $permissionStatus');
        
        _isInitialized = true;
        return true;
      }
      
      return false;
    } catch (e) {
      print('LocalNotificationService initialization failed: $e');
      return false;
    }
  }

  /// 通知チャンネルの作成
  Future<void> _createNotificationChannels() async {
    final android = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      // 習慣リマインダーチャンネル
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdHabits,
          '習慣リマインダー',
          description: '習慣の実行を促すリマインダー通知',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
      
      // タスク締切チャンネル
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdTasks,
          'タスク締切アラート',
          description: 'タスクの締切を知らせるアラート通知',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
      
      // AI週次レポートチャンネル
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdAI,
          'AI分析レポート',
          description: '週次のAI分析レポート通知',
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: false,
          showBadge: true,
        ),
      );
      
      // 一般通知チャンネル
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdGeneral,
          '一般通知',
          description: '一般的な通知',
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: false,
          showBadge: true,
        ),
      );
    }
  }

  /// 習慣リマインダー通知をスケジュール
  Future<bool> scheduleHabitReminder({
    required int id,
    required String habitName,
    required DateTime scheduledTime,
    required String message,
    String? customSound,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final androidDetails = AndroidNotificationDetails(
        _channelIdHabits,
        '習慣リマインダー',
        channelDescription: '習慣の実行を促すリマインダー通知',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          message,
          contentTitle: '🌟 習慣リマインダー',
          summaryText: habitName,
        ),
        actions: [
          const AndroidNotificationAction(
            'complete',
            '完了',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          const AndroidNotificationAction(
            'snooze',
            '30分後',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      );
      
      const iosDetails = DarwinNotificationDetails(
        categoryIdentifier: 'habit_reminder',
        threadIdentifier: 'habit_reminders',
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        '🌟 習慣リマインダー',
        message,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'habit_reminder:$habitName',
      );
      
      return true;
    } catch (e) {
      print('Failed to schedule habit reminder: $e');
      return false;
    }
  }

  /// タスク締切アラート通知をスケジュール
  Future<bool> scheduleTaskDeadlineAlert({
    required int id,
    required String taskName,
    required DateTime scheduledTime,
    required String message,
    required TaskPriority priority,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final importance = priority == TaskPriority.high ? Importance.max : Importance.high;
      final priorityLevel = priority == TaskPriority.high ? Priority.max : Priority.high;
      
      final androidDetails = AndroidNotificationDetails(
        _channelIdTasks,
        'タスク締切アラート',
        channelDescription: 'タスクの締切を知らせるアラート通知',
        importance: importance,
        priority: priorityLevel,
        styleInformation: BigTextStyleInformation(
          message,
          contentTitle: '⏰ タスク締切アラート',
          summaryText: taskName,
        ),
        actions: [
          const AndroidNotificationAction(
            'complete',
            '完了',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          const AndroidNotificationAction(
            'snooze',
            '1時間後',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
        color: priority == TaskPriority.high ? const Color(0xFFFF5252) : const Color(0xFFFF9800),
      );
      
      const iosDetails = DarwinNotificationDetails(
        categoryIdentifier: 'task_deadline',
        threadIdentifier: 'task_deadlines',
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        '⏰ タスク締切アラート',
        message,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'task_deadline:$taskName',
      );
      
      return true;
    } catch (e) {
      print('Failed to schedule task deadline alert: $e');
      return false;
    }
  }

  /// AI週次レポート通知をスケジュール
  Future<bool> scheduleAIWeeklyReport({
    required int id,
    required DateTime scheduledTime,
    required String message,
    String? summary,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final androidDetails = AndroidNotificationDetails(
        _channelIdAI,
        'AI分析レポート',
        channelDescription: '週次のAI分析レポート通知',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        styleInformation: BigTextStyleInformation(
          message,
          contentTitle: '🤖 AI週次レポート',
          summaryText: summary ?? '今週の活動分析が完了しました',
        ),
        actions: [
          const AndroidNotificationAction(
            'view',
            '詳細を見る',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
        color: const Color(0xFF9C27B0),
      );
      
      const iosDetails = DarwinNotificationDetails(
        categoryIdentifier: 'ai_report',
        threadIdentifier: 'ai_reports',
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        '🤖 AI週次レポート',
        message,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'ai_report:weekly',
      );
      
      return true;
    } catch (e) {
      print('Failed to schedule AI weekly report: $e');
      return false;
    }
  }

  /// 即座通知の表示
  Future<bool> showImmediateNotification({
    required int id,
    required String title,
    required String message,
    NotificationCategory category = NotificationCategory.general,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final channelId = _getChannelId(category);
      final channelName = _getChannelName(category);
      
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: _getChannelDescription(category),
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        styleInformation: BigTextStyleInformation(message),
      );
      
      const iosDetails = DarwinNotificationDetails();
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        message,
        notificationDetails,
        payload: payload,
      );
      
      return true;
    } catch (e) {
      print('Failed to show immediate notification: $e');
      return false;
    }
  }

  /// 通知をキャンセル
  Future<bool> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      return true;
    } catch (e) {
      print('Failed to cancel notification: $e');
      return false;
    }
  }

  /// 全通知をキャンセル
  Future<bool> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      return true;
    } catch (e) {
      print('Failed to cancel all notifications: $e');
      return false;
    }
  }

  /// 予定されている通知の一覧を取得
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      print('Failed to get pending notifications: $e');
      return [];
    }
  }

  /// 通知権限の状態を確認
  Future<bool?> checkAndRequestPermissions() async {
    await initialize();
    return await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  /// 通知権限の詳細情報を取得
  Future<Map<String, dynamic>> getPermissionDetails() async {
    await initialize();
    final status = await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    return {
      'hasPermission': status == true,
      'overallStatus': status?.toString() ?? 'unknown',
      'canOpenSettings': false,
      'shouldShowRationale': false,
      'statusDescription': status == true ? '許可済み' : '未許可',
      'disabledCategories': [],
      'lastChecked': DateTime.now().toIso8601String(),
    };
  }

  // === カテゴリ別通知管理 ===

  /// 習慣通知をすべてキャンセル
  Future<bool> cancelHabitNotifications() async {
    try {
      // 習慣通知のIDレンジ: 1000-1999
      for (int i = 1000; i < 2000; i++) {
        await _flutterLocalNotificationsPlugin.cancel(i);
      }
      return true;
    } catch (e) {
      print('Failed to cancel habit notifications: $e');
      return false;
    }
  }

  /// タスク通知をすべてキャンセル
  Future<bool> cancelTaskNotifications() async {
    try {
      // タスク通知のIDレンジ: 2000-2999
      for (int i = 2000; i < 3000; i++) {
        await _flutterLocalNotificationsPlugin.cancel(i);
      }
      return true;
    } catch (e) {
      print('Failed to cancel task notifications: $e');
      return false;
    }
  }

  /// AI通知をすべてキャンセル
  Future<bool> cancelAINotifications() async {
    try {
      // AI通知のIDレンジ: 3000-3999
      for (int i = 3000; i < 4000; i++) {
        await _flutterLocalNotificationsPlugin.cancel(i);
      }
      return true;
    } catch (e) {
      print('Failed to cancel AI notifications: $e');
      return false;
    }
  }

  /// 習慣通知を設定に基づいてスケジュール
  Future<bool> scheduleHabitNotifications(dynamic habitSettings) async {
    try {
      // まず既存の習慣通知をキャンセル
      await cancelHabitNotifications();
      
      // 習慣通知が無効の場合は何もしない
      if (habitSettings.enabled != true) {
        return true;
      }
      
      // TODO: 実際の習慣データを取得してスケジュールを設定
      // 現在はモック実装
      print('習慣通知スケジュール設定: enabled=${habitSettings.enabled}');
      
      return true;
    } catch (e) {
      print('Failed to schedule habit notifications: $e');
      return false;
    }
  }

  /// タスク通知を設定に基づいてスケジュール
  Future<bool> scheduleTaskNotifications(dynamic taskSettings) async {
    try {
      // まず既存のタスク通知をキャンセル
      await cancelTaskNotifications();
      
      // タスク通知が無効の場合は何もしない
      if (taskSettings.deadlineAlertsEnabled != true) {
        return true;
      }
      
      // TODO: 実際のタスクデータを取得してスケジュールを設定
      // 現在はモック実装
      print('タスク通知スケジュール設定: enabled=${taskSettings.deadlineAlertsEnabled}');
      
      return true;
    } catch (e) {
      print('Failed to schedule task notifications: $e');
      return false;
    }
  }

  /// AI通知を設定に基づいてスケジュール
  Future<bool> scheduleAINotifications(dynamic aiSettings) async {
    try {
      // まず既存のAI通知をキャンセル
      await cancelAINotifications();
      
      // AI通知が無効の場合は何もしない
      if (aiSettings.weeklyReportEnabled != true) {
        return true;
      }
      
      // TODO: AI週次レポートのスケジュールを設定
      // 現在はモック実装
      print('AI通知スケジュール設定: enabled=${aiSettings.weeklyReportEnabled}');
      
      return true;
    } catch (e) {
      print('Failed to schedule AI notifications: $e');
      return false;
    }
  }

  /// 通知統計を取得
  Future<NotificationStats> getNotificationStats() async {
    try {
      final pendingNotifications = await getPendingNotifications();
      
      int habitCount = 0;
      int taskCount = 0;
      int aiCount = 0;
      
      for (final notification in pendingNotifications) {
        final id = notification.id;
        if (id >= 1000 && id < 2000) {
          habitCount++;
        } else if (id >= 2000 && id < 3000) {
          taskCount++;
        } else if (id >= 3000 && id < 4000) {
          aiCount++;
        }
      }
      
      return NotificationStats(
        totalScheduled: pendingNotifications.length,
        totalHabits: habitCount,
        totalTasks: taskCount,
        totalAIReports: aiCount,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      print('Failed to get notification stats: $e');
      return NotificationStats(
        totalScheduled: 0,
        totalHabits: 0,
        totalTasks: 0,
        totalAIReports: 0,
        lastUpdate: DateTime.now(),
      );
    }
  }

  // === プライベートメソッド ===

  String _getChannelId(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.habitReminders:
        return _channelIdHabits;
      case NotificationCategory.taskDeadlines:
        return _channelIdTasks;
      case NotificationCategory.aiReports:
        return _channelIdAI;
      case NotificationCategory.general:
        return _channelIdGeneral;
    }
  }

  String _getChannelName(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.habitReminders:
        return '習慣リマインダー';
      case NotificationCategory.taskDeadlines:
        return 'タスク締切アラート';
      case NotificationCategory.aiReports:
        return 'AI分析レポート';
      case NotificationCategory.general:
        return '一般通知';
    }
  }

  String _getChannelDescription(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.habitReminders:
        return '習慣の実行を促すリマインダー通知';
      case NotificationCategory.taskDeadlines:
        return 'タスクの締切を知らせるアラート通知';
      case NotificationCategory.aiReports:
        return '週次のAI分析レポート通知';
      case NotificationCategory.general:
        return '一般的な通知';
    }
  }

  // === 通知応答ハンドラー ===

  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      print('Notification clicked: $payload');
      // TODO: 通知タップ時の処理を実装
    }
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      print('Background notification clicked: $payload');
      // TODO: バックグラウンド通知タップ時の処理を実装
    }
  }
}

/// 通知カテゴリ
enum NotificationCategory {
  habitReminders,
  taskDeadlines,
  aiReports,
  general,
}

/// タスク優先度
enum TaskPriority {
  low,
  medium,
  high,
}

/// 通知情報
class NotificationInfo {
  final int id;
  final String title;
  final String message;
  final DateTime scheduledTime;
  final NotificationCategory category;
  final String? payload;

  const NotificationInfo({
    required this.id,
    required this.title,
    required this.message,
    required this.scheduledTime,
    required this.category,
    this.payload,
  });
}

/// 通知統計情報
class NotificationStats {
  final int totalScheduled;
  final int totalHabits;
  final int totalTasks;
  final int totalAIReports;
  final DateTime lastUpdate;

  const NotificationStats({
    required this.totalScheduled,
    required this.totalHabits,
    required this.totalTasks,
    required this.totalAIReports,
    required this.lastUpdate,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalScheduled': totalScheduled,
      'totalHabits': totalHabits,
      'totalTasks': totalTasks,
      'totalAIReports': totalAIReports,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      totalScheduled: json['totalScheduled'] ?? 0,
      totalHabits: json['totalHabits'] ?? 0,
      totalTasks: json['totalTasks'] ?? 0,
      totalAIReports: json['totalAIReports'] ?? 0,
      lastUpdate: DateTime.parse(json['lastUpdate'] ?? DateTime.now().toIso8601String()),
    );
  }
} 