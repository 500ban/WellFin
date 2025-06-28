import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../models/habit_model.dart';

/// Firebase Firestoreを使用する習慣リポジトリの実装
class FirestoreHabitRepository implements HabitRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 現在のユーザーIDを取得
  String? get _currentUserId => _auth.currentUser?.uid;

  /// ユーザーの習慣コレクション参照を取得
  CollectionReference<Map<String, dynamic>> _getHabitsCollection() {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('ユーザーが認証されていません');
    }
    return _firestore.collection('users').doc(userId).collection('habits');
  }

  @override
  Future<dartz.Either<String, Habit>> createHabit(Habit habit) async {
    try {
      print('[DEBUG] createHabit: userId=$_currentUserId, habit=$habit');
      final habitModel = HabitModel.fromDomain(habit);
      print('[DEBUG] Firestoreに書き込むデータ: ${habitModel.toFirestore()}');
      final docRef = await _getHabitsCollection().add(habitModel.toFirestore());
      print('[DEBUG] Firestore書き込み成功: docId=${docRef.id}');
      // 作成された習慣を取得して返す
      final doc = await docRef.get();
      final createdHabit = HabitModel.fromFirestore(doc).toDomain();
      print('[DEBUG] 作成習慣: $createdHabit');
      return dartz.Right(createdHabit);
    } catch (e, st) {
      print('[ERROR] createHabit失敗: $e\n$st');
      return dartz.Left('習慣の作成に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, Habit?>> getHabit(String habitId) async {
    try {
      final doc = await _getHabitsCollection().doc(habitId).get();
      
      if (!doc.exists) {
        return dartz.Right(null);
      }
      
      final habit = HabitModel.fromFirestore(doc).toDomain();
      return dartz.Right(habit);
    } catch (e) {
      return dartz.Left('習慣の取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Habit>>> getAllHabits(String userId) async {
    try {
      final querySnapshot = await _getHabitsCollection()
          .orderBy('createdAt', descending: true)
          .get();
      
      final habits = querySnapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc).toDomain())
          .toList();
      
      return dartz.Right(habits);
    } catch (e) {
      return dartz.Left('習慣の取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Habit>>> getTodayHabits(String userId) async {
    try {
      // 今日が対象日の習慣を取得
      final querySnapshot = await _getHabitsCollection()
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .get();
      
      final allHabits = querySnapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc).toDomain())
          .toList();
      
      // 今日が対象日の習慣のみをフィルタリング
      final todayHabits = allHabits.where((habit) => habit.isTodayTarget).toList();
      
      return dartz.Right(todayHabits);
    } catch (e) {
      return dartz.Left('今日の習慣の取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Habit>>> getHabitsByDate(String userId, DateTime date) async {
    try {
      // 指定日が対象日の習慣を取得
      final querySnapshot = await _getHabitsCollection()
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .get();
      
      final allHabits = querySnapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc).toDomain())
          .toList();
      
      // 指定日が対象日の習慣のみをフィルタリング
      final dateHabits = allHabits.where((habit) {
        final weekday = date.weekday;
        final startDateOnly = DateTime(habit.startDate.year, habit.startDate.month, habit.startDate.day);
        final dateOnly = DateTime(date.year, date.month, date.day);
        
        switch (habit.frequency) {
          case HabitFrequency.daily:
            return true;
          case HabitFrequency.everyOtherDay:
            // 開始日から何日経過したかを計算
            final daysSinceStart = dateOnly.difference(startDateOnly).inDays;
            return daysSinceStart % 2 == 0;
          case HabitFrequency.twiceAWeek:
            // 週2回の場合は、開始日から3日おきに実行
            final daysSinceStart = dateOnly.difference(startDateOnly).inDays;
            return daysSinceStart % 3 == 0;
          case HabitFrequency.threeTimesAWeek:
            // 週3回の場合は、開始日から2日おきに実行
            final daysSinceStart = dateOnly.difference(startDateOnly).inDays;
            return daysSinceStart % 2 == 0;
          case HabitFrequency.weekly:
            return habit.targetDays.any((day) => day.value == weekday);
          case HabitFrequency.twiceAMonth:
            // 月2回の場合は、開始日の日付と15日後に実行
            final startDay = habit.startDate.day;
            final dateDay = date.day;
            return dateDay == startDay || dateDay == (startDay + 15) % 30;
          case HabitFrequency.monthly:
            return date.day == habit.startDate.day;
          case HabitFrequency.quarterly:
            // 四半期に1回の場合は、開始日から3ヶ月おきに実行
            final monthsSinceStart = (date.year - habit.startDate.year) * 12 + (date.month - habit.startDate.month);
            return monthsSinceStart % 3 == 0 && date.day == habit.startDate.day;
          case HabitFrequency.yearly:
            // 年に1回の場合は、毎年同じ月日に実行
            return date.month == habit.startDate.month && date.day == habit.startDate.day;
          case HabitFrequency.custom:
            return habit.targetDays.any((day) => day.value == weekday);
        }
      }).toList();
      
      return dartz.Right(dateHabits);
    } catch (e) {
      return dartz.Left('指定日の習慣の取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Habit>>> getActiveHabits(String userId) async {
    try {
      final querySnapshot = await _getHabitsCollection()
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();
      
      final habits = querySnapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc).toDomain())
          .toList();
      
      return dartz.Right(habits);
    } catch (e) {
      return dartz.Left('アクティブな習慣の取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Habit>>> getFinishedHabits(String userId) async {
    try {
      final querySnapshot = await _getHabitsCollection()
          .where('status', isEqualTo: 'finished')
          .orderBy('createdAt', descending: true)
          .get();
      
      final habits = querySnapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc).toDomain())
          .toList();
      
      return dartz.Right(habits);
    } catch (e) {
      return dartz.Left('終了した習慣の取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Habit>>> getPausedHabits(String userId) async {
    try {
      final querySnapshot = await _getHabitsCollection()
          .where('status', isEqualTo: 'paused')
          .orderBy('createdAt', descending: true)
          .get();
      
      final habits = querySnapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc).toDomain())
          .toList();
      
      return dartz.Right(habits);
    } catch (e) {
      return dartz.Left('一時停止中の習慣の取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Habit>>> getHabitsByCategory(String userId, String category) async {
    try {
      final querySnapshot = await _getHabitsCollection()
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      final habits = querySnapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc).toDomain())
          .toList();
      
      return dartz.Right(habits);
    } catch (e) {
      return dartz.Left('カテゴリ別習慣の取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Habit>>> getHabitsByGoal(String userId, String goalId) async {
    try {
      final querySnapshot = await _getHabitsCollection()
          .where('goalId', isEqualTo: goalId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      final habits = querySnapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc).toDomain())
          .toList();
      
      return dartz.Right(habits);
    } catch (e) {
      return dartz.Left('目標関連習慣の取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<Habit>>> getHabitsByTag(String userId, String tag) async {
    try {
      final querySnapshot = await _getHabitsCollection()
          .where('tags', arrayContains: tag)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      final habits = querySnapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc).toDomain())
          .toList();
      
      return dartz.Right(habits);
    } catch (e) {
      return dartz.Left('タグ別習慣の取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, Habit>> updateHabit(Habit habit) async {
    try {
      final habitModel = HabitModel.fromDomain(habit);
      await _getHabitsCollection().doc(habit.id).update(habitModel.toFirestore());
      
      // 更新された習慣を取得して返す
      final doc = await _getHabitsCollection().doc(habit.id).get();
      final updatedHabit = HabitModel.fromFirestore(doc).toDomain();
      
      return dartz.Right(updatedHabit);
    } catch (e) {
      return dartz.Left('習慣の更新に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, void>> deleteHabit(String habitId) async {
    try {
      await _getHabitsCollection().doc(habitId).delete();
      return dartz.Right(null);
    } catch (e) {
      return dartz.Left('習慣の削除に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, Habit>> recordDailyCompletion(String habitId) async {
    try {
      final doc = await _getHabitsCollection().doc(habitId).get();
      if (!doc.exists) {
        return dartz.Left('習慣が見つかりません');
      }
      
      final habit = HabitModel.fromFirestore(doc).toDomain();
      final updatedHabit = habit.markAsCompleted(); // 日々の取り組みを記録
      
      final result = await updateHabit(updatedHabit);
      return result;
    } catch (e) {
      return dartz.Left('日々の取り組み記録に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, Habit>> completeHabit(String habitId) async {
    try {
      final doc = await _getHabitsCollection().doc(habitId).get();
      if (!doc.exists) {
        return dartz.Left('習慣が見つかりません');
      }
      
      final habit = HabitModel.fromFirestore(doc).toDomain();
      final finishedHabit = habit.complete(); // 習慣を終了状態に変更
      
      final result = await updateHabit(finishedHabit);
      return result;
    } catch (e) {
      return dartz.Left('習慣の終了に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, Habit>> pauseHabit(String habitId) async {
    try {
      final doc = await _getHabitsCollection().doc(habitId).get();
      if (!doc.exists) {
        return dartz.Left('習慣が見つかりません');
      }
      
      final habit = HabitModel.fromFirestore(doc).toDomain();
      final pausedHabit = habit.pause();
      
      final result = await updateHabit(pausedHabit);
      return result;
    } catch (e) {
      return dartz.Left('習慣の一時停止に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, Habit>> resumeHabit(String habitId) async {
    try {
      final doc = await _getHabitsCollection().doc(habitId).get();
      if (!doc.exists) {
        return dartz.Left('習慣が見つかりません');
      }
      
      final habit = HabitModel.fromFirestore(doc).toDomain();
      final resumedHabit = habit.resume();
      
      final result = await updateHabit(resumedHabit);
      return result;
    } catch (e) {
      return dartz.Left('習慣の再開に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, HabitStatistics>> getHabitStatistics(String userId) async {
    try {
      final allHabitsResult = await getAllHabits(userId);
      
      return allHabitsResult.fold(
        (error) => dartz.Left(error),
        (habits) {
          final activeHabits = habits.where((h) => h.isInProgress).length;
          final completedHabits = habits.where((h) => h.isCompleted).length;
          final pausedHabits = habits.where((h) => h.isPaused).length;
          
          final totalCompletions = habits.fold<int>(0, (sum, habit) => sum + habit.totalCompletions);
          final averageCompletionRate = habits.isEmpty ? 0.0 : 
              habits.map((h) => h.todayProgress).reduce((a, b) => a + b) / habits.length;
          
          final currentStreak = habits.isEmpty ? 0 : 
              habits.map((h) => h.currentStreak).reduce((a, b) => a > b ? a : b);
          final longestStreak = habits.isEmpty ? 0 : 
              habits.map((h) => h.longestStreak).reduce((a, b) => a > b ? a : b);
          
          final categoryDistribution = <String, int>{};
          for (final habit in habits) {
            final category = habit.category.label;
            categoryDistribution[category] = (categoryDistribution[category] ?? 0) + 1;
          }
          
          final weeklyProgress = <String, double>{};
          final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
          for (int i = 0; i < 7; i++) {
            // 簡易実装のため、デフォルト値を設定
            weeklyProgress[weekdays[i]] = 0.5;
          }
          
          final statistics = HabitStatistics(
            totalHabits: habits.length,
            activeHabits: activeHabits,
            completedHabits: completedHabits,
            pausedHabits: pausedHabits,
            averageCompletionRate: averageCompletionRate,
            totalCompletions: totalCompletions,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            categoryDistribution: categoryDistribution,
            weeklyProgress: weeklyProgress,
          );
          
          return dartz.Right(statistics);
        },
      );
    } catch (e) {
      return dartz.Left('習慣統計の取得に失敗しました: $e');
    }
  }

  @override
  Future<dartz.Either<String, List<HabitStreakInfo>>> getHabitStreaks(String userId) async {
    try {
      final activeHabitsResult = await getActiveHabits(userId);
      
      return activeHabitsResult.fold(
        (error) => dartz.Left(error),
        (habits) {
          final streakInfos = habits.map((habit) {
            final lastCompletion = habit.completions.isNotEmpty 
                ? habit.completions.map((c) => c.completedAt).reduce((a, b) => a.isAfter(b) ? a : b)
                : DateTime.now().subtract(const Duration(days: 365));
            
            return HabitStreakInfo(
              habitId: habit.id,
              habitTitle: habit.title,
              currentStreak: habit.currentStreak,
              longestStreak: habit.longestStreak,
              lastCompletionDate: lastCompletion,
              isCompletedToday: habit.isCompletedToday,
            );
          }).toList();
          
          // ストリーク数で降順ソート
          streakInfos.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
          
          return dartz.Right(streakInfos);
        },
      );
    } catch (e) {
      return dartz.Left('習慣ストリークの取得に失敗しました: $e');
    }
  }
} 