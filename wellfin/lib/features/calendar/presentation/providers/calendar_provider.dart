import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import '../../../../shared/services/google_calendar_service.dart';
import '../../domain/entities/calendar_event.dart';

/// カレンダー状態管理
class CalendarState {
  final List<CalendarEvent> events;
  final bool isLoading;
  final String? error;
  final DateTime selectedDate;

  const CalendarState({
    this.events = const [],
    this.isLoading = false,
    this.error,
    required this.selectedDate,
  });

  CalendarState copyWith({
    List<CalendarEvent>? events,
    bool? isLoading,
    String? error,
    DateTime? selectedDate,
  }) {
    return CalendarState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

/// カレンダープロバイダー
class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier() : super(CalendarState(selectedDate: DateTime.now()));
  
  bool _isLoading = false;



  /// 指定期間のカレンダーイベントを取得
  Future<void> loadEvents(DateTime start, DateTime end) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final googleEvents = await GoogleCalendarService.getEvents(
        startTime: start,
        endTime: end,
      );

      final events = googleEvents.map((event) => _convertToCalendarEvent(event)).toList();

      state = state.copyWith(
        events: events,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'イベント取得に失敗しました: $e',
        isLoading: false,
      );
    }
  }

  /// カレンダーイベントを作成
  Future<bool> createEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? colorId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final createdEvent = await GoogleCalendarService.createEvent(
        title: title,
        startTime: startTime,
        endTime: endTime,
        description: description,
        colorId: colorId,
      );

      if (createdEvent != null) {
        // 既存のイベントリストに追加
        final newEvent = _convertToCalendarEvent(createdEvent);
        final updatedEvents = [...state.events, newEvent];
        
        // イベント作成完了
        
        state = state.copyWith(
          events: updatedEvents,
          isLoading: false,
        );
        
        return true;
      } else {
        state = state.copyWith(
          error: 'イベント作成に失敗しました',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        error: 'イベント作成に失敗しました: $e',
        isLoading: false,
      );
      return false;
    }
  }

  /// カレンダーイベントを移動（ローカル状態更新）
  void moveEventLocally(CalendarEvent originalEvent, DateTime newStartTime) {
    // 新しい終了時間を計算
    final duration = originalEvent.endTime.difference(originalEvent.startTime);
    final newEndTime = newStartTime.add(duration);

    // copyWithを使って効率的に更新
    final updatedEvent = originalEvent.copyWith(
      startTime: newStartTime,
      endTime: newEndTime,
    );

    // イベントリストを更新
    final updatedEvents = state.events.map((event) {
      return event.id == originalEvent.id ? updatedEvent : event;
    }).toList();

    state = state.copyWith(events: updatedEvents);
  }

  /// カレンダーイベントを削除（ローカル状態）
  void removeEventLocally(String eventId) {
    final updatedEvents = state.events.where((event) => event.id != eventId).toList();
    state = state.copyWith(events: updatedEvents);
  }

  /// カレンダーイベントを削除（Google Calendar + ローカル状態）
  Future<bool> deleteEvent(String eventId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Google Calendarから削除
      final success = await GoogleCalendarService.deleteEvent(eventId: eventId);

      if (success) {
        // イベント削除完了
        
        // ローカル状態からも削除
        removeEventLocally(eventId);
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          error: 'イベント削除に失敗しました',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        error: 'イベント削除に失敗しました: $e',
        isLoading: false,
      );
      return false;
    }
  }

  /// カレンダーイベントを更新（Google Calendar + ローカル状態）
  Future<bool> updateEvent({
    required String eventId,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? colorId,
  }) async {
    try {
      // Google Calendarで更新
      final updatedEvent = await GoogleCalendarService.updateEvent(
        eventId: eventId,
        title: title,
        startTime: startTime,
        endTime: endTime,
        description: description,
        colorId: colorId,
      );

      if (updatedEvent != null) {
        // ローカル状態を更新
        final newEvent = _convertToCalendarEvent(updatedEvent);
        final updatedEvents = state.events.map((event) {
          return event.id == eventId ? newEvent : event;
        }).toList();
        
        state = state.copyWith(events: updatedEvents);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Failed to update event: $e');
      return false;
    }
  }

  /// Google Calendar EventをCalendarEventに変換
  CalendarEvent _convertToCalendarEvent(calendar.Event googleEvent) {
    // タイムゾーン変換を適切に処理
    DateTime startTime = DateTime.now();
    DateTime endTime = DateTime.now();
    
    // Google Calendar APIの時間データを日本時間に変換
    if (googleEvent.start?.dateTime != null) {
      startTime = googleEvent.start!.dateTime!.toLocal();
    } else if (googleEvent.start?.date != null) {
      // 終日イベントの場合
      startTime = googleEvent.start!.date!;
    }
    
    if (googleEvent.end?.dateTime != null) {
      endTime = googleEvent.end!.dateTime!.toLocal();
    } else if (googleEvent.end?.date != null) {
      // 終日イベントの場合
      endTime = googleEvent.end!.date!;
    }
    
    return CalendarEvent(
      id: googleEvent.id ?? '',
      title: googleEvent.summary ?? '無題',
      description: googleEvent.description,
      startTime: startTime,
      endTime: endTime,
      isAllDay: googleEvent.start?.date != null,
      attendees: googleEvent.attendees?.map((a) => a.email ?? '').toList() ?? [],
      location: googleEvent.location,
      url: googleEvent.htmlLink,
      colorId: googleEvent.colorId,
    );
  }

  /// トークンの有効性をチェックし、必要に応じて更新
  Future<bool> checkAndRefreshToken() async {
    // 同時実行を防ぐ
    if (_isLoading) {
      return false;
    }
    
    _isLoading = true;
    try {
      final isValid = await GoogleCalendarService.isTokenValid();
      if (!isValid) {
        await GoogleCalendarService.refreshToken();
        return await GoogleCalendarService.isTokenValid();
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: 'トークン更新に失敗しました: $e');
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 選択日を変更
  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }
}

/// カレンダープロバイダーのインスタンス
final calendarProvider = StateNotifierProvider<CalendarNotifier, CalendarState>(
  (ref) => CalendarNotifier(),
);



/// 週間イベント取得プロバイダー
final weeklyEventsProvider = FutureProvider.family<List<CalendarEvent>, DateTime>(
  (ref, startOfWeek) async {
    final endOfWeek = startOfWeek.add(Duration(days: 7));
    final calendarNotifier = ref.read(calendarProvider.notifier);
    await calendarNotifier.loadEvents(startOfWeek, endOfWeek);
    return ref.read(calendarProvider).events;
  },
);

/// Google Calendar認証状態プロバイダー
final calendarAuthProvider = FutureProvider<bool>((ref) async {
  return await GoogleCalendarService.isTokenValid();
}); 