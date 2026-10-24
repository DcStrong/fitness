import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'plans_models.dart';

class PlansRepository {
  PlansRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<TagItem> createTag(String name) async {
    try {
      final response = await _dio.post<dynamic>('/tags', data: {'name': name});
      return TagItem.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<TagItem>> listTags() async {
    try {
      final response = await _dio.get<dynamic>('/tags');
      return _asList(response.data).map(TagItem.fromJson).toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<void> deleteTag(String id) async {
    try {
      await _dio.delete<dynamic>('/tags/$id');
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<TagAssignee> assignTag({
    required String tagId,
    required String userId,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/tags/$tagId/users',
        data: {'userId': userId},
      );
      return TagAssignee.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<void> unassignTag({
    required String tagId,
    required String userId,
  }) async {
    try {
      await _dio.delete<dynamic>('/tags/$tagId/users/$userId');
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<TagAssignee>> listAssignees(String tagId) async {
    try {
      final response = await _dio.get<dynamic>('/tags/$tagId/users');
      return _asList(response.data).map(TagAssignee.fromJson).toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<TagHub> getTagHub(String tagId) async {
    try {
      final response = await _dio.get<dynamic>('/tags/$tagId');
      return TagHub.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<ExerciseItem>> listExercises({String? tagId}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/exercises',
        queryParameters: {'tagId': ?tagId},
      );
      return _asList(response.data).map(ExerciseItem.fromJson).toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<ExerciseItem>> listVisibleExercises() async {
    try {
      final response = await _dio.get<dynamic>('/exercises/visible');
      return _asList(response.data).map(ExerciseItem.fromJson).toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<ExerciseItem> replaceExerciseTags({
    required String exerciseId,
    required List<String> tagIds,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        '/exercises/$exerciseId/tags',
        data: {'tagIds': tagIds},
      );
      return ExerciseItem.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<ExerciseItem>> assignExercises({
    required List<String> exerciseIds,
    List<String> studentIds = const [],
    List<String> tagIds = const [],
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/exercises/assign',
        data: {
          'exerciseIds': exerciseIds,
          if (studentIds.isNotEmpty) 'studentIds': studentIds,
          if (tagIds.isNotEmpty) 'tagIds': tagIds,
        },
      );
      return _asList(response.data).map(ExerciseItem.fromJson).toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<ExerciseItem> createExercise({
    required String name,
    required String kind,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/exercises',
        data: {'name': name, 'kind': kind},
      );
      return ExerciseItem.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<TrainingPlanItem> createPlan({
    required String title,
    String? notes,
    String? body,
    String goal = 'general',
    List<String> tagIds = const [],
    List<PlanExerciseItem> exercises = const [],
    String? assignedStudentId,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/plans',
        data: {
          'title': title,
          'goal': goal,
          'notes': notes ?? body ?? '',
          'tagIds': tagIds,
          'exercises': exercises.map((item) => item.toJson()).toList(),
          'assignedStudentId': ?assignedStudentId,
        },
      );
      return TrainingPlanItem.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<TrainingPlanItem>> listOwnPlans() async {
    try {
      final response = await _dio.get<dynamic>('/plans');
      return _asList(response.data).map(TrainingPlanItem.fromJson).toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<TrainingPlanItem>> listCatalogPlans() async {
    try {
      final response = await _dio.get<dynamic>(
        '/plans',
        queryParameters: {'kind': 'catalog'},
      );
      return _asList(response.data).map(TrainingPlanItem.fromJson).toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<TrainingPlanItem>> listVisiblePlans() async {
    try {
      final response = await _dio.get<dynamic>('/plans/visible');
      return _asList(response.data).map(TrainingPlanItem.fromJson).toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<TrainingPlanItem>> listAssignedPlans({String? studentId}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/plans',
        queryParameters: {'kind': 'assigned', 'studentId': ?studentId},
      );
      return _asList(response.data).map(TrainingPlanItem.fromJson).toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<TrainingPlanItem>> assignPlan({
    required String planId,
    List<String> studentIds = const [],
    List<String> tagIds = const [],
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/plans/$planId/assign',
        data: {
          if (studentIds.isNotEmpty) 'studentIds': studentIds,
          if (tagIds.isNotEmpty) 'tagIds': tagIds,
        },
      );
      return _asList(response.data).map(TrainingPlanItem.fromJson).toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<TrainingPlanItem>> assignPlansBatch({
    required String studentId,
    required List<String> planIds,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/plans/assign-batch',
        data: {'studentId': studentId, 'planIds': planIds},
      );
      return _asList(response.data).map(TrainingPlanItem.fromJson).toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<TrainingPlanItem> getPlan(String id) async {
    try {
      final response = await _dio.get<dynamic>('/plans/$id');
      return TrainingPlanItem.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<TrainingPlanItem> clonePlan(String id) async {
    try {
      final response = await _dio.post<dynamic>('/plans/$id/clone');
      return TrainingPlanItem.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<TrainingPlanItem> updatePlan({
    required String id,
    String? title,
    String? notes,
    String? body,
    String? goal,
    List<String>? tagIds,
    List<PlanExerciseItem>? exercises,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (notes != null || body != null) data['notes'] = notes ?? body;
      if (goal != null) data['goal'] = goal;
      if (tagIds != null) data['tagIds'] = tagIds;
      if (exercises != null) {
        data['exercises'] = exercises.map((item) => item.toJson()).toList();
      }
      final response = await _dio.patch<dynamic>('/plans/$id', data: data);
      return TrainingPlanItem.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<TrainingPlanItem> updatePlanLoads({
    required String id,
    required List<({String exerciseId, double weightKg})> items,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
        '/plans/$id/loads',
        data: {
          'items': [
            for (final item in items)
              {'exerciseId': item.exerciseId, 'weightKg': item.weightKg},
          ],
        },
      );
      return TrainingPlanItem.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<void> deletePlan(String id) async {
    try {
      await _dio.delete<dynamic>('/plans/$id');
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Неверный ответ сервера');
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  ApiException _map(DioException error) {
    final data = error.response?.data;
    var message = 'Ошибка сети';
    if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    } else if (data is Map && data['message'] is List) {
      message = (data['message'] as List).join(', ');
    }
    final lower = message.toLowerCase();
    if (lower.contains('title is required') ||
        lower.contains('name is required')) {
      message = 'Укажите название';
    } else if (lower.contains('already exists')) {
      message = message.toLowerCase().contains('exercise')
          ? 'Такое упражнение уже есть'
          : 'Такой тег уже есть';
    } else if (lower.contains('catalog')) {
      message = 'Каталог нельзя изменять';
    } else if (lower.contains('referenced')) {
      message = 'Упражнение используется в плане';
    } else if (lower.contains('not linked')) {
      message = 'Нет связи тренер ↔ ученик';
    } else if (lower.contains('foreign') || lower.contains('invalid')) {
      message = 'Некорректные теги или упражнения';
    } else if (lower.contains('not visible')) {
      message = 'План недоступен';
    }
    return ApiException(message, statusCode: error.response?.statusCode);
  }
}
