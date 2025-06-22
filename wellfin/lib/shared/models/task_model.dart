import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
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
  final TaskStatus status;
  final int difficulty;
  final String? goalId;
  final String? milestoneId;
  final String? parentTaskId;
  final RepeatRule? repeatRule;
  final TaskLocation? location;
  final String? calendarEventId;
  final List<String> tags;
  final String color;
  final bool isSkippable;
  final double procrastinationRisk;
  final List<SubTask> subTasks;

  TaskModel({
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
    this.status = TaskStatus.pending,
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
      status: TaskStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => TaskStatus.pending,
      ),
      difficulty: data['difficulty'] ?? 3,
      goalId: data['goalId'],
      milestoneId: data['milestoneId'],
      parentTaskId: data['parentTaskId'],
      repeatRule: data['repeatRule'] != null 
          ? RepeatRule.fromMap(data['repeatRule']) 
          : null,
      location: data['location'] != null 
          ? TaskLocation.fromMap(data['location']) 
          : null,
      calendarEventId: data['calendarEventId'],
      tags: List<String>.from(data['tags'] ?? []),
      color: data['color'] ?? '#2196F3',
      isSkippable: data['isSkippable'] ?? false,
      procrastinationRisk: (data['procrastinationRisk'] ?? 0.0).toDouble(),
      subTasks: (data['subTasks'] as List<dynamic>? ?? [])
          .map((e) => SubTask.fromMap(e))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
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
      'status': status.toString().split('.').last,
      'difficulty': difficulty,
      'goalId': goalId,
      'milestoneId': milestoneId,
      'parentTaskId': parentTaskId,
      'repeatRule': repeatRule?.toMap(),
      'location': location?.toMap(),
      'calendarEventId': calendarEventId,
      'tags': tags,
      'color': color,
      'isSkippable': isSkippable,
      'procrastinationRisk': procrastinationRisk,
      'subTasks': subTasks.map((e) => e.toMap()).toList(),
    };
  }

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
    TaskStatus? status,
    int? difficulty,
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

  bool get isCompleted => status == TaskStatus.completed;
  bool get isOverdue => scheduledDate.isBefore(DateTime.now()) && !isCompleted;
  bool get isToday => scheduledDate.day == DateTime.now().day && 
                      scheduledDate.month == DateTime.now().month && 
                      scheduledDate.year == DateTime.now().year;
}

enum TaskStatus {
  pending,
  inProgress,
  completed,
  delayed,
}

class RepeatRule {
  final String frequency;
  final int interval;
  final List<int>? daysOfWeek;
  final int? dayOfMonth;
  final DateTime? endDate;
  final int? count;

  RepeatRule({
    required this.frequency,
    this.interval = 1,
    this.daysOfWeek,
    this.dayOfMonth,
    this.endDate,
    this.count,
  });

  factory RepeatRule.fromMap(Map<String, dynamic> map) {
    return RepeatRule(
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
}

class TaskLocation {
  final String name;
  final String address;
  final GeoPoint? coordinates;

  TaskLocation({
    required this.name,
    required this.address,
    this.coordinates,
  });

  factory TaskLocation.fromMap(Map<String, dynamic> map) {
    return TaskLocation(
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
}

class SubTask {
  final String id;
  final String title;
  final DateTime? completedAt;

  SubTask({
    required this.id,
    required this.title,
    this.completedAt,
  });

  factory SubTask.fromMap(Map<String, dynamic> map) {
    return SubTask(
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

  bool get isCompleted => completedAt != null;
} 