import '../../../../core/services/socket_service.dart';
import '../models/message_model.dart';

abstract class ChatSocketDataSource {
  void connect(String token);
  void reconnectIfDisconnected();
  void disconnect();
  bool get isConnected;
  Stream<bool> get connectionStream;
  Stream<MessageModel> get messageStream;
  Stream<bool> get typingStream;
  void emitJoinRoom({required String roomId, required String userId});
  void emitLeaveRoom({required String roomId, required String userId});
  void emitSendMessage({
    required String roomId,
    required String senderId,
    required String content,
  });
  void emitTyping({required String roomId, required String userName});
  void emitStopTyping({required String roomId});
}

class ChatSocketDataSourceImpl implements ChatSocketDataSource {
  final SocketService _socketService;

  const ChatSocketDataSourceImpl(this._socketService);

  @override
  void connect(String token) => _socketService.connect(token);

  @override
  void reconnectIfDisconnected() => _socketService.reconnectIfDisconnected();

  @override
  void disconnect() => _socketService.disconnect();

  @override
  bool get isConnected => _socketService.isConnected;

  @override
  Stream<bool> get connectionStream => _socketService.connectionStream;

  @override
  Stream<MessageModel> get messageStream =>
      _socketService.messageStream.map(MessageModel.fromJson);

  @override
  Stream<bool> get typingStream => _socketService.typingStream
      .map((data) => (data['isTyping'] as bool?) ?? false);

  @override
  void emitJoinRoom({required String roomId, required String userId}) {
    _socketService.emit('join_room', {'roomId': roomId, 'userId': userId});
  }

  @override
  void emitLeaveRoom({required String roomId, required String userId}) {
    _socketService.emit('leave_room', {'roomId': roomId, 'userId': userId});
  }

  @override
  void emitSendMessage({
    required String roomId,
    required String senderId,
    required String content,
  }) {
    _socketService.emit('send_message', {
      'roomId': roomId,
      'senderId': senderId,
      'content': content,
    });
  }

  @override
  void emitTyping({required String roomId, required String userName}) {
    _socketService.emit('typing', {'roomId': roomId, 'userName': userName});
  }

  @override
  void emitStopTyping({required String roomId}) {
    _socketService.emit('stop_typing', {'roomId': roomId});
  }
}