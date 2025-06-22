import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

// ユーザーデータプロバイダー
final userDataProvider = FutureProvider.family<UserModel?, String>((ref, uid) async {
  return await AuthService.getUserData(uid);
});

// 現在のユーザーデータプロバイダー
final currentUserDataProvider = Provider<AsyncValue<UserModel?>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId != null) {
    return ref.watch(userDataProvider(userId));
  }
  return const AsyncValue.data(null);
});

// ユーザー統計情報プロバイダー
final userStatsProvider = Provider<AsyncValue<UserStats?>>((ref) {
  final userData = ref.watch(currentUserDataProvider);
  return userData.when(
    data: (user) => AsyncValue.data(user?.stats),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// ユーザー設定プロバイダー
final userPreferencesProvider = Provider<AsyncValue<UserPreferences?>>((ref) {
  final userData = ref.watch(currentUserDataProvider);
  return userData.when(
    data: (user) => AsyncValue.data(user?.preferences),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// カレンダー同期設定プロバイダー
final calendarSyncProvider = Provider<AsyncValue<CalendarSync?>>((ref) {
  final userData = ref.watch(currentUserDataProvider);
  return userData.when(
    data: (user) => AsyncValue.data(user?.calendarSync),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// ユーザーアクション用のプロバイダー
final userActionsProvider = Provider<UserActions>((ref) {
  return UserActions(ref);
});

class UserActions {
  final Ref _ref;

  UserActions(this._ref);

  // ユーザー統計情報を更新
  Future<void> updateUserStats(UserStats stats) async {
    final userId = _ref.read(userIdProvider);
    if (userId != null) {
      await AuthService.updateUserStats(userId, stats);
      // プロバイダーを無効化して再読み込み
      _ref.invalidate(userDataProvider(userId));
    }
  }

  // ユーザー設定を更新
  Future<void> updateUserPreferences(UserPreferences preferences) async {
    final userId = _ref.read(userIdProvider);
    if (userId != null) {
      await AuthService.updateUserPreferences(userId, preferences);
      // プロバイダーを無効化して再読み込み
      _ref.invalidate(userDataProvider(userId));
    }
  }

  // カレンダー同期設定を更新
  Future<void> updateCalendarSync(CalendarSync calendarSync) async {
    final userId = _ref.read(userIdProvider);
    if (userId != null) {
      await AuthService.updateCalendarSync(userId, calendarSync);
      // プロバイダーを無効化して再読み込み
      _ref.invalidate(userDataProvider(userId));
    }
  }

  // ユーザー情報を更新
  Future<void> updateUserData(Map<String, dynamic> data) async {
    final userId = _ref.read(userIdProvider);
    if (userId != null) {
      await AuthService.updateUserData(userId, data);
      // プロバイダーを無効化して再読み込み
      _ref.invalidate(userDataProvider(userId));
    }
  }

  // ユーザーデータを再読み込み
  void refreshUserData() {
    final userId = _ref.read(userIdProvider);
    if (userId != null) {
      _ref.invalidate(userDataProvider(userId));
    }
  }
}

// ユーザーIDプロバイダー（auth_provider.dartから参照）
final userIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.uid;
});

// 現在のユーザープロバイダー（Firebase AuthのUser型）
final currentUserProvider = Provider<User?>((ref) {
  return AuthService.currentUser;
}); 