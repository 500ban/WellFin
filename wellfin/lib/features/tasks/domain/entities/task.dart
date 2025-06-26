import 'package:equatable/equatable.dart';

/// タスクのドメインエンティティ
/// ビジネスロジックとバリデーションを含む
class Task extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime scheduledDate;
  final DateTime? scheduledTimeStart;
  final DateTime? scheduledTimeEnd;
  final int estimatedDuration; // 分単位
  final int? actualDuration; // 分単位
  final DateTime? completedAt;
  final DateTime? reminderTime;
  final TaskPriority priority;
  final TaskStatus status;
  final TaskDifficulty difficulty;
  final String? goalId;
  final String? milestoneId;
  final String? parentTaskId;
  final RepeatRule? repeatRule;
  final TaskLocation? location;
  final String? calendarEventId;
  final List<String> tags;
  final String color;
  final bool isSkippable;
  final double procrastinationRisk; // 0.0 - 1.0
  final List<SubTask> subTasks;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.scheduledDate,
    this.scheduledTimeStart,
    this.scheduledTimeEnd,
    this.estimatedDuration = 60,
    this.actualDuration,
    this.completedAt,
    this.reminderTime,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.difficulty = TaskDifficulty.medium,
    this.goalId,
    this.milestoneId,
    this.parentTaskId,
    this.repeatRule,
    this.location,
    this.calendarEventId,
    this.tags = const [],
    this.color = '#2196F3',
    this.isSkippable = false,
    this.procrastinationRisk = 0.0,
    this.subTasks = const [],
  }) : assert(title.isNotEmpty, 'タイトルは必須です'),
       assert(estimatedDuration > 0, '予想時間は0より大きい必要があります'),
       assert(procrastinationRisk >= 0.0 && procrastinationRisk <= 1.0, '先延ばしリスクは0.0-1.0の範囲である必要があります');

  /// タスクが完了しているかどうか
  bool get isCompleted => status == TaskStatus.completed;

  /// タスクが期限切れかどうか
  bool get isOverdue {
    final now = DateTime.now();
    return scheduledDate.isBefore(DateTime(now.year, now.month, now.day)) && !isCompleted;
  }

  /// タスクが今日のタスクかどうか
  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
           scheduledDate.month == now.month &&
           scheduledDate.day == now.day;
  }

  /// タスクが進行中かどうか
  bool get isInProgress => status == TaskStatus.inProgress;

  /// タスクが遅延しているかどうか
  bool get isDelayed => status == TaskStatus.delayed;

  /// タスクの進捗率（0.0 - 1.0）
  double get progress {
    if (isCompleted) return 1.0;
    if (subTasks.isEmpty) return 0.0;
    
    final completedSubTasks = subTasks.where((task) => task.isCompleted).length;
    return completedSubTasks / subTasks.length;
  }

  /// タスクの残り時間（分）
  int? get remainingTime {
    if (actualDuration != null) return null;
    if (scheduledTimeStart == null || scheduledTimeEnd == null) return estimatedDuration;
    
    final now = DateTime.now();
    if (now.isAfter(scheduledTimeEnd!)) return 0;
    if (now.isBefore(scheduledTimeStart!)) return estimatedDuration;
    
    return scheduledTimeEnd!.difference(now).inMinutes;
  }

  /// タスクの重要度スコア（優先度と難易度を考慮）
  double get importanceScore {
    final priorityScore = priority.value;
    final difficultyScore = difficulty.value;
    return (priorityScore * 0.7) + (difficultyScore * 0.3);
  }

  /// タスクを完了状態に変更
  Task markAsCompleted() {
    return copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
      actualDuration: actualDuration ?? estimatedDuration,
    );
  }

  /// タスクを進行中状態に変更
  Task markAsInProgress() {
    return copyWith(status: TaskStatus.inProgress);
  }

  /// タスクを遅延状態に変更
  Task markAsDelayed() {
    return copyWith(status: TaskStatus.delayed);
  }

  /// タスクを保留状態に変更
  Task markAsPending() {
    return copyWith(status: TaskStatus.pending);
  }

  /// サブタスクを追加
  Task addSubTask(SubTask subTask) {
    return copyWith(
      subTasks: [...subTasks, subTask],
    );
  }

  /// サブタスクを削除
  Task removeSubTask(String subTaskId) {
    return copyWith(
      subTasks: subTasks.where((task) => task.id != subTaskId).toList(),
    );
  }

  /// サブタスクを完了
  Task completeSubTask(String subTaskId) {
    final updatedSubTasks = subTasks.map((task) {
      if (task.id == subTaskId) {
        return task.copyWith(completedAt: DateTime.now());
      }
      return task;
    }).toList();

    return copyWith(subTasks: updatedSubTasks);
  }

  /// タグを追加
  Task addTag(String tag) {
    if (tags.contains(tag)) return this;
    return copyWith(tags: [...tags, tag]);
  }

  /// タグを削除
  Task removeTag(String tag) {
    return copyWith(tags: tags.where((t) => t != tag).toList());
  }

  /// タスクのコピーを作成（指定されたフィールドを更新）
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? scheduledDate,
    DateTime? scheduledTimeStart,
    DateTime? scheduledTimeEnd,
    int? estimatedDuration,
    int? actualDuration,
    DateTime? completedAt,
    DateTime? reminderTime,
    TaskPriority? priority,
    TaskStatus? status,
    TaskDifficulty? difficulty,
    String? goalId,
    String? milestoneId,
    String? parentTaskId,
    RepeatRule? repeatRule,
    TaskLocation? location,
    String? calendarEventId,
    List<String>? tags,
    String? color,
    bool? isSkippable,
    double? procrastinationRisk,
    List<SubTask>? subTasks,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTimeStart: scheduledTimeStart ?? this.scheduledTimeStart,
      scheduledTimeEnd: scheduledTimeEnd ?? this.scheduledTimeEnd,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      completedAt: completedAt ?? this.completedAt,
      reminderTime: reminderTime ?? this.reminderTime,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      goalId: goalId ?? this.goalId,
      milestoneId: milestoneId ?? this.milestoneId,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      repeatRule: repeatRule ?? this.repeatRule,
      location: location ?? this.location,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      tags: tags ?? this.tags,
      color: color ?? this.color,
      isSkippable: isSkippable ?? this.isSkippable,
      procrastinationRisk: procrastinationRisk ?? this.procrastinationRisk,
      subTasks: subTasks ?? this.subTasks,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    createdAt,
    scheduledDate,
    scheduledTimeStart,
    scheduledTimeEnd,
    estimatedDuration,
    actualDuration,
    completedAt,
    reminderTime,
    priority,
    status,
    difficulty,
    goalId,
    milestoneId,
    parentTaskId,
    repeatRule,
    location,
    calendarEventId,
    tags,
    color,
    isSkippable,
    procrastinationRisk,
    subTasks,
  ];

  @override
  String toString() {
    return 'Task(id: $id, title: $title, status: $status, priority: $priority)';
  }
}

/// タスクの優先度
enum TaskPriority {
  low(1, '低'),
  medium(3, '中'),
  high(5, '高'),
  urgent(7, '緊急');

  const TaskPriority(this.value, this.label);
  final int value;
  final String label;

  static TaskPriority fromValue(int value) {
    return TaskPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

/// タスクのステータス
enum TaskStatus {
  pending('pending', '保留中'),
  inProgress('in_progress', '進行中'),
  completed('completed', '完了'),
  delayed('delayed', '遅延');

  const TaskStatus(this.value, this.label);
  final String value;
  final String label;

  static TaskStatus fromValue(String value) {
    return TaskStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TaskStatus.pending,
    );
  }
}

/// タスクの難易度
enum TaskDifficulty {
  easy(1, '簡単'),
  medium(3, '普通'),
  hard(5, '困難'),
  expert(7, '専門的');

  const TaskDifficulty(this.value, this.label);
  final int value;
  final String label;

  static TaskDifficulty fromValue(int value) {
    return TaskDifficulty.values.firstWhere(
      (difficulty) => difficulty.value == value,
      orElse: () => TaskDifficulty.medium,
    );
  }
}

/// 繰り返しルール
class RepeatRule extends Equatable {
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final int interval;
  final List<int>? daysOfWeek; // 0=日曜日, 1=月曜日, ...
  final int? dayOfMonth; // 1-31
  final DateTime? endDate;
  final int? count;

  RepeatRule({
    required this.frequency,
    this.interval = 1,
    this.daysOfWeek,
    this.dayOfMonth,
    this.endDate,
    this.count,
  }) : assert(interval > 0, '間隔は0より大きい必要があります'),
       assert(daysOfWeek == null || daysOfWeek.every((day) => day >= 0 && day <= 6), '曜日は0-6の範囲である必要があります'),
       assert(dayOfMonth == null || (dayOfMonth >= 1 && dayOfMonth <= 31), '日付は1-31の範囲である必要があります');

  /// 次の繰り返し日を計算
  DateTime getNextOccurrence(DateTime fromDate) {
    switch (frequency) {
      case 'daily':
        return fromDate.add(Duration(days: interval));
      case 'weekly':
        return fromDate.add(Duration(days: 7 * interval));
      case 'monthly':
        final nextMonth = DateTime(fromDate.year, fromDate.month + interval, fromDate.day);
        return nextMonth;
      case 'yearly':
        return DateTime(fromDate.year + interval, fromDate.month, fromDate.day);
      default:
        return fromDate.add(Duration(days: interval));
    }
  }

  /// 繰り返しが終了しているかどうか
  bool get isEnded {
    if (endDate != null) {
      return DateTime.now().isAfter(endDate!);
    }
    if (count != null) {
      // 実装が必要（現在の繰り返し回数を追跡する必要がある）
      return false;
    }
    return false;
  }

  @override
  List<Object?> get props => [frequency, interval, daysOfWeek, dayOfMonth, endDate, count];

  /// Mapに変換
  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency,
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'dayOfMonth': dayOfMonth,
      'endDate': endDate,
      'count': count,
    };
  }
}

/// タスクの場所情報
class TaskLocation extends Equatable {
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;

  TaskLocation({
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
  }) : assert(name.isNotEmpty, '場所名は必須です'),
       assert(address.isNotEmpty, '住所は必須です');

  /// 座標が設定されているかどうか
  bool get hasCoordinates => latitude != null && longitude != null;

  @override
  List<Object?> get props => [name, address, latitude, longitude];

  /// Mapに変換
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

/// サブタスク
class SubTask extends Equatable {
  final String id;
  final String title;
  final DateTime? completedAt;

  SubTask({
    required this.id,
    required this.title,
    this.completedAt,
  }) : assert(title.isNotEmpty, 'サブタスクのタイトルは必須です');

  /// サブタスクが完了しているかどうか
  bool get isCompleted => completedAt != null;

  /// サブタスクを完了状態に変更
  SubTask markAsCompleted() {
    return copyWith(completedAt: DateTime.now());
  }

  /// サブタスクを未完了状態に変更
  SubTask markAsIncomplete() {
    return copyWith(completedAt: null);
  }

  /// サブタスクのコピーを作成
  SubTask copyWith({
    String? id,
    String? title,
    DateTime? completedAt,
  }) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, completedAt];

  /// Mapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'completedAt': completedAt,
    };
  }
} 