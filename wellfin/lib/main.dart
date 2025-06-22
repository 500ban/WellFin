import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/firebase_config.dart';
import 'core/config/google_cloud_config.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/user_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'shared/widgets/loading_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase初期化
  await FirebaseConfig.initialize();
  
  // Google Cloud設定初期化
  await GoogleCloudConfig.initialize();
  
  runApp(const ProviderScope(child: WellFinApp()));
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
      
      // テーマ設定
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        
        // AppBarテーマ
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        
        // カードテーマ
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        
        // ボタンテーマ
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        
        // 入力フィールドテーマ
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
          ),
        ),
      ),
      
      // ダークテーマ
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      
      // ホームページ
      home: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authStateProvider);
          
          return authState.when(
            data: (user) {
              if (user != null) {
                // ユーザーがログインしている場合
                return Consumer(
                  builder: (context, ref, child) {
                    final userData = ref.watch(userDataProvider(user.uid));
                    
                    return userData.when(
                      data: (userModel) {
                        if (userModel != null) {
                          return const DashboardPage();
                        } else {
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
      },
    );
  }
}
