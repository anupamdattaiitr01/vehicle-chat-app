import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class DioClient {
  late final Dio dio;
  final FlutterSecureStorage _secureStorage;

  DioClient(this._secureStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!options.headers.containsKey('Authorization')) {
            final token =
            await _secureStorage.read(key: AppConstants.jwtTokenKey);
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (DioException error, handler) {
          debugPrint(
            '[Dio Error] ${error.requestOptions.method} ${error.requestOptions.path} '
                '-> ${error.response?.statusCode}: ${error.message}',
          );
          handler.next(error);
        },
      ),
    );
  }

  static String extractErrorMessage(
      dynamic error, {
        String fallback = 'Something went wrong. Please try again.',
      }) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic> &&
          responseData['error'] != null) {
        return responseData['error'].toString();
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Network error. Is the backend running?';
      }
    }
    return fallback;
  }
}