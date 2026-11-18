import 'dart:convert';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/crypto_helper.dart';
import '../models/driver_model.dart';
import '../models/manager_model.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

abstract class AuthRemoteDataSource {
  Future<DriverModel> login({
    required String phone,
    required String password,
  });

  Future<void> register({
    required String name,
    required String phone,
    required String password,
    required String managerId,
  });

  Future<List<ManagerModel>> fetchManagers();

  Future<void> syncFcmToken(String fcmToken);

  Future<void> removeFcmToken();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _dioClient;

  const AuthRemoteDataSourceImpl(this._dioClient);

  @override
  Future<DriverModel> login({
    required String phone,
    required String password,
  }) async {
    final rawPayload = json.encode({
      'phone': phone.trim(),
      'password': password.trim(),
    });
    final encryptedPayload = CryptoHelper.encryptPayload(rawPayload);

    final response = await _dioClient.dio.post(
      ApiEndpoints.login,
      data: {'data': encryptedPayload},
    );

    final data = response.data as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>?;

    if (user == null || user['role'] != 'driver') {
      throw const AuthException('Access denied: This app is for Drivers only.');
    }

    return DriverModel.fromLoginJson(data);
  }

  @override
  Future<void> register({
    required String name,
    required String phone,
    required String password,
    required String managerId,
  }) async {
    final rawPayload = json.encode({
      'name': name.trim(),
      'phone': phone.trim(),
      'password': password.trim(),
      'role': 'driver',
      'managerId': managerId,
    });
    final encryptedPayload = CryptoHelper.encryptPayload(rawPayload);

    await _dioClient.dio.post(
      ApiEndpoints.register,
      data: {'data': encryptedPayload},
    );
  }

  @override
  Future<List<ManagerModel>> fetchManagers() async {
    final response = await _dioClient.dio.get(ApiEndpoints.managers);
    final list = response.data as List<dynamic>;
    return list
        .map((item) => ManagerModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> syncFcmToken(String fcmToken) async {
    await _dioClient.dio.post(
      ApiEndpoints.fcmToken,
      data: {'fcmToken': fcmToken},
    );
  }

  @override
  Future<void> removeFcmToken() async {
    await _dioClient.dio.delete(ApiEndpoints.fcmToken);
  }
}