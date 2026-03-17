import 'package:flutter/material.dart';

// Clase principal para manejar el estilo global de AgroVet AI
class AppTheme {
  // Paleta de colores inspirada en la naturaleza y tecnología (Nature-Tech)
  static const Color primaryGreen = Color(0xFF1B5E20); // Verde bosque profundo
  static const Color accentBlue = Color(0xFF0288D1);   // Azul inteligente (del logo)
  static const Color lightBg = Color(0xFFF8FAF8);      // Fondo crema muy suave
  static const Color cardWhite = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: accentBlue,
        surface: cardWhite,
        background: lightBg,
      ),
      // Tipografía profesional para una app de ingeniería/veterinaria
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32, 
          fontWeight: FontWeight.bold, 
          color: primaryGreen,
          letterSpacing: -1,
        ),
        titleLarge: TextStyle(
          fontSize: 22, 
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
      ),
      // Diseño de los campos de texto (Inputs)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.black54),
      ),
      // Estilo global de los botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          shadowColor: primaryGreen.withOpacity(0.4),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}