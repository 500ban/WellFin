import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'auth_provider.dart';

// ユーザーデータプロバイダー
final userDataProvider = FutureProvider.family<UserModel?, String>((ref, uid) async {
  return await AuthService.getUserData(uid);
});

// 現在のユーザーデータプロバイダー
final currentUserDataProvider = Provider<AsyncValue<UserModel?>>((ref) {
  // 認証状態の変更を監視
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user != null) {
        return ref.watch(userDataProvider(user.uid));
      }
      return const AsyncValue.data(null);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// 🔧 autoUserProvider - 無限ループを防ぐ安全なプロバイダー
final autoUserProvider = FutureProvider<UserModel?>((ref) async {
  // 認証状態を取得
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) async {
      if (user != null) {
        // Future.microtaskで循環参照を防ぐ
        return Future.microtask(() => AuthService.getUserData(user.uid));
      }
      return null;
    },
    loading: () => null,
    error: (error, stack) => null,
  );
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
    final authState = _ref.read(authStateProvider);
    final userId = authState.value?.uid;
    if (userId != null) {
      await AuthService.updateUserStats(userId, stats);
      // プロバイダーを無効化して再読み込み
      _ref.invalidate(userDataProvider(userId));
    }
  }

  // ユーザー情報を更新
  Future<void> updateUserData(Map<String, dynamic> data) async {
    final authState = _ref.read(authStateProvider);
    final userId = authState.value?.uid;
    if (userId != null) {
      await AuthService.updateUserData(userId, data);
      // プロバイダーを無効化して再読み込み
      _ref.invalidate(userDataProvider(userId));
    }
  }

  // ユーザーデータを再読み込み
  void refreshUserData() {
    final authState = _ref.read(authStateProvider);
    final userId = authState.value?.uid;
    if (userId != null) {
      _ref.invalidate(userDataProvider(userId));
    }
  }
}

 