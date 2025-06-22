import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// 認証状態プロバイダー
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.authStateChanges;
});

// 現在のユーザープロバイダー
final currentUserProvider = Provider<User?>((ref) {
  return AuthService.currentUser;
});

// 認証サービスプロバイダー
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// ログイン状態プロバイダー
final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

// ユーザーIDプロバイダー
final userIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.uid;
});

// 認証エラープロバイダー
final authErrorProvider = StateProvider<String?>((ref) => null);

// ローディング状態プロバイダー
final authLoadingProvider = StateProvider<bool>((ref) => false);

// 認証アクション用のプロバイダー
final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions(ref);
});

class AuthActions {
  final Ref _ref;

  AuthActions(this._ref);

  // Google認証でサインイン
  Future<void> signInWithGoogle() async {
    try {
      _ref.read(authLoadingProvider.notifier).state = true;
      _ref.read(authErrorProvider.notifier).state = null;
      
      await AuthService.signInWithGoogle();
    } catch (e) {
      _ref.read(authErrorProvider.notifier).state = e.toString();
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  // サインアウト
  Future<void> signOut() async {
    try {
      _ref.read(authLoadingProvider.notifier).state = true;
      _ref.read(authErrorProvider.notifier).state = null;
      
      await AuthService.signOut();
    } catch (e) {
      _ref.read(authErrorProvider.notifier).state = e.toString();
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  // アカウント削除
  Future<void> deleteAccount() async {
    try {
      _ref.read(authLoadingProvider.notifier).state = true;
      _ref.read(authErrorProvider.notifier).state = null;
      
      await AuthService.deleteAccount();
    } catch (e) {
      _ref.read(authErrorProvider.notifier).state = e.toString();
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  // エラーをクリア
  void clearError() {
    _ref.read(authErrorProvider.notifier).state = null;
  }
} 