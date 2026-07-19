import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialization settings
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions for Android 13+
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    _isInitialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
    // This will be used for deep linking to product detail screen
    final payload = response.payload;
    if (payload != null) {
      // Navigate to product detail screen
      // This would need to be implemented with navigation logic
      // ignore: avoid_print
      print('Notification tapped with payload: $payload');
    }
  }

  Future<void> showPriceDropNotification({
    required String productName,
    required double oldPrice,
    required double newPrice,
    required double priceDropPercent,
    required String productId,
  }) async {
    if (!_isInitialized) await initialize();

    final priceDropString = priceDropPercent.abs().toStringAsFixed(1);
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'price_drops_channel',
      'Price Drops',
      channelDescription: 'Notifications for price drops',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Price Drop Alert!',
      '$productName: ${oldPrice.toStringAsFixed(2)}₺ → ${newPrice.toStringAsFixed(2)}₺ ($priceDropString% düşüş)',
      platformChannelSpecifics,
      payload: 'product_detail:$productId',
    );
  }

  Future<void> showTargetPriceNotification({
    required String productName,
    required double targetPrice,
    required double currentPrice,
    required String productId,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'target_price_channel',
      'Target Price Reached',
      channelDescription: 'Notifications when target price is reached',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Target Price Reached! 🎉',
      '$productName has reached your target price of ${targetPrice.toStringAsFixed(2)}₺! Current price: ${currentPrice.toStringAsFixed(2)}₺',
      platformChannelSpecifics,
      payload: 'product_detail:$productId',
    );
  }

  Future<void> showCheckErrorNotification({
    required String productName,
    required String errorType,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'check_errors_channel',
      'Price Check Errors',
      channelDescription: 'Notifications for price check errors',
      importance: Importance.low,
      priority: Priority.low,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Price Check Error',
      '$productName: Could not check price ($errorType)',
      platformChannelSpecifics,
      payload: null,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }
}
