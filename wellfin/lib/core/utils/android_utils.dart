import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Android固有の機能を提供するユーティリティクラス
class AndroidUtils {
  static const MethodChannel _channel = MethodChannel('com.ban500.wellfin/android');

  /// Androidかどうかを判定
  static bool get isAndroid => Platform.isAndroid;

  /// システムUIの設定
  static Future<void> setSystemUIOverlayStyle({
    SystemUiOverlayStyle? style,
  }) async {
    if (!isAndroid) return;

    final defaultStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    );

    SystemChrome.setSystemUIOverlayStyle(style ?? defaultStyle);
  }

  /// ダークモード用のシステムUI設定
  static void setDarkSystemUI() {
    if (!isAndroid) return;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF121212),
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  /// ライトモード用のシステムUI設定
  static void setLightSystemUI() {
    if (!isAndroid) return;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  /// 画面の向きを固定
  static Future<void> setPreferredOrientations(List<DeviceOrientation> orientations) async {
    await SystemChrome.setPreferredOrientations(orientations);
  }

  /// 画面の向きを縦向きに固定
  static Future<void> setPortraitMode() async {
    await setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  /// 画面の向きを横向きに固定
  static Future<void> setLandscapeMode() async {
    await setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// 画面の向きを自動に設定
  static Future<void> setAutoOrientation() async {
    await setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// 権限の要求
  static Future<bool> requestPermission(Permission permission) async {
    if (!isAndroid) return true;

    final status = await permission.request();
    return status.isGranted;
  }

  /// 複数の権限を要求
  static Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    if (!isAndroid) {
      return {for (var permission in permissions) permission: PermissionStatus.granted};
    }

    return await permissions.request();
  }

  /// 通知権限の要求
  static Future<bool> requestNotificationPermission() async {
    if (!isAndroid) return true;

    return await requestPermission(Permission.notification);
  }

  /// カメラ権限の要求
  static Future<bool> requestCameraPermission() async {
    if (!isAndroid) return true;

    return await requestPermission(Permission.camera);
  }

  /// 位置情報権限の要求
  static Future<bool> requestLocationPermission() async {
    if (!isAndroid) return true;

    final fineLocation = await requestPermission(Permission.location);
    if (!fineLocation) {
      return await requestPermission(Permission.locationWhenInUse);
    }
    return fineLocation;
  }

  /// ストレージ権限の要求
  static Future<bool> requestStoragePermission() async {
    if (!isAndroid) return true;

    return await requestPermission(Permission.storage);
  }

  /// バイブレーション機能
  static Future<void> vibrate({Duration? duration}) async {
    if (!isAndroid) return;

    try {
      await _channel.invokeMethod('vibrate', {
        'duration': duration?.inMilliseconds ?? 100,
      });
    } catch (e) {
      // フォールバック: HapticFeedbackを使用
      HapticFeedback.lightImpact();
    }
  }

  /// 長いバイブレーション
  static Future<void> vibrateLong() async {
    await vibrate(duration: const Duration(milliseconds: 500));
  }

  /// 短いバイブレーション
  static Future<void> vibrateShort() async {
    await vibrate(duration: const Duration(milliseconds: 100));
  }

  /// デバイス情報の取得
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    if (!isAndroid) return {};

    try {
      final result = await _channel.invokeMethod('getDeviceInfo');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {};
    }
  }

  /// バッテリー情報の取得
  static Future<Map<String, dynamic>> getBatteryInfo() async {
    if (!isAndroid) return {};

    try {
      final result = await _channel.invokeMethod('getBatteryInfo');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {};
    }
  }

  /// ネットワーク情報の取得
  static Future<Map<String, dynamic>> getNetworkInfo() async {
    if (!isAndroid) return {};

    try {
      final result = await _channel.invokeMethod('getNetworkInfo');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {};
    }
  }

  /// アプリのバージョン情報を取得
  static Future<Map<String, dynamic>> getAppVersion() async {
    if (!isAndroid) return {};

    try {
      final result = await _channel.invokeMethod('getAppVersion');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {};
    }
  }

  /// ファイル共有
  static Future<bool> shareFile(String filePath, {String? mimeType}) async {
    if (!isAndroid) return false;

    try {
      final result = await _channel.invokeMethod('shareFile', {
        'filePath': filePath,
        'mimeType': mimeType,
      });
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// テキスト共有
  static Future<bool> shareText(String text, {String? subject}) async {
    if (!isAndroid) return false;

    try {
      final result = await _channel.invokeMethod('shareText', {
        'text': text,
        'subject': subject,
      });
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// アプリの評価を開く
  static Future<void> openAppRating() async {
    if (!isAndroid) return;

    try {
      await _channel.invokeMethod('openAppRating');
    } catch (e) {
      // フォールバック処理
    }
  }

  /// 設定画面を開く
  static Future<void> openAppSettings() async {
    if (!isAndroid) return;

    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (e) {
      // フォールバック処理
    }
  }

  /// ホーム画面に戻る
  static Future<void> goToHome() async {
    if (!isAndroid) return;

    try {
      await _channel.invokeMethod('goToHome');
    } catch (e) {
      // フォールバック処理
    }
  }

  /// 最近のアプリ画面を開く
  static Future<void> openRecentApps() async {
    if (!isAndroid) return;

    try {
      await _channel.invokeMethod('openRecentApps');
    } catch (e) {
      // フォールバック処理
    }
  }
} 