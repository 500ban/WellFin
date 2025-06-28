import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../models/goal_model.dart';

/// 目標管理のFirestoreリポジトリ実装
class FirestoreGoalRepository implements GoalRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreGoalRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  /// ユーザーIDを取得
  String? get _userId => _auth.currentUser?.uid;

  /// ユーザーの目標コレクション参照を取得
  CollectionReference<Map<String, dynamic>> get _goalsCollection {
    final userId = _userId;
    if (userId == null) {
      throw Exception('ユーザーが認証されていません');
    }
    return _firestore.collection('users').doc(userId).collection('goals');
  }

  @override
  Future<Goal> createGoal(Goal goal) async {
    try {
      final goalModel = GoalModel.fromDomain(goal);
      final docRef = await _goalsCollection.add(goalModel.toFirestore());
      
      // 作成されたドキュメントのIDで更新
      final updatedGoal = goal.copyWith(id: docRef.id);
      return updatedGoal;
    } catch (e) {
      throw Exception('目標の作成に失敗しました: $e');
    }
  }

  @override
  Future<Goal?> getGoal(String id) async {
    try {
      final doc = await _goalsCollection.doc(id).get();
      if (!doc.exists) return null;
      
      final goalModel = GoalModel.fromFirestore(doc);
      return goalModel.toDomain();
    } catch (e) {
      throw Exception('目標の取得に失敗しました: $e');
    }
  }

  @override
  Future<List<Goal>> getAllGoals() async {
    try {
      final querySnapshot = await _goalsCollection.get();
      return querySnapshot.docs
          .map((doc) => GoalModel.fromFirestore(doc).toDomain())
          .toList();
    } catch (e) {
      throw Exception('目標の取得に失敗しました: $e');
    }
  }

  @override
  Future<List<Goal>> getActiveGoals() async {
    try {
      final querySnapshot = await _goalsCollection
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .get();
      
      return querySnapshot.docs
          .map((doc) => GoalModel.fromFirestore(doc).toDomain())
          .toList();
    } catch (e) {
      throw Exception('アクティブな目標の取得に失敗しました: $e');
    }
  }

  @override
  Future<List<Goal>> getGoalsByCategory(GoalCategory category) async {
    try {
      final querySnapshot = await _goalsCollection
          .where('category', isEqualTo: category.name)
          .get();
      
      return querySnapshot.docs
          .map((doc) => GoalModel.fromFirestore(doc).toDomain())
          .toList();
    } catch (e) {
      throw Exception('カテゴリ別目標の取得に失敗しました: $e');
    }
  }

  @override
  Future<List<Goal>> getGoalsByStatus(GoalStatus status) async {
    try {
      final querySnapshot = await _goalsCollection
          .where('status', isEqualTo: status.value)
          .get();
      
      return querySnapshot.docs
          .map((doc) => GoalModel.fromFirestore(doc).toDomain())
          .toList();
    } catch (e) {
      throw Exception('ステータス別目標の取得に失敗しました: $e');
    }
  }

  @override
  Future<List<Goal>> getGoalsByPriority(GoalPriority priority) async {
    try {
      final querySnapshot = await _goalsCollection
          .where('priority', isEqualTo: priority.value)
          .get();
      
      return querySnapshot.docs
          .map((doc) => GoalModel.fromFirestore(doc).toDomain())
          .toList();
    } catch (e) {
      throw Exception('優先度別目標の取得に失敗しました: $e');
    }
  }

  @override
  Future<List<Goal>> getOverdueGoals() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _goalsCollection
          .where('targetDate', isLessThan: Timestamp.fromDate(now))
          .where('progress', isLessThan: 1.0)
          .get();
      
      return querySnapshot.docs
          .map((doc) => GoalModel.fromFirestore(doc).toDomain())
          .toList();
    } catch (e) {
      throw Exception('期限切れ目標の取得に失敗しました: $e');
    }
  }

  @override
  Future<List<Goal>> getGoalsWithDeadlineWithin(int days) async {
    try {
      final now = DateTime.now();
      final deadline = now.add(Duration(days: days));
      
      final querySnapshot = await _goalsCollection
          .where('targetDate', isGreaterThan: Timestamp.fromDate(now))
          .where('targetDate', isLessThanOrEqualTo: Timestamp.fromDate(deadline))
          .get();
      
      return querySnapshot.docs
          .map((doc) => GoalModel.fromFirestore(doc).toDomain())
          .toList();
    } catch (e) {
      throw Exception('期限が近い目標の取得に失敗しました: $e');
    }
  }

  @override
  Future<Goal> updateGoal(Goal goal) async {
    try {
      final goalModel = GoalModel.fromDomain(goal);
      await _goalsCollection.doc(goal.id).update(goalModel.toFirestore());
      return goal;
    } catch (e) {
      throw Exception('目標の更新に失敗しました: $e');
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    try {
      await _goalsCollection.doc(id).delete();
    } catch (e) {
      throw Exception('目標の削除に失敗しました: $e');
    }
  }

  @override
  Future<Goal> updateGoalProgress(String goalId, double progress) async {
    try {
      final goal = await getGoal(goalId);
      if (goal == null) {
        throw Exception('目標が見つかりません');
      }
      
      final updatedGoal = goal.updateProgress(progress);
      await updateGoal(updatedGoal);
      return updatedGoal;
    } catch (e) {
      throw Exception('目標進捗の更新に失敗しました: $e');
    }
  }

  @override
  Future<Goal> addMilestone(String goalId, Milestone milestone) async {
    try {
      final goal = await getGoal(goalId);
      if (goal == null) {
        throw Exception('目標が見つかりません');
      }
      
      final updatedGoal = goal.addMilestone(milestone);
      await updateGoal(updatedGoal);
      return updatedGoal;
    } catch (e) {
      throw Exception('マイルストーンの追加に失敗しました: $e');
    }
  }

  @override
  Future<Goal> updateMilestone(String goalId, String milestoneId, Milestone milestone) async {
    try {
      final goal = await getGoal(goalId);
      if (goal == null) {
        throw Exception('目標が見つかりません');
      }
      
      final updatedGoal = goal.updateMilestone(milestoneId, milestone);
      await updateGoal(updatedGoal);
      return updatedGoal;
    } catch (e) {
      throw Exception('マイルストーンの更新に失敗しました: $e');
    }
  }

  @override
  Future<Goal> removeMilestone(String goalId, String milestoneId) async {
    try {
      final goal = await getGoal(goalId);
      if (goal == null) {
        throw Exception('目標が見つかりません');
      }
      
      final updatedGoal = goal.removeMilestone(milestoneId);
      await updateGoal(updatedGoal);
      return updatedGoal;
    } catch (e) {
      throw Exception('マイルストーンの削除に失敗しました: $e');
    }
  }

  @override
  Future<Goal> markGoalAsCompleted(String goalId) async {
    try {
      final goal = await getGoal(goalId);
      if (goal == null) {
        throw Exception('目標が見つかりません');
      }
      
      final updatedGoal = goal.markAsCompleted();
      await updateGoal(updatedGoal);
      return updatedGoal;
    } catch (e) {
      throw Exception('目標の完了処理に失敗しました: $e');
    }
  }

  @override
  Future<Goal> pauseGoal(String goalId) async {
    try {
      final goal = await getGoal(goalId);
      if (goal == null) {
        throw Exception('目標が見つかりません');
      }
      
      final updatedGoal = goal.pause();
      await updateGoal(updatedGoal);
      return updatedGoal;
    } catch (e) {
      throw Exception('目標の一時停止に失敗しました: $e');
    }
  }

  @override
  Future<Goal> resumeGoal(String goalId) async {
    try {
      final goal = await getGoal(goalId);
      if (goal == null) {
        throw Exception('目標が見つかりません');
      }
      
      final updatedGoal = goal.resume();
      await updateGoal(updatedGoal);
      return updatedGoal;
    } catch (e) {
      throw Exception('目標の再開に失敗しました: $e');
    }
  }

  @override
  Future<Goal> cancelGoal(String goalId) async {
    try {
      final goal = await getGoal(goalId);
      if (goal == null) {
        throw Exception('目標が見つかりません');
      }
      
      final updatedGoal = goal.cancel();
      await updateGoal(updatedGoal);
      return updatedGoal;
    } catch (e) {
      throw Exception('目標のキャンセルに失敗しました: $e');
    }
  }

  @override
  Future<GoalStatistics> getGoalStatistics() async {
    try {
      final allGoals = await getAllGoals();
      
      final activeGoals = allGoals.where((goal) => goal.isInProgress).length;
      final completedGoals = allGoals.where((goal) => goal.isCompleted).length;
      final pausedGoals = allGoals.where((goal) => goal.isPaused).length;
      final cancelledGoals = allGoals.where((goal) => goal.isCancelled).length;
      final overdueGoals = allGoals.where((goal) => goal.isOverdue).length;
      
      // 平均進捗の計算を安全に行う
      double averageProgress = 0.0;
      if (allGoals.isNotEmpty) {
        final totalProgress = allGoals.fold<double>(0.0, (sum, goal) => sum + goal.progress);
        averageProgress = totalProgress / allGoals.length;
      }
      
      final goalsByCategory = <GoalCategory, int>{};
      for (final category in GoalCategory.values) {
        goalsByCategory[category] = allGoals.where((goal) => goal.category == category).length;
      }
      
      final goalsByPriority = <GoalPriority, int>{};
      for (final priority in GoalPriority.values) {
        goalsByPriority[priority] = allGoals.where((goal) => goal.priority == priority).length;
      }
      
      final totalMilestones = allGoals.fold<int>(0, (sum, goal) => sum + goal.milestones.length);
      final completedMilestones = allGoals.fold<int>(0, (sum, goal) => sum + goal.completedMilestonesCount);
      
      return GoalStatistics(
        totalGoals: allGoals.length,
        activeGoals: activeGoals,
        completedGoals: completedGoals,
        pausedGoals: pausedGoals,
        cancelledGoals: cancelledGoals,
        overdueGoals: overdueGoals,
        averageProgress: averageProgress,
        goalsByCategory: goalsByCategory,
        goalsByPriority: goalsByPriority,
        totalMilestones: totalMilestones,
        completedMilestones: completedMilestones,
      );
    } catch (e) {
      throw Exception('目標統計の取得に失敗しました: $e');
    }
  }

  @override
  Future<List<GoalProgress>> getGoalProgressHistory(String goalId) async {
    try {
      final goal = await getGoal(goalId);
      if (goal == null) {
        throw Exception('目標が見つかりません');
      }
      
      return goal.progressHistory;
    } catch (e) {
      throw Exception('目標進捗履歴の取得に失敗しました: $e');
    }
  }

  @override
  Future<List<Goal>> searchGoals(String query) async {
    try {
      final allGoals = await getAllGoals();
      final lowercaseQuery = query.toLowerCase();
      
      return allGoals.where((goal) {
        return goal.title.toLowerCase().contains(lowercaseQuery) ||
               goal.description.toLowerCase().contains(lowercaseQuery) ||
               goal.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
      }).toList();
    } catch (e) {
      throw Exception('目標の検索に失敗しました: $e');
    }
  }

  @override
  Future<List<Goal>> sortGoals(GoalSortOption sortOption) async {
    try {
      final allGoals = await getAllGoals();
      
      switch (sortOption) {
        case GoalSortOption.importance:
          allGoals.sort((a, b) => b.importanceScore.compareTo(a.importanceScore));
          break;
        case GoalSortOption.deadline:
          allGoals.sort((a, b) {
            if (a.targetDate == null && b.targetDate == null) return 0;
            if (a.targetDate == null) return 1;
            if (b.targetDate == null) return -1;
            return a.targetDate!.compareTo(b.targetDate!);
          });
          break;
        case GoalSortOption.createdAt:
          allGoals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case GoalSortOption.progress:
          allGoals.sort((a, b) => b.progress.compareTo(a.progress));
          break;
        case GoalSortOption.title:
          allGoals.sort((a, b) => a.title.compareTo(b.title));
          break;
        case GoalSortOption.priority:
          allGoals.sort((a, b) => b.priority.value.compareTo(a.priority.value));
          break;
      }
      
      return allGoals;
    } catch (e) {
      throw Exception('目標の並び替えに失敗しました: $e');
    }
  }
} 