import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/booking_request_models.dart';
import '../../data/booking_requests_repository.dart';

enum StudentRequestsStatus {
  initial,
  loading,
  empty,
  success,
  failure,
  submitting,
  conflict,
}

class StudentRequestsState extends Equatable {
  const StudentRequestsState({
    this.status = StudentRequestsStatus.initial,
    this.items = const [],
    this.message,
  });

  final StudentRequestsStatus status;
  final List<BookingRequest> items;
  final String? message;

  @override
  List<Object?> get props => [status, items, message];
}

class StudentRequestsCubit extends Cubit<StudentRequestsState> {
  StudentRequestsCubit({
    required BookingRequestsRepository repository,
    List<BookingRequest> initialItems = const [],
  }) : _repository = repository,
       super(
         StudentRequestsState(
           status: initialItems.isEmpty
               ? StudentRequestsStatus.initial
               : StudentRequestsStatus.success,
           items: initialItems,
         ),
       );

  final BookingRequestsRepository _repository;

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) {
      emit(
        StudentRequestsState(
          status: StudentRequestsStatus.loading,
          items: state.items,
        ),
      );
    }
    try {
      final page = await _repository.listMine();
      emit(
        StudentRequestsState(
          status: page.items.isEmpty
              ? StudentRequestsStatus.empty
              : StudentRequestsStatus.success,
          items: page.items,
        ),
      );
    } catch (error) {
      emit(
        StudentRequestsState(
          status: StudentRequestsStatus.failure,
          items: state.items,
          message: error.toString(),
        ),
      );
    }
  }

  Future<bool> create(String scheduleSlotId) async {
    emit(
      StudentRequestsState(
        status: StudentRequestsStatus.submitting,
        items: state.items,
      ),
    );
    try {
      final request = await _repository.create(scheduleSlotId);
      emit(
        StudentRequestsState(
          status: StudentRequestsStatus.success,
          items: [
            request,
            ...state.items.where((item) => item.id != request.id),
          ],
          message: 'Заявка отправлена. Ожидайте подтверждения тренера.',
        ),
      );
      return true;
    } catch (error) {
      final message = error.toString();
      emit(
        StudentRequestsState(
          status: _isConflict(message)
              ? StudentRequestsStatus.conflict
              : StudentRequestsStatus.failure,
          items: state.items,
          message: message,
        ),
      );
      return false;
    }
  }

  Future<bool> withdraw(String id) async {
    emit(
      StudentRequestsState(
        status: StudentRequestsStatus.submitting,
        items: state.items,
      ),
    );
    try {
      final updated = await _repository.withdraw(id);
      emit(
        StudentRequestsState(
          status: StudentRequestsStatus.success,
          items: [
            for (final item in state.items) item.id == id ? updated : item,
          ],
          message: 'Заявка отозвана',
        ),
      );
      return true;
    } catch (error) {
      emit(
        StudentRequestsState(
          status: StudentRequestsStatus.failure,
          items: state.items,
          message: error.toString(),
        ),
      );
      return false;
    }
  }

  Future<void> refresh() => load(showLoading: false);

  bool _isConflict(String message) =>
      message.contains('уже') ||
      message.contains('занято') ||
      message.contains('истекло') ||
      message.contains('2 часа');
}
