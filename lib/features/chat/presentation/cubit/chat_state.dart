import 'package:equatable/equatable.dart';
import '../../domain/entities/message_entity.dart';

class ChatState extends Equatable {
  final int selectedTabIndex;
  final String? communityRoomId;
  final String? personalRoomId;
  final String? activeRoomId;
  final String managerName;
  final String communityLastMessage;
  final String personalLastMessage;
  final bool isLoadingRooms;
  final bool isConnected;
  final List<MessageEntity> messages;
  final bool isManagerTyping;
  final bool isLoggedOut;
  final String? snackBarMessage;

  const ChatState({
    this.selectedTabIndex = 0,
    this.communityRoomId,
    this.personalRoomId,
    this.activeRoomId,
    this.managerName = 'Manager',
    this.communityLastMessage = 'Fleet announcements & driver updates',
    this.personalLastMessage = 'Tap to chat with your manager',
    this.isLoadingRooms = true,
    this.isConnected = false,
    this.messages = const [],
    this.isManagerTyping = false,
    this.isLoggedOut = false,
    this.snackBarMessage,
  });

  ChatState copyWith({
    int? selectedTabIndex,
    String? communityRoomId,
    String? personalRoomId,
    String? activeRoomId,
    String? managerName,
    String? communityLastMessage,
    String? personalLastMessage,
    bool? isLoadingRooms,
    bool? isConnected,
    List<MessageEntity>? messages,
    bool? isManagerTyping,
    bool? isLoggedOut,
    String? snackBarMessage,
  }) {
    return ChatState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      communityRoomId: communityRoomId ?? this.communityRoomId,
      personalRoomId: personalRoomId ?? this.personalRoomId,
      activeRoomId: activeRoomId ?? this.activeRoomId,
      managerName: managerName ?? this.managerName,
      communityLastMessage: communityLastMessage ?? this.communityLastMessage,
      personalLastMessage: personalLastMessage ?? this.personalLastMessage,
      isLoadingRooms: isLoadingRooms ?? this.isLoadingRooms,
      isConnected: isConnected ?? this.isConnected,
      messages: messages ?? this.messages,
      isManagerTyping: isManagerTyping ?? this.isManagerTyping,
      isLoggedOut: isLoggedOut ?? this.isLoggedOut,
      snackBarMessage: snackBarMessage,
    );
  }

  @override
  List<Object?> get props => [
    selectedTabIndex,
    communityRoomId,
    personalRoomId,
    activeRoomId,
    managerName,
    communityLastMessage,
    personalLastMessage,
    isLoadingRooms,
    isConnected,
    messages,
    isManagerTyping,
    isLoggedOut,
    snackBarMessage,
  ];
}