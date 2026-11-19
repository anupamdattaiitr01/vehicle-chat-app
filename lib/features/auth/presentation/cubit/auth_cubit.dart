import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../domain/usecases/login_driver_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final RestoreSessionUseCase _restoreSessionUseCase;
  final LoginDriverUseCase _loginDriverUseCase;
  final NotificationService _notificationService;

  AuthCubit({
    required this._restoreSessionUseCase,
    required this._loginDriverUseCase,
    required this._notificationService,
  }) : super(const AuthInitial());

  Future<void> checkSessionAndNotification() async {
    emit(const AuthSessionChecking());
    try {
      final initialLocalData =
      _notificationService.consumeInitialLocalNotification();
      final initialFcmMessage = await _notificationService.getInitialMessage();

      final Map<String, dynamic>? launchData =
          initialLocalData ?? initialFcmMessage?.data;

      final isBookingLaunch = launchData?['type'] == 'BOOKING_ASSIGNED';
      final initialRoomType = launchData?['roomType']?.toString();
      final initialTab = AppConstants.tabIndexFromRoomType(initialRoomType);

      final driver = await _restoreSessionUseCase();

      if (driver != null) {
        emit(
          AuthAuthenticated(
            driver: driver,
            initialTabIndex: initialTab,
            initialRoomId: launchData?['roomId']?.toString(),
            initialBookingData: isBookingLaunch ? launchData : null,
          ),
        );
      } else {
        emit(
          AuthUnauthenticated(
            pendingTabIndex: launchData != null ? initialTab : 0,
            pendingBookingData: isBookingLaunch ? launchData : null,
          ),
        );
      }
    } catch (e) {
      debugPrint('Session restore error: $e');
      emit(const AuthUnauthenticated());
    }
  }

  AuthFormState get _currentFormState {
    final current = state;
    if (current is AuthFormState) return current;
    return const AuthFormState();
  }

  Future<void> submitLogin({
    required String phone,
    required String password,
    int pendingTabIndex = 0,
    Map<String, dynamic>? pendingBookingData,
  }) async {
    if (phone.trim().isEmpty || password.trim().isEmpty) {
      emit(
        _currentFormState.copyWith(
          isSubmitting: false,
          errorMessage: 'Please enter your phone number and password.',
        ),
      );
      return;
    }

    emit(
      _currentFormState.copyWith(
        isSubmitting: true,
        errorMessage: '',
      ),
    );

    try {
      final driver = await _loginDriverUseCase(
        phone: phone,
        password: password,
      );

      emit(
        AuthAuthenticated(
          driver: driver,
          initialTabIndex: pendingTabIndex,
          initialBookingData: pendingBookingData,
        ),
      );
    } on AuthException catch (e) {
      emit(
        _currentFormState.copyWith(
          isSubmitting: false,
          errorMessage: e.message,
        ),
      );
    }
  }
}