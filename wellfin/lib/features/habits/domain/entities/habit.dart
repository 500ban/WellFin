import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// 習慣のドメインエンティティ
/// ビジネスロジックとバリデーションを含む
class Habit extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime? endDate;
  final HabitCategory category;
  final HabitFrequency frequency;
  final List<HabitDay> targetDays; // 週のどの曜日を対象にするか
  final TimeOfDay? reminderTime;
  final HabitPriority priority;
  final HabitStatus status;
  final int currentStreak; // 現在の連続達成日数
  final int longestStreak; // 最長連続達成日数
  final int totalCompletions; // 総達成回数
  final List<HabitCompletion> completions; // 達成履歴
  final String? goalId;
  final List<String> tags;
  final String color;
  final bool isActive;
  final String? iconName;
  final int targetCount; // 1日あたりの目標回数（デフォルト1）
  final String? notes;

  Habit({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.startDate,
    this.endDate,
    this.category = HabitCategory.personal,
    this.frequency = HabitFrequency.daily,
    this.targetDays = const [],
    this.reminderTime,
    this.priority = HabitPriority.medium,
    this.status = HabitStatus.active,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalCompletions = 0,
    this.completions = const [],
    this.goalId,
    this.tags = const [],
    this.color = '#4CAF50',
    this.isActive = true,
    this.iconName,
    this.targetCount = 1,
    this.notes,
  }) : assert(title.isNotEmpty, 'タイトルは必須です'),
       assert(targetCount > 0, '目標回数は0より大きい必要があります'),
       assert(startDate.isBefore(endDate ?? DateTime.now().add(const Duration(days: 365))), '開始日は終了日より前である必要があります');

  /// 習慣が今日完了しているかどうか
  bool get isCompletedToday {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return completions.any((completion) {
      final completionDate = DateTime(
        completion.completedAt.year,
        completion.completedAt.month,
        completion.completedAt.day,
      );
      return completionDate.isAtSameMomentAs(todayDate);
    });
  }

  /// 習慣が今日の対象日かどうか
  bool get isTodayTarget {
    final today = DateTime.now();
    final weekday = today.weekday;
    final startDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    
    switch (frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.everyOtherDay:
        // 開始日から何日経過したかを計算
        final daysSinceStart = todayOnly.difference(startDateOnly).inDays;
        return daysSinceStart % 2 == 0;
      case HabitFrequency.twiceAWeek:
        // 週2回の場合は、開始日から3日おきに実行
        final daysSinceStart = todayOnly.difference(startDateOnly).inDays;
        return daysSinceStart % 3 == 0;
      case HabitFrequency.threeTimesAWeek:
        // 週3回の場合は、開始日から2日おきに実行
        final daysSinceStart = todayOnly.difference(startDateOnly).inDays;
        return daysSinceStart % 2 == 0;
      case HabitFrequency.weekly:
        return targetDays.any((day) => day.value == weekday);
      case HabitFrequency.twiceAMonth:
        // 月2回の場合は、開始日の日付と15日後に実行
        final startDay = startDate.day;
        final todayDay = today.day;
        return todayDay == startDay || todayDay == (startDay + 15) % 30;
      case HabitFrequency.monthly:
        // 月1回の場合は毎月同じ日に実行
        return today.day == startDate.day;
      case HabitFrequency.quarterly:
        // 四半期に1回の場合は、開始日から3ヶ月おきに実行
        final monthsSinceStart = (today.year - startDate.year) * 12 + (today.month - startDate.month);
        return monthsSinceStart % 3 == 0 && today.day == startDate.day;
      case HabitFrequency.yearly:
        // 年に1回の場合は、毎年同じ月日に実行
        return today.month == startDate.month && today.day == startDate.day;
      case HabitFrequency.custom:
        return targetDays.any((day) => day.value == weekday);
    }
  }

  /// 習慣が期限切れかどうか
  bool get isOverdue {
    if (endDate == null) return false;
    final today = DateTime.now();
    return today.isAfter(endDate!) && !isCompletedToday;
  }

  /// 習慣が進行中かどうか
  bool get isInProgress => status == HabitStatus.active && isActive;

  /// 習慣が完了しているかどうか
  bool get isCompleted => status == HabitStatus.finished;

  /// 習慣が一時停止中かどうか
  bool get isPaused => status == HabitStatus.paused;

  /// 今日の達成回数
  int get todayCompletions {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return completions.where((completion) {
      final completionDate = DateTime(
        completion.completedAt.year,
        completion.completedAt.month,
        completion.completedAt.day,
      );
      return completionDate.isAtSameMomentAs(todayDate);
    }).length;
  }

  /// 今日の目標達成率（0.0 - 1.0）
  double get todayProgress {
    if (targetCount == 0) return 0.0;
    return (todayCompletions / targetCount).clamp(0.0, 1.0);
  }

  /// 習慣の重要度スコア（優先度と頻度を考慮）
  double get importanceScore {
    final priorityScore = priority.value;
    final frequencyScore = frequency.value;
    return (priorityScore * 0.6) + (frequencyScore * 0.4);
  }

  /// 習慣を完了状態に変更
  Habit markAsCompleted() {
    final now = DateTime.now();
    
    // 今日の完了記録を作成
    final completion = HabitCompletion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      completedAt: now,
      notes: null,
    );
    
    // 新しい完了リストを作成
    final newCompletions = [...completions, completion];
    
    // ストリークを計算
    final newCurrentStreak = _calculateCurrentStreak(newCompletions);
    final newLongestStreak = newCurrentStreak > longestStreak 
        ? newCurrentStreak 
        : longestStreak;
    
    return copyWith(
      completions: newCompletions,
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
      totalCompletions: totalCompletions + 1,
    );
  }

  /// 習慣を一時停止
  Habit pause() {
    return copyWith(
      status: HabitStatus.paused,
      isActive: false,
    );
  }

  /// 習慣を再開
  Habit resume() {
    return copyWith(
      status: HabitStatus.active,
      isActive: true,
    );
  }

  /// 習慣を完了
  Habit complete() {
    return copyWith(status: HabitStatus.finished);
  }

  /// 習慣を削除（論理削除）
  Habit deactivate() {
    return copyWith(isActive: false);
  }

  /// タグを追加
  Habit addTag(String tag) {
    if (tags.contains(tag)) return this;
    return copyWith(tags: [...tags, tag]);
  }

  /// タグを削除
  Habit removeTag(String tag) {
    return copyWith(tags: tags.where((t) => t != tag).toList());
  }

  /// 現在のストリークを計算
  int _calculateCurrentStreak(List<HabitCompletion> completions) {
    if (completions.isEmpty) return 0;
    
    final sortedCompletions = completions
        .map((c) => DateTime(
              c.completedAt.year,
              c.completedAt.month,
              c.completedAt.day,
            ))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // 降順ソート
    
    if (sortedCompletions.isEmpty) return 0;
    
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // 今日が完了済みでない場合は0
    if (!sortedCompletions.any((date) => date.isAtSameMomentAs(todayDate))) {
      return 0;
    }
    
    int streak = 0;
    DateTime currentDate = todayDate;
    
    for (final completionDate in sortedCompletions) {
      if (completionDate.isAtSameMomentAs(currentDate)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else if (completionDate.isBefore(currentDate)) {
        break;
      }
    }
    
    return streak;
  }

  /// 習慣のコピーを作成（指定されたフィールドを更新）
  Habit copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    HabitCategory? category,
    HabitFrequency? frequency,
    List<HabitDay>? targetDays,
    TimeOfDay? reminderTime,
    HabitPriority? priority,
    HabitStatus? status,
    int? currentStreak,
    int? longestStreak,
    int? totalCompletions,
    List<HabitCompletion>? completions,
    String? goalId,
    List<String>? tags,
    String? color,
    bool? isActive,
    String? iconName,
    int? targetCount,
    String? notes,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      targetDays: targetDays ?? this.targetDays,
      reminderTime: reminderTime ?? this.reminderTime,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      completions: completions ?? this.completions,
      goalId: goalId ?? this.goalId,
      tags: tags ?? this.tags,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      iconName: iconName ?? this.iconName,
      targetCount: targetCount ?? this.targetCount,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    createdAt,
    startDate,
    endDate,
    category,
    frequency,
    targetDays,
    reminderTime,
    priority,
    status,
    currentStreak,
    longestStreak,
    totalCompletions,
    completions,
    goalId,
    tags,
    color,
    isActive,
    iconName,
    targetCount,
    notes,
  ];
}

/// 習慣の完了記録
class HabitCompletion extends Equatable {
  final String id;
  final DateTime completedAt;
  final String? notes;

  const HabitCompletion({
    required this.id,
    required this.completedAt,
    this.notes,
  });

  HabitCompletion copyWith({
    String? id,
    DateTime? completedAt,
    String? notes,
  }) {
    return HabitCompletion(
      id: id ?? this.id,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  /// Mapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'completedAt': completedAt,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [id, completedAt, notes];
}

/// 習慣のカテゴリ
enum HabitCategory {
  personal('個人'),
  health('健康'),
  work('仕事'),
  learning('学習'),
  fitness('フィットネス'),
  mindfulness('マインドフルネス'),
  social('社交'),
  financial('財務'),
  creative('創造性'),
  other('その他');

  const HabitCategory(this.label);
  final String label;

  int get value {
    switch (this) {
      case HabitCategory.health:
        return 5;
      case HabitCategory.work:
        return 4;
      case HabitCategory.learning:
        return 4;
      case HabitCategory.fitness:
        return 3;
      case HabitCategory.mindfulness:
        return 3;
      case HabitCategory.personal:
        return 2;
      case HabitCategory.social:
        return 2;
      case HabitCategory.financial:
        return 2;
      case HabitCategory.creative:
        return 1;
      case HabitCategory.other:
        return 1;
    }
  }
}

/// 習慣の頻度
enum HabitFrequency {
  daily('毎日'),
  everyOtherDay('隔日'),
  twiceAWeek('週2回'),
  threeTimesAWeek('週3回'),
  weekly('毎週'),
  twiceAMonth('月2回'),
  monthly('毎月'),
  quarterly('四半期'),
  yearly('毎年'),
  custom('カスタム');

  const HabitFrequency(this.label);
  final String label;

  int get value {
    switch (this) {
      case HabitFrequency.daily:
        return 5;
      case HabitFrequency.everyOtherDay:
        return 4;
      case HabitFrequency.threeTimesAWeek:
        return 4;
      case HabitFrequency.twiceAWeek:
        return 3;
      case HabitFrequency.weekly:
        return 3;
      case HabitFrequency.twiceAMonth:
        return 2;
      case HabitFrequency.monthly:
        return 2;
      case HabitFrequency.quarterly:
        return 1;
      case HabitFrequency.yearly:
        return 1;
      case HabitFrequency.custom:
        return 1;
    }
  }

  /// 頻度の説明を取得
  String get description {
    switch (this) {
      case HabitFrequency.daily:
        return '毎日実行';
      case HabitFrequency.everyOtherDay:
        return '1日おきに実行';
      case HabitFrequency.twiceAWeek:
        return '週に2回実行';
      case HabitFrequency.threeTimesAWeek:
        return '週に3回実行';
      case HabitFrequency.weekly:
        return '週に1回実行';
      case HabitFrequency.twiceAMonth:
        return '月に2回実行';
      case HabitFrequency.monthly:
        return '月に1回実行';
      case HabitFrequency.quarterly:
        return '3ヶ月に1回実行';
      case HabitFrequency.yearly:
        return '年に1回実行';
      case HabitFrequency.custom:
        return 'カスタム設定';
    }
  }

  /// 頻度に応じたアイコンを取得
  IconData get icon {
    switch (this) {
      case HabitFrequency.daily:
        return Icons.calendar_today;
      case HabitFrequency.everyOtherDay:
        return Icons.calendar_view_day;
      case HabitFrequency.twiceAWeek:
        return Icons.calendar_view_week;
      case HabitFrequency.threeTimesAWeek:
        return Icons.calendar_view_week;
      case HabitFrequency.weekly:
        return Icons.calendar_view_week;
      case HabitFrequency.twiceAMonth:
        return Icons.calendar_view_month;
      case HabitFrequency.monthly:
        return Icons.calendar_view_month;
      case HabitFrequency.quarterly:
        return Icons.calendar_view_month;
      case HabitFrequency.yearly:
        return Icons.calendar_view_month;
      case HabitFrequency.custom:
        return Icons.settings;
    }
  }
}

/// 習慣の優先度
enum HabitPriority {
  low('低'),
  medium('中'),
  high('高'),
  critical('最重要');

  const HabitPriority(this.label);
  final String label;

  int get value {
    switch (this) {
      case HabitPriority.low:
        return 1;
      case HabitPriority.medium:
        return 2;
      case HabitPriority.high:
        return 3;
      case HabitPriority.critical:
        return 4;
    }
  }
}

/// 習慣のステータス
enum HabitStatus {
  active('アクティブ'),
  paused('一時停止'),
  finished('終了');

  const HabitStatus(this.label);
  final String label;

  String get value {
    switch (this) {
      case HabitStatus.active:
        return 'active';
      case HabitStatus.paused:
        return 'paused';
      case HabitStatus.finished:
        return 'finished';
    }
  }
}

/// 曜日
enum HabitDay {
  monday('月曜日', 1),
  tuesday('火曜日', 2),
  wednesday('水曜日', 3),
  thursday('木曜日', 4),
  friday('金曜日', 5),
  saturday('土曜日', 6),
  sunday('日曜日', 7);

  const HabitDay(this.label, this.value);
  final String label;
  final int value;
} 