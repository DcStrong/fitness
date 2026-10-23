import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/chat_models.dart';
import '../../data/chat_realtime.dart';
import '../../data/chats_repository.dart';

enum ChatThreadStatus { loading, ready, failure }

class ChatThreadState extends Equatable {
  const ChatThreadState({
    this.status = ChatThreadStatus.loading,
    this.conversation,
    this.messages = const [],
    this.hasOlder = false,
    this.loadingOlder = false,
    this.errorMessage,
  });

  final ChatThreadStatus status;
  final ChatConversation? conversation;

  /// Oldest first, as shown top to bottom.
  final List<ChatMessage> messages;
  final bool hasOlder;
  final bool loadingOlder;
  final String? errorMessage;

  ChatThreadState copyWith({
    ChatThreadStatus? status,
    ChatConversation? conversation,
    List<ChatMessage>? messages,
    bool? hasOlder,
    bool? loadingOlder,
    String? errorMessage,
    bool clearError = false,
  }) => ChatThreadState(
    status: status ?? this.status,
    conversation: conversation ?? this.conversation,
    messages: messages ?? this.messages,
    hasOlder: hasOlder ?? this.hasOlder,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [
    status,
    conversation,
    messages,
    hasOlder,
    loadingOlder,
    errorMessage,
  ];
}

/// One conversation: history, live messages from [ChatRealtime], optimistic
/// sends with retry, and the read marker.
class ChatThreadCubit extends Cubit<ChatThreadState> {
  ChatThreadCubit({
    required ChatsRepository repository,
    required ChatRealtime realtime,
    required this.myUserId,
    this.conversationId,
    this.counterpartId,
    String Function()? newClientId,
    this.readDebounce = const Duration(milliseconds: 400),
  }) : assert(conversationId != null || counterpartId != null),
       _repository = repository,
       _realtime = realtime,
       _newClientId = newClientId ?? _randomUuid,
       super(const ChatThreadState());

  final ChatsRepository _repository;
  final ChatRealtime _realtime;
  final String myUserId;
  final String? conversationId;

  /// Opens (or creates) the conversation with this user when no id is known.
  final String? counterpartId;
  final String Function() _newClientId;
  final Duration readDebounce;

  StreamSubscription<ChatMessage>? _messagesSub;
  StreamSubscription<void>? _connectedSub;
  Timer? _readTimer;
  String? _lastMarkedId;

  static const pageSize = 50;

  String? get _id => state.conversation?.id ?? conversationId;

  Future<void> load() async {
    emit(state.copyWith(status: ChatThreadStatus.loading, clearError: true));
    try {
      final conversation = conversationId != null
          ? await _repository.get(conversationId!)
          : await _repository.open(counterpartId!);
      final page = await _repository.messages(conversation.id, limit: pageSize);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ChatThreadStatus.ready,
          conversation: conversation,
          messages: page.items,
          hasOlder: page.hasMore,
        ),
      );
      _subscribe();
      _scheduleRead();
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ChatThreadStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }

  Future<void> loadOlder() async {
    final id = _id;
    final oldest = _firstServerMessage();
    if (id == null || oldest == null || !state.hasOlder || state.loadingOlder) {
      return;
    }
    emit(state.copyWith(loadingOlder: true));
    try {
      final page = await _repository.messages(
        id,
        before: oldest.id,
        limit: pageSize,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          messages: _merge(page.items, state.messages),
          hasOlder: page.hasMore,
          loadingOlder: false,
        ),
      );
    } on ApiException {
      if (isClosed) return;
      emit(state.copyWith(loadingOlder: false));
    }
  }

  Future<void> send(String text) async {
    final id = _id;
    final body = text.trim();
    if (id == null || body.isEmpty) return;
    final pending = ChatMessage.pending(
      clientId: _newClientId(),
      conversationId: id,
      senderId: myUserId,
      body: body,
    );
    emit(state.copyWith(messages: [...state.messages, pending]));
    await _deliver(pending);
  }

  /// Resends a failed bubble with the same client id, so the server dedupes.
  Future<void> retry(String clientId) async {
    final failed = state.messages.where(
      (m) => m.clientId == clientId && m.delivery == ChatDeliveryState.failed,
    );
    if (failed.isEmpty) return;
    final message = failed.first.copyWith(delivery: ChatDeliveryState.sending);
    emit(state.copyWith(messages: _replaceLocal(message)));
    await _deliver(message);
  }

  Future<void> _deliver(ChatMessage pending) async {
    try {
      final saved = await _repository.send(
        pending.conversationId,
        clientId: pending.clientId!,
        body: pending.body,
      );
      if (isClosed) return;
      emit(state.copyWith(messages: _merge(state.messages, [saved])));
    } on ApiException {
      if (isClosed) return;
      emit(
        state.copyWith(
          messages: _replaceLocal(
            pending.copyWith(delivery: ChatDeliveryState.failed),
          ),
        ),
      );
    }
  }

  void _subscribe() {
    _messagesSub ??= _realtime.messages.listen((message) {
      if (message.conversationId != _id || isClosed) return;
      emit(state.copyWith(messages: _merge(state.messages, [message])));
      if (message.senderId != myUserId) _scheduleRead();
    });
    _connectedSub ??= _realtime.connected.listen((_) => _catchUp());
  }

  /// Pulls what arrived while the socket was down.
  Future<void> _catchUp() async {
    final id = _id;
    final newest = _lastServerMessage();
    if (id == null || isClosed) return;
    try {
      final page = newest == null
          ? await _repository.messages(id, limit: pageSize)
          : await _repository.messages(id, after: newest.id, limit: 100);
      if (isClosed || page.items.isEmpty) return;
      emit(state.copyWith(messages: _merge(state.messages, page.items)));
      _scheduleRead();
    } on ApiException {
      // Next reconnect retries.
    }
  }

  void _scheduleRead() {
    _readTimer?.cancel();
    _readTimer = Timer(readDebounce, () => unawaited(_markRead()));
  }

  Future<void> _markRead() async {
    final id = _id;
    final last = _lastServerMessage();
    if (id == null || last == null || last.id == _lastMarkedId || isClosed) {
      return;
    }
    _lastMarkedId = last.id;
    try {
      await _repository.markRead(id, last.id);
    } on ApiException {
      _lastMarkedId = null;
    }
  }

  ChatMessage? _firstServerMessage() {
    for (final message in state.messages) {
      if (!message.isLocal) return message;
    }
    return null;
  }

  ChatMessage? _lastServerMessage() {
    for (final message in state.messages.reversed) {
      if (!message.isLocal) return message;
    }
    return null;
  }

  List<ChatMessage> _replaceLocal(ChatMessage message) => [
    for (final m in state.messages)
      if (m.isLocal && m.clientId == message.clientId) message else m,
  ];

  @override
  Future<void> close() async {
    _readTimer?.cancel();
    await _messagesSub?.cancel();
    await _connectedSub?.cancel();
    return super.close();
  }
}

/// Server messages win over local copies (matched by id or client id); local
/// bubbles stay after server messages in the order they were typed.
List<ChatMessage> _merge(List<ChatMessage> a, List<ChatMessage> b) {
  final server = <String, ChatMessage>{};
  final local = <ChatMessage>[];
  for (final message in [...a, ...b]) {
    if (message.isLocal) {
      local.add(message);
    } else {
      server[message.id] = message;
    }
  }
  final confirmed = server.values
      .map((m) => m.clientId)
      .whereType<String>()
      .toSet();
  final sorted = server.values.toList()
    ..sort((x, y) {
      final byTime = x.createdAt.compareTo(y.createdAt);
      return byTime != 0 ? byTime : x.id.compareTo(y.id);
    });
  return [...sorted, ...local.where((m) => !confirmed.contains(m.clientId))];
}

final _random = Random.secure();

String _randomUuid() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
