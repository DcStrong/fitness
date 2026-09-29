import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'progress_models.dart';

class ProgressRepository {
  ProgressRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<ProgressExerciseSummary>> listExercises({
    required String studentId,
    String? coachId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/students/$studentId/progress',
        queryParameters: {
          if (coachId != null && coachId.isNotEmpty) 'coachId': coachId,
        },
      );
      final data = response.data;
      if (data is Map && data['exercises'] is List) {
        return (data['exercises'] as List)
            .whereType<Map>()
            .map(
              (item) => ProgressExerciseSummary.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
      return const [];
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<ProgressSeries> getSeries({
    required String studentId,
    required String exerciseId,
    String? coachId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/students/$studentId/progress',
        queryParameters: {
          'exerciseId': exerciseId,
          if (coachId != null && coachId.isNotEmpty) 'coachId': coachId,
        },
      );
      final data = response.data;
      if (data is Map) {
        return ProgressSeries.fromJson(Map<String, dynamic>.from(data));
      }
      throw ApiException('Неверный ответ сервера');
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  ApiException _map(DioException error) {
    final data = error.response?.data;
    var message = 'Не удалось загрузить прогресс';
    if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    }
    return ApiException(message, statusCode: error.response?.statusCode);
  }
}
