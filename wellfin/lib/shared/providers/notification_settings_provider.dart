import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/notification_settings.dart';
import '../services/notification_settings_service.dart';
import '../services/local_notification_service.dart';
// import '../services/push_notification_scheduler.dart';

/// 🔔 通知設定�Eロバイダー
/// 設定�E状態管琁E��変更時�E即座反映を行う
class NotificationSettingsProvider extends StateNotifier<NotificationSettingsState> {
  final NotificationSettingsService _service;
  LocalNotificationService? _localNotificationService;
  final Logger _logger = Logger();
  
  // 🔧 Debounce機�Eでスケジュール更新を最適匁E
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);
  
  // 🔍 操作トラチE��ング用
  String _lastTrigger = 'unknown';
  
  // 🛡�E�E循環参�E防止
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

  /// 操作�E重褁E��ェチE��
  bool _canStartOperation(String operationId) {
    if (_activeOperations.contains(operationId)) {
      _logger.d('🔔 [GUARD] Operation $operationId already in progress, skipping...');
      return false;
    }
    _activeOperations.add(operationId);
    return true;
  }

  /// 操作�E完亁E�E琁E
  void _completeOperation(String operationId) {
    _activeOperations.remove(operationId);
  }

  /// 一意�EセチE��ョンIDを生戁E
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000);
    return '${timestamp}_$random';
  }

  /// LocalNotificationServiceの初期匁E
  Future<void> _initializeNotificationService() async {
    try {
      _localNotificationService = LocalNotificationService();
      await _localNotificationService!.initialize();
    } catch (e) {
      _logger.e('LocalNotificationService初期化エラー: $e');
    }
  }

  /// 設定を読み込み
  Future<void> _loadSettings() async {
    try {
      state = NotificationSettingsState.loading();
      final settings = await _service.loadAllSettings();
      state = settings;
    } catch (e) {
      state = NotificationSettingsState.error('設定�E読み込みに失敗しました: $e');
    }
  }

  /// 設定を再読み込み
  Future<void> refresh() async {
    await _loadSettings();
  }

  // === 🔧 Debounce機�E付きスケジュール更新 ===

  /// Debounce機�E付きでスケジュール更新をトリガー
  void _triggerScheduleUpdate([String trigger = 'unknown']) {
    // 🛡�E�E更新中の場合�EスキチE�E
    if (_isUpdating) {
      _logger.d('🔔 [GUARD] Schedule update skipped - already updating (trigger: $trigger)');
      return;
    }
    
    // 🛡�E�E同じトリガーの重褁E��ェチE��
    if (!_canStartOperation('schedule_update_$trigger')) {
      return;
    }
    
    _lastTrigger = trigger;
    
    // 既存�Eタイマ�Eをキャンセル
    _debounceTimer?.cancel();
    
    // 新しいタイマ�Eを設定！E00ms後に実行！E
    _debounceTimer = Timer(_debounceDuration, () {
      _logger.d('🔔 [Debounce] Executing delayed schedule update (triggered by: $_lastTrigger)...');
      _executeScheduleUpdate();
      _completeOperation('schedule_update_$trigger');
    });
    
    _logger.d('🔔 [Debounce] Schedule update triggered by: $trigger (delayed ${_debounceDuration.inMilliseconds}ms)');
  }

  /// 実際のスケジュール更新を実衁E
  Future<void> _executeScheduleUpdate() async {
    // 🛡�E�E更新中フラグを設宁E
    if (_isUpdating) {
      _logger.d('🔔 [GUARD] Schedule update already in progress, skipping...');
      return;
    }
    
    _isUpdating = true;
    final sessionId = _generateSessionId();
    
    try {
      _logger.d('🔔 [Schedule-$sessionId] Executing notification schedule update (triggered by: $_lastTrigger)...');
      
      // 並行実行（佁E��、debounceで制御済み�E�E
      await Future.wait([
        _scheduleHabitNotifications(sessionId),
        _scheduleTaskNotifications(sessionId),
        _scheduleAINotifications(sessionId),
      ]);
      
      _logger.d('🔔 [Schedule-$sessionId] All notifications scheduled successfully (triggered by: $_lastTrigger)');
    } catch (e) {
      _logger.e('🔔 [Schedule-$sessionId] スケジュール更新エラー (triggered by: $_lastTrigger): $e');
    } finally {
      // 🛡�E�E更新中フラグをリセチE��
      _isUpdating = false;
    }
  }

  /// 手動でスケジュール更新を実衁E
  Future<void> forceScheduleUpdate() async {
    _debounceTimer?.cancel();
    await _executeScheduleUpdate();
  }

  // === 🔧 個別スケジューラー�E�シンプル化！E===

  Future<void> _scheduleHabitNotifications(String sessionId) async {
    try {
      if (_localNotificationService != null) {
        final settings = state.habitSettings;
        _logger.d('🔔 [Schedule-$sessionId] 習�E通知スケジュール設宁E enabled=${settings.enabled}, defaultTime=${settings.defaultTime}, defaultDays=${settings.defaultDays}');
        
        await _localNotificationService!.scheduleHabitNotifications(settings);
        _logger.d('🔔 [Schedule-$sessionId] Habit notifications scheduled');
      }
    } catch (e) {
      _logger.e('🔔 [Schedule-$sessionId] 習�E通知スケジュールエラー: $e');
    }
  }

  Future<void> _scheduleTaskNotifications(String sessionId) async {
    try {
      if (_localNotificationService != null) {
        final settings = state.taskSettings;
        _logger.d('🔔 [Schedule-$sessionId] タスク通知スケジュール設宁E enabled=${settings.deadlineAlertsEnabled}, alertHours=${settings.alertHours}, completionCelebration=${settings.completionCelebration}');
        
        await _localNotificationService!.scheduleTaskNotifications(settings);
        _logger.d('🔔 [Schedule-$sessionId] Task notifications scheduled');
      }
    } catch (e) {
      _logger.e('🔔 [Schedule-$sessionId] タスク通知スケジュールエラー: $e');
    }
  }

  Future<void> _scheduleAINotifications(String sessionId) async {
    try {
      if (_localNotificationService != null) {
        final settings = state.aiSettings;
        _logger.d('🔔 [Schedule-$sessionId] AI通知スケジュール設宁E weeklyReportEnabled=${settings.weeklyReportEnabled}, day=${settings.weeklyReportDay}, time=${settings.weeklyReportTime}, instantInsights=${settings.instantInsightsEnabled}');
        
        await _localNotificationService!.scheduleAINotifications(settings);
        _logger.d('🔔 [Schedule-$sessionId] AI notifications scheduled');
      }
    } catch (e) {
      _logger.e('🔔 [Schedule-$sessionId] AI通知スケジュールエラー: $e');
    }
  }

  // === 全体設宁E===

  /// 全体通知設定を更新
  Future<void> updateOverallSettings(OverallNotificationSettings settings) async {
    final sessionId = _generateSessionId();
    final operationId = 'updateOverallSettings-$sessionId';
    
    // 🛡�E�E重褁E��行チェチE��
    if (!_canStartOperation(operationId)) {
      return;
    }
    
    try {
      _logger.d('🔔 [API-$sessionId] updateOverallSettings called with: notificationsEnabled=${settings.notificationsEnabled}, weekendEnabled=${settings.weekendNotificationsEnabled}');
      await _service.saveOverallSettings(settings);
      state = state.copyWith(overallSettings: settings);
      // 🔧 自動スケジュール更新を削除し、debounce機�Eを使用
      _triggerScheduleUpdate('updateOverallSettings-$sessionId');
      _logger.d('🔔 [API-$sessionId] updateOverallSettings completed successfully');
    } catch (e) {
      _logger.d('🔔 [API-$sessionId] updateOverallSettings failed: $e');
      state = state.copyWith(error: '全体設定�E更新に失敗しました: $e');
    } finally {
      // 🛡�E�E操作完亁E�E琁E
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
      state = state.copyWith(error: 'サイレント時間�E更新に失敗しました: $e');
    }
  }

  /// 週末通知の有効/無効を�Eり替ぁE
  Future<void> toggleWeekendNotifications(bool enabled) async {
    try {
      final updatedSettings = state.overallSettings.copyWith(
        weekendNotificationsEnabled: enabled,
      );
      await updateOverallSettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: '週末通知設定�E更新に失敗しました: $e');
    }
  }

  /// 通知全体�E有効/無効を�Eり替ぁE
  Future<void> toggleNotifications(bool enabled) async {
    final sessionId = _generateSessionId();
    try {
      _logger.d('🔔 [API-$sessionId] 【OVERALL TOGGLE、EtoggleNotifications called with: $enabled');
      final updatedSettings = state.overallSettings.copyWith(
        notificationsEnabled: enabled,
      );
      await updateOverallSettings(updatedSettings);
      _logger.d('🔔 [API-$sessionId] 【OVERALL TOGGLE、EtoggleNotifications completed successfully');
    } catch (e) {
      _logger.d('🔔 [API-$sessionId] 【OVERALL TOGGLE、EtoggleNotifications failed: $e');
      state = state.copyWith(error: '通知設定�E更新に失敗しました: $e');
    }
  }

  // === 習�E設宁E===

  /// 習�E通知設定を更新
  Future<void> updateHabitSettings(HabitNotificationSettings settings) async {
    final sessionId = _generateSessionId();
    final operationId = 'updateHabitSettings-$sessionId';
    
    // 🛡�E�E重褁E��行チェチE��
    if (!_canStartOperation(operationId)) {
      return;
    }
    
    try {
      _logger.d('🔔 [API-$sessionId] updateHabitSettings called with: enabled=${settings.enabled}, defaultTime=${settings.defaultTime}');
      await _service.saveHabitSettings(settings);
      state = state.copyWith(habitSettings: settings);
      // 🔧 自動スケジュール更新を削除し、debounce機�Eを使用
      _triggerScheduleUpdate('updateHabitSettings-$sessionId');
      _logger.d('🔔 [API-$sessionId] updateHabitSettings completed successfully');
    } catch (e) {
      _logger.d('🔔 [API-$sessionId] updateHabitSettings failed: $e');
      state = state.copyWith(error: '習�E設定�E更新に失敗しました: $e');
    } finally {
      // 🛡�E�E操作完亁E�E琁E
      _completeOperation(operationId);
    }
  }

  /// 習�E通知の有効/無効を�Eり替ぁE
  Future<void> toggleHabitNotifications(bool enabled) async {
    final sessionId = _generateSessionId();
    try {
      _logger.d('🔔 [API-$sessionId] 【HABIT TOGGLE、EtoggleHabitNotifications called with: $enabled');
      final updatedSettings = state.habitSettings.copyWith(enabled: enabled);
      await updateHabitSettings(updatedSettings);
      _logger.d('🔔 [API-$sessionId] 【HABIT TOGGLE、EtoggleHabitNotifications completed successfully');
    } catch (e) {
      _logger.d('🔔 [API-$sessionId] 【HABIT TOGGLE、EtoggleHabitNotifications failed: $e');
      state = state.copyWith(error: '習�E通知設定�E更新に失敗しました: $e');
    }
  }

  /// チE��ォルト習�E通知時間を更新
  Future<void> updateDefaultHabitTime(String time) async {
    try {
      final updatedSettings = state.habitSettings.copyWith(defaultTime: time);
      await updateHabitSettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: 'チE��ォルト通知時間の更新に失敗しました: $e');
    }
  }

  /// チE��ォルト習�E通知曜日を更新
  Future<void> updateDefaultHabitDays(List<int> days) async {
    try {
      final updatedSettings = state.habitSettings.copyWith(defaultDays: days);
      await updateHabitSettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: 'チE��ォルト通知曜日の更新に失敗しました: $e');
    }
  }

  /// 特定�E習�Eのカスタム設定を更新
  Future<void> updateHabitCustomSettings(String habitId, HabitCustomSettings settings) async {
    final sessionId = _generateSessionId();
    try {
      _logger.d('🔔 [API-$sessionId] updateHabitCustomSettings called for habitId: $habitId');
      await _service.saveHabitCustomSettings(habitId, settings);
      
      // 現在の設定を更新
      final updatedCustomSettings = Map<String, HabitCustomSettings>.from(state.habitSettings.customSettings);
      updatedCustomSettings[habitId] = settings;
      
      final updatedHabitSettings = state.habitSettings.copyWith(customSettings: updatedCustomSettings);
      state = state.copyWith(habitSettings: updatedHabitSettings);
      
      _triggerScheduleUpdate('updateHabitCustomSettings-$sessionId');
      _logger.d('🔔 [API-$sessionId] updateHabitCustomSettings completed successfully');
    } catch (e) {
      _logger.d('🔔 [API-$sessionId] updateHabitCustomSettings failed: $e');
      state = state.copyWith(error: '習�Eカスタム設定�E更新に失敗しました: $e');
    }
  }

  /// 特定�E習�Eのカスタム設定を削除
  Future<void> removeHabitCustomSettings(String habitId) async {
    final sessionId = _generateSessionId();
    try {
      _logger.d('🔔 [API-$sessionId] removeHabitCustomSettings called for habitId: $habitId');
      await _service.removeHabitCustomSettings(habitId);
      
      // 現在の設定を更新
      final updatedCustomSettings = Map<String, HabitCustomSettings>.from(state.habitSettings.customSettings);
      updatedCustomSettings.remove(habitId);
      
      final updatedHabitSettings = state.habitSettings.copyWith(customSettings: updatedCustomSettings);
      state = state.copyWith(habitSettings: updatedHabitSettings);
      
      _triggerScheduleUpdate('removeHabitCustomSettings-$sessionId');
      _logger.d('🔔 [API-$sessionId] removeHabitCustomSettings completed successfully');
    } catch (e) {
      _logger.d('🔔 [API-$sessionId] removeHabitCustomSettings failed: $e');
      state = state.copyWith(error: '習�Eカスタム設定�E削除に失敗しました: $e');
    }
  }

  // === タスク設宁E===

  /// タスク通知設定を更新
  Future<void> updateTaskSettings(TaskNotificationSettings settings) async {
    final sessionId = _generateSessionId();
    final operationId = 'updateTaskSettings-$sessionId';
    
    // 🛡�E�E重褁E��行チェチE��
    if (!_canStartOperation(operationId)) {
      return;
    }
    
    try {
      _logger.d('🔔 [API-$sessionId] updateTaskSettings called with: deadlineAlerts=${settings.deadlineAlertsEnabled}, completionCelebration=${settings.completionCelebration}');
      await _service.saveTaskSettings(settings);
      state = state.copyWith(taskSettings: settings);
      _triggerScheduleUpdate('updateTaskSettings-$sessionId');
      _logger.d('🔔 [API-$sessionId] updateTaskSettings completed successfully');
    } catch (e) {
      _logger.d('🔔 [API-$sessionId] updateTaskSettings failed: $e');
      state = state.copyWith(error: 'タスク設定�E更新に失敗しました: $e');
    } finally {
      // 🛡�E�E操作完亁E�E琁E
      _completeOperation(operationId);
    }
  }

  /// 締刁E��ラート�E有効/無効を�Eり替ぁE
  Future<void> toggleDeadlineAlerts(bool enabled) async {
    final sessionId = _generateSessionId();
    try {
      _logger.d('🔔 [API-$sessionId] 【TASK TOGGLE、EtoggleDeadlineAlerts called with: $enabled');
      final updatedSettings = state.taskSettings.copyWith(deadlineAlertsEnabled: enabled);
      await updateTaskSettings(updatedSettings);
      _logger.d('🔔 [API-$sessionId] 【TASK TOGGLE、EtoggleDeadlineAlerts completed successfully');
    } catch (e) {
      _logger.d('🔔 [API-$sessionId] 【TASK TOGGLE、EtoggleDeadlineAlerts failed: $e');
      state = state.copyWith(error: '締刁E��ラート設定�E更新に失敗しました: $e');
    }
  }

  /// 完亁E��い通知の有効/無効を�Eり替ぁE
  Future<void> toggleCompletionCelebration(bool enabled) async {
    try {
      final updatedSettings = state.taskSettings.copyWith(completionCelebration: enabled);
      await updateTaskSettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: '完亁E��い設定�E更新に失敗しました: $e');
    }
  }

  /// アラート時間を更新�E�何時間前に通知するか！E
  Future<void> updateAlertHours(List<int> hours) async {
    try {
      final updatedSettings = state.taskSettings.copyWith(alertHours: hours);
      await updateTaskSettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: 'アラート時間�E更新に失敗しました: $e');
    }
  }

  /// 作業時間限定通知の有効/無効を�Eり替ぁE
  Future<void> toggleWorkingHoursOnly(bool enabled) async {
    try {
      final updatedSettings = state.taskSettings.copyWith(workingHoursOnly: enabled);
      await updateTaskSettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: '作業時間限定設定�E更新に失敗しました: $e');
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
      _logger.d('🔔 [API-$sessionId] updatePriorityAlertSettings called for priority: $priority');
      await _service.savePriorityAlertSettings(priority, settings);
      
      // 現在の設定を更新
      final updatedPrioritySettings = Map<String, PriorityAlertSettings>.from(state.taskSettings.prioritySettings);
      updatedPrioritySettings[priority] = settings;
      
      final updatedTaskSettings = state.taskSettings.copyWith(prioritySettings: updatedPrioritySettings);
      state = state.copyWith(taskSettings: updatedTaskSettings);
      
      _triggerScheduleUpdate('updatePriorityAlertSettings-$sessionId');
      _logger.d('🔔 [API-$sessionId] updatePriorityAlertSettings completed successfully');
    } catch (e) {
      _logger.d('🔔 [API-$sessionId] updatePriorityAlertSettings failed: $e');
      state = state.copyWith(error: '優先度アラート設定�E更新に失敗しました: $e');
    }
  }

  // === AI設宁E===

  /// AI通知設定を更新
  Future<void> updateAISettings(AINotificationSettings settings) async {
    final sessionId = _generateSessionId();
    final operationId = 'updateAISettings-$sessionId';
    
    // 🛡�E�E重褁E��行チェチE��
    if (!_canStartOperation(operationId)) {
      return;
    }
    
    try {
      _logger.d('🔔 [API-$sessionId] updateAISettings called with: weeklyReport=${settings.weeklyReportEnabled}, instantInsights=${settings.instantInsightsEnabled}');
      await _service.saveAISettings(settings);
      state = state.copyWith(aiSettings: settings);
      _triggerScheduleUpdate('updateAISettings-$sessionId');
      _logger.d('🔔 [API-$sessionId] updateAISettings completed successfully');
    } catch (e) {
      _logger.d('🔔 [API-$sessionId] updateAISettings failed: $e');
      state = state.copyWith(error: 'AI設定�E更新に失敗しました: $e');
    } finally {
      // 🛡�E�E操作完亁E�E琁E
      _completeOperation(operationId);
    }
  }

  /// 週次レポ�Eト�E有効/無効を�Eり替ぁE
  Future<void> toggleWeeklyReport(bool enabled) async {
    final sessionId = _generateSessionId();
    try {
      _logger.d('🔔 [API-$sessionId] 【AI TOGGLE、EtoggleWeeklyReport called with: $enabled');
      final updatedSettings = state.aiSettings.copyWith(weeklyReportEnabled: enabled);
      await updateAISettings(updatedSettings);
      _logger.d('🔔 [API-$sessionId] 【AI TOGGLE、EtoggleWeeklyReport completed successfully');
    } catch (e) {
      _logger.d('🔔 [API-$sessionId] 【AI TOGGLE、EtoggleWeeklyReport failed: $e');
      state = state.copyWith(error: '週次レポ�Eト設定�E更新に失敗しました: $e');
    }
  }

  /// 週次レポ�Eト�E時間を更新
  Future<void> updateWeeklyReportTime(String day, String time) async {
    try {
      final updatedSettings = state.aiSettings.copyWith(
        weeklyReportDay: day,
        weeklyReportTime: time,
      );
      await updateAISettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: '週次レポ�Eト時間�E更新に失敗しました: $e');
    }
  }

  /// 即座の洞察�E有効/無効を�Eり替ぁE
  Future<void> toggleInstantInsights(bool enabled) async {
    try {
      final updatedSettings = state.aiSettings.copyWith(instantInsightsEnabled: enabled);
      await updateAISettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: '即座の洞察設定�E更新に失敗しました: $e');
    }
  }

  /// 改喁E��案�E有効/無効を�Eり替ぁE
  Future<void> toggleImprovementSuggestions(bool enabled) async {
    try {
      final updatedSettings = state.aiSettings.copyWith(improvementSuggestionsEnabled: enabled);
      await updateAISettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: '改喁E��案設定�E更新に失敗しました: $e');
    }
  }

  /// 改喁E��案�E頻度を更新
  Future<void> updateSuggestionFrequency(String frequency) async {
    try {
      final updatedSettings = state.aiSettings.copyWith(suggestionFrequency: frequency);
      await updateAISettings(updatedSettings);
    } catch (e) {
      state = state.copyWith(error: '改喁E��案頻度の更新に失敗しました: $e');
    }
  }

  // === 設定リセチE�� ===

  /// 全ての設定をチE��ォルトにリセチE��
  Future<void> resetAllSettings() async {
    final sessionId = _generateSessionId();
    try {
      _logger.d('🔔 [API-$sessionId] 【RESET、EresetAllSettings called');
      await _service.resetToDefaults();
      state = NotificationSettingsState.initial();
      _triggerScheduleUpdate('resetAllSettings-$sessionId');
      _logger.d('🔔 [API-$sessionId] 【RESET、EresetAllSettings completed successfully');
    } catch (e) {
      _logger.d('🔔 [API-$sessionId] 【RESET、EresetAllSettings failed: $e');
      state = state.copyWith(error: '設定�EリセチE��に失敗しました: $e');
    }
  }

  /// 特定カチE��リの設定をリセチE��
  Future<void> resetCategorySettings(String category) async {
    final sessionId = _generateSessionId();
    try {
      _logger.d('🔔 [API-$sessionId] 【RESET、EresetCategorySettings called for category: $category');
      await _service.resetCategorySettings(category);
      
      // 該当カチE��リの設定をチE��ォルトに更新
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
      _logger.d('🔔 [API-$sessionId] 【RESET、EresetCategorySettings completed successfully for category: $category');
    } catch (e) {
      _logger.d('🔔 [API-$sessionId] 【RESET、EresetCategorySettings failed for category $category: $e');
      state = state.copyWith(error: '設定カチE��リのリセチE��に失敗しました: $e');
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

  /// 通知可能かどぁE��を判宁E
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

  // === 設定統訁E===

  /// 設定統計を取征E
  Future<Map<String, dynamic>> getSettingsStats() async {
    try {
      return await _service.getSettingsStats();
    } catch (e) {
      return {'error': 'Failed to get settings stats: $e'};
    }
  }

  /// 通知効果�E刁E��チE�Eタを取征E
  Future<NotificationEffectivenessData> getNotificationEffectiveness() async {
    try {
      final settings = state;
      final effectivenessData = NotificationEffectivenessData(
        overallEnabled: settings.overallSettings.notificationsEnabled,
        habitNotifications: settings.habitSettings.enabled,
        taskNotifications: settings.taskSettings.deadlineAlertsEnabled,
        aiNotifications: settings.aiSettings.weeklyReportEnabled,
        instantInsights: settings.aiSettings.instantInsightsEnabled,
        silentHours: _calculateSilentHours(settings.overallSettings),
        weekendNotifications: settings.overallSettings.weekendNotificationsEnabled,
        soundEnabled: settings.overallSettings.soundEnabled,
        vibrationEnabled: settings.overallSettings.vibrationEnabled,
        lastUpdated: DateTime.now(),
      );
      
      return effectivenessData;
    } catch (e) {
      _logger.d('通知効果�E析データ取得エラー: $e');
      return NotificationEffectivenessData.empty();
    }
  }

  /// サイレント時間�E計箁E
  int _calculateSilentHours(OverallNotificationSettings settings) {
    try {
      final startTime = _timeToMinutes(settings.silentStartTime);
      final endTime = _timeToMinutes(settings.silentEndTime);
      
      if (startTime <= endTime) {
        return endTime - startTime;
      } else {
        // 日をまたぐ場吁E
        return (24 * 60 - startTime) + endTime;
      }
    } catch (e) {
      return 0;
    }
  }

  /// 時間斁E���Eを�E単位に変換
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  /// 通知設定�E最適化提案を取征E
  Future<List<NotificationOptimizationSuggestion>> getOptimizationSuggestions() async {
    try {
      final suggestions = <NotificationOptimizationSuggestion>[];
      final settings = state;
      
      // 通知が完全に無効の場合
      if (!settings.overallSettings.notificationsEnabled) {
        suggestions.add(NotificationOptimizationSuggestion(
          type: SuggestionType.enableNotifications,
          title: '通知を有効にする',
          description: '重要なリマインダーや分析結果を見逃さないよう、通知を有効にすることをお勧めします。',
          priority: SuggestionPriority.high,
        ));
      }
      
      // サイレント時間が長すぎる場合
      final silentHours = _calculateSilentHours(settings.overallSettings);
      if (silentHours > 12) {
        suggestions.add(NotificationOptimizationSuggestion(
          type: SuggestionType.adjustSilentHours,
          title: 'サイレント時間の調整',
          description: 'サイレント時間が長すぎるため、重要な通知を見逃す可能性があります。',
          priority: SuggestionPriority.medium,
        ));
      }
      
      // AI通知が無効の場合
      if (!settings.aiSettings.weeklyReportEnabled) {
        suggestions.add(NotificationOptimizationSuggestion(
          type: SuggestionType.enableAIReports,
          title: 'AI週次レポートを有効にする',
          description: '週次レポートで生産性の改善を把握できます。',
          priority: SuggestionPriority.medium,
        ));
      }
      
      // 即座インサイトが無効の場合
      if (!settings.aiSettings.instantInsightsEnabled) {
        suggestions.add(NotificationOptimizationSuggestion(
          type: SuggestionType.enableInstantInsights,
          title: '即座インサイトを有効にする',
          description: 'リアルタイムの分析結果を即座に確認できます。',
          priority: SuggestionPriority.low,
        ));
      }
      
      // 週末通知が無効の場合
      if (!settings.overallSettings.weekendNotificationsEnabled) {
        suggestions.add(NotificationOptimizationSuggestion(
          type: SuggestionType.enableWeekendNotifications,
          title: '週末通知を有効にする',
          description: '週末も習慣やタスクの管理・継続ができます。',
          priority: SuggestionPriority.low,
        ));
      }
      
      return suggestions;
    } catch (e) {
      _logger.d('最適化提案取得エラー: $e');
      return [];
    }
  }

  /// 通知設定�E統計情報を取征E
  Future<NotificationSettingsStats> getNotificationSettingsStats() async {
    try {
      final settings = state;
      final stats = NotificationSettingsStats(
        totalSettings: 15, // 設定頁E��の総数
        enabledSettings: _countEnabledSettings(settings),
        disabledSettings: _countDisabledSettings(settings),
        customSettings: _countCustomSettings(settings),
        lastOptimized: DateTime.now(),
        optimizationScore: _calculateOptimizationScore(settings),
      );
      
      return stats;
    } catch (e) {
      _logger.d('設定統計取得エラー: $e');
      return NotificationSettingsStats.empty();
    }
  }

  /// 有効な設定�E数をカウンチE
  int _countEnabledSettings(NotificationSettingsState settings) {
    int count = 0;
    
    // 全体設宁E
    if (settings.overallSettings.notificationsEnabled) count++;
    if (settings.overallSettings.weekendNotificationsEnabled) count++;
    if (settings.overallSettings.soundEnabled) count++;
    if (settings.overallSettings.vibrationEnabled) count++;
    
    // 習�E設宁E
    if (settings.habitSettings.enabled) count++;
    
    // タスク設宁E
    if (settings.taskSettings.deadlineAlertsEnabled) count++;
    if (settings.taskSettings.completionCelebration) count++;
    
    // AI設宁E
    if (settings.aiSettings.weeklyReportEnabled) count++;
    if (settings.aiSettings.instantInsightsEnabled) count++;
    if (settings.aiSettings.improvementSuggestionsEnabled) count++;
    if (settings.aiSettings.performanceAlertsEnabled) count++;
    
    return count;
  }

  /// 無効な設定�E数をカウンチE
  int _countDisabledSettings(NotificationSettingsState settings) {
    return 15 - _countEnabledSettings(settings);
  }

  /// カスタム設定�E数をカウンチE
  int _countCustomSettings(NotificationSettingsState settings) {
    int count = 0;
    
    // 習�Eのカスタム設宁E
    count += settings.habitSettings.customSettings.length;
    
    // タスクの優先度設宁E
    count += settings.taskSettings.prioritySettings.length;
    
    return count;
  }

  /// 最適化スコアを計箁E
  double _calculateOptimizationScore(NotificationSettingsState settings) {
    double score = 0.0;
    
    // 基本通知が有効: 30点
    if (settings.overallSettings.notificationsEnabled) score += 30;
    
    // AI通知が有効: 25点
    if (settings.aiSettings.weeklyReportEnabled) score += 25;
    if (settings.aiSettings.instantInsightsEnabled) score += 15;
    
    // 習�E・タスク通知が有効: 20点
    if (settings.habitSettings.enabled) score += 10;
    if (settings.taskSettings.deadlineAlertsEnabled) score += 10;
    
    // そ�E他�E設宁E 10点
    if (settings.overallSettings.weekendNotificationsEnabled) score += 5;
    if (settings.overallSettings.soundEnabled) score += 2.5;
    if (settings.overallSettings.vibrationEnabled) score += 2.5;
    
    return score.clamp(0.0, 100.0);
  }

  // === 通知権限管琁E===

  /// 通知権限を要汁E
  Future<bool> requestNotificationPermission() async {
    try {
      if (_localNotificationService == null) return false;
      
      final result = await _localNotificationService!.checkAndRequestPermissions();
      return result == true;
    } catch (e) {
      _logger.d('通知権限�E要求中にエラーが発生しました: $e');
      return false;
    }
  }

  /// 現在の通知権限状況を取征E
  Future<Map<String, dynamic>> getPermissionStatus() async {
    try {
      if (_localNotificationService == null) {
        return {
          'hasPermission': false,
          'overallStatus': 'unknown',
          'canOpenSettings': false,
          'shouldShowRationale': false,
          'statusDescription': 'LocalNotificationServiceが�E期化されてぁE��せん',
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
        'statusDescription': details['statusDescription'] ?? '不�E',
        'disabledCategories': details['disabledCategories'] ?? [],
        'lastChecked': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _logger.d('通知権限�E取得中にエラーが発生しました: $e');
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

  /// 通知統計を取征E
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      if (_localNotificationService == null) {
        return {
          'totalScheduled': 0,
          'totalHabits': 0,
          'totalTasks': 0,
          'totalAIReports': 0,
          'lastUpdate': DateTime.now().toIso8601String(),
          'error': 'LocalNotificationServiceが�E期化されてぁE��せん',
        };
      }
      
      final stats = await _localNotificationService!.getNotificationStats();
      return stats.toJson();
    } catch (e) {
      _logger.d('通知統計�E取得中にエラーが発生しました: $e');
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

  /// 通知権限�E設定画面を開ぁE
  Future<void> openNotificationSettings() async {
    try {
      // プラットフォーム固有の設定画面を開く
      // TODO: 実装予定
      _logger.d('通知設定画面を開く機能は未実装です');
    } catch (e) {
      _logger.d('通知設定画面の起動中にエラーが発生しました: $e');
    }
  }

  // === チE��ト機�E ===

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
        _logger.d('テスト習慣通知を送信しました');
      } else {
        _logger.d('テスト習慣通知の送信に失敗しました');
      }
      return success;
    } catch (e) {
      _logger.d('テスト習慣通知の送信中にエラーが発生しました: $e');
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
        _logger.d('テストタスク通知を送信しました');
      } else {
        _logger.d('テストタスク通知の送信に失敗しました');
      }
      return success;
    } catch (e) {
      _logger.d('テストタスク通知の送信中にエラーが発生しました: $e');
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
        _logger.d('テストAI通知を送信しました');
      } else {
        _logger.d('テストAI通知の送信に失敗しました');
      }
      return success;
    } catch (e) {
      _logger.d('テストAI通知の送信中にエラーが発生しました: $e');
      return false;
    }
  }

  /// 全てのチEト通知をキャンセル
  Future<void> cancelAllTestNotifications() async {
    try {
      if (_localNotificationService == null) return;
      
      await _localNotificationService!.cancelNotification(9999);
      await _localNotificationService!.cancelNotification(9998);
      await _localNotificationService!.cancelNotification(9997);
      _logger.d('全てのチE��ト通知をキャンセルしました');
    } catch (e) {
      _logger.d('チE��ト通知のキャンセル中にエラーが発生しました: $e');
    }
  }
}

/// 通知効果�E析データ
class NotificationEffectivenessData {
  final bool overallEnabled;
  final bool habitNotifications;
  final bool taskNotifications;
  final bool aiNotifications;
  final bool instantInsights;
  final int silentHours;
  final bool weekendNotifications;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final DateTime lastUpdated;

  const NotificationEffectivenessData({
    required this.overallEnabled,
    required this.habitNotifications,
    required this.taskNotifications,
    required this.aiNotifications,
    required this.instantInsights,
    required this.silentHours,
    required this.weekendNotifications,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.lastUpdated,
  });

  factory NotificationEffectivenessData.empty() {
    return NotificationEffectivenessData(
      overallEnabled: false,
      habitNotifications: false,
      taskNotifications: false,
      aiNotifications: false,
      instantInsights: false,
      silentHours: 0,
      weekendNotifications: false,
      soundEnabled: false,
      vibrationEnabled: false,
      lastUpdated: DateTime.now(),
    );
  }
}

/// 通知最適化提桁E
class NotificationOptimizationSuggestion {
  final SuggestionType type;
  final String title;
  final String description;
  final SuggestionPriority priority;

  const NotificationOptimizationSuggestion({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
  });
}

/// 提案タイチE
enum SuggestionType {
  enableNotifications,
  adjustSilentHours,
  enableAIReports,
  enableInstantInsights,
  enableWeekendNotifications,
}

/// 提案優先度
enum SuggestionPriority {
  low,
  medium,
  high,
}

/// 通知設定統訁E
class NotificationSettingsStats {
  final int totalSettings;
  final int enabledSettings;
  final int disabledSettings;
  final int customSettings;
  final DateTime lastOptimized;
  final double optimizationScore;

  const NotificationSettingsStats({
    required this.totalSettings,
    required this.enabledSettings,
    required this.disabledSettings,
    required this.customSettings,
    required this.lastOptimized,
    required this.optimizationScore,
  });

  factory NotificationSettingsStats.empty() {
    return NotificationSettingsStats(
      totalSettings: 0,
      enabledSettings: 0,
      disabledSettings: 0,
      customSettings: 0,
      lastOptimized: DateTime.now(),
      optimizationScore: 0.0,
    );
  }
}

/// 🔔 通知設定�Eロバイダーのインスタンス
final notificationSettingsServiceProvider = Provider<NotificationSettingsService>((ref) {
  return NotificationSettingsService();
});

/// 🔔 通知設定状態�Eロバイダー
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsProvider, NotificationSettingsState>((ref) {
  final service = ref.watch(notificationSettingsServiceProvider);
  return NotificationSettingsProvider(service);
});

// === 便利な派生�Eロバイダー ===

/// 通知が有効かどぁE��を監要E
final notificationsEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(notificationSettingsProvider);
  return settings.overallSettings.notificationsEnabled;
});

/// 習�E通知が有効かどぁE��を監要E
final habitNotificationsEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(notificationSettingsProvider);
  return settings.habitSettings.enabled;
});

/// タスク通知が有効かどぁE��を監要E
final taskNotificationsEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(notificationSettingsProvider);
  return settings.taskSettings.deadlineAlertsEnabled;
});

/// AI通知が有効かどぁE��を監要E
final aiNotificationsEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(notificationSettingsProvider);
  return settings.aiSettings.weeklyReportEnabled;
});

/// 現在通知可能かどぁE��を監要E
final canSendNotificationProvider = FutureProvider<bool>((ref) async {
  final provider = ref.watch(notificationSettingsProvider.notifier);
  return await provider.canSendNotification();
});

/// 設定統計を監要E
final settingsStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final provider = ref.watch(notificationSettingsProvider.notifier);
  return await provider.getSettingsStats();
});
