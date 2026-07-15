import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF0D47A1); // Deep Blue
  static const Color primaryLight = Color(0xFF1E88E5);
  static const Color accent = Color(0xFF7C4DFF); // Purple Accent
  
  // Status / Risk Level Colors
  static const Color rendah = Color(0xFF22C55E); // Green
  static const Color sedang = Color(0xFFEAB308); // Yellow
  static const Color tinggi = Color(0xFFF97316); // Orange
  static const Color sangatTinggi = Color(0xFFEF4444); // Red

  // Neutral Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color background = Color(0xFFF8FAFC);

  // Gradients
  static const Gradient headerGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient prediksiGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        background: AppColors.background,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        bodyLarge: GoogleFonts.outfit(color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.outfit(color: AppColors.textSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.sangatTinggi),
        ),
        labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.08),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.textSecondary);
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11);
          }
          return const TextStyle(color: AppColors.textSecondary, fontSize: 11);
        }),
      ),
    );
  }
}

// Utility functions for risk status
Color risikoColor(String? level) {
  switch (level?.toLowerCase()) {
    case 'sangat tinggi':
      return AppColors.sangatTinggi;
    case 'tinggi':
      return AppColors.tinggi;
    case 'sedang':
      return AppColors.sedang;
    case 'rendah':
    default:
      return AppColors.rendah;
  }
}

IconData risikoIcon(String? level) {
  switch (level?.toLowerCase()) {
    case 'sangat tinggi':
      return Icons.gpp_bad; // Dangerous icon
    case 'tinggi':
      return Icons.warning_amber_rounded; // Warning icon
    case 'sedang':
      return Icons.info_outline; // Info icon
    case 'rendah':
    default:
      return Icons.check_circle_outline; // Check icon
  }
}
