import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class TelephonyPlatform {
  static const MethodChannel _androidChannel =
      MethodChannel('cc.blackmatter.opencaller/call_screening');
  static const MethodChannel _iosChannel =
      MethodChannel('cc.blackmatter.opencaller/callkit');

  /// Android: Requests user to set OpenCaller as the Call Screening app
  static Future<bool> requestCallScreeningRole() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final result = await _androidChannel.invokeMethod<bool>('requestRole');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error requesting CallScreening role: $e');
      return false;
    }
  }

  /// Android: Checks if OpenCaller currently holds the Call Screening role
  static Future<bool> isCallScreeningEnabled() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final result = await _androidChannel.invokeMethod<bool>('checkRoleStatus');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking CallScreening role: $e');
      return false;
    }
  }

  /// iOS: Triggers CXCallDirectoryManager to reload the extension dataset
  static Future<bool> reloadCallDirectoryExtension() async {
    if (kIsWeb || !Platform.isIOS) return false;
    try {
      final result = await _iosChannel.invokeMethod<bool>('reloadExtension');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error reloading Call Directory Extension: $e');
      return false;
    }
  }

  /// iOS: Checks whether user has enabled the OpenCaller extension in iOS Settings
  static Future<int> getCallDirectoryEnabledStatus() async {
    if (kIsWeb || !Platform.isIOS) return 0;
    try {
      // 0: Unknown, 1: Disabled, 2: Enabled
      final result = await _iosChannel.invokeMethod<int>('getExtensionStatus');
      return result ?? 0;
    } on PlatformException catch (e) {
      debugPrint('Error checking extension status: $e');
      return 0;
    }
  }

  /// Opens iOS Settings > Phone > Call Blocking & Identification
  static Future<void> openSystemSettings() async {
    if (kIsWeb) return;
    try {
      if (Platform.isIOS) {
        await _iosChannel.invokeMethod('openSettings');
      } else if (Platform.isAndroid) {
        await _androidChannel.invokeMethod('openSettings');
      }
    } catch (e) {
      debugPrint('Error opening settings: $e');
    }
  }
}
