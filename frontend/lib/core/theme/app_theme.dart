import 'package:flutter/material.dart';

/// MedAID global design system: the ONLY theme source in the app (D-004).
///
/// Screens and widgets read visual values through [Theme.of], the
/// [AppThemeContext] extension, or the token classes below. Never hardcode
/// colors, radii or text styles elsewhere. If a new token is needed, add it
/// here.

// ---------------------------------------------------------------------------
// Color tokens
// ---------------------------------------------------------------------------

abstract final class AppColors {
  // Brand: calm healthcare teal.
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primaryContainer = Color(0xFFD7F3EE);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF053B35);

  // Secondary: strong dark accent for neutral CTAs.
  static const Color secondary = Color(0xFF1E293B);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE2E8F0);
  static const Color onSecondaryContainer = Color(0xFF0F172A);

  // Emergency (SOS): reserved for emergency actions and states only.
  static const Color emergency = Color(0xFFE11D48);
  static const Color emergencyDark = Color(0xFFBE123C);
  static const Color emergencyContainer = Color(0xFFFFE4E9);
  static const Color onEmergency = Color(0xFFFFFFFF);
  static const Color onEmergencyContainer = Color(0xFF881337);

  // Status
  static const Color success = Color(0xFF15803D);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFB45309);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF1D4ED8);
  static const Color infoContainer = Color(0xFFDBEAFE);
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF7F1D1D);

  // Neutrals
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEF2F6);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color disabled = Color(0xFFCBD5E1);
  static const Color scrim = Color(0x800F172A);
  static const Color shadow = Color(0x140F172A);
  static const Color transparent = Color(0x00000000);
}

// ---------------------------------------------------------------------------
// Layout tokens
// ---------------------------------------------------------------------------

abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Horizontal padding used by every screen.
  static const double screen = 20;
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: screen);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
}

abstract final class AppRadii {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

abstract final class AppElevation {
  static const double none = 0;
  static const double low = 1;
  static const double medium = 4;
  static const double high = 8;
}

abstract final class AppSizes {
  static const double buttonHeight = 54;
  static const double buttonHeightCompact = 42;
  static const double minTouchTarget = 48;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;
  static const double iconHero = 56;
  static const double avatarSm = 36;
  static const double avatarMd = 48;
  static const double avatarLg = 72;
  static const double sosButton = 188;
  static const double bottomNavHeight = 72;
  static const double mapPreviewHeight = 220;
  static const double maxContentWidth = 560;
}

abstract final class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: AppColors.shadow, blurRadius: 18, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> emergencyGlow = [
    BoxShadow(color: Color(0x40E11D48), blurRadius: 36, spreadRadius: 6),
  ];
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  /// How long the SOS button must be held to trigger an alert (OQ-14).
  static const Duration sosHold = Duration(milliseconds: 1500);
}

// ---------------------------------------------------------------------------
// Semantic tones (status chips, banners, cards)
// ---------------------------------------------------------------------------

enum AppTone { neutral, brand, info, success, warning, danger, emergency }

/// Background/foreground pair for an [AppTone].
typedef ToneColors = ({Color background, Color foreground});

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.emergency,
    required this.emergencyDark,
    required this.onEmergency,
    required this.emergencyContainer,
    required this.onEmergencyContainer,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.info,
    required this.infoContainer,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.surfaceMuted,
  });

  final Color emergency;
  final Color emergencyDark;
  final Color onEmergency;
  final Color emergencyContainer;
  final Color onEmergencyContainer;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color info;
  final Color infoContainer;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color surfaceMuted;

  static const AppPalette light = AppPalette(
    emergency: AppColors.emergency,
    emergencyDark: AppColors.emergencyDark,
    onEmergency: AppColors.onEmergency,
    emergencyContainer: AppColors.emergencyContainer,
    onEmergencyContainer: AppColors.onEmergencyContainer,
    success: AppColors.success,
    successContainer: AppColors.successContainer,
    warning: AppColors.warning,
    warningContainer: AppColors.warningContainer,
    info: AppColors.info,
    infoContainer: AppColors.infoContainer,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    border: AppColors.border,
    surfaceMuted: AppColors.surfaceMuted,
  );

  ToneColors tone(AppTone tone) => switch (tone) {
    AppTone.neutral => (background: surfaceMuted, foreground: textSecondary),
    AppTone.brand => (
      background: AppColors.primaryContainer,
      foreground: AppColors.onPrimaryContainer,
    ),
    AppTone.info => (background: infoContainer, foreground: info),
    AppTone.success => (background: successContainer, foreground: success),
    AppTone.warning => (background: warningContainer, foreground: warning),
    AppTone.danger => (
      background: AppColors.errorContainer,
      foreground: AppColors.onErrorContainer,
    ),
    AppTone.emergency => (background: emergencyContainer, foreground: onEmergencyContainer),
  };

  @override
  AppPalette copyWith({
    Color? emergency,
    Color? emergencyDark,
    Color? onEmergency,
    Color? emergencyContainer,
    Color? onEmergencyContainer,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? info,
    Color? infoContainer,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? surfaceMuted,
  }) {
    return AppPalette(
      emergency: emergency ?? this.emergency,
      emergencyDark: emergencyDark ?? this.emergencyDark,
      onEmergency: onEmergency ?? this.onEmergency,
      emergencyContainer: emergencyContainer ?? this.emergencyContainer,
      onEmergencyContainer: onEmergencyContainer ?? this.onEmergencyContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      emergency: mix(emergency, other.emergency),
      emergencyDark: mix(emergencyDark, other.emergencyDark),
      onEmergency: mix(onEmergency, other.onEmergency),
      emergencyContainer: mix(emergencyContainer, other.emergencyContainer),
      onEmergencyContainer: mix(onEmergencyContainer, other.onEmergencyContainer),
      success: mix(success, other.success),
      successContainer: mix(successContainer, other.successContainer),
      warning: mix(warning, other.warning),
      warningContainer: mix(warningContainer, other.warningContainer),
      info: mix(info, other.info),
      infoContainer: mix(infoContainer, other.infoContainer),
      textSecondary: mix(textSecondary, other.textSecondary),
      textMuted: mix(textMuted, other.textMuted),
      border: mix(border, other.border),
      surfaceMuted: mix(surfaceMuted, other.surfaceMuted),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme
// ---------------------------------------------------------------------------

abstract final class AppTheme {
  /// Bundled font with Latin + Devanagari coverage (P-18).
  static const String fontFamily = 'Poppins';

  static const TextTheme textTheme = TextTheme(
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: AppColors.textPrimary,
    ),
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 30,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.3,
      color: AppColors.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.3,
      color: AppColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: AppColors.textPrimary,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.textPrimary,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: AppColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: AppColors.textPrimary,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.3,
      color: AppColors.textPrimary,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.3,
      color: AppColors.textSecondary,
    ),
  );

  static const ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.info,
    onTertiary: AppColors.onPrimary,
    error: AppColors.error,
    onError: AppColors.onPrimary,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerLowest: AppColors.surface,
    surfaceContainerLow: AppColors.background,
    surfaceContainer: AppColors.surfaceMuted,
    surfaceContainerHigh: AppColors.surfaceMuted,
    surfaceContainerHighest: AppColors.border,
    outline: AppColors.borderStrong,
    outlineVariant: AppColors.border,
    shadow: AppColors.shadow,
    scrim: AppColors.scrim,
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: AppColors.surface,
    inversePrimary: AppColors.primaryContainer,
    surfaceTint: AppColors.transparent,
  );

  /// The single light theme used by the whole app (built once).
  static final ThemeData light = _buildLight();

  static ThemeData _buildLight() {
    const pillShape = StadiumBorder();
    const buttonMinSize = Size(64, AppSizes.buttonHeight);
    const buttonPadding = EdgeInsets.symmetric(horizontal: AppSpacing.xxl);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: AppRadii.mdAll,
      borderSide: BorderSide(color: color, width: width),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.border,
      splashFactory: InkSparkle.splashFactory,
      extensions: const [AppPalette.light],
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: AppSizes.iconLg),
      appBarTheme: AppBarThemeData(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: AppColors.transparent,
        elevation: AppElevation.none,
        scrolledUnderElevation: AppElevation.none,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.surface,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: pillShape,
          textStyle: textTheme.labelLarge,
          elevation: AppElevation.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.surface,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: pillShape,
          textStyle: textTheme.labelLarge,
          elevation: AppElevation.none,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.surface,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: pillShape,
          side: const BorderSide(color: AppColors.borderStrong, width: 1.2),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: textTheme.labelLarge,
          shape: pillShape,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: pillShape,
        elevation: AppElevation.low,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.primary),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.error),
        errorMaxLines: 2,
        border: inputBorder(AppColors.border),
        enabledBorder: inputBorder(AppColors.border),
        disabledBorder: inputBorder(AppColors.border),
        focusedBorder: inputBorder(AppColors.primary, 1.6),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error, 1.6),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: AppElevation.none,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.lgAll,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.primaryContainer,
        disabledColor: AppColors.surfaceMuted,
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: AppColors.onPrimaryContainer),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        shape: pillShape,
        side: BorderSide.none,
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: AppElevation.none,
        height: AppSizes.bottomNavHeight,
        indicatorColor: AppColors.primaryContainer,
        indicatorShape: pillShape,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                )
              : textTheme.labelSmall,
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: AppSizes.iconLg,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.xlAll),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.borderStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.surface),
        actionTextColor: AppColors.primaryContainer,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondary,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceMuted,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.surface),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.success : AppColors.borderStrong,
        ),
        trackOutlineColor: WidgetStateProperty.all(AppColors.transparent),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Convenience accessors
// ---------------------------------------------------------------------------

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  AppPalette get palette => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
