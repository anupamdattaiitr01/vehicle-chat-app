import '../../domain/entities/chat_rooms_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../datasources/chat_socket_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final ChatSocketDataSource socketDataSource;

  const ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.socketDataSource,
  });

  @override
  Future<ChatRoomsEntity> getMyRooms() => remoteDataSource.fetchMyRooms();

  @override
  Future<List<MessageEntity>> getMessageHistory(String roomId) {
    return remoteDataSource.fetchMessageHistory(roomId);
  }

  @override
  void connectSocket(String token) => socketDataSource.connect(token);

  @override
  void reconnectSocketIfNeeded() => socketDataSource.reconnectIfDisconnected();

  @override
  void disconnectSocket() => socketDataSource.disconnect();

  @override
  bool get isSocketConnected => socketDataSource.isConnected;

  @override
  Stream<bool> get connectionStream => socketDataSource.connectionStream;

  @override
  Stream<MessageEntity> get messageStream => socketDataSource.messageStream;

  @override
  Stream<bool> get typingStream => socketDataSource.typingStream;

  @override
  void joinRoom({required String roomId, required String userId}) {
    socketDataSource.emitJoinRoom(roomId: roomId, userId: userId);
  }

  @override
  void leaveRoom({required String roomId, required String userId}) {
    socketDataSource.emitLeaveRoom(roomId: roomId, userId: userId);
  }

  @override
  void sendMessage({
    required String roomId,
    required String senderId,
    required String content,
  }) {
    socketDataSource.emitSendMessage(
      roomId: roomId,
      senderId: senderId,
      content: content,
    );
  }

  @override
  void sendTyping({required String roomId, required String userName}) {
    socketDataSource.emitTyping(roomId: roomId, userName: userName);
  }

  @override
  void sendStopTyping({required String roomId}) {
    socketDataSource.emitStopTyping(roomId: roomId);
  }
}