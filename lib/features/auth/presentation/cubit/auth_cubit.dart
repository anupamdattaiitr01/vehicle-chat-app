import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../domain/usecases/get_managers_usecase.dart';
import '../../domain/usecases/login_driver_usecase.dart';
import '../../domain/usecases/register_driver_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final RestoreSessionUseCase _restoreSessionUseCase;
  final LoginDriverUseCase _loginDriverUseCase;
  final RegisterDriverUseCase _registerDriverUseCase;
  final GetManagersUseCase _getManagersUseCase;
  final NotificationService _notificationService;

  AuthCubit({
    required this._restoreSessionUseCase,
    required this._loginDriverUseCase,
    required this._registerDriverUseCase,
    required this._getManagersUseCase,
    required this._notificationService,
  }) : super(const AuthInitial());

  Future<void> checkSessionAndNotification() async {
    emit(const AuthSessionChecking());
    try {
      final initialMessage = await _notificationService.getInitialMessage();
      final initialRoomType = initialMessage?.data['roomType']?.toString();
      final initialTab = AppConstants.tabIndexFromRoomType(initialRoomType);

      final driver = await _restoreSessionUseCase();

      if (driver != null) {
        emit(
          AuthAuthenticated(
            driver: driver,
            initialTabIndex: initialTab,
            initialRoomId: initialMessage?.data['roomId']?.toString(),
          ),
        );
      } else {
        emit(
          AuthUnauthenticated(
            pendingTabIndex: initialMessage != null ? initialTab : 0,
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

  Future<void> fetchManagers() async {
    final current = _currentFormState;
    emit(current.copyWith(isLoadingManagers: true));

    try {
      final managers = await _getManagersUseCase();
      String? nextSelectedId = current.selectedManagerId;

      if (managers.isNotEmpty &&
          !managers.any((m) => m.id == nextSelectedId)) {
        nextSelectedId = managers.first.id;
      }

      emit(
        _currentFormState.copyWith(
          isLoadingManagers: false,
          managers: managers,
          selectedManagerId: nextSelectedId,
        ),
      );
    } catch (e) {
      debugPrint('Failed to load managers: $e');
      emit(_currentFormState.copyWith(isLoadingManagers: false));
    }
  }

  void toggleAuthMode() {
    final current = _currentFormState;
    final nextIsRegister = !current.isRegisterMode;

    emit(
      current.copyWith(
        isRegisterMode: nextIsRegister,
        errorMessage: '',
        successMessage: '',
      ),
    );

    if (nextIsRegister) {
      fetchManagers();
    }
  }

  void selectManager(String? managerId) {
    emit(_currentFormState.copyWith(selectedManagerId: managerId));
  }

  Future<void> submitAuth({
    required String name,
    required String phone,
    required String password,
    int pendingTabIndex = 0,
  }) async {
    final current = _currentFormState;
    emit(
      current.copyWith(
        isSubmitting: true,
        errorMessage: '',
        successMessage: '',
      ),
    );

    if (current.isRegisterMode) {
      if (name.trim().isEmpty ||
          phone.trim().isEmpty ||
          password.trim().isEmpty) {
        emit(
          _currentFormState.copyWith(
            isSubmitting: false,
            errorMessage: 'Please fill in all fields.',
          ),
        );
        return;
      }

      final managerId = current.selectedManagerId;
      if (managerId == null || managerId.isEmpty) {
        emit(
          _currentFormState.copyWith(
            isSubmitting: false,
            errorMessage: 'Please select your assigned manager.',
          ),
        );
        return;
      }

      try {
        await _registerDriverUseCase(
          name: name,
          phone: phone,
          password: password,
          managerId: managerId,
        );

        emit(
          _currentFormState.copyWith(
            isSubmitting: false,
            isRegisterMode: false,
            successMessage: 'Driver registered! Please log in.',
            shouldClearPassword: true,
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
    } else {
      try {
        final driver = await _loginDriverUseCase(
          phone: phone,
          password: password,
        );

        emit(
          AuthAuthenticated(
            driver: driver,
            initialTabIndex: pendingTabIndex,
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
}