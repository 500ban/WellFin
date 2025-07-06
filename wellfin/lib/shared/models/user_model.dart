import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime lastLogin;
  final String timeZone;
  final UserPreferences preferences;
  final CalendarSync calendarSync;
  final UserStats stats;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.lastLogin,
    required this.timeZone,
    required this.preferences,
    required this.calendarSync,
    required this.stats,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: (data['lastLogin'] as Timestamp).toDate(),
      timeZone: data['timeZone'] ?? 'Asia/Tokyo',
      preferences: UserPreferences.fromMap(data['preferences'] ?? {}),
      calendarSync: CalendarSync.fromMap(data['calendarSync'] ?? {}),
      stats: UserStats.fromMap(data['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'timeZone': timeZone,
      'preferences': preferences.toMap(),
      'calendarSync': calendarSync.toMap(),
      'stats': stats.toMap(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? timeZone,
    UserPreferences? preferences,
    CalendarSync? calendarSync,
    UserStats? stats,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      timeZone: timeZone ?? this.timeZone,
      preferences: preferences ?? this.preferences,
      calendarSync: calendarSync ?? this.calendarSync,
      stats: stats ?? this.stats,
    );
  }
}

class UserPreferences {
  final String language;
  final String theme;
  final List<int> productivityPeakHours;
  final int weekStartDay;

  UserPreferences({
    this.language = 'ja',
    this.theme = 'system',
    this.productivityPeakHours = const [9, 10, 11, 14, 15, 16],
    this.weekStartDay = 1,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      language: map['language'] ?? 'ja',
      theme: map['theme'] ?? 'system',
      productivityPeakHours: List<int>.from(map['productivityPeakHours'] ?? [9, 10, 11, 14, 15, 16]),
      weekStartDay: map['weekStartDay'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'theme': theme,
      'productivityPeakHours': productivityPeakHours,
      'weekStartDay': weekStartDay,
    };
  }

  UserPreferences copyWith({
    String? language,
    String? theme,
    List<int>? productivityPeakHours,
    int? weekStartDay,
  }) {
    return UserPreferences(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      productivityPeakHours: productivityPeakHours ?? this.productivityPeakHours,
      weekStartDay: weekStartDay ?? this.weekStartDay,
    );
  }
}

class CalendarSync {
  final String? googleCalendarId;
  final DateTime? lastSyncTime;
  final List<String> syncedCalendars;

  CalendarSync({
    this.googleCalendarId,
    this.lastSyncTime,
    this.syncedCalendars = const [],
  });

  factory CalendarSync.fromMap(Map<String, dynamic> map) {
    return CalendarSync(
      googleCalendarId: map['googleCalendarId'],
      lastSyncTime: map['lastSyncTime'] != null 
          ? (map['lastSyncTime'] as Timestamp).toDate() 
          : null,
      syncedCalendars: List<String>.from(map['syncedCalendars'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'googleCalendarId': googleCalendarId,
      'lastSyncTime': lastSyncTime != null ? Timestamp.fromDate(lastSyncTime!) : null,
      'syncedCalendars': syncedCalendars,
    };
  }
}

class UserStats {
  final int totalTasks;
  final int completedTasks;
  final int totalHabits;
  final int completedHabits;
  final int totalGoals;
  final int completedGoals;
  final int totalMinutesLogged;
  final int currentStreak;
  final int longestStreak;

  UserStats({
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.totalHabits = 0,
    this.completedHabits = 0,
    this.totalGoals = 0,
    this.completedGoals = 0,
    this.totalMinutesLogged = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      totalTasks: map['totalTasks'] ?? 0,
      completedTasks: map['completedTasks'] ?? 0,
      totalHabits: map['totalHabits'] ?? 0,
      completedHabits: map['completedHabits'] ?? 0,
      totalGoals: map['totalGoals'] ?? 0,
      completedGoals: map['completedGoals'] ?? 0,
      totalMinutesLogged: map['totalMinutesLogged'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'totalHabits': totalHabits,
      'completedHabits': completedHabits,
      'totalGoals': totalGoals,
      'completedGoals': completedGoals,
      'totalMinutesLogged': totalMinutesLogged,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    };
  }
} 