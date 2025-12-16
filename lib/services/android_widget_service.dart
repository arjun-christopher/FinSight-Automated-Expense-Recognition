import 'package:flutter/services.dart';
import 'dart:io' show Platform;

/// Service for managing Android home screen widget
/// Updates widget with today's spending information
class AndroidWidgetService {
  static const MethodChannel _channel = MethodChannel('com.finsight.app/widget');

  /// Update the Android widget with today's spending data
  /// 
  /// [todayAmount] - Total amount spent today
  /// [expenseCount] - Number of expenses today
  /// 
  /// Returns true if update was successful
  Future<bool> updateWidget({
    required double todayAmount,
    required int expenseCount,
  }) async {
    // Only update on Android
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod('updateWidget', {
        'todayAmount': todayAmount,
        'expenseCount': expenseCount,
      });
      
      return result == true;
    } on PlatformException catch (e) {
      print('Failed to update widget: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error updating widget: $e');
      return false;
    }
  }

  /// Get the initial route if app was launched from widget
  /// Returns null if launched normally, or a route like "/add-expense" if launched from widget
  Future<String?> getInitialRoute() async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod('getInitialRoute');
      return result as String?;
    } catch (e) {
      print('Error getting initial route: $e');
      return null;
    }
  }

  /// Check if platform supports widgets
  bool get isWidgetSupported => Platform.isAndroid;
}
