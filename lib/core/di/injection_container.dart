import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_managers_usecase.dart';
import '../../features/auth/domain/usecases/login_driver_usecase.dart';
import '../../features/auth/domain/usecases/logout_driver_usecase.dart';
import '../../features/auth/domain/usecases/register_driver_usecase.dart';
import '../../features/auth/domain/usecases/restore_session_usecase.dart';
import '../../features/auth/domain/usecases/sync_fcm_token_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/chat/data/datasources/chat_remote_datasource.dart';
import '../../features/chat/data/datasources/chat_socket_datasource.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/domain/usecases/get_message_history_usecase.dart';
import '../../features/chat/domain/usecases/get_my_rooms_usecase.dart';
import '../../features/chat/domain/usecases/join_room_usecase.dart';
import '../../features/chat/domain/usecases/leave_room_usecase.dart';
import '../../features/chat/domain/usecases/send_message_usecase.dart';
import '../../features/chat/presentation/cubit/chat_cubit.dart';
import '../network/dio_client.dart';
import '../services/notification_service.dart';
import '../services/socket_service.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton<FlutterSecureStorage>(
        () => const FlutterSecureStorage(),
  );
  sl.registerLazySingleton<DioClient>(() => DioClient(sl()));
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<SocketService>(() => SocketService());

  // Auth Feature - Data Sources
  sl.registerLazySingleton<AuthLocalDataSource>(
        () => AuthLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(sl()),
  );

  // Auth Feature - Repository
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Auth Feature - Use Cases
  sl.registerLazySingleton(() => RestoreSessionUseCase(sl()));
  sl.registerLazySingleton(() => LoginDriverUseCase(sl()));
  sl.registerLazySingleton(() => RegisterDriverUseCase(sl()));
  sl.registerLazySingleton(() => GetManagersUseCase(sl()));
  sl.registerLazySingleton(() => SyncFcmTokenUseCase(sl()));
  sl.registerLazySingleton(() => LogoutDriverUseCase(sl()));

  // Auth Feature - Cubit
  sl.registerFactory(
        () => AuthCubit(
      restoreSessionUseCase: sl(),
      loginDriverUseCase: sl(),
      registerDriverUseCase: sl(),
      getManagersUseCase: sl(),
      notificationService: sl(),
    ),
  );

  // Chat Feature - Data Sources
  sl.registerLazySingleton<ChatRemoteDataSource>(
        () => ChatRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ChatSocketDataSource>(
        () => ChatSocketDataSourceImpl(sl()),
  );

  // Chat Feature - Repository
  sl.registerLazySingleton<ChatRepository>(
        () => ChatRepositoryImpl(
      remoteDataSource: sl(),
      socketDataSource: sl(),
    ),
  );

  // Chat Feature - Use Cases
  sl.registerLazySingleton(() => GetMyRoomsUseCase(sl()));
  sl.registerLazySingleton(() => GetMessageHistoryUseCase(sl()));
  sl.registerLazySingleton(() => JoinRoomUseCase(sl()));
  sl.registerLazySingleton(() => LeaveRoomUseCase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));

  // Chat Feature - Cubit
  sl.registerFactory(
        () => ChatCubit(
      chatRepository: sl(),
      getMyRoomsUseCase: sl(),
      getMessageHistoryUseCase: sl(),
      joinRoomUseCase: sl(),
      leaveRoomUseCase: sl(),
      sendMessageUseCase: sl(),
      syncFcmTokenUseCase: sl(),
      logoutDriverUseCase: sl(),
      notificationService: sl(),
    ),
  );
}