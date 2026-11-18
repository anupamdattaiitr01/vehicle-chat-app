import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/chat/presentation/cubit/chat_cubit.dart';
import '../../features/chat/presentation/pages/driver_chat_page.dart';
import '../di/injection_container.dart';

class LoginRouteArgs {
  final int pendingTabIndex;

  const LoginRouteArgs({this.pendingTabIndex = 0});
}

class ChatRouteArgs {
  final String driverId;
  final String driverName;
  final String token;
  final int initialTabIndex;
  final String? initialRoomId;

  const ChatRouteArgs({
    required this.driverId,
    required this.driverName,
    required this.token,
    this.initialTabIndex = 0,
    this.initialRoomId,
  });
}

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String login = '/login';
  static const String chat = '/chat';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthCubit>()..checkSessionAndNotification(),
          child: const SplashPage(),
        ),
      ),
      GoRoute(
        path: login,
        builder: (context, state) {
          final args = state.extra is LoginRouteArgs
              ? state.extra as LoginRouteArgs
              : const LoginRouteArgs();
          return BlocProvider(
            create: (_) => sl<AuthCubit>(),
            child: LoginPage(pendingTabIndex: args.pendingTabIndex),
          );
        },
      ),
      GoRoute(
        path: chat,
        builder: (context, state) {
          final args = state.extra as ChatRouteArgs;
          return BlocProvider(
            create: (_) => sl<ChatCubit>()..initialize(args),
            child: DriverChatPage(args: args),
          );
        },
      ),
    ],
  );
}