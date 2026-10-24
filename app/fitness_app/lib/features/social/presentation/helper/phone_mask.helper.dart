import 'package:flutter/services.dart';

const _nationalDigits = 10;

/// Цифры национальной части номера РФ (без кода страны), не более 10.
String _nationalDigitsOf(String input) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.isNotEmpty && (digits[0] == '7' || digits[0] == '8')) {
    digits = digits.substring(1);
  }
  return digits.length > _nationalDigits
      ? digits.substring(0, _nationalDigits)
      : digits;
}

/// Форматирует ввод в маску `+7 (XXX) XXX-XX-XX`; пустой ввод даёт пустую строку.
String formatRuPhone(String input) {
  final digits = _nationalDigitsOf(input);
  if (digits.isEmpty) return '';
  final buffer = StringBuffer('+7 (');
  for (var i = 0; i < digits.length; i++) {
    if (i == 3) buffer.write(') ');
    if (i == 6 || i == 8) buffer.write('-');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Нормализует номер к E.164 (`+7XXXXXXXXXX`); `null`, если номер неполный.
String? normalizeRuPhone(String input) {
  final digits = _nationalDigitsOf(input);
  return digits.length == _nationalDigits ? '+7$digits' : null;
}

/// Применяет маску `+7 (XXX) XXX-XX-XX` и ограничивает длину ввода.
class RuPhoneInputFormatter extends TextInputFormatter {
  const RuPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = formatRuPhone(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
