import 'package:flutter/material.dart';

final appTheme = ThemeData(
  primarySwatch: Colors.blue, // Ana renk paleti
  hintColor: Colors.grey, // Input alanlarındaki ipucu rengi
  scaffoldBackgroundColor: Colors.white, // Scaffold arka plan rengi
  appBarTheme: const AppBarTheme( // AppBar teması
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    elevation: 0, // AppBar gölgesi
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData( // ElevatedButton teması
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme( // InputDecoration teması
    border: OutlineInputBorder(),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blue, width: 2),
    ),
  ),
    textTheme: const TextTheme( // Metin teması (isteğe bağlı)
    bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
    bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
     // Diğer metin stilleri...
  ),
  // Diğer tema ayarları...
);