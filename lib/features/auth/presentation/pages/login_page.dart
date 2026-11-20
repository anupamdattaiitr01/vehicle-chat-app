import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginPage extends StatefulWidget {
  final int pendingTabIndex;
  final Map<String, dynamic>? pendingBookingData;

  const LoginPage({
    super.key,
    this.pendingTabIndex = 0,
    this.pendingBookingData,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _localValidationError = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    FocusScope.of(context).unfocus();
    final digitsOnlyPhone =
    _phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (digitsOnlyPhone.length != 10) {
      setState(() {
        _localValidationError = 'Phone number must be exactly 10 digits.';
      });
      return;
    }

    if (_localValidationError.isNotEmpty) {
      setState(() => _localValidationError = '');
    }

    context.read<AuthCubit>().submitLogin(
      phone: digitsOnlyPhone,
      password: _passwordController.text,
      pendingTabIndex: widget.pendingTabIndex,
      pendingBookingData: widget.pendingBookingData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final milo = context.milo;
    final isDark = context.isDarkMode;

    return Scaffold(
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
        child: SafeArea(
          child: BlocConsumer<AuthCubit, AuthState>(
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
                    initialBookingData: state.initialBookingData,
                  ),
                );
              }
            },
            builder: (context, state) {
              final formState =
              state is AuthFormState ? state : const AuthFormState();
              final displayedError = _localValidationError.isNotEmpty
                  ? _localValidationError
                  : formState.errorMessage;
              final isPhoneValid = _phoneController.text.length == 10;

              return Column(
                children: [
                  // Top-right Dark / Light Mode Pill Toggle
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ThemePillToggle(
                          isDark: isDark,
                          onSelectDark: () => context
                              .read<ThemeCubit>()
                              .setThemeMode(ThemeMode.dark),
                          onSelectLight: () => context
                              .read<ThemeCubit>()
                              .setThemeMode(ThemeMode.light),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 16,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: milo.cardBackground,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: milo.cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.35 : 0.06,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Milo Drive Logo Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAF7F8),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color:
                                      milo.burgundy.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Image.asset(
                                    AppTheme.logoAssetPath,
                                    height: 52,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 22),

                                Text(
                                  'Driver Sign In',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: milo.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Enter the 10-digit phone number & password assigned by your manager',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: milo.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                if (displayedError.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 11,
                                    ),
                                    margin: const EdgeInsets.only(bottom: 18),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF36161C)
                                          : const Color(0xFFFDECEA),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE74C3C)
                                            .withValues(alpha: 0.45),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: Color(0xFFE74C3C),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            displayedError,
                                            style: TextStyle(
                                              color: isDark
                                                  ? const Color(0xFFFF8A80)
                                                  : const Color(0xFFC0392B),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  maxLength: 10,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  onChanged: (_) {
                                    setState(() {
                                      if (_localValidationError.isNotEmpty &&
                                          _phoneController.text.length == 10) {
                                        _localValidationError = '';
                                      }
                                    });
                                  },
                                  style: TextStyle(
                                    color: milo.textPrimary,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Phone Number',
                                    hintText: '10-digit mobile number',
                                    counterText:
                                    '${_phoneController.text.length}/10',
                                    prefixIcon: Icon(
                                      Icons.phone_outlined,
                                      color: milo.textSecondary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _onSubmit(),
                                  style: TextStyle(
                                    color: milo.textPrimary,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(
                                      Icons.lock_outline_rounded,
                                      color: milo.textSecondary,
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: milo.textSecondary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed:
                                    formState.isSubmitting || !isPhoneValid
                                        ? null
                                        : _onSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: milo.burgundy,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: milo.burgundy
                                          .withValues(alpha: 0.4),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: formState.isSubmitting
                                        ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                        : const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),

                                Text(
                                  'Accounts are provisioned by your fleet manager.\nContact your manager if you need access.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: milo.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ThemePillToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onSelectDark;
  final VoidCallback onSelectLight;

  const _ThemePillToggle({
    required this.isDark,
    required this.onSelectDark,
    required this.onSelectLight,
  });

  @override
  Widget build(BuildContext context) {
    final milo = context.milo;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: milo.cardBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: milo.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(
            label: 'Dark',
            selected: isDark,
            milo: milo,
            onTap: onSelectDark,
          ),
          _segment(
            label: 'Light',
            selected: !isDark,
            milo: milo,
            onTap: onSelectLight,
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required bool selected,
    required MiloColors milo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? milo.burgundy : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : milo.textSecondary,
          ),
        ),
      ),
    );
  }
}