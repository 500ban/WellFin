import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';

/// タスクのデータモデル
/// Firestoreとの相互変換を行う
class TaskModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime scheduledDate;
  final DateTime? scheduledTimeStart;
  final DateTime? scheduledTimeEnd;
  final int estimatedDuration;
  final int? actualDuration;
  final DateTime? completedAt;
  final DateTime? reminderTime;
  final int priority;
  final String status;
  final int difficulty;
  final String? goalId;
  final String? milestoneId;
  final String? parentTaskId;
  final Map<String, dynamic>? repeatRule;
  final Map<String, dynamic>? location;
  final String? calendarEventId;
  final List<String> tags;
  final String color;
  final bool isSkippable;
  final double procrastinationRisk;
  final List<Map<String, dynamic>> subTasks;

  const TaskModel({
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
    this.priority = 3,
    this.status = 'pending',
    this.difficulty = 3,
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
  });

  /// FirestoreドキュメントからTaskModelを作成
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
      scheduledTimeStart: data['scheduledTimeStart'] != null 
          ? (data['scheduledTimeStart'] as Timestamp).toDate() 
          : null,
      scheduledTimeEnd: data['scheduledTimeEnd'] != null 
          ? (data['scheduledTimeEnd'] as Timestamp).toDate() 
          : null,
      estimatedDuration: data['estimatedDuration'] ?? 60,
      actualDuration: data['actualDuration'],
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
      reminderTime: data['reminderTime'] != null 
          ? (data['reminderTime'] as Timestamp).toDate() 
          : null,
      priority: data['priority'] ?? 3,
      status: data['status'] ?? 'pending',
      difficulty: data['difficulty'] ?? 3,
      goalId: data['goalId'],
      milestoneId: data['milestoneId'],
      parentTaskId: data['parentTaskId'],
      repeatRule: data['repeatRule'] as Map<String, dynamic>?,
      location: data['location'] as Map<String, dynamic>?,
      calendarEventId: data['calendarEventId'],
      tags: List<String>.from(data['tags'] ?? []),
      color: data['color'] ?? '#2196F3',
      isSkippable: data['isSkippable'] ?? false,
      procrastinationRisk: (data['procrastinationRisk'] ?? 0.0).toDouble(),
      subTasks: (data['subTasks'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }

  /// TaskModelをFirestoreドキュメントに変換
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'scheduledTimeStart': scheduledTimeStart != null 
          ? Timestamp.fromDate(scheduledTimeStart!) 
          : null,
      'scheduledTimeEnd': scheduledTimeEnd != null 
          ? Timestamp.fromDate(scheduledTimeEnd!) 
          : null,
      'estimatedDuration': estimatedDuration,
      'actualDuration': actualDuration,
      'completedAt': completedAt != null 
          ? Timestamp.fromDate(completedAt!) 
          : null,
      'reminderTime': reminderTime != null 
          ? Timestamp.fromDate(reminderTime!) 
          : null,
      'priority': priority,
      'status': status,
      'difficulty': difficulty,
      'goalId': goalId,
      'milestoneId': milestoneId,
      'parentTaskId': parentTaskId,
      'repeatRule': repeatRule,
      'location': location,
      'calendarEventId': calendarEventId,
      'tags': tags,
      'color': color,
      'isSkippable': isSkippable,
      'procrastinationRisk': procrastinationRisk,
      'subTasks': subTasks,
    };
  }

  /// ドメインエンティティからTaskModelを作成
  factory TaskModel.fromDomain(Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      createdAt: task.createdAt,
      scheduledDate: task.scheduledDate,
      scheduledTimeStart: task.scheduledTimeStart,
      scheduledTimeEnd: task.scheduledTimeEnd,
      estimatedDuration: task.estimatedDuration,
      actualDuration: task.actualDuration,
      completedAt: task.completedAt,
      reminderTime: task.reminderTime,
      priority: task.priority.value,
      status: task.status.value,
      difficulty: task.difficulty.value,
      goalId: task.goalId,
      milestoneId: task.milestoneId,
      parentTaskId: task.parentTaskId,
      repeatRule: task.repeatRule?.toMap(),
      location: task.location?.toMap(),
      calendarEventId: task.calendarEventId,
      tags: task.tags,
      color: task.color,
      isSkippable: task.isSkippable,
      procrastinationRisk: task.procrastinationRisk,
      subTasks: task.subTasks.map((subTask) => subTask.toMap()).toList(),
    );
  }

  /// TaskModelをドメインエンティティに変換
  Task toDomain() {
    return Task(
      id: id,
      title: title,
      description: description,
      createdAt: createdAt,
      scheduledDate: scheduledDate,
      scheduledTimeStart: scheduledTimeStart,
      scheduledTimeEnd: scheduledTimeEnd,
      estimatedDuration: estimatedDuration,
      actualDuration: actualDuration,
      completedAt: completedAt,
      reminderTime: reminderTime,
      priority: TaskPriority.fromValue(priority),
      status: TaskStatus.fromValue(status),
      difficulty: TaskDifficulty.fromValue(difficulty),
      goalId: goalId,
      milestoneId: milestoneId,
      parentTaskId: parentTaskId,
      repeatRule: repeatRule != null ? RepeatRuleModel.fromMap(repeatRule!).toDomain() : null,
      location: location != null ? TaskLocationModel.fromMap(location!).toDomain() : null,
      calendarEventId: calendarEventId,
      tags: tags,
      color: color,
      isSkippable: isSkippable,
      procrastinationRisk: procrastinationRisk,
      subTasks: subTasks.map((subTask) => SubTaskModel.fromMap(subTask).toDomain()).toList(),
    );
  }

  /// TaskModelをコピーして更新
  TaskModel copyWith({
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
    int? priority,
    String? status,
    int? difficulty,
    String? goalId,
    String? milestoneId,
    String? parentTaskId,
    Map<String, dynamic>? repeatRule,
    Map<String, dynamic>? location,
    String? calendarEventId,
    List<String>? tags,
    String? color,
    bool? isSkippable,
    double? procrastinationRisk,
    List<Map<String, dynamic>>? subTasks,
  }) {
    return TaskModel(
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
}

/// 繰り返しルールのデータモデル
class RepeatRuleModel {
  final String frequency;
  final int interval;
  final List<int>? daysOfWeek;
  final int? dayOfMonth;
  final DateTime? endDate;
  final int? count;

  const RepeatRuleModel({
    required this.frequency,
    this.interval = 1,
    this.daysOfWeek,
    this.dayOfMonth,
    this.endDate,
    this.count,
  });

  factory RepeatRuleModel.fromMap(Map<String, dynamic> map) {
    return RepeatRuleModel(
      frequency: map['frequency'] ?? 'daily',
      interval: map['interval'] ?? 1,
      daysOfWeek: map['daysOfWeek'] != null 
          ? List<int>.from(map['daysOfWeek']) 
          : null,
      dayOfMonth: map['dayOfMonth'],
      endDate: map['endDate'] != null 
          ? (map['endDate'] as Timestamp).toDate() 
          : null,
      count: map['count'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency,
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'dayOfMonth': dayOfMonth,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'count': count,
    };
  }

  RepeatRule toDomain() {
    return RepeatRule(
      frequency: frequency,
      interval: interval,
      daysOfWeek: daysOfWeek,
      dayOfMonth: dayOfMonth,
      endDate: endDate,
      count: count,
    );
  }
}

/// タスクの場所情報のデータモデル
class TaskLocationModel {
  final String name;
  final String address;
  final GeoPoint? coordinates;

  const TaskLocationModel({
    required this.name,
    required this.address,
    this.coordinates,
  });

  factory TaskLocationModel.fromMap(Map<String, dynamic> map) {
    return TaskLocationModel(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      coordinates: map['coordinates'] as GeoPoint?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'coordinates': coordinates,
    };
  }

  TaskLocation toDomain() {
    return TaskLocation(
      name: name,
      address: address,
      latitude: coordinates?.latitude,
      longitude: coordinates?.longitude,
    );
  }
}

/// サブタスクのデータモデル
class SubTaskModel {
  final String id;
  final String title;
  final DateTime? completedAt;

  const SubTaskModel({
    required this.id,
    required this.title,
    this.completedAt,
  });

  factory SubTaskModel.fromMap(Map<String, dynamic> map) {
    return SubTaskModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  SubTask toDomain() {
    return SubTask(
      id: id,
      title: title,
      completedAt: completedAt,
    );
  }
} 