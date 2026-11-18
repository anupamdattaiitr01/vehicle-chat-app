import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final String? id;
  final String? roomId;
  final String senderId;
  final String content;
  final String? createdAt;

  const MessageEntity({
    this.id,
    this.roomId,
    required this.senderId,
    required this.content,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, roomId, senderId, content, createdAt];
}