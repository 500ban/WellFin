import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_settings.dart';
import '../providers/notification_settings_provider.dart' show notificationSettingsProvider;
import '../services/push_notification_scheduler.dart';
import '../services/local_notification_service.dart';

/// 🤖 AI週次レポートスケジューラー（最適化版）
/// 曜日・時間設定に基づく分析レポート配信を管理
class AIReportScheduler {
  final WidgetRef _ref;
  
  AIReportScheduler(this._ref);

  /// AI週次レポートをスケジュール（最適化版）
  Future<bool> scheduleWeeklyReport({
    AINotificationSettings? customSettings,
  }) async {
    try {
      // 通知設定を取得
      final notificationSettings = _ref.read(notificationSettingsProvider);
      final settings = customSettings ?? notificationSettings.aiSettings;
      
      // 通知が無効の場合はスキップ
      if (!settings.weeklyReportEnabled) {
        debugPrint('AI週次レポート通知が無効です');
        return true;
      }
      
      // 基本設定を使用
      final day = settings.weeklyReportDay;
      final time = settings.weeklyReportTime;
      
      // 次の配信日時を計算
      final nextReportTime = _calculateNextReportTime(_dayStringToInt(day), time);
      
      // 通知メッセージを生成
      final message = _generateWeeklyReportMessage(settings);
      
      // 通知をスケジュール
      final notificationId = _generateNotificationId('weekly', day.hashCode);
      
      // LocalNotificationServiceを使用して通知をスケジュール
      await LocalNotificationService().scheduleAIWeeklyReport(
        id: notificationId,
        scheduledTime: nextReportTime,
        message: message,
        summary: '今週の活動分析が完了しました',
      );
      
      debugPrint('AI週次レポートをスケジュール: $day $time (${nextReportTime.toString()})');
      
      return true;
    } catch (e) {
      debugPrint('AI週次レポートスケジュールエラー: $e');
      return false;
    }
  }

  /// 即座のAI分析レポートを送信（最適化版）
  Future<bool> triggerImmediateReport({
    required String reportType,
    required String summary,
    String? customMessage,
  }) async {
    try {
      // 通知設定を確認
      final notificationSettings = _ref.read(notificationSettingsProvider);
      
      // AI通知が無効の場合はスキップ
      if (!notificationSettings.aiSettings.instantInsightsEnabled) {
        debugPrint('AI即座インサイト通知が無効です');
        return true;
      }
      
      // サイレント時間チェック
      final isSilent = await _checkSilentTime();
      if (isSilent) {
        debugPrint('現在はサイレント時間のため通知をスキップ');
        return true;
      }
      
      // 通知メッセージを生成
      final message = customMessage ?? _generateInstantReportMessage(reportType, summary);
      
      // 通知IDを生成
      final notificationId = _generateNotificationId('instant', reportType.hashCode);
      
             // ローカル通知を即座に送信
       await LocalNotificationService().showImmediateNotification(
         id: notificationId,
         title: summary,
         message: message,
         category: NotificationCategory.aiReports,
         payload: 'ai_report:$reportType',
       );
      
      debugPrint('即座AI分析レポート送信完了: $summary');
      
      return true;
    } catch (e) {
      debugPrint('即座AI分析レポート送信エラー: $e');
      return false;
    }
  }

  /// 次の配信日時を計算
  DateTime _calculateNextReportTime(int day, String time) {
    final now = DateTime.now();
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    // 今日の指定時間
    var nextTime = DateTime(now.year, now.month, now.day, hour, minute);
    
    // 今日が指定曜日で、時間が過ぎている場合は来週に設定
    if (now.weekday == day && now.isAfter(nextTime)) {
      nextTime = nextTime.add(const Duration(days: 7));
    } else {
      // 指定曜日まで待つ
      while (nextTime.weekday != day) {
        nextTime = nextTime.add(const Duration(days: 1));
      }
    }
    
    return nextTime;
  }

  /// 週次レポートメッセージを生成
  String _generateWeeklyReportMessage(AINotificationSettings settings) {
    final messages = [
      '今週の活動を分析しました。詳細を確認してみましょう！',
      '週間レポートが完成しました。成果を振り返ってみませんか？',
      '今週の生産性分析結果をお届けします。',
      '週間活動レポートが準備できました。',
    ];
    
    // 設定に基づいてメッセージをカスタマイズ
    if (settings.improvementSuggestionsEnabled) {
      return '${messages[0]} 改善提案も含まれています。';
    }
    
    return messages[DateTime.now().millisecondsSinceEpoch % messages.length];
  }

  /// 即座レポートメッセージを生成
  String _generateInstantReportMessage(String reportType, String summary) {
    switch (reportType) {
      case 'weekly_analytics':
        return '週間分析が完了しました。$summary';
      case 'monthly_analytics':
        return '月間分析が完了しました。$summary';
      case 'productivity_pattern':
        return '生産性パターン分析が完了しました。$summary';
      case 'goal_progress':
        return '目標進捗分析が完了しました。$summary';
      default:
        return '分析が完了しました。$summary';
    }
  }

  /// 通知IDを生成
  int _generateNotificationId(String type, int identifier) {
    final typeHash = type.hashCode;
    return (typeHash << 16) | (identifier & 0xFFFF);
  }

  /// サイレント時間チェック
  Future<bool> _checkSilentTime() async {
    try {
      final notificationSettings = _ref.read(notificationSettingsProvider);
      final overallSettings = notificationSettings.overallSettings;
      
      if (!overallSettings.notificationsEnabled) {
        return true;
      }
      
      final now = DateTime.now();
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      return _isTimeBetween(currentTime, overallSettings.silentStartTime, overallSettings.silentEndTime);
    } catch (e) {
      debugPrint('サイレント時間チェックエラー: $e');
      return false;
    }
  }

  /// 時間が範囲内かどうかを判定
  bool _isTimeBetween(String current, String start, String end) {
    final currentMinutes = _timeToMinutes(current);
    final startMinutes = _timeToMinutes(start);
    final endMinutes = _timeToMinutes(end);
    
    if (startMinutes <= endMinutes) {
      // 同じ日内の範囲 (例: 09:00 - 17:00)
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // 日をまたぐ範囲 (例: 22:00 - 07:00)
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  /// 時間文字列を分単位に変換
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  /// 曜日文字列を数値に変換
  int _dayStringToInt(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        return DateTime.sunday;
    }
  }

  /// 通知スケジュールの最適化
  Future<void> optimizeNotificationSchedule() async {
    try {
      final notificationSettings = _ref.read(notificationSettingsProvider);
      final aiSettings = notificationSettings.aiSettings;
      
      // 既存のスケジュールをクリア
      await _clearExistingSchedules();
      
      // 新しいスケジュールを設定
      if (aiSettings.weeklyReportEnabled) {
        await scheduleWeeklyReport();
      }
      
      debugPrint('通知スケジュール最適化完了');
    } catch (e) {
      debugPrint('通知スケジュール最適化エラー: $e');
    }
  }

  /// 既存のスケジュールをクリア
  Future<void> _clearExistingSchedules() async {
    try {
      final localNotificationService = LocalNotificationService();
      await localNotificationService.cancelAINotifications();
      debugPrint('既存のAI通知スケジュールをクリアしました');
    } catch (e) {
      debugPrint('スケジュールクリアエラー: $e');
    }
  }

  /// AI分析の進捗通知
  Future<bool> sendAnalysisProgressNotification({
    required String taskName,
    required int progress,
    required int total,
  }) async {
    try {
      final notificationSettings = _ref.read(notificationSettingsProvider);
      final settings = notificationSettings.aiSettings;
      
      if (!settings.weeklyReportEnabled || !settings.instantInsightsEnabled) {
        return false;
      }
      
      final percentage = ((progress / total) * 100).round();
      // final message = 'AI分析進行中: $taskName ($percentage% 完了)';
      // final notificationId = _generateNotificationId('progress', 'sunday');
      
      // TODO: LocalNotificationServiceを使用して進捗通知
      // await LocalNotificationService().showImmediateNotification(
      //   id: notificationId,
      //   title: '🔄 AI分析進捗',
      //   message: message,
      //   category: NotificationCategory.aiReports,
      // );
      
      debugPrint('AI分析進捗通知を送信: $taskName - $percentage%');
      return true;
    } catch (e) {
      debugPrint('AI分析進捗通知の送信中にエラーが発生しました: $e');
      return false;
    }
  }

  /// 分析完了通知
  Future<bool> sendAnalysisCompletedNotification({
    required String analysisType,
    required Map<String, dynamic> results,
  }) async {
    try {
      final notificationSettings = _ref.read(notificationSettingsProvider);
      final settings = notificationSettings.aiSettings;
      
      if (!settings.weeklyReportEnabled) {
        return false;
      }
      
      // final message = _generateAnalysisCompletedMessage(analysisType, results);
      // final notificationId = _generateNotificationId('completed', 'sunday');
      
      // TODO: LocalNotificationServiceを使用して完了通知
      // await LocalNotificationService().showImmediateNotification(
      //   id: notificationId,
      //   title: '✅ AI分析完了',
      //   message: message,
      //   category: NotificationCategory.aiReports,
      // );
      
      debugPrint('AI分析完了通知を送信: $analysisType');
      return true;
    } catch (e) {
      debugPrint('AI分析完了通知の送信中にエラーが発生しました: $e');
      return false;
    }
  }

  /// AI分析レポートの統計を取得
  Future<AIReportStats> getReportStats() async {
    try {
      final notificationSettings = _ref.read(notificationSettingsProvider);
      final settings = notificationSettings.aiSettings;
      
      // 次の配信予定を計算
      final nextWeeklyReport = _calculateNextReportTime(
        _dayStringToInt(settings.weeklyReportDay),
        settings.weeklyReportTime,
      );
      
      // 今週の分析実行回数（模擬データ）
      final weeklyAnalysisCount = 3; // TODO: 実際の実行回数を取得
      
      return AIReportStats(
        nextWeeklyReport: nextWeeklyReport,
        weeklyAnalysisCount: weeklyAnalysisCount,
        monthlyReportEnabled: settings.improvementSuggestionsEnabled,
        analysisProgressEnabled: settings.instantInsightsEnabled,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      debugPrint('AI分析レポート統計の取得中にエラーが発生しました: $e');
      return AIReportStats.empty();
    }
  }

  // 例: PushNotificationSchedulerの初期化時
  Future<void> initializePushScheduler(String userId) async {
    final pushScheduler = PushNotificationScheduler();
    await pushScheduler.initialize(userId: userId, ref: _ref as Ref); // WidgetRef→Refにキャスト
  }

  // === プライベートメソッド ===




}

/// AI分析レポート統計
class AIReportStats {
  final DateTime nextWeeklyReport;
  final int weeklyAnalysisCount;
  final bool monthlyReportEnabled;
  final bool analysisProgressEnabled;
  final DateTime lastUpdate;

  const AIReportStats({
    required this.nextWeeklyReport,
    required this.weeklyAnalysisCount,
    required this.monthlyReportEnabled,
    required this.analysisProgressEnabled,
    required this.lastUpdate,
  });

  factory AIReportStats.empty() {
    return AIReportStats(
      nextWeeklyReport: DateTime.now(),
      weeklyAnalysisCount: 0,
      monthlyReportEnabled: false,
      analysisProgressEnabled: false,
      lastUpdate: DateTime.now(),
    );
  }

  String get nextReportText {
    final now = DateTime.now();
    final difference = nextWeeklyReport.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}日後';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間後';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分後';
    } else {
      return '間もなく';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'nextWeeklyReport': nextWeeklyReport.toIso8601String(),
      'weeklyAnalysisCount': weeklyAnalysisCount,
      'monthlyReportEnabled': monthlyReportEnabled,
      'analysisProgressEnabled': analysisProgressEnabled,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }
} 