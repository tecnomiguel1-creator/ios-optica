import 'package:flutter/material.dart';

/// Paleta de colores e identidad corporativa para Óptica ONLY EYES S.R.L.
/// Inspirada en la precisión óptica, oftalmología clínica y ergonomía visual ejecutiva
class AppColors {
  // Identidad Corporativa Oficial
  static const String companyName = 'Óptica ONLY EYES S.R.L.';
  static const String systemName = 'ONLY EYES 360';
  static const String companySlogan = 'Un compromiso con tu visión';

  // Primarios - Azul Zafiro Óptico y Teal Clínico
  static const Color primary = Color(0xFF0F4C81); // Classic Sapphire Navy
  static const Color primaryDark = Color(0xFF0A3156);
  static const Color primaryLight = Color(0xFFE8F1F8);
  static const Color secondary = Color(0xFF00A896); // Clinical Teal
  static const Color secondaryDark = Color(0xFF028074);
  static const Color secondaryLight = Color(0xFFE6F7F5);
  static const Color accent = Color(0xFF0288D1); // Cyan Vision

  // Superficies y Fondos
  static const Color background = Color(0xFFF8FAFC); // Slate Soft White
  static const Color surface = Colors.white;
  static const Color cardBg = Colors.white;
  static const Color sidebarBg = Color(0xFF0A192F); // Deep Navy Slate
  static const Color sidebarText = Color(0xFF94A3B8);
  static const Color sidebarActive = Color(0xFF38BDF8);

  // Estados y Alertas
  static const Color success = Color(0xFF10B981); // Verde salud / Stock OK
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B); // Ámbar / Stock bajo
  static const Color warningDark = Color(0xFFB45309);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444); // Rojo / Sin stock / Error
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Textos y Bordes
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color divider = Color(0xFFEEF2F6);
}
