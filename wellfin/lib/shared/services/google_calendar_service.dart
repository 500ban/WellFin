import 'dart:async';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart';

class GoogleCalendarService {
  static final Logger _logger = Logger();
  static calendar.CalendarApi? _calendarApi;
  static Completer<calendar.CalendarApi?>? _initializationCompleter;

  // 認証エラー状態管理
  static bool _isAuthenticationError = false;
  static String? _lastAuthError;
  static DateTime? _lastAuthErrorTime;

  /// Google Sign-inのアクセストークンを使ってCalendar APIクライアントを初期化
  static Future<calendar.CalendarApi?> _initializeCalendarApi() async {
    // 同時初期化を防ぐ
    if (_initializationCompleter != null) {
      _logger.w('Calendar API initialization already in progress, waiting...');
      return await _initializationCompleter!.future;
    }

    // 既に初期化されている場合はそのまま返す
    if (_calendarApi != null) {
      return _calendarApi;
    }

    _initializationCompleter = Completer<calendar.CalendarApi?>();
    
    try {
      final googleSignIn = GoogleSignIn(
        scopes: [
          'https://www.googleapis.com/auth/calendar',
          'https://www.googleapis.com/auth/calendar.events',
        ],
      );

      final account = await googleSignIn.signInSilently();
      if (account == null) {
        _logger.w('Google account not signed in');
        return null;
      }

      final authentication = await account.authentication;
      if (authentication.accessToken == null) {
        _logger.w('Access token not available');
        return null;
      }

      // アクセストークンを使ってAuthClientを作成
      final authClient = authenticatedClient(
        Client(),
        AccessCredentials(
          AccessToken(
            'Bearer',
            authentication.accessToken!,
            DateTime.now().toUtc().add(Duration(hours: 1)), // UTC時間で1時間有効
          ),
          null, // リフレッシュトークンは自動管理
          ['https://www.googleapis.com/auth/calendar'],
        ),
      );

      _calendarApi = calendar.CalendarApi(authClient);
      _logger.i('Google Calendar API initialized successfully');
      
      _initializationCompleter!.complete(_calendarApi);
      _initializationCompleter = null;
      return _calendarApi;

    } catch (e) {
      _logger.e('Failed to initialize Google Calendar API: $e');
      _initializationCompleter!.complete(null);
      _initializationCompleter = null;
      return null;
    }
  }

  /// カレンダーイベントを取得
  static Future<List<calendar.Event>> getEvents({
    required DateTime startTime,
    required DateTime endTime,
    String calendarId = 'primary',
  }) async {
    try {
      // 認証エラー状態をリセット
      _isAuthenticationError = false;
      _lastAuthError = null;
      
      // トークンの有効性をチェック
      final isTokenValid = await GoogleCalendarService.isTokenValid();
      if (!isTokenValid) {
        _logger.w('Google Calendar token is invalid, skipping event fetch');
        _setAuthenticationError('Google Calendar token is invalid');
        return [];
      }

      final api = await _initializeCalendarApi();
      if (api == null) {
        _logger.w('Google Calendar API not available');
        _setAuthenticationError('Google Calendar API not available');
        return [];
      }

      // タイムゾーンを考慮した時間範囲の設定
      final response = await api.events.list(
        calendarId,
        timeMin: startTime,
        timeMax: endTime,
        singleEvents: true,
        orderBy: 'startTime',
        timeZone: 'Asia/Tokyo', // 日本時間での取得を明示
      );

      _logger.i('Successfully fetched ${response.items?.length ?? 0} calendar events');
      return response.items ?? [];
    } catch (e) {
      _logger.e('Failed to get calendar events: $e');
      _setAuthenticationError('Failed to get calendar events: $e');
      return [];
    }
  }

  /// カレンダーイベントを作成
  static Future<calendar.Event?> createEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? colorId,
    String calendarId = 'primary',
  }) async {
    try {
      final api = await _initializeCalendarApi();
      if (api == null) return null;

      final event = calendar.Event()
        ..summary = title
        ..description = description
        ..start = calendar.EventDateTime()
        ..start!.dateTime = startTime
        ..start!.timeZone = 'Asia/Tokyo'
        ..end = calendar.EventDateTime()
        ..end!.dateTime = endTime
        ..end!.timeZone = 'Asia/Tokyo';

      // 色情報を設定（Google Calendar colorId）
      if (colorId != null && colorId.isNotEmpty) {
        event.colorId = colorId;
      }

      final createdEvent = await api.events.insert(event, calendarId);
      _logger.i('Calendar event created: ${createdEvent.id} with color: $colorId');
      return createdEvent;

    } catch (e) {
      _logger.e('Failed to create calendar event: $e');
      return null;
    }
  }

  /// カレンダーイベントを削除
  static Future<bool> deleteEvent({
    required String eventId,
    String calendarId = 'primary',
  }) async {
    try {
      final api = await _initializeCalendarApi();
      if (api == null) return false;

      await api.events.delete(calendarId, eventId);
      _logger.i('Calendar event deleted: $eventId');
      return true;

    } catch (e) {
      _logger.e('Failed to delete calendar event: $e');
      return false;
    }
  }

  /// カレンダーイベントを更新
  static Future<calendar.Event?> updateEvent({
    required String eventId,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? colorId,
    String calendarId = 'primary',
  }) async {
    try {
      final api = await _initializeCalendarApi();
      if (api == null) return null;

      final event = calendar.Event()
        ..summary = title
        ..description = description
        ..start = calendar.EventDateTime()
        ..start!.dateTime = startTime
        ..start!.timeZone = 'Asia/Tokyo'
        ..end = calendar.EventDateTime()
        ..end!.dateTime = endTime
        ..end!.timeZone = 'Asia/Tokyo';

      // 色情報を設定（Google Calendar colorId）
      if (colorId != null && colorId.isNotEmpty) {
        event.colorId = colorId;
      }

      final updatedEvent = await api.events.update(event, calendarId, eventId);
      _logger.i('Calendar event updated: $eventId with color: $colorId');
      return updatedEvent;

    } catch (e) {
      _logger.e('Failed to update calendar event: $e');
      return null;
    }
  }



  /// アクセストークンの有効性をチェック
  static Future<bool> isTokenValid() async {
    try {
      final api = await _initializeCalendarApi();
      if (api == null) return false;

      // 簡単なAPIコールでトークンの有効性をテスト
      await api.calendarList.list();
      
      // 成功した場合は認証エラー状態をクリア
      _isAuthenticationError = false;
      _lastAuthError = null;
      
      return true;
    } catch (e) {
      _logger.e('Token validation failed: $e');
      _setAuthenticationError('Token validation failed: $e');
      return false;
    }
  }

  /// 強制的にトークンを更新
  static Future<bool> refreshToken() async {
    // 同時実行を防ぐ
    if (_initializationCompleter != null) {
      _logger.w('Cannot refresh token while initialization is in progress');
      return false;
    }

    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      
      if (account != null) {
        _calendarApi = null; // 次回アクセス時に再初期化
        
        // 認証エラー状態をクリア
        _isAuthenticationError = false;
        _lastAuthError = null;
        _lastAuthErrorTime = null;
        
        _logger.i('Google Calendar token refreshed successfully');
        return true;
      } else {
        _logger.w('User cancelled Google sign-in');
        return false;
      }
    } catch (e) {
      _logger.e('Failed to refresh token: $e');
      _setAuthenticationError('Failed to refresh token: $e');
      return false;
    }
  }

  /// 認証エラー状態を設定
  static void _setAuthenticationError(String error) {
    _isAuthenticationError = true;
    _lastAuthError = error;
    _lastAuthErrorTime = DateTime.now();
  }

  /// 認証エラー状態を取得
  static bool get hasAuthenticationError => _isAuthenticationError;

  /// 最後の認証エラーメッセージを取得
  static String? get lastAuthError => _lastAuthError;

  /// 最後の認証エラー時刻を取得
  static DateTime? get lastAuthErrorTime => _lastAuthErrorTime;

  /// 認証エラー状態をクリア
  static void clearAuthenticationError() {
    _isAuthenticationError = false;
    _lastAuthError = null;
    _lastAuthErrorTime = null;
  }

  /// 認証エラーが特定の時間以内に発生したかチェック
  static bool isRecentAuthError({Duration threshold = const Duration(minutes: 5)}) {
    if (!_isAuthenticationError || _lastAuthErrorTime == null) return false;
    
    final now = DateTime.now();
    return now.difference(_lastAuthErrorTime!) < threshold;
  }
} 