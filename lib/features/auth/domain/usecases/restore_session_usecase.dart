import '../entities/driver_entity.dart';
import '../repositories/auth_repository.dart';

class RestoreSessionUseCase {
  final AuthRepository _repository;

  const RestoreSessionUseCase(this._repository);

  Future<DriverEntity?> call() => _repository.restoreSession();
}