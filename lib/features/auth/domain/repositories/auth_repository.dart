import '../entities/driver_entity.dart';
import '../entities/manager_entity.dart';

abstract class AuthRepository {
  Future<DriverEntity?> restoreSession();

  Future<DriverEntity> loginDriver({
    required String phone,
    required String password,
  });

  Future<void> registerDriver({
    required String name,
    required String phone,
    required String password,
    required String managerId,
  });

  Future<List<ManagerEntity>> getManagers();

  Future<void> syncFcmToken(String fcmToken);

  Future<void> logoutDriver();
}