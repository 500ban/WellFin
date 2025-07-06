import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Google Calendar色定数
class CalendarColors {
  static const Map<String, Map<String, dynamic>> colors = {
    '1': {'name': 'ラベンダー', 'color': Color(0xFF7986CB), 'id': '1'},
    '2': {'name': 'セージ', 'color': Color(0xFF33B679), 'id': '2'},
    '3': {'name': 'グレープ', 'color': Color(0xFF8E24AA), 'id': '3'},
    '4': {'name': 'フラミンゴ', 'color': Color(0xFFE67C73), 'id': '4'},
    '5': {'name': 'バナナ', 'color': Color(0xFFF6BF26), 'id': '5'},
    '6': {'name': 'タンジェリン', 'color': Color(0xFFFF8A65), 'id': '6'},
    '7': {'name': 'ピーコック', 'color': Color(0xFF039BE5), 'id': '7'},
    '8': {'name': 'グラファイト', 'color': Color(0xFF616161), 'id': '8'},
    '9': {'name': 'ブルーベリー', 'color': Color(0xFF3F51B5), 'id': '9'},
    '10': {'name': 'バジル', 'color': Color(0xFF0B8043), 'id': '10'},
    '11': {'name': 'トマト', 'color': Color(0xFFD50000), 'id': '11'},
  };

  static Color getColor(String? colorId) {
    return colors[colorId]?['color'] ?? const Color(0xFF1976D2);
  }

  static String getName(String? colorId) {
    return colors[colorId]?['name'] ?? 'デフォルト';
  }

  static List<MapEntry<String, Map<String, dynamic>>> get allColors {
    return colors.entries.toList();
  }
}

/// カレンダーイベントエンティティ
class CalendarEvent extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final List<String> attendees;
  final String? location;
  final String? url;
  final String? colorId; // Google Calendar colorId (1-11)

  const CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.attendees = const [],
    this.location,
    this.url,
    this.colorId,
  });

  /// イベントの色を取得
  Color get color => CalendarColors.getColor(colorId);

  /// イベントの継続時間を取得
  Duration get duration => endTime.difference(startTime);

  /// イベントが進行中かどうか
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// イベントが今日かどうか
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(startTime.year, startTime.month, startTime.day);
    return eventDay == today;
  }

  /// コピー用メソッド
  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    List<String>? attendees,
    String? location,
    String? url,
    String? colorId,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      attendees: attendees ?? this.attendees,
      location: location ?? this.location,
      url: url ?? this.url,
      colorId: colorId ?? this.colorId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        startTime,
        endTime,
        isAllDay,
        attendees,
        location,
        url,
        colorId,
      ];

  @override
  String toString() {
    return 'CalendarEvent(id: $id, title: $title, startTime: $startTime, endTime: $endTime, colorId: $colorId)';
  }
} 