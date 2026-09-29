class MoneyFormatter {
  const MoneyFormatter._();

  static String format(String amountMinor, {String currency = 'RUB'}) {
    final value = BigInt.tryParse(amountMinor) ?? BigInt.zero;
    final negative = value.isNegative;
    final absolute = value.abs().toString().padLeft(3, '0');
    final major = absolute.substring(0, absolute.length - 2);
    final minor = absolute.substring(absolute.length - 2);
    final grouped = major.replaceAllMapped(
      RegExp(r'(?<=\d)(?=(\d{3})+$)'),
      (_) => '\u00a0',
    );
    final symbol = currency == 'RUB' ? '₽' : currency;
    return '${negative ? '−' : ''}$grouped,$minor $symbol';
  }

  static String? parseRubles(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[\s\u00a0₽]'), '')
        .replaceAll(',', '.');
    final match = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(normalized);
    if (match == null) return null;
    final major = BigInt.parse(match.group(1)!);
    final decimals = (match.group(2) ?? '').padRight(2, '0');
    final minor = decimals.isEmpty ? BigInt.zero : BigInt.parse(decimals);
    final result = major * BigInt.from(100) + minor;
    return result > BigInt.zero ? result.toString() : null;
  }
}
