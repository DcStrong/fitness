import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/booking_request_models.dart';
import '../../data/booking_requests_repository.dart';

enum TrainerInboxStatus {
  initial,
  loading,
  empty,
  success,
  failure,
  submitting,
}

class TrainerInboxState extends Equatable {
  const TrainerInboxState({
    this.status = TrainerInboxStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasNext = false,
    this.message,
    this.processingId,
  });

  final TrainerInboxStatus status;
  final List<BookingRequest> items;
  final int page;
  final bool hasNext;
  final String? message;
  final String? processingId;

  @override
  List<Object?> get props => [
    status,
    items,
    page,
    hasNext,
    message,
    processingId,
  ];
}

class TrainerInboxCubit extends Cubit<TrainerInboxState> {
  TrainerInboxCubit({
    required BookingRequestsRepository repository,
    List<BookingRequest> initialItems = const [],
  }) : _repository = repository,
       super(
         TrainerInboxState(
           status: initialItems.isEmpty
               ? TrainerInboxStatus.initial
               : TrainerInboxStatus.success,
           items: initialItems,
         ),
       );

  final BookingRequestsRepository _repository;

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) {
      emit(const TrainerInboxState(status: TrainerInboxStatus.loading));
    }
    try {
      final page = await _repository.inbox();
      _emitPage(page);
    } catch (error) {
      emit(
        TrainerInboxState(
          status: TrainerInboxStatus.failure,
          items: state.items,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasNext || state.status == TrainerInboxStatus.loading) return;
    try {
      final page = await _repository.inbox(page: state.page + 1);
      _emitPage(page, previous: state.items);
    } catch (error) {
      emit(
        TrainerInboxState(
          status: TrainerInboxStatus.failure,
          items: state.items,
          page: state.page,
          hasNext: state.hasNext,
          message: error.toString(),
        ),
      );
    }
  }

  Future<bool> accept(String id) =>
      _mutate(id, () => _repository.accept(id), 'Заявка принята');

  Future<bool> reject(
    String id, {
    required BookingRequestRejectionReason reason,
    String? comment,
  }) => _mutate(
    id,
    () => _repository.reject(id, reason: reason, comment: comment),
    'Заявка отклонена',
  );

  Future<bool> alternate(String id, DateTime startsAt) => _mutate(
    id,
    () => _repository.alternate(id, startsAt),
    'Другое время назначено',
  );

  Future<bool> _mutate(
    String id,
    Future<BookingRequest> Function() action,
    String successMessage,
  ) async {
    if (state.processingId != null) return false;
    emit(
      TrainerInboxState(
        status: TrainerInboxStatus.submitting,
        items: state.items,
        page: state.page,
        hasNext: state.hasNext,
        processingId: id,
      ),
    );
    try {
      final updated = await action();
      emit(
        TrainerInboxState(
          status: TrainerInboxStatus.success,
          items: [
            for (final item in state.items) item.id == id ? updated : item,
          ],
          page: state.page,
          hasNext: state.hasNext,
          message: successMessage,
        ),
      );
      return true;
    } catch (error) {
      emit(
        TrainerInboxState(
          status: TrainerInboxStatus.failure,
          items: state.items,
          page: state.page,
          hasNext: state.hasNext,
          message: error.toString(),
        ),
      );
      return false;
    }
  }

  Future<void> refresh() => load(showLoading: false);

  void _emitPage(
    BookingRequestPage page, {
    List<BookingRequest> previous = const [],
  }) {
    final items = [...previous, ...page.items];
    emit(
      TrainerInboxState(
        status: items.isEmpty
            ? TrainerInboxStatus.empty
            : TrainerInboxStatus.success,
        items: items,
        page: page.page,
        hasNext: page.hasNext,
      ),
    );
  }
}
