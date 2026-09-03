import 'package:flutter/material.dart';

/// Paleta de colores para FishBit Finance 2.0
/// Combinación de Dark OLED Luxury, Glassmorphism y Acentos Acuícolas
class AppColors {
  AppColors._();

  // ─── Fondos y Superficies ───────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF070A0F);
  static const Color backgroundLight = Color(0xFFF6F8FA);
  
  static const Color surfaceDark = Color(0xFF101622);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // ─── Capas Glassmorphism (Translúcidas) ──────────────────────────────────────
  static const Color glassFillDark = Color(0x0FFFFFFF); // ~6% blanco
  static const Color glassFillLight = Color(0xF2FFFFFF); // ~95% blanco esmerilado puro
  
  static const Color glassBorderDark = Color(0x1FFFFFFF); // ~12% blanco
  static const Color glassBorderLight = Color(0xFFE2E8F0); // Borde cristalino nítido
  
  static const Color glassBorderHighlight = Color(0x40FFFFFF); // ~25% resplandor

  // ─── Acentos de Marca (Acuicultura de Precisión) ────────────────────────────
  static const Color cyanWater = Color(0xFF00B2CC);      // Tecnología, agua, dashboard
  static const Color coralAction = Color(0xFFFF2D55);    // Acciones principales, alertas
  static const Color greenBiomass = Color(0xFF10B981);   // Biomasa sana, rentabilidad, OK
  static const Color amberWarning = Color(0xFFFF9500);   // Alerta de oxígeno, stock bajo
  static const Color purpleAnalytics = Color(0xFF8B5CF6);// Métricas analíticas, FCR
  static const Color blueOcean = Color(0xFF1D4ED8);      // Sedes e infraestructura

  // ─── Texto y Tipografía ─────────────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF8E9BAE);
  static const Color textTertiaryDark = Color(0xFF4B5563);

  static const Color textPrimaryLight = Color(0xFF0F172A);  // Midnight Slate (Alto contraste)
  static const Color textSecondaryLight = Color(0xFF475569);// Neutral Slate
  static const Color textTertiaryLight = Color(0xFF64748B); // Muted Slate

  // ─── Estados de Calidad de Agua ─────────────────────────────────────────────
  static const Color waterOptimal = Color(0xFF10B981);
  static const Color waterCaution = Color(0xFFFBBF24);
  static const Color waterCritical = Color(0xFFEF4444);
}
