import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(
            AppRouter.chat,
            extra: ChatRouteArgs(
              driverId: state.driver.id,
              driverName: state.driver.name,
              token: state.driver.token,
              initialTabIndex: state.initialTabIndex,
              initialRoomId: state.initialRoomId,
            ),
          );
        } else if (state is AuthUnauthenticated) {
          context.go(
            AppRouter.login,
            extra: LoginRouteArgs(pendingTabIndex: state.pendingTabIndex),
          );
        }
      },
      child: const Scaffold(
        backgroundColor: Color(0xFFECF0F1),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_car, size: 64, color: Color(0xFF2C3E50)),
              SizedBox(height: 16),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}