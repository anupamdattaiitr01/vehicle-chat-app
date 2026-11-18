import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/driver_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveSession(DriverModel driver);
  Future<DriverModel?> getSession();
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _secureStorage;

  const AuthLocalDataSourceImpl(this._secureStorage);

  @override
  Future<void> saveSession(DriverModel driver) async {
    await _secureStorage.write(
      key: AppConstants.jwtTokenKey,
      value: driver.token,
    );
    await _secureStorage.write(
      key: AppConstants.driverIdKey,
      value: driver.id,
    );
    await _secureStorage.write(
      key: AppConstants.driverNameKey,
      value: driver.name,
    );
  }

  @override
  Future<DriverModel?> getSession() async {
    final token = await _secureStorage.read(key: AppConstants.jwtTokenKey);
    final driverId = await _secureStorage.read(key: AppConstants.driverIdKey);
    final driverName =
    await _secureStorage.read(key: AppConstants.driverNameKey);

    if (token != null &&
        token.isNotEmpty &&
        driverId != null &&
        driverId.isNotEmpty &&
        driverName != null &&
        driverName.isNotEmpty) {
      return DriverModel(
        id: driverId,
        name: driverName,
        token: token,
      );
    }
    return null;
  }

  @override
  Future<void> clearSession() async {
    await _secureStorage.deleteAll();
  }
}