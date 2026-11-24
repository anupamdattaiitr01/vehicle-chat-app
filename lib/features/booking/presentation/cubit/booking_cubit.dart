import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/overlay_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../data/datasources/booking_remote_datasource.dart';
import '../../domain/entities/booking_entity.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final BookingRemoteDataSource _remoteDataSource;
  final SocketService _socketService;
  final NotificationService _notificationService;

  StreamSubscription<SocketEventData>? _bookingAssignedSub;
  StreamSubscription<SocketEventData>? _bookingUpdatedSub;
  StreamSubscription<SocketEventData>? _bookingReallocatedSub;
  StreamSubscription<RemoteMessage>? _foregroundFcmSub;
  StreamSubscription<RemoteMessage>? _openedFcmSub;
  StreamSubscription<NotificationData>? _localTapSub;
  Timer? _expiryPruningTimer;

  final Set<String> _minimizedBookingIds = <String>{};
  final Set<String> _respondedBookingIds = <String>{};
  bool _isAppInForeground = true;

  BookingCubit({
    required this._remoteDataSource,
    required this._socketService,
    required this._notificationService,
  }) : super(const BookingState());

  void setAppForegroundState(bool isForeground) {
    _isAppInForeground = isForeground;
  }

  void initialize({Map<String, dynamic>? initialBookingData}) {
    BookingEntity? initialIncoming;
    if (initialBookingData != null &&
        initialBookingData['type'] == 'BOOKING_ASSIGNED') {
      initialIncoming = BookingEntity.fromMap(initialBookingData);
      if (initialIncoming.id.isEmpty ||
          !initialIncoming.isPending ||
          !initialIncoming.isUpcoming) {
        initialIncoming = null;
      }
    }

    if (initialIncoming != null) {
      unawaited(OverlayService.closeOverlay());
      emit(
        state.copyWith(
          activeIncomingBooking: initialIncoming,
          openSheetInQueryMode: false,
          bookings: [initialIncoming],
        ),
      );
    }

    _startExpiryTimer();
    _bindRealtimeStreams();
    onAppResumed();
  }

  /// Called on startup and whenever DriverChatPage returns to foreground.
  Future<void> onAppResumed() async {
    await fetchMyBookings();
    await _checkPendingOverlayQuery();
  }

  void _startExpiryTimer() {
    _expiryPruningTimer?.cancel();
    _expiryPruningTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isClosed) return;
      final upcomingOnly =
      state.bookings.where((b) => b.isUpcoming).toList();
      if (upcomingOnly.length != state.bookings.length) {
        emit(state.copyWith(bookings: upcomingOnly));
      }
    });
  }

  Future<void> _checkPendingOverlayQuery() async {
    final pendingQueryId = await OverlayService.consumePendingQueryBookingId();
    if (pendingQueryId == null || pendingQueryId.isEmpty || isClosed) return;
    _openQueryForBookingId(pendingQueryId);
  }

  void _openQueryForBookingId(String bookingId) {
    final idx = state.bookings.indexWhere((b) => b.id == bookingId);
    if (idx >= 0) {
      openBookingCard(state.bookings[idx], startInQueryMode: true);
    }
  }

  void _bindRealtimeStreams() {
    _bookingAssignedSub?.cancel();
    _bookingAssignedSub = _socketService.bookingAssignedStream.listen((data) {
      final booking = BookingEntity.fromMap(data);
      if (booking.id.isEmpty) return;
      _respondedBookingIds.remove(booking.id);
      _minimizedBookingIds.remove(booking.id);
      unawaited(_handleIncomingBooking(booking));
    });

    _bookingUpdatedSub?.cancel();
    _bookingUpdatedSub = _socketService.bookingUpdatedStream.listen((data) {
      final updated = BookingEntity.fromMap(data);
      if (updated.id.isEmpty) return;

      if (updated.isCancelled) {
        unawaited(_notificationService.cancelBookingNotification(updated.id));
        unawaited(OverlayService.closeOverlay());
        final remaining =
        state.bookings.where((b) => b.id != updated.id).toList();
        final shouldClearSheet = state.activeIncomingBooking?.id == updated.id;
        emit(
          state.copyWith(
            bookings: remaining,
            clearActiveIncoming: shouldClearSheet,
            openSheetInQueryMode:
            shouldClearSheet ? false : state.openSheetInQueryMode,
            snackBarMessage:
            'Ride for ${updated.passengerName} was cancelled by your manager.',
          ),
        );
        return;
      }

      if (!updated.isPending) {
        _respondedBookingIds.add(updated.id);
        unawaited(_notificationService.cancelBookingNotification(updated.id));
        unawaited(OverlayService.closeOverlay());
      }
      _upsertBookingInList(updated);
      if (!updated.isPending &&
          state.activeIncomingBooking?.id == updated.id) {
        emit(
          state.copyWith(
            clearActiveIncoming: true,
            openSheetInQueryMode: false,
          ),
        );
      }
    });

    _bookingReallocatedSub?.cancel();
    _bookingReallocatedSub =
        _socketService.bookingReallocatedStream.listen((data) {
          final bookingId = (data['bookingId'] ?? '').toString();
          if (bookingId.isEmpty) return;

          unawaited(_notificationService.cancelBookingNotification(bookingId));
          unawaited(OverlayService.closeOverlay());
          final remaining =
          state.bookings.where((b) => b.id != bookingId).toList();
          final shouldClearSheet = state.activeIncomingBooking?.id == bookingId;

          emit(
            state.copyWith(
              bookings: remaining,
              clearActiveIncoming: shouldClearSheet,
              openSheetInQueryMode:
              shouldClearSheet ? false : state.openSheetInQueryMode,
              snackBarMessage: 'A ride was reassigned by your manager.',
            ),
          );
        });

    _foregroundFcmSub?.cancel();
    _foregroundFcmSub =
        _notificationService.onForegroundMessage.listen((RemoteMessage msg) {
          if (msg.data['type'] == 'BOOKING_ASSIGNED') {
            final booking = BookingEntity.fromMap(msg.data);
            if (booking.id.isNotEmpty) {
              unawaited(_handleIncomingBooking(booking));
            }
          }
        });

    _openedFcmSub?.cancel();
    _openedFcmSub =
        _notificationService.onMessageOpenedApp.listen((RemoteMessage msg) {
          if (msg.data['type'] == 'BOOKING_ASSIGNED') {
            final booking = BookingEntity.fromMap(msg.data);
            if (booking.id.isNotEmpty &&
                !_respondedBookingIds.contains(booking.id)) {
              _minimizedBookingIds.remove(booking.id);
              unawaited(_handleIncomingBooking(booking));
            }
          }
        });

    _localTapSub?.cancel();
    _localTapSub =
        _notificationService.onLocalNotificationTap.listen((NotificationData data) {
          if (data['type'] == 'BOOKING_ASSIGNED') {
            final booking = BookingEntity.fromMap(data);
            if (booking.id.isNotEmpty &&
                !_respondedBookingIds.contains(booking.id)) {
              _minimizedBookingIds.remove(booking.id);
              unawaited(_handleIncomingBooking(booking));
            }
          }
        });
  }

  Future<void> _handleIncomingBooking(BookingEntity booking) async {
    if (isClosed || !booking.isUpcoming) return;

    final existingIdx = state.bookings.indexWhere((b) => b.id == booking.id);
    final alreadyHandled = _respondedBookingIds.contains(booking.id) ||
        (existingIdx >= 0 && !state.bookings[existingIdx].isPending);

    if (alreadyHandled && booking.isPending) {
      return;
    }

    _upsertBookingInList(booking);

    // When app is backgrounded or killed, MiloFirebaseMessagingService renders
    // the native WindowManager floating card directly. Only emit the in-app
    // Flutter bottom sheet when the app is in the foreground.
    if (!_isAppInForeground) {
      return;
    }

    if (booking.isPending &&
        !alreadyHandled &&
        !_minimizedBookingIds.contains(booking.id) &&
        state.activeIncomingBooking?.id != booking.id &&
        !isClosed) {
      unawaited(OverlayService.closeOverlay());
      emit(
        state.copyWith(
          activeIncomingBooking: booking,
          openSheetInQueryMode: false,
          clearError: true,
        ),
      );
    }
  }

  void _upsertBookingInList(BookingEntity booking) {
    final updatedList =
    state.bookings.where((b) => b.isUpcoming && b.id != booking.id).toList();
    if (booking.isUpcoming) {
      updatedList.add(booking);
    }
    updatedList.sort((a, b) => a.sortTimestamp.compareTo(b.sortTimestamp));
    emit(state.copyWith(bookings: updatedList));
  }

  Future<void> fetchMyBookings() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true));
    try {
      final fetched = await _remoteDataSource.fetchMyBookings();
      if (isClosed) return;

      final upcomingOnly = fetched.where((b) => b.isUpcoming).toList()
        ..sort((a, b) => a.sortTimestamp.compareTo(b.sortTimestamp));

      for (final b in upcomingOnly) {
        if (!b.isPending) {
          _respondedBookingIds.add(b.id);
          unawaited(_notificationService.cancelBookingNotification(b.id));
        }
      }

      BookingEntity? nextIncoming = state.activeIncomingBooking;
      if (nextIncoming != null &&
          (!nextIncoming.isUpcoming ||
              (!state.openSheetInQueryMode &&
                  _respondedBookingIds.contains(nextIncoming.id)))) {
        nextIncoming = null;
      }

      if (nextIncoming == null) {
        final firstPending = upcomingOnly.where(
              (b) =>
          b.isPending &&
              !_respondedBookingIds.contains(b.id) &&
              !_minimizedBookingIds.contains(b.id),
        );
        if (firstPending.isNotEmpty) {
          nextIncoming = firstPending.first;
        }
      }

      if (nextIncoming != null) {
        unawaited(OverlayService.closeOverlay());
      }

      emit(
        state.copyWith(
          bookings: upcomingOnly,
          activeIncomingBooking: nextIncoming,
          clearActiveIncoming: nextIncoming == null,
          openSheetInQueryMode:
          nextIncoming == null ? false : state.openSheetInQueryMode,
          isLoading: false,
        ),
      );
    } catch (e) {
      debugPrint('Fetch bookings error: $e');
      if (!isClosed) {
        emit(state.copyWith(isLoading: false));
      }
    }
  }

  /// Opens the booking sheet for pending rides OR confirmed/queried rides (in query mode).
  void openBookingCard(
      BookingEntity booking, {
        bool startInQueryMode = false,
      }) {
    if (!booking.isUpcoming || booking.isCancelled) {
      return;
    }
    _minimizedBookingIds.remove(booking.id);
    unawaited(OverlayService.closeOverlay());
    emit(
      state.copyWith(
        activeIncomingBooking: booking,
        openSheetInQueryMode: startInQueryMode || !booking.isPending,
        clearError: true,
      ),
    );
  }

  void minimizeBookingCard() {
    final current = state.activeIncomingBooking;
    if (current != null && current.isPending) {
      _minimizedBookingIds.add(current.id);
    }
    emit(
      state.copyWith(
        clearActiveIncoming: true,
        openSheetInQueryMode: false,
        clearError: true,
      ),
    );
  }

  Future<void> confirmBooking(String bookingId) async {
    if (isClosed) return;
    emit(state.copyWith(isSubmittingResponse: true, clearError: true));

    try {
      final updated = await _remoteDataSource.respondToBooking(
        bookingId: bookingId,
        action: 'confirm',
      );
      if (isClosed) return;

      _respondedBookingIds.add(bookingId);
      unawaited(_notificationService.cancelBookingNotification(bookingId));
      unawaited(OverlayService.closeOverlay());
      _upsertBookingInList(updated);
      emit(
        state.copyWith(
          isSubmittingResponse: false,
          clearActiveIncoming: true,
          openSheetInQueryMode: false,
          snackBarMessage: 'Ride confirmed with your manager!',
        ),
      );
    } on BookingException catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isSubmittingResponse: false,
            errorMessage: e.message,
          ),
        );
      }
    }
  }

  Future<void> raiseQuery({
    required String bookingId,
    required String queryText,
  }) async {
    final trimmed = queryText.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(errorMessage: 'Please enter your query first.'));
      return;
    }

    if (isClosed) return;
    emit(state.copyWith(isSubmittingResponse: true, clearError: true));

    try {
      final updated = await _remoteDataSource.respondToBooking(
        bookingId: bookingId,
        action: 'raise_query',
        queryText: trimmed,
      );
      if (isClosed) return;

      _respondedBookingIds.add(bookingId);
      unawaited(_notificationService.cancelBookingNotification(bookingId));
      unawaited(OverlayService.closeOverlay());
      _upsertBookingInList(updated);
      emit(
        state.copyWith(
          isSubmittingResponse: false,
          clearActiveIncoming: true,
          openSheetInQueryMode: false,
          navigateToManagerChat: true,
          snackBarMessage: 'Query sent to your manager chat.',
        ),
      );
    } on BookingException catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isSubmittingResponse: false,
            errorMessage: e.message,
          ),
        );
      }
    }
  }

  void consumeNavigation() {
    emit(state.copyWith(navigateToManagerChat: false, clearSnackBar: true));
  }

  @override
  Future<void> close() {
    _expiryPruningTimer?.cancel();
    _bookingAssignedSub?.cancel();
    _bookingUpdatedSub?.cancel();
    _bookingReallocatedSub?.cancel();
    _foregroundFcmSub?.cancel();
    _openedFcmSub?.cancel();
    _localTapSub?.cancel();
    return super.close();
  }
}