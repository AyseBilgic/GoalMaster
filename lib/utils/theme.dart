// lib/utils/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Google Fonts paketi

// --- Renk Paleti ---
const Color primaryColor = Color(0xFF4A90E2);    // Canlı Mavi
const Color secondaryColor = Color(0xFF50E3C2);  // Turkuaz/Mint
const Color accentColor = Color(0xFFF5A623);     // Turuncu Vurgu
const Color backgroundColor = Color(0xFFF8F9FA); // Çok Açık Gri
const Color surfaceColor = Colors.white;         // Kart vb. Yüzeyler
const Color errorColor = Color(0xFFD0021B);     // Kırmızı (Hata)
const Color onPrimaryColor = Colors.white;       // Ana Renk Üzeri Yazı
const Color onSecondaryColor = Colors.black;     // İkincil Renk Üzeri Yazı
const Color onBackgroundColor = Color(0xFF242424); // Arka Plan Üzeri Yazı
const Color onSurfaceColor = Color(0xFF242424);  // Yüzey Üzeri Yazı
const Color onSurfaceVariantColor = Colors.grey; // Daha soluk yüzey yazısı

// --- ThemeData Tanımı ---
final ThemeData appTheme = ThemeData(
  // 1. Renk Şeması (ColorScheme)
  colorScheme: ColorScheme.light(
    primary: primaryColor,
    onPrimary: onPrimaryColor,
    secondary: secondaryColor,
    onSecondary: onSecondaryColor,
    error: errorColor,
    onError: Colors.white,
    surface: surfaceColor,
    onSurface: onSurfaceColor,
    background: backgroundColor,
    onBackground: onBackgroundColor,
    surfaceVariant: Colors.grey.shade100,
    onSurfaceVariant: onSurfaceVariantColor,
    outline: Colors.grey.shade400,
    shadow: Colors.black.withOpacity(0.1),
    inverseSurface: onSurfaceColor,
    onInverseSurface: surfaceColor,
    primaryContainer: primaryColor.withOpacity(0.1),
    onPrimaryContainer: primaryColor,
  ),

  // 2. Tipografi (Google Fonts - Poppins)
  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme).copyWith(
    displayLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 34),
    displayMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 28),
    displaySmall: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 24),
    headlineLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 26),
    headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 22),
    headlineSmall: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 20),
    titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
    titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16),
    titleSmall: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
    bodyLarge: GoogleFonts.poppins(fontSize: 15, height: 1.5),
    bodyMedium: GoogleFonts.poppins(fontSize: 14, height: 1.4, color: onSurfaceColor.withOpacity(0.8)),
    bodySmall: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
    labelLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
    labelMedium: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.grey.shade700),
    labelSmall: GoogleFonts.poppins(fontSize: 11, color: onSurfaceColor.withOpacity(0.7)),
  ).apply( bodyColor: onBackgroundColor, displayColor: onBackgroundColor, ),

  // 3. Scaffold Arka Plan Rengi
  scaffoldBackgroundColor: backgroundColor,

  // 4. AppBar Teması
  appBarTheme: AppBarTheme(
    backgroundColor: surfaceColor,
    foregroundColor: onSurfaceColor,
    elevation: 0.5,
    scrolledUnderElevation: 1.0,
    iconTheme: IconThemeData(color: onSurfaceColor.withOpacity(0.8), size: 22),
    actionsIconTheme: IconThemeData(color: onSurfaceColor.withOpacity(0.8), size: 22),
    titleTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: onSurfaceColor),
    centerTitle: false,
  ),

  // 5. Card Teması
  cardTheme: CardTheme(
    elevation: 1.5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    color: surfaceColor, clipBehavior: Clip.antiAlias,
  ),

  // 6. ListTile Teması
  listTileTheme: ListTileThemeData(
     contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
     tileColor: Colors.transparent, minVerticalPadding: 10,
     iconColor: onSurfaceVariantColor,
     titleTextStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: onSurfaceColor),
     subtitleTextStyle: GoogleFonts.poppins(fontSize: 13, color: onSurfaceVariantColor),
  ),

  // 7. Input (TextFormField) Teması
  inputDecorationTheme: InputDecorationTheme(
    filled: true, fillColor: Colors.grey.shade50.withOpacity(0.7),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder( borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none, ),
    enabledBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300, width: 1), ),
    focusedBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 1.5), ),
    errorBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: errorColor, width: 1), ),
    focusedErrorBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: errorColor, width: 1.5), ),
    labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w400),
    floatingLabelStyle: const TextStyle(color: primaryColor),
    prefixIconColor: MaterialStateColor.resolveWith((states) => states.contains(MaterialState.focused) ? primaryColor : Colors.grey.shade600),
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
  ),

  // 8. ElevatedButton Teması
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: onPrimaryColor, backgroundColor: primaryColor,
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
    ),
  ),

   // 9. TextButton Teması
   textButtonTheme: TextButtonThemeData(
     style: TextButton.styleFrom( foregroundColor: primaryColor, textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500), )
   ),

  // 10. FloatingActionButton Teması
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: accentColor, foregroundColor: Colors.white, elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),

  // 11. Checkbox Teması
  checkboxTheme: CheckboxThemeData(
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
     side: BorderSide(color: Colors.grey.shade400, width: 1.5),
     fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) { return primaryColor.withOpacity(0.9); }
        return null;
     }),
      // *** DÜZELTME: checkColor MaterialStateProperty.all ile sarmalandı ***
      checkColor: MaterialStateProperty.all(const Color.fromARGB(255, 255, 255, 255)), // Beyaz tik rengi daha iyi olabilir
      visualDensity: VisualDensity.compact,
  ),

  // 12. Chip Teması
  chipTheme: ChipThemeData(
     backgroundColor: primaryColor.withOpacity(0.1),
     labelStyle: GoogleFonts.poppins(fontSize: 11, color: primaryColor.withOpacity(0.9), fontWeight: FontWeight.w500),
     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
     side: BorderSide.none,
  ),

  // 13. Dialog Teması
  dialogTheme: DialogTheme(
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
     titleTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: onSurfaceColor),
     contentTextStyle: GoogleFonts.poppins(fontSize: 15, color: onSurfaceColor.withOpacity(0.8)),
     elevation: 5,
  ),

  // 14. Divider Teması
  dividerTheme: DividerThemeData( color: Colors.grey.shade200, thickness: 1, space: 30, indent: 16, endIndent: 16, ),

  // 15. ProgressIndicator Teması
   progressIndicatorTheme: ProgressIndicatorThemeData( color: primaryColor, linearTrackColor: Colors.grey.shade200,),

   // Use Material 3
   useMaterial3: true,
);