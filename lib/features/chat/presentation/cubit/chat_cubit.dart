import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/domain/usecases/logout_driver_usecase.dart';
import '../../../auth/domain/usecases/sync_fcm_token_usecase.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/get_message_history_usecase.dart';
import '../../domain/usecases/get_my_rooms_usecase.dart';
import '../../domain/usecases/join_room_usecase.dart';
import '../../domain/usecases/leave_room_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepository;
  final GetMyRoomsUseCase _getMyRoomsUseCase;
  final GetMessageHistoryUseCase _getMessageHistoryUseCase;
  final JoinRoomUseCase _joinRoomUseCase;
  final LeaveRoomUseCase _leaveRoomUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final SyncFcmTokenUseCase _syncFcmTokenUseCase;
  final LogoutDriverUseCase _logoutDriverUseCase;
  final NotificationService _notificationService;

  late ChatRouteArgs _args;
  Timer? _typingTimer;

  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<MessageEntity>? _messageSub;
  StreamSubscription<bool>? _typingSub;
  StreamSubscription<RemoteMessage>? _foregroundMsgSub;
  StreamSubscription<RemoteMessage>? _openedAppMsgSub;
  StreamSubscription<NotificationData>? _localNotifTapSub;
  StreamSubscription<String>? _tokenRefreshSub;

  ChatCubit({
    required this._chatRepository,
    required this._getMyRoomsUseCase,
    required this._getMessageHistoryUseCase,
    required this._joinRoomUseCase,
    required this._leaveRoomUseCase,
    required this._sendMessageUseCase,
    required this._syncFcmTokenUseCase,
    required this._logoutDriverUseCase,
    required this._notificationService,
  }) : super(const ChatState());

  void initialize(ChatRouteArgs args) {
    _args = args;
    emit(state.copyWith(selectedTabIndex: args.initialTabIndex));

    _bindNotificationListeners();
    _syncFcmToken();
    _bindSocketStreams();
    _chatRepository.connectSocket(args.token);
    _fetchMyRooms();
  }

  void onAppLifecycleChanged(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.inactive) {
      final activeRoom = state.activeRoomId;
      if (_chatRepository.isSocketConnected && activeRoom != null) {
        _leaveRoomUseCase(roomId: activeRoom, userId: _args.driverId);
      }
    } else if (lifecycleState == AppLifecycleState.resumed) {
      if (!_chatRepository.isSocketConnected) {
        _chatRepository.reconnectSocketIfNeeded();
      } else if (state.activeRoomId != null) {
        _joinRoomUseCase(
          roomId: state.activeRoomId!,
          userId: _args.driverId,
        );
        _fetchHistory();
      }
    }
  }

  int _resolveTargetTab(NotificationData data) {
    final incomingRoomId = data['roomId']?.toString();
    if (incomingRoomId != null && incomingRoomId.isNotEmpty) {
      if (state.personalRoomId != null &&
          incomingRoomId == state.personalRoomId) {
        return 1;
      }
      if (state.communityRoomId != null &&
          incomingRoomId == state.communityRoomId) {
        return 0;
      }
    }
    return AppConstants.tabIndexFromRoomType(data['roomType']?.toString());
  }

  void _bindNotificationListeners() {
    _openedAppMsgSub?.cancel();
    _openedAppMsgSub =
        _notificationService.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('Background notification tapped: ${message.data}');
          _navigateToRoomTab(_resolveTargetTab(message.data));
        });

    _foregroundMsgSub?.cancel();
    _foregroundMsgSub =
        _notificationService.onForegroundMessage.listen((RemoteMessage message) {
          debugPrint('Foreground FCM arrived: ${message.data}');
          final targetTab = _resolveTargetTab(message.data);

          if (targetTab != state.selectedTabIndex) {
            final title = message.notification?.title ??
                message.data['title']?.toString() ??
                message.data['senderName']?.toString() ??
                'New Fleet Message';
            final body = message.notification?.body ??
                message.data['body']?.toString() ??
                message.data['content']?.toString() ??
                '';

            _notificationService.showForegroundNotification(
              title: title,
              body: body,
              data: message.data,
            );
          }
        });

    _localNotifTapSub?.cancel();
    _localNotifTapSub =
        _notificationService.onLocalNotificationTap.listen((data) {
          _navigateToRoomTab(_resolveTargetTab(data));
        });

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _notificationService.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Refreshed Token: $newToken');
      _sendFcmTokenToBackend(newToken);
    });
  }

  Future<void> _syncFcmToken() async {
    try {
      final currentToken = await _notificationService.getToken();
      debugPrint('FCM Current Token: $currentToken');
      if (currentToken != null && currentToken.isNotEmpty) {
        await _sendFcmTokenToBackend(currentToken);
      } else if (!isClosed) {
        emit(
          state.copyWith(
            snackBarMessage:
            'FCM Warning: Device returned an empty push token.',
          ),
        );
      }
    } catch (e) {
      debugPrint('Error syncing FCM token: $e');
      if (!isClosed) {
        emit(state.copyWith(snackBarMessage: 'FCM Token Error: $e'));
      }
    }
  }

  Future<void> _sendFcmTokenToBackend(String fcmToken) async {
    try {
      await _syncFcmTokenUseCase(fcmToken);
      debugPrint('FCM Token synced to backend');
    } catch (e) {
      debugPrint('Failed to sync FCM token to backend: $e');
    }
  }

  void _navigateToRoomTab(int targetIndex) {
    if (isClosed) return;
    if (state.selectedTabIndex == targetIndex) {
      _fetchHistory();
      return;
    }
    onTabTapped(targetIndex);
  }

  void _bindSocketStreams() {
    _connectionSub?.cancel();
    _connectionSub = _chatRepository.connectionStream.listen((connected) {
      if (isClosed) return;

      if (connected) {
        emit(state.copyWith(isConnected: true));
        _syncFcmToken();

        if (state.activeRoomId == null) {
          _fetchMyRooms();
        } else {
          _joinRoomUseCase(
            roomId: state.activeRoomId!,
            userId: _args.driverId,
          );
          _fetchHistory();
        }
      } else {
        emit(state.copyWith(isConnected: false, isManagerTyping: false));
      }
    });

    _messageSub?.cancel();
    _messageSub = _chatRepository.messageStream.listen((incoming) {
      if (isClosed) return;

      String nextCommunityPreview = state.communityLastMessage;
      String nextPersonalPreview = state.personalLastMessage;

      if (incoming.roomId == state.communityRoomId &&
          incoming.content.trim().isNotEmpty) {
        nextCommunityPreview = incoming.content.trim();
      } else if (incoming.roomId == state.personalRoomId &&
          incoming.content.trim().isNotEmpty) {
        nextPersonalPreview = incoming.content.trim();
      }

      if (incoming.roomId == null || incoming.roomId == state.activeRoomId) {
        final alreadyExists = incoming.id != null &&
            state.messages.any((m) => m.id == incoming.id);

        if (!alreadyExists) {
          emit(
            state.copyWith(
              messages: [...state.messages, incoming],
              communityLastMessage: nextCommunityPreview,
              personalLastMessage: nextPersonalPreview,
            ),
          );
        }
      } else {
        emit(
          state.copyWith(
            communityLastMessage: nextCommunityPreview,
            personalLastMessage: nextPersonalPreview,
          ),
        );
      }
    });

    _typingSub?.cancel();
    _typingSub = _chatRepository.typingStream.listen((isTyping) {
      if (isClosed) return;
      emit(state.copyWith(isManagerTyping: isTyping));
    });
  }

  Future<void> _fetchMyRooms() async {
    try {
      final rooms = await _getMyRoomsUseCase();
      if (isClosed) return;

      int nextTab = state.selectedTabIndex;
      if (_args.initialRoomId != null &&
          _args.initialRoomId == rooms.personalRoomId) {
        nextTab = 1;
      }

      final nextActiveRoomId =
      nextTab == 0 ? rooms.communityRoomId : rooms.personalRoomId;

      emit(
        state.copyWith(
          communityRoomId: rooms.communityRoomId,
          personalRoomId: rooms.personalRoomId,
          managerName: rooms.managerName,
          selectedTabIndex: nextTab,
          activeRoomId: nextActiveRoomId,
          isLoadingRooms: false,
        ),
      );

      // Load latest previews for both rooms in the hub
      await _preloadRoomPreviews(
        communityRoomId: rooms.communityRoomId,
        personalRoomId: rooms.personalRoomId,
      );

      if (nextActiveRoomId != null) {
        await _fetchHistory();
        if (_chatRepository.isSocketConnected) {
          _joinRoomUseCase(
            roomId: nextActiveRoomId,
            userId: _args.driverId,
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch driver rooms: $e');
      if (!isClosed) {
        emit(state.copyWith(isLoadingRooms: false));
      }
    }
  }

  Future<void> _preloadRoomPreviews({
    String? communityRoomId,
    String? personalRoomId,
  }) async {
    String? communityPreview;
    String? personalPreview;

    if (communityRoomId != null) {
      try {
        final history = await _getMessageHistoryUseCase(communityRoomId);
        if (history.isNotEmpty) {
          communityPreview = history.last.content;
        }
      } catch (_) {}
    }

    if (personalRoomId != null) {
      try {
        final history = await _getMessageHistoryUseCase(personalRoomId);
        if (history.isNotEmpty) {
          personalPreview = history.last.content;
        }
      } catch (_) {}
    }

    if (!isClosed && (communityPreview != null || personalPreview != null)) {
      emit(
        state.copyWith(
          communityLastMessage: communityPreview,
          personalLastMessage: personalPreview,
        ),
      );
    }
  }

  void openRoom(int index) {
    final previousRoomId = state.activeRoomId;
    final nextRoomId =
    index == 0 ? state.communityRoomId : state.personalRoomId;

    if (_chatRepository.isSocketConnected &&
        previousRoomId != null &&
        previousRoomId != nextRoomId) {
      _leaveRoomUseCase(roomId: previousRoomId, userId: _args.driverId);
    }

    emit(
      state.copyWith(
        selectedTabIndex: index,
        activeRoomId: nextRoomId,
        messages: previousRoomId == nextRoomId ? state.messages : const [],
        isManagerTyping: false,
      ),
    );

    if (nextRoomId != null) {
      _fetchHistory();
      if (_chatRepository.isSocketConnected) {
        _joinRoomUseCase(roomId: nextRoomId, userId: _args.driverId);
      }
    }
  }

  void onTabTapped(int index) {
    if (state.selectedTabIndex == index) return;
    openRoom(index);
  }

  Future<void> _fetchHistory() async {
    final roomId = state.activeRoomId;
    if (roomId == null) return;

    try {
      final history = await _getMessageHistoryUseCase(roomId);
      if (!isClosed) {
        String? updatedCommunity;
        String? updatedPersonal;
        if (history.isNotEmpty) {
          if (roomId == state.communityRoomId) {
            updatedCommunity = history.last.content;
          } else if (roomId == state.personalRoomId) {
            updatedPersonal = history.last.content;
          }
        }
        emit(
          state.copyWith(
            messages: history,
            communityLastMessage: updatedCommunity,
            personalLastMessage: updatedPersonal,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to fetch message history: $e');
    }
  }

  bool sendMessage(String rawText) {
    final text = rawText.trim();
    final roomId = state.activeRoomId;
    if (text.isEmpty || roomId == null) return false;

    if (!state.isConnected || !_chatRepository.isSocketConnected) {
      emit(
        state.copyWith(
          snackBarMessage: 'Offline — waiting for network to reconnect...',
        ),
      );
      return false;
    }

    _sendMessageUseCase(
      roomId: roomId,
      senderId: _args.driverId,
      content: text,
    );
    _chatRepository.sendStopTyping(roomId: roomId);
    return true;
  }

  void onTypingChanged() {
    final roomId = state.activeRoomId;
    if (roomId == null || !state.isConnected) return;

    _chatRepository.sendTyping(roomId: roomId, userName: _args.driverName);

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_chatRepository.isSocketConnected) {
        _chatRepository.sendStopTyping(roomId: roomId);
      }
    });
  }

  Future<void> logout() async {
    await _logoutDriverUseCase();
    _chatRepository.disconnectSocket();
    if (!isClosed) {
      emit(state.copyWith(isLoggedOut: true));
    }
  }

  @override
  Future<void> close() {
    _connectionSub?.cancel();
    _messageSub?.cancel();
    _typingSub?.cancel();
    _foregroundMsgSub?.cancel();
    _openedAppMsgSub?.cancel();
    _localNotifTapSub?.cancel();
    _tokenRefreshSub?.cancel();
    _typingTimer?.cancel();
    _chatRepository.disconnectSocket();
    return super.close();
  }
}