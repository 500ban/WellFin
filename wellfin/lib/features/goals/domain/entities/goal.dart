import 'package:equatable/equatable.dart';

/// 目標のドメインエンティティ
/// ビジネスロジックとバリデーションを含む
class Goal extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime? targetDate;
  final GoalCategory category;
  final GoalPriority priority;
  final GoalStatus status;
  final double progress; // 0.0 - 1.0
  final List<Milestone> milestones;
  final List<String> tags;
  final String color;
  final bool isActive;
  final String? iconName;
  final String? notes;
  final GoalType type;
  final double targetValue; // 数値目標の場合の目標値
  final String? unit; // 単位（kg、km、回数など）
  final List<GoalProgress> progressHistory;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.startDate,
    this.targetDate,
    this.category = GoalCategory.personal,
    this.priority = GoalPriority.medium,
    this.status = GoalStatus.active,
    this.progress = 0.0,
    this.milestones = const [],
    this.tags = const [],
    this.color = '#2196F3',
    this.isActive = true,
    this.iconName,
    this.notes,
    this.type = GoalType.general,
    this.targetValue = 0.0,
    this.unit,
    this.progressHistory = const [],
  }) : assert(title.isNotEmpty, 'タイトルは必須です'),
       assert(progress >= 0.0 && progress <= 1.0, '進捗は0.0から1.0の間である必要があります'),
       assert(startDate.isBefore(targetDate ?? DateTime.now().add(const Duration(days: 365))), '開始日は目標日より前である必要があります');

  /// 目標が期限切れかどうか
  bool get isOverdue {
    if (targetDate == null) return false;
    final today = DateTime.now();
    return today.isAfter(targetDate!) && progress < 1.0;
  }

  /// 目標が進行中かどうか
  bool get isInProgress => status == GoalStatus.active && isActive && progress < 1.0;

  /// 目標が完了しているかどうか
  bool get isCompleted => progress >= 1.0 || status == GoalStatus.completed;

  /// 目標が一時停止中かどうか
  bool get isPaused => status == GoalStatus.paused;

  /// 目標がキャンセルされているかどうか
  bool get isCancelled => status == GoalStatus.cancelled;

  /// 残り日数
  int? get remainingDays {
    if (targetDate == null) return null;
    final today = DateTime.now();
    final remaining = targetDate!.difference(today).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// 目標の重要度スコア（優先度と期限を考慮）
  double get importanceScore {
    final priorityScore = priority.value;
    final deadlineScore = _calculateDeadlineScore();
    return (priorityScore * 0.7) + (deadlineScore * 0.3);
  }

  /// 完了したマイルストーンの数
  int get completedMilestonesCount {
    return milestones.where((milestone) => milestone.isCompleted).length;
  }

  /// マイルストーンの完了率
  double get milestonesProgress {
    if (milestones.isEmpty) return 0.0;
    return completedMilestonesCount / milestones.length;
  }

  /// 目標を完了状態に変更
  Goal markAsCompleted() {
    return copyWith(
      progress: 1.0,
      status: GoalStatus.completed,
    );
  }

  /// 目標を一時停止
  Goal pause() {
    return copyWith(
      status: GoalStatus.paused,
      isActive: false,
    );
  }

  /// 目標を再開
  Goal resume() {
    return copyWith(
      status: GoalStatus.active,
      isActive: true,
    );
  }

  /// 目標をキャンセル
  Goal cancel() {
    return copyWith(
      status: GoalStatus.cancelled,
      isActive: false,
    );
  }

  /// 進捗を更新
  Goal updateProgress(double newProgress) {
    final clampedProgress = newProgress.clamp(0.0, 1.0);
    final progressEntry = GoalProgress(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      progress: clampedProgress,
      notes: null,
    );
    
    return copyWith(
      progress: clampedProgress,
      progressHistory: [...progressHistory, progressEntry],
    );
  }

  /// マイルストーンを追加
  Goal addMilestone(Milestone milestone) {
    return copyWith(
      milestones: [...milestones, milestone],
    );
  }

  /// マイルストーンを更新
  Goal updateMilestone(String milestoneId, Milestone updatedMilestone) {
    final updatedMilestones = milestones.map((milestone) {
      return milestone.id == milestoneId ? updatedMilestone : milestone;
    }).toList();
    
    return copyWith(milestones: updatedMilestones);
  }

  /// マイルストーンを削除
  Goal removeMilestone(String milestoneId) {
    final updatedMilestones = milestones.where((milestone) => milestone.id != milestoneId).toList();
    return copyWith(milestones: updatedMilestones);
  }

  /// 期限スコアを計算（期限が近いほど高いスコア）
  double _calculateDeadlineScore() {
    if (targetDate == null) return 0.5; // 期限なしは中程度のスコア
    
    final today = DateTime.now();
    final daysUntilDeadline = targetDate!.difference(today).inDays;
    
    if (daysUntilDeadline <= 0) return 1.0; // 期限切れ
    if (daysUntilDeadline <= 7) return 0.9; // 1週間以内
    if (daysUntilDeadline <= 30) return 0.7; // 1ヶ月以内
    if (daysUntilDeadline <= 90) return 0.5; // 3ヶ月以内
    return 0.3; // それ以上
  }

  /// コピーメソッド
  Goal copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? targetDate,
    GoalCategory? category,
    GoalPriority? priority,
    GoalStatus? status,
    double? progress,
    List<Milestone>? milestones,
    List<String>? tags,
    String? color,
    bool? isActive,
    String? iconName,
    String? notes,
    GoalType? type,
    double? targetValue,
    String? unit,
    List<GoalProgress>? progressHistory,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      milestones: milestones ?? this.milestones,
      tags: tags ?? this.tags,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      iconName: iconName ?? this.iconName,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      progressHistory: progressHistory ?? this.progressHistory,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    createdAt,
    startDate,
    targetDate,
    category,
    priority,
    status,
    progress,
    milestones,
    tags,
    color,
    isActive,
    iconName,
    notes,
    type,
    targetValue,
    unit,
    progressHistory,
  ];
}

/// マイルストーンのドメインエンティティ
class Milestone extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime targetDate;
  final double progress;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? notes;

  Milestone({
    required this.id,
    required this.title,
    required this.description,
    required this.targetDate,
    this.progress = 0.0,
    this.isCompleted = false,
    this.completedAt,
    this.notes,
  }) : assert(title.isNotEmpty, 'タイトルは必須です'),
       assert(progress >= 0.0 && progress <= 1.0, '進捗は0.0から1.0の間である必要があります');

  /// マイルストーンを完了状態に変更
  Milestone markAsCompleted() {
    return copyWith(
      progress: 1.0,
      isCompleted: true,
      completedAt: DateTime.now(),
    );
  }

  /// 進捗を更新
  Milestone updateProgress(double newProgress) {
    final clampedProgress = newProgress.clamp(0.0, 1.0);
    return copyWith(
      progress: clampedProgress,
      isCompleted: clampedProgress >= 1.0,
      completedAt: clampedProgress >= 1.0 ? DateTime.now() : completedAt,
    );
  }

  /// コピーメソッド
  Milestone copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? targetDate,
    double? progress,
    bool? isCompleted,
    DateTime? completedAt,
    String? notes,
  }) {
    return Milestone(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    targetDate,
    progress,
    isCompleted,
    completedAt,
    notes,
  ];
}

/// 目標進捗のドメインエンティティ
class GoalProgress extends Equatable {
  final String id;
  final DateTime date;
  final double progress;
  final String? notes;

  GoalProgress({
    required this.id,
    required this.date,
    required this.progress,
    this.notes,
  }) : assert(progress >= 0.0 && progress <= 1.0, '進捗は0.0から1.0の間である必要があります');

  /// Mapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'progress': progress,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [id, date, progress, notes];
}

/// 目標カテゴリ
enum GoalCategory {
  personal('personal', '個人'),
  health('health', '健康'),
  work('work', '仕事'),
  learning('learning', '学習'),
  fitness('fitness', 'フィットネス'),
  financial('financial', '財務'),
  creative('creative', '創造性'),
  social('social', '社交'),
  travel('travel', '旅行'),
  other('other', 'その他');

  const GoalCategory(this.value, this.label);
  final String value;
  final String label;
}

/// 目標優先度
enum GoalPriority {
  low(1, '低'),
  medium(2, '中'),
  high(3, '高'),
  critical(4, '最重要');

  const GoalPriority(this.value, this.label);
  final int value;
  final String label;
}

/// 目標ステータス
enum GoalStatus {
  active('active', 'アクティブ'),
  paused('paused', '一時停止'),
  completed('completed', '完了'),
  cancelled('cancelled', 'キャンセル');

  const GoalStatus(this.value, this.label);
  final String value;
  final String label;
}

/// 目標タイプ
enum GoalType {
  general('general', '一般'),
  numeric('numeric', '数値目標'),
  habit('habit', '習慣形成'),
  project('project', 'プロジェクト'),
  milestone('milestone', 'マイルストーン');

  const GoalType(this.value, this.label);
  final String value;
  final String label;
}

/// 目標並び替えオプション
enum GoalSortOption {
  createdAt('createdAt', '作成日順'),
  title('title', 'タイトル順'),
  priority('priority', '優先度順'),
  deadline('deadline', '期限順'),
  progress('progress', '進捗順'),
  importance('importance', '重要度順');

  const GoalSortOption(this.value, this.label);
  final String value;
  final String label;
} 