import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Android固有のサービスを提供するクラス
class AndroidService {
  static const MethodChannel _channel = MethodChannel('com.ban500.wellfin/android');

  /// Androidかどうかを判定
  static bool get isAndroid => Platform.isAndroid;

  /// 権限の要求
  static Future<bool> requestPermission(Permission permission) async {
    if (!isAndroid) return true;

    final status = await permission.request();
    return status.isGranted;
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
} 