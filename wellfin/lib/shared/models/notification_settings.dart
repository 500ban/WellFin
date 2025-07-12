/// 🔄 習慣リマインダー設定
class HabitNotificationSettings {
  final bool enabled;                    // 習慣通知の有効/無効
  final String defaultTime;              // デフォルト時間 "07:00"
  final List<int> defaultDays;           // デフォルト曜日 [1,2,3,4,5]
  final bool allowCustomPerHabit;        // 習慣ごとの個別設定許可
  final Map<String, HabitCustomSettings> customSettings; // 個別習慣設定

  const HabitNotificationSettings({
    required this.enabled,
    required this.defaultTime,
    required this.defaultDays,
    required this.allowCustomPerHabit,
    required this.customSettings,
  });

  // デフォルト設定
  factory HabitNotificationSettings.defaultSettings() {
    return const HabitNotificationSettings(
      enabled: true,
      defaultTime: "07:00",
      defaultDays: [1, 2, 3, 4, 5], // 平日のみ
      allowCustomPerHabit: true,
      customSettings: {},
    );
  }

  // JSON変換
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'defaultTime': defaultTime,
      'defaultDays': defaultDays,
      'allowCustomPerHabit': allowCustomPerHabit,
      'customSettings': customSettings.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  factory HabitNotificationSettings.fromJson(Map<String, dynamic> json) {
    return HabitNotificationSettings(
      enabled: json['enabled'] ?? true,
      defaultTime: json['defaultTime'] ?? "07:00",
      defaultDays: List<int>.from(json['defaultDays'] ?? [1, 2, 3, 4, 5]),
      allowCustomPerHabit: json['allowCustomPerHabit'] ?? true,
      customSettings: (json['customSettings'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, HabitCustomSettings.fromJson(value)),
      ) ?? {},
    );
  }

  // コピー機能
  HabitNotificationSettings copyWith({
    bool? enabled,
    String? defaultTime,
    List<int>? defaultDays,
    bool? allowCustomPerHabit,
    Map<String, HabitCustomSettings>? customSettings,
  }) {
    return HabitNotificationSettings(
      enabled: enabled ?? this.enabled,
      defaultTime: defaultTime ?? this.defaultTime,
      defaultDays: defaultDays ?? this.defaultDays,
      allowCustomPerHabit: allowCustomPerHabit ?? this.allowCustomPerHabit,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

/// 🔄 個別習慣設定
class HabitCustomSettings {
  final bool enabled;                    // この習慣の通知ON/OFF
  final String? customTime;              // カスタム時間（nullならデフォルト）
  final List<int>? customDays;           // カスタム曜日（nullならデフォルト）
  final int reminderCount;               // 1日の通知回数 1-3
  final List<String> reminderTimes;      // 複数回の場合の時間リスト
  final String notificationStyle;        // "gentle", "standard", "urgent"

  const HabitCustomSettings({
    required this.enabled,
    this.customTime,
    this.customDays,
    required this.reminderCount,
    required this.reminderTimes,
    required this.notificationStyle,
  });

  // デフォルト設定
  factory HabitCustomSettings.defaultSettings() {
    return const HabitCustomSettings(
      enabled: true,
      customTime: null,
      customDays: null,
      reminderCount: 1,
      reminderTimes: [],
      notificationStyle: "standard",
    );
  }

  // JSON変換
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'customTime': customTime,
      'customDays': customDays,
      'reminderCount': reminderCount,
      'reminderTimes': reminderTimes,
      'notificationStyle': notificationStyle,
    };
  }

  factory HabitCustomSettings.fromJson(Map<String, dynamic> json) {
    return HabitCustomSettings(
      enabled: json['enabled'] ?? true,
      customTime: json['customTime'],
      customDays: json['customDays'] != null ? List<int>.from(json['customDays']) : null,
      reminderCount: json['reminderCount'] ?? 1,
      reminderTimes: List<String>.from(json['reminderTimes'] ?? []),
      notificationStyle: json['notificationStyle'] ?? "standard",
    );
  }

  // コピー機能
  HabitCustomSettings copyWith({
    bool? enabled,
    String? customTime,
    List<int>? customDays,
    int? reminderCount,
    List<String>? reminderTimes,
    String? notificationStyle,
  }) {
    return HabitCustomSettings(
      enabled: enabled ?? this.enabled,
      customTime: customTime ?? this.customTime,
      customDays: customDays ?? this.customDays,
      reminderCount: reminderCount ?? this.reminderCount,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      notificationStyle: notificationStyle ?? this.notificationStyle,
    );
  }
}

/// 📝 タスク・締切アラート設定
class TaskNotificationSettings {
  final bool deadlineAlertsEnabled;      // 締切アラート有効/無効
  final List<int> alertHours;            // 何時間前 [24, 1] 
  final bool completionCelebration;      // 完了祝い
  final bool priorityBasedAlerts;        // 優先度別の通知強度
  final Map<String, PriorityAlertSettings> prioritySettings; // 優先度別設定
  final bool workingHoursOnly;           // 作業時間中のみ通知
  final String workingStart;             // "09:00"
  final String workingEnd;               // "18:00"

  const TaskNotificationSettings({
    required this.deadlineAlertsEnabled,
    required this.alertHours,
    required this.completionCelebration,
    required this.priorityBasedAlerts,
    required this.prioritySettings,
    required this.workingHoursOnly,
    required this.workingStart,
    required this.workingEnd,
  });

  // デフォルト設定
  factory TaskNotificationSettings.defaultSettings() {
    return TaskNotificationSettings(
      deadlineAlertsEnabled: true,
      alertHours: [24, 1], // 24時間前と1時間前
      completionCelebration: true,
      priorityBasedAlerts: true,
      prioritySettings: {
        'high': PriorityAlertSettings.defaultSettings('high'),
        'medium': PriorityAlertSettings.defaultSettings('medium'),
        'low': PriorityAlertSettings.defaultSettings('low'),
      },
      workingHoursOnly: false,
      workingStart: "09:00",
      workingEnd: "18:00",
    );
  }

  // JSON変換
  Map<String, dynamic> toJson() {
    return {
      'deadlineAlertsEnabled': deadlineAlertsEnabled,
      'alertHours': alertHours,
      'completionCelebration': completionCelebration,
      'priorityBasedAlerts': priorityBasedAlerts,
      'prioritySettings': prioritySettings.map((key, value) => MapEntry(key, value.toJson())),
      'workingHoursOnly': workingHoursOnly,
      'workingStart': workingStart,
      'workingEnd': workingEnd,
    };
  }

  factory TaskNotificationSettings.fromJson(Map<String, dynamic> json) {
    return TaskNotificationSettings(
      deadlineAlertsEnabled: json['deadlineAlertsEnabled'] ?? true,
      alertHours: List<int>.from(json['alertHours'] ?? [24, 1]),
      completionCelebration: json['completionCelebration'] ?? true,
      priorityBasedAlerts: json['priorityBasedAlerts'] ?? true,
      prioritySettings: (json['prioritySettings'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, PriorityAlertSettings.fromJson(value)),
      ) ?? {
        'high': PriorityAlertSettings.defaultSettings('high'),
        'medium': PriorityAlertSettings.defaultSettings('medium'),
        'low': PriorityAlertSettings.defaultSettings('low'),
      },
      workingHoursOnly: json['workingHoursOnly'] ?? false,
      workingStart: json['workingStart'] ?? "09:00",
      workingEnd: json['workingEnd'] ?? "18:00",
    );
  }

  // コピー機能
  TaskNotificationSettings copyWith({
    bool? deadlineAlertsEnabled,
    List<int>? alertHours,
    bool? completionCelebration,
    bool? priorityBasedAlerts,
    Map<String, PriorityAlertSettings>? prioritySettings,
    bool? workingHoursOnly,
    String? workingStart,
    String? workingEnd,
  }) {
    return TaskNotificationSettings(
      deadlineAlertsEnabled: deadlineAlertsEnabled ?? this.deadlineAlertsEnabled,
      alertHours: alertHours ?? this.alertHours,
      completionCelebration: completionCelebration ?? this.completionCelebration,
      priorityBasedAlerts: priorityBasedAlerts ?? this.priorityBasedAlerts,
      prioritySettings: prioritySettings ?? this.prioritySettings,
      workingHoursOnly: workingHoursOnly ?? this.workingHoursOnly,
      workingStart: workingStart ?? this.workingStart,
      workingEnd: workingEnd ?? this.workingEnd,
    );
  }
}

/// 📝 優先度別アラート設定
class PriorityAlertSettings {
  final bool enabled;                    // この優先度の通知ON/OFF
  final List<int> alertHours;            // カスタム通知タイミング
  final String notificationStyle;        // 通知スタイル
  final bool soundEnabled;               // 音の有効/無効
  final bool vibrationEnabled;           // バイブレーションの有効/無効

  const PriorityAlertSettings({
    required this.enabled,
    required this.alertHours,
    required this.notificationStyle,
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  // デフォルト設定
  factory PriorityAlertSettings.defaultSettings(String priority) {
    switch (priority) {
      case 'high':
        return const PriorityAlertSettings(
          enabled: true,
          alertHours: [24, 8, 1],
          notificationStyle: "urgent",
          soundEnabled: true,
          vibrationEnabled: true,
        );
      case 'medium':
        return const PriorityAlertSettings(
          enabled: true,
          alertHours: [24, 1],
          notificationStyle: "standard",
          soundEnabled: true,
          vibrationEnabled: false,
        );
      case 'low':
        return const PriorityAlertSettings(
          enabled: true,
          alertHours: [24],
          notificationStyle: "gentle",
          soundEnabled: false,
          vibrationEnabled: false,
        );
      default:
        return const PriorityAlertSettings(
          enabled: true,
          alertHours: [24],
          notificationStyle: "standard",
          soundEnabled: true,
          vibrationEnabled: false,
        );
    }
  }

  // JSON変換
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'alertHours': alertHours,
      'notificationStyle': notificationStyle,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  factory PriorityAlertSettings.fromJson(Map<String, dynamic> json) {
    return PriorityAlertSettings(
      enabled: json['enabled'] ?? true,
      alertHours: List<int>.from(json['alertHours'] ?? [24]),
      notificationStyle: json['notificationStyle'] ?? "standard",
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? false,
    );
  }

  // コピー機能
  PriorityAlertSettings copyWith({
    bool? enabled,
    List<int>? alertHours,
    String? notificationStyle,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return PriorityAlertSettings(
      enabled: enabled ?? this.enabled,
      alertHours: alertHours ?? this.alertHours,
      notificationStyle: notificationStyle ?? this.notificationStyle,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}

/// 🤖 AI分析・レポート設定
class AINotificationSettings {
  final bool weeklyReportEnabled;        // 週次レポート
  final String weeklyReportDay;          // "sunday"
  final String weeklyReportTime;         // "19:00"
  final bool instantInsightsEnabled;     // 即座の洞察
  final int insightsThreshold;           // 洞察の重要度閾値
  final bool improvementSuggestionsEnabled; // 改善提案
  final String suggestionFrequency;      // "weekly", "bi-weekly", "monthly"
  final bool performanceAlertsEnabled;   // パフォーマンス低下アラート
  final double performanceThreshold;     // アラート閾値（0.0-1.0）

  const AINotificationSettings({
    required this.weeklyReportEnabled,
    required this.weeklyReportDay,
    required this.weeklyReportTime,
    required this.instantInsightsEnabled,
    required this.insightsThreshold,
    required this.improvementSuggestionsEnabled,
    required this.suggestionFrequency,
    required this.performanceAlertsEnabled,
    required this.performanceThreshold,
  });

  // デフォルト設定
  factory AINotificationSettings.defaultSettings() {
    return const AINotificationSettings(
      weeklyReportEnabled: true,
      weeklyReportDay: "sunday",
      weeklyReportTime: "19:00",
      instantInsightsEnabled: true,
      insightsThreshold: 3, // 1-5スケール
      improvementSuggestionsEnabled: true,
      suggestionFrequency: "weekly",
      performanceAlertsEnabled: false,
      performanceThreshold: 0.7,
    );
  }

  // JSON変換
  Map<String, dynamic> toJson() {
    return {
      'weeklyReportEnabled': weeklyReportEnabled,
      'weeklyReportDay': weeklyReportDay,
      'weeklyReportTime': weeklyReportTime,
      'instantInsightsEnabled': instantInsightsEnabled,
      'insightsThreshold': insightsThreshold,
      'improvementSuggestionsEnabled': improvementSuggestionsEnabled,
      'suggestionFrequency': suggestionFrequency,
      'performanceAlertsEnabled': performanceAlertsEnabled,
      'performanceThreshold': performanceThreshold,
    };
  }

  factory AINotificationSettings.fromJson(Map<String, dynamic> json) {
    return AINotificationSettings(
      weeklyReportEnabled: json['weeklyReportEnabled'] ?? true,
      weeklyReportDay: json['weeklyReportDay'] ?? "sunday",
      weeklyReportTime: json['weeklyReportTime'] ?? "19:00",
      instantInsightsEnabled: json['instantInsightsEnabled'] ?? true,
      insightsThreshold: json['insightsThreshold'] ?? 3,
      improvementSuggestionsEnabled: json['improvementSuggestionsEnabled'] ?? true,
      suggestionFrequency: json['suggestionFrequency'] ?? "weekly",
      performanceAlertsEnabled: json['performanceAlertsEnabled'] ?? false,
      performanceThreshold: json['performanceThreshold'] ?? 0.7,
    );
  }

  // コピー機能
  AINotificationSettings copyWith({
    bool? weeklyReportEnabled,
    String? weeklyReportDay,
    String? weeklyReportTime,
    bool? instantInsightsEnabled,
    int? insightsThreshold,
    bool? improvementSuggestionsEnabled,
    String? suggestionFrequency,
    bool? performanceAlertsEnabled,
    double? performanceThreshold,
  }) {
    return AINotificationSettings(
      weeklyReportEnabled: weeklyReportEnabled ?? this.weeklyReportEnabled,
      weeklyReportDay: weeklyReportDay ?? this.weeklyReportDay,
      weeklyReportTime: weeklyReportTime ?? this.weeklyReportTime,
      instantInsightsEnabled: instantInsightsEnabled ?? this.instantInsightsEnabled,
      insightsThreshold: insightsThreshold ?? this.insightsThreshold,
      improvementSuggestionsEnabled: improvementSuggestionsEnabled ?? this.improvementSuggestionsEnabled,
      suggestionFrequency: suggestionFrequency ?? this.suggestionFrequency,
      performanceAlertsEnabled: performanceAlertsEnabled ?? this.performanceAlertsEnabled,
      performanceThreshold: performanceThreshold ?? this.performanceThreshold,
    );
  }
}

/// 🔔 全体通知設定
class OverallNotificationSettings {
  final bool notificationsEnabled;       // 通知の全体許可
  final String silentStartTime;          // サイレント開始時間
  final String silentEndTime;            // サイレント終了時間
  final bool soundEnabled;               // 音の有効/無効
  final bool vibrationEnabled;           // バイブレーションの有効/無効
  final bool weekendNotificationsEnabled; // 週末通知の有効/無効

  const OverallNotificationSettings({
    required this.notificationsEnabled,
    required this.silentStartTime,
    required this.silentEndTime,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.weekendNotificationsEnabled,
  });

  // デフォルト設定
  factory OverallNotificationSettings.defaultSettings() {
    return const OverallNotificationSettings(
      notificationsEnabled: true,
      silentStartTime: "22:00",
      silentEndTime: "07:00",
      soundEnabled: true,
      vibrationEnabled: true,
      weekendNotificationsEnabled: false,
    );
  }

  // JSON変換
  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'silentStartTime': silentStartTime,
      'silentEndTime': silentEndTime,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'weekendNotificationsEnabled': weekendNotificationsEnabled,
    };
  }

  factory OverallNotificationSettings.fromJson(Map<String, dynamic> json) {
    return OverallNotificationSettings(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      silentStartTime: json['silentStartTime'] ?? "22:00",
      silentEndTime: json['silentEndTime'] ?? "07:00",
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      weekendNotificationsEnabled: json['weekendNotificationsEnabled'] ?? false,
    );
  }

  // コピー機能
  OverallNotificationSettings copyWith({
    bool? notificationsEnabled,
    String? silentStartTime,
    String? silentEndTime,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? weekendNotificationsEnabled,
  }) {
    return OverallNotificationSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      silentStartTime: silentStartTime ?? this.silentStartTime,
      silentEndTime: silentEndTime ?? this.silentEndTime,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      weekendNotificationsEnabled: weekendNotificationsEnabled ?? this.weekendNotificationsEnabled,
    );
  }
}

/// 🔔 通知設定の統合状態
class NotificationSettingsState {
  final bool isLoading;
  final String? error;
  final OverallNotificationSettings overallSettings;
  final HabitNotificationSettings habitSettings;
  final TaskNotificationSettings taskSettings;
  final AINotificationSettings aiSettings;

  const NotificationSettingsState({
    required this.isLoading,
    this.error,
    required this.overallSettings,
    required this.habitSettings,
    required this.taskSettings,
    required this.aiSettings,
  });

  // 初期状態
  factory NotificationSettingsState.initial() {
    return NotificationSettingsState(
      isLoading: false,
      error: null,
      overallSettings: OverallNotificationSettings.defaultSettings(),
      habitSettings: HabitNotificationSettings.defaultSettings(),
      taskSettings: TaskNotificationSettings.defaultSettings(),
      aiSettings: AINotificationSettings.defaultSettings(),
    );
  }

  // ローディング状態
  factory NotificationSettingsState.loading() {
    return NotificationSettingsState(
      isLoading: true,
      error: null,
      overallSettings: OverallNotificationSettings.defaultSettings(),
      habitSettings: HabitNotificationSettings.defaultSettings(),
      taskSettings: TaskNotificationSettings.defaultSettings(),
      aiSettings: AINotificationSettings.defaultSettings(),
    );
  }

  // エラー状態
  factory NotificationSettingsState.error(String error) {
    return NotificationSettingsState(
      isLoading: false,
      error: error,
      overallSettings: OverallNotificationSettings.defaultSettings(),
      habitSettings: HabitNotificationSettings.defaultSettings(),
      taskSettings: TaskNotificationSettings.defaultSettings(),
      aiSettings: AINotificationSettings.defaultSettings(),
    );
  }

  // JSON変換
  Map<String, dynamic> toJson() {
    return {
      'isLoading': isLoading,
      'error': error,
      'overallSettings': overallSettings.toJson(),
      'habitSettings': habitSettings.toJson(),
      'taskSettings': taskSettings.toJson(),
      'aiSettings': aiSettings.toJson(),
    };
  }

  factory NotificationSettingsState.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsState(
      isLoading: json['isLoading'] ?? false,
      error: json['error'],
      overallSettings: OverallNotificationSettings.fromJson(json['overallSettings'] ?? {}),
      habitSettings: HabitNotificationSettings.fromJson(json['habitSettings'] ?? {}),
      taskSettings: TaskNotificationSettings.fromJson(json['taskSettings'] ?? {}),
      aiSettings: AINotificationSettings.fromJson(json['aiSettings'] ?? {}),
    );
  }

  // コピー機能
  NotificationSettingsState copyWith({
    bool? isLoading,
    String? error,
    OverallNotificationSettings? overallSettings,
    HabitNotificationSettings? habitSettings,
    TaskNotificationSettings? taskSettings,
    AINotificationSettings? aiSettings,
  }) {
    return NotificationSettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      overallSettings: overallSettings ?? this.overallSettings,
      habitSettings: habitSettings ?? this.habitSettings,
      taskSettings: taskSettings ?? this.taskSettings,
      aiSettings: aiSettings ?? this.aiSettings,
    );
  }
} 