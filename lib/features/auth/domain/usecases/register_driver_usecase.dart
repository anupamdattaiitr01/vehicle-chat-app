import '../repositories/auth_repository.dart';

class RegisterDriverUseCase {
  final AuthRepository _repository;

  const RegisterDriverUseCase(this._repository);

  Future<void> call({
    required String name,
    required String phone,
    required String password,
    required String managerId,
  }) {
    return _repository.registerDriver(
      name: name,
      phone: phone,
      password: password,
      managerId: managerId,
    );
  }
}