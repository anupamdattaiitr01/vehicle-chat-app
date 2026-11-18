import '../repositories/chat_repository.dart';

class JoinRoomUseCase {
  final ChatRepository _repository;

  const JoinRoomUseCase(this._repository);

  void call({required String roomId, required String userId}) {
    _repository.joinRoom(roomId: roomId, userId: userId);
  }
}