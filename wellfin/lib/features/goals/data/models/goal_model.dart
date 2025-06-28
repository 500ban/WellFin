import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/goal.dart';

/// 目標のデータモデル
/// Firestoreとの相互変換を行う
class GoalModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime? targetDate;
  final String category;
  final int priority;
  final String status;
  final double progress;
  final List<Map<String, dynamic>> milestones;
  final List<String> tags;
  final String color;
  final bool isActive;
  final String? iconName;
  final String? notes;
  final String type;
  final double targetValue;
  final String? unit;
  final List<Map<String, dynamic>> progressHistory;

  const GoalModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.startDate,
    this.targetDate,
    this.category = 'personal',
    this.priority = 2,
    this.status = 'active',
    this.progress = 0.0,
    this.milestones = const [],
    this.tags = const [],
    this.color = '#2196F3',
    this.isActive = true,
    this.iconName,
    this.notes,
    this.type = 'general',
    this.targetValue = 0.0,
    this.unit,
    this.progressHistory = const [],
  });

  /// FirestoreドキュメントからGoalModelを作成
  factory GoalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GoalModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      targetDate: data['targetDate'] != null 
          ? (data['targetDate'] as Timestamp).toDate() 
          : null,
      category: data['category'] ?? 'personal',
      priority: data['priority'] ?? 2,
      status: data['status'] ?? 'active',
      progress: (data['progress'] ?? 0.0).toDouble(),
      milestones: (data['milestones'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      tags: List<String>.from(data['tags'] ?? []),
      color: data['color'] ?? '#2196F3',
      isActive: data['isActive'] ?? true,
      iconName: data['iconName'],
      notes: data['notes'],
      type: data['type'] ?? 'general',
      targetValue: (data['targetValue'] ?? 0.0).toDouble(),
      unit: data['unit'],
      progressHistory: (data['progressHistory'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }

  /// GoalModelをFirestoreドキュメントに変換
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'startDate': Timestamp.fromDate(startDate),
      'targetDate': targetDate != null 
          ? Timestamp.fromDate(targetDate!) 
          : null,
      'category': category,
      'priority': priority,
      'status': status,
      'progress': progress,
      'milestones': milestones,
      'tags': tags,
      'color': color,
      'isActive': isActive,
      'iconName': iconName,
      'notes': notes,
      'type': type,
      'targetValue': targetValue,
      'unit': unit,
      'progressHistory': progressHistory,
    };
  }

  /// ドメインエンティティからGoalModelを作成
  factory GoalModel.fromDomain(Goal goal) {
    return GoalModel(
      id: goal.id,
      title: goal.title,
      description: goal.description,
      createdAt: goal.createdAt,
      startDate: goal.startDate,
      targetDate: goal.targetDate,
      category: goal.category.name,
      priority: goal.priority.value,
      status: goal.status.value,
      progress: goal.progress,
      milestones: goal.milestones.map((milestone) => MilestoneModel.fromDomain(milestone).toMap()).toList(),
      tags: goal.tags,
      color: goal.color,
      isActive: goal.isActive,
      iconName: goal.iconName,
      notes: goal.notes,
      type: goal.type.name,
      targetValue: goal.targetValue,
      unit: goal.unit,
      progressHistory: goal.progressHistory.map((progress) => progress.toMap()).toList(),
    );
  }

  /// GoalModelをドメインエンティティに変換
  Goal toDomain() {
    return Goal(
      id: id,
      title: title,
      description: description,
      createdAt: createdAt,
      startDate: startDate,
      targetDate: targetDate,
      category: GoalCategory.values.firstWhere(
        (c) => c.name == category,
        orElse: () => GoalCategory.personal,
      ),
      priority: GoalPriority.values.firstWhere(
        (p) => p.value == priority,
        orElse: () => GoalPriority.medium,
      ),
      status: GoalStatus.values.firstWhere(
        (s) => s.value == status,
        orElse: () => GoalStatus.active,
      ),
      progress: progress,
      milestones: milestones.map((milestone) => MilestoneModel.fromMap(milestone).toDomain()).toList(),
      tags: tags,
      color: color,
      isActive: isActive,
      iconName: iconName,
      notes: notes,
      type: GoalType.values.firstWhere(
        (t) => t.name == type,
        orElse: () => GoalType.general,
      ),
      targetValue: targetValue,
      unit: unit,
      progressHistory: progressHistory.map((progress) => GoalProgressModel.fromMap(progress).toDomain()).toList(),
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

/// マイルストーンのデータモデル
class MilestoneModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime targetDate;
  final double progress;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? notes;

  const MilestoneModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetDate,
    this.progress = 0.0,
    this.isCompleted = false,
    this.completedAt,
    this.notes,
  });

  /// MapからMilestoneModelを作成
  factory MilestoneModel.fromMap(Map<String, dynamic> map) {
    return MilestoneModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      targetDate: (map['targetDate'] as Timestamp).toDate(),
      progress: (map['progress'] ?? 0.0).toDouble(),
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate() 
          : null,
      notes: map['notes'],
    );
  }

  /// ドメインエンティティからMilestoneModelを作成
  factory MilestoneModel.fromDomain(Milestone milestone) {
    return MilestoneModel(
      id: milestone.id,
      title: milestone.title,
      description: milestone.description,
      targetDate: milestone.targetDate,
      progress: milestone.progress,
      isCompleted: milestone.isCompleted,
      completedAt: milestone.completedAt,
      notes: milestone.notes,
    );
  }

  /// MilestoneModelをMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetDate': Timestamp.fromDate(targetDate),
      'progress': progress,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null 
          ? Timestamp.fromDate(completedAt!) 
          : null,
      'notes': notes,
    };
  }

  /// MilestoneModelをドメインエンティティに変換
  Milestone toDomain() {
    return Milestone(
      id: id,
      title: title,
      description: description,
      targetDate: targetDate,
      progress: progress,
      isCompleted: isCompleted,
      completedAt: completedAt,
      notes: notes,
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

/// 目標進捗のデータモデル
class GoalProgressModel extends Equatable {
  final String id;
  final DateTime date;
  final double progress;
  final String? notes;

  const GoalProgressModel({
    required this.id,
    required this.date,
    required this.progress,
    this.notes,
  });

  /// MapからGoalProgressModelを作成
  factory GoalProgressModel.fromMap(Map<String, dynamic> map) {
    return GoalProgressModel(
      id: map['id'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      progress: (map['progress'] ?? 0.0).toDouble(),
      notes: map['notes'],
    );
  }

  /// ドメインエンティティからGoalProgressModelを作成
  factory GoalProgressModel.fromDomain(GoalProgress progress) {
    return GoalProgressModel(
      id: progress.id,
      date: progress.date,
      progress: progress.progress,
      notes: progress.notes,
    );
  }

  /// GoalProgressModelをMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'progress': progress,
      'notes': notes,
    };
  }

  /// GoalProgressModelをドメインエンティティに変換
  GoalProgress toDomain() {
    return GoalProgress(
      id: id,
      date: date,
      progress: progress,
      notes: notes,
    );
  }

  @override
  List<Object?> get props => [id, date, progress, notes];
} 