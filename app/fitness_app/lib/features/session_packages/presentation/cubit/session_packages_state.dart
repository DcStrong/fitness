import 'package:equatable/equatable.dart';

import '../../../invitations/data/invitation_models.dart';
import '../../data/session_package_models.dart';

enum SessionPackagesStatus { initial, loading, ready, failure }

enum StudentListFilter { all, paid, unpaid, waiting }

enum StudentPaymentCategory { paid, unpaid, waiting }

class StudentPackageRow extends Equatable {
  const StudentPackageRow({
    required this.student,
    this.package,
    this.category = StudentPaymentCategory.unpaid,
  });

  final RelationshipItem student;
  final SessionPackage? package;
  final StudentPaymentCategory category;

  @override
  List<Object?> get props => [student, package, category];
}

StudentPaymentCategory categorizeStudentRow({
  required SessionPackage? package,
  required bool hasPendingRequest,
}) {
  if (hasPendingRequest) return StudentPaymentCategory.waiting;
  if (package?.isActive == true) return StudentPaymentCategory.paid;
  return StudentPaymentCategory.unpaid;
}

class SessionPackagesState extends Equatable {
  const SessionPackagesState({
    this.status = SessionPackagesStatus.initial,
    this.rows = const [],
    this.filter = StudentListFilter.all,
    this.errorMessage,
    this.busy = false,
  });

  final SessionPackagesStatus status;
  final List<StudentPackageRow> rows;
  final StudentListFilter filter;
  final String? errorMessage;
  final bool busy;

  List<StudentPackageRow> get visibleRows {
    switch (filter) {
      case StudentListFilter.all:
        return rows;
      case StudentListFilter.paid:
        return rows
            .where((row) => row.category == StudentPaymentCategory.paid)
            .toList();
      case StudentListFilter.unpaid:
        return rows
            .where((row) => row.category == StudentPaymentCategory.unpaid)
            .toList();
      case StudentListFilter.waiting:
        return rows
            .where((row) => row.category == StudentPaymentCategory.waiting)
            .toList();
    }
  }

  SessionPackagesState copyWith({
    SessionPackagesStatus? status,
    List<StudentPackageRow>? rows,
    StudentListFilter? filter,
    Object? errorMessage = _sentinel,
    bool? busy,
  }) {
    return SessionPackagesState(
      status: status ?? this.status,
      rows: rows ?? this.rows,
      filter: filter ?? this.filter,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      busy: busy ?? this.busy,
    );
  }

  @override
  List<Object?> get props => [status, rows, filter, errorMessage, busy];
}

const _sentinel = Object();
