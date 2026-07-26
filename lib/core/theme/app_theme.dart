import 'package:flutter/material.dart';

/// MyWallet design tokens.
///
/// Palette is deliberately restrained to five source colors plus two
/// derived tones (a lighter plum for elevated surfaces, and a muted sage
/// pulled from the charcoal for "positive" states) so nothing feels like
/// a stock Material red/green finance app.
class AppColors {
  AppColors._();

  // --- Source palette ---
  static const black = Color(0xFF000000);
  static const plum = Color(0xFF291528);
  static const charcoal = Color(0xFF3A3E3B);
  static const offWhite = Color(0xFFF0EFF4);
  static const mauve = Color(0xFF9E829C);

  // --- Derived, staying within the family ---
  /// Slightly lifted plum, used for cards/sheets so they read as a step
  /// above the pure-black canvas.
  static const plumElevated = Color(0xFF34193A);

  /// A muted sage pulled out of the charcoal by warming it toward
  /// off-white. Used as the "income / positive" signal instead of a
  /// generic green.
  static const sage = Color(0xFF7C8877);

  /// Mauve at low opacity, used for glows, selected-state fills, dividers.
  static Color mauveDim(double opacity) => mauve.withValues(alpha: opacity);
  static Color offWhiteDim(double opacity) => offWhite.withValues(alpha: opacity);

  /// Deeper mauve, used at the dark end of gradients.
  static const mauveDeep = Color(0xFF5C4A5A);

  /// Deeper sage, used at the dark end of income gradients.
  static const sageDeep = Color(0xFF454F42);
}

/// Gradients built only from the source palette / its derived tones —
/// no new hues introduced, just depth.
class AppGradients {
  AppGradients._();

  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF432349), AppColors.plumElevated, Color(0xFF1B0E1E)],
    stops: [0.0, 0.55, 1.0],
  );

  static const expenseCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4A3549), AppColors.plumElevated],
  );

  static const incomeCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A4238), AppColors.plumElevated],
  );

  static const tile = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.plumElevated, Color(0xFF2C1730)],
  );

  static LinearGradient chipSelected = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.mauve, AppColors.mauveDeep],
  );
}

class AppTheme {
  AppTheme._();

  static const fontFamily = 'dmsans';

  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.black,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.black,
        primary: AppColors.mauve,
        secondary: AppColors.sage,
        error: Color(0xFFC97B86),
        onSurface: AppColors.offWhite,
        onPrimary: AppColors.black,
      ),
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.black,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.offWhite),
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.offWhite,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.plumElevated,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.offWhiteDim(0.06)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.plumElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.offWhite,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.offWhiteDim(0.75),
          fontSize: 14,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.plumElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.plum,
        hintStyle: TextStyle(color: AppColors.offWhiteDim(0.35)),
        labelStyle: TextStyle(color: AppColors.offWhiteDim(0.6)),
        floatingLabelStyle: const TextStyle(color: AppColors.mauve),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.offWhiteDim(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.offWhiteDim(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.mauve, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mauve,
          foregroundColor: AppColors.black,
          disabledBackgroundColor: AppColors.mauveDim(0.3),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: -0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.offWhiteDim(0.7),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: IconThemeData(color: AppColors.offWhiteDim(0.85)),
      dividerTheme: DividerThemeData(color: AppColors.offWhiteDim(0.08), space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.plumElevated,
        selectedColor: AppColors.mauve,
        disabledColor: AppColors.plumElevated,
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.offWhiteDim(0.7),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.black,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        side: BorderSide(color: AppColors.offWhiteDim(0.08)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.mauve,
        foregroundColor: AppColors.black,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.plumElevated,
        contentTextStyle: const TextStyle(fontFamily: fontFamily, color: AppColors.offWhite),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.offWhiteDim(0.7),
        textColor: AppColors.offWhite,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.mauve),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.plumElevated,
        headerBackgroundColor: AppColors.plum,
        headerForegroundColor: AppColors.offWhite,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      // Hero / balance figure
      displaySmall: const TextStyle(
        fontFamily: fontFamily,
        color: AppColors.offWhite,
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        height: 1.0,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      // Section eyebrows ("EXPENSES BY CATEGORY")
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.offWhiteDim(0.5),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
      titleLarge: const TextStyle(
        fontFamily: fontFamily,
        color: AppColors.offWhite,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: const TextStyle(
        fontFamily: fontFamily,
        color: AppColors.offWhite,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.offWhite,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.offWhiteDim(0.85),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.offWhiteDim(0.45),
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
