import 'package:equatable/equatable.dart';
import '../../domain/entities/driver_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthSessionChecking extends AuthState {
  const AuthSessionChecking();
}

class AuthAuthenticated extends AuthState {
  final DriverEntity driver;
  final int initialTabIndex;
  final String? initialRoomId;
  final Map<String, dynamic>? initialBookingData;

  const AuthAuthenticated({
    required this.driver,
    this.initialTabIndex = 0,
    this.initialRoomId,
    this.initialBookingData,
  });

  @override
  List<Object?> get props => [
    driver,
    initialTabIndex,
    initialRoomId,
    initialBookingData,
  ];
}

class AuthUnauthenticated extends AuthState {
  final int pendingTabIndex;
  final Map<String, dynamic>? pendingBookingData;

  const AuthUnauthenticated({
    this.pendingTabIndex = 0,
    this.pendingBookingData,
  });

  @override
  List<Object?> get props => [pendingTabIndex, pendingBookingData];
}

class AuthFormState extends AuthState {
  final bool isSubmitting;
  final String errorMessage;

  const AuthFormState({
    this.isSubmitting = false,
    this.errorMessage = '',
  });

  AuthFormState copyWith({
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return AuthFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isSubmitting, errorMessage];
}