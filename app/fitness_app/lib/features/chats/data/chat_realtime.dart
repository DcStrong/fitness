import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/config/api_config.dart';
import '../../../core/network/token_storage.dart';
import 'chat_models.dart';

/// Server → app chat events. Writes go through [ChatsRepository]; the socket
/// only delivers what the server stored. After every (re)connect the app
/// catches up over REST, so a missed event is never lost.
abstract class ChatRealtime {
  Stream<ChatMessage> get messages;
  Stream<ChatReadEvent> get reads;

  /// Fires after each successful (re)connect; listeners refetch what they show.
  Stream<void> get connected;

  void start();
  void stop();
}

/// socket.io client for the `/chat` namespace.
class SocketChatRealtime implements ChatRealtime {
  SocketChatRealtime({
    required TokenStorage tokenStorage,
    required Future<void> Function() refreshSession,
    String? baseUrl,
  }) : _tokenStorage = tokenStorage,
       _refreshSession = refreshSession,
       _baseUrl = baseUrl ?? kApiBaseUrl;

  final TokenStorage _tokenStorage;

  /// Any authenticated REST call: the auth interceptor refreshes an expired
  /// access token on 401, which the socket handshake cannot do by itself.
  final Future<void> Function() _refreshSession;
  final String _baseUrl;

  final _messages = StreamController<ChatMessage>.broadcast();
  final _reads = StreamController<ChatReadEvent>.broadcast();
  final _connected = StreamController<void>.broadcast();

  io.Socket? _socket;
  Timer? _retry;
  Duration _retryDelay = _minRetry;
  bool _running = false;

  static const _minRetry = Duration(seconds: 2);
  static const _maxRetry = Duration(seconds: 60);

  @override
  Stream<ChatMessage> get messages => _messages.stream;

  @override
  Stream<ChatReadEvent> get reads => _reads.stream;

  @override
  Stream<void> get connected => _connected.stream;

  @override
  void start() {
    if (_running) return;
    _running = true;
    final socket = io.io(
      '$_baseUrl/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setAuthFn((callback) {
            unawaited(
              _tokenStorage.readAccessToken().then(
                (token) => callback({'token': token ?? ''}),
              ),
            );
          })
          .build(),
    );
    socket
      ..onConnect((_) {
        _retryDelay = _minRetry;
        _connected.add(null);
      })
      ..onDisconnect((reason) {
        // The server drops the socket on a missing or expired token; client
        // reconnection does not cover that, so refresh and dial again.
        if (reason == 'io server disconnect') _scheduleRedial();
      })
      ..on('message.created', (data) {
        if (data is Map) {
          _messages.add(ChatMessage.fromJson(Map<String, dynamic>.from(data)));
        }
      })
      ..on('conversation.read', (data) {
        if (data is Map) {
          _reads.add(ChatReadEvent.fromJson(Map<String, dynamic>.from(data)));
        }
      });
    _socket = socket;
    socket.connect();
  }

  @override
  void stop() {
    _running = false;
    _retry?.cancel();
    _retry = null;
    _socket
      ?..clearListeners()
      ..dispose();
    _socket = null;
  }

  void _scheduleRedial() {
    if (!_running) return;
    _retry?.cancel();
    final delay = _retryDelay;
    _retryDelay = delay * 2 > _maxRetry ? _maxRetry : delay * 2;
    _retry = Timer(delay, () async {
      if (!_running) return;
      try {
        await _refreshSession();
      } catch (_) {
        // Offline or logged out: the next redial tries again.
      }
      if (_running) _socket?.connect();
    });
  }
}
