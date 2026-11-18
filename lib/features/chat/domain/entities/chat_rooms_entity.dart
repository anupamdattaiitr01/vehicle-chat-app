import 'package:equatable/equatable.dart';

class ChatRoomsEntity extends Equatable {
  final String? communityRoomId;
  final String? personalRoomId;
  final String managerName;

  const ChatRoomsEntity({
    this.communityRoomId,
    this.personalRoomId,
    this.managerName = 'Manager',
  });

  @override
  List<Object?> get props => [communityRoomId, personalRoomId, managerName];
}