import '../../domain/entities/chat_rooms_entity.dart';

class ChatRoomsModel extends ChatRoomsEntity {
  const ChatRoomsModel({
    super.communityRoomId,
    super.personalRoomId,
    super.managerName,
  });

  factory ChatRoomsModel.fromJson(Map<String, dynamic> json) {
    final manager = json['manager'] as Map<String, dynamic>?;
    return ChatRoomsModel(
      communityRoomId: json['communityRoomId']?.toString(),
      personalRoomId: manager?['roomId']?.toString(),
      managerName: manager?['managerName']?.toString() ?? 'Manager',
    );
  }
}