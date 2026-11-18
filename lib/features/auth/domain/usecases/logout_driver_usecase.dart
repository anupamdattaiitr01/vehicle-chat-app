import '../repositories/auth_repository.dart';

class LogoutDriverUseCase {
  final AuthRepository _repository;

  const LogoutDriverUseCase(this._repository);

  Future<void> call() => _repository.logoutDriver();
}