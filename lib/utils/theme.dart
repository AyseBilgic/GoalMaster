// lib/utils/theme.dart
import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  // Material 3 kullan
  useMaterial3: true,

  // Renk şeması (İsteğe bağlı: ColorScheme.fromSeed ile daha kolay)
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple, // Ana renk
    // brightness: Brightness.light, // Açık tema (varsayılan)
    // primary: Colors.deepPurple,
    // secondary: Colors.amber,
    // error: Colors.redAccent,
  ),

  // AppBar Teması
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.deepPurple, // AppBar arkaplan rengi
    foregroundColor: Colors.white, // AppBar ikon ve yazı rengi
    elevation: 4.0, // Gölge
    centerTitle: true, // Başlığı ortala (isteğe bağlı)
    titleTextStyle: TextStyle(
        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
  ),

  // ElevatedButton Teması
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple, // Buton arkaplanı
      foregroundColor: Colors.white, // Buton yazı rengi
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Köşe yuvarlaklığı
      ),
    ),
  ),

  // TextButton Teması
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.deepPurple, // Yazı rengi
    ),
  ),

  // TextFormField (Input) Teması
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder( // Varsayılan kenarlık
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder( // Odaklanıldığında kenarlık
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
    ),
    labelStyle: const TextStyle(color: Colors.deepPurple), // Label rengi
    prefixIconColor: Colors.deepPurple[200], // İkon rengi
  ),

  // Card Teması
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  ),

  // Diğer tema ayarları buraya eklenebilir...
  // textTheme: ...,
  // iconTheme: ...,
  // checkboxTheme: ...,
);