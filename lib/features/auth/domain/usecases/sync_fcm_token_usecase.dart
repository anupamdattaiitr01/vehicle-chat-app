import '../repositories/auth_repository.dart';

class SyncFcmTokenUseCase {
  final AuthRepository _repository;

  const SyncFcmTokenUseCase(this._repository);

  Future<void> call(String fcmToken) => _repository.syncFcmToken(fcmToken);
}