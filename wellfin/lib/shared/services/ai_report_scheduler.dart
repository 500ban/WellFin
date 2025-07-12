import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_settings.dart';
import '../providers/notification_settings_provider.dart';

/// 🤖 AI週次レポートスケジューラー
/// 曜日・時間設定に基づく分析レポート配信を管理
class AIReportScheduler {
  final Ref _ref;
  
  AIReportScheduler(this._ref);

  /// AI週次レポートをスケジュール
  Future<bool> scheduleWeeklyReport({
    AINotificationSettings? customSettings,
  }) async {
    try {
      // 通知設定を取得
      final notificationSettings = _ref.read(notificationSettingsProvider);
      final settings = customSettings ?? notificationSettings.aiSettings;
      
      // 通知が無効の場合はスキップ
      if (!settings.weeklyReportEnabled) {
        return true;
      }
      
      // 基本設定を使用
      final day = settings.weeklyReportDay;
      final time = settings.weeklyReportTime;
      
      // 次の配信日時を計算
      // final nextReportTime = _calculateNextReportTime(day, time);
      
      // 通知メッセージを生成
      // final message = _generateWeeklyReportMessage(settings);
      
      // 通知をスケジュール
      // final notificationId = _generateNotificationId('weekly', day);
      
      // TODO: LocalNotificationServiceを使用して通知をスケジュール
      // await LocalNotificationService().scheduleAIWeeklyReport(
      //   id: notificationId,
      //   scheduledTime: nextReportTime,
      //   message: message,
      //   summary: '今週の活動分析が完了しました',
      // );
      
      debugPrint('AI週次レポートをスケジュール: $day $time');
      
      return true;
    } catch (e) {
      debugPrint('AI週次レポートのスケジュール中にエラーが発生しました: $e');
      return false;
    }
  }

  /// AI週次レポートをキャンセル
  Future<bool> cancelWeeklyReport() async {
    try {
      // 各曜日の通知をキャンセル
      final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      for (final day in days) {
        // final notificationId = _generateNotificationId('weekly', day);
        
        // TODO: LocalNotificationServiceを使用して通知をキャンセル
        // await LocalNotificationService().cancelNotification(notificationId);
        
        debugPrint('AI週次レポートをキャンセル: $day');
      }
      
      return true;
    } catch (e) {
      debugPrint('AI週次レポートのキャンセル中にエラーが発生しました: $e');
      return false;
    }
  }

  /// 即座にAI分析レポートを配信
  Future<bool> triggerImmediateReport({
    required String reportType,
    required String summary,
    String? customMessage,
  }) async {
    try {
      final notificationSettings = _ref.read(notificationSettingsProvider);
      final settings = notificationSettings.aiSettings;
      
      if (!settings.weeklyReportEnabled) {
        return false;
      }
      
      // final message = customMessage ?? _generateImmediateReportMessage(reportType, summary);
      // final notificationId = _generateNotificationId('immediate', 'sunday');
      
      // TODO: LocalNotificationServiceを使用して即座通知
      // await LocalNotificationService().showImmediateNotification(
      //   id: notificationId,
      //   title: '🤖 AI分析レポート',
      //   message: message,
      //   category: NotificationCategory.aiReports,
      // );
      
      debugPrint('即座AI分析レポートを配信: $reportType');
      return true;
    } catch (e) {
      debugPrint('即座AI分析レポートの配信中にエラーが発生しました: $e');
      return false;
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
        settings.weeklyReportDay,
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

  // === プライベートメソッド ===



  /// 次のレポート時刻を計算
  DateTime _calculateNextReportTime(String day, String time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 時間を解析
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    // 基本時刻を設定
    final baseTime = DateTime(
      today.year,
      today.month,
      today.day,
      hour,
      minute,
    );
    
    // 曜日を数値に変換
    int targetWeekday;
    switch (day) {
      case 'monday':
        targetWeekday = DateTime.monday;
        break;
      case 'tuesday':
        targetWeekday = DateTime.tuesday;
        break;
      case 'wednesday':
        targetWeekday = DateTime.wednesday;
        break;
      case 'thursday':
        targetWeekday = DateTime.thursday;
        break;
      case 'friday':
        targetWeekday = DateTime.friday;
        break;
      case 'saturday':
        targetWeekday = DateTime.saturday;
        break;
      case 'sunday':
        targetWeekday = DateTime.sunday;
        break;
      default:
        targetWeekday = DateTime.sunday;
    }
    
    // 指定曜日の次の日付を計算
    final currentWeekday = today.weekday;
    final daysUntilTarget = (targetWeekday - currentWeekday) % 7;
    
    var targetDate = baseTime.add(Duration(days: daysUntilTarget));
    
    // 過去の時刻の場合は次の週にする
    if (targetDate.isBefore(now)) {
      targetDate = targetDate.add(const Duration(days: 7));
    }
    
    return targetDate;
  }






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