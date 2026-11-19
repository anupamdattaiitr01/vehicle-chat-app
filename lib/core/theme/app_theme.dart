import 'package:flutter/material.dart';

@immutable
class MiloColors extends ThemeExtension<MiloColors> {
  final Color burgundy;
  final Color burgundyLight;
  final Color scaffoldBackground;
  final Color radialGlow;
  final Color cardBackground;
  final Color cardBorder;
  final Color incomingBubble;
  final Color outgoingBubble;
  final Color textPrimary;
  final Color textSecondary;
  final Color inputFill;
  final Color badgeAmberBg;
  final Color badgeAmberText;
  final Color onlineGreen;

  const MiloColors({
    required this.burgundy,
    required this.burgundyLight,
    required this.scaffoldBackground,
    required this.radialGlow,
    required this.cardBackground,
    required this.cardBorder,
    required this.incomingBubble,
    required this.outgoingBubble,
    required this.textPrimary,
    required this.textSecondary,
    required this.inputFill,
    required this.badgeAmberBg,
    required this.badgeAmberText,
    required this.onlineGreen,
  });

  static const dark = MiloColors(
    burgundy: Color(0xFF6E1D3D),
    burgundyLight: Color(0xFF9E335D),
    scaffoldBackground: Color(0xFF121012),
    radialGlow: Color(0xFF3A1122),
    cardBackground: Color(0xFF1D191C),
    cardBorder: Color(0xFF2E282C),
    incomingBubble: Color(0xFF231F22),
    outgoingBubble: Color(0xFF6E1D3D),
    textPrimary: Color(0xFFF5F2F4),
    textSecondary: Color(0xFF9E9599),
    inputFill: Color(0xFF1E1A1D),
    badgeAmberBg: Color(0xFF332614),
    badgeAmberText: Color(0xFFE5A93C),
    onlineGreen: Color(0xFF2ECC71),
  );

  static const light = MiloColors(
    burgundy: Color(0xFF6E1D3D),
    burgundyLight: Color(0xFF8C2850),
    scaffoldBackground: Color(0xFFFAF7F8),
    radialGlow: Color(0xFFF2DFE6),
    cardBackground: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFEAE2E5),
    incomingBubble: Color(0xFFEFEAEC),
    outgoingBubble: Color(0xFF6E1D3D),
    textPrimary: Color(0xFF181416),
    textSecondary: Color(0xFF736A6E),
    inputFill: Color(0xFFF3EEF0),
    badgeAmberBg: Color(0xFFFEF3DC),
    badgeAmberText: Color(0xFFB57816),
    onlineGreen: Color(0xFF27AE60),
  );

  @override
  MiloColors copyWith({
    Color? burgundy,
    Color? burgundyLight,
    Color? scaffoldBackground,
    Color? radialGlow,
    Color? cardBackground,
    Color? cardBorder,
    Color? incomingBubble,
    Color? outgoingBubble,
    Color? textPrimary,
    Color? textSecondary,
    Color? inputFill,
    Color? badgeAmberBg,
    Color? badgeAmberText,
    Color? onlineGreen,
  }) {
    return MiloColors(
      burgundy: burgundy ?? this.burgundy,
      burgundyLight: burgundyLight ?? this.burgundyLight,
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      radialGlow: radialGlow ?? this.radialGlow,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      incomingBubble: incomingBubble ?? this.incomingBubble,
      outgoingBubble: outgoingBubble ?? this.outgoingBubble,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      inputFill: inputFill ?? this.inputFill,
      badgeAmberBg: badgeAmberBg ?? this.badgeAmberBg,
      badgeAmberText: badgeAmberText ?? this.badgeAmberText,
      onlineGreen: onlineGreen ?? this.onlineGreen,
    );
  }

  @override
  MiloColors lerp(ThemeExtension<MiloColors>? other, double t) {
    if (other is! MiloColors) return this;
    return MiloColors(
      burgundy: Color.lerp(burgundy, other.burgundy, t)!,
      burgundyLight: Color.lerp(burgundyLight, other.burgundyLight, t)!,
      scaffoldBackground:
      Color.lerp(scaffoldBackground, other.scaffoldBackground, t)!,
      radialGlow: Color.lerp(radialGlow, other.radialGlow, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      incomingBubble: Color.lerp(incomingBubble, other.incomingBubble, t)!,
      outgoingBubble: Color.lerp(outgoingBubble, other.outgoingBubble, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      badgeAmberBg: Color.lerp(badgeAmberBg, other.badgeAmberBg, t)!,
      badgeAmberText: Color.lerp(badgeAmberText, other.badgeAmberText, t)!,
      onlineGreen: Color.lerp(onlineGreen, other.onlineGreen, t)!,
    );
  }
}

extension MiloThemeContext on BuildContext {
  MiloColors get milo =>
      Theme.of(this).extension<MiloColors>() ?? MiloColors.dark;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

class AppTheme {
  AppTheme._();

  static const String logoAssetPath = 'assets/images/milo_logo.png';

  static ThemeData get darkTheme {
    const colors = MiloColors.dark;
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: colors.scaffoldBackground,
      colorScheme: ColorScheme.dark(
        primary: colors.burgundy,
        secondary: colors.burgundyLight,
        surface: colors.cardBackground,
        onPrimary: Colors.white,
        onSurface: colors.textPrimary,
      ),
      extensions: const [colors],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        hintStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
        labelStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.burgundyLight, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    const colors = MiloColors.light;
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: colors.scaffoldBackground,
      colorScheme: ColorScheme.light(
        primary: colors.burgundy,
        secondary: colors.burgundyLight,
        surface: colors.cardBackground,
        onPrimary: Colors.white,
        onSurface: colors.textPrimary,
      ),
      extensions: const [colors],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        hintStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
        labelStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.burgundy, width: 1.5),
        ),
      ),
    );
  }
}