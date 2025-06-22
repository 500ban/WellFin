import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Logger _logger = Logger();

  // 現在のユーザーを取得
  static User? get currentUser => _auth.currentUser;

  // 認証状態の変更を監視
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google認証でサインイン
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Google Sign-Inの実行
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Google認証情報を取得
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase認証情報を作成
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebaseでサインイン
      final userCredential = await _auth.signInWithCredential(credential);
      
      // ユーザー情報をFirestoreに保存
      await _saveUserToFirestore(userCredential.user!);
      
      return userCredential;
    } catch (e) {
      _logger.e('Error signing in with Google: $e');
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
          preferences: UserPreferences(
            notificationChannels: NotificationChannels(),
          ),
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

  // ユーザー設定を更新
  static Future<void> updateUserPreferences(String uid, UserPreferences preferences) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'preferences': preferences.toMap(),
      });
    } catch (e) {
      _logger.e('Error updating user preferences: $e');
      rethrow;
    }
  }

  // カレンダー同期設定を更新
  static Future<void> updateCalendarSync(String uid, CalendarSync calendarSync) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'calendarSync': calendarSync.toMap(),
      });
    } catch (e) {
      _logger.e('Error updating calendar sync: $e');
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