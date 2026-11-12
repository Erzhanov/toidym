import 'package:flutter/services.dart';

/// Маска ввода казахстанского телефона формата `+7 (7XX) XXX-XX-XX`.
class KzPhoneMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (rawDigits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    var digits = rawDigits;
    if (digits.startsWith('7') || digits.startsWith('8')) {
      digits = digits.substring(1);
    }
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    final buf = StringBuffer('+7');
    if (digits.isNotEmpty) {
      buf.write(' (');
      buf.write(digits.substring(0, digits.length.clamp(0, 3)));
      if (digits.length >= 3) {
        buf.write(')');
      }
    }
    if (digits.length > 3) {
      buf.write(' ');
      buf.write(digits.substring(3, digits.length.clamp(3, 6)));
    }
    if (digits.length > 6) {
      buf.write('-');
      buf.write(digits.substring(6, digits.length.clamp(6, 8)));
    }
    if (digits.length > 8) {
      buf.write('-');
      buf.write(digits.substring(8, digits.length.clamp(8, 10)));
    }

    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Валидация полей авторизации (Email, телефон, пароль).
abstract final class AuthValidators {
  static bool isValidEmail(String email) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(email.trim());
  }

  static bool isValidKzPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length == 11 &&
        (digits.startsWith('77') || digits.startsWith('87'));
  }

  /// Требование безопасности §4.3: минимум 8 символов, 1 цифра и 1 заглавная буква.
  static bool isStrongPassword(String password) {
    if (password.length < 8) return false;
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final hasUpper = RegExp(r'[A-ZА-ЯЁҚӨҰҮІҢҒҺ]').hasMatch(password);
    return hasDigit && hasUpper;
  }
}
