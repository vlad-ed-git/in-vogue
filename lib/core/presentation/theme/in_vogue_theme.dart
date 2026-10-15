import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_motion.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';

/// The app's only theme, light, mapped onto Material roles.
abstract final class InVogueTheme {
  /// Dark system bar content on paper.
  static const systemOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Color(0x00000000),
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: InVogueColors.paper,
    systemNavigationBarDividerColor: Color(0x00000000),
    systemNavigationBarIconBrightness: Brightness.dark,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );

  static const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: InVogueColors.signal,
    onPrimary: InVogueColors.onSignal,
    primaryContainer: InVogueColors.accent,
    onPrimaryContainer: InVogueColors.onAccent,
    secondary: InVogueColors.accent,
    onSecondary: InVogueColors.onAccent,
    secondaryContainer: InVogueColors.accent,
    onSecondaryContainer: InVogueColors.onAccent,
    tertiary: InVogueColors.accent,
    onTertiary: InVogueColors.onAccent,
    error: InVogueColors.alert,
    onError: InVogueColors.paper,
    errorContainer: InVogueColors.accent,
    onErrorContainer: InVogueColors.alert,
    surface: InVogueColors.paper,
    onSurface: InVogueColors.ink,
    onSurfaceVariant: InVogueColors.graphite,
    surfaceDim: InVogueColors.studio,
    surfaceBright: InVogueColors.paper,
    surfaceContainerLowest: InVogueColors.paper,
    surfaceContainerLow: InVogueColors.paper,
    surfaceContainer: InVogueColors.paper,
    surfaceContainerHigh: InVogueColors.paper,
    surfaceContainerHighest: InVogueColors.accent,
    outline: InVogueColors.line,
    outlineVariant: InVogueColors.rule,
    shadow: Color(0x00000000),
    scrim: InVogueColors.ink,
    inverseSurface: InVogueColors.ink,
    onInverseSurface: InVogueColors.paper,
    inversePrimary: InVogueColors.accent,
    surfaceTint: Color(0x00000000),
  );

  static const textTheme = TextTheme(
    displayLarge: InVogueType.numeral,
    displayMedium: InVogueType.headline,
    displaySmall: InVogueType.numeralSmall,
    headlineLarge: InVogueType.title,
    headlineMedium: InVogueType.figure,
    headlineSmall: InVogueType.section,
    titleLarge: InVogueType.section,
    titleMedium: InVogueType.bodyStrong,
    titleSmall: InVogueType.item,
    bodyLarge: InVogueType.body,
    bodyMedium: InVogueType.meta,
    bodySmall: InVogueType.caption,
    labelLarge: InVogueType.button,
    labelMedium: InVogueType.link,
    labelSmall: InVogueType.label,
  );

  static const _square = RoundedRectangleBorder();
  static const _transparent = WidgetStatePropertyAll<Color>(Color(0x00000000));

  static final ThemeData paper = _build();

  static ThemeData _build() {
    final buttonShape = const WidgetStatePropertyAll<OutlinedBorder>(_square);
    final noElevation = const WidgetStatePropertyAll<double>(0);
    WidgetStateProperty<Color?> disabledOnly(Color color) =>
        WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled) ? color : null,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: InVogueType.textFamily,
      fontFamilyFallback: InVogueType.cjkFallback,
      scaffoldBackgroundColor: InVogueColors.paper,
      canvasColor: InVogueColors.paper,
      cardColor: InVogueColors.paper,
      dividerColor: InVogueColors.rule,
      disabledColor: InVogueColors.graphite,
      hintColor: InVogueColors.graphite,
      splashFactory: NoSplash.splashFactory,
      splashColor: const Color(0x00000000),
      highlightColor: const Color(0x00000000),
      hoverColor: const Color(0x00000000),
      focusColor: const Color(0x00000000),
      shadowColor: const Color(0x00000000),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      iconTheme: const IconThemeData(color: InVogueColors.ink, size: 24),
      cupertinoOverrideTheme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: InVogueColors.ink,
        scaffoldBackgroundColor: InVogueColors.paper,
        barBackgroundColor: InVogueColors.paper,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: InVogueColors.paper,
        foregroundColor: InVogueColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Color(0x00000000),
        shadowColor: Color(0x00000000),
        centerTitle: false,
        toolbarHeight: InVogueLayout.topBarHeight,
        titleTextStyle: InVogueType.item,
        systemOverlayStyle: systemOverlayStyle,
      ),
      dividerTheme: const DividerThemeData(
        color: InVogueColors.rule,
        thickness: InVogueLayout.strokeHairline,
        space: InVogueLayout.strokeHairline,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          elevation: noElevation,
          overlayColor: _transparent,
          shadowColor: _transparent,
          surfaceTintColor: _transparent,
          minimumSize: const WidgetStatePropertyAll(
            Size(0, InVogueLayout.controlHeight),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsetsDirectional.only(start: 18, end: 16),
          ),
          alignment: AlignmentDirectional.centerStart,
          textStyle: const WidgetStatePropertyAll(InVogueType.button),
          backgroundColor: disabledOnly(InVogueColors.studio),
          foregroundColor: disabledOnly(InVogueColors.graphite),
          animationDuration: InVogueMotion.press,
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          elevation: noElevation,
          overlayColor: _transparent,
          foregroundColor: const WidgetStatePropertyAll(InVogueColors.ink),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: InVogueType.textFamily,
              fontSize: 15,
              height: 20 / 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
              decoration: TextDecoration.underline,
            ),
          ),
          minimumSize: const WidgetStatePropertyAll(
            Size(InVogueLayout.targetMin, InVogueLayout.targetMin),
          ),
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          elevation: noElevation,
          overlayColor: _transparent,
          foregroundColor: const WidgetStatePropertyAll(InVogueColors.ink),
          side: const WidgetStatePropertyAll(
            BorderSide(color: InVogueColors.ink),
          ),
          textStyle: const WidgetStatePropertyAll(InVogueType.button),
          minimumSize: const WidgetStatePropertyAll(
            Size(0, InVogueLayout.controlHeight),
          ),
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          overlayColor: _transparent,
          foregroundColor: const WidgetStatePropertyAll(InVogueColors.ink),
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: false,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: InVogueType.label,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        hintStyle: TextStyle(color: InVogueColors.graphite),
        errorStyle: TextStyle(color: InVogueColors.alert),
        border: OutlineInputBorder(
          borderRadius: InVogueLayout.radiusNone,
          borderSide: BorderSide(color: InVogueColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: InVogueLayout.radiusNone,
          borderSide: BorderSide(color: InVogueColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: InVogueLayout.radiusNone,
          borderSide: BorderSide(
            color: InVogueColors.ink,
            width: InVogueLayout.strokeSelect,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: InVogueLayout.radiusNone,
          borderSide: BorderSide(color: InVogueColors.alert),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: InVogueLayout.radiusNone,
          borderSide: BorderSide(
            color: InVogueColors.alert,
            width: InVogueLayout.strokeSelect,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: InVogueLayout.radiusNone,
          borderSide: BorderSide(color: InVogueColors.rule),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: InVogueColors.ink,
        selectionColor: InVogueColors.accent,
        selectionHandleColor: InVogueColors.ink,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: InVogueColors.paper,
        modalBackgroundColor: InVogueColors.paper,
        surfaceTintColor: Color(0x00000000),
        shadowColor: Color(0x00000000),
        elevation: 0,
        modalElevation: 0,
        modalBarrierColor: InVogueColors.veil,
        shape: _square,
        showDragHandle: false,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: InVogueColors.paper,
        surfaceTintColor: Color(0x00000000),
        shadowColor: Color(0x00000000),
        elevation: 0,
        shape: _square,
        barrierColor: InVogueColors.veil,
        titleTextStyle: InVogueType.section,
        contentTextStyle: InVogueType.body,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: InVogueColors.ink,
        contentTextStyle: TextStyle(
          fontFamily: InVogueType.textFamily,
          fontSize: 16,
          height: 24 / 16,
          letterSpacing: 0,
          color: InVogueColors.paper,
        ),
        actionTextColor: InVogueColors.paper,
        elevation: 0,
        shape: _square,
      ),
      cardTheme: const CardThemeData(
        color: InVogueColors.paper,
        surfaceTintColor: Color(0x00000000),
        shadowColor: Color(0x00000000),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: _square,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: InVogueColors.paper,
        surfaceTintColor: Color(0x00000000),
        shadowColor: Color(0x00000000),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: InVogueColors.rule),
        ),
        textStyle: InVogueType.body,
      ),
      menuTheme: const MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(InVogueColors.paper),
          surfaceTintColor: _transparent,
          shadowColor: _transparent,
          elevation: WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(side: BorderSide(color: InVogueColors.rule)),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: InVogueColors.ink,
        linearTrackColor: InVogueColors.rule,
        circularTrackColor: Color(0x00000000),
      ),
      scrollbarTheme: const ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(InVogueColors.line),
        radius: Radius.zero,
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(color: InVogueColors.ink),
        textStyle: TextStyle(
          fontFamily: InVogueType.textFamily,
          fontSize: 12,
          height: 16 / 12,
          letterSpacing: 0,
          color: InVogueColors.paper,
        ),
      ),
    );
  }

  /// A `MaterialApp.builder` that forces light platform brightness, sets the
  /// system bar style and caps text scaling at 200%.
  static Widget builder(BuildContext context, Widget? child) {
    final media = MediaQuery.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: MediaQuery(
        data: media.copyWith(
          platformBrightness: Brightness.light,
          textScaler: media.textScaler.clamp(
            maxScaleFactor: InVogueType.textMaxScale,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
