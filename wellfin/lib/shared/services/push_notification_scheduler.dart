import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:logger/logger.dart';
import '../providers/notification_settings_provider.dart' show notificationSettingsProvider;
import 'fcm_service.dart';

/// 📡 プッシュ通知スケジューラー
/// サーバーサイド通知配信管理・FCMサービス連携
class PushNotificationScheduler {
  static final PushNotificationScheduler _instance = PushNotificationScheduler._internal();
  factory PushNotificationScheduler() => _instance;
  PushNotificationScheduler._internal();

  static final Logger _logger = Logger();
  
  // Cloud Run Functions API URL（ビルド時に設定）
  static String get _baseUrl => const String.fromEnvironment(
    'WELLFIN_API_URL',
    defaultValue: 'http://localhost:8080', // ローカル開発用フォールバック
  );
  
  // APIキーを環境変数から取得
  static String get _apiKey => const String.fromEnvironment(
    'WELLFIN_API_KEY',
    defaultValue: 'dev-secret-key',
  );
  
  // APIキー認証ヘッダー（統一）
  static Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'X-API-Key': _apiKey,
    'X-App-Version': '1.0.0',
    'X-Platform': Platform.operatingSystem,
  };
  
  final FCMService _fcmService = FCMService();
  final http.Client _httpClient = http.Client();
  
  bool _isInitialized = false;
  String? _userId;
  String? _fcmToken;

  /// 初期化
  Future<bool> initialize({
    required String userId,
    required Ref ref,
  }) async {
    if (_isInitialized) return true;

    try {
      _userId = userId;

      // FCMサービス初期化
      final fcmInitialized = await _fcmService.initialize(
        onMessageReceived: _onPushNotificationReceived,
        onMessageOpenedApp: _onPushNotificationOpened,
        onTokenRefresh: _onTokenRefresh,
      );

      if (!fcmInitialized) {
        _logger.e('FCMサービスの初期化に失敗しました');
        return false;
      }

      // FCMトークン取得
      _fcmToken = _fcmService.currentToken;
      
      if (_fcmToken == null) {
        _logger.e('FCMトークンの取得に失敗しました');
        return false;
      }

      // トークンをサーバーに登録
      final tokenRegistered = await _registerTokenToServer();
      if (!tokenRegistered) {
        _logger.e('サーバーへのトークン登録に失敗しました');
        return false;
      }

      // 通知設定に基づくトピック購読
      await _setupTopicSubscriptions(ref);

      _isInitialized = true;
      _logger.i('PushNotificationScheduler初期化完了');
      return true;
    } catch (e) {
      _logger.e('PushNotificationScheduler初期化エラー: $e');
      return false;
    }
  }

  /// 習慣リマインダーのプッシュ通知をスケジュール
  Future<bool> scheduleHabitReminderPush({
    required String habitName,
    required DateTime scheduledTime,
    String? customMessage,
  }) async {
    if (!_isInitialized || _userId == null) return false;

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/push-notifications/habit-reminder'),
        headers: _authHeaders,
        body: jsonEncode({
          'userId': _userId,
          'habitName': habitName,
          'reminderTime': scheduledTime.toIso8601String(),
          'customMessage': customMessage,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('習慣リマインダープッシュ通知スケジュール成功: ${result['messageId']}');
        return true;
      } else {
        debugPrint('習慣リマインダープッシュ通知スケジュール失敗: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('習慣リマインダープッシュ通知スケジュールエラー: $e');
      return false;
    }
  }

  /// タスク締切アラートのプッシュ通知をスケジュール
  Future<bool> scheduleTaskDeadlinePush({
    required String taskName,
    required DateTime dueDate,
    required String priority,
    required int beforeMinutes,
  }) async {
    if (!_isInitialized || _userId == null) return false;

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/push-notifications/task-deadline'),
        headers: _authHeaders,
        body: jsonEncode({
          'userId': _userId,
          'taskName': taskName,
          'dueDate': dueDate.toIso8601String(),
          'priority': priority,
          'beforeMinutes': beforeMinutes,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('タスク締切プッシュ通知スケジュール成功: ${result['messageId']}');
        return true;
      } else {
        debugPrint('タスク締切プッシュ通知スケジュール失敗: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('タスク締切プッシュ通知スケジュールエラー: $e');
      return false;
    }
  }

  /// AI週次レポートのプッシュ通知をスケジュール
  Future<bool> scheduleAIReportPush({
    required String reportType,
    required String summary,
    Map<String, dynamic>? reportData,
  }) async {
    if (!_isInitialized || _userId == null) return false;

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/push-notifications/ai-report'),
        headers: _authHeaders,
        body: jsonEncode({
          'userId': _userId,
          'reportType': reportType,
          'summary': summary,
          'reportData': reportData,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('AIレポートプッシュ通知スケジュール成功: ${result['messageId']}');
        return true;
      } else {
        debugPrint('AIレポートプッシュ通知スケジュール失敗: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('AIレポートプッシュ通知スケジュールエラー: $e');
      return false;
    }
  }

  /// 即座プッシュ通知送信
  Future<bool> sendImmediatePush({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    Map<String, dynamic>? options,
  }) async {
    if (!_isInitialized || _fcmToken == null) return false;

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/push-notifications/send'),
        headers: _authHeaders,
        body: jsonEncode({
          'token': _fcmToken,
          'title': title,
          'body': body,
          'data': data,
          'options': options,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('即座プッシュ通知送信成功: ${result['messageId']}');
        return true;
      } else {
        debugPrint('即座プッシュ通知送信失敗: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('即座プッシュ通知送信エラー: $e');
      return false;
    }
  }

  /// プッシュ通知履歴を取得
  Future<List<PushNotificationHistory>> getNotificationHistory({
    int limit = 50,
    String? startAfter,
  }) async {
    if (!_isInitialized || _userId == null) return [];

    try {
      final uri = Uri.parse('$_baseUrl/push-notifications/history/$_userId').replace(
        queryParameters: {
          'limit': limit.toString(),
          if (startAfter != null) 'startAfter': startAfter,
        },
      );

      final response = await _httpClient.get(uri);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final historyList = List<Map<String, dynamic>>.from(result['history']);
        
        return historyList.map((json) => PushNotificationHistory.fromJson(json)).toList();
      } else {
        debugPrint('プッシュ通知履歴取得失敗: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('プッシュ通知履歴取得エラー: $e');
      return [];
    }
  }

  /// プッシュ通知統計を取得
  Future<PushNotificationStats> getNotificationStats() async {
    try {
      final history = await getNotificationHistory();
      final fcmStats = _fcmService.getStats();
      
      // 今日の通知数を計算
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayNotifications = history.where((h) => 
        h.sentAt.isAfter(todayStart)
      ).length;

      // 今週の通知数を計算
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final weekNotifications = history.where((h) => 
        h.sentAt.isAfter(weekStartDate)
      ).length;

      return PushNotificationStats(
        totalNotifications: history.length,
        todayNotifications: todayNotifications,
        weekNotifications: weekNotifications,
        fcmToken: fcmStats.currentToken,
        subscriptionCount: fcmStats.subscriptionCount,
        isActive: _isInitialized && fcmStats.hasToken,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      debugPrint('プッシュ通知統計取得エラー: $e');
      return PushNotificationStats.empty();
    }
  }

  /// トピック購読設定を更新
  Future<bool> updateTopicSubscriptions(Ref ref) async {
    if (!_isInitialized) return false;

    try {
      await _setupTopicSubscriptions(ref);
      return true;
    } catch (e) {
      debugPrint('トピック購読更新エラー: $e');
      return false;
    }
  }

  // === プライベートメソッド ===

  /// サーバーにFCMトークンを登録
  Future<bool> _registerTokenToServer() async {
    if (_userId == null || _fcmToken == null) return false;

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/push-notifications/register-token'),
        headers: _authHeaders,
        body: jsonEncode({
          'userId': _userId,
          'fcmToken': _fcmToken,
          'platform': 'flutter',
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('FCMトークンのサーバー登録成功');
        return true;
      } else {
        debugPrint('FCMトークンのサーバー登録失敗: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('FCMトークンのサーバー登録エラー: $e');
      return false;
    }
  }

  /// 通知設定に基づくトピック購読設定
  Future<void> _setupTopicSubscriptions(Ref ref) async {
    try {
      final notificationSettings = ref.read(notificationSettingsProvider);
      
      // 全般的な通知トピック
      if (notificationSettings.overallSettings.notificationsEnabled) {
        await _fcmService.subscribeToTopic('general_notifications');
      } else {
        await _fcmService.unsubscribeFromTopic('general_notifications');
      }

      // 習慣関連トピック
      if (notificationSettings.habitSettings.enabled) {
        await _fcmService.subscribeToTopic('habit_notifications');
      } else {
        await _fcmService.unsubscribeFromTopic('habit_notifications');
      }

      // タスク関連トピック
      if (notificationSettings.taskSettings.deadlineAlertsEnabled) {
        await _fcmService.subscribeToTopic('task_notifications');
      } else {
        await _fcmService.unsubscribeFromTopic('task_notifications');
      }

      // AI分析関連トピック
      if (notificationSettings.aiSettings.weeklyReportEnabled) {
        await _fcmService.subscribeToTopic('ai_notifications');
      } else {
        await _fcmService.unsubscribeFromTopic('ai_notifications');
      }

      debugPrint('トピック購読設定完了');
    } catch (e) {
      debugPrint('トピック購読設定エラー: $e');
    }
  }

  /// プッシュ通知受信時のコールバック
  void _onPushNotificationReceived(dynamic message) {
    debugPrint('プッシュ通知受信: ${message.toString()}');
    
    // TODO: アプリ内での通知処理
    // - 通知カウンターの更新
    // - UI状態の更新
    // - 必要に応じて画面遷移
  }

  /// プッシュ通知タップ時のコールバック
  void _onPushNotificationOpened(dynamic message) {
    debugPrint('プッシュ通知からアプリ起動: ${message.toString()}');
    
    // TODO: 通知タップ時の処理
    // - 適切な画面への遷移
    // - 関連データの読み込み
    // - ユーザーアクションの実行
  }

  /// FCMトークン更新時のコールバック
  void _onTokenRefresh(String? newToken) {
    debugPrint('FCMトークン更新: $newToken');
    
    if (newToken != null) {
      _fcmToken = newToken;
      // サーバーに新しいトークンを送信
      _registerTokenToServer();
    }
  }

  /// リソースクリーンアップ
  Future<void> dispose() async {
    _httpClient.close();
    _isInitialized = false;
    debugPrint('PushNotificationSchedulerリソースクリーンアップ完了');
  }
}

/// プッシュ通知履歴
class PushNotificationHistory {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime sentAt;
  final String status;

  const PushNotificationHistory({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.sentAt,
    required this.status,
  });

  factory PushNotificationHistory.fromJson(Map<String, dynamic> json) {
    return PushNotificationHistory(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      sentAt: DateTime.parse(json['sentAt']),
      status: json['status'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'data': data,
      'sentAt': sentAt.toIso8601String(),
      'status': status,
    };
  }
}

/// プッシュ通知統計
class PushNotificationStats {
  final int totalNotifications;
  final int todayNotifications;
  final int weekNotifications;
  final String? fcmToken;
  final int subscriptionCount;
  final bool isActive;
  final DateTime lastUpdate;

  const PushNotificationStats({
    required this.totalNotifications,
    required this.todayNotifications,
    required this.weekNotifications,
    this.fcmToken,
    required this.subscriptionCount,
    required this.isActive,
    required this.lastUpdate,
  });

  factory PushNotificationStats.empty() {
    return PushNotificationStats(
      totalNotifications: 0,
      todayNotifications: 0,
      weekNotifications: 0,
      fcmToken: null,
      subscriptionCount: 0,
      isActive: false,
      lastUpdate: DateTime.now(),
    );
  }

  bool get hasToken => fcmToken != null && fcmToken!.isNotEmpty;

  String get statusText {
    if (!isActive) return 'プッシュ通知無効';
    if (!hasToken) return 'トークン未取得';
    return 'プッシュ通知正常動作中';
  }

  Map<String, dynamic> toJson() {
    return {
      'totalNotifications': totalNotifications,
      'todayNotifications': todayNotifications,
      'weekNotifications': weekNotifications,
      'fcmToken': fcmToken,
      'subscriptionCount': subscriptionCount,
      'isActive': isActive,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }
} 