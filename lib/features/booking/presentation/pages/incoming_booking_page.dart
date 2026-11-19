import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/booking_entity.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';

class IncomingBookingPage extends StatefulWidget {
  final BookingEntity booking;

  const IncomingBookingPage({super.key, required this.booking});

  @override
  State<IncomingBookingPage> createState() => _IncomingBookingPageState();
}

class _IncomingBookingPageState extends State<IncomingBookingPage> {
  final TextEditingController _queryController = TextEditingController();
  bool _isQueryExpanded = false;

  static const List<String> _quickQueryPresets = [
    'Pickup time conflict',
    'Low battery • need charging first',
    'Need exact pickup landmark',
  ];

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final milo = context.milo;
    final isDark = context.isDarkMode;

    return BlocConsumer<BookingCubit, BookingState>(
      listenWhen: (prev, curr) =>
      prev.activeIncomingBooking != curr.activeIncomingBooking,
      listener: (context, state) {
        if (state.activeIncomingBooking == null && mounted) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final booking = state.activeIncomingBooking ?? widget.booking;

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
              child: Column(
                children: [
                  // Top Bar with Urgent Ride Badge + Minimize Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: milo.burgundy,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'NEW RIDE ASSIGNED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: state.isSubmittingResponse
                              ? null
                              : () => context
                              .read<BookingCubit>()
                              .minimizeBookingCard(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: milo.textSecondary,
                          ),
                          tooltip: 'Minimize',
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: milo.cardBackground,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: milo.burgundyLight.withValues(alpha: 0.45),
                            width: 1.3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.4 : 0.08,
                              ),
                              blurRadius: 26,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Assigned By Manager Subtitle
                            Text(
                              'Assigned by ${booking.managerName}',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: milo.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Scheduled Pickup Time Highlight Pill
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: milo.badgeAmberBg,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_filled_rounded,
                                    color: milo.badgeAmberText,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SCHEDULED PICKUP TIME',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                            color: milo.badgeAmberText,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          booking.scheduledTime,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: milo.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Passenger Card
                            Text(
                              'PASSENGER DETAILS',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: milo.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: milo.inputFill,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: milo.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: milo.burgundy,
                                    child: Text(
                                      booking.passengerName.isNotEmpty
                                          ? booking.passengerName[0]
                                          .toUpperCase()
                                          : 'P',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          booking.passengerName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: milo.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          booking.passengerPhone,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500,
                                            color: milo.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Pickup -> Drop Route Timeline
                            Text(
                              'TRIP ROUTE',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: milo.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: milo.inputFill,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: milo.cardBorder),
                              ),
                              child: Column(
                                children: [
                                  _routeStop(
                                    icon: Icons.radio_button_checked_rounded,
                                    iconColor: milo.onlineGreen,
                                    label: 'PICKUP LOCATION',
                                    address: booking.pickupLocation,
                                    milo: milo,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 9, top: 4, bottom: 4),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        width: 2,
                                        height: 18,
                                        color: milo.cardBorder,
                                      ),
                                    ),
                                  ),
                                  _routeStop(
                                    icon: Icons.location_on_rounded,
                                    iconColor: milo.burgundyLight,
                                    label: 'DROP LOCATION',
                                    address: booking.dropLocation,
                                    milo: milo,
                                  ),
                                ],
                              ),
                            ),

                            if (booking.notes.trim().isNotEmpty) ...[
                              const SizedBox(height: 18),
                              Text(
                                'MANAGER NOTES',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: milo.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: milo.inputFill,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: milo.cardBorder),
                                ),
                                child: Text(
                                  booking.notes,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: milo.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],

                            if (state.errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF36161C)
                                      : const Color(0xFFFDECEA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE74C3C)
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Text(
                                  state.errorMessage!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? const Color(0xFFFF8A80)
                                        : const Color(0xFFC0392B),
                                  ),
                                ),
                              ),
                            ],

                            // Expandable Query Composer
                            if (_isQueryExpanded) ...[
                              const SizedBox(height: 20),
                              Divider(color: milo.cardBorder),
                              const SizedBox(height: 14),
                              Text(
                                'RAISE QUERY TO MANAGER CHAT',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                  color: milo.burgundyLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _quickQueryPresets.map((preset) {
                                  return GestureDetector(
                                    onTap: () {
                                      _queryController.text = preset;
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: milo.inputFill,
                                        borderRadius:
                                        BorderRadius.circular(999),
                                        border:
                                        Border.all(color: milo.cardBorder),
                                      ),
                                      child: Text(
                                        preset,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: milo.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _queryController,
                                maxLines: 3,
                                autofocus: true,
                                style: TextStyle(
                                  color: milo.textPrimary,
                                  fontSize: 14,
                                ),
                                decoration: const InputDecoration(
                                  hintText:
                                  'Describe your issue or question for the manager...',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: state.isSubmittingResponse
                                          ? null
                                          : () => setState(
                                              () => _isQueryExpanded = false),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        side:
                                        BorderSide(color: milo.cardBorder),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: milo.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: state.isSubmittingResponse
                                          ? null
                                          : () {
                                        context
                                            .read<BookingCubit>()
                                            .raiseQuery(
                                          bookingId: booking.id,
                                          queryText:
                                          _queryController.text,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: milo.burgundy,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: state.isSubmittingResponse
                                          ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                          : const Text(
                                        'Send Query to Chat',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Primary Action Buttons: Confirm Ride & Raise Query
                  if (!_isQueryExpanded)
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      decoration: BoxDecoration(
                        color: milo.cardBackground,
                        border: Border(top: BorderSide(color: milo.cardBorder)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: state.isSubmittingResponse
                                  ? null
                                  : () =>
                                  setState(() => _isQueryExpanded = true),
                              style: OutlinedButton.styleFrom(
                                padding:
                                const EdgeInsets.symmetric(vertical: 15),
                                side: BorderSide(
                                  color: milo.burgundyLight,
                                  width: 1.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: Icon(
                                Icons.help_outline_rounded,
                                color: milo.burgundyLight,
                                size: 19,
                              ),
                              label: Text(
                                'Raise Query',
                                style: TextStyle(
                                  color: milo.burgundyLight,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: state.isSubmittingResponse
                                  ? null
                                  : () => context
                                  .read<BookingCubit>()
                                  .confirmBooking(booking.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: milo.burgundy,
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: state.isSubmittingResponse
                                  ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                              ),
                              label: const Text(
                                'Confirm Ride',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _routeStop({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
    required MiloColors milo,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: milo.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: milo.textPrimary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}