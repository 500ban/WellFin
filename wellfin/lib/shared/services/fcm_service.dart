import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 🔔 Firebase Cloud Messaging サービス
/// プッシュ通知の受信・処理・トークン管理を担当
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  static const String _tokenKey = 'fcm_token';
  static const String _subscriptionsKey = 'fcm_subscriptions';
  static const String _notificationHistoryKey = 'fcm_notification_history';

  FirebaseMessaging? _firebaseMessaging;
  FlutterLocalNotificationsPlugin? _localNotificationsPlugin;
  
  String? _currentToken;
  bool _isInitialized = false;
  List<String> _subscriptions = [];
  List<FCMNotificationHistory> _notificationHistory = [];

  // コールバック関数
  Function(RemoteMessage)? _onMessageReceived;
  Function(RemoteMessage)? _onMessageOpenedApp;
  Function(String?)? _onTokenRefresh;

  /// 初期化
  Future<bool> initialize({
    Function(RemoteMessage)? onMessageReceived,
    Function(RemoteMessage)? onMessageOpenedApp,
    Function(String?)? onTokenRefresh,
  }) async {
    if (_isInitialized) return true;

    try {
      _firebaseMessaging = FirebaseMessaging.instance;
      _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

      // コールバック設定
      _onMessageReceived = onMessageReceived;
      _onMessageOpenedApp = onMessageOpenedApp;
      _onTokenRefresh = onTokenRefresh;

      // 権限要求
      final authStatus = await _requestPermissions();
      if (authStatus != AuthorizationStatus.authorized) {
        debugPrint('FCM権限が許可されていません: $authStatus');
        return false;
      }

      // 初期トークン取得
      _currentToken = await _firebaseMessaging!.getToken();
      debugPrint('FCM Token: $_currentToken');

      // トークンを保存
      await _saveToken(_currentToken);

      // 保存された設定を読み込み
      await _loadSettings();

      // リスナー設定
      await _setupListeners();

      // フォアグラウンドでの通知表示設定
      await _setupForegroundNotifications();

      _isInitialized = true;
      debugPrint('FCMService initialization completed');
      return true;
    } catch (e) {
      debugPrint('FCMService initialization failed: $e');
      return false;
    }
  }

  /// 権限要求
  Future<AuthorizationStatus> _requestPermissions() async {
    final settings = await _firebaseMessaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    return settings.authorizationStatus;
  }

  /// 現在のFCMトークンを取得
  String? get currentToken => _currentToken;

  /// FCMトークンの更新確認
  Future<String?> refreshToken() async {
    if (!_isInitialized) return null;

    try {
      final newToken = await _firebaseMessaging!.getToken();
      if (newToken != _currentToken) {
        _currentToken = newToken;
        await _saveToken(_currentToken);
        
        // コールバック実行
        _onTokenRefresh?.call(_currentToken);
        
        debugPrint('FCM Token updated: $_currentToken');
      }
      return _currentToken;
    } catch (e) {
      debugPrint('FCM Token refresh failed: $e');
      return null;
    }
  }

  /// トピック購読
  Future<bool> subscribeToTopic(String topic) async {
    if (!_isInitialized) return false;

    try {
      await _firebaseMessaging!.subscribeToTopic(topic);
      
      if (!_subscriptions.contains(topic)) {
        _subscriptions.add(topic);
        await _saveSubscriptions();
      }
      
      debugPrint('FCM subscribed to topic: $topic');
      return true;
    } catch (e) {
      debugPrint('FCM topic subscription failed: $e');
      return false;
    }
  }

  /// トピック購読解除
  Future<bool> unsubscribeFromTopic(String topic) async {
    if (!_isInitialized) return false;

    try {
      await _firebaseMessaging!.unsubscribeFromTopic(topic);
      
      _subscriptions.remove(topic);
      await _saveSubscriptions();
      
      debugPrint('FCM unsubscribed from topic: $topic');
      return true;
    } catch (e) {
      debugPrint('FCM topic unsubscription failed: $e');
      return false;
    }
  }

  /// 購読しているトピック一覧を取得
  List<String> get subscriptions => List.from(_subscriptions);

  /// 通知履歴を取得
  List<FCMNotificationHistory> get notificationHistory => List.from(_notificationHistory);

  /// 通知履歴をクリア
  Future<bool> clearNotificationHistory() async {
    try {
      _notificationHistory.clear();
      await _saveNotificationHistory();
      return true;
    } catch (e) {
      debugPrint('FCM notification history clear failed: $e');
      return false;
    }
  }

  /// FCMサービスの統計情報を取得
  FCMStats getStats() {
    return FCMStats(
      currentToken: _currentToken,
      subscriptionCount: _subscriptions.length,
      notificationCount: _notificationHistory.length,
      lastTokenRefresh: _notificationHistory.isNotEmpty 
          ? _notificationHistory.last.receivedAt 
          : null,
      isInitialized: _isInitialized,
    );
  }

  /// バックグラウンドで受信したメッセージを処理
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('FCM Background message received: ${message.messageId}');
    
    // 通知履歴に追加
    final history = FCMNotificationHistory.fromRemoteMessage(message);
    await _saveNotificationHistoryStatic(history);
    
    // 必要に応じて追加処理
    // TODO: バックグラウンドでの特別な処理があれば実装
  }

  // === プライベートメソッド ===

  /// リスナー設定
  Future<void> _setupListeners() async {
    // フォアグラウンドでメッセージを受信
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM Foreground message received: ${message.messageId}');
      
      // 通知履歴に追加
      final history = FCMNotificationHistory.fromRemoteMessage(message);
      _notificationHistory.add(history);
      _saveNotificationHistory();
      
      // ローカル通知として表示
      _showLocalNotification(message);
      
      // コールバック実行
      _onMessageReceived?.call(message);
    });

    // アプリが開かれたときのメッセージ処理
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM App opened from message: ${message.messageId}');
      
      // コールバック実行
      _onMessageOpenedApp?.call(message);
    });

    // トークン更新リスナー
    _firebaseMessaging!.onTokenRefresh.listen((String token) {
      debugPrint('FCM Token refreshed: $token');
      
      _currentToken = token;
      _saveToken(_currentToken);
      
      // コールバック実行
      _onTokenRefresh?.call(_currentToken);
    });

    // バックグラウンドメッセージハンドラー設定
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  }

  /// フォアグラウンド通知設定
  Future<void> _setupForegroundNotifications() async {
    await _localNotificationsPlugin!.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Local notification tapped: ${response.payload}');
        // TODO: 通知タップ時の処理
      },
    );
  }

  /// ローカル通知として表示
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'fcm_channel',
      'FCM通知',
      channelDescription: 'Firebase Cloud Messagingからの通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin!.show(
      message.hashCode,
      message.notification?.title ?? 'WellFin',
      message.notification?.body ?? '新しい通知があります',
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// 設定の保存・読み込み
  Future<void> _saveToken(String? token) async {
    if (token == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _saveSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_subscriptionsKey, _subscriptions);
  }

  Future<void> _saveNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _notificationHistory.map((h) => h.toJson()).toList();
    await prefs.setString(_notificationHistoryKey, jsonEncode(historyJson));
  }

  static Future<void> _saveNotificationHistoryStatic(FCMNotificationHistory history) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_notificationHistoryKey);
    
    List<Map<String, dynamic>> historyList = [];
    if (existingJson != null) {
      historyList = List<Map<String, dynamic>>.from(jsonDecode(existingJson));
    }
    
    historyList.add(history.toJson());
    await prefs.setString(_notificationHistoryKey, jsonEncode(historyList));
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 購読トピック読み込み
    _subscriptions = prefs.getStringList(_subscriptionsKey) ?? [];
    
    // 通知履歴読み込み
    final historyJson = prefs.getString(_notificationHistoryKey);
    if (historyJson != null) {
      final historyList = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
      _notificationHistory = historyList
          .map((json) => FCMNotificationHistory.fromJson(json))
          .toList();
    }
  }
}

/// FCM通知履歴
class FCMNotificationHistory {
  final String messageId;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  final DateTime receivedAt;
  final bool wasOpened;

  FCMNotificationHistory({
    required this.messageId,
    this.title,
    this.body,
    required this.data,
    required this.receivedAt,
    this.wasOpened = false,
  });

  factory FCMNotificationHistory.fromRemoteMessage(RemoteMessage message) {
    return FCMNotificationHistory(
      messageId: message.messageId ?? '',
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
      receivedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'title': title,
      'body': body,
      'data': data,
      'receivedAt': receivedAt.toIso8601String(),
      'wasOpened': wasOpened,
    };
  }

  factory FCMNotificationHistory.fromJson(Map<String, dynamic> json) {
    return FCMNotificationHistory(
      messageId: json['messageId'] ?? '',
      title: json['title'],
      body: json['body'],
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      receivedAt: DateTime.parse(json['receivedAt']),
      wasOpened: json['wasOpened'] ?? false,
    );
  }
}

/// FCM統計情報
class FCMStats {
  final String? currentToken;
  final int subscriptionCount;
  final int notificationCount;
  final DateTime? lastTokenRefresh;
  final bool isInitialized;

  FCMStats({
    required this.currentToken,
    required this.subscriptionCount,
    required this.notificationCount,
    this.lastTokenRefresh,
    required this.isInitialized,
  });

  bool get hasToken => currentToken != null && currentToken!.isNotEmpty;
  
  String get statusText {
    if (!isInitialized) return 'FCM未初期化';
    if (!hasToken) return 'トークン未取得';
    return 'FCM正常動作中';
  }

  Map<String, dynamic> toJson() {
    return {
      'currentToken': currentToken,
      'subscriptionCount': subscriptionCount,
      'notificationCount': notificationCount,
      'lastTokenRefresh': lastTokenRefresh?.toIso8601String(),
      'isInitialized': isInitialized,
    };
  }
} 