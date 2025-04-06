// lib/widgets/custom_button.dart
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // Null olabilir (devre dışı bırakmak için)
  final IconData? icon; // Opsiyonel ikon
  final Color? backgroundColor; // Opsiyonel arkaplan rengi
  final Color? foregroundColor; // Opsiyonel yazı/ikon rengi
  final bool isLoading; // Yükleme durumu

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false, // Varsayılan false
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed, // Yükleniyorsa null yap
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor, // Temadan alır veya override eder
        foregroundColor: foregroundColor,
         padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ).copyWith(
         // Yükleniyorsa farklı görünüm
         elevation: MaterialStateProperty.all(isLoading ? 0 : null),
      ),
      child: isLoading
          ? SizedBox( // Yüklenirken küçük indicator
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : Row( // İkon ve yazı
              mainAxisSize: MainAxisSize.min, // İçeriğe göre boyutlan
              children: [
                if (icon != null) Icon(icon, size: 18),
                if (icon != null) const SizedBox(width: 8),
                Text(text),
              ],
            ),
    );
  }
}