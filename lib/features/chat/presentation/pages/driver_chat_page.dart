import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../../booking/presentation/cubit/booking_cubit.dart';
import '../../../booking/presentation/cubit/booking_state.dart';
import '../../../booking/presentation/pages/incoming_booking_page.dart';
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
  bool _isBookingRouteOpen = false;
  bool _canUseFullScreenIntent = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkFullScreenPermission();

    // Check if cold-launched with an incoming booking payload
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final initialBooking =
          context.read<BookingCubit>().state.activeIncomingBooking;
      if (initialBooking != null) {
        _presentIncomingBooking(initialBooking);
      }
    });
  }

  Future<void> _checkFullScreenPermission() async {
    final allowed = await sl<NotificationService>().canUseFullScreenIntent();
    if (mounted && allowed != _canUseFullScreenIntent) {
      setState(() => _canUseFullScreenIntent = allowed);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<ChatCubit>().onAppLifecycleChanged(state);
    if (state == AppLifecycleState.resumed) {
      _checkFullScreenPermission();
      context.read<BookingCubit>().fetchMyBookings();
    }
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

  void _presentIncomingBooking(BookingEntity booking) {
    if (_isBookingRouteOpen || !mounted) return;
    _isBookingRouteOpen = true;

    final bookingCubit = context.read<BookingCubit>();
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BlocProvider.value(
          value: bookingCubit,
          child: IncomingBookingPage(booking: booking),
        ),
      ),
    )
        .whenComplete(() {
      if (mounted) {
        _isBookingRouteOpen = false;
      }
    });
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

  Future<void> _showLogoutConfirmationDialog() async {
    final milo = context.milo;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: milo.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: milo.cardBorder),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFC0392B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE74C3C),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Log Out of Milo Drive?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: milo.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'You will be disconnected from your manager chat and will not receive incoming ride booking alerts until you sign in again.',
            style: TextStyle(
              fontSize: 13.5,
              color: milo.textSecondary,
              height: 1.45,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: milo.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: milo.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC0392B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Log Out',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      context.read<ChatCubit>().logout();
    }
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
                    _showLogoutConfirmationDialog();
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

    return BlocConsumer<BookingCubit, BookingState>(
      listener: (context, bookingState) {
        if (bookingState.activeIncomingBooking != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && bookingState.activeIncomingBooking != null) {
              _presentIncomingBooking(bookingState.activeIncomingBooking!);
            }
          });
        }

        if (bookingState.snackBarMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(bookingState.snackBarMessage!),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        if (bookingState.navigateToManagerChat) {
          context.read<BookingCubit>().consumeNavigation();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _openConversation(roomTabIndex: 1);
            }
          });
        } else if (bookingState.snackBarMessage != null) {
          context.read<BookingCubit>().consumeNavigation();
        }
      },
      builder: (context, bookingState) {
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

            // If launched directly via chat push notification tap, open that room
            if (!_handledInitialDeepLink &&
                !state.isLoadingRooms &&
                widget.args.initialBookingData == null &&
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

            final latestBooking = bookingState.latestBooking;

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
                                  GestureDetector(
                                    onTap: () => context
                                        .read<ThemeCubit>()
                                        .toggleTheme(),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: milo.cardBackground,
                                        shape: BoxShape.circle,
                                        border:
                                        Border.all(color: milo.cardBorder),
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
                                        border:
                                        Border.all(color: milo.cardBorder),
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

                              // Android 14+ Full-Screen Intent Permission Prompt
                              if (!_canUseFullScreenIntent) ...[
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: milo.badgeAmberBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: milo.badgeAmberText
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.notifications_active_rounded,
                                        color: milo.badgeAmberText,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Enable full-screen ride alerts so incoming bookings wake your screen.',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: milo.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () =>
                                            sl<NotificationService>()
                                                .openFullScreenIntentSettings(),
                                        child: Text(
                                          'Enable',
                                          style: TextStyle(
                                            color: milo.badgeAmberText,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Latest Assigned Ride Summary Card
                              if (latestBooking != null) ...[
                                const SizedBox(height: 22),
                                Text(
                                  'ASSIGNED RIDE',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: milo.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _AssignedRideCard(
                                  booking: latestBooking,
                                  onTap: () => context
                                      .read<BookingCubit>()
                                      .openBookingCard(latestBooking),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // CHATS Header
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
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
                                    onTap: () =>
                                        _openConversation(roomTabIndex: 1),
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
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 28),
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

              // Custom Milo Bottom Navigation Bar
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
      },
    );
  }
}

class _AssignedRideCard extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback onTap;

  const _AssignedRideCard({
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final milo = context.milo;

    final Color badgeBg = booking.isConfirmed
        ? milo.onlineGreen.withValues(alpha: 0.16)
        : booking.isQueryRaised
        ? const Color(0xFFE74C3C).withValues(alpha: 0.16)
        : milo.badgeAmberBg;

    final Color badgeText = booking.isConfirmed
        ? milo.onlineGreen
        : booking.isQueryRaised
        ? const Color(0xFFE74C3C)
        : milo.badgeAmberText;

    final String statusLabel = booking.isConfirmed
        ? 'CONFIRMED'
        : booking.isQueryRaised
        ? 'QUERY RAISED'
        : 'PENDING RESPONSE';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: milo.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: booking.isPending
                ? milo.burgundyLight.withValues(alpha: 0.55)
                : milo.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: badgeText,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  booking.scheduledTime,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: milo.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Passenger: ${booking.passengerName} (${booking.passengerPhone})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: milo.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${booking.pickupLocation} → ${booking.dropLocation}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: milo.textSecondary,
              ),
            ),
          ],
        ),
      ),
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