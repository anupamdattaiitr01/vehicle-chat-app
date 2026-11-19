import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_entity.dart';

class BookingState extends Equatable {
  final List<BookingEntity> bookings;
  final BookingEntity? activeIncomingBooking;
  final bool isLoading;
  final bool isSubmittingResponse;
  final String? errorMessage;
  final String? snackBarMessage;
  final bool navigateToManagerChat;

  const BookingState({
    this.bookings = const [],
    this.activeIncomingBooking,
    this.isLoading = false,
    this.isSubmittingResponse = false,
    this.errorMessage,
    this.snackBarMessage,
    this.navigateToManagerChat = false,
  });

  BookingEntity? get latestBooking =>
      bookings.isNotEmpty ? bookings.first : null;

  BookingState copyWith({
    List<BookingEntity>? bookings,
    BookingEntity? activeIncomingBooking,
    bool clearActiveIncoming = false,
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
    isLoading,
    isSubmittingResponse,
    errorMessage,
    snackBarMessage,
    navigateToManagerChat,
  ];
}