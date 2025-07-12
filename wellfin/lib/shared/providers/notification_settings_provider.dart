import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_settings.dart';
import '../services/notification_settings_service.dart';
import '../services/local_notification_service.dart';
// import '../services/push_notification_scheduler.dart';

/// 🔔 通知設定プロバイダー
/// 設定の状態管理と変更時の即座反映を行う
class NotificationSettingsProvider extends StateNotifier<NotificationSettingsState> {
  final NotificationSettingsService _service;
  LocalNotificationService? _localNotificationService;
  
  // 🔧 Debounce機能でスケジュール更新を最適化
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);
  
  // 🔍 操作トラッキング用
  String _lastTrigger = 'unknown';
  
  // 🛡️ 循環参照防止
  bool _isUpdating = false;
  Set<String> _activeOperations = {};
  
  NotificationSettingsProvider(this._service)
      : super(NotificationSettingsState.initial()) {
    _initializeNotificationService();
    _loadSettings();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// 操作の重複チェック
  bool _canStartOperation(String operationId) {
    if (_activeOperations.contains(operationId)) {
      print('🔔 [GUARD] Operation $operationId already in progress, skipping...');
      return false;
    }
    _activeOperations.add(operationId);
    return true;
  }

  /// 操作の完了処理
  void _completeOperation(String operationId) {
    _activeOperations.remove(operationId);
  }

  /// 一意のセッションIDを生成
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000);
    return '${timestamp}_$random';
  }

  /// LocalNotificationServiceの初期化
  Future<void> _initializeNotificationService() async {
    try {
      _localNotificationService = LocalNotificationService();
      await _localNotificationService!.initialize();
    } catch (e) {
      print('LocalNotificationService初期化エラー: $e');
    }
  }

  /// 設定を読み込み
  Future<void> _loadSettings() async {
    try {
      state = NotificationSettingsState.loading();
      final settings = await _service.loadAllSettings();
      state = settings;
    } catch (e) {
      state = NotificationSettingsState.error('設定の読み込みに失敗しました: $e');
    }
  }

  /// 設定を再読み込み
  Future<void> refresh() async {
    await _loadSettings();
  }

  // === 🔧 Debounce機能付きスケジュール更新 ===

  /// Debounce機能付きでスケジュール更新をトリガー
  void _triggerScheduleUpdate([String trigger = 'unknown']) {
    // 🛡️ 更新中の場合はスキップ
    if (_isUpdating) {
      print('🔔 [GUARD] Schedule update skipped - already updating (trigger: $trigger)');
      return;
    }
    
    // 🛡️ 同じトリガーの重複チェック
    if (!_canStartOperation('schedule_update_$trigger')) {
      return;
    }
    
    _lastTrigger = trigger;
    
    // 既存のタイマーをキャンセル
    _debounceTimer?.cancel();
    
    // 新しいタイマーを設定（500ms後に実行）
    _debounceTimer = Timer(_debounceDuration, () {
      print('🔔 [Debounce] Executing delayed schedule update (triggered by: $_lastTrigger)...');
      _executeScheduleUpdate();
      _completeOperation('schedule_update_$trigger');
    });
    
    print('🔔 [Debounce] Schedule update triggered by: $trigger (delayed ${_debounceDuration.inMilliseconds}ms)');
  }

  /// 実際のスケジュール更新を実行
  Future<void> _executeScheduleUpdate() async {
    // 🛡️ 更新中フラグを設定
    if (_isUpdating) {
      print('🔔 [GUARD] Schedule update already in progress, skipping...');
      return;
    }
    
    _isUpdating = true;
    final sessionId = _generateSessionId();
    
    try {
      print('🔔 [Schedule-$sessionId] Executing notification schedule update (triggered by: $_lastTrigger)...');
      
      // 並行実行（但し、debounceで制御済み）
      await Future.wait([
        _scheduleHabitNotifications(sessionId),
        _scheduleTaskNotifications(sessionId),
        _scheduleAINotifications(sessionId),
      ]);
      
      print('🔔 [Schedule-$sessionId] All notifications scheduled successfully (triggered by: $_lastTrigger)');
    } catch (e) {
      print('🔔 [Schedule-$sessionId] スケジュール更新エラー (triggered by: $_lastTrigger): $e');
    } finally {
      // 🛡️ 更新中フラグをリセット
      _isUpdating = false;
    }
  }

  /// 手動でスケジュール更新を実行
  Future<void> forceScheduleUpdate() async {
    _debounceTimer?.cancel();
    await _executeScheduleUpdate();
  }

  // === 🔧 個別スケジューラー（シンプル化） ===

  Future<void> _scheduleHabitNotifications(String sessionId) async {
    try {
      if (_localNotificationService != null) {
        final settings = state.habitSettings;
        print('🔔 [Schedule-$sessionId] 習慣通知スケジュール設定: enabled=${settings.enabled}, defaultTime=${settings.defaultTime}, defaultDays=${settings.defaultDays}');
        
        await _localNotificationService!.scheduleHabitNotifications(settings);
        print('🔔 [Schedule-$sessionId] Habit notifications scheduled');
      }
    } catch (e) {
      print('🔔 [Schedule-$sessionId] 習慣通知スケジュールエラー: $e');
    }
  }

  Future<void> _scheduleTaskNotifications(String sessionId) async {
    try {
      if (_localNotificationService != null) {
        final settings = state.taskSettings;
        print('🔔 [Schedule-$sessionId] タスク通知スケジュール設定: enabled=${settings.deadlineAlertsEnabled}, alertHours=${settings.alertHours}, completionCelebration=${settings.completionCelebration}');
        
        await _localNotificationService!.scheduleTaskNotifications(settings);
        print('🔔 [Schedule-$sessionId] Task notifications scheduled');
      }
    } catch (e) {
      print('🔔 [Schedule-$sessionId] タスク通知スケジュールエラー: $e');
    }
  }

  Future<void> _scheduleAINotifications(String sessionId) async {
    try {
      if (_localNotificationService != null) {
        final settings = state.aiSettings;
        print('🔔 [Schedule-$sessionId] AI通知スケジュール設定: weeklyReportEnabled=${settings.weeklyReportEnabled}, day=${settings.weeklyReportDay}, time=${settings.weeklyReportTime}, instantInsights=${settings.instantInsightsEnabled}');
        
        await _localNotificationService!.scheduleAINotifications(settings);
        print('🔔 [Schedule-$sessionId] AI notifications scheduled');
      }
    } catch (e) {
      print('🔔 [Schedule-$sessionId] AI通知スケジュールエラー: $e');
    }
  }

  // === 全体設定 ===

  /// 全体通知設定を更新
  Future<void> updateOverallSettings(OverallNotificationSettings settings) async {
    final sessionId = _generateSessionId();
    final operationId = 'updateOverallSettings-$sessionId';
    
    // 🛡️ 重複実行チェック
    if (!_canStartOperation(operationId)) {
      return;
    }
    
    try {
      print('🔔 [API-$sessionId] updateOverallSettings called with: notificationsEnabled=${settings.notificationsEnabled}, weekendEnabled=${settings.weekendNotificationsEnabled}');
      await _service.saveOverallSettings(settings);
      state = state.copyWith(overallSettings: settings);
      // 🔧 自動スケジュール更新を削除し、debounce機能を使用
      _triggerScheduleUpdate('updateOverallSettings-$sessionId');
      print('🔔 [API-$sessionId] updateOverallSettings completed successfully');
    } catch (e) {
      print('🔔 [API-$sessionId] updateOverallSettings failed: $e');
      state = state.copyWith(error: '全体設定の更新に失敗しました: $e');
    } finally {
      // 🛡️ 操作完了処理
      _completeOperation(operationId);
    }
  }

  /// サイレント時間を更新
  Future<void> updateSilentHours(String startTime, String endTime) async {
    try {
      final updatedSettings = state.overallSettings.copyWith(
        silentStartTime: startTime,
        silentEndTime: endTime,
      );
      await updateOverallSettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: 'サイレント時間の更新に失敗しました: $e');
    }
  }

  /// 週末通知の有効/無効を切り替え
  Future<void> toggleWeekendNotifications(bool enabled) async {
    try {
      final updatedSettings = state.overallSettings.copyWith(
        weekendNotificationsEnabled: enabled,
      );
      await updateOverallSettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: '週末通知設定の更新に失敗しました: $e');
    }
  }

  /// 通知全体の有効/無効を切り替え
  Future<void> toggleNotifications(bool enabled) async {
    final sessionId = _generateSessionId();
    try {
      print('🔔 [API-$sessionId] 【OVERALL TOGGLE】 toggleNotifications called with: $enabled');
      final updatedSettings = state.overallSettings.copyWith(
        notificationsEnabled: enabled,
      );
      await updateOverallSettings(updatedSettings);
      print('🔔 [API-$sessionId] 【OVERALL TOGGLE】 toggleNotifications completed successfully');
    } catch (e) {
      print('🔔 [API-$sessionId] 【OVERALL TOGGLE】 toggleNotifications failed: $e');
      state = state.copyWith(error: '通知設定の更新に失敗しました: $e');
    }
  }

  // === 習慣設定 ===

  /// 習慣通知設定を更新
  Future<void> updateHabitSettings(HabitNotificationSettings settings) async {
    final sessionId = _generateSessionId();
    final operationId = 'updateHabitSettings-$sessionId';
    
    // 🛡️ 重複実行チェック
    if (!_canStartOperation(operationId)) {
      return;
    }
    
    try {
      print('🔔 [API-$sessionId] updateHabitSettings called with: enabled=${settings.enabled}, defaultTime=${settings.defaultTime}');
      await _service.saveHabitSettings(settings);
      state = state.copyWith(habitSettings: settings);
      // 🔧 自動スケジュール更新を削除し、debounce機能を使用
      _triggerScheduleUpdate('updateHabitSettings-$sessionId');
      print('🔔 [API-$sessionId] updateHabitSettings completed successfully');
    } catch (e) {
      print('🔔 [API-$sessionId] updateHabitSettings failed: $e');
      state = state.copyWith(error: '習慣設定の更新に失敗しました: $e');
    } finally {
      // 🛡️ 操作完了処理
      _completeOperation(operationId);
    }
  }

  /// 習慣通知の有効/無効を切り替え
  Future<void> toggleHabitNotifications(bool enabled) async {
    final sessionId = _generateSessionId();
    try {
      print('🔔 [API-$sessionId] 【HABIT TOGGLE】 toggleHabitNotifications called with: $enabled');
      final updatedSettings = state.habitSettings.copyWith(enabled: enabled);
      await updateHabitSettings(updatedSettings);
      print('🔔 [API-$sessionId] 【HABIT TOGGLE】 toggleHabitNotifications completed successfully');
    } catch (e) {
      print('🔔 [API-$sessionId] 【HABIT TOGGLE】 toggleHabitNotifications failed: $e');
      state = state.copyWith(error: '習慣通知設定の更新に失敗しました: $e');
    }
  }

  /// デフォルト習慣通知時間を更新
  Future<void> updateDefaultHabitTime(String time) async {
    try {
      final updatedSettings = state.habitSettings.copyWith(defaultTime: time);
      await updateHabitSettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: 'デフォルト通知時間の更新に失敗しました: $e');
    }
  }

  /// デフォルト習慣通知曜日を更新
  Future<void> updateDefaultHabitDays(List<int> days) async {
    try {
      final updatedSettings = state.habitSettings.copyWith(defaultDays: days);
      await updateHabitSettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: 'デフォルト通知曜日の更新に失敗しました: $e');
    }
  }

  /// 特定の習慣のカスタム設定を更新
  Future<void> updateHabitCustomSettings(String habitId, HabitCustomSettings settings) async {
    final sessionId = _generateSessionId();
    try {
      print('🔔 [API-$sessionId] updateHabitCustomSettings called for habitId: $habitId');
      await _service.saveHabitCustomSettings(habitId, settings);
      
      // 現在の設定を更新
      final updatedCustomSettings = Map<String, HabitCustomSettings>.from(state.habitSettings.customSettings);
      updatedCustomSettings[habitId] = settings;
      
      final updatedHabitSettings = state.habitSettings.copyWith(customSettings: updatedCustomSettings);
      state = state.copyWith(habitSettings: updatedHabitSettings);
      
      _triggerScheduleUpdate('updateHabitCustomSettings-$sessionId');
      print('🔔 [API-$sessionId] updateHabitCustomSettings completed successfully');
    } catch (e) {
      print('🔔 [API-$sessionId] updateHabitCustomSettings failed: $e');
      state = state.copyWith(error: '習慣カスタム設定の更新に失敗しました: $e');
    }
  }

  /// 特定の習慣のカスタム設定を削除
  Future<void> removeHabitCustomSettings(String habitId) async {
    final sessionId = _generateSessionId();
    try {
      print('🔔 [API-$sessionId] removeHabitCustomSettings called for habitId: $habitId');
      await _service.removeHabitCustomSettings(habitId);
      
      // 現在の設定を更新
      final updatedCustomSettings = Map<String, HabitCustomSettings>.from(state.habitSettings.customSettings);
      updatedCustomSettings.remove(habitId);
      
      final updatedHabitSettings = state.habitSettings.copyWith(customSettings: updatedCustomSettings);
      state = state.copyWith(habitSettings: updatedHabitSettings);
      
      _triggerScheduleUpdate('removeHabitCustomSettings-$sessionId');
      print('🔔 [API-$sessionId] removeHabitCustomSettings completed successfully');
    } catch (e) {
      print('🔔 [API-$sessionId] removeHabitCustomSettings failed: $e');
      state = state.copyWith(error: '習慣カスタム設定の削除に失敗しました: $e');
    }
  }

  // === タスク設定 ===

  /// タスク通知設定を更新
  Future<void> updateTaskSettings(TaskNotificationSettings settings) async {
    final sessionId = _generateSessionId();
    final operationId = 'updateTaskSettings-$sessionId';
    
    // 🛡️ 重複実行チェック
    if (!_canStartOperation(operationId)) {
      return;
    }
    
    try {
      print('🔔 [API-$sessionId] updateTaskSettings called with: deadlineAlerts=${settings.deadlineAlertsEnabled}, completionCelebration=${settings.completionCelebration}');
      await _service.saveTaskSettings(settings);
      state = state.copyWith(taskSettings: settings);
      _triggerScheduleUpdate('updateTaskSettings-$sessionId');
      print('🔔 [API-$sessionId] updateTaskSettings completed successfully');
    } catch (e) {
      print('🔔 [API-$sessionId] updateTaskSettings failed: $e');
      state = state.copyWith(error: 'タスク設定の更新に失敗しました: $e');
    } finally {
      // 🛡️ 操作完了処理
      _completeOperation(operationId);
    }
  }

  /// 締切アラートの有効/無効を切り替え
  Future<void> toggleDeadlineAlerts(bool enabled) async {
    final sessionId = _generateSessionId();
    try {
      print('🔔 [API-$sessionId] 【TASK TOGGLE】 toggleDeadlineAlerts called with: $enabled');
      final updatedSettings = state.taskSettings.copyWith(deadlineAlertsEnabled: enabled);
      await updateTaskSettings(updatedSettings);
      print('🔔 [API-$sessionId] 【TASK TOGGLE】 toggleDeadlineAlerts completed successfully');
    } catch (e) {
      print('🔔 [API-$sessionId] 【TASK TOGGLE】 toggleDeadlineAlerts failed: $e');
      state = state.copyWith(error: '締切アラート設定の更新に失敗しました: $e');
    }
  }

  /// 完了祝い通知の有効/無効を切り替え
  Future<void> toggleCompletionCelebration(bool enabled) async {
    try {
      final updatedSettings = state.taskSettings.copyWith(completionCelebration: enabled);
      await updateTaskSettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: '完了祝い設定の更新に失敗しました: $e');
    }
  }

  /// アラート時間を更新（何時間前に通知するか）
  Future<void> updateAlertHours(List<int> hours) async {
    try {
      final updatedSettings = state.taskSettings.copyWith(alertHours: hours);
      await updateTaskSettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: 'アラート時間の更新に失敗しました: $e');
    }
  }

  /// 作業時間限定通知の有効/無効を切り替え
  Future<void> toggleWorkingHoursOnly(bool enabled) async {
    try {
      final updatedSettings = state.taskSettings.copyWith(workingHoursOnly: enabled);
      await updateTaskSettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: '作業時間限定設定の更新に失敗しました: $e');
    }
  }

  /// 作業時間を更新
  Future<void> updateWorkingHours(String startTime, String endTime) async {
    try {
      final updatedSettings = state.taskSettings.copyWith(
        workingStart: startTime,
        workingEnd: endTime,
      );
      await updateTaskSettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: '作業時間の更新に失敗しました: $e');
    }
  }

  /// 特定優先度のアラート設定を更新
  Future<void> updatePriorityAlertSettings(String priority, PriorityAlertSettings settings) async {
    final sessionId = _generateSessionId();
    try {
      print('🔔 [API-$sessionId] updatePriorityAlertSettings called for priority: $priority');
      await _service.savePriorityAlertSettings(priority, settings);
      
      // 現在の設定を更新
      final updatedPrioritySettings = Map<String, PriorityAlertSettings>.from(state.taskSettings.prioritySettings);
      updatedPrioritySettings[priority] = settings;
      
      final updatedTaskSettings = state.taskSettings.copyWith(prioritySettings: updatedPrioritySettings);
      state = state.copyWith(taskSettings: updatedTaskSettings);
      
      _triggerScheduleUpdate('updatePriorityAlertSettings-$sessionId');
      print('🔔 [API-$sessionId] updatePriorityAlertSettings completed successfully');
    } catch (e) {
      print('🔔 [API-$sessionId] updatePriorityAlertSettings failed: $e');
      state = state.copyWith(error: '優先度アラート設定の更新に失敗しました: $e');
    }
  }

  // === AI設定 ===

  /// AI通知設定を更新
  Future<void> updateAISettings(AINotificationSettings settings) async {
    final sessionId = _generateSessionId();
    final operationId = 'updateAISettings-$sessionId';
    
    // 🛡️ 重複実行チェック
    if (!_canStartOperation(operationId)) {
      return;
    }
    
    try {
      print('🔔 [API-$sessionId] updateAISettings called with: weeklyReport=${settings.weeklyReportEnabled}, instantInsights=${settings.instantInsightsEnabled}');
      await _service.saveAISettings(settings);
      state = state.copyWith(aiSettings: settings);
      _triggerScheduleUpdate('updateAISettings-$sessionId');
      print('🔔 [API-$sessionId] updateAISettings completed successfully');
    } catch (e) {
      print('🔔 [API-$sessionId] updateAISettings failed: $e');
      state = state.copyWith(error: 'AI設定の更新に失敗しました: $e');
    } finally {
      // 🛡️ 操作完了処理
      _completeOperation(operationId);
    }
  }

  /// 週次レポートの有効/無効を切り替え
  Future<void> toggleWeeklyReport(bool enabled) async {
    final sessionId = _generateSessionId();
    try {
      print('🔔 [API-$sessionId] 【AI TOGGLE】 toggleWeeklyReport called with: $enabled');
      final updatedSettings = state.aiSettings.copyWith(weeklyReportEnabled: enabled);
      await updateAISettings(updatedSettings);
      print('🔔 [API-$sessionId] 【AI TOGGLE】 toggleWeeklyReport completed successfully');
    } catch (e) {
      print('🔔 [API-$sessionId] 【AI TOGGLE】 toggleWeeklyReport failed: $e');
      state = state.copyWith(error: '週次レポート設定の更新に失敗しました: $e');
    }
  }

  /// 週次レポートの時間を更新
  Future<void> updateWeeklyReportTime(String day, String time) async {
    try {
      final updatedSettings = state.aiSettings.copyWith(
        weeklyReportDay: day,
        weeklyReportTime: time,
      );
      await updateAISettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: '週次レポート時間の更新に失敗しました: $e');
    }
  }

  /// 即座の洞察の有効/無効を切り替え
  Future<void> toggleInstantInsights(bool enabled) async {
    try {
      final updatedSettings = state.aiSettings.copyWith(instantInsightsEnabled: enabled);
      await updateAISettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: '即座の洞察設定の更新に失敗しました: $e');
    }
  }

  /// 改善提案の有効/無効を切り替え
  Future<void> toggleImprovementSuggestions(bool enabled) async {
    try {
      final updatedSettings = state.aiSettings.copyWith(improvementSuggestionsEnabled: enabled);
      await updateAISettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: '改善提案設定の更新に失敗しました: $e');
    }
  }

  /// 改善提案の頻度を更新
  Future<void> updateSuggestionFrequency(String frequency) async {
    try {
      final updatedSettings = state.aiSettings.copyWith(suggestionFrequency: frequency);
      await updateAISettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: '改善提案頻度の更新に失敗しました: $e');
    }
  }

  // === 設定リセット ===

  /// 全ての設定をデフォルトにリセット
  Future<void> resetAllSettings() async {
    final sessionId = _generateSessionId();
    try {
      print('🔔 [API-$sessionId] 【RESET】 resetAllSettings called');
      await _service.resetToDefaults();
      state = NotificationSettingsState.initial();
      _triggerScheduleUpdate('resetAllSettings-$sessionId');
      print('🔔 [API-$sessionId] 【RESET】 resetAllSettings completed successfully');
    } catch (e) {
      print('🔔 [API-$sessionId] 【RESET】 resetAllSettings failed: $e');
      state = state.copyWith(error: '設定のリセットに失敗しました: $e');
    }
  }

  /// 特定カテゴリの設定をリセット
  Future<void> resetCategorySettings(String category) async {
    final sessionId = _generateSessionId();
    try {
      print('🔔 [API-$sessionId] 【RESET】 resetCategorySettings called for category: $category');
      await _service.resetCategorySettings(category);
      
      // 該当カテゴリの設定をデフォルトに更新
      switch (category) {
        case 'overall':
          state = state.copyWith(overallSettings: OverallNotificationSettings.defaultSettings());
          break;
        case 'habits':
          state = state.copyWith(habitSettings: HabitNotificationSettings.defaultSettings());
          break;
        case 'tasks':
          state = state.copyWith(taskSettings: TaskNotificationSettings.defaultSettings());
          break;
        case 'ai':
          state = state.copyWith(aiSettings: AINotificationSettings.defaultSettings());
          break;
      }
      
      _triggerScheduleUpdate('resetCategorySettings-$sessionId-$category');
      print('🔔 [API-$sessionId] 【RESET】 resetCategorySettings completed successfully for category: $category');
    } catch (e) {
      print('🔔 [API-$sessionId] 【RESET】 resetCategorySettings failed for category $category: $e');
      state = state.copyWith(error: '設定カテゴリのリセットに失敗しました: $e');
    }
  }

  // === 設定検証 ===

  /// 現在の設定を検証
  Future<bool> validateCurrentSettings() async {
    try {
      return await _service.validateSettings();
    } catch (e) {
      return false;
    }
  }

  /// 通知可能かどうかを判定
  Future<bool> canSendNotification() async {
    try {
      if (!state.overallSettings.notificationsEnabled) {
        return false;
      }
      
      final isSilent = await _service.isCurrentlySilent();
      if (isSilent) {
        return false;
      }
      
      final isWeekendEnabled = await _service.isWeekendNotificationEnabled();
      if (!isWeekendEnabled) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // === 設定統計 ===

  /// 設定統計を取得
  Future<Map<String, dynamic>> getSettingsStats() async {
    try {
      return await _service.getSettingsStats();
    } catch (e) {
      return {'error': 'Failed to get settings stats: $e'};
    }
  }

  // === 通知権限管理 ===

  /// 通知権限を要求
  Future<bool> requestNotificationPermission() async {
    try {
      if (_localNotificationService == null) return false;
      
      final result = await _localNotificationService!.checkAndRequestPermissions();
      return result == true;
    } catch (e) {
      print('通知権限の要求中にエラーが発生しました: $e');
      return false;
    }
  }

  /// 現在の通知権限状況を取得
  Future<Map<String, dynamic>> getPermissionStatus() async {
    try {
      if (_localNotificationService == null) {
        return {
          'hasPermission': false,
          'overallStatus': 'unknown',
          'canOpenSettings': false,
          'shouldShowRationale': false,
          'statusDescription': 'LocalNotificationServiceが初期化されていません',
          'disabledCategories': [],
          'lastChecked': DateTime.now().toIso8601String(),
        };
      }
      
      final details = await _localNotificationService!.getPermissionDetails();
      return {
        'hasPermission': details['hasPermission'] ?? false,
        'overallStatus': details['overallStatus'] ?? 'unknown',
        'canOpenSettings': details['canOpenSettings'] ?? false,
        'shouldShowRationale': details['shouldShowRationale'] ?? false,
        'statusDescription': details['statusDescription'] ?? '不明',
        'disabledCategories': details['disabledCategories'] ?? [],
        'lastChecked': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('通知権限の取得中にエラーが発生しました: $e');
      return {
        'hasPermission': false,
        'overallStatus': 'unknown',
        'canOpenSettings': false,
        'shouldShowRationale': false,
        'statusDescription': 'エラーが発生しました',
        'disabledCategories': [],
        'lastChecked': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  /// 通知統計を取得
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      if (_localNotificationService == null) {
        return {
          'totalScheduled': 0,
          'totalHabits': 0,
          'totalTasks': 0,
          'totalAIReports': 0,
          'lastUpdate': DateTime.now().toIso8601String(),
          'error': 'LocalNotificationServiceが初期化されていません',
        };
      }
      
      final stats = await _localNotificationService!.getNotificationStats();
      return stats.toJson();
    } catch (e) {
      print('通知統計の取得中にエラーが発生しました: $e');
      return {
        'totalScheduled': 0,
        'totalHabits': 0,
        'totalTasks': 0,
        'totalAIReports': 0,
        'lastUpdate': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  /// 通知権限の設定画面を開く
  Future<void> openNotificationSettings() async {
    try {
      // プラットフォーム固有の設定画面を開く
      // TODO: 実装が必要
      print('通知設定画面を開く機能は実装予定です');
    } catch (e) {
      print('通知設定画面の起動中にエラーが発生しました: $e');
    }
  }

  // === テスト機能 ===

  /// テスト用習慣通知を送信
  Future<bool> sendTestHabitNotification() async {
    try {
      if (_localNotificationService == null) return false;
      
      final success = await _localNotificationService!.showImmediateNotification(
        id: 9999,
        title: '🌟 テスト習慣リマインダー',
        message: 'これはテスト用の習慣通知です。通知設定が正常に動作しています。',
        payload: 'test_habit_notification',
      );
      
      if (success) {
        print('テスト習慣通知を送信しました');
      } else {
        print('テスト習慣通知の送信に失敗しました');
      }
      
      return success;
    } catch (e) {
      print('テスト習慣通知の送信中にエラーが発生しました: $e');
      return false;
    }
  }

  /// テスト用タスク通知を送信
  Future<bool> sendTestTaskNotification() async {
    try {
      if (_localNotificationService == null) return false;
      
      final success = await _localNotificationService!.showImmediateNotification(
        id: 9998,
        title: '⏰ テストタスク締切アラート',
        message: 'これはテスト用のタスク通知です。締切アラートが正常に動作しています。',
        payload: 'test_task_notification',
      );
      
      if (success) {
        print('テストタスク通知を送信しました');
      } else {
        print('テストタスク通知の送信に失敗しました');
      }
      
      return success;
    } catch (e) {
      print('テストタスク通知の送信中にエラーが発生しました: $e');
      return false;
    }
  }

  /// テスト用AI通知を送信
  Future<bool> sendTestAINotification() async {
    try {
      if (_localNotificationService == null) return false;
      
      final success = await _localNotificationService!.showImmediateNotification(
        id: 9997,
        title: '🤖 テストAI週次レポート',
        message: 'これはテスト用のAI通知です。週次レポートが正常に動作しています。',
        payload: 'test_ai_notification',
      );
      
      if (success) {
        print('テストAI通知を送信しました');
      } else {
        print('テストAI通知の送信に失敗しました');
      }
      
      return success;
    } catch (e) {
      print('テストAI通知の送信中にエラーが発生しました: $e');
      return false;
    }
  }

  /// 全てのテスト通知をキャンセル
  Future<void> cancelAllTestNotifications() async {
    try {
      if (_localNotificationService == null) return;
      
      await _localNotificationService!.cancelNotification(9999);
      await _localNotificationService!.cancelNotification(9998);
      await _localNotificationService!.cancelNotification(9997);
      print('全てのテスト通知をキャンセルしました');
    } catch (e) {
      print('テスト通知のキャンセル中にエラーが発生しました: $e');
    }
  }
}

/// 🔔 通知設定プロバイダーのインスタンス
final notificationSettingsServiceProvider = Provider<NotificationSettingsService>((ref) {
  return NotificationSettingsService();
});

/// 🔔 通知設定状態プロバイダー
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsProvider, NotificationSettingsState>((ref) {
  final service = ref.watch(notificationSettingsServiceProvider);
  return NotificationSettingsProvider(service);
});

// === 便利な派生プロバイダー ===

/// 通知が有効かどうかを監視
final notificationsEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(notificationSettingsProvider);
  return settings.overallSettings.notificationsEnabled;
});

/// 習慣通知が有効かどうかを監視
final habitNotificationsEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(notificationSettingsProvider);
  return settings.habitSettings.enabled;
});

/// タスク通知が有効かどうかを監視
final taskNotificationsEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(notificationSettingsProvider);
  return settings.taskSettings.deadlineAlertsEnabled;
});

/// AI通知が有効かどうかを監視
final aiNotificationsEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(notificationSettingsProvider);
  return settings.aiSettings.weeklyReportEnabled;
});

/// 現在通知可能かどうかを監視
final canSendNotificationProvider = FutureProvider<bool>((ref) async {
  final provider = ref.watch(notificationSettingsProvider.notifier);
  return await provider.canSendNotification();
});

/// 設定統計を監視
final settingsStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final provider = ref.watch(notificationSettingsProvider.notifier);
  return await provider.getSettingsStats();
});