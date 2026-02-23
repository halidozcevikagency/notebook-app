/// Uygulama genelinde kullanılan renk sabitleri
/// Zen tasarım dilini yansıtan, yüksek kontrastlı renk paleti
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Ana renkler (Indigo / Violet spectrum)
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Vurgu rengi
  static const Color accent = Color(0xFF8B5CF6);

  // Nötr renkler (Light Mode)
  static const Color backgroundLight = Color(0xFFFAFAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceSecondaryLight = Color(0xFFF4F4F8);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);

  // Nötr renkler (Dark Mode)
  static const Color backgroundDark = Color(0xFF0F0F13);
  static const Color surfaceDark = Color(0xFF1A1A24);
  static const Color surfaceSecondaryDark = Color(0xFF232330);
  static const Color borderDark = Color(0xFF2D2D3D);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textTertiaryDark = Color(0xFF6B7280);

  // Durum renkleri
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Etiket renkleri (Tag sistemi)
  static const List<Color> tagColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Blue
    Color(0xFF06B6D4), // Cyan
    Color(0xFF84CC16), // Lime
    Color(0xFFF97316), // Orange
  ];

  // Glassmorphism için
  static const Color glassLight = Color(0x1AFFFFFF);
  static const Color glassDark = Color(0x1AFFFFFF);
}
