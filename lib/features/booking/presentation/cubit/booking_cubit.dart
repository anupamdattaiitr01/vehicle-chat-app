import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notification_service.dart';
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
  StreamSubscription<RemoteMessage>? _foregroundFcmSub;
  StreamSubscription<RemoteMessage>? _openedFcmSub;
  StreamSubscription<NotificationData>? _localTapSub;

  final Set<String> _minimizedBookingIds = <String>{};

  BookingCubit({
    required this._remoteDataSource,
    required this._socketService,
    required this._notificationService,
  }) : super(const BookingState());

  void initialize({Map<String, dynamic>? initialBookingData}) {
    BookingEntity? initialIncoming;
    if (initialBookingData != null &&
        initialBookingData['type'] == 'BOOKING_ASSIGNED') {
      initialIncoming = BookingEntity.fromMap(initialBookingData);
      if (initialIncoming.id.isEmpty) {
        initialIncoming = null;
      }
    }

    if (initialIncoming != null) {
      emit(
        state.copyWith(
          activeIncomingBooking: initialIncoming,
          bookings: [initialIncoming],
        ),
      );
    }

    _bindRealtimeStreams();
    fetchMyBookings();
  }

  void _bindRealtimeStreams() {
    _bookingAssignedSub?.cancel();
    _bookingAssignedSub = _socketService.bookingAssignedStream.listen((data) {
      final booking = BookingEntity.fromMap(data);
      if (booking.id.isEmpty) return;
      _handleIncomingBooking(booking);
    });

    _bookingUpdatedSub?.cancel();
    _bookingUpdatedSub = _socketService.bookingUpdatedStream.listen((data) {
      final updated = BookingEntity.fromMap(data);
      if (updated.id.isEmpty) return;
      _upsertBookingInList(updated);
    });

    _foregroundFcmSub?.cancel();
    _foregroundFcmSub =
        _notificationService.onForegroundMessage.listen((RemoteMessage msg) {
          if (msg.data['type'] == 'BOOKING_ASSIGNED') {
            final booking = BookingEntity.fromMap(msg.data);
            if (booking.id.isNotEmpty) {
              _handleIncomingBooking(booking);
            }
          }
        });

    _openedFcmSub?.cancel();
    _openedFcmSub =
        _notificationService.onMessageOpenedApp.listen((RemoteMessage msg) {
          if (msg.data['type'] == 'BOOKING_ASSIGNED') {
            final booking = BookingEntity.fromMap(msg.data);
            if (booking.id.isNotEmpty) {
              _minimizedBookingIds.remove(booking.id);
              _handleIncomingBooking(booking);
            }
          }
        });

    _localTapSub?.cancel();
    _localTapSub =
        _notificationService.onLocalNotificationTap.listen((NotificationData data) {
          if (data['type'] == 'BOOKING_ASSIGNED') {
            final booking = BookingEntity.fromMap(data);
            if (booking.id.isNotEmpty) {
              _minimizedBookingIds.remove(booking.id);
              _handleIncomingBooking(booking);
            }
          }
        });
  }

  void _handleIncomingBooking(BookingEntity booking) {
    if (isClosed) return;
    _upsertBookingInList(booking);

    if (booking.isPending && !_minimizedBookingIds.contains(booking.id)) {
      emit(
        state.copyWith(
          activeIncomingBooking: booking,
          clearError: true,
        ),
      );
    }
  }

  void _upsertBookingInList(BookingEntity booking) {
    final existingIdx = state.bookings.indexWhere((b) => b.id == booking.id);
    final updatedList = List<BookingEntity>.from(state.bookings);
    if (existingIdx >= 0) {
      updatedList[existingIdx] = booking;
    } else {
      updatedList.insert(0, booking);
    }
    emit(state.copyWith(bookings: updatedList));
  }

  Future<void> fetchMyBookings() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true));
    try {
      final fetched = await _remoteDataSource.fetchMyBookings();
      if (isClosed) return;

      BookingEntity? nextIncoming = state.activeIncomingBooking;
      if (nextIncoming == null) {
        final firstPending = fetched.where(
              (b) => b.isPending && !_minimizedBookingIds.contains(b.id),
        );
        if (firstPending.isNotEmpty) {
          nextIncoming = firstPending.first;
        }
      }

      emit(
        state.copyWith(
          bookings: fetched,
          activeIncomingBooking: nextIncoming,
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

  void openBookingCard(BookingEntity booking) {
    _minimizedBookingIds.remove(booking.id);
    emit(
      state.copyWith(
        activeIncomingBooking: booking,
        clearError: true,
      ),
    );
  }

  void minimizeBookingCard() {
    final current = state.activeIncomingBooking;
    if (current != null) {
      _minimizedBookingIds.add(current.id);
    }
    emit(state.copyWith(clearActiveIncoming: true, clearError: true));
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

      _upsertBookingInList(updated);
      emit(
        state.copyWith(
          isSubmittingResponse: false,
          clearActiveIncoming: true,
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

      _upsertBookingInList(updated);
      emit(
        state.copyWith(
          isSubmittingResponse: false,
          clearActiveIncoming: true,
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
    _bookingAssignedSub?.cancel();
    _bookingUpdatedSub?.cancel();
    _foregroundFcmSub?.cancel();
    _openedFcmSub?.cancel();
    _localTapSub?.cancel();
    return super.close();
  }
}