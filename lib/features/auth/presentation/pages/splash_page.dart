import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final milo = context.milo;

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
      child: Scaffold(
        backgroundColor: milo.scaffoldBackground,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.85, -0.85),
              radius: 1.35,
              colors: [
                milo.radialGlow,
                milo.scaffoldBackground,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F8),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: milo.burgundy.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: milo.burgundy.withValues(alpha: 0.22),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    AppTheme.logoAssetPath,
                    height: 64,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'FLEET DRIVER PORTAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                    color: milo.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: milo.burgundyLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}