import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../navigation/app_routes.dart';
import '../network/api_client.dart';

class PushNotificationMessage {
  const PushNotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
  });

  final String? id;
  final String? title;
  final String? body;
  final Map<String, String> data;

  String get targetRoute => switch (data['notification_type']) {
    'member_payment_reminder' => '${AppRoutes.paymentsPath}?admin=false',
    'admin_payment_reminder' => '${AppRoutes.paymentsPath}?admin=true',
    _ => AppRoutes.notificationsPath,
  };
}

enum PushPermissionStatus { authorized, provisional, denied, unknown }

abstract interface class PushMessagingPlatform {
  Future<void> initialize();
  Future<PushPermissionStatus> requestPermission();
  Future<String?> getToken();
  Stream<String> get tokenRefreshes;
  Stream<PushNotificationMessage> get foregroundMessages;
  Stream<PushNotificationMessage> get openedMessages;
  Future<PushNotificationMessage?> getInitialMessage();
}

abstract interface class ForegroundNotificationPresenter {
  Future<void> initialize(void Function(String route) onOpen);
  Future<void> show(PushNotificationMessage message);
}

class FirebasePushMessagingPlatform implements PushMessagingPlatform {
  @override
  Future<void> initialize() async {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: false,
          badge: false,
          sound: false,
        );
  }

  @override
  Future<PushPermissionStatus> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized => PushPermissionStatus.authorized,
      AuthorizationStatus.provisional => PushPermissionStatus.provisional,
      AuthorizationStatus.denied => PushPermissionStatus.denied,
      AuthorizationStatus.deniedPermanently => PushPermissionStatus.denied,
      AuthorizationStatus.notDetermined => PushPermissionStatus.unknown,
    };
  }

  @override
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  @override
  Stream<String> get tokenRefreshes =>
      FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<PushNotificationMessage> get foregroundMessages =>
      FirebaseMessaging.onMessage.map(_mapMessage);

  @override
  Stream<PushNotificationMessage> get openedMessages =>
      FirebaseMessaging.onMessageOpenedApp.map(_mapMessage);

  @override
  Future<PushNotificationMessage?> getInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    return message == null ? null : _mapMessage(message);
  }

  static PushNotificationMessage _mapMessage(RemoteMessage message) =>
      PushNotificationMessage(
        id: message.messageId,
        title: message.notification?.title,
        body: message.notification?.body,
        data: message.data.map((key, value) => MapEntry(key, value.toString())),
      );
}

class LocalForegroundNotificationPresenter
    implements ForegroundNotificationPresenter {
  LocalForegroundNotificationPresenter([
    FlutterLocalNotificationsPlugin? plugin,
  ]) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'membership_reminders';
  static const _channelName = 'Podsjetnici članarine';
  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize(void Function(String route) onOpen) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route != null && route.isNotEmpty) onOpen(route);
      },
    );
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: 'Podsjetnici i statusi članarine',
              importance: Importance.high,
            ),
          );
    }
  }

  @override
  Future<void> show(PushNotificationMessage message) => _plugin.show(
    id:
        int.tryParse(message.data['notification_id'] ?? '') ??
        (message.id?.hashCode ?? DateTime.now().millisecondsSinceEpoch),
    title: message.title,
    body: message.body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Podsjetnici i statusi članarine',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
      ),
    ),
    payload: message.targetRoute,
  );
}

class PushNotificationsService {
  PushNotificationsService(
    this._api, {
    PushMessagingPlatform? messaging,
    ForegroundNotificationPresenter? presenter,
  }) : _messaging = messaging ?? FirebasePushMessagingPlatform(),
       _presenter = presenter ?? LocalForegroundNotificationPresenter();

  final ApiClient _api;
  final PushMessagingPlatform _messaging;
  final ForegroundNotificationPresenter _presenter;
  final _routes = StreamController<String>.broadcast();
  StreamSubscription<String>? _refreshSubscription;
  StreamSubscription<PushNotificationMessage>? _foregroundSubscription;
  StreamSubscription<PushNotificationMessage>? _openedSubscription;
  bool _initialized = false;
  String? _pendingRoute;

  Stream<String> get openedRoutes => _routes.stream;
  bool get isInitialized => _initialized;

  String? takePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  Future<void> initialize() async {
    if (_initialized || kIsWeb || !_isMobile) return;
    try {
      await _messaging.initialize();
      await _presenter.initialize(_openRoute);
      _refreshSubscription = _messaging.tokenRefreshes.listen(_register);
      _foregroundSubscription = _messaging.foregroundMessages.listen(
        _showForeground,
      );
      _openedSubscription = _messaging.openedMessages.listen(
        (message) => _openRoute(message.targetRoute),
      );
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) _pendingRoute = initialMessage.targetRoute;
      _initialized = true;
    } catch (error) {
      await _refreshSubscription?.cancel();
      await _foregroundSubscription?.cancel();
      await _openedSubscription?.cancel();
      _refreshSubscription = null;
      _foregroundSubscription = null;
      _openedSubscription = null;
      debugPrint('Firebase Messaging is not configured: $error');
    }
  }

  Future<PushPermissionStatus> requestPermission() async {
    await initialize();
    if (!_initialized) return PushPermissionStatus.unknown;
    return _messaging.requestPermission();
  }

  Future<void> registerCurrentToken() async {
    final permission = await requestPermission();
    if (permission != PushPermissionStatus.authorized &&
        permission != PushPermissionStatus.provisional) {
      return;
    }
    final token = await _messaging.getToken();
    if (token != null) await _register(token);
  }

  Future<void> unregisterCurrentToken() async {
    if (!_initialized) return;
    final token = await _messaging.getToken();
    if (token == null) return;
    try {
      await _api.delete<void>(
        '/api/notifications/device-token',
        data: {'token': token, 'platform': _platform},
      );
    } catch (_) {
      // Logging out must not be blocked by push cleanup.
    }
  }

  Future<void> _register(String token) async {
    final platform = _platform;
    if (platform == null) return;
    try {
      await _api.put<void>(
        '/api/notifications/device-token',
        data: {'token': token, 'platform': platform},
      );
    } catch (_) {
      // The token is retried after the next login or Firebase refresh.
    }
  }

  void _openRoute(String route) {
    if (_routes.hasListener) {
      _routes.add(route);
    } else {
      _pendingRoute = route;
    }
  }

  Future<void> _showForeground(PushNotificationMessage message) async {
    try {
      await _presenter.show(message);
    } catch (error) {
      debugPrint('Could not display a foreground notification: $error');
    }
  }

  bool get _isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  String? get _platform => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    _ => null,
  };

  Future<void> dispose() async {
    await _refreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _routes.close();
  }
}
