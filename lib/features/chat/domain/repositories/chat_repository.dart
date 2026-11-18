import '../entities/chat_rooms_entity.dart';
import '../entities/message_entity.dart';

abstract class ChatRepository {
  Future<ChatRoomsEntity> getMyRooms();

  Future<List<MessageEntity>> getMessageHistory(String roomId);

  void connectSocket(String token);

  void reconnectSocketIfNeeded();

  void disconnectSocket();

  bool get isSocketConnected;

  Stream<bool> get connectionStream;

  Stream<MessageEntity> get messageStream;

  Stream<bool> get typingStream;

  void joinRoom({required String roomId, required String userId});

  void leaveRoom({required String roomId, required String userId});

  void sendMessage({
    required String roomId,
    required String senderId,
    required String content,
  });

  void sendTyping({required String roomId, required String userName});

  void sendStopTyping({required String roomId});
}