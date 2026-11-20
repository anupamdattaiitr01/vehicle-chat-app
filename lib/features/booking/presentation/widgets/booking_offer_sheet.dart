import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/booking_entity.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';

class BookingOfferBottomSheet extends StatefulWidget {
  final BookingEntity booking;
  final bool initialQueryMode;

  const BookingOfferBottomSheet({
    super.key,
    required this.booking,
    this.initialQueryMode = false,
  });

  @override
  State<BookingOfferBottomSheet> createState() =>
      _BookingOfferBottomSheetState();
}

class _BookingOfferBottomSheetState extends State<BookingOfferBottomSheet> {
  late bool _isQueryExpanded;
  bool _hasPopped = false;
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const List<String> _quickQueries = [
    'Need 10 mins extra',
    'Pickup gate unclear',
    'Battery charging low',
    'Traffic delay on route',
  ];

  @override
  void initState() {
    super.initState();
    _isQueryExpanded = widget.initialQueryMode || !widget.booking.isPending;
    if (widget.booking.queryMessage.isNotEmpty) {
      _queryController.text = widget.booking.queryMessage;
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _expandQueryBox() {
    setState(() => _isQueryExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submitQuery() {
    FocusScope.of(context).unfocus();
    context.read<BookingCubit>().raiseQuery(
      bookingId: widget.booking.id,
      queryText: _queryController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final milo = context.milo;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxCardHeight =
    (screenHeight - bottomInset - 28).clamp(260.0, screenHeight * 0.88);

    return BlocConsumer<BookingCubit, BookingState>(
      listener: (context, state) {
        if (!_hasPopped &&
            state.activeIncomingBooking == null &&
            Navigator.canPop(context)) {
          _hasPopped = true;
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final booking = state.activeIncomingBooking ?? widget.booking;
        final isSubmitting = state.isSubmittingResponse;

        final String headerPillText = booking.isConfirmed
            ? 'CONFIRMED RIDE'
            : booking.isQueryRaised
            ? 'QUERY RAISED'
            : 'NEW RIDE';
        final Color headerPillBg = booking.isConfirmed
            ? milo.onlineGreen.withValues(alpha: 0.16)
            : milo.badgeAmberBg;
        final Color headerPillColor =
        booking.isConfirmed ? milo.onlineGreen : milo.badgeAmberText;

        return AnimatedPadding(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(12, 0, 12, 16 + bottomInset),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxCardHeight),
              child: Container(
                decoration: BoxDecoration(
                  color: milo.cardBackground,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: milo.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: milo.cardBorder,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),

                      // Top Badges + Minimize (X) Button
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: milo.burgundy,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.directions_car_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Milo Fleet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: headerPillBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              headerPillText,
                              style: TextStyle(
                                color: headerPillColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: isSubmitting
                                ? null
                                : () => context
                                .read<BookingCubit>()
                                .minimizeBookingCard(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: milo.inputFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: milo.cardBorder),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: milo.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Hero Scheduled Pickup Time
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              booking.scheduledTime,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: milo.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: milo.burgundy.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.bolt_rounded,
                              size: 18,
                              color: milo.burgundyLight,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Passenger Info + Verified Pill
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: milo.onlineGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 14,
                                  color: milo.onlineGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: milo.onlineGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${booking.passengerName} • ${booking.passengerPhone}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: milo.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      Divider(height: 24, color: milo.cardBorder),

                      // Circle-to-Square Route Timeline
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              children: [
                                const SizedBox(height: 4),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: milo.textPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    margin:
                                    const EdgeInsets.symmetric(vertical: 4),
                                    color: milo.cardBorder,
                                  ),
                                ),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: milo.burgundyLight,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PICKUP',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.7,
                                      color: milo.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    booking.pickupLocation,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: milo.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'DROP-OFF',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.7,
                                      color: milo.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    booking.dropLocation,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: milo.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (booking.notes.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: milo.inputFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: milo.cardBorder),
                          ),
                          child: Text(
                            'Note: ${booking.notes}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: milo.textSecondary,
                            ),
                          ),
                        ),
                      ],

                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          state.errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFE74C3C),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Inline Raise Query Section OR Confirm / Raise Query Buttons
                      if (_isQueryExpanded) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _quickQueries.map((preset) {
                            return ActionChip(
                              label: Text(
                                preset,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: milo.textPrimary,
                                ),
                              ),
                              backgroundColor: milo.inputFill,
                              side: BorderSide(color: milo.cardBorder),
                              onPressed: isSubmitting
                                  ? null
                                  : () {
                                _queryController.text = preset;
                                _queryController.selection =
                                    TextSelection.collapsed(
                                      offset: preset.length,
                                    );
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _queryController,
                          autofocus: true,
                          maxLines: 2,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            if (!isSubmitting) _submitQuery();
                          },
                          style:
                          TextStyle(color: milo.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Write your query for your manager...',
                            filled: true,
                            fillColor: milo.inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: milo.cardBorder),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () {
                                  FocusScope.of(context).unfocus();
                                  if (booking.isPending) {
                                    setState(
                                            () => _isQueryExpanded = false);
                                  } else {
                                    context
                                        .read<BookingCubit>()
                                        .minimizeBookingCard();
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: milo.cardBorder),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  booking.isPending ? 'Back' : 'Cancel',
                                  style: TextStyle(
                                    color: milo.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: isSubmitting ? null : _submitQuery,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC0392B),
                                  foregroundColor: Colors.white,
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  isSubmitting ? 'Sending...' : 'Send Query',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                isSubmitting ? null : _expandQueryBox,
                                style: OutlinedButton.styleFrom(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 15),
                                  side: BorderSide(color: milo.cardBorder),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Raise Query',
                                  style: TextStyle(
                                    color: milo.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: isSubmitting
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
                                child: Text(
                                  isSubmitting
                                      ? 'Confirming...'
                                      : 'Confirm Ride',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15.5,
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
          ),
        );
      },
    );
  }
}