import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/chat_models.dart';
import '../../data/chat_realtime.dart';
import '../../data/chats_repository.dart';

enum ChatListStatus { loading, ready, failure }

class ChatListState extends Equatable {
  const ChatListState({
    this.status = ChatListStatus.loading,
    this.conversations = const [],
    this.query = '',
    this.errorMessage,
  });

  final ChatListStatus status;
  final List<ChatConversation> conversations;
  final String query;
  final String? errorMessage;

  ChatListState copyWith({
    ChatListStatus? status,
    List<ChatConversation>? conversations,
    String? query,
    String? errorMessage,
  }) => ChatListState(
    status: status ?? this.status,
    conversations: conversations ?? this.conversations,
    query: query ?? this.query,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [status, conversations, query, errorMessage];
}

/// Conversation list; any live event re-reads it (lists are short and the
/// server already orders them and counts unread).
class ChatListCubit extends Cubit<ChatListState> {
  ChatListCubit({
    required ChatsRepository repository,
    required ChatRealtime realtime,
    this.refreshDebounce = const Duration(milliseconds: 300),
  }) : _repository = repository,
       _realtime = realtime,
       super(const ChatListState());

  final ChatsRepository _repository;
  final ChatRealtime _realtime;
  final Duration refreshDebounce;

  final List<StreamSubscription<Object?>> _subs = [];
  Timer? _refresh;
  int _generation = 0;

  Future<void> load() async {
    if (_subs.isEmpty) {
      _subs
        ..add(_realtime.messages.listen((_) => _scheduleRefresh()))
        ..add(_realtime.reads.listen((_) => _scheduleRefresh()))
        ..add(_realtime.connected.listen((_) => _scheduleRefresh()));
    }
    await _fetch(showLoading: state.conversations.isEmpty);
  }

  Future<void> search(String query) async {
    if (query == state.query) return;
    emit(state.copyWith(query: query));
    await _fetch(showLoading: false);
  }

  void _scheduleRefresh() {
    _refresh?.cancel();
    _refresh = Timer(refreshDebounce, () => unawaited(_fetch()));
  }

  Future<void> _fetch({bool showLoading = false}) async {
    final generation = ++_generation;
    if (showLoading) emit(state.copyWith(status: ChatListStatus.loading));
    try {
      final items = await _repository.list(query: state.query);
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(status: ChatListStatus.ready, conversations: items));
    } on ApiException catch (error) {
      if (isClosed || generation != _generation) return;
      if (state.conversations.isEmpty) {
        emit(
          state.copyWith(
            status: ChatListStatus.failure,
            errorMessage: error.message,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    _refresh?.cancel();
    for (final sub in _subs) {
      await sub.cancel();
    }
    return super.close();
  }
}
