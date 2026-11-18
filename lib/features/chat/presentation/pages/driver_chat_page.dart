import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/connection_banner.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

class DriverChatPage extends StatefulWidget {
  final ChatRouteArgs args;

  const DriverChatPage({super.key, required this.args});

  @override
  State<DriverChatPage> createState() => _DriverChatPageState();
}

class _DriverChatPageState extends State<DriverChatPage>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<ChatCubit>().onAppLifecycleChanged(state);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatState>(
      listenWhen: (previous, current) =>
      previous.messages.length != current.messages.length ||
          (!previous.isManagerTyping && current.isManagerTyping) ||
          (!previous.isLoggedOut && current.isLoggedOut) ||
          current.snackBarMessage != null,
      listener: (context, state) {
        if (state.isLoggedOut) {
          context.go(AppRouter.login);
          return;
        }

        if (state.snackBarMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.snackBarMessage!),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        _scrollToBottom();
      },
      builder: (context, state) {
        final appBarTitle = state.selectedTabIndex == 0
            ? 'Community Hub'
            : 'Manager: ${state.managerName}';

        return Scaffold(
          appBar: AppBar(
            title: Text(appBarTitle),
            backgroundColor: const Color(0xFF2C3E50),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => context.read<ChatCubit>().logout(),
              ),
            ],
          ),
          body: Column(
            children: [
              if (!state.isConnected && !state.isLoadingRooms)
                const ConnectionBanner(),
              Expanded(
                child: state.isLoadingRooms
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final msg = state.messages[index];
                    final isMe = msg.senderId == widget.args.driverId;
                    return MessageBubble(message: msg, isMe: isMe);
                  },
                ),
              ),
              if (state.isManagerTyping)
                TypingIndicator(managerName: state.managerName),
              ChatInputBar(
                controller: _messageController,
                isConnected: state.isConnected,
                onChanged: (_) => context.read<ChatCubit>().onTypingChanged(),
                onSend: _handleSend,
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: state.selectedTabIndex,
            onTap: (index) => context.read<ChatCubit>().onTabTapped(index),
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Community Hub',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Personal Chat',
              ),
            ],
          ),
        );
      },
    );
  }
}