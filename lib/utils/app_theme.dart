import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2A3F6F); // Koyu Mavi
  static const Color accent = Color(0xFF4FC3F7); // Açık Turkuaz
  static const Color backgroundLight = Color(0xFFF8F8F8); // Açık Gri
  static const Color backgroundDarker = Color(0xFFF0F2F5); // Biraz daha koyu açık gri
  static const Color textDark = Color(0xFF333333);
  static const Color textGrey = Color(0xFF757575);
  static const Color errorRed = Color(0xFFEF5350);
  static const Color error = errorRed;
  static const Color success = Color(0xFF4CAF50);
  static const Color secondary = Color(0xFF26C6DA);
  static const Color textSecondary = textGrey;
  static const Color cardBackground = Colors.white;
}

class AppTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: 'Readex Pro',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static const TextStyle headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textDark,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textGrey,
  );
  static const TextStyle button = buttonText;
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
  static const TextStyle inputLabel = labelText;
  static const TextStyle labelText = TextStyle(
    color: AppColors.textGrey,
    fontSize: 14,
  );
  static const TextStyle inputText = inputTextStyle;
  static const TextStyle inputTextStyle = TextStyle(
    color: AppColors.textDark,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle locationInfo = TextStyle(
    fontSize: 12,
    color: AppColors.textGrey,
    fontStyle: FontStyle.italic,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  // Burası eklenecek yeni stil!
  static const TextStyle floatingLabel = TextStyle(
    fontSize: 18, // İstediğiniz daha büyük font boyutu
    fontWeight: FontWeight.w600, // İsteğe bağlı: daha belirgin bir kalınlık
    color: AppColors.primary, // Veya başka bir belirgin renk
  );
}