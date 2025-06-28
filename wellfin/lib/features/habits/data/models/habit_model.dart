import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/habit.dart';

/// 習慣のデータモデル
/// Firestoreとの相互変換を行う
class HabitModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime? endDate;
  final String category;
  final String frequency;
  final List<int> targetDays; // 曜日の数値（1-7）
  final Map<String, dynamic>? reminderTime; // {hour: int, minute: int}
  final int priority;
  final String status;
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final List<Map<String, dynamic>> completions;
  final String? goalId;
  final List<String> tags;
  final String color;
  final bool isActive;
  final String? iconName;
  final int targetCount;
  final String? notes;

  const HabitModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.startDate,
    this.endDate,
    this.category = 'personal',
    this.frequency = 'daily',
    this.targetDays = const [],
    this.reminderTime,
    this.priority = 2,
    this.status = 'active',
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
  });

  /// FirestoreドキュメントからHabitModelを作成
  factory HabitModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HabitModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null 
          ? (data['endDate'] as Timestamp).toDate() 
          : null,
      category: data['category'] ?? 'personal',
      frequency: data['frequency'] ?? 'daily',
      targetDays: List<int>.from(data['targetDays'] ?? []),
      reminderTime: data['reminderTime'] as Map<String, dynamic>?,
      priority: data['priority'] ?? 2,
      status: data['status'] ?? 'active',
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      totalCompletions: data['totalCompletions'] ?? 0,
      completions: (data['completions'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      goalId: data['goalId'],
      tags: List<String>.from(data['tags'] ?? []),
      color: data['color'] ?? '#4CAF50',
      isActive: data['isActive'] ?? true,
      iconName: data['iconName'],
      targetCount: data['targetCount'] ?? 1,
      notes: data['notes'],
    );
  }

  /// HabitModelをFirestoreドキュメントに変換
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null 
          ? Timestamp.fromDate(endDate!) 
          : null,
      'category': category,
      'frequency': frequency,
      'targetDays': targetDays,
      'reminderTime': reminderTime,
      'priority': priority,
      'status': status,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalCompletions': totalCompletions,
      'completions': completions,
      'goalId': goalId,
      'tags': tags,
      'color': color,
      'isActive': isActive,
      'iconName': iconName,
      'targetCount': targetCount,
      'notes': notes,
    };
  }

  /// ドメインエンティティからHabitModelを作成
  factory HabitModel.fromDomain(Habit habit) {
    return HabitModel(
      id: habit.id,
      title: habit.title,
      description: habit.description,
      createdAt: habit.createdAt,
      startDate: habit.startDate,
      endDate: habit.endDate,
      category: habit.category.name,
      frequency: habit.frequency.name,
      targetDays: habit.targetDays.map((day) => day.value).toList(),
      reminderTime: habit.reminderTime != null 
          ? {'hour': habit.reminderTime!.hour, 'minute': habit.reminderTime!.minute}
          : null,
      priority: habit.priority.value,
      status: habit.status.value,
      currentStreak: habit.currentStreak,
      longestStreak: habit.longestStreak,
      totalCompletions: habit.totalCompletions,
      completions: habit.completions.map((completion) => completion.toMap()).toList(),
      goalId: habit.goalId,
      tags: habit.tags,
      color: habit.color,
      isActive: habit.isActive,
      iconName: habit.iconName,
      targetCount: habit.targetCount,
      notes: habit.notes,
    );
  }

  /// HabitModelをドメインエンティティに変換
  Habit toDomain() {
    return Habit(
      id: id,
      title: title,
      description: description,
      createdAt: createdAt,
      startDate: startDate,
      endDate: endDate,
      category: HabitCategory.values.firstWhere(
        (c) => c.name == category,
        orElse: () => HabitCategory.personal,
      ),
      frequency: HabitFrequency.values.firstWhere(
        (f) => f.name == frequency,
        orElse: () => HabitFrequency.daily,
      ),
      targetDays: targetDays.map((dayValue) {
        return HabitDay.values.firstWhere(
          (day) => day.value == dayValue,
          orElse: () => HabitDay.monday,
        );
      }).toList(),
      reminderTime: reminderTime != null 
          ? TimeOfDay(
              hour: reminderTime!['hour'] as int,
              minute: reminderTime!['minute'] as int,
            )
          : null,
      priority: HabitPriority.values.firstWhere(
        (p) => p.value == priority,
        orElse: () => HabitPriority.medium,
      ),
      status: HabitStatus.values.firstWhere(
        (s) => s.value == status,
        orElse: () => HabitStatus.active,
      ),
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalCompletions: totalCompletions,
      completions: completions.map((completion) => HabitCompletionModel.fromMap(completion).toDomain()).toList(),
      goalId: goalId,
      tags: tags,
      color: color,
      isActive: isActive,
      iconName: iconName,
      targetCount: targetCount,
      notes: notes,
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

/// 習慣完了記録のデータモデル
class HabitCompletionModel extends Equatable {
  final String id;
  final DateTime completedAt;
  final String? notes;

  const HabitCompletionModel({
    required this.id,
    required this.completedAt,
    this.notes,
  });

  /// MapからHabitCompletionModelを作成
  factory HabitCompletionModel.fromMap(Map<String, dynamic> map) {
    return HabitCompletionModel(
      id: map['id'] ?? '',
      completedAt: (map['completedAt'] as Timestamp).toDate(),
      notes: map['notes'],
    );
  }

  /// HabitCompletionModelをMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'completedAt': Timestamp.fromDate(completedAt),
      'notes': notes,
    };
  }

  /// ドメインエンティティからHabitCompletionModelを作成
  factory HabitCompletionModel.fromDomain(HabitCompletion completion) {
    return HabitCompletionModel(
      id: completion.id,
      completedAt: completion.completedAt,
      notes: completion.notes,
    );
  }

  /// HabitCompletionModelをドメインエンティティに変換
  HabitCompletion toDomain() {
    return HabitCompletion(
      id: id,
      completedAt: completedAt,
      notes: notes,
    );
  }

  @override
  List<Object?> get props => [id, completedAt, notes];
} 