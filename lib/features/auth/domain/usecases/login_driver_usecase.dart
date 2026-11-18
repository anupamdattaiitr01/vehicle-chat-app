import '../entities/driver_entity.dart';
import '../repositories/auth_repository.dart';

class LoginDriverUseCase {
  final AuthRepository _repository;

  const LoginDriverUseCase(this._repository);

  Future<DriverEntity> call({
    required String phone,
    required String password,
  }) {
    return _repository.loginDriver(phone: phone, password: password);
  }
}