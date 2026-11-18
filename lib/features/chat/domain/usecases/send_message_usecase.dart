import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository _repository;

  const SendMessageUseCase(this._repository);

  void call({
    required String roomId,
    required String senderId,
    required String content,
  }) {
    _repository.sendMessage(
      roomId: roomId,
      senderId: senderId,
      content: content,
    );
  }
}