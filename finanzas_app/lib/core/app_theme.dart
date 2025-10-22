import 'package:flutter/material.dart';

class AppTheme {
  static const Color fondo = Color(0xFFF6F6F6);
  static const Color texto = Color(0xFF111111);
  static const Color botonesFondo = Color(0xFFFFCB74);
  static const Color botonesTexto = Color(0xFF2F2F2F);
  static const Color card1Fondo = Color(0xFFFFFFFF);
  static const Color card1Texto = Color(0xFF2F2F2F);
  static const Color card2Fondo = Color(0xFF2F2F2F);
  static const Color card2Texto = Color(0xFFF6F6F6);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: card2Fondo,
      colorScheme: ColorScheme.light(
        primary: card2Fondo,
        secondary: botonesFondo,
        background: fondo,
        surface: card1Fondo,
        onSurface: texto,
      ),
      scaffoldBackgroundColor: fondo,
      appBarTheme: AppBarTheme(
        backgroundColor: card2Fondo,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFF6F6F6)),
        titleTextStyle: const TextStyle(
          color: Color(0xFFF6F6F6),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: card1Fondo,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: botonesFondo,
          foregroundColor: botonesTexto,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: texto,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        titleLarge: TextStyle(
          color: texto,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        bodyLarge: TextStyle(
          color: texto,
          fontSize: 16,
        ),
      ),
      useMaterial3: true,
    );
  }
}