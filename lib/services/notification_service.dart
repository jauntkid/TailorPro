import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'data_service.dart';

/// Local push notification service.
/// Schedules periodic notifications every 3 hours about orders due today.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  Timer? _periodicTimer;
  DataService? _dataService;

  static const _channelId = 'godukaan_due_orders';
  static const _channelName = 'Due Orders';
  static const _channelDesc = 'Notifications about orders due today';

  /// Initialize the notification plugin and request permissions.
  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    // Request Android 13+ notification permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Attach a DataService and start the periodic check.
  void attach(DataService ds) {
    _dataService = ds;
    // Check immediately on attach
    _checkAndNotify();
    // Then every 3 hours
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(hours: 3), (_) {
      _checkAndNotify();
    });
  }

  /// Stop the periodic timer.
  void detach() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _dataService = null;
  }

  /// Check for due-today orders and show a notification if any.
  Future<void> _checkAndNotify() async {
    final ds = _dataService;
    if (ds == null) return;

    final dueCount = ds.dueTodayOrders.length;
    if (dueCount <= 0) return;

    final title =
        '\u2702\ufe0f $dueCount order${dueCount > 1 ? 's' : ''} due today';
    final body = dueCount == 1
        ? 'You have 1 order due today. Tap to check details.'
        : 'You have $dueCount orders due today. Tap to review them.';

    await _showNotification(id: 100, title: title, body: body);
  }

  /// Show a local notification.
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFD4A574),
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    try {
      await _plugin.show(id, title, body, details);
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
