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
  final NotificationChannels notificationChannels;
  final List<int> productivityPeakHours;
  final int weekStartDay;

  UserPreferences({
    this.language = 'ja',
    this.theme = 'system',
    required this.notificationChannels,
    this.productivityPeakHours = const [9, 10, 11, 14, 15, 16],
    this.weekStartDay = 1,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      language: map['language'] ?? 'ja',
      theme: map['theme'] ?? 'system',
      notificationChannels: NotificationChannels.fromMap(map['notificationChannels'] ?? {}),
      productivityPeakHours: List<int>.from(map['productivityPeakHours'] ?? [9, 10, 11, 14, 15, 16]),
      weekStartDay: map['weekStartDay'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'theme': theme,
      'notificationChannels': notificationChannels.toMap(),
      'productivityPeakHours': productivityPeakHours,
      'weekStartDay': weekStartDay,
    };
  }
}

class NotificationChannels {
  final bool app;
  final bool push;
  final bool email;

  NotificationChannels({
    this.app = true,
    this.push = true,
    this.email = false,
  });

  factory NotificationChannels.fromMap(Map<String, dynamic> map) {
    return NotificationChannels(
      app: map['app'] ?? true,
      push: map['push'] ?? true,
      email: map['email'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'app': app,
      'push': push,
      'email': email,
    };
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
  final int completedTasks;
  final double completionRate;
  final int streakDays;
  final int totalGoalsCompleted;

  UserStats({
    this.completedTasks = 0,
    this.completionRate = 0.0,
    this.streakDays = 0,
    this.totalGoalsCompleted = 0,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      completedTasks: map['completedTasks'] ?? 0,
      completionRate: (map['completionRate'] ?? 0.0).toDouble(),
      streakDays: map['streakDays'] ?? 0,
      totalGoalsCompleted: map['totalGoalsCompleted'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'completedTasks': completedTasks,
      'completionRate': completionRate,
      'streakDays': streakDays,
      'totalGoalsCompleted': totalGoalsCompleted,
    };
  }
} 