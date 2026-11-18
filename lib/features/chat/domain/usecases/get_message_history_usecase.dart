import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

class GetMessageHistoryUseCase {
  final ChatRepository _repository;

  const GetMessageHistoryUseCase(this._repository);

  Future<List<MessageEntity>> call(String roomId) {
    return _repository.getMessageHistory(roomId);
  }
}