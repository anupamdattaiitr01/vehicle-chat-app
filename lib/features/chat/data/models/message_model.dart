import '../../domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    super.id,
    super.roomId,
    required super.senderId,
    required super.content,
    super.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id']?.toString(),
      roomId: json['roomId']?.toString(),
      senderId: json['senderId']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
    );
  }
}