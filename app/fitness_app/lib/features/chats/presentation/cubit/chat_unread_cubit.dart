import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/chat_realtime.dart';
import '../../data/chats_repository.dart';

/// Total unread for the bottom-navigation badge. Lives for the whole signed-in
/// session and starts / stops the shared socket with it.
class ChatUnreadCubit extends Cubit<int> {
  ChatUnreadCubit({
    required ChatsRepository repository,
    required ChatRealtime realtime,
    this.refreshDebounce = const Duration(milliseconds: 300),
  }) : _repository = repository,
       _realtime = realtime,
       super(0);

  final ChatsRepository _repository;
  final ChatRealtime _realtime;
  final Duration refreshDebounce;

  final List<StreamSubscription<Object?>> _subs = [];
  Timer? _refresh;
  bool _active = false;

  void start() {
    if (_active) return;
    _active = true;
    _subs
      ..add(_realtime.messages.listen((_) => _scheduleRefresh()))
      ..add(_realtime.reads.listen((_) => _scheduleRefresh()))
      ..add(_realtime.connected.listen((_) => _scheduleRefresh()));
    _realtime.start();
    unawaited(refresh());
  }

  Future<void> stop() async {
    if (!_active) return;
    _active = false;
    _refresh?.cancel();
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    _realtime.stop();
    if (!isClosed) emit(0);
  }

  Future<void> refresh() async {
    try {
      final total = await _repository.unreadCount();
      if (!isClosed && _active) emit(total);
    } on ApiException {
      // Badge keeps its last value; the next event or reconnect retries.
    }
  }

  void _scheduleRefresh() {
    _refresh?.cancel();
    _refresh = Timer(refreshDebounce, () => unawaited(refresh()));
  }

  @override
  Future<void> close() async {
    await stop();
    return super.close();
  }
}
