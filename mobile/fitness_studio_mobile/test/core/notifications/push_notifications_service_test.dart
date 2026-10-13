import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fitness_studio_mobile/core/auth/access_token_provider.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/core/network/api_client.dart';
import 'package:fitness_studio_mobile/core/notifications/push_notifications_service.dart';
import 'package:fitness_studio_mobile/navigation/app_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('maps payment notification types to the correct screens', () {
    expect(
      _message('member_payment_reminder').targetRoute,
      '${AppRoutes.paymentsPath}?admin=false',
    );
    expect(
      _message('admin_payment_reminder').targetRoute,
      '${AppRoutes.paymentsPath}?admin=true',
    );
    expect(_message('other').targetRoute, AppRoutes.notificationsPath);
  });

  test('shows foreground message and emits its route when tapped', () async {
    final messaging = _FakeMessagingPlatform();
    final presenter = _FakePresenter();
    final service = PushNotificationsService(
      _client(_CapturingAdapter()),
      messaging: messaging,
      presenter: presenter,
    );
    addTearDown(service.dispose);
    await service.initialize();

    final route = service.openedRoutes.first;
    final message = _message('member_payment_reminder');
    messaging.foregroundController.add(message);
    await Future<void>.delayed(Duration.zero);
    expect(presenter.messages, [message]);

    presenter.open(message.targetRoute);
    expect(await route, '${AppRoutes.paymentsPath}?admin=false');
  });

  test('registers an authorized device token after login', () async {
    final adapter = _CapturingAdapter();
    final messaging = _FakeMessagingPlatform(token: 'fcm-token');
    final service = PushNotificationsService(
      _client(adapter),
      messaging: messaging,
      presenter: _FakePresenter(),
    );
    addTearDown(service.dispose);

    await service.registerCurrentToken();

    expect(adapter.request?.method, 'PUT');
    expect(adapter.request?.path, '/api/notifications/device-token');
    expect(adapter.request?.data, {
      'token': 'fcm-token',
      'platform': 'android',
    });
  });

  test('does not register a token when permission is denied', () async {
    final adapter = _CapturingAdapter();
    final service = PushNotificationsService(
      _client(adapter),
      messaging: _FakeMessagingPlatform(
        permission: PushPermissionStatus.denied,
        token: 'fcm-token',
      ),
      presenter: _FakePresenter(),
    );
    addTearDown(service.dispose);

    await service.registerCurrentToken();

    expect(adapter.request, isNull);
  });

  test(
    'registers refreshed tokens and removes the current token on logout',
    () async {
      final adapter = _CapturingAdapter();
      final messaging = _FakeMessagingPlatform(token: 'current-token');
      final service = PushNotificationsService(
        _client(adapter),
        messaging: messaging,
        presenter: _FakePresenter(),
      );
      addTearDown(service.dispose);
      await service.initialize();

      final refreshedRequest = adapter.nextRequest;
      messaging.tokenController.add('refreshed-token');
      await refreshedRequest;
      expect(adapter.request?.method, 'PUT');
      expect(adapter.request?.data, {
        'token': 'refreshed-token',
        'platform': 'android',
      });

      await service.unregisterCurrentToken();
      expect(adapter.request?.method, 'DELETE');
      expect(adapter.request?.data, {
        'token': 'current-token',
        'platform': 'android',
      });
    },
  );

  test(
    'keeps an initial notification route until the app consumes it',
    () async {
      final service = PushNotificationsService(
        _client(_CapturingAdapter()),
        messaging: _FakeMessagingPlatform(
          initialMessage: _message('admin_payment_reminder'),
        ),
        presenter: _FakePresenter(),
      );
      addTearDown(service.dispose);

      await service.initialize();

      expect(
        service.takePendingRoute(),
        '${AppRoutes.paymentsPath}?admin=true',
      );
      expect(service.takePendingRoute(), isNull);
    },
  );
}

PushNotificationMessage _message(String type) => PushNotificationMessage(
  id: 'message-1',
  title: 'Članarina čeka uplatu',
  body: 'Iznos 70,00 EUR dospio je danas.',
  data: {'notification_id': '5', 'notification_type': type},
);

ApiClient _client(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
  dio.httpClientAdapter = adapter;
  return ApiClient(
    config: const AppConfig(apiBaseUrl: 'http://example.test'),
    accessTokenProvider: const _TokenProvider(),
    dio: dio,
  );
}

class _TokenProvider implements AccessTokenProvider {
  const _TokenProvider();

  @override
  Future<String?> getAccessToken() async => 'access-token';
}

class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? request;
  final _nextRequest = Completer<RequestOptions>();

  Future<RequestOptions> get nextRequest => _nextRequest.future;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    if (!_nextRequest.isCompleted) _nextRequest.complete(options);
    return ResponseBody.fromString('', 204);
  }

  @override
  void close({bool force = false}) {}
}

class _FakeMessagingPlatform implements PushMessagingPlatform {
  _FakeMessagingPlatform({
    this.permission = PushPermissionStatus.authorized,
    this.token,
    this.initialMessage,
  });

  final PushPermissionStatus permission;
  final String? token;
  final PushNotificationMessage? initialMessage;
  final tokenController = StreamController<String>.broadcast();
  final foregroundController =
      StreamController<PushNotificationMessage>.broadcast();
  final openedController =
      StreamController<PushNotificationMessage>.broadcast();

  @override
  Stream<PushNotificationMessage> get foregroundMessages =>
      foregroundController.stream;

  @override
  Future<PushNotificationMessage?> getInitialMessage() async => initialMessage;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> initialize() async {}

  @override
  Stream<PushNotificationMessage> get openedMessages => openedController.stream;

  @override
  Future<PushPermissionStatus> requestPermission() async => permission;

  @override
  Stream<String> get tokenRefreshes => tokenController.stream;
}

class _FakePresenter implements ForegroundNotificationPresenter {
  final messages = <PushNotificationMessage>[];
  late void Function(String route) open;

  @override
  Future<void> initialize(void Function(String route) onOpen) async {
    open = onOpen;
  }

  @override
  Future<void> show(PushNotificationMessage message) async {
    messages.add(message);
  }
}
