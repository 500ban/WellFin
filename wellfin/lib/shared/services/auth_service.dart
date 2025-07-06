import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import 'package:flutter/services.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events',
    ],
  );
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Logger _logger = Logger();

  // 現在のユーザーを取得
  static User? get currentUser => _auth.currentUser;

  // 認証状態の変更を監視
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google認証でサインイン
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      _logger.i('Starting Google Sign-In process...');
      
      // Google Sign-Inの設定を確認
      _logger.i('Google Sign-In configuration check...');
      _logger.i('Package name: com.ban500.wellfin');
      _logger.i('Firebase project ID: wellfin-72698');
      
      // 既存のGoogle認証をクリア（アカウント選択を強制）
      await _googleSignIn.signOut();
      
      // Google Sign-Inの実行
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _logger.w('Google Sign-In was cancelled by user');
        return null;
      }

      _logger.i('Google Sign-In successful for user: ${googleUser.email}');

      // Google認証情報を取得
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      _logger.i('Google authentication tokens obtained');
      _logger.i('Access token: ${googleAuth.accessToken != null ? 'Present' : 'Missing'}');
      _logger.i('ID token: ${googleAuth.idToken != null ? 'Present' : 'Missing'}');

      // Firebase認証情報を作成
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebaseでサインイン
      final userCredential = await _auth.signInWithCredential(credential);
      _logger.i('Firebase authentication successful for user: ${userCredential.user?.uid}');
      
      // ユーザー情報をFirestoreに保存
      await _saveUserToFirestore(userCredential.user!);
      _logger.i('User data saved to Firestore');
      
      return userCredential;
    } catch (e) {
      _logger.e('Error signing in with Google: $e');
      _logger.e('Error details: ${e.toString()}');
      
      // より詳細なエラー情報をログに出力
      if (e is PlatformException) {
        _logger.e('Platform Exception Code: ${e.code}');
        _logger.e('Platform Exception Message: ${e.message}');
        _logger.e('Platform Exception Details: ${e.details}');
        
        // エラーコード10の詳細情報
        if (e.code == 'sign_in_failed' && e.message?.contains('10') == true) {
          _logger.e('Error 10 typically indicates:');
          _logger.e('1. SHA-1 fingerprint mismatch in Firebase Console');
          _logger.e('2. Google Play Services issues on emulator');
          _logger.e('3. OAuth client configuration problems');
          _logger.e('4. Package name mismatch');
        }
      }
      
      rethrow;
    }
  }

  // サインアウト
  static Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      _logger.e('Error signing out: $e');
      rethrow;
    }
  }

  // ユーザー情報をFirestoreに保存
  static Future<void> _saveUserToFirestore(User firebaseUser) async {
    try {
      final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
      final userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        // 新規ユーザーの場合
        final userModel = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? '',
          photoURL: firebaseUser.photoURL,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          timeZone: 'Asia/Tokyo',
          preferences: UserPreferences(),
          calendarSync: CalendarSync(),
          stats: UserStats(),
        );

        await userDoc.set(userModel.toMap());
      } else {
        // 既存ユーザーの場合、最終ログイン時刻を更新
        await userDoc.update({
          'lastLogin': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      _logger.e('Error saving user to Firestore: $e');
      rethrow;
    }
  }

  // ユーザー情報を取得
  static Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting user data: $e');
      rethrow;
    }
  }

  // ユーザー情報を更新
  static Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      _logger.e('Error updating user data: $e');
      rethrow;
    }
  }

  // ユーザー統計情報を更新
  static Future<void> updateUserStats(String uid, UserStats stats) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'stats': stats.toMap(),
      });
    } catch (e) {
      _logger.e('Error updating user stats: $e');
      rethrow;
    }
  }



  // アカウント削除
  static Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Firestoreのデータを削除
        await _firestore.collection('users').doc(user.uid).delete();
        
        // Firebase認証アカウントを削除
        await user.delete();
      }
    } catch (e) {
      _logger.e('Error deleting account: $e');
      rethrow;
    }
  }

  // 認証トークンを取得
  static Future<String?> getIdToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      _logger.e('Error getting ID token: $e');
      rethrow;
    }
  }

  // トークンを更新
  static Future<String?> refreshToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        return await user.getIdToken(true);
      }
      return null;
    } catch (e) {
      _logger.e('Error refreshing token: $e');
      rethrow;
    }
  }
} 