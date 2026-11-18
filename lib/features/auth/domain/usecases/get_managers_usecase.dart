import '../entities/manager_entity.dart';
import '../repositories/auth_repository.dart';

class GetManagersUseCase {
  final AuthRepository _repository;

  const GetManagersUseCase(this._repository);

  Future<List<ManagerEntity>> call() => _repository.getManagers();
}