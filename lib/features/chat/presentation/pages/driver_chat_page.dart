import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/connection_banner.dart';
import 'chat_room_page.dart';

class DriverChatPage extends StatefulWidget {
  final ChatRouteArgs args;

  const DriverChatPage({super.key, required this.args});

  @override
  State<DriverChatPage> createState() => _DriverChatPageState();
}

class _DriverChatPageState extends State<DriverChatPage>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  int _bottomNavIndex = 3; // 0: Home, 1: Performance, 3: Chat, 4: Profile
  bool _handledInitialDeepLink = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<ChatCubit>().onAppLifecycleChanged(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  String get _firstName {
    final trimmed = widget.args.driverName.trim();
    if (trimmed.isEmpty) return 'Driver';
    return trimmed.split(' ').first;
  }

  void _openConversation({required int roomTabIndex}) {
    final chatCubit = context.read<ChatCubit>();
    chatCubit.openRoom(roomTabIndex);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: chatCubit,
          child: ChatRoomPage(
            args: widget.args,
            roomTabIndex: roomTabIndex,
          ),
        ),
      ),
    );
  }

  void _openProfileSheet(ChatState state) {
    final milo = context.milo;
    final isDark = context.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: milo.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: milo.cardBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 30,
                backgroundColor: milo.burgundy,
                child: Text(
                  _firstName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.args.driverName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: milo.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Assigned Manager: ${state.managerName}',
                style: TextStyle(
                  fontSize: 13,
                  color: milo.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: milo.inputFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: milo.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Appearance',
                      style: TextStyle(
                        color: milo.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        context.read<ThemeCubit>().toggleTheme();
                        Navigator.pop(sheetContext);
                      },
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        size: 18,
                        color: milo.burgundyLight,
                      ),
                      label: Text(
                        isDark ? 'Switch to Light' : 'Switch to Dark',
                        style: TextStyle(
                          color: milo.burgundyLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.read<ChatCubit>().logout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC0392B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final milo = context.milo;
    final isDark = context.isDarkMode;

    return BlocConsumer<ChatCubit, ChatState>(
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

        // If launched directly via push notification tap, open that chat room
        if (!_handledInitialDeepLink &&
            !state.isLoadingRooms &&
            (widget.args.initialRoomId != null ||
                widget.args.initialTabIndex == 1)) {
          _handledInitialDeepLink = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _openConversation(roomTabIndex: state.selectedTabIndex);
            }
          });
        }
      },
      builder: (context, state) {
        final query = _searchQuery.trim().toLowerCase();
        final showManagerRow = query.isEmpty ||
            state.managerName.toLowerCase().contains(query) ||
            state.personalLastMessage.toLowerCase().contains(query);
        final showCommunityRow = query.isEmpty ||
            'community hub'.contains(query) ||
            state.communityLastMessage.toLowerCase().contains(query);

        return Scaffold(
          backgroundColor: milo.scaffoldBackground,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.85, -0.88),
                radius: 1.35,
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
                  if (!state.isConnected && !state.isLoadingRooms)
                    const ConnectionBanner(),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Header: Messages + Theme Toggle + Search Button
                          Row(
                            children: [
                              Text(
                                'Messages',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: milo.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const Spacer(),
                              // Dark / Light Toggle Button
                              GestureDetector(
                                onTap: () =>
                                    context.read<ThemeCubit>().toggleTheme(),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: milo.cardBackground,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: milo.cardBorder),
                                  ),
                                  child: Icon(
                                    isDark
                                        ? Icons.light_mode_outlined
                                        : Icons.dark_mode_outlined,
                                    size: 19,
                                    color: milo.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Search Circle Button
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isSearching = !_isSearching;
                                    if (!_isSearching) {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    }
                                  });
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _isSearching
                                        ? milo.burgundy
                                        : milo.cardBackground,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: milo.cardBorder),
                                  ),
                                  child: Icon(
                                    _isSearching
                                        ? Icons.close_rounded
                                        : Icons.search_rounded,
                                    size: 20,
                                    color: _isSearching
                                        ? Colors.white
                                        : milo.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (_isSearching) ...[
                            const SizedBox(height: 14),
                            TextField(
                              controller: _searchController,
                              autofocus: true,
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val),
                              style: TextStyle(color: milo.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Search manager or messages...',
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: milo.textSecondary,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Greeting
                          Text(
                            'Hi $_firstName 👋',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: milo.textPrimary,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your manager & fleet conversations',
                            style: TextStyle(
                              fontSize: 15,
                              color: milo.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 26),

                          // CHATS Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'CHATS',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: milo.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _openConversation(roomTabIndex: 1),
                                child: Text(
                                  'Message manager',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: milo.burgundyLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (state.isLoadingRooms)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 28),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: milo.burgundyLight,
                                ),
                              ),
                            )
                          else ...[
                            // 1. Assigned Manager Chat Row
                            if (showManagerRow)
                              _ChatThreadTile(
                                title: state.managerName,
                                subtitle: state.isManagerTyping
                                    ? '${state.managerName} is typing...'
                                    : state.personalLastMessage,
                                isTyping: state.isManagerTyping,
                                badgeLabel: 'YOUR MANAGER',
                                isOnline: state.isConnected,
                                avatar: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: const Color(0xFF8C5230),
                                  child: Text(
                                    state.managerName.isNotEmpty
                                        ? state.managerName[0].toUpperCase()
                                        : 'M',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                onTap: () =>
                                    _openConversation(roomTabIndex: 1),
                              ),

                            if (showManagerRow && showCommunityRow)
                              Divider(
                                height: 1,
                                indent: 64,
                                color: milo.cardBorder,
                              ),

                            // 2. Community Hub Row
                            if (showCommunityRow)
                              _ChatThreadTile(
                                title: 'Community Hub',
                                subtitle: state.communityLastMessage,
                                isOnline: false,
                                avatar: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: milo.burgundy,
                                  child: const Text(
                                    'milo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                onTap: () =>
                                    _openConversation(roomTabIndex: 0),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Custom Milo Bottom Navigation Bar with Center Burgundy Bolt Button
          bottomNavigationBar: _MiloBottomBar(
            currentIndex: _bottomNavIndex,
            onSelectTab: (idx) {
              if (idx == 4) {
                _openProfileSheet(state);
                return;
              }
              if (idx == 2) {
                _openConversation(roomTabIndex: 1);
                return;
              }
              setState(() => _bottomNavIndex = idx);
            },
          ),
        );
      },
    );
  }
}

class _ChatThreadTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget avatar;
  final String? badgeLabel;
  final bool isOnline;
  final bool isTyping;
  final VoidCallback onTap;

  const _ChatThreadTile({
    required this.title,
    required this.subtitle,
    required this.avatar,
    required this.onTap,
    this.badgeLabel,
    this.isOnline = false,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    final milo = context.milo;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                avatar,
                if (isOnline)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: milo.onlineGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: milo.scaffoldBackground,
                          width: 2.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: milo.textPrimary,
                          ),
                        ),
                      ),
                      if (badgeLabel != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: milo.badgeAmberBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeLabel!,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: milo.badgeAmberText,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isTyping ? FontWeight.w600 : FontWeight.w400,
                      color: isTyping ? milo.onlineGreen : milo.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: milo.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiloBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelectTab;

  const _MiloBottomBar({
    required this.currentIndex,
    required this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    final milo = context.milo;

    return Container(
      decoration: BoxDecoration(
        color: milo.cardBackground,
        border: Border(
          top: BorderSide(color: milo.cardBorder),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: currentIndex == 0,
                milo: milo,
                onTap: () => onSelectTab(0),
              ),
              _navItem(
                icon: Icons.bar_chart_rounded,
                label: 'Performance',
                selected: currentIndex == 1,
                milo: milo,
                onTap: () => onSelectTab(1),
              ),
              // Raised Burgundy Bolt Action Button
              GestureDetector(
                onTap: () => onSelectTab(2),
                child: Transform.translate(
                  offset: const Offset(0, -10),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: milo.burgundy,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: milo.burgundy.withValues(alpha: 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              _navItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat',
                selected: currentIndex == 3,
                milo: milo,
                onTap: () => onSelectTab(3),
              ),
              _navItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                selected: currentIndex == 4,
                milo: milo,
                onTap: () => onSelectTab(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool selected,
    required MiloColors milo,
    required VoidCallback onTap,
  }) {
    final color = selected ? milo.burgundyLight : milo.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 66,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}