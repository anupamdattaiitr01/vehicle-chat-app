import '../repositories/chat_repository.dart';

class LeaveRoomUseCase {
  final ChatRepository _repository;

  const LeaveRoomUseCase(this._repository);

  void call({required String roomId, required String userId}) {
    _repository.leaveRoom(roomId: roomId, userId: userId);
  }
}