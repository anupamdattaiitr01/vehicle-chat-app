import '../entities/chat_rooms_entity.dart';
import '../repositories/chat_repository.dart';

class GetMyRoomsUseCase {
  final ChatRepository _repository;

  const GetMyRoomsUseCase(this._repository);

  Future<ChatRoomsEntity> call() => _repository.getMyRooms();
}