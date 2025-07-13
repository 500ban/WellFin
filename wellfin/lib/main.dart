import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import 'core/config/firebase_config.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/user_provider.dart';
import 'shared/services/android_service.dart';
import 'shared/services/fcm_service.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/calendar/presentation/pages/calendar_page.dart';
import 'features/analytics/presentation/pages/analytics_page.dart';
import 'features/analytics/presentation/pages/weekly_report_page.dart';
import 'features/analytics/presentation/pages/monthly_report_page.dart';
import 'features/analytics/presentation/pages/productivity_patterns_page.dart';
import 'features/analytics/presentation/pages/goal_progress_tracking_page.dart';
import 'shared/widgets/loading_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Logger初期化
  final logger = Logger();
  
  // Android固有の初期化
  await _initializeAndroid(logger);
  
  // Firebase初期化
  await FirebaseConfig.initialize();
  
  // 通知サービス初期化
  await _initializeNotificationServices(logger);
  
  runApp(const ProviderScope(child: WellFinApp()));
}

/// Android固有の初期化処理
Future<void> _initializeAndroid(Logger logger) async {
  if (!AndroidService.isAndroid) return;

  logger.d('🚀 [Init] Starting Android initialization...');

  // システムUIの設定
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // 画面の向きを縦向きに固定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 通知権限の要求
  logger.d('🔔 [Init] Requesting notification permission...');
  final permissionGranted = await AndroidService.requestNotificationPermission();
  logger.d('🔔 [Init] Notification permission result: $permissionGranted');
}

/// 通知サービス初期化処理
Future<void> _initializeNotificationServices(Logger logger) async {
  try {
    logger.d('🔔 [Init] Starting notification services initialization...');
    
    // FCMService初期化
    logger.d('🔔 [Init] Initializing FCMService...');
    final fcmService = FCMService();
    final fcmInitialized = await fcmService.initialize(
      onMessageReceived: (message) {
        logger.d('🔔 [FCM] Message received: ${message.notification?.title}');
      },
      onMessageOpenedApp: (message) {
        logger.d('🔔 [FCM] Message opened app: ${message.notification?.title}');
      },
      onTokenRefresh: (token) {
        logger.d('🔔 [FCM] Token refreshed: $token');
      },
    );
    
    if (fcmInitialized) {
      logger.d('🔔 [Init] FCMService initialized successfully');
      logger.d('🔔 [FCM] Token: ${fcmService.currentToken}');
    } else {
      logger.d('🔔 [Init] FCMService initialization failed');
    }
    
    logger.d('🔔 [Init] Notification services initialization completed');
  } catch (e) {
    logger.e('🔔 [Init] Notification services initialization error: $e');
  }
}

class WellFinApp extends ConsumerWidget {
  const WellFinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'WellFin',
      debugShowCheckedModeBanner: false,
      
      // ローカライゼーション設定
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ja', 'JP'),
      
      // Material Design 3 テーマ設定
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      
      // ホームページ
      home: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authStateProvider);
          
          return authState.when(
            data: (user) {
              if (user != null) {
                // ユーザーがログインしている場合
                // 🔧 autoUserProviderを使用（無限ループを防ぐ）
                final userData = ref.watch(autoUserProvider);
                    
                return userData.when(
                  data: (userModel) {
                    if (userModel != null) {
                      return const DashboardPage();
                    } else {
                      // ユーザーデータが存在しない場合、ログインページに戻す
                      return const LoginPage();
                    }
                  },
                  loading: () => const LoadingWidget(),
                  error: (error, stack) {
                    // エラーの場合はログインページに戻す
                    return const LoginPage();
                  },
                );
              } else {
                // ユーザーがログインしていない場合
                return const LoginPage();
              }
            },
            loading: () => const LoadingWidget(),
            error: (error, stack) {
              // エラーの場合はログインページに戻す
              return const LoginPage();
            },
          );
        },
      ),
      
      // ルート設定
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/calendar': (context) => const CalendarPage(),
        '/analytics': (context) => const AnalyticsPage(),
        '/weekly-report': (context) => const WeeklyReportPage(),
        '/monthly-report': (context) => const MonthlyReportPage(),
        '/productivity-patterns': (context) => const ProductivityPatternsPage(),
        '/goal-progress': (context) => const GoalProgressTrackingPage(),
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.light,
        primary: const Color(0xFF2196F3),
        secondary: const Color(0xFF03DAC6),
        tertiary: const Color(0xFFE91E63),
        surface: const Color(0xFFFAFAFA),
        background: const Color(0xFFFFFFFF),
        error: const Color(0xFFB00020),
      ),
      fontFamily: 'Roboto',
      
      // AppBarテーマ
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
      ),
      
      // カードテーマ
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      
      // ボタンテーマ
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // 入力フィールドテーマ
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB00020), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: Colors.grey.shade600),
        floatingLabelStyle: const TextStyle(color: Color(0xFF2196F3)),
      ),
      
      // ボトムナビゲーションテーマ
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF2196F3),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // フローティングアクションボタンテーマ
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      
      // ダイアログテーマ
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: Colors.black54,
        ),
      ),
      
      // スナックバーテーマ
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF323232),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.dark,
        primary: const Color(0xFF90CAF9),
        secondary: const Color(0xFF80DEEA),
        tertiary: const Color(0xFFF48FB1),
        surface: const Color(0xFF121212),
        background: const Color(0xFF000000),
        error: const Color(0xFFCF6679),
      ),
      fontFamily: 'Roboto',
      
      // AppBarテーマ
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
      ),
      
      // カードテーマ
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      
      // ボタンテーマ
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF90CAF9),
          foregroundColor: Colors.black,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // 入力フィールドテーマ
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF90CAF9), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCF6679), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: Color(0xFFBDBDBD)),
        floatingLabelStyle: const TextStyle(color: Color(0xFF90CAF9)),
      ),
      
      // ボトムナビゲーションテーマ
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: Color(0xFF90CAF9),
        unselectedItemColor: Color(0xFF757575),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // フローティングアクションボタンテーマ
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF90CAF9),
        foregroundColor: Colors.black,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      
      // ダイアログテーマ
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: Color(0xFFBDBDBD),
        ),
      ),
      
      // スナックバーテーマ
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF424242),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
