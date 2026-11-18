import 'package:flutter/foundation.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/driver_entity.dart';
import '../../domain/entities/manager_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<DriverEntity?> restoreSession() {
    return localDataSource.getSession();
  }

  @override
  Future<DriverEntity> loginDriver({
    required String phone,
    required String password,
  }) async {
    try {
      final driver = await remoteDataSource.login(
        phone: phone,
        password: password,
      );
      await localDataSource.saveSession(driver);
      return driver;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        DioClient.extractErrorMessage(e, fallback: 'Login failed'),
      );
    }
  }

  @override
  Future<void> registerDriver({
    required String name,
    required String phone,
    required String password,
    required String managerId,
  }) async {
    try {
      await remoteDataSource.register(
        name: name,
        phone: phone,
        password: password,
        managerId: managerId,
      );
    } catch (e) {
      throw AuthException(
        DioClient.extractErrorMessage(e, fallback: 'Registration failed'),
      );
    }
  }

  @override
  Future<List<ManagerEntity>> getManagers() {
    return remoteDataSource.fetchManagers();
  }

  @override
  Future<void> syncFcmToken(String fcmToken) {
    return remoteDataSource.syncFcmToken(fcmToken);
  }

  @override
  Future<void> logoutDriver() async {
    try {
      await remoteDataSource.removeFcmToken();
    } catch (e) {
      debugPrint('Failed to clear FCM token on logout: $e');
    }
    await localDataSource.clearSession();
  }
}