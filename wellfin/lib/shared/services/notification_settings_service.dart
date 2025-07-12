import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_settings.dart';

/// 🔔 通知設定サービス
/// SharedPreferencesによる設定データの永続化を管理
class NotificationSettingsService {
  static const String _keyPrefix = 'notification_settings_';
  static const String _overallKey = '${_keyPrefix}overall';
  static const String _habitKey = '${_keyPrefix}habits';
  static const String _taskKey = '${_keyPrefix}tasks';
  static const String _aiKey = '${_keyPrefix}ai';

  // === 全体設定 ===
  
  /// 全体通知設定を保存
  Future<void> saveOverallSettings(OverallNotificationSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(settings.toJson());
      await prefs.setString(_overallKey, json);
    } catch (e) {
      throw Exception('全体通知設定の保存に失敗しました: $e');
    }
  }

  /// 全体通知設定を読み込み
  Future<OverallNotificationSettings> loadOverallSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_overallKey);
      
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        return OverallNotificationSettings.fromJson(data);
      }
      
      // デフォルト設定を返す
      return OverallNotificationSettings.defaultSettings();
    } catch (e) {
      // エラー時はデフォルト設定を返す
      return OverallNotificationSettings.defaultSettings();
    }
  }

  // === 習慣設定 ===

  /// 習慣通知設定を保存
  Future<void> saveHabitSettings(HabitNotificationSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(settings.toJson());
      await prefs.setString(_habitKey, json);
    } catch (e) {
      throw Exception('習慣通知設定の保存に失敗しました: $e');
    }
  }

  /// 習慣通知設定を読み込み
  Future<HabitNotificationSettings> loadHabitSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_habitKey);
      
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        return HabitNotificationSettings.fromJson(data);
      }
      
      // デフォルト設定を返す
      return HabitNotificationSettings.defaultSettings();
    } catch (e) {
      // エラー時はデフォルト設定を返す
      return HabitNotificationSettings.defaultSettings();
    }
  }

  /// 特定の習慣のカスタム設定を保存
  Future<void> saveHabitCustomSettings(String habitId, HabitCustomSettings settings) async {
    try {
      final currentSettings = await loadHabitSettings();
      final updatedCustomSettings = Map<String, HabitCustomSettings>.from(currentSettings.customSettings);
      updatedCustomSettings[habitId] = settings;
      
      final updatedSettings = currentSettings.copyWith(customSettings: updatedCustomSettings);
      await saveHabitSettings(updatedSettings);
    } catch (e) {
      throw Exception('習慣カスタム設定の保存に失敗しました: $e');
    }
  }

  /// 特定の習慣のカスタム設定を削除
  Future<void> removeHabitCustomSettings(String habitId) async {
    try {
      final currentSettings = await loadHabitSettings();
      final updatedCustomSettings = Map<String, HabitCustomSettings>.from(currentSettings.customSettings);
      updatedCustomSettings.remove(habitId);
      
      final updatedSettings = currentSettings.copyWith(customSettings: updatedCustomSettings);
      await saveHabitSettings(updatedSettings);
    } catch (e) {
      throw Exception('習慣カスタム設定の削除に失敗しました: $e');
    }
  }

  // === タスク設定 ===

  /// タスク通知設定を保存
  Future<void> saveTaskSettings(TaskNotificationSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(settings.toJson());
      await prefs.setString(_taskKey, json);
    } catch (e) {
      throw Exception('タスク通知設定の保存に失敗しました: $e');
    }
  }

  /// タスク通知設定を読み込み
  Future<TaskNotificationSettings> loadTaskSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_taskKey);
      
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        return TaskNotificationSettings.fromJson(data);
      }
      
      // デフォルト設定を返す
      return TaskNotificationSettings.defaultSettings();
    } catch (e) {
      // エラー時はデフォルト設定を返す
      return TaskNotificationSettings.defaultSettings();
    }
  }

  /// 特定優先度のアラート設定を保存
  Future<void> savePriorityAlertSettings(String priority, PriorityAlertSettings settings) async {
    try {
      final currentSettings = await loadTaskSettings();
      final updatedPrioritySettings = Map<String, PriorityAlertSettings>.from(currentSettings.prioritySettings);
      updatedPrioritySettings[priority] = settings;
      
      final updatedSettings = currentSettings.copyWith(prioritySettings: updatedPrioritySettings);
      await saveTaskSettings(updatedSettings);
    } catch (e) {
      throw Exception('優先度アラート設定の保存に失敗しました: $e');
    }
  }

  // === AI設定 ===

  /// AI通知設定を保存
  Future<void> saveAISettings(AINotificationSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(settings.toJson());
      await prefs.setString(_aiKey, json);
    } catch (e) {
      throw Exception('AI通知設定の保存に失敗しました: $e');
    }
  }

  /// AI通知設定を読み込み
  Future<AINotificationSettings> loadAISettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_aiKey);
      
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        return AINotificationSettings.fromJson(data);
      }
      
      // デフォルト設定を返す
      return AINotificationSettings.defaultSettings();
    } catch (e) {
      // エラー時はデフォルト設定を返す
      return AINotificationSettings.defaultSettings();
    }
  }

  // === 統合設定 ===

  /// 全ての通知設定を一括読み込み
  Future<NotificationSettingsState> loadAllSettings() async {
    try {
      final overallSettings = await loadOverallSettings();
      final habitSettings = await loadHabitSettings();
      final taskSettings = await loadTaskSettings();
      final aiSettings = await loadAISettings();

      return NotificationSettingsState(
        isLoading: false,
        error: null,
        overallSettings: overallSettings,
        habitSettings: habitSettings,
        taskSettings: taskSettings,
        aiSettings: aiSettings,
      );
    } catch (e) {
      return NotificationSettingsState.error('設定の読み込みに失敗しました: $e');
    }
  }

  /// 全ての通知設定を一括保存
  Future<void> saveAllSettings(NotificationSettingsState state) async {
    try {
      await Future.wait([
        saveOverallSettings(state.overallSettings),
        saveHabitSettings(state.habitSettings),
        saveTaskSettings(state.taskSettings),
        saveAISettings(state.aiSettings),
      ]);
    } catch (e) {
      throw Exception('設定の保存に失敗しました: $e');
    }
  }

  // === 設定リセット ===

  /// 全ての通知設定をデフォルトにリセット
  Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 通知設定関連のキーをすべて削除
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      throw Exception('設定のリセットに失敗しました: $e');
    }
  }

  /// 特定の設定カテゴリをリセット
  Future<void> resetCategorySettings(String category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      switch (category) {
        case 'overall':
          await prefs.remove(_overallKey);
          break;
        case 'habits':
          await prefs.remove(_habitKey);
          break;
        case 'tasks':
          await prefs.remove(_taskKey);
          break;
        case 'ai':
          await prefs.remove(_aiKey);
          break;
        default:
          throw Exception('不明な設定カテゴリ: $category');
      }
    } catch (e) {
      throw Exception('設定カテゴリのリセットに失敗しました: $e');
    }
  }

  // === 設定の検証 ===

  /// 設定データの整合性を検証
  Future<bool> validateSettings() async {
    try {
      final state = await loadAllSettings();
      
      // 基本的な検証
      if (state.error != null) {
        return false;
      }
      
      // 時間形式の検証
      if (!_isValidTime(state.overallSettings.silentStartTime) ||
          !_isValidTime(state.overallSettings.silentEndTime)) {
        return false;
      }
      
      if (!_isValidTime(state.habitSettings.defaultTime)) {
        return false;
      }
      
      if (!_isValidTime(state.taskSettings.workingStart) ||
          !_isValidTime(state.taskSettings.workingEnd)) {
        return false;
      }
      
      if (!_isValidTime(state.aiSettings.weeklyReportTime)) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 時間形式の検証 (HH:MM)
  bool _isValidTime(String time) {
    final regex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    return regex.hasMatch(time);
  }

  // === 設定情報の取得 ===

  /// 設定の統計情報を取得
  Future<Map<String, dynamic>> getSettingsStats() async {
    try {
      final state = await loadAllSettings();
      
      return {
        'overall': {
          'enabled': state.overallSettings.notificationsEnabled,
          'silent_hours': '${state.overallSettings.silentStartTime} - ${state.overallSettings.silentEndTime}',
          'weekend_enabled': state.overallSettings.weekendNotificationsEnabled,
        },
        'habits': {
          'enabled': state.habitSettings.enabled,
          'default_time': state.habitSettings.defaultTime,
          'custom_settings_count': state.habitSettings.customSettings.length,
          'default_days_count': state.habitSettings.defaultDays.length,
        },
        'tasks': {
          'deadline_alerts': state.taskSettings.deadlineAlertsEnabled,
          'completion_celebration': state.taskSettings.completionCelebration,
          'alert_hours': state.taskSettings.alertHours,
          'working_hours': state.taskSettings.workingHoursOnly,
        },
        'ai': {
          'weekly_report': state.aiSettings.weeklyReportEnabled,
          'instant_insights': state.aiSettings.instantInsightsEnabled,
          'improvement_suggestions': state.aiSettings.improvementSuggestionsEnabled,
          'performance_alerts': state.aiSettings.performanceAlertsEnabled,
        },
      };
    } catch (e) {
      return {'error': 'Failed to get settings stats: $e'};
    }
  }

  // === 設定の有効性チェック ===

  /// 現在サイレント時間かどうかを判定
  Future<bool> isCurrentlySilent() async {
    try {
      final settings = await loadOverallSettings();
      final now = DateTime.now();
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      return _isTimeBetween(currentTime, settings.silentStartTime, settings.silentEndTime);
    } catch (e) {
      return false;
    }
  }

  /// 週末通知が有効かどうかを判定
  Future<bool> isWeekendNotificationEnabled() async {
    try {
      final settings = await loadOverallSettings();
      final now = DateTime.now();
      final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
      
      return !isWeekend || settings.weekendNotificationsEnabled;
    } catch (e) {
      return true; // エラー時は通知を許可
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
} 