import '../entities/driver_entity.dart';

abstract class AuthRepository {
  Future<DriverEntity?> restoreSession();

  Future<DriverEntity> loginDriver({
    required String phone,
    required String password,
  });

  Future<void> syncFcmToken(String fcmToken);

  Future<void> logoutDriver();
}