import 'package:equatable/equatable.dart';

enum ChatMessageKind { text, system }

/// Server `systemType`; [unknown] keeps older apps safe when the API adds types.
enum ChatSystemType {
  sessionBooked('session_booked'),
  sessionCancelled('session_cancelled'),
  sessionRescheduled('session_rescheduled'),
  occurrenceSkipped('occurrence_skipped'),
  requestAccepted('request_accepted'),
  requestAlternate('request_alternate'),
  requestRejected('request_rejected'),
  unknown('');

  const ChatSystemType(this.wireValue);

  final String wireValue;

  static ChatSystemType? parse(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return ChatSystemType.values.firstWhere(
      (type) => type.wireValue == raw,
      orElse: () => ChatSystemType.unknown,
    );
  }
}

/// Local delivery state of an own message; server messages are [sent].
enum ChatDeliveryState { sending, failed, sent }

class ChatSystemPayload extends Equatable {
  const ChatSystemPayload({
    this.sessionId,
    this.bookingRequestId,
    this.startsAt,
    this.endsAt,
    this.previousStartsAt,
    this.localDate,
    this.note,
  });

  factory ChatSystemPayload.fromJson(Map<String, dynamic> json) =>
      ChatSystemPayload(
        sessionId: json['sessionId'] as String?,
        bookingRequestId: json['bookingRequestId'] as String?,
        startsAt: _date(json['startsAt']),
        endsAt: _date(json['endsAt']),
        previousStartsAt: _date(json['previousStartsAt']),
        localDate: json['localDate'] as String?,
        note: json['note'] as String?,
      );

  final String? sessionId;
  final String? bookingRequestId;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? previousStartsAt;
  final String? localDate;
  final String? note;

  @override
  List<Object?> get props => [
    sessionId,
    bookingRequestId,
    startsAt,
    endsAt,
    previousStartsAt,
    localDate,
    note,
  ];
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.kind,
    required this.body,
    required this.createdAt,
    this.systemType,
    this.payload,
    this.clientId,
    this.delivery = ChatDeliveryState.sent,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String?,
      kind: json['kind'] == 'system'
          ? ChatMessageKind.system
          : ChatMessageKind.text,
      body: json['body'] as String? ?? '',
      systemType: ChatSystemType.parse(json['systemType']),
      payload: payload is Map
          ? ChatSystemPayload.fromJson(Map<String, dynamic>.from(payload))
          : null,
      clientId: json['clientId'] as String?,
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
    );
  }

  /// Optimistic bubble shown before the server confirms the send.
  factory ChatMessage.pending({
    required String clientId,
    required String conversationId,
    required String senderId,
    required String body,
  }) => ChatMessage(
    id: 'local-$clientId',
    conversationId: conversationId,
    senderId: senderId,
    kind: ChatMessageKind.text,
    body: body,
    createdAt: DateTime.now(),
    clientId: clientId,
    delivery: ChatDeliveryState.sending,
  );

  final String id;
  final String conversationId;
  final String? senderId;
  final ChatMessageKind kind;
  final String body;
  final ChatSystemType? systemType;
  final ChatSystemPayload? payload;
  final String? clientId;
  final DateTime createdAt;
  final ChatDeliveryState delivery;

  bool get isSystem => kind == ChatMessageKind.system;
  bool get isLocal => id.startsWith('local-');

  ChatMessage copyWith({ChatDeliveryState? delivery}) => ChatMessage(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    kind: kind,
    body: body,
    systemType: systemType,
    payload: payload,
    clientId: clientId,
    createdAt: createdAt,
    delivery: delivery ?? this.delivery,
  );

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    kind,
    body,
    systemType,
    payload,
    clientId,
    createdAt,
    delivery,
  ];
}

class ChatCounterpart extends Equatable {
  const ChatCounterpart({required this.id, this.email, this.displayName});

  factory ChatCounterpart.fromJson(Map<String, dynamic> json) =>
      ChatCounterpart(
        id: json['id'] as String,
        email: json['email'] as String?,
        displayName: json['displayName'] as String?,
      );

  final String id;
  final String? email;
  final String? displayName;

  @override
  List<Object?> get props => [id, email, displayName];
}

class ChatConversation extends Equatable {
  const ChatConversation({
    required this.id,
    required this.coachId,
    required this.studentId,
    required this.isCoach,
    required this.counterpart,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final last = json['lastMessage'];
    return ChatConversation(
      id: json['id'] as String,
      coachId: json['coachId'] as String,
      studentId: json['studentId'] as String,
      isCoach: json['myRole'] == 'coach',
      counterpart: ChatCounterpart.fromJson(
        Map<String, dynamic>.from(json['counterpart'] as Map),
      ),
      lastMessage: last is Map
          ? ChatMessage.fromJson(Map<String, dynamic>.from(last))
          : null,
      lastMessageAt: _date(json['lastMessageAt']),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String coachId;
  final String studentId;
  final bool isCoach;
  final ChatCounterpart counterpart;
  final ChatMessage? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ChatConversation copyWith({
    ChatMessage? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) => ChatConversation(
    id: id,
    coachId: coachId,
    studentId: studentId,
    isCoach: isCoach,
    counterpart: counterpart,
    lastMessage: lastMessage ?? this.lastMessage,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    unreadCount: unreadCount ?? this.unreadCount,
  );

  @override
  List<Object?> get props => [
    id,
    coachId,
    studentId,
    isCoach,
    counterpart,
    lastMessage,
    lastMessageAt,
    unreadCount,
  ];
}

class ChatMessagesPage extends Equatable {
  const ChatMessagesPage({required this.items, required this.hasMore});

  factory ChatMessagesPage.fromJson(Map<String, dynamic> json) =>
      ChatMessagesPage(
        items: (json['items'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        hasMore: json['hasMore'] == true,
      );

  final List<ChatMessage> items;
  final bool hasMore;

  @override
  List<Object?> get props => [items, hasMore];
}

/// `conversation.read` socket event.
class ChatReadEvent extends Equatable {
  const ChatReadEvent({
    required this.conversationId,
    required this.readerId,
    required this.lastReadAt,
  });

  factory ChatReadEvent.fromJson(Map<String, dynamic> json) => ChatReadEvent(
    conversationId: json['conversationId'] as String,
    readerId: json['readerId'] as String,
    lastReadAt: _date(json['lastReadAt']) ?? DateTime.now(),
  );

  final String conversationId;
  final String readerId;
  final DateTime lastReadAt;

  @override
  List<Object?> get props => [conversationId, readerId, lastReadAt];
}

DateTime? _date(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
