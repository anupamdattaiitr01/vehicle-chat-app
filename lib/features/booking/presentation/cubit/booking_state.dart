import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_entity.dart';

class BookingState extends Equatable {
  final List<BookingEntity> bookings;
  final BookingEntity? activeIncomingBooking;
  final bool openSheetInQueryMode;
  final bool isLoading;
  final bool isSubmittingResponse;
  final String? errorMessage;
  final String? snackBarMessage;
  final bool navigateToManagerChat;

  const BookingState({
    this.bookings = const [],
    this.activeIncomingBooking,
    this.openSheetInQueryMode = false,
    this.isLoading = false,
    this.isSubmittingResponse = false,
    this.errorMessage,
    this.snackBarMessage,
    this.navigateToManagerChat = false,
  });

  List<BookingEntity> get upcomingBookings {
    final upcoming = bookings.where((b) => b.isUpcoming).toList();
    upcoming.sort((a, b) => a.sortTimestamp.compareTo(b.sortTimestamp));
    return upcoming;
  }

  BookingEntity? get latestBooking => upcomingBookings.isNotEmpty
      ? upcomingBookings.first
      : (bookings.isNotEmpty ? bookings.first : null);

  BookingState copyWith({
    List<BookingEntity>? bookings,
    BookingEntity? activeIncomingBooking,
    bool clearActiveIncoming = false,
    bool? openSheetInQueryMode,
    bool? isLoading,
    bool? isSubmittingResponse,
    String? errorMessage,
    bool clearError = false,
    String? snackBarMessage,
    bool clearSnackBar = false,
    bool? navigateToManagerChat,
  }) {
    return BookingState(
      bookings: bookings ?? this.bookings,
      activeIncomingBooking: clearActiveIncoming
          ? null
          : (activeIncomingBooking ?? this.activeIncomingBooking),
      openSheetInQueryMode: openSheetInQueryMode ?? this.openSheetInQueryMode,
      isLoading: isLoading ?? this.isLoading,
      isSubmittingResponse: isSubmittingResponse ?? this.isSubmittingResponse,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      snackBarMessage:
      clearSnackBar ? null : (snackBarMessage ?? this.snackBarMessage),
      navigateToManagerChat:
      navigateToManagerChat ?? this.navigateToManagerChat,
    );
  }

  @override
  List<Object?> get props => [
    bookings,
    activeIncomingBooking,
    openSheetInQueryMode,
    isLoading,
    isSubmittingResponse,
    errorMessage,
    snackBarMessage,
    navigateToManagerChat,
  ];
}