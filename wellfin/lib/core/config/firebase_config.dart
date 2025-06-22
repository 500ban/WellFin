import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp();
    
    // Analytics設定
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    
    // Crashlytics設定
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    
    // Performance設定
    await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
  }
} 