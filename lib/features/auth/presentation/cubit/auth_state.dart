import 'package:equatable/equatable.dart';
import '../../domain/entities/driver_entity.dart';
import '../../domain/entities/manager_entity.dart';

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

  const AuthAuthenticated({
    required this.driver,
    this.initialTabIndex = 0,
    this.initialRoomId,
  });

  @override
  List<Object?> get props => [driver, initialTabIndex, initialRoomId];
}

class AuthUnauthenticated extends AuthState {
  final int pendingTabIndex;

  const AuthUnauthenticated({this.pendingTabIndex = 0});

  @override
  List<Object?> get props => [pendingTabIndex];
}

class AuthFormState extends AuthState {
  final bool isRegisterMode;
  final bool isSubmitting;
  final bool isLoadingManagers;
  final List<ManagerEntity> managers;
  final String? selectedManagerId;
  final String errorMessage;
  final String successMessage;
  final bool shouldClearPassword;

  const AuthFormState({
    this.isRegisterMode = false,
    this.isSubmitting = false,
    this.isLoadingManagers = false,
    this.managers = const [],
    this.selectedManagerId,
    this.errorMessage = '',
    this.successMessage = '',
    this.shouldClearPassword = false,
  });

  AuthFormState copyWith({
    bool? isRegisterMode,
    bool? isSubmitting,
    bool? isLoadingManagers,
    List<ManagerEntity>? managers,
    String? selectedManagerId,
    String? errorMessage,
    String? successMessage,
    bool? shouldClearPassword,
  }) {
    return AuthFormState(
      isRegisterMode: isRegisterMode ?? this.isRegisterMode,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoadingManagers: isLoadingManagers ?? this.isLoadingManagers,
      managers: managers ?? this.managers,
      selectedManagerId: selectedManagerId ?? this.selectedManagerId,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      shouldClearPassword: shouldClearPassword ?? false,
    );
  }

  @override
  List<Object?> get props => [
    isRegisterMode,
    isSubmitting,
    isLoadingManagers,
    managers,
    selectedManagerId,
    errorMessage,
    successMessage,
    shouldClearPassword,
  ];
}