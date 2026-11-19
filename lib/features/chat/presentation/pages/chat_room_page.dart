import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/connection_banner.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

class ChatRoomPage extends StatefulWidget {
  final ChatRouteArgs args;
  final int roomTabIndex;

  const ChatRoomPage({
    super.key,
    required this.args,
    required this.roomTabIndex,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _didInitialScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollToBottom(animate: false);
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final targetOffset = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(targetOffset);
        // Second pass after dynamic multi-line bubble heights settle
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
      }
    });
  }

  void _handleSend() {
    final sent = context.read<ChatCubit>().sendMessage(_messageController.text);
    if (sent) {
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final milo = context.milo;

    return BlocConsumer<ChatCubit, ChatState>(
      listenWhen: (previous, current) =>
      previous.messages != current.messages ||
          (!previous.isManagerTyping && current.isManagerTyping),
      listener: (context, state) {
        final isInitialLoad = !_didInitialScroll && state.messages.isNotEmpty;
        if (isInitialLoad) {
          _didInitialScroll = true;
        }
        _scrollToBottom(animate: !isInitialLoad);
      },
      builder: (context, state) {
        final isPersonal = widget.roomTabIndex == 1;
        final roomTitle = isPersonal ? state.managerName : 'Community Hub';
        final avatarInitial = roomTitle.isNotEmpty
            ? roomTitle.trim()[0].toUpperCase()
            : 'M';

        return Scaffold(
          backgroundColor: milo.scaffoldBackground,
          body: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.85, -0.9),
                radius: 1.3,
                colors: [
                  milo.radialGlow,
                  milo.scaffoldBackground,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top Conversation Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        // Rounded Back Button
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: milo.cardBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: milo.cardBorder),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: milo.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Avatar with Online Dot
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isPersonal
                                    ? const Color(0xFF8C5230)
                                    : milo.burgundy,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: isPersonal
                                  ? Text(
                                avatarInitial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                ),
                              )
                                  : const Text(
                                'milo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            Positioned(
                              right: -1,
                              bottom: -1,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: state.isConnected
                                      ? milo.onlineGreen
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: milo.scaffoldBackground,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Name + Status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                roomTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: milo.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: state.isConnected
                                          ? milo.onlineGreen
                                          : Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      isPersonal && state.isManagerTyping
                                          ? '${state.managerName} is typing...'
                                          : isPersonal
                                          ? 'Driver Manager • ${state.isConnected ? 'Online' : 'Reconnecting'}'
                                          : 'Fleet Community • ${state.isConnected ? 'Online' : 'Reconnecting'}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isPersonal &&
                                            state.isManagerTyping
                                            ? milo.onlineGreen
                                            : milo.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, color: milo.cardBorder),

                  if (!state.isConnected && !state.isLoadingRooms)
                    const ConnectionBanner(),

                  // Messages List
                  Expanded(
                    child: state.isLoadingRooms
                        ? Center(
                      child: CircularProgressIndicator(
                        color: milo.burgundyLight,
                      ),
                    )
                        : state.messages.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: milo.cardBackground,
                              borderRadius:
                              BorderRadius.circular(999),
                              border:
                              Border.all(color: milo.cardBorder),
                            ),
                            child: Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 12,
                                color: milo.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            isPersonal
                                ? 'Start a conversation with ${state.managerName}'
                                : 'Welcome to the Milo Community Hub',
                            style: TextStyle(
                              color: milo.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                          16, 12, 16, 12),
                      itemCount: state.messages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Center(
                            child: Container(
                              margin:
                              const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: milo.cardBackground,
                                borderRadius:
                                BorderRadius.circular(999),
                                border: Border.all(
                                    color: milo.cardBorder),
                              ),
                              child: Text(
                                'Today',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: milo.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }

                        final msg = state.messages[index - 1];
                        final isMe =
                            msg.senderId == widget.args.driverId;
                        return MessageBubble(
                          message: msg,
                          isMe: isMe,
                        );
                      },
                    ),
                  ),

                  if (isPersonal && state.isManagerTyping)
                    TypingIndicator(managerName: state.managerName),

                  // Rounded Pill Input Bar
                  ChatInputBar(
                    controller: _messageController,
                    isConnected: state.isConnected,
                    onChanged: (_) =>
                        context.read<ChatCubit>().onTypingChanged(),
                    onSend: _handleSend,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}